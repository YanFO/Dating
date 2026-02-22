"""語音教練模組的自訂例外類別。"""


class VoiceCoachError(Exception):
    """語音教練模組的基礎例外類別。"""
    pass


class SessionNotFound(VoiceCoachError):
    """找不到指定的會話時拋出的例外。"""
    pass


class OpenAIConnectionFailed(VoiceCoachError):
    """無法連線至 OpenAI Realtime API 時拋出的例外。"""
    pass


class AudioFormatError(VoiceCoachError):
    """音訊格式不正確時拋出的例外。"""
    pass
