"""Love Coach 模組的自訂例外類別

定義 Love Coach 聊天服務中可能拋出的錯誤類型，
用於服務層與路由層之間的錯誤傳遞。
"""


class LoveCoachError(Exception):
    """Love Coach 模組的基礎例外類別"""
    pass


class InvalidMessageError(LoveCoachError):
    """訊息內容為空或無效時拋出"""
    pass


class ConversationNotFoundError(LoveCoachError):
    """指定的對話 ID 不存在時拋出"""
    pass
