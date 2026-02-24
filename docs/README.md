# Dating Lens - 功能實現技術文件

## 目錄

- [專案概覽](#專案概覽)
- [技術棧](#技術棧)
- [系統架構](#系統架構)
- [功能一：Icebreaker Coach（破冰教練）](#功能一icebreaker-coach破冰教練)
- [功能二：Reply Coach（回覆教練）](#功能二reply-coach回覆教練)
- [功能三：Voice Coach（即時語音教練）](#功能三voice-coach即時語音教練)
- [功能四：Love Coach（戀愛教練聊天）](#功能四love-coach戀愛教練聊天)
- [功能五：Persona（個人化 AI 風格）](#功能五persona個人化-ai-風格)
- [功能六：Insights（數據分析儀表板）](#功能六insights數據分析儀表板)
- [功能七：Match Pipeline（配對管理）](#功能七match-pipeline配對管理)
- [狀態管理](#狀態管理)
- [網路層](#網路層)
- [資料庫設計](#資料庫設計)
- [國際化](#國際化)
- [主題與設計系統](#主題與設計系統)

---

## 專案概覽

Dating Lens 是一款 AI 驅動的約會教練應用程式，透過多種 LLM（大型語言模型）整合，為使用者提供即時的社交與約會建議。應用程式涵蓋場景分析、聊天回覆建議、即時語音教練、戀愛諮詢聊天、個人化 AI 風格設定、績效分析等功能。

### 專案結構

```
Dating_Lens/
├── flutter/                    # Flutter 前端應用（跨平台：iOS / Android / Web）
│   └── lib/
│       ├── core/               # 基礎設施與設定
│       │   ├── audio/          # 音訊錄製抽象層（Native + Web）
│       │   ├── config/         # API 與應用設定
│       │   ├── constants/      # 顏色、字型、主題常數
│       │   ├── l10n/           # 國際化（英文 & 繁體中文）
│       │   ├── network/        # HTTP (Dio)、SSE、WebSocket 客戶端
│       │   └── utils/          # 工具函式與擴展
│       ├── data/
│       │   └── models/         # 各功能的資料模型
│       └── presentation/
│           ├── pages/          # 頁面元件（Home、Coach、Insights、Profile）
│           ├── providers/      # Riverpod 狀態管理
│           ├── router/         # GoRouter 導航
│           └── widgets/        # 可重用 UI 元件
├── backend/                    # Python Quart 後端（HTTP + WebSocket）
│   ├── api_server/
│   │   ├── routers/            # HTTP 端點藍圖
│   │   ├── middlewares/        # CORS、認證、限流、追蹤
│   │   ├── schemas/            # 請求/回應驗證
│   │   └── websocket.py        # Voice Coach WebSocket 端點
│   ├── modules/                # 功能模組（業務邏輯）
│   │   ├── icebreaker/         # 場景分析 & 開場白
│   │   ├── reply/              # 聊天回覆教練
│   │   ├── voice_coach/        # 即時語音教練
│   │   ├── love_coach/         # 戀愛諮詢聊天
│   │   ├── persona/            # 個人化 AI 風格
│   │   ├── match/              # 配對管理
│   │   ├── insights/           # 分析與報告
│   │   └── jobs/               # 非同步任務管理
│   ├── infra/
│   │   ├── database/           # SQLAlchemy ORM 模型
│   │   └── security/           # 認證 & 稽核日誌
│   ├── services/               # 跨模組服務
│   ├── config/                 # 設定 & Feature Flags
│   └── clients/                # LLM 客戶端（Gemini、OpenAI）
├── prisma/                     # 資料庫 Schema 定義
└── flutter-shadcn-ui/          # Shadcn UI 元件庫（子模組）
```

---

## 技術棧

### 前端（Flutter）

| 類別 | 技術 | 說明 |
|------|------|------|
| 框架 | Flutter 3.10.7+ | 跨平台 UI 框架 |
| 狀態管理 | Riverpod 2.6+ | 響應式狀態管理，支援 Code Generation |
| 導航 | GoRouter 14.8+ | 宣告式路由 |
| UI 元件庫 | Shadcn UI (本地子模組) | 自訂設計系統 |
| HTTP 客戶端 | Dio 5.8+ | 攔截器、重試邏輯 |
| WebSocket | web_socket_channel 3.0+ | 即時通訊 |
| 音訊錄製 | record 5.1.2 | 跨平台音訊擷取 |
| 序列化 | Freezed + JsonSerializable | 型別安全的 JSON 轉換 |
| 本地儲存 | SharedPreferences 2.5+ | 持久化本地狀態 |
| 圖示 | Lucide Icons 0.257.0 | 一致的圖示系統 |

### 後端（Python）

| 類別 | 技術 | 說明 |
|------|------|------|
| Web 框架 | Quart 0.20.0 | 非同步 Python Web 框架 |
| ASGI 伺服器 | Hypercorn 0.17.3 | 高效能非同步伺服器 |
| 主要資料庫 | PostgreSQL + SQLAlchemy 2.0+ (asyncpg) | 關聯式資料儲存 |
| 輔助資料庫 | MongoDB + motor 3.6.0 | 對話日誌儲存 |
| LLM - 分析 | Google Gemini (google-genai 1.5.0) | 圖像分析、文字生成、串流 |
| LLM - 語音 | OpenAI Realtime API (openai 1.60.0) | 即時語音對話 |
| HTTP 客戶端 | httpx 0.28.1 | 非同步 HTTP 請求 |
| 資料驗證 | Pydantic 2.10.0 | Schema 驗證 |
| 結構化日誌 | structlog 24.4.0 | JSON 格式結構化日誌 |
| 序列化 | orjson 3.10.12 | 高效能 JSON |
| 資料庫遷移 | Alembic 1.14.1 | 漸進式 Schema 遷移 |

---

## 系統架構

### 整體架構圖

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter 前端                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐  │
│  │  Pages   │  │ Widgets  │  │Providers │  │ Router │  │
│  │ (UI層)   │◄─┤ (元件)   │  │(Riverpod)│  │(GoRouter)│ │
│  └────┬─────┘  └──────────┘  └────┬─────┘  └────────┘  │
│       │                           │                      │
│  ┌────▼───────────────────────────▼─────┐               │
│  │           Core / Network              │               │
│  │  ┌─────────┐ ┌────────┐ ┌─────────┐  │               │
│  │  │ApiClient│ │SseClient│ │VoiceWs  │  │               │
│  │  │ (Dio)   │ │ (SSE)  │ │(WebSocket)│ │               │
│  │  └────┬────┘ └───┬────┘ └────┬─────┘  │               │
│  └───────┼──────────┼───────────┼────────┘               │
└──────────┼──────────┼───────────┼────────────────────────┘
           │ HTTP     │ SSE       │ WebSocket
           ▼          ▼           ▼
┌─────────────────────────────────────────────────────────┐
│                   Python 後端 (Quart)                    │
│  ┌──────────────────────────────────────────┐           │
│  │            Middleware Stack               │           │
│  │  Tracing → CORS → Auth → RateLimit       │           │
│  └──────────────┬───────────────────────────┘           │
│                 │                                        │
│  ┌──────────────▼───────────────────────────┐           │
│  │            Routers (HTTP Endpoints)       │           │
│  │  /icebreaker  /reply  /love-coach         │           │
│  │  /persona     /matches  /insights         │           │
│  └──────────────┬───────────────────────────┘           │
│                 │                                        │
│  ┌──────────────▼───────────────────────────┐           │
│  │         Modules (Business Logic)          │           │
│  │  IcebreakerService  ReplyService          │           │
│  │  VoiceCoachService  LoveCoachService      │           │
│  │  PersonaService     InsightsService       │           │
│  └──────┬───────────────────┬───────────────┘           │
│         │                   │                            │
│  ┌──────▼──────┐     ┌──────▼──────┐                    │
│  │  LLM Clients │     │  Database   │                    │
│  │  Gemini      │     │  PostgreSQL │                    │
│  │  OpenAI      │     │  MongoDB    │                    │
│  └─────────────┘     └─────────────┘                    │
└─────────────────────────────────────────────────────────┘
```

### 後端 Middleware 管線

所有請求依序經過以下中介軟體：

1. **Tracing** — 注入 `request_id`，供結構化日誌追蹤
2. **CORS** — 跨域資源共享設定
3. **Auth** — Token 驗證與身份確認
4. **Rate Limiting** — API 請求限流保護
5. **Security Headers** — 安全標頭注入

---

## 功能一：Icebreaker Coach（破冰教練）

### 功能說明

分析社交場景（圖片 + 文字描述），產生多個搭話開場白，並提供觀察切入點、話題建議與行為提示。

### 前端實現

**頁面**：`flutter/lib/presentation/pages/home/home_page.dart`
**Provider**：`flutter/lib/presentation/providers/icebreaker_provider.dart`
**Model**：`flutter/lib/data/models/icebreaker_models.dart`

#### 使用者流程

```
拍照 / 選擇圖片 → 輸入場景描述 → 點擊分析按鈕
    → 沉浸式掃描動畫（進度階段提示）
    → 水平卡片輪播顯示結果
```

#### UI 元件

- **圖片選擇器**：支援相機拍攝與相簿選取
- **文字輸入**：場景描述輸入框
- **掃描動畫**：沉浸式載入畫面，包含掃描線動畫與進度階段提示
- **結果輪播**：`PageView` 水平卡片展示 6+ 張結果卡
  - 場景分析卡
  - 多張開場白卡（含語氣、信心指數）
  - 觀察切入點卡
  - 話題建議卡
  - 行為提示卡

#### 狀態管理

```dart
// StateNotifierProvider 管理非同步分析狀態
final icebreakerProvider = StateNotifierProvider<
    IcebreakerNotifier, AsyncValue<IcebreakerResult?>>();

// 圖片狀態
final icebreakerImageProvider = StateProvider<XFile?>();
```

`IcebreakerNotifier` 呼叫 `ApiClient` 發送 HTTP 請求，根據回傳結果更新 `AsyncValue` 狀態（loading → data / error）。

### 後端實現

**Service**：`backend/modules/icebreaker/service.py`
**Router**：`backend/api_server/routers/icebreaker.py`

#### API 端點

```
POST /api/icebreaker/analyze
```

#### 請求格式

```json
{
  "scene_description": "咖啡廳裡有一位正在看書的女生",
  "image_base64": "<base64 encoded image>",
  "language": "zh-TW"
}
```

#### 處理流程

```
1. 接收圖片 (Base64) + 文字描述
2. 建構 System Prompt（含語言指示、輸出格式要求）
3. 呼叫 Google Gemini API（Vision + Text 模型）
4. 解析 LLM 結構化 JSON 回應
5. 寫入 analysis_logs 資料表（供 Insights 使用）
6. 回傳結構化結果
```

#### 回應資料結構

```json
{
  "scene_analysis": "場景描述分析",
  "approach_readiness": 85,
  "opening_lines": [
    {
      "text": "你好，那本書看起來很有趣...",
      "tone": "friendly",
      "confidence": 0.9,
      "based_on": "觀察到她正在讀的書"
    }
  ],
  "observation_hooks": [...],
  "topic_suggestions": [...],
  "behavior_tips": [...]
}
```

---

## 功能二：Reply Coach（回覆教練）

### 功能說明

分析約會聊天截圖或文字，根據關係階段提供策略性回覆建議，包含情緒分析、回覆選項與教練建議。

### 前端實現

**頁面**：`flutter/lib/presentation/pages/coach/coach_page.dart`
**Provider**：`flutter/lib/presentation/providers/reply_provider.dart`
**Model**：`flutter/lib/data/models/reply_models.dart`

#### 使用者流程

```
選擇關係階段（新配對 / 約會中 / 重新連結）
    → 上傳聊天截圖 或 輸入聊天文字
    → 點擊生成按鈕
    → 顯示分析結果面板
```

#### UI 元件

- **階段選擇器**：水平 Chip 選擇器（New Match / Dating / Revive）
- **截圖上傳區**：支援拍照與相簿
- **文字輸入區**：聊天文字 TextArea
- **結果面板**：
  - 情緒分析區塊（偵測情緒 + 信心指數 + 潛台詞）
  - 多個回覆選項卡（文字、意圖、策略、框架技巧）
  - 教練觀點（該做 / 不該做）
  - 階段教練（目前階段、策略、技巧、警告）

#### 關係階段對應

| 前端標籤 | 後端值 | 說明 |
|---------|--------|------|
| New Match | `early` | 初始配對階段 |
| Dating | `flirting` | 約會進行中 |
| Revive | `couple` | 重新建立連結 |

### 後端實現

**Service**：`backend/modules/reply/service.py`
**Router**：`backend/api_server/routers/reply.py`

#### API 端點

```
POST /api/reply/analyze
```

#### 請求格式

```json
{
  "chat_text": "她說：今天好累喔...",
  "screenshot_base64": "<base64 encoded image>",
  "language": "zh-TW",
  "relationship_stage": "early",
  "user_gender": "male",
  "target_gender": "female"
}
```

#### 處理流程

```
1. 接收聊天截圖 (Base64) 或文字 + 關係階段參數
2. 根據 relationship_stage 選擇對應的 System Prompt 模板
3. 結合性別動態（user_gender / target_gender）微調提示
4. 呼叫 Google Gemini API 分析
5. 解析結構化 JSON（情緒分析、回覆選項、教練建議）
6. 寫入 analysis_logs
7. 回傳結果
```

#### 回應資料結構

```json
{
  "emotion_analysis": {
    "detected_emotion": "疲憊",
    "subtext": "可能在尋求關心",
    "confidence": 0.85
  },
  "reply_options": [
    {
      "text": "聽起來真的很辛苦，要不要聊聊？",
      "intent": "表達關心",
      "strategy": "共情回應",
      "framework_technique": "情感鏡射"
    }
  ],
  "coach_panel": {
    "dos": ["表達同理心", "詢問具體情況"],
    "donts": ["忽略她的感受", "立刻轉換話題"]
  },
  "stage_coaching": {
    "current_stage": "early",
    "strategy": "建立信任",
    "technique": "積極傾聽",
    "warnings": ["避免過度主動"]
  }
}
```

---

## 功能三：Voice Coach（即時語音教練）

### 功能說明

透過 OpenAI Realtime API 提供即時語音對話教練功能。使用者在約會場景中進行對話時，系統即時分析語音並提供教練建議。

### 前端實現

**Provider**：`flutter/lib/presentation/providers/voice_coach_provider.dart`
**Widget**：`flutter/lib/presentation/widgets/voice_coach_island.dart`
**Audio**：`flutter/lib/core/audio/`

#### 使用者流程

```
點擊浮動 Voice Coach Island → 建立 WebSocket 連線
    → 開始錄音（PCM16 24kHz）
    → 即時串流音訊至後端
    → 接收即時教練回饋
    → 結束對話
```

#### 音訊處理

```dart
// 跨平台音訊錄製抽象
// Native (iOS/Android): 使用 record 套件
// Web: 使用 Web Audio API
```

錄音以 PCM16 格式、24kHz 取樣率擷取，透過 WebSocket 以 Base64 編碼串流至後端。

#### 即時回饋顯示

- 偵測情緒 + 情緒細節
- 教練建議列表
- 對話方向指引
- 核心技巧名稱
- VAD（語音活動偵測）狀態

### 後端實現

**Service**：`backend/modules/voice_coach/service.py`
**WebSocket**：`backend/api_server/websocket.py`

#### 連線端點

```
WebSocket /ws/voice-coach
```

#### 架構流程

```
Flutter 客戶端                    後端 (Quart)                  外部 API
    │                               │                              │
    │──── WebSocket 連線 ───────────▶│                              │
    │                               │──── WebSocket 連線 ─────────▶│
    │                               │         OpenAI Realtime API  │
    │                               │                              │
    │── PCM16 音訊 (Base64) ───────▶│── 轉發音訊 ────────────────▶│
    │                               │                              │
    │                               │◀─── 即時轉錄 + 回應 ────────│
    │                               │                              │
    │                               │── 呼叫 Gemini ──────────────▶│
    │                               │    (結構化教練分析)           │ Google Gemini
    │                               │◀── 教練回饋 JSON ────────────│
    │                               │                              │
    │◀─── coaching_update 事件 ─────│                              │
    │                               │                              │
    │── 結束對話 ──────────────────▶│── 清理 Session ─────────────▶│
```

#### 後端處理細節

1. **建立 Session**：建立到 OpenAI Realtime API 的 WebSocket 連線
2. **音訊中繼**：將客戶端 PCM16 音訊轉發至 OpenAI
3. **轉錄處理**：接收 OpenAI 的即時語音轉錄
4. **教練分析**：每次回應完成後，呼叫 Gemini 生成結構化教練分析
5. **事件串流**：將 `coaching_update` 事件推送回客戶端
6. **Session 管理**：支援 TTL 超時與資源清理

#### 教練回饋資料結構

```json
{
  "type": "coaching_update",
  "data": {
    "emotion": "緊張",
    "emotion_detail": "語速偏快，可能是因為緊張",
    "suggestions": ["放慢語速", "多用開放式問題"],
    "direction": "嘗試引導話題到共同興趣",
    "technique": "積極傾聽"
  }
}
```

---

## 功能四：Love Coach（戀愛教練聊天）

### 功能說明

互動式文字聊天介面，透過 SSE（Server-Sent Events）串流提供即時的戀愛建議與關係諮詢。

### 前端實現

**Widget**：`flutter/lib/presentation/widgets/love_coach_chat_sheet.dart`
**Provider**：`flutter/lib/presentation/providers/love_coach_provider.dart`
**Model**：`flutter/lib/data/models/love_coach_models.dart`

#### 使用者流程

```
點擊底部導航列中央的 ❤️ 按鈕
    → 彈出可拖曳的 Bottom Sheet
    → 輸入問題或描述情況
    → SSE 串流接收 AI 回覆（逐字顯示）
    → 對話歷史持久化
```

#### SSE 客戶端實現

```dart
// 跨平台 SSE 客戶端
// Web: 原生 fetch + ReadableStream
// Native: Dio stream response

class SseClient {
  // 解析 SSE chunks 為 Stream<String>
  // 偵測 __DONE__ 事件取得 conversation_id
}
```

#### 狀態管理

```dart
final loveCoachProvider = StateNotifierProvider<
    LoveCoachNotifier, LoveCoachState>();

class LoveCoachState {
  final List<LoveCoachMessage> messages;
  final String? conversationId;
  final bool isStreaming;
  final String currentStreamText; // 串流中逐步累積的文字
}
```

### 後端實現

**Service**：`backend/modules/love_coach/service.py`
**Router**：`backend/api_server/routers/love_coach.py`

#### API 端點

```
POST /api/love-coach/chat  (回應格式：text/event-stream)
```

#### 請求格式

```json
{
  "message": "她突然已讀不回，我該怎麼辦？",
  "conversation_id": "uuid-xxx"  // 可選，首次對話時自動產生
}
```

#### 處理流程

```
1. 接收使用者訊息 + conversation_id（可選）
2. 載入或建立對話記錄（PostgreSQL）
3. 儲存使用者訊息至 love_coach_messages
4. 建構對話歷史上下文（最多 20 輪）
5. 呼叫 Gemini API（串流模式）
6. 透過 SSE 逐 chunk 推送回應
7. 最終 chunk 附帶 __DONE__ + conversation_id
8. 儲存完整 AI 回應至 love_coach_messages
```

#### SSE 回應格式

```
data: 首先
data: ，不要
data: 緊張。
data: 已讀不回
data: 不一定代表...
data: __DONE__{"conversation_id": "uuid-xxx"}
```

#### 資料庫結構

```
love_coach_conversations
├── id (UUID)
├── user_id
├── title
├── message_count
├── created_at
└── updated_at

love_coach_messages
├── id (UUID)
├── conversation_id (FK)
├── role (user / model)
├── text
└── created_at
```

---

## 功能五：Persona（個人化 AI 風格）

### 功能說明

讓使用者透過滑桿控制 AI 的寫作風格，使 AI 建議的回覆更貼近使用者的個人溝通方式。包含即時預覽（Sandbox）功能。

### 前端實現

**頁面**：`flutter/lib/presentation/pages/profile/profile_page.dart`
**Model**：`flutter/lib/data/models/persona_models.dart`

#### 使用者介面

- **Sync %**：AI 模仿使用者風格的程度
- **Emoji Usage (0-100)**：表情符號使用頻率
- **Sentence Length (0-100)**：句子長度偏好
- **Colloquialism (0-100)**：口語化程度

每個滑桿即時更新，變更儲存至後端。

#### Sandbox 預覽

使用者可上傳訓練樣本文字，系統根據 Persona 設定顯示：
- 原始文字
- AI 重寫後的文字（套用使用者風格）

### 後端實現

**Service**：`backend/modules/persona/service.py`
**Router**：`backend/api_server/routers/persona.py`

#### API 端點

```
POST /api/persona/tone       # 取得 / 更新 Persona 設定
POST /api/persona/sandbox     # 預覽 AI 重寫效果
```

#### Persona 設定資料結構

```json
{
  "sync_pct": 75,
  "emoji_usage": 40,
  "sentence_length": 60,
  "colloquialism": 80
}
```

#### 整合方式

Persona 設定被其他模組（Reply Coach、Love Coach）引用，在生成回覆時將使用者的溝通風格偏好注入 System Prompt，使 AI 輸出更個人化。

---

## 功能六：Insights（數據分析儀表板）

### 功能說明

彙整所有教練功能的績效數據，以視覺化方式呈現使用者的社交技能成長。

### 前端實現

**頁面**：`flutter/lib/presentation/pages/insights/insights_page.dart`
**Provider**：`flutter/lib/presentation/providers/insights_provider.dart`
**Model**：`flutter/lib/data/models/insights_models.dart`

#### UI 元件

##### 1. 六維雷達圖（Custom Painted）

自訂 `CustomPainter` 繪製六維技能雷達圖：

| 維度 | 說明 |
|------|------|
| Emotional Value | 情感價值 |
| Listening | 傾聽能力 |
| Frame Control | 框架控制 |
| Escalation | 升溫能力 |
| Empathy | 同理心 |
| Humor | 幽默感 |

```dart
class RadarChartPainter extends CustomPainter {
  // 計算六邊形頂點座標
  // 繪製背景網格
  // 繪製數據多邊形
  // 標註軸標籤
}
```

##### 2. 約會報告卡

- 綜合分數 (0-100)
- 各項技能細分
- 優點列表
- 改進建議
- 行動項目

##### 3. 語音教練紀錄

可摺疊列表，每筆紀錄包含：
- 對話時長
- 輸入轉錄文字
- 教練轉錄文字
- 教練回饋更新列表

### 後端實現

**Service**：`backend/modules/insights/service.py`
**Router**：`backend/api_server/routers/insights.py`

#### API 端點

```
GET /api/insights/skills           # 技能雷達圖數據
GET /api/insights/reports          # 約會報告列表
GET /api/insights/voice-coach-logs # 語音教練紀錄
```

#### 數據來源

- **Skills**：從 `date_reports` 資料表彙整平均技能分數
- **Reports**：直接查詢 `date_reports` 資料表（支援分頁）
- **Voice Coach Logs**：從 `analysis_logs` 資料表篩選語音教練類型的紀錄

---

## 功能七：Match Pipeline（配對管理）

### 功能說明

CRM 風格的約會對象管理系統，追蹤活躍的配對對象。

### 前端實現

**位置**：`flutter/lib/presentation/pages/home/home_page.dart`（Pipeline 區塊）

#### UI 元件

- 水平捲動的配對卡片列表
- 新增配對對話框（名稱 + 備註）
- 長按刪除
- 狀態追蹤（active / archived）

### 後端實現

**Service**：`backend/modules/match/service.py`
**Router**：`backend/api_server/routers/match.py`

#### API 端點

```
POST   /api/matches    # 新增配對
GET    /api/matches    # 取得配對列表
DELETE /api/matches/:id # 刪除配對
```

#### 資料庫結構

```
matches
├── id (UUID)
├── user_id
├── name
├── context
├── status (active / archived)
├── created_at
└── updated_at
```

---

## 狀態管理

### Riverpod 架構

本專案使用 Riverpod 2.6+ 作為狀態管理方案，搭配 Code Generation 確保型別安全。

#### Provider 類型分佈

```
┌─────────────────────────────────────────┐
│              Core Providers              │
│  Provider<ApiClient>                    │
│  Provider<SharedPreferences>            │
│  StateProvider<bool> (voiceCoachEnabled) │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│           Feature Providers              │
│                                         │
│  StateNotifierProvider                  │
│  ├── IcebreakerNotifier                 │
│  ├── ReplyNotifier                      │
│  ├── VoiceCoachNotifier                 │
│  └── LoveCoachNotifier                  │
│                                         │
│  AsyncNotifierProvider                  │
│  ├── SkillsNotifier                     │
│  ├── ReportsNotifier                    │
│  └── VoiceCoachLogsNotifier             │
└─────────────────────────────────────────┘
```

#### 非同步錯誤處理模式

```dart
// Either 模式：API 呼叫結果
typedef ApiResult<T> = Future<Either<ApiException, T>>;

// AsyncValue 模式：Riverpod 內建的 loading / data / error 狀態
ref.watch(provider).when(
  loading: () => LoadingWidget(),
  data: (data) => DataWidget(data),
  error: (err, stack) => ErrorWidget(err),
);
```

---

## 網路層

### HTTP 客戶端 (ApiClient)

**檔案**：`flutter/lib/core/network/api_client.dart`

基於 Dio 建構，具備：
- **請求攔截器**：自動附加 Auth Token、Content-Type
- **日誌攔截器**：開發環境自動記錄請求 / 回應
- **重試邏輯**：網路錯誤自動重試
- **錯誤處理**：統一的 `ApiException` 型別轉換

### SSE 客戶端 (SseClient)

**檔案**：`flutter/lib/core/network/sse_client.dart`

跨平台 SSE 實現：
- **Web 平台**：使用原生 `fetch` API + `ReadableStream`
- **原生平台**：使用 Dio Stream Response
- 自動解析 SSE chunk，輸出 `Stream<String>`
- 偵測 `__DONE__` 結束事件

### WebSocket 客戶端 (VoiceCoachWs)

**檔案**：`flutter/lib/core/network/voice_coach_ws.dart`

基於 `web_socket_channel` 套件：
- 管理 WebSocket 連線生命週期
- 發送 Base64 編碼的 PCM16 音訊
- 接收並解析 JSON 事件
- 自動重連與錯誤處理

---

## 資料庫設計

### PostgreSQL（主要關聯式資料庫）

| 資料表 | 用途 |
|--------|------|
| `users` | 使用者帳號資訊 |
| `user_personas` | AI 寫作風格設定 |
| `matches` | 約會配對管理 |
| `date_reports` | 績效分數 & 回饋 |
| `love_coach_conversations` | 聊天 Session 元資料 |
| `love_coach_messages` | 聊天訊息紀錄 |
| `analysis_logs` | 全功能使用追蹤（Icebreaker、Reply、Voice Coach） |

### MongoDB（輔助文件資料庫）

用於儲存非結構化的對話日誌，目前為輔助角色。

### ORM 與遷移

- **SQLAlchemy 2.0+**：非同步 ORM（使用 `asyncpg` 驅動）
- **Alembic**：漸進式 Schema 遷移管理

---

## 國際化

### 支援語言

| 語言 | 代碼 | 檔案 |
|------|------|------|
| English | `en` | `flutter/lib/core/l10n/app_localizations_en.dart` |
| 繁體中文 | `zh-TW` | `flutter/lib/core/l10n/app_localizations_zh.dart` |

### 實現方式

自訂 i18n 方案，透過 `AppLocalizations` 類別提供各語言字串：

```dart
class AppLocalizations {
  final String locale;

  String get homeTitle => _localizedValues[locale]!['homeTitle']!;
  String get coachTitle => _localizedValues[locale]!['coachTitle']!;
  // ...
}
```

後端 API 也支援 `language` 參數，LLM Prompt 會根據語言切換，確保 AI 回應使用正確的語言。

---

## 主題與設計系統

### 色彩系統

```dart
// 深色主題
class AppColors {
  static const background = Color(0xFF0A0A0A);
  static const foreground = Color(0xFFFAFAFA);
  static const primary = Color(0xFFFAFAFA);
  // ...
}

// 淺色主題
class AppColorsLight {
  static const background = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF0A0A0A);
  // ...
}
```

### 圓角 Token

```dart
class AppRadius {
  static const sm = 6.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const xl = 16.0;
  static const xxl = 24.0;
}
```

### 字型

使用 Google Fonts **Inter** 作為主要字型。

### UI 元件庫

整合本地 `flutter-shadcn-ui` 子模組，提供一致的設計系統元件（按鈕、輸入框、卡片等）。

---

## 導航結構

### GoRouter 設定

```dart
GoRoute(
  path: '/',
  name: 'home',
  pageBuilder: (_, __) => NoTransitionPage(child: MainShell()),
)
```

### MainShell 導航

使用 `IndexedStack` 實現底部 Tab 導航，保持各頁面狀態：

| Tab | 頁面 | 功能 |
|-----|------|------|
| 1 | Home | Icebreaker Coach + Match Pipeline |
| 2 | Coach | Reply Coach |
| 3 | ❤️ (中央) | Love Coach（Bottom Sheet） |
| 4 | Insights | 數據分析儀表板 |
| 5 | Profile | Persona 設定 |

### 全域浮動元件

- **VoiceCoachIsland**：浮動語音教練按鈕，全域可存取
- **ImpulseControlOverlay**：全螢幕衝動控制提醒覆蓋層
