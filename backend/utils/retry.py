import asyncio
import functools
import random
from typing import Tuple, Type


def async_retry(
    max_attempts: int = 3,
    backoff_base: float = 1.0,
    jitter: bool = True,
    retry_on: Tuple[Type[BaseException], ...] = (Exception,),
):
    def decorator(func):
        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            last_exc = None
            for attempt in range(max_attempts):
                try:
                    return await func(*args, **kwargs)
                except retry_on as e:
                    last_exc = e
                    if attempt < max_attempts - 1:
                        delay = backoff_base * (2**attempt)
                        if jitter:
                            delay *= 0.5 + random.random()
                        await asyncio.sleep(delay)
            raise last_exc

        return wrapper

    return decorator
