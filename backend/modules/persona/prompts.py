"""Persona 沙盒改寫 LLM Prompt

根據用戶的語調設定（emoji 使用量、句子長度、口語程度）
動態組建 system prompt，引導 LLM 改寫訊息。
"""


def build_sandbox_prompt(emoji_usage: float, sentence_length: float, colloquialism: float) -> str:
    """根據語調設定動態組建沙盒改寫 system prompt

    Args:
        emoji_usage: Emoji 使用量（0-100）
        sentence_length: 句子長度偏好（0-100）
        colloquialism: 口語程度（0-100）

    Returns:
        組合完成的 system prompt 字串
    """

    # 解析 emoji 等級描述
    if emoji_usage < 33:
        emoji_desc = "完全不使用 emoji 或表情符號"
    elif emoji_usage < 66:
        emoji_desc = "適度使用 emoji，偶爾加一兩個增添語氣"
    else:
        emoji_desc = "大量使用 emoji 和表情符號，讓訊息充滿活力"

    # 解析句子長度描述
    if sentence_length < 33:
        length_desc = "極度簡短，每句話控制在 5-10 字以內"
    elif sentence_length < 66:
        length_desc = "中等長度，簡潔但完整"
    else:
        length_desc = "詳細表達，可以寫較長的句子"

    # 解析口語程度描述
    if colloquialism < 33:
        tone_desc = "正式書面語，用詞禮貌得體"
    elif colloquialism < 66:
        tone_desc = "日常口語，輕鬆自然"
    else:
        tone_desc = "高度口語化，使用網路用語、縮寫、俚語"

    return f"""你是一個訊息改寫助手。你的任務是把用戶輸入的訊息，用指定的語調風格改寫。

語調設定：
- Emoji 風格：{emoji_desc}
- 句子長度：{length_desc}
- 口語程度：{tone_desc}

規則：
1. 保留原始訊息的核心語意，不要改變意思
2. 只回傳改寫後的訊息文字，不要加任何說明或前綴
3. 用繁體中文回覆
4. 改寫結果必須自然，像真人聊天一樣"""
