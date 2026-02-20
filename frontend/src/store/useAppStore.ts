import { create } from "zustand";
import type {
  AsyncState,
  IcebreakerResponse,
  ReplyCoachResponse,
  LiveCoachHint,
  LiveCoachSessionSummary,
  LiveCoachConnectionState,
  RecordingState,
  InputMethod,
} from "@/types/api";

interface AppState {
  // === Feature 1: Icebreaker ===
  icebreaker: {
    inputMethod: InputMethod;
    imagePreview: string | null;
    sceneDescription: string;
    result: AsyncState<IcebreakerResponse>;
  };
  setIcebreakerInput: (patch: Partial<AppState["icebreaker"]>) => void;
  setIcebreakerResult: (result: AsyncState<IcebreakerResponse>) => void;
  resetIcebreaker: () => void;

  // === Feature 2: Reply Coach ===
  replyCoach: {
    inputMethod: InputMethod;
    imagePreview: string | null;
    chatText: string;
    result: AsyncState<ReplyCoachResponse>;
  };
  setReplyCoachInput: (patch: Partial<AppState["replyCoach"]>) => void;
  setReplyCoachResult: (result: AsyncState<ReplyCoachResponse>) => void;
  resetReplyCoach: () => void;

  // === Feature 3: Live Coach ===
  liveCoach: {
    connection: LiveCoachConnectionState;
    recording: RecordingState;
    activeHints: LiveCoachHint[];
    sessionSummary: AsyncState<LiveCoachSessionSummary>;
  };
  setLiveCoachConnection: (state: LiveCoachConnectionState) => void;
  setRecordingState: (state: RecordingState) => void;
  addHint: (hint: LiveCoachHint) => void;
  dismissHint: (hintId: string) => void;
  setSessionSummary: (state: AsyncState<LiveCoachSessionSummary>) => void;
  resetLiveCoach: () => void;

  // === Global ===
  activeFeature: "icebreaker" | "reply-coach" | "live-coach" | null;
  setActiveFeature: (feature: AppState["activeFeature"]) => void;
}

const initialIcebreaker: AppState["icebreaker"] = {
  inputMethod: "photo",
  imagePreview: null,
  sceneDescription: "",
  result: { status: "idle" },
};

const initialReplyCoach: AppState["replyCoach"] = {
  inputMethod: "photo",
  imagePreview: null,
  chatText: "",
  result: { status: "idle" },
};

const initialLiveCoach: AppState["liveCoach"] = {
  connection: { status: "disconnected" },
  recording: { status: "idle" },
  activeHints: [],
  sessionSummary: { status: "idle" },
};

export const useAppStore = create<AppState>((set) => ({
  // Icebreaker
  icebreaker: initialIcebreaker,
  setIcebreakerInput: (patch) =>
    set((s) => ({ icebreaker: { ...s.icebreaker, ...patch } })),
  setIcebreakerResult: (result) =>
    set((s) => ({ icebreaker: { ...s.icebreaker, result } })),
  resetIcebreaker: () => set({ icebreaker: initialIcebreaker }),

  // Reply Coach
  replyCoach: initialReplyCoach,
  setReplyCoachInput: (patch) =>
    set((s) => ({ replyCoach: { ...s.replyCoach, ...patch } })),
  setReplyCoachResult: (result) =>
    set((s) => ({ replyCoach: { ...s.replyCoach, result } })),
  resetReplyCoach: () => set({ replyCoach: initialReplyCoach }),

  // Live Coach
  liveCoach: initialLiveCoach,
  setLiveCoachConnection: (connection) =>
    set((s) => ({ liveCoach: { ...s.liveCoach, connection } })),
  setRecordingState: (recording) =>
    set((s) => ({ liveCoach: { ...s.liveCoach, recording } })),
  addHint: (hint) =>
    set((s) => ({
      liveCoach: {
        ...s.liveCoach,
        activeHints: [hint, ...s.liveCoach.activeHints].slice(0, 5),
      },
    })),
  dismissHint: (hintId) =>
    set((s) => ({
      liveCoach: {
        ...s.liveCoach,
        activeHints: s.liveCoach.activeHints.filter((h) => h.id !== hintId),
      },
    })),
  setSessionSummary: (sessionSummary) =>
    set((s) => ({ liveCoach: { ...s.liveCoach, sessionSummary } })),
  resetLiveCoach: () => set({ liveCoach: initialLiveCoach }),

  // Global
  activeFeature: null,
  setActiveFeature: (activeFeature) => set({ activeFeature }),
}));
