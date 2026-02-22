<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta
      name="viewport"
      content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"
    />
    <title>AURA - Dating CRM</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://code.iconify.design/iconify-icon/1.0.7/iconify-icon.min.js"></script>
    <link
      href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600&amp;display=swap"
      rel="stylesheet"
    />
    <style>
      body {
          font-family: 'Inter', sans-serif;
          background-color: #000000;
          margin: 0;
          display: flex;
          justify-content: center;
          align-items: center;
          min-height: 100vh;
          color: #fafafa;
          -webkit-font-smoothing: antialiased;
      }

      /* Custom Scrollbar Hiding */
      .hide-scrollbar::-webkit-scrollbar {
          display: none;
      }
      .hide-scrollbar {
          -ms-overflow-style: none;
          scrollbar-width: none;
      }

      /* Animations */
      @keyframes pulse-soft {
          0%, 100% { transform: scale(1); opacity: 0.1; }
          50% { transform: scale(1.05); opacity: 0.3; }
      }

      @keyframes breathe-deep {
          0%, 100% { transform: scale(0.85); border-color: rgba(59, 130, 246, 0.1); box-shadow: 0 0 20px rgba(59, 130, 246, 0.05); }
          50% { transform: scale(1.15); border-color: rgba(59, 130, 246, 0.6); box-shadow: 0 0 60px rgba(59, 130, 246, 0.3); }
      }

      @keyframes shimmer {
          100% { transform: translateX(100%); }
      }

      .animate-breathe-deep {
          animation: breathe-deep 5s ease-in-out infinite;
      }

      .animate-pulse-bg {
          animation: pulse-soft 2.5s infinite ease-in-out;
      }

      /* Tab Routing Logic */
      .view-section { display: none; }

      #tab-home:checked ~ #app-container .view-home,
      #tab-coach:checked ~ #app-container .view-coach,
      #tab-insights:checked ~ #app-container .view-insights,
      #tab-profile:checked ~ #app-container .view-profile {
          display: flex;
      }

      #tab-home:checked ~ #app-container .nav-home,
      #tab-coach:checked ~ #app-container .nav-coach,
      #tab-insights:checked ~ #app-container .nav-insights,
      #tab-profile:checked ~ #app-container .nav-profile {
          color: #FF66A1;
      }

      #tab-home:checked ~ #app-container .nav-home iconify-icon,
      #tab-coach:checked ~ #app-container .nav-coach iconify-icon,
      #tab-insights:checked ~ #app-container .nav-insights iconify-icon,
      #tab-profile:checked ~ #app-container .nav-profile iconify-icon {
          color: #FF66A1;
      }

      /* Panic / Impulse Control Overlay Logic */
      #panic-overlay {
          opacity: 0;
          pointer-events: none;
          transition: opacity 0.4s ease;
      }

      #toggle-panic:checked ~ #app-container #panic-overlay {
          opacity: 1;
          pointer-events: auto;
      }

      /* Custom Input Range */
      input[type=range] {
          -webkit-appearance: none;
          background: transparent;
      }
      input[type=range]::-webkit-slider-thumb {
          -webkit-appearance: none;
          height: 16px;
          width: 16px;
          border-radius: 50%;
          background: #FF66A1;
          margin-top: -6px;
          box-shadow: 0 0 10px rgba(255,102,161,0.5);
      }
      input[type=range]::-webkit-slider-runnable-track {
          width: 100%;
          height: 4px;
          cursor: pointer;
          background: #27272a;
          border-radius: 4px;
      }

      /* Custom Checkbox as Chip */
      .chip-checkbox:checked + label {
          background-color: rgba(255, 102, 161, 0.1);
          border-color: #FF66A1;
          color: #FF66A1;
      }
    </style>
  </head>
  <body class="bg-black relative">
    <!-- State Management Inputs -->
    <input
      type="radio"
      name="app-tabs"
      id="tab-home"
      class="hidden"
      checked=""
    />
    <input type="radio" name="app-tabs" id="tab-coach" class="hidden" />
    <input type="radio" name="app-tabs" id="tab-insights" class="hidden" />
    <input type="radio" name="app-tabs" id="tab-profile" class="hidden" />

    <!-- Emergency Panic Toggle -->
    <input type="checkbox" id="toggle-panic" class="hidden" />

    <!-- Mobile Device Container -->
    <div
      id="app-container"
      class="w-full max-w-[400px] h-[100dvh] sm:h-[850px] bg-[#09090b] sm:rounded-[40px] sm:border-[6px] border-[#1f1f22] overflow-hidden relative shadow-2xl flex flex-col"
    >
      <!-- Impulse Control (Cold Room) Overlay -->
      <div
        id="panic-overlay"
        class="absolute inset-0 z-[100] bg-gradient-to-b from-slate-900 to-[#09090b] flex flex-col items-center justify-center px-6"
      >
        <label
          for="toggle-panic"
          class="absolute top-12 right-6 w-10 h-10 rounded-full bg-white/5 flex items-center justify-center cursor-pointer hover:bg-white/10 active:scale-95 transition-all"
        >
          <iconify-icon
            icon="solar:close-circle-linear"
            class="text-2xl text-zinc-400"
          ></iconify-icon>
        </label>
        <div
          class="relative w-56 h-56 rounded-full flex items-center justify-center mb-12"
        >
          <div
            class="absolute inset-0 rounded-full border-2 border-blue-500/20 animate-breathe-deep pointer-events-none"
          ></div>
          <div
            class="absolute inset-6 rounded-full bg-blue-500/5 pointer-events-none"
          ></div>
          <iconify-icon
            icon="solar:moon-sleep-linear"
            class="text-6xl text-blue-400 relative z-10"
          ></iconify-icon>
        </div>
        <h2 class="text-2xl tracking-tight font-medium text-zinc-100 mb-4">
          Impulse Control Active
        </h2>
        <p
          class="text-sm text-blue-200/60 text-center leading-relaxed max-w-[240px]"
        >
          Breathe in. Breathe out.
          <br />
          Close the app. Do not double text right now.
        </p>
      </div>

      <!-- Global Header -->
      <header
        class="w-full flex justify-between items-center px-6 pt-12 pb-3 z-20 bg-[#09090b]/95 backdrop-blur-md"
      >
        <span class="text-xl tracking-tighter font-medium text-zinc-100">
          AURA
        </span>
        <div class="flex items-center gap-3">
          <!-- Impulse Control Trigger -->
          <label
            for="toggle-panic"
            class="w-8 h-8 rounded-full bg-slate-800/50 border border-slate-700/50 flex items-center justify-center cursor-pointer active:scale-95 transition-transform group"
          >
            <iconify-icon
              icon="solar:shield-warning-linear"
              class="text-blue-400 group-hover:text-blue-300 transition-colors"
              stroke-width="1.5"
            ></iconify-icon>
          </label>
          <!-- Notifications -->
          <div
            class="w-8 h-8 rounded-full bg-[#18181b] border border-white/5 flex items-center justify-center cursor-pointer active:scale-95 transition-transform"
          >
            <iconify-icon
              icon="solar:bell-linear"
              class="text-zinc-400"
              stroke-width="1.5"
            ></iconify-icon>
          </div>
        </div>
      </header>

      <!-- Global Dynamic Island (Voice Coach) -->
      <div
        class="px-4 pb-2 bg-gradient-to-b from-[#09090b]/95 to-transparent relative z-10"
      >
        <button
          class="w-full bg-[#18181b]/90 backdrop-blur-xl border border-white/10 rounded-2xl px-4 py-3 flex items-center justify-between shadow-lg active:scale-[0.98] transition-all group overflow-hidden relative"
        >
          <div
            class="absolute inset-0 bg-gradient-to-r from-[#FF66A1]/0 via-[#FF66A1]/5 to-[#FF66A1]/0 -translate-x-full group-hover:animate-[shimmer_2s_infinite]"
          ></div>
          <div class="flex items-center gap-3 relative z-10">
            <div
              class="w-9 h-9 rounded-full bg-gradient-to-br from-[#FF66A1]/20 to-transparent flex items-center justify-center border border-[#FF66A1]/30"
            >
              <iconify-icon
                icon="solar:microphone-2-linear"
                class="text-base text-[#FF66A1]"
                stroke-width="1.5"
              ></iconify-icon>
            </div>
            <div class="text-left">
              <h3 class="text-xs font-medium text-zinc-100">
                Live Voice Coach
              </h3>
              <p class="text-[10px] text-[#FF66A1]/80 mt-0.5">
                Listening in background...
              </p>
            </div>
          </div>
          <div class="flex gap-1 items-end h-3 relative z-10 opacity-80">
            <div
              class="w-0.5 bg-[#FF66A1] rounded-full h-full animate-[pulse_1s_ease-in-out_infinite]"
            ></div>
            <div
              class="w-0.5 bg-[#FF66A1] rounded-full h-2/3 animate-[pulse_1.2s_ease-in-out_infinite_0.2s]"
            ></div>
            <div
              class="w-0.5 bg-[#FF66A1] rounded-full h-4/5 animate-[pulse_0.9s_ease-in-out_infinite_0.4s]"
            ></div>
          </div>
        </button>
      </div>

      <!-- VIEW: HOME -->
      <main
        class="view-home view-section flex-col flex-1 overflow-y-auto hide-scrollbar pb-28 px-4"
      >
        <!-- Context-Aware Icebreaker -->
        <section
          class="bg-[#141417] border border-white/5 rounded-3xl p-6 relative overflow-hidden mt-2 flex flex-col items-center shadow-lg"
        >
          <div
            class="absolute -top-20 -right-20 w-48 h-48 bg-[#FF66A1] rounded-full blur-[80px] opacity-5 pointer-events-none"
          ></div>

          <h2
            class="text-xl tracking-tight font-medium text-zinc-100 w-full text-left"
          >
            Context-Aware Icebreaker
          </h2>

          <!-- Enhanced Scan Button (Primary Touch Target) -->
          <button
            class="w-32 h-32 rounded-full bg-gradient-to-br from-[#FF66A1] to-[#e84386] mt-8 mb-8 flex items-center justify-center relative group transition-all active:scale-95 shadow-[0_0_30px_rgba(255,102,161,0.3)] hover:shadow-[0_0_45px_rgba(255,102,161,0.5)] border border-white/10"
          >
            <div
              class="absolute inset-0 rounded-full bg-white/20 animate-pulse-bg pointer-events-none"
            ></div>
            <iconify-icon
              icon="solar:scanner-linear"
              class="text-5xl text-white group-hover:scale-110 transition-transform duration-300 drop-shadow-md"
              stroke-width="1.5"
            ></iconify-icon>
          </button>

          <p class="text-xs text-zinc-500 mb-4 text-center">
            Tap to scan the scene, or type below.
          </p>

          <!-- Text Input Option -->
          <div class="relative w-full">
            <input
              type="text"
              placeholder="e.g., She's reading a book and drinking an iced latte..."
              class="w-full bg-[#09090b] border border-white/10 rounded-2xl py-4 px-4 pl-11 text-xs text-zinc-200 focus:outline-none focus:border-[#FF66A1]/50 transition-colors placeholder:text-zinc-600"
            />
            <iconify-icon
              icon="solar:pen-linear"
              class="absolute left-4 top-1/2 -translate-y-1/2 text-zinc-500 text-lg"
              stroke-width="1.5"
            ></iconify-icon>
            <button
              class="absolute right-2 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-white/5 flex items-center justify-center hover:bg-white/10 transition-colors"
            >
              <iconify-icon
                icon="solar:arrow-right-linear"
                class="text-zinc-400"
              ></iconify-icon>
            </button>
          </div>
        </section>

        <!-- CRM Pipeline -->
        <section class="mt-8 mb-4">
          <h3 class="text-sm font-medium text-zinc-400 px-2 mb-4">
            Active Pipeline
          </h3>
          <div
            class="flex overflow-x-auto hide-scrollbar gap-3 snap-x snap-mandatory px-2 pb-4"
          >
            <!-- Match Card 1 -->
            <div
              class="snap-start shrink-0 w-[140px] bg-[#141417] border border-white/5 rounded-3xl p-4 flex flex-col items-center shadow-md"
            >
              <div
                class="w-14 h-14 rounded-full bg-zinc-800 mb-3 overflow-hidden border border-white/10 flex items-center justify-center"
              >
                <iconify-icon
                  icon="solar:user-linear"
                  class="text-zinc-500 text-xl"
                  stroke-width="1.5"
                ></iconify-icon>
              </div>
              <span class="text-sm font-medium text-zinc-200">Elena</span>
              <div class="flex gap-1 mt-2 flex-wrap justify-center">
                <span
                  class="text-[10px] bg-[#FF66A1]/10 text-[#FF66A1] px-2 py-1 rounded-full border border-[#FF66A1]/20"
                >
                  Art Gallery
                </span>
              </div>
            </div>

            <!-- Match Card 2 -->
            <div
              class="snap-start shrink-0 w-[140px] bg-[#141417] border border-white/5 rounded-3xl p-4 flex flex-col items-center shadow-md"
            >
              <div
                class="w-14 h-14 rounded-full bg-zinc-800 mb-3 overflow-hidden border border-white/10 flex items-center justify-center"
              >
                <iconify-icon
                  icon="solar:user-linear"
                  class="text-zinc-500 text-xl"
                  stroke-width="1.5"
                ></iconify-icon>
              </div>
              <span class="text-sm font-medium text-zinc-200">Sarah</span>
              <div class="flex gap-1 mt-2 flex-wrap justify-center">
                <span
                  class="text-[10px] bg-[#FF66A1]/10 text-[#FF66A1] px-2 py-1 rounded-full border border-[#FF66A1]/20"
                >
                  Coffee fan
                </span>
              </div>
            </div>

            <!-- Empty State / Add Lead -->
            <div
              class="snap-start shrink-0 w-[140px] bg-[#09090b] border border-dashed border-white/10 rounded-3xl p-4 flex flex-col items-center justify-center text-zinc-600 hover:border-white/20 transition-colors cursor-pointer"
            >
              <div
                class="w-10 h-10 rounded-full bg-white/5 flex items-center justify-center mb-2"
              >
                <iconify-icon
                  icon="solar:add-circle-linear"
                  class="text-xl"
                  stroke-width="1.5"
                ></iconify-icon>
              </div>
              <span class="text-[10px] text-center mt-1">
                Add Lead
                <br />
                or scan room
              </span>
            </div>
          </div>
        </section>
      </main>

      <!-- VIEW: COACH -->
      <main
        class="view-coach view-section flex-col flex-1 overflow-y-auto hide-scrollbar pb-28 px-4"
      >
        <div class="flex justify-between items-center px-2 mt-2 mb-6">
          <h2 class="text-2xl tracking-tight font-medium text-zinc-100">
            Chat Optimizer
          </h2>
        </div>

        <!-- Enhanced Upload Area -->
        <label
          class="w-full bg-[#141417]/50 border-2 border-dashed border-white/10 rounded-3xl h-48 flex flex-col items-center justify-center cursor-pointer hover:bg-[#141417] hover:border-[#FF66A1]/30 transition-all group"
        >
          <input type="file" class="hidden" />
          <div
            class="w-14 h-14 rounded-full bg-white/5 flex items-center justify-center mb-4 group-hover:scale-110 group-hover:bg-[#FF66A1]/10 transition-all duration-300"
          >
            <iconify-icon
              icon="solar:gallery-send-linear"
              class="text-2xl text-zinc-400 group-hover:text-[#FF66A1] transition-colors"
              stroke-width="1.5"
            ></iconify-icon>
          </div>
          <span class="text-sm font-medium text-zinc-200">
            Upload Conversation
          </span>
          <span class="text-xs text-zinc-500 mt-1.5">
            AI will analyze context and subtext
          </span>
        </label>

        <!-- Context Selectors -->
        <div class="mt-8">
          <div class="flex justify-between items-center px-2 mb-3">
            <span class="text-sm font-medium text-zinc-400">
              Relationship Context
            </span>
          </div>
          <div class="flex flex-wrap gap-2 px-2">
            <div>
              <input
                type="checkbox"
                id="ctx1"
                class="hidden chip-checkbox"
                checked=""
              />
              <label
                for="ctx1"
                class="text-xs px-4 py-2 rounded-full border border-white/10 text-zinc-400 cursor-pointer transition-colors block"
              >
                New Match
              </label>
            </div>
            <div>
              <input type="checkbox" id="ctx2" class="hidden chip-checkbox" />
              <label
                for="ctx2"
                class="text-xs px-4 py-2 rounded-full border border-white/10 text-zinc-400 cursor-pointer transition-colors block"
              >
                Dating
              </label>
            </div>
            <div>
              <input type="checkbox" id="ctx3" class="hidden chip-checkbox" />
              <label
                for="ctx3"
                class="text-xs px-4 py-2 rounded-full border border-white/10 text-zinc-400 cursor-pointer transition-colors block"
              >
                Revive Ghost
              </label>
            </div>
          </div>
        </div>

        <!-- Tone Selectors -->
        <div class="mt-6 mb-8">
          <div class="flex justify-between items-center px-2 mb-3">
            <span class="text-sm font-medium text-zinc-400">
              Strategic Tone
            </span>
          </div>
          <div class="flex flex-wrap gap-2 px-2">
            <div>
              <input
                type="checkbox"
                id="tone1"
                class="hidden chip-checkbox"
                checked=""
              />
              <label
                for="tone1"
                class="text-xs px-4 py-2 rounded-full border border-white/10 text-zinc-400 cursor-pointer transition-colors block"
              >
                Humorous
              </label>
            </div>
            <div>
              <input type="checkbox" id="tone2" class="hidden chip-checkbox" />
              <label
                for="tone2"
                class="text-xs px-4 py-2 rounded-full border border-white/10 text-zinc-400 cursor-pointer transition-colors block"
              >
                Push-Pull
              </label>
            </div>
            <div>
              <input type="checkbox" id="tone3" class="hidden chip-checkbox" />
              <label
                for="tone3"
                class="text-xs px-4 py-2 rounded-full border border-white/10 text-zinc-400 cursor-pointer transition-colors block"
              >
                High Value
              </label>
            </div>
          </div>
        </div>

        <!-- Progressive Disclosure: Generate Button -->
        <button
          class="w-full bg-gradient-to-r from-[#FF66A1] to-[#D83B7D] text-white font-medium text-sm py-4 rounded-2xl relative overflow-hidden group active:scale-[0.98] transition-all shadow-[0_4px_20px_rgba(255,102,161,0.25)]"
        >
          <div
            class="absolute inset-0 w-[200%] h-full bg-gradient-to-r from-transparent via-white/20 to-transparent -translate-x-full group-hover:animate-[shimmer_1.5s_infinite]"
          ></div>
          <span class="relative z-10 flex items-center justify-center gap-2">
            <iconify-icon
              icon="solar:magic-stick-3-linear"
              class="text-lg"
            ></iconify-icon>
            Generate Strategy
          </span>
        </button>
      </main>

      <!-- VIEW: INSIGHTS -->
      <main
        class="view-insights view-section flex-col flex-1 overflow-y-auto hide-scrollbar pb-28 px-4"
      >
        <h2
          class="text-2xl tracking-tight font-medium text-zinc-100 px-2 mt-2 mb-6"
        >
          Growth Radar
        </h2>

        <!-- High-Contrast Radar Chart -->
        <div
          class="bg-[#141417] border border-white/5 rounded-3xl p-6 flex flex-col items-center justify-center relative mt-2 shadow-lg"
        >
          <svg
            viewBox="0 0 100 100"
            class="w-56 h-56 mt-4 mb-2 overflow-visible"
          >
            <!-- Background Webs -->
            <polygon
              points="50,5 89,27.5 89,72.5 50,95 11,72.5 11,27.5"
              fill="none"
              stroke="#27272a"
              stroke-width="0.5"
            ></polygon>
            <polygon
              points="50,20 76,35 76,65 50,80 24,65 24,35"
              fill="none"
              stroke="#27272a"
              stroke-width="0.5"
            ></polygon>
            <polygon
              points="50,35 63,42.5 63,57.5 50,65 37,57.5 37,42.5"
              fill="none"
              stroke="#27272a"
              stroke-width="0.5"
            ></polygon>

            <!-- Axes -->
            <line
              x1="50"
              y1="50"
              x2="50"
              y2="5"
              stroke="#27272a"
              stroke-width="0.5"
            ></line>
            <line
              x1="50"
              y1="50"
              x2="89"
              y2="27.5"
              stroke="#27272a"
              stroke-width="0.5"
            ></line>
            <line
              x1="50"
              y1="50"
              x2="89"
              y2="72.5"
              stroke="#27272a"
              stroke-width="0.5"
            ></line>
            <line
              x1="50"
              y1="50"
              x2="50"
              y2="95"
              stroke="#27272a"
              stroke-width="0.5"
            ></line>
            <line
              x1="50"
              y1="50"
              x2="11"
              y2="72.5"
              stroke="#27272a"
              stroke-width="0.5"
            ></line>
            <line
              x1="50"
              y1="50"
              x2="11"
              y2="27.5"
              stroke="#27272a"
              stroke-width="0.5"
            ></line>

            <!-- Data Polygon -->
            <polygon
              points="50,25 75,30 80,60 50,75 25,65 30,35"
              fill="rgba(255, 102, 161, 0.2)"
              stroke="#FF66A1"
              stroke-width="1.5"
              stroke-linejoin="round"
            ></polygon>

            <!-- Points -->
            <circle cx="50" cy="25" r="2.5" fill="#FF66A1"></circle>
            <circle cx="75" cy="30" r="2.5" fill="#FF66A1"></circle>
            <circle cx="80" cy="60" r="2.5" fill="#FF66A1"></circle>
            <circle cx="50" cy="75" r="2.5" fill="#FF66A1"></circle>
            <circle cx="25" cy="65" r="2.5" fill="#FF66A1"></circle>
            <circle cx="30" cy="35" r="2.5" fill="#FF66A1"></circle>

            <!-- High Contrast Labels -->
            <text
              x="50"
              y="-2"
              fill="#e4e4e7"
              font-size="4"
              text-anchor="middle"
              font-weight="500"
              font-family="Inter"
            >
              Emotional Value
            </text>
            <text
              x="95"
              y="27.5"
              fill="#e4e4e7"
              font-size="4"
              text-anchor="start"
              font-weight="500"
              font-family="Inter"
            >
              Listening
            </text>
            <text
              x="95"
              y="75"
              fill="#e4e4e7"
              font-size="4"
              text-anchor="start"
              font-weight="500"
              font-family="Inter"
            >
              Frame Control
            </text>
            <text
              x="50"
              y="102"
              fill="#e4e4e7"
              font-size="4"
              text-anchor="middle"
              font-weight="500"
              font-family="Inter"
            >
              Escalation
            </text>
            <text
              x="5"
              y="75"
              fill="#e4e4e7"
              font-size="4"
              text-anchor="end"
              font-weight="500"
              font-family="Inter"
            >
              Empathy
            </text>
            <text
              x="5"
              y="27.5"
              fill="#e4e4e7"
              font-size="4"
              text-anchor="end"
              font-weight="500"
              font-family="Inter"
            >
              Humor
            </text>
          </svg>
        </div>

        <!-- Post-Date Report -->
        <h3 class="text-sm font-medium text-zinc-400 px-2 mt-8 mb-4">
          Latest Post-Date Report
        </h3>
        <div
          class="bg-gradient-to-br from-[#141417] to-[#09090b] border border-white/5 rounded-3xl p-6 relative overflow-hidden shadow-md"
        >
          <div
            class="absolute -right-6 -top-10 text-[120px] font-medium opacity-[0.03] text-white select-none pointer-events-none"
          >
            85
          </div>

          <div class="flex items-end gap-2 mb-6">
            <span class="text-5xl tracking-tight font-medium text-[#FF66A1]">
              85
            </span>
            <span class="text-sm text-zinc-500 mb-2 font-medium">/ 100</span>
          </div>

          <div class="space-y-5">
            <div>
              <h4
                class="text-xs font-medium text-zinc-300 mb-3 uppercase tracking-wider"
              >
                What went well
              </h4>
              <ul class="space-y-2">
                <li class="flex items-start gap-2 text-sm text-zinc-400">
                  <iconify-icon
                    icon="solar:check-circle-linear"
                    class="text-[#FF66A1] mt-0.5 text-base shrink-0"
                    stroke-width="1.5"
                  ></iconify-icon>
                  <span>Maintained strong eye contact.</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-zinc-400">
                  <iconify-icon
                    icon="solar:check-circle-linear"
                    class="text-[#FF66A1] mt-0.5 text-base shrink-0"
                    stroke-width="1.5"
                  ></iconify-icon>
                  <span>Used callback humor effectively.</span>
                </li>
              </ul>
            </div>

            <div class="w-full h-px bg-white/5"></div>

            <div>
              <h4
                class="text-xs font-medium text-zinc-300 mb-3 uppercase tracking-wider"
              >
                To Improve
              </h4>
              <ul class="space-y-2">
                <li class="flex items-start gap-2 text-sm text-zinc-400">
                  <iconify-icon
                    icon="solar:info-circle-linear"
                    class="text-amber-500 mt-0.5 text-base shrink-0"
                    stroke-width="1.5"
                  ></iconify-icon>
                  <span>Interrupted 3 times during her story.</span>
                </li>
              </ul>

              <!-- Actionability: CTA to Coach -->
              <label
                for="tab-coach"
                class="mt-4 w-full bg-white/5 hover:bg-white/10 border border-white/10 rounded-xl py-3 px-4 text-xs font-medium text-zinc-300 flex items-center justify-between transition-colors cursor-pointer group"
              >
                <span>Practice Active Listening</span>
                <div
                  class="w-6 h-6 rounded-full bg-white/5 flex items-center justify-center group-hover:bg-[#FF66A1]/20 transition-colors"
                >
                  <iconify-icon
                    icon="solar:arrow-right-linear"
                    class="text-zinc-400 group-hover:text-[#FF66A1] transition-colors"
                  ></iconify-icon>
                </div>
              </label>
            </div>
          </div>
        </div>
      </main>

      <!-- VIEW: PROFILE (Train Persona) -->
      <main
        class="view-profile view-section flex-col flex-1 overflow-y-auto hide-scrollbar pb-28 px-4"
      >
        <h2
          class="text-2xl tracking-tight font-medium text-zinc-100 px-2 mt-2 mb-6"
        >
          Digital Persona
        </h2>

        <div
          class="bg-[#141417] border border-white/5 rounded-3xl p-6 relative overflow-hidden shadow-lg mt-2"
        >
          <div class="flex items-center gap-4 mb-6">
            <div
              class="w-14 h-14 rounded-full bg-gradient-to-br from-[#FF66A1] to-[#7c3aed] p-0.5 shadow-[0_0_15px_rgba(255,102,161,0.2)]"
            >
              <div
                class="w-full h-full bg-[#09090b] rounded-full flex items-center justify-center"
              >
                <iconify-icon
                  icon="solar:user-linear"
                  class="text-2xl text-zinc-200"
                  stroke-width="1.5"
                ></iconify-icon>
              </div>
            </div>
            <div>
              <h3 class="text-sm font-medium text-zinc-100">AI Clone Status</h3>
              <div class="flex items-center gap-2 mt-1">
                <div
                  class="w-16 h-1.5 bg-zinc-800 rounded-full overflow-hidden"
                >
                  <div class="w-[85%] h-full bg-[#FF66A1] rounded-full"></div>
                </div>
                <span class="text-[10px] text-[#FF66A1] font-medium">
                  85% Sync
                </span>
              </div>
            </div>
          </div>

          <p class="text-xs text-zinc-400 mb-6 leading-relaxed">
            Train your digital clone to sound exactly like you. Upload past
            successful chats so the AI learns your unique slang, humor, and
            pacing.
          </p>

          <label
            class="w-full bg-[#09090b] border border-dashed border-white/10 rounded-2xl h-28 flex flex-col items-center justify-center cursor-pointer hover:border-[#FF66A1]/50 hover:bg-[#FF66A1]/5 transition-all group"
          >
            <input type="file" class="hidden" multiple="" />
            <div
              class="w-8 h-8 rounded-full bg-white/5 flex items-center justify-center mb-2 group-hover:scale-110 transition-transform"
            >
              <iconify-icon
                icon="solar:upload-minimalistic-linear"
                class="text-lg text-zinc-400 group-hover:text-[#FF66A1] transition-colors"
              ></iconify-icon>
            </div>
            <span
              class="text-xs text-zinc-300 font-medium group-hover:text-[#FF66A1] transition-colors"
            >
              Upload Past Chats
            </span>
          </label>
        </div>

        <div
          class="bg-[#141417] border border-white/5 rounded-3xl p-6 relative shadow-lg mt-4"
        >
          <h3 class="text-sm font-medium text-zinc-100 mb-6">
            Tone Adjustments
          </h3>
          <div class="space-y-5">
            <div>
              <div class="flex justify-between items-center mb-2">
                <span class="text-xs text-zinc-400">Emoji Usage</span>
                <span class="text-[10px] text-[#FF66A1] font-medium">
                  Moderate
                </span>
              </div>
              <input type="range" min="0" max="100" value="50" class="w-full" />
              <div class="flex justify-between mt-1 px-1">
                <span class="text-[10px] text-zinc-600">None</span>
                <span class="text-[10px] text-zinc-600">Lots</span>
              </div>
            </div>
            <div>
              <div class="flex justify-between items-center mb-2">
                <span class="text-xs text-zinc-400">Sentence Length</span>
                <span class="text-[10px] text-[#FF66A1] font-medium">
                  Short
                </span>
              </div>
              <input type="range" min="0" max="100" value="30" class="w-full" />
              <div class="flex justify-between mt-1 px-1">
                <span class="text-[10px] text-zinc-600">Brief</span>
                <span class="text-[10px] text-zinc-600">Detailed</span>
              </div>
            </div>
            <div>
              <div class="flex justify-between items-center mb-2">
                <span class="text-xs text-zinc-400">Colloquialism</span>
                <span class="text-[10px] text-[#FF66A1] font-medium">
                  Casual
                </span>
              </div>
              <input type="range" min="0" max="100" value="70" class="w-full" />
              <div class="flex justify-between mt-1 px-1">
                <span class="text-[10px] text-zinc-600">Formal</span>
                <span class="text-[10px] text-zinc-600">Slang</span>
              </div>
            </div>
          </div>
        </div>

        <div
          class="bg-gradient-to-br from-[#141417] to-[#09090b] border border-[#FF66A1]/20 rounded-3xl p-6 relative shadow-lg mt-4"
        >
          <div class="flex items-center gap-3 mb-4">
            <div
              class="w-8 h-8 rounded-full bg-[#FF66A1]/10 flex items-center justify-center"
            >
              <iconify-icon
                icon="solar:test-tube-linear"
                class="text-[#FF66A1] text-lg"
              ></iconify-icon>
            </div>
            <h3 class="text-sm font-medium text-zinc-100">Sandbox Testing</h3>
          </div>
          <p class="text-xs text-zinc-400 mb-4 leading-relaxed">
            Type a basic message and see how your AI clone rewrites it.
          </p>
          <div class="bg-[#09090b] border border-white/10 rounded-xl p-3 mb-3">
            <span class="text-[10px] text-zinc-500 block mb-1">You typed:</span>
            <p class="text-sm text-zinc-300">
              What do you want to eat tonight?
            </p>
          </div>
          <div
            class="bg-[#FF66A1]/10 border border-[#FF66A1]/20 rounded-xl p-3 relative"
          >
            <div class="flex justify-between items-start mb-1">
              <span class="text-[10px] text-[#FF66A1] font-medium block">
                Clone rewritten:
              </span>
              <iconify-icon
                icon="solar:copy-linear"
                class="text-zinc-500 hover:text-zinc-300 cursor-pointer transition-colors"
              ></iconify-icon>
            </div>
            <p class="text-sm text-zinc-100">
              Ay what're we eating tonight? Kinda starving ngl 🍕
            </p>
          </div>
        </div>
        <div class="w-full h-px bg-white/5 my-8"></div>

        <div class="px-2">
          <button
            class="w-full flex items-center justify-between py-3 text-sm text-zinc-400 hover:text-zinc-200 transition-colors"
          >
            <div class="flex items-center gap-3">
              <iconify-icon
                icon="solar:settings-linear"
                class="text-lg"
                stroke-width="1.5"
              ></iconify-icon>
              <span>Account Settings</span>
            </div>
            <iconify-icon icon="solar:alt-arrow-right-linear"></iconify-icon>
          </button>
          <button
            class="w-full flex items-center justify-between py-3 text-sm text-zinc-400 hover:text-zinc-200 transition-colors"
          >
            <div class="flex items-center gap-3">
              <iconify-icon
                icon="solar:card-linear"
                class="text-lg"
                stroke-width="1.5"
              ></iconify-icon>
              <span>Subscription</span>
            </div>
            <iconify-icon icon="solar:alt-arrow-right-linear"></iconify-icon>
          </button>
        </div>
      </main>

      <!-- Bottom Navigation Bar -->
      <nav
        class="absolute bottom-0 w-full h-[90px] bg-[#09090b]/90 backdrop-blur-xl border-t border-white/5 flex justify-around items-center px-2 pb-5 z-40"
      >
        <label
          for="tab-home"
          class="nav-home flex flex-col items-center justify-center w-16 h-full text-zinc-500 cursor-pointer transition-colors hover:text-zinc-300"
        >
          <iconify-icon
            icon="solar:home-smile-linear"
            class="text-[26px] mb-1 transition-colors"
            stroke-width="1.5"
          ></iconify-icon>
          <span class="text-[10px] font-medium">Home</span>
        </label>

        <label
          for="tab-coach"
          class="nav-coach flex flex-col items-center justify-center w-16 h-full text-zinc-500 cursor-pointer transition-colors hover:text-zinc-300"
        >
          <iconify-icon
            icon="solar:magic-stick-3-linear"
            class="text-[26px] mb-1 transition-colors"
            stroke-width="1.5"
          ></iconify-icon>
          <span class="text-[10px] font-medium">Coach</span>
        </label>

        <label
          for="tab-insights"
          class="nav-insights flex flex-col items-center justify-center w-16 h-full text-zinc-500 cursor-pointer transition-colors hover:text-zinc-300"
        >
          <iconify-icon
            icon="solar:radar-linear"
            class="text-[26px] mb-1 transition-colors"
            stroke-width="1.5"
          ></iconify-icon>
          <span class="text-[10px] font-medium">Insights</span>
        </label>

        <label
          for="tab-profile"
          class="nav-profile flex flex-col items-center justify-center w-16 h-full text-zinc-500 cursor-pointer transition-colors hover:text-zinc-300"
        >
          <iconify-icon
            icon="solar:user-rounded-linear"
            class="text-[26px] mb-1 transition-colors"
            stroke-width="1.5"
          ></iconify-icon>
          <span class="text-[10px] font-medium">Profile</span>
        </label>
      </nav>
    </div>
  </body>
</html>