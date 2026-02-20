"""Batch job runner CLI.

Usage:
    python job_runner.py --job-type <type> --payload '{"key": "value"}'
"""

import argparse
import asyncio
import json

import structlog

from config.settings import load_settings
from config.logging import setup_logging

logger = structlog.get_logger()


async def run_job(job_type: str, payload: dict):
    logger.info("job_runner_start", job_type=job_type)
    # Skeleton: will be connected to job executor in future
    logger.info("job_runner_complete", job_type=job_type, status="SUCCEEDED")


def main():
    parser = argparse.ArgumentParser(description="Dating Lens Job Runner")
    parser.add_argument("--job-type", required=True, help="Job type to execute")
    parser.add_argument("--payload", default="{}", help="JSON payload")
    args = parser.parse_args()

    settings = load_settings()
    setup_logging(settings)

    payload = json.loads(args.payload)
    asyncio.run(run_job(args.job_type, payload))


if __name__ == "__main__":
    main()
