import asyncio
from dataclasses import dataclass, field
from typing import Optional

import orjson
import structlog
import websockets

from config.constants import WS_OPENAI_CONNECT_TIMEOUT, WS_HEARTBEAT_INTERVAL, WS_HEARTBEAT_TIMEOUT
from modules.voice_coach.errors import OpenAIConnectionFailed, SessionNotFound
from modules.voice_coach.models import VoiceCoachSession
from modules.voice_coach.prompts import VOICE_COACH_SYSTEM_PROMPT
from services.stream_service import StreamService

logger = structlog.get_logger()

OPENAI_REALTIME_URL = "wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview"


@dataclass
class _SessionState:
    session_id: str
    openai_ws: object = None
    listener_task: Optional[asyncio.Task] = None


class VoiceCoachService:
    def __init__(self, api_key: str, stream_service: StreamService):
        self._api_key = api_key
        self._stream = stream_service
        self._sessions: dict[str, _SessionState] = {}

    async def create_session(
        self, session_id: str, request_id: str
    ) -> VoiceCoachSession:
        log = logger.bind(request_id=request_id, session_id=session_id)
        log.info("voice_coach_session_creating")

        headers = {
            "Authorization": f"Bearer {self._api_key}",
            "OpenAI-Beta": "realtime=v1",
        }

        try:
            openai_ws = await asyncio.wait_for(
                websockets.connect(
                    OPENAI_REALTIME_URL,
                    extra_headers=headers,
                    ping_interval=WS_HEARTBEAT_INTERVAL,
                    ping_timeout=WS_HEARTBEAT_TIMEOUT,
                    close_timeout=5,
                ),
                timeout=WS_OPENAI_CONNECT_TIMEOUT,
            )
        except (asyncio.TimeoutError, Exception) as e:
            log.error("openai_ws_connect_failed", error=str(e))
            raise OpenAIConnectionFailed(str(e)) from e

        # Configure the session
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
                        "silence_duration_ms": 500,
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

    async def relay_audio(self, session_id: str, audio_base64: str) -> None:
        state = self._sessions.get(session_id)
        if not state:
            raise SessionNotFound(session_id)
        msg = orjson.dumps(
            {"type": "input_audio_buffer.append", "audio": audio_base64}
        ).decode()
        await state.openai_ws.send(msg)

    async def _listen_openai(self, session_id: str, openai_ws) -> None:
        log = logger.bind(session_id=session_id)
        try:
            async for message in openai_ws:
                event = orjson.loads(message)
                event_type = event.get("type", "")

                if event_type == "response.audio.delta":
                    await self._stream.publish(
                        session_id,
                        {"type": "audio", "payload": event.get("delta", "")},
                    )
                elif event_type == "response.audio_transcript.delta":
                    await self._stream.publish(
                        session_id,
                        {"type": "transcript", "payload": event.get("delta", "")},
                    )
                elif event_type == "response.text.delta":
                    await self._stream.publish(
                        session_id,
                        {"type": "suggestion", "payload": event.get("delta", "")},
                    )
                elif event_type == "response.done":
                    await self._stream.publish(
                        session_id, {"type": "response_complete"}
                    )
                elif event_type == "input_audio_buffer.speech_started":
                    await self._stream.publish(
                        session_id, {"type": "speech_started"}
                    )
                elif event_type == "input_audio_buffer.speech_stopped":
                    await self._stream.publish(
                        session_id, {"type": "speech_stopped"}
                    )
                elif event_type == "error":
                    log.error("openai_realtime_error", error=event.get("error"))
                    await self._stream.publish(
                        session_id,
                        {"type": "error", "payload": event.get("error", {})},
                    )
        except websockets.ConnectionClosed as e:
            log.warning("openai_ws_closed", code=e.code)
            await self._stream.publish(session_id, {"type": "disconnected"})
        except Exception as e:
            log.error("openai_listener_error", error=str(e))
            await self._stream.publish(
                session_id, {"type": "error", "payload": {"message": str(e)}}
            )

    async def close_session(self, session_id: str) -> None:
        state = self._sessions.pop(session_id, None)
        if not state:
            return
        log = logger.bind(session_id=session_id)
        log.info("voice_coach_session_closing")
        if state.listener_task and not state.listener_task.done():
            state.listener_task.cancel()
        if state.openai_ws:
            try:
                await state.openai_ws.close()
            except Exception:
                pass
        log.info("voice_coach_session_closed")
