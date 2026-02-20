Frontend Architecture & Development Plan: AI Dating Coach
1. 技術棧 (Tech Stack)
核心框架: Next.js 14+ (採用 App Router 架構)

程式語言: TypeScript (嚴格型別檢查，利於未來對接 Flutter)

樣式框架: Tailwind CSS

狀態管理: Zustand (輕量、適合處理跨元件的對話狀態)

音訊處理: 瀏覽器原生 Web Audio API 與 MediaRecorder

2. 目錄結構規劃 (Directory Structure)
建議在專案根目錄下建立 frontend/ 資料夾，內部結構如下：

frontend/
├── src/
│   ├── app/                 # Next.js 頁面路由
│   │   ├── layout.tsx       # 全域 Layout
│   │   ├── page.tsx         # 首頁 (功能導覽)
│   │   ├── icebreaker/      # 功能一：情境破冰頁面
│   │   ├── reply-coach/     # 功能二：訊息回覆頁面
│   │   └── live-coach/      # 功能三：即時語音教練頁面
│   ├── components/          # 共用 UI 元件 (依原子設計原則)
│   │   ├── ui/              # 基礎元件 (按鈕、輸入框、載入動畫)
│   │   └── features/        # 複雜功能元件 (相機預覽、對話氣泡、錄音視覺化)
│   ├── hooks/               # 自訂 React Hooks (隔離商業邏輯)
│   │   ├── useAudioRecorder.ts # 封裝麥克風權限與音訊擷取邏輯
│   │   ├── useWebSocket.ts     # 封裝與後端連線的 WS 邏輯
│   │   └── useChatHistory.ts   # 處理文字聊天的歷史紀錄
│   ├── services/            # API 呼叫層
│   │   ├── apiClient.ts     # Axios 或 Fetch 的基底設定 (攔截器)
│   │   └── coachService.ts  # 定義呼叫後端的各項 REST API
│   ├── store/               # 全域狀態管理
│   │   └── useAppStore.ts   # 管理 UI 狀態與快取資料
│   ├── types/               # TypeScript 型別定義
│   │   └── api.d.ts         # 定義前後端溝通的 JSON 介面 (必須與後端對齊)
│   └── utils/               # 工具函式
│       ├── fileToDataUrl.ts # 圖片轉 Base64 工具
│       └── audioUtils.ts    # 音訊格式轉換工具

3. 核心模組實作指引
模組 A: 靜態圖文解析 (整合功能一與功能二)
實作重點: 圖片上傳與表單提交。

運作流程: 使用者在元件中選擇照片或輸入文字 -> 觸發 services/coachService.ts 中的函式 -> 將資料封裝為 FormData 或 JSON -> 發送 POST 請求至後端 -> 接收分析結果並渲染「多語氣回覆」與「教練解析」。

模組 B: 即時語音處理 (整合功能三)
實作重點: 麥克風串流與 WebSocket。

運作流程:

透過 useAudioRecorder 取得麥克風串流 (設定取樣率，例如 16kHz 或 24kHz，依後端需求而定)。

透過 useWebSocket 建立與 Python 後端 /ws/live-coach 的連線。

將收音的 Blob/Buffer 定期 (例如每 200 毫秒) 轉為 Base64 透過 WS 發送。

監聽 WS 的 onmessage 事件，若收到後端傳來的「話題建議」JSON，立即觸發畫面上的 UI 提示 (例如彈出一個浮動建議框)。

4. 開發階段備註
第一階段: 先用假資料 (Mock Data) 寫死介面，確保 UI 切換與元件渲染順暢。

第二階段: 串接後端 REST API (圖片與文字分析)。

第三階段: 實作 WebSocket 與麥克風串流。

第四階段 (最後實作): 實作 JWT 登入與 Token 夾帶機制 (目前所有 API 請求先不做權限驗證，方便平行開發與測試)。