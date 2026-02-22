"""搭訕破冰模組的自訂例外類別。"""


class IcebreakerError(Exception):
    """破冰模組的基礎例外類別。"""
    pass


class ImageAnalysisFailed(IcebreakerError):
    """圖片分析失敗時拋出的例外。"""
    pass


class InvalidInputError(IcebreakerError):
    """輸入參數無效時拋出的例外。"""
    pass
