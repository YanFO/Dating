class VoiceCoachError(Exception):
    pass


class SessionNotFound(VoiceCoachError):
    pass


class OpenAIConnectionFailed(VoiceCoachError):
    pass


class AudioFormatError(VoiceCoachError):
    pass
