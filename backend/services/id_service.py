import uuid


def generate_request_id() -> str:
    return str(uuid.uuid4())


def generate_session_id() -> str:
    return f"sess_{uuid.uuid4().hex[:16]}"


def generate_job_id() -> str:
    return f"job_{uuid.uuid4().hex[:16]}"
