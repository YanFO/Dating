import structlog

logger = structlog.get_logger()

_JOB_TYPES: dict[str, callable] = {}


def register_job_type(name: str, handler: callable) -> None:
    _JOB_TYPES[name] = handler
    logger.debug("job_type_registered", name=name)


def get_job_handler(name: str) -> callable:
    handler = _JOB_TYPES.get(name)
    if not handler:
        raise ValueError(f"Unknown job type: {name}")
    return handler
