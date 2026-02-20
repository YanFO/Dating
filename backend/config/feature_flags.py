from dataclasses import dataclass


@dataclass
class FeatureFlags:
    ENABLE_MOCK_MODE: bool = False
    ENABLE_VOICE_COACH: bool = True
