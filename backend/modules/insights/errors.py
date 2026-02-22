"""Insights 模組自定義錯誤

定義成長洞察與約會報告操作中可能發生的業務邏輯錯誤。
"""


class InsightsError(Exception):
    """Insights 模組基礎錯誤"""
    pass


class ReportNotFound(InsightsError):
    """找不到指定的約會報告"""
    pass
