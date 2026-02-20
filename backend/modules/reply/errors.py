class ReplyError(Exception):
    pass


class ChatAnalysisFailed(ReplyError):
    pass


class NoInputProvided(ReplyError):
    pass
