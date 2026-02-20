import asyncio
from concurrent.futures import ThreadPoolExecutor
from functools import partial
from typing import Any, Callable, Coroutine, Sequence

_executor = ThreadPoolExecutor(max_workers=4)


async def run_in_executor(func: Callable, *args: Any) -> Any:
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(_executor, partial(func, *args))


async def gather_with_timeout(
    coros: Sequence[Coroutine], timeout: float
) -> list[Any]:
    return await asyncio.wait_for(
        asyncio.gather(*coros, return_exceptions=True),
        timeout=timeout,
    )
