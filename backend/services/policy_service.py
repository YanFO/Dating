from config.feature_flags import FeatureFlags


class PolicyService:
    def __init__(self, flags: FeatureFlags):
        self._flags = flags

    def is_feature_enabled(self, flag_name: str) -> bool:
        return getattr(self._flags, flag_name, False)
