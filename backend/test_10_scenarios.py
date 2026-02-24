"""10 種情境 API 測試 - 對應通用情境偵測規則 + 各階段策略"""
import asyncio
import httpx
import json
import time

BASE_URL = "http://localhost:9999/api/reply/analyze"

SCENARIOS = [
    # === 通用情境規則測試 ===
    {
        "name": "1. 外貌焦慮",
        "payload": {
            "chat_text": "女：我最近胖了好多，臉都圓了，好醜喔😭",
            "relationship_stage": "couple",
            "user_gender": "male",
            "target_gender": "female",
            "language": "zh-TW",
        },
    },
    {
        "name": "2. 情緒抒發（抱怨工作）",
        "payload": {
            "chat_text": "女：今天主管又在那邊針對我，明明是別人的錯結果怪到我頭上，真的快氣死",
            "relationship_stage": "flirting",
            "user_gender": "male",
            "target_gender": "female",
            "language": "zh-TW",
        },
    },
    {
        "name": "3. 反話偵測 — 情緒冰點",
        "payload": {
            "chat_text": "男：今天要不要出去？\n女：隨便你\n男：怎麼了嗎？\n女：沒事",
            "relationship_stage": "couple",
            "user_gender": "male",
            "target_gender": "female",
            "language": "zh-TW",
        },
    },
    {
        "name": "4. 反話偵測 — 選擇障礙",
        "payload": {
            "chat_text": "男：週末想去哪吃飯？\n女：都可以啊，看你",
            "relationship_stage": "flirting",
            "user_gender": "male",
            "target_gender": "female",
            "language": "zh-TW",
        },
    },
    {
        "name": "5. 異性求生慾測試",
        "payload": {
            "chat_text": "女：欸你覺得我朋友小美漂亮嗎？她今天穿得超辣的",
            "relationship_stage": "couple",
            "user_gender": "male",
            "target_gender": "female",
            "language": "zh-TW",
        },
    },
    {
        "name": "6. 隱性需求表達",
        "payload": {
            "chat_text": "女：今天加班到現在好累喔，脖子超痠的",
            "relationship_stage": "couple",
            "user_gender": "male",
            "target_gender": "female",
            "language": "zh-TW",
        },
    },
    {
        "name": "7. 消費認同測試",
        "payload": {
            "chat_text": "女：[傳了一張包包的照片] 你覺得這個好看嗎？有點想買但又覺得有點貴",
            "relationship_stage": "flirting",
            "user_gender": "male",
            "target_gender": "female",
            "language": "zh-TW",
        },
    },
    # === 聊天初期策略測試 ===
    {
        "name": "8. 初期破冰 — 順應話題讓對方分享",
        "payload": {
            "chat_text": "女：我週末去爬了象山，風景超美的！",
            "relationship_stage": "early",
            "user_gender": "male",
            "target_gender": "female",
            "language": "zh-TW",
        },
    },
    {
        "name": "9. 初期 — 廢物測試應對",
        "payload": {
            "chat_text": "女：你是不是對每個女生都這樣講話啊？",
            "relationship_stage": "early",
            "user_gender": "male",
            "target_gender": "female",
            "language": "zh-TW",
        },
    },
    {
        "name": "10. 衝突降溫（翻舊帳）",
        "payload": {
            "chat_text": "女：你每次都這樣！上次也是說好了又放我鴿子，你到底有沒有把我放在心上？",
            "relationship_stage": "couple",
            "user_gender": "male",
            "target_gender": "female",
            "language": "zh-TW",
        },
    },
]


async def test_scenario(client: httpx.AsyncClient, scenario: dict) -> dict:
    name = scenario["name"]
    print(f"\n{'='*60}")
    print(f"🔹 {name}")
    print(f"  輸入：{scenario['payload']['chat_text'][:60]}...")
    print(f"  階段：{scenario['payload']['relationship_stage']}")

    start = time.time()
    try:
        resp = await client.post(BASE_URL, json=scenario["payload"], timeout=120)
        elapsed = time.time() - start
        data = resp.json()

        if not data.get("success"):
            print(f"  ❌ 失敗: {data.get('error', 'unknown')}")
            return {"name": name, "success": False, "error": str(data.get("error")), "elapsed": elapsed}

        result = data["data"]
        emotion = result.get("emotion_analysis", {})
        replies = result.get("reply_options", [])
        coach = result.get("coach_panel", {})
        stage = result.get("stage_coaching", {})

        print(f"  ⏱  {elapsed:.1f}s")
        print(f"  🎭 情緒：{emotion.get('detected_emotion', 'N/A')}")
        print(f"  💬 潛台詞：{emotion.get('subtext', 'N/A')[:80]}...")
        print(f"  📊 信心：{emotion.get('confidence', 'N/A')}")
        print(f"  💡 技巧：{stage.get('technique_used', 'N/A')}")
        print(f"  ---回覆選項---")
        for i, r in enumerate(replies, 1):
            print(f"    [{i}] {r.get('text', 'N/A')}")
            print(f"        意圖：{r.get('intent', '')} | 技巧：{r.get('framework_technique', '')}")
        print(f"  ---教練建議---")
        print(f"    觀點：{coach.get('perspective_note', 'N/A')[:80]}")
        print(f"    DO：{coach.get('dos', [])}")
        print(f"    DON'T：{coach.get('donts', [])}")

        return {"name": name, "success": True, "elapsed": elapsed, "data": result}

    except Exception as e:
        elapsed = time.time() - start
        print(f"  ❌ 例外: {e}")
        return {"name": name, "success": False, "error": str(e), "elapsed": elapsed}


async def main():
    print("=" * 60)
    print("Dating Lens — 10 情境 API 測試")
    print("=" * 60)

    total_start = time.time()
    results = []

    async with httpx.AsyncClient() as client:
        for scenario in SCENARIOS:
            result = await test_scenario(client, scenario)
            results.append(result)

    total_elapsed = time.time() - total_start

    # Summary
    print("\n" + "=" * 60)
    print("📋 測試總結")
    print("=" * 60)
    success_count = sum(1 for r in results if r["success"])
    print(f"  通過：{success_count}/{len(results)}")
    print(f"  總耗時：{total_elapsed:.1f}s")
    print(f"  平均耗時：{total_elapsed/len(results):.1f}s")
    print()
    for r in results:
        status = "✅" if r["success"] else "❌"
        print(f"  {status} {r['name']} ({r['elapsed']:.1f}s)")

    # Save results
    with open("/home/ubuntu/Dating_Lens/backend/data/results/test_10_scenarios.json", "w") as f:
        json.dump(results, f, ensure_ascii=False, indent=2, default=str)
    print(f"\n結果已儲存至 data/results/test_10_scenarios.json")


if __name__ == "__main__":
    asyncio.run(main())
