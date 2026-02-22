"""語音教練模組的核心服務，負責即時語音對話的 WebSocket 中繼與管理。

主要職責：
- 建立與 OpenAI Realtime API 的 WebSocket 連線
- 中繼客戶端音訊至 OpenAI，並將回應串流推送給客戶端
- 在 AI 語音回應完成後，使用 Gemini 產出結構化教練分析（情緒、建議、方向）
- 管理會話生命週期（建立、TTL 檢查、關閉、全局清理）

架構說明：
OpenAI Realtime API 負責音訊對話（語音教練建議），
Gemini 負責結構化分析（情緒偵測、下一句建議、聊天方向），
兩者在 response.done 事件後並行運作，Gemini 分析在背景任務中執行。
"""

import asyncio
import time
from dataclasses import dataclass, field
from typing import Optional

import orjson
import structlog
import websockets
from sqlalchemy.ext.asyncio import async_sessionmaker
from websockets.exceptions import (
    ConnectionClosed,
    InvalidHandshake,
    InvalidURI,
)
from websockets.protocol import State as WsState

from config.constants import (
    VOICE_COACH_SESSION_TTL_SECONDS,
    WS_HEARTBEAT_INTERVAL,
    WS_HEARTBEAT_TIMEOUT,
    WS_OPENAI_CONNECT_TIMEOUT,
)
from infra.database.models import AnalysisLog
from modules.voice_coach.errors import OpenAIConnectionFailed, SessionNotFound
from modules.voice_coach.models import VoiceCoachSession
from clients.llm.gemini_client import GeminiClient
from modules.voice_coach.prompts import VOICE_COACH_SYSTEM_PROMPT, COACHING_ANALYSIS_PROMPT
from services.id_service import generate_cuid
from services.stream_service import StreamService

logger = structlog.get_logger()


@dataclass
class _SessionState:
    """內部會話狀態，追蹤 OpenAI WebSocket 連線、監聽任務及建立時間。

    同時收集對話過程中的轉寫文字與教練分析結果，
    在會話結束時持久化至 analysis_logs 表。
    """

    session_id: str
    openai_ws: Optional[websockets.asyncio.client.ClientConnection] = None
    listener_task: Optional[asyncio.Task] = None
    created_at: float = field(default_factory=time.monotonic)
    # 收集會話期間的對話轉寫（麥克風收音的即時辨識結果）
    input_transcripts: list[str] = field(default_factory=list)
    # 收集會話期間的 AI 教練語音轉寫
    coach_transcripts: list[str] = field(default_factory=list)
    # 收集會話期間的結構化教練分析結果
    coaching_updates: list[dict] = field(default_factory=list)


class VoiceCoachService:
    """語音教練服務，透過 OpenAI Realtime API 提供即時約會對話指導。"""

    def __init__(
        self,
        api_key: str,
        stream_service: StreamService,
        realtime_url: str,
        session_factory: Optional[async_sessionmaker] = None,
        gemini_client: Optional[GeminiClient] = None,
    ):
        """初始化語音教練服務。

        Args:
            api_key: OpenAI API 金鑰
            stream_service: 串流事件推送服務
            realtime_url: OpenAI Realtime API 的 WebSocket URL
            session_factory: SQLAlchemy async session 工廠，用於持久化對話紀錄
            gemini_client: Gemini 客戶端，用於結構化教練分析（比 OpenAI text 回應更聰明）
        """
        self._api_key = api_key
        self._stream = stream_service
        self._realtime_url = realtime_url
        self._sf = session_factory
        self._gemini = gemini_client
        self._sessions: dict[str, _SessionState] = {}
        # 累加 AI 語音回應轉寫，用於判斷是否需要觸發分析
        self._audio_transcript_buffers: dict[str, str] = {}

    # ── 會話建立 ──────────────────────────────────────────────

    async def create_session(
        self, session_id: str, request_id: str
    ) -> VoiceCoachSession:
        """建立新的語音教練會話，連接 OpenAI Realtime API 並啟動監聽。

        Raises:
            OpenAIConnectionFailed: 無法連線至 OpenAI Realtime API
        """
        log = logger.bind(request_id=request_id, session_id=session_id)
        log.info("voice_coach_session_creating")

        headers = {
            "Authorization": f"Bearer {self._api_key}",
            "OpenAI-Beta": "realtime=v1",
        }

        try:
            openai_ws = await asyncio.wait_for(
                websockets.connect(
                    self._realtime_url,
                    additional_headers=headers,
                    ping_interval=WS_HEARTBEAT_INTERVAL,
                    ping_timeout=WS_HEARTBEAT_TIMEOUT,
                    close_timeout=5,
                ),
                timeout=WS_OPENAI_CONNECT_TIMEOUT,
            )
        except asyncio.TimeoutError:
            log.error("openai_realtime_connect_timeout")
            raise OpenAIConnectionFailed("連線 OpenAI Realtime API 逾時")
        except (InvalidHandshake, InvalidURI, OSError) as exc:
            log.error("openai_realtime_connect_failed", error=str(exc))
            raise OpenAIConnectionFailed(f"連線 OpenAI Realtime API 失敗: {exc}")

        # 發送會話配置：啟用雙模態（文字+音訊）、VAD、Whisper 轉寫
        config_msg = orjson.dumps(
            {
                "type": "session.update",
                "session": {
                    "modalities": ["text", "audio"],
                    "instructions": VOICE_COACH_SYSTEM_PROMPT,
                    "input_audio_format": "pcm16",
                    "output_audio_format": "pcm16",
                    "input_audio_transcription": {"model": "whisper-1"},
                    "turn_detection": {
                        "type": "server_vad",
                        "threshold": 0.5,
                        "prefix_padding_ms": 300,
                        "silence_duration_ms": 600,
                    },
                },
            }
        ).decode()
        await openai_ws.send(config_msg)

        state = _SessionState(
            session_id=session_id,
            openai_ws=openai_ws,
            listener_task=asyncio.create_task(
                self._listen_openai(session_id, openai_ws)
            ),
        )
        self._sessions[session_id] = state
        log.info("voice_coach_session_created")

        return VoiceCoachSession(session_id=session_id, status="active")

    # ── 音訊中繼 ──────────────────────────────────────────────

    async def relay_audio(self, session_id: str, audio_base64: str) -> None:
        """將客戶端音訊資料轉發至 OpenAI WebSocket。"""
        state = self._get_active_session(session_id)

        if state.openai_ws is None or state.openai_ws.state != WsState.OPEN:
            logger.bind(session_id=session_id).warning("relay_audio_ws_closed")
            await self.close_session(session_id)
            raise SessionNotFound(session_id)

        msg = orjson.dumps(
            {"type": "input_audio_buffer.append", "audio": audio_base64}
        ).decode()
        await state.openai_ws.send(msg)

    # ── OpenAI 事件監聽 ──────────────────────────────────────

    async def _listen_openai(
        self,
        session_id: str,
        openai_ws: websockets.asyncio.client.ClientConnection,
    ) -> None:
        """監聽 OpenAI WebSocket 訊息並透過串流服務推送給客戶端。

        事件處理流程：
        1. 語音回應事件（audio.delta / audio_transcript.delta）→ 串流給客戶端
        2. 語音回應完成（response.done）→ 背景呼叫 Gemini 進行結構化分析
        3. 輸入音訊辨識完成 → 推送對話辨識內容給客戶端
        """
        log = logger.bind(session_id=session_id)
        try:
            async for message in openai_ws:
                event = orjson.loads(message)
                event_type = event.get("type", "")

                # AI 語音回應的音訊串流
                if event_type == "response.audio.delta":
                    await self._safe_publish(
                        session_id,
                        {"type": "audio", "payload": event.get("delta", "")},
                    )

                # AI 語音回應的即時轉寫（流式 delta）
                elif event_type == "response.audio_transcript.delta":
                    delta = event.get("delta", "")
                    await self._safe_publish(
                        session_id,
                        {"type": "transcript", "payload": delta},
                    )
                    # 累加用於後續判斷是否需要觸發分析
                    self._audio_transcript_buffers[session_id] = (
                        self._audio_transcript_buffers.get(session_id, "") + delta
                    )

                # AI 語音回應的完整轉寫（一個回應結束時）
                elif event_type == "response.audio_transcript.done":
                    transcript = event.get("transcript", "")
                    if transcript:
                        await self._safe_publish(
                            session_id,
                            {"type": "transcript_done", "payload": transcript},
                        )

                # 回應完成（語音回應完成後，用 Gemini 做結構化分析）
                elif event_type == "response.done":
                    # 語音回應完成 → 用 Gemini 觸發結構化分析
                    coach_text = self._audio_transcript_buffers.pop(session_id, "")
                    if coach_text:
                        # 收集 AI 教練語音轉寫供會話結束時持久化
                        state = self._sessions.get(session_id)
                        if state:
                            state.coach_transcripts.append(coach_text)
                        log.info(
                            "triggering_gemini_analysis",
                            transcript_len=len(coach_text),
                        )
                        # 用背景任務呼叫 Gemini，不阻塞音訊串流
                        asyncio.create_task(
                            self._gemini_coaching_analysis(session_id)
                        )

                    await self._safe_publish(
                        session_id, {"type": "response_complete"}
                    )

                # 輸入音訊辨識完成（麥克風收音的即時轉寫）
                elif event_type == "conversation.item.input_audio_transcription.completed":
                    transcript_text = event.get("transcript", "")
                    if transcript_text:
                        await self._safe_publish(
                            session_id,
                            {"type": "input_transcript", "payload": transcript_text},
                        )
                        # 收集對話轉寫供會話結束時持久化
                        state = self._sessions.get(session_id)
                        if state:
                            state.input_transcripts.append(transcript_text)

                # 使用者開始說話
                elif event_type == "input_audio_buffer.speech_started":
                    await self._safe_publish(
                        session_id, {"type": "speech_started"}
                    )

                # 使用者停止說話
                elif event_type == "input_audio_buffer.speech_stopped":
                    await self._safe_publish(
                        session_id, {"type": "speech_stopped"}
                    )

                # OpenAI API 錯誤
                elif event_type == "error":
                    error_obj = event.get("error", {})
                    error_msg = error_obj.get("message", "") if isinstance(error_obj, dict) else str(error_obj)
                    # 過濾已知的非致命錯誤（取消回應後的殘餘錯誤）
                    if "active response" in error_msg.lower():
                        log.info("openai_active_response_conflict", error=error_msg)
                    else:
                        log.error("openai_realtime_error", error=error_obj)
                        await self._safe_publish(
                            session_id,
                            {"type": "error", "payload": error_obj},
                        )

        except ConnectionClosed as exc:
            log.warning("openai_ws_connection_closed", code=exc.code, reason=str(exc.reason))
            await self._safe_publish(
                session_id,
                {"type": "error", "payload": {"message": "OpenAI 連線已中斷"}},
            )
        except asyncio.CancelledError:
            log.info("listener_task_cancelled")
        except Exception as exc:
            log.exception("listener_task_unexpected_error", error=str(exc))
            await self._safe_publish(
                session_id,
                {"type": "error", "payload": {"message": "語音教練內部錯誤"}},
            )
        finally:
            log.info("listener_task_exiting")
            await self.close_session(session_id)

    # ── 主動請求結構化教練分析 ──────────────────────────────────

    async def _gemini_coaching_analysis(self, session_id: str) -> None:
        """使用 Gemini 分析對話內容，產出結構化教練資料（情緒、建議、方向）。

        在背景任務中執行，不阻塞 OpenAI 音訊串流。
        從 session state 收集最近的對話轉寫作為輸入。
        """
        if not self._gemini:
            return

        log = logger.bind(session_id=session_id)
        state = self._sessions.get(session_id)
        if not state:
            return

        # 組合最近的對話內容作為分析輸入
        conversation_parts = []
        for t in state.input_transcripts[-5:]:
            conversation_parts.append(f"[對話] {t}")
        for t in state.coach_transcripts[-3:]:
            conversation_parts.append(f"[教練回覆] {t}")
        conversation_text = "\n".join(conversation_parts)

        if not conversation_text.strip():
            return

        try:
            log.info("gemini_analysis_start", input_len=len(conversation_text))
            coaching = await self._gemini.analyze_text(
                system_prompt=COACHING_ANALYSIS_PROMPT,
                user_prompt=f"以下是目前的對話紀錄：\n\n{conversation_text}",
                request_id=f"vc-{session_id[:8]}",
            )
            log.info("gemini_analysis_done", emotion=coaching.get("emotion"))

            await self._safe_publish(
                session_id,
                {"type": "coaching_update", "payload": coaching},
            )
            # 收集教練分析結果供會話結束時持久化
            state = self._sessions.get(session_id)
            if state:
                state.coaching_updates.append(coaching)
        except Exception as exc:
            log.warning("gemini_analysis_failed", error=str(exc))
            # Gemini 失敗不影響主要語音功能

    # ── 安全發布（防止 QueueFull）─────────────────────────────

    async def _safe_publish(self, session_id: str, event: dict) -> None:
        """安全地向串流服務發布事件，捕獲 QueueFull 以避免阻塞。"""
        try:
            await self._stream.publish(session_id, event)
        except asyncio.QueueFull:
            logger.bind(session_id=session_id).warning(
                "stream_queue_full", event_type=event.get("type")
            )

    # ── 會話狀態查詢（含 TTL 檢查）──────────────────────────

    def _get_active_session(self, session_id: str) -> _SessionState:
        """取得活躍的會話狀態，含 TTL 過期檢查。"""
        state = self._sessions.get(session_id)
        if not state:
            raise SessionNotFound(session_id)

        elapsed = time.monotonic() - state.created_at
        if elapsed > VOICE_COACH_SESSION_TTL_SECONDS:
            logger.bind(session_id=session_id).warning(
                "session_ttl_expired", elapsed_seconds=int(elapsed)
            )
            asyncio.create_task(self.close_session(session_id))
            raise SessionNotFound(session_id)

        return state

    # ── 會話關閉 ──────────────────────────────────────────────

    async def close_session(self, session_id: str) -> None:
        """關閉指定的語音教練會話，清理所有資源並持久化對話紀錄。冪等操作。"""
        self._audio_transcript_buffers.pop(session_id, None)
        state = self._sessions.pop(session_id, None)
        if not state:
            return

        log = logger.bind(session_id=session_id)
        log.info("voice_coach_session_closing")

        if state.listener_task and not state.listener_task.done():
            state.listener_task.cancel()
            try:
                await state.listener_task
            except (asyncio.CancelledError, Exception):
                pass

        if state.openai_ws and state.openai_ws.state == WsState.OPEN:
            try:
                await state.openai_ws.close()
            except Exception:
                log.warning("openai_ws_close_error", exc_info=True)

        # 持久化對話紀錄至 analysis_logs 表
        await self._persist_session_log(state)
        log.info("voice_coach_session_closed")

    # ── 對話紀錄持久化 ──────────────────────────────────────

    async def _persist_session_log(self, state: _SessionState) -> None:
        """將會話期間收集的對話轉寫與教練分析寫入 analysis_logs 表。"""
        if not self._sf:
            return

        # 若無對話內容則跳過
        if not state.input_transcripts and not state.coach_transcripts:
            return

        log = logger.bind(session_id=state.session_id)
        elapsed_ms = int((time.monotonic() - state.created_at) * 1000)

        # 組合對話摘要：使用者/AI 輪替的轉寫紀錄
        input_summary_lines = []
        for t in state.input_transcripts:
            input_summary_lines.append(f"[對話] {t}")
        for t in state.coach_transcripts:
            input_summary_lines.append(f"[教練] {t}")
        input_summary = "\n".join(input_summary_lines)

        # 輸出 JSON 包含所有教練分析
        output_json = {
            "input_transcripts": state.input_transcripts,
            "coach_transcripts": state.coach_transcripts,
            "coaching_updates": state.coaching_updates,
        }

        try:
            async with self._sf() as session:
                row = AnalysisLog(
                    id=generate_cuid(),
                    user_id="anonymous",
                    session_id=state.session_id,
                    feature="voice_coach",
                    input_type="audio",
                    input_summary=input_summary,
                    output_json=output_json,
                    llm_model="gpt-4o-realtime",
                    latency_ms=elapsed_ms,
                    status="success",
                )
                session.add(row)
                await session.commit()
            log.info(
                "voice_coach_log_persisted",
                input_count=len(state.input_transcripts),
                coaching_count=len(state.coaching_updates),
            )
        except Exception as exc:
            log.error("voice_coach_log_persist_failed", error=str(exc))

    # ── 全局清理（應用關閉時呼叫）────────────────────────────

    async def close_all_sessions(self) -> None:
        """關閉所有活躍的語音教練會話。"""
        session_ids = list(self._sessions.keys())
        if not session_ids:
            return

        logger.info("voice_coach_closing_all_sessions", count=len(session_ids))
        await asyncio.gather(
            *(self.close_session(sid) for sid in session_ids),
            return_exceptions=True,
        )
        logger.info("voice_coach_all_sessions_closed")
