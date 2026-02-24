"""Match 領域模型

定義約會管線（Active Pipeline）中的 Match 與 MatchMemory 資料結構。
"""

from dataclasses import asdict, dataclass, field
from typing import Optional


@dataclass
class MatchRecord:
    """單筆約會對象記錄"""

    match_id: str
    user_id: str
    name: str
    context_tag: Optional[str] = None
    status: str = "active"
    created_at: str = ""
    updated_at: str = ""

    def to_dict(self) -> dict:
        """轉換為 dict 供 API 回傳使用"""
        return asdict(self)


# ─── Memory Profile 所有 JSONB 欄位名稱 ─────────

MEMORY_LIST_FIELDS = [
    "anniversaries", "routine",
    "favorite_food", "favorite_restaurant", "disliked_food",
    "dietary_restrictions", "beverage_customization",
    "favorite_places", "travel_wishlist", "hobbies", "entertainment_tastes",
    "landmines", "pet_peeves", "soothing_methods", "love_languages",
    "wishlist", "favorite_brands", "aesthetic_preference",
    "other_notes",
]

MEMORY_STRING_FIELDS = ["birthday", "mbti_or_zodiac"]


@dataclass
class MemoryProfile:
    """每個約會對象的結構化記憶檔案（一對一綁定 Match）"""

    memory_id: str
    user_id: str
    match_id: str
    # 1. 基本資訊與重要節日
    birthday: Optional[str] = None
    anniversaries: list = field(default_factory=list)
    mbti_or_zodiac: Optional[str] = None
    routine: list = field(default_factory=list)
    # 2. 飲食偏好
    favorite_food: list = field(default_factory=list)
    favorite_restaurant: list = field(default_factory=list)
    disliked_food: list = field(default_factory=list)
    dietary_restrictions: list = field(default_factory=list)
    beverage_customization: list = field(default_factory=list)
    # 3. 地點與休閒娛樂
    favorite_places: list = field(default_factory=list)
    travel_wishlist: list = field(default_factory=list)
    hobbies: list = field(default_factory=list)
    entertainment_tastes: list = field(default_factory=list)
    # 4. 情感地雷與情緒撫慰
    landmines: list = field(default_factory=list)
    pet_peeves: list = field(default_factory=list)
    soothing_methods: list = field(default_factory=list)
    love_languages: list = field(default_factory=list)
    # 5. 物質與送禮
    wishlist: list = field(default_factory=list)
    favorite_brands: list = field(default_factory=list)
    aesthetic_preference: list = field(default_factory=list)
    # 6. 其他
    other_notes: list = field(default_factory=list)
    created_at: str = ""
    updated_at: str = ""

    def to_dict(self) -> dict:
        """轉換為 dict 供 API 回傳使用"""
        return asdict(self)


@dataclass
class ChatImportResult:
    """聊天記錄匯入分析結果"""

    match: MatchRecord
    memory: MemoryProfile
    relationship_stage: str = "early"
