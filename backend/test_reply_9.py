"""Test script: 3 chat images × 3 relationship stages = 9 API calls."""

import asyncio
import base64
import json
import time
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from config.settings import load_settings
from config.feature_flags import FeatureFlags
from modules.reply.service import ReplyService
from modules.reply.models import ReplyRequest
from clients.llm.gemini_client import GeminiClient
from clients.llm.openai_client import OpenAIClient


CHAT_IMAGES = [
    Path("data/chat_1.jpg"),
    Path("data/chat_2.jpg"),
    Path("data/chat_3.jpg"),
]

STAGES = ["early", "flirting", "couple"]

OUTPUT_DIR = Path("data/results")


def load_image_base64(path: Path) -> str:
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode()


async def main():
    settings = load_settings()
    flags = FeatureFlags(ENABLE_MOCK_MODE=False)

    gemini_client = GeminiClient(
        api_key=settings.GOOGLE_API_KEY,
        model=settings.GOOGLE_GEMINI_MODEL or "gemini-3-pro-preview",
    )
    openai_client = OpenAIClient(
        api_key=settings.OPENAI_API_KEY,
        model=settings.OPENAI_MODEL or "gpt-4o",
    )
    service = ReplyService(gemini_client, flags, fallback_client=openai_client)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    results_summary = []

    for img_path in CHAT_IMAGES:
        img_name = img_path.stem  # chat_1, chat_2, chat_3
        img_b64 = load_image_base64(img_path)

        for stage in STAGES:
            label = f"{img_name} × {stage}"
            print(f"\n{'='*60}")
            print(f"Testing: {label}")
            print(f"{'='*60}")

            request = ReplyRequest(
                screenshot_base64=img_b64,
                language="zh-TW",
                relationship_stage=stage,
            )

            request_id = f"test-{img_name}-{stage}"
            start = time.time()

            try:
                response = await service.analyze(request, request_id)
                elapsed = time.time() - start

                result = {
                    "success": True,
                    "data": response.to_dict(),
                    "error": None,
                    "request_id": request_id,
                    "_meta": {
                        "source_image": img_path.name,
                        "stage": stage,
                        "elapsed_seconds": round(elapsed, 2),
                    },
                }

                # Print reply texts and their lengths
                print(f"\n  Stage: {stage} | Time: {elapsed:.1f}s")
                for i, opt in enumerate(response.reply_options):
                    text_len = len(opt.text)
                    marker = "✓" if text_len <= 50 else "✗"
                    print(f"  {marker} Option {i+1} ({text_len} chars) [{opt.framework_technique}]: {opt.text}")

                results_summary.append({
                    "label": label,
                    "elapsed": round(elapsed, 2),
                    "num_options": len(response.reply_options),
                    "max_text_len": max(len(o.text) for o in response.reply_options),
                })

            except Exception as e:
                elapsed = time.time() - start
                result = {
                    "success": False,
                    "data": None,
                    "error": str(e),
                    "request_id": request_id,
                    "_meta": {
                        "source_image": img_path.name,
                        "stage": stage,
                        "elapsed_seconds": round(elapsed, 2),
                    },
                }
                print(f"  ERROR: {e}")

            # Save individual result
            out_file = OUTPUT_DIR / f"reply_{img_name}_{stage}.json"
            with open(out_file, "w", encoding="utf-8") as f:
                json.dump(result, f, ensure_ascii=False, indent=2)
            print(f"  Saved: {out_file}")

    # Print summary
    print(f"\n\n{'='*60}")
    print("SUMMARY")
    print(f"{'='*60}")
    for r in results_summary:
        print(f"  {r['label']:25s} | {r['elapsed']:5.1f}s | {r['num_options']} options | max_len={r['max_text_len']}")


if __name__ == "__main__":
    asyncio.run(main())
