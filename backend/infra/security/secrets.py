import os


def get_secret(key: str) -> str:
    value = os.environ.get(key, "")
    if not value:
        raise ValueError(f"Secret '{key}' is not set")
    return value


def redact(value: str) -> str:
    if len(value) <= 8:
        return "****"
    return value[:4] + "****" + value[-4:]
