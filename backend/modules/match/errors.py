"""Match 模組自定義錯誤

定義 Match 管線操作中可能發生的業務邏輯錯誤。
"""


class MatchError(Exception):
    """Match 模組基礎錯誤"""
    pass


class MatchNotFound(MatchError):
    """找不到指定的 match 記錄"""
    pass


class InvalidMatchInput(MatchError):
    """Match 輸入資料不合法"""
    pass


class MemoryNotFound(MatchError):
    """找不到指定的 match memory 記錄"""
    pass
