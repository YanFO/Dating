"""功能开关模块，集中管理各功能的启用与禁用状态。"""

from dataclasses import dataclass


@dataclass
class FeatureFlags:
    """功能开关配置，控制模拟模式、语音教练、Love Coach 等功能的启停。"""
    ENABLE_MOCK_MODE: bool = False
    ENABLE_VOICE_COACH: bool = True
    ENABLE_LOVE_COACH: bool = True
