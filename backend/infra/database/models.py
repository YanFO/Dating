"""PostgreSQL ORM 模型定義

與 prisma/schema.prisma 完全對齊的 SQLAlchemy 模型。
主鍵統一使用 CUID 字串格式（由應用層生成）。

資料表：
- users: 用戶帳號
- user_personas: 數位人格（語調滑桿）
- matches: 約會管線
- date_reports: 約會報告（含雷達圖快照）
- love_coach_conversations: Love Coach 聊天對話
- love_coach_messages: Love Coach 聊天訊息
- sessions: 分析 session
- analysis_logs: 請求/回應日誌
- jobs: 非同步任務追蹤
"""

from datetime import datetime

from sqlalchemy import DateTime, Float, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    """SQLAlchemy 宣告式基類"""
    pass


# ─── 用戶帳號 ─────────────────────────────────────

class User(Base):
    """用戶帳號模型"""
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(30), primary_key=True)             # 主鍵，CUID 格式
    email: Mapped[str | None] = mapped_column(String(255), unique=True, nullable=True)  # 電子郵件
    display_name: Mapped[str | None] = mapped_column(String(128), nullable=True)        # 顯示名稱
    role: Mapped[str] = mapped_column(String(32), default="user")             # 角色：user / admin
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()                    # 建立時間
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()  # 最後更新時間
    )


# ─── 數位人格（Profile 頁 AI Clone + 語調滑桿）─────

class UserPersona(Base):
    """數位人格模型，儲存 AI 分身語調設定"""
    __tablename__ = "user_personas"

    id: Mapped[str] = mapped_column(String(30), primary_key=True)             # 主鍵，CUID 格式
    user_id: Mapped[str] = mapped_column(String(30), unique=True, nullable=False, index=True)  # 所屬用戶 ID
    sync_pct: Mapped[float] = mapped_column(Float, default=0)                # AI 同步百分比 0-100
    emoji_usage: Mapped[float] = mapped_column(Float, default=50)            # Emoji 使用量 0-100
    sentence_length: Mapped[float] = mapped_column(Float, default=50)        # 句子長度偏好 0-100
    colloquialism: Mapped[float] = mapped_column(Float, default=50)          # 口語程度 0-100
    training_files: Mapped[dict | None] = mapped_column(JSONB, default=list)  # 訓練檔案 JSON 陣列
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()                    # 建立時間
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()  # 最後更新時間
    )


# ─── Match 管線（Home 頁 Active Pipeline）─────────

class Match(Base):
    """約會管線模型，記錄 Active Pipeline 中的對象"""
    __tablename__ = "matches"

    id: Mapped[str] = mapped_column(String(30), primary_key=True)             # 主鍵，CUID 格式
    user_id: Mapped[str] = mapped_column(String(30), nullable=False, index=True)  # 所屬用戶 ID
    name: Mapped[str] = mapped_column(String(128), nullable=False)            # 對方姓名或暱稱
    context_tag: Mapped[str | None] = mapped_column(String(128), nullable=True)  # 場景標籤
    status: Mapped[str] = mapped_column(String(32), default="active")         # 狀態：active / archived
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()                    # 建立時間
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()  # 最後更新時間
    )


# ─── 約會報告（Insights 頁雷達圖 + Post-Date Report）

class DateReport(Base):
    """約會報告模型，含 6 維技能快照與回饋"""
    __tablename__ = "date_reports"

    id: Mapped[str] = mapped_column(String(30), primary_key=True)             # 主鍵，CUID 格式
    user_id: Mapped[str] = mapped_column(String(30), nullable=False, index=True)  # 所屬用戶 ID
    session_id: Mapped[str | None] = mapped_column(String(30), nullable=True)  # 關聯 session ID
    score: Mapped[int] = mapped_column(Integer, nullable=False)               # 總分 0-100
    skills: Mapped[dict | None] = mapped_column(JSONB, default=dict)          # 6 維技能快照 JSON
    good_points: Mapped[dict | None] = mapped_column(JSONB, default=list)     # 做得好的項目 string[]
    to_improve: Mapped[dict | None] = mapped_column(JSONB, default=list)      # 待改進項目 string[]
    action_items: Mapped[dict | None] = mapped_column(JSONB, default=list)    # 行動建議 string[]
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()                    # 建立時間
    )


# ─── Love Coach 對話（全域聊天面板）──────────────

class LoveCoachConversation(Base):
    """Love Coach 對話模型，儲存使用者與 AI 教練的聊天會話"""
    __tablename__ = "love_coach_conversations"

    id: Mapped[str] = mapped_column(String(30), primary_key=True)             # 主鍵，CUID 格式
    user_id: Mapped[str] = mapped_column(String(30), nullable=False, index=True)  # 所屬用戶 ID
    title: Mapped[str | None] = mapped_column(String(256), nullable=True)     # 對話標題（從首則訊息自動擷取）
    status: Mapped[str] = mapped_column(String(32), default="active")         # 狀態：active / archived
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()                    # 建立時間
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()  # 最後更新時間
    )


class LoveCoachMessage(Base):
    """Love Coach 訊息模型，儲存對話中的每則訊息"""
    __tablename__ = "love_coach_messages"

    id: Mapped[str] = mapped_column(String(30), primary_key=True)             # 主鍵，CUID 格式
    conversation_id: Mapped[str] = mapped_column(String(30), nullable=False, index=True)  # 所屬對話 ID
    role: Mapped[str] = mapped_column(String(16), nullable=False)             # 角色：user / model
    text: Mapped[str] = mapped_column(Text, nullable=False)                   # 訊息內容
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()                    # 建立時間
    )


# ─── 分析 Session ─────────────────────────────────

class Session(Base):
    """分析 session 模型，記錄各功能的使用會話"""
    __tablename__ = "sessions"

    id: Mapped[str] = mapped_column(String(30), primary_key=True)             # 主鍵，CUID 格式
    user_id: Mapped[str] = mapped_column(String(30), nullable=False, index=True)  # 所屬用戶 ID
    feature: Mapped[str] = mapped_column(String(32), nullable=False)          # 功能：icebreaker / reply / voice_coach
    status: Mapped[str] = mapped_column(String(32), default="active")         # 狀態：active / completed
    metadata_json: Mapped[dict | None] = mapped_column(JSONB, nullable=True)  # 額外元數據
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()                    # 建立時間
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()  # 最後更新時間
    )


# ─── 分析日誌 ─────────────────────────────────────

class AnalysisLog(Base):
    """分析日誌模型，記錄每次 LLM 請求的輸入/輸出"""
    __tablename__ = "analysis_logs"

    id: Mapped[str] = mapped_column(String(30), primary_key=True)             # 主鍵，CUID 格式
    user_id: Mapped[str] = mapped_column(String(30), nullable=False, index=True)  # 所屬用戶 ID
    session_id: Mapped[str | None] = mapped_column(String(64), nullable=True)  # 關聯 session ID（UUID 36 字元）
    feature: Mapped[str] = mapped_column(String(32), nullable=False)          # 功能類型
    input_type: Mapped[str] = mapped_column(String(32), nullable=False)       # 輸入類型：text / image / screenshot
    input_summary: Mapped[str | None] = mapped_column(Text, nullable=True)    # 輸入摘要
    output_json: Mapped[dict | None] = mapped_column(JSONB, nullable=True)    # LLM 回應 JSON
    llm_model: Mapped[str | None] = mapped_column(String(64), nullable=True)  # LLM 模型名稱
    latency_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)    # 請求耗時 ms
    status: Mapped[str] = mapped_column(String(32), default="success")        # 狀態：success / error
    error_message: Mapped[str | None] = mapped_column(Text, nullable=True)    # 錯誤訊息
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()                    # 建立時間
    )


# ─── 非同步任務 ───────────────────────────────────

class Job(Base):
    """非同步任務模型，追蹤任務狀態與結果"""
    __tablename__ = "jobs"

    id: Mapped[str] = mapped_column(String(30), primary_key=True)             # 主鍵，CUID 格式
    user_id: Mapped[str | None] = mapped_column(String(30), nullable=True, index=True)  # 所屬用戶 ID
    job_type: Mapped[str] = mapped_column(String(64), nullable=False)         # 任務類型
    status: Mapped[str] = mapped_column(
        String(32), default="PENDING", index=True                             # PENDING / RUNNING / SUCCEEDED / FAILED
    )
    progress: Mapped[int] = mapped_column(Integer, default=0)                 # 進度 0-100
    payload_json: Mapped[dict | None] = mapped_column(JSONB, nullable=True)   # 輸入參數 JSON
    result_json: Mapped[dict | None] = mapped_column(JSONB, nullable=True)    # 結果 JSON
    error_summary: Mapped[str | None] = mapped_column(Text, nullable=True)    # 錯誤摘要
    retry_count: Mapped[int] = mapped_column(Integer, default=0)              # 已重試次數
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()                    # 建立時間
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()  # 最後更新時間
    )
