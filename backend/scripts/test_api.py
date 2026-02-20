"""Test icebreaker (girl images) and reply (chat screenshots) APIs with real images.

Sends all 6 images to the respective endpoints and saves responses as JSON.

Usage:
    python scripts/test_api.py
"""

import asyncio
import base64
import json
import os
import sys
import time

import httpx

BASE_URL = "http://localhost:8000"
DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
OUTPUT_DIR = os.path.join(DATA_DIR, "results")


def load_image_base64(filename: str) -> str:
    path = os.path.join(DATA_DIR, filename)
    with open(path, "rb") as f:
        raw = f.read()
    b64 = base64.b64encode(raw).decode()
    return f"data:image/jpeg;base64,{b64}"


async def test_icebreaker(client: httpx.AsyncClient, image_file: str, index: int) -> dict:
    print(f"[icebreaker] Sending {image_file}...")
    image_b64 = load_image_base64(image_file)
    start = time.time()
    resp = await client.post(
        f"{BASE_URL}/api/v1/icebreaker/analyze",
        json={"image_base64": image_b64, "scene_description": ""},
        timeout=120.0,
    )
    elapsed = time.time() - start
    data = resp.json()
    data["_meta"] = {
        "source_image": image_file,
        "status_code": resp.status_code,
        "elapsed_seconds": round(elapsed, 2),
    }
    print(f"[icebreaker] {image_file} done in {elapsed:.1f}s (status={resp.status_code})")
    return data


async def test_reply(client: httpx.AsyncClient, image_file: str, index: int) -> dict:
    print(f"[reply] Sending {image_file}...")
    image_b64 = load_image_base64(image_file)
    start = time.time()
    resp = await client.post(
        f"{BASE_URL}/api/v1/reply/analyze",
        json={"screenshot_base64": image_b64},
        timeout=120.0,
    )
    elapsed = time.time() - start
    data = resp.json()
    data["_meta"] = {
        "source_image": image_file,
        "status_code": resp.status_code,
        "elapsed_seconds": round(elapsed, 2),
    }
    print(f"[reply] {image_file} done in {elapsed:.1f}s (status={resp.status_code})")
    return data


def save_json(data: dict, filename: str):
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    path = os.path.join(OUTPUT_DIR, filename)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"[saved] {path}")


async def main():
    async with httpx.AsyncClient() as client:
        # Run all 6 requests concurrently
        tasks = [
            test_icebreaker(client, "girl_1.jpg", 1),
            test_icebreaker(client, "girl_2.jpg", 2),
            test_icebreaker(client, "girl_3.jpg", 3),
            test_reply(client, "chat_1.jpg", 1),
            test_reply(client, "chat_2.jpg", 2),
            test_reply(client, "chat_3.jpg", 3),
        ]
        results = await asyncio.gather(*tasks, return_exceptions=True)

    # Save individual results
    filenames = [
        "icebreaker_girl_1.json",
        "icebreaker_girl_2.json",
        "icebreaker_girl_3.json",
        "reply_chat_1.json",
        "reply_chat_2.json",
        "reply_chat_3.json",
    ]
    for result, fname in zip(results, filenames):
        if isinstance(result, Exception):
            save_json({"error": str(result)}, fname)
        else:
            save_json(result, fname)

    # Save combined summary
    summary = {}
    for result, fname in zip(results, filenames):
        key = fname.replace(".json", "")
        if isinstance(result, Exception):
            summary[key] = {"success": False, "error": str(result)}
        else:
            summary[key] = {
                "success": result.get("success", False),
                "status_code": result.get("_meta", {}).get("status_code"),
                "elapsed_seconds": result.get("_meta", {}).get("elapsed_seconds"),
            }
    save_json(summary, "summary.json")
    print("\nAll tests complete!")


if __name__ == "__main__":
    asyncio.run(main())
