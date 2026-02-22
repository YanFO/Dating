"""WebSocket 路由模块，提供健康检查和语音教练实时通信端点。"""

import asyncio

import orjson
import structlog
from quart import Quart, websocket

from services.id_service import generate_request_id

logger = structlog.get_logger()


def register_websocket_routes(app: Quart) -> None:
    """注册所有 WebSocket 路由到应用实例。"""

    @app.websocket("/ws/health")
    async def ws_health():
        """WebSocket 健康检查，收到消息后回复 pong。"""
        data = await websocket.receive()
        await websocket.send("pong")

    @app.websocket("/ws/voice-coach/<session_id>")
    async def voice_coach_ws(session_id: str):
        """语音教练 WebSocket 端点，中继客户端音频到 OpenAI 并推送实时反馈。"""
        request_id = generate_request_id()
        log = logger.bind(request_id=request_id, session_id=session_id)

        voice_service = app.config.get("voice_coach_service")
        stream_service = app.config.get("stream_service")

        if not voice_service or not stream_service:
            await websocket.send(
                orjson.dumps(
                    {"type": "error", "payload": {"message": "Voice coach not enabled"}}
                ).decode()
            )
            return

        log.info("voice_coach_ws_connected")

        session = await voice_service.create_session(session_id, request_id)

        queue = await stream_service.subscribe(session_id)

        await websocket.send(
            orjson.dumps(
                {
                    "type": "session_ready",
                    "session_id": session_id,
                    "request_id": request_id,
                }
            ).decode()
        )

        audio_chunk_count = 0

        async def client_to_openai():
            """接收客户端音频消息并转发到 OpenAI 服务。"""
            nonlocal audio_chunk_count
            while True:
                raw = await websocket.receive()
                msg = orjson.loads(raw)
                msg_type = msg.get("type", "")
                if msg_type == "audio":
                    audio_chunk_count += 1
                    payload = msg.get("payload", "")
                    if audio_chunk_count <= 3 or audio_chunk_count % 50 == 0:
                        log.info(
                            "ws_audio_chunk_received",
                            chunk_num=audio_chunk_count,
                            payload_len=len(payload),
                        )
                    await voice_service.relay_audio(session_id, payload)
                elif msg_type == "close":
                    log.info("ws_client_close_requested")
                    break
                else:
                    log.info("ws_unknown_msg_type", msg_type=msg_type)

        async def openai_to_client():
            """从队列读取 OpenAI 事件并推送给客户端。"""
            while True:
                event = await asyncio.wait_for(queue.get(), timeout=60.0)
                event_type = event.get("type", "")
                # 音訊 delta 量大，不逐筆記錄
                if event_type != "audio":
                    log.info("ws_event_to_client", event_type=event_type)
                await websocket.send(orjson.dumps(event).decode())
                if event_type in ("disconnected", "error"):
                    break

        try:
            await asyncio.gather(client_to_openai(), openai_to_client())
        except asyncio.TimeoutError:
            log.warning("ws_queue_timeout", audio_chunks_received=audio_chunk_count)
        except Exception as exc:
            log.error("ws_unexpected_error", error=str(exc), audio_chunks_received=audio_chunk_count)
        finally:
            log.info(
                "voice_coach_ws_closing",
                total_audio_chunks=audio_chunk_count,
            )
            await stream_service.unsubscribe(session_id, queue)
            await voice_service.close_session(session_id)
            log.info("voice_coach_ws_disconnected")
