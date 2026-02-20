Backend Architecture & Development Plan: AI Dating Coach
1. 技術棧 (Tech Stack)
核心框架: Python 3.10+, FastAPI (極佳的非同步支援)

伺服器: Uvicorn

AI 串接: OpenAI Python SDK (支援 GPT-4o Vision 與 Realtime API)

資料驗證: Pydantic

依賴管理: pip 或 poetry

2. 目錄結構規劃 (Directory Structure)
建議在專案根目錄下建立 backend/ 資料夾，內部結構如下：

backend/
├── app/
│   ├── init.py
│   ├── main.py              # FastAPI 實例與 CORS 設定
│   ├── api/                 # REST API 路由控制器
│   │   ├── routes/
│   │   │   ├── icebreaker.py # 處理情境破冰 API
│   │   │   └── reply.py      # 處理訊息回覆 API
│   ├── websockets/          # WebSocket 路由控制器
│   │   └── live_coach.py    # 處理即時語音串流與中繼轉發
│   ├── services/            # 核心商業邏輯與外部 AI 呼叫
│   │   ├── openai_vision.py # 處理圖片與截圖分析邏輯
│   │   └── openai_realtime.py # 封裝 OpenAI Realtime API 的連線邏輯
│   ├── core/                # 系統配置
│   │   ├── config.py        # 環境變數載入 (API Keys)
│   │   └── prompts.py       # 集中管理所有 System Prompts (教練人設)
│   ├── schemas/             # Pydantic 結構定義 ( Request / Response )
│   │   ├── request.py
│   │   └── response.py
│   └── utils/               # 工具函式
│       └── audio_parser.py  # 處理音訊編解碼
├──.env                     # 環境變數 (不進版控)
└── requirements.txt         # 依賴清單

3. 核心模組實作指引
模組 A: 靜態圖文解析 API (Feature 1 & 2)
實作重點: 建立 /api/v1/icebreaker 與 /api/v1/reply POST 端點。

運作流程:

FastAPI 接收前端傳來的 Base64 圖片與補充文字。

讀取 core/prompts.py 中針對台灣語境設計的提示詞。

呼叫 services/openai_vision.py 傳送給 GPT-4o 模型，並強制要求模型以 JSON 格式回應 (利用 OpenAI 的 JSON Mode 或 Function Calling)。

透過 Pydantic 模型驗證輸出的 JSON 格式是否正確，再回傳給前端。

模組 B: 即時語音中繼伺服器 (Feature 3 - 最核心技術)
實作重點: FastAPI 必須作為前端與 OpenAI 之間的橋樑 (Relay Server)。

運作流程:

在 websockets/live_coach.py 建立 @app.websocket("/ws/live-coach") 端點。

當前端連上此 WS 時，後端同時在背景開啟一個通往 OpenAI Realtime API (WebSocket 或 WebRTC 協定) 的持續連線。

雙向轉發：

將前端收到的 User Audio Chunks 直接轉發給 OpenAI。

監聽 OpenAI 回傳的事件 (session.updated, response.text.delta, 或自訂的 function call 分析結果)。

戰術推播：當後端從 OpenAI 的意圖分析中，發現對方語氣不耐煩或有尷尬空白時，後端主動透過 WS 推播一筆 JSON 資料 (包含話題建議) 給前端。

4. 開發階段備註
第一階段: 建立 main.py 與 schemas，並讓 API 回傳寫死的 JSON 假資料，提供給前端進行串接測試 (平行開發的關鍵)。

第二階段: 實作 OpenAI Vision 的串接與 Prompts 微調。

第三階段: 實作 WebSocket 中繼機制。這部分難度較高，需處理非同步的非阻塞 I/O (Async I/O) 與音訊格式對齊。

第四階段 (最後實作): 實作 JWT 認證 (app/core/security.py)，並將使用者對話紀錄存入資料庫 (如 PostgreSQL/Supabase)。目前先以無狀態 (Stateless) 方式開發核心功能。