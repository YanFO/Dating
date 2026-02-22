"""回覆教練模組的自訂例外類別。"""


class ReplyError(Exception):
    """回覆模組的基礎例外類別。"""
    pass


class ChatAnalysisFailed(ReplyError):
    """聊天分析失敗時拋出的例外。"""
    pass


class NoInputProvided(ReplyError):
    """未提供任何輸入資料時拋出的例外。"""
    pass
