"""Persona 模組自定義錯誤

定義數位人格操作中可能發生的業務邏輯錯誤。
"""


class PersonaError(Exception):
    """Persona 模組基礎錯誤"""
    pass


class PersonaNotFound(PersonaError):
    """找不到指定用戶的人格設定"""
    pass
