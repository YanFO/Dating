// ============================================================
// Shared / Common Types
// ============================================================

/** Union-based state machine for async operations */
export type AsyncState<T> =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: T }
  | { status: "error"; message: string };

/** Standard API response envelope */
export interface ApiResponse<T> {
  success: boolean;
  request_id: string;
  data: T | null;
  error: ApiError | null;
}

export interface ApiError {
  code: string;
  message: string;
  details?: Record<string, unknown>;
}

/** Supported tone styles for reply generation */
export type ToneStyle = "humorous" | "sincere" | "flirty" | "confident";

/** Detected emotion from sentiment analysis */
export type DetectedEmotion =
  | "happy"
  | "interested"
  | "neutral"
  | "impatient"
  | "annoyed"
  | "testing"
  | "cold";

/** Input method for features */
export type InputMethod = "photo" | "text" | "both";

// ============================================================
// Feature 1: Context-Aware Icebreaker
// ============================================================

export interface IcebreakerRequest {
  image_base64?: string;
  scene_description?: string;
  input_method: InputMethod;
}

export interface SceneAnalysis {
  location_type: string;
  observed_details: string[];
  atmosphere: string;
  confidence: number;
}

export interface OpeningLine {
  id: string;
  tone: ToneStyle;
  line: string;
  explanation: string;
  success_probability: number;
}

export interface NonVerbalTip {
  id: string;
  category: "body_language" | "positioning" | "timing" | "expression";
  tip: string;
  importance: "high" | "medium" | "low";
}

export interface IcebreakerResponse {
  scene_analysis: SceneAnalysis;
  opening_lines: OpeningLine[];
  non_verbal_tips: NonVerbalTip[];
  overall_strategy: string;
}

// ============================================================
// Feature 2: Semantic & Emotion Reply Engine
// ============================================================

export interface ReplyCoachRequest {
  image_base64?: string;
  chat_text?: string;
  input_method: InputMethod;
}

export interface ChatMessage {
  id: string;
  sender: "user" | "other";
  text: string;
  timestamp: string;
}

export interface SentimentAnalysis {
  overall_emotion: DetectedEmotion;
  confidence: number;
  subtext: string;
  emoji_analysis?: string;
}

export interface ReplyOption {
  id: string;
  tone: ToneStyle;
  message: string;
  risk_level: "safe" | "moderate" | "bold";
  expected_reaction: string;
}

export interface CoachAnalysis {
  situation_summary: string;
  detected_patterns: string[];
  recommended_strategy: string;
  psychological_insight: string;
  do_list: string[];
  dont_list: string[];
}

export interface ReplyCoachResponse {
  parsed_messages: ChatMessage[];
  sentiment: SentimentAnalysis;
  reply_options: ReplyOption[];
  coach_analysis: CoachAnalysis;
}

// ============================================================
// Feature 3: Real-time Voice Coaching
// ============================================================

export type LiveCoachConnectionState =
  | { status: "disconnected" }
  | { status: "connecting" }
  | { status: "connected"; session_id: string }
  | { status: "error"; message: string };

export type RecordingState =
  | { status: "idle" }
  | { status: "requesting_permission" }
  | { status: "recording"; duration_seconds: number }
  | { status: "paused"; duration_seconds: number }
  | { status: "error"; message: string };

export interface LiveCoachHint {
  id: string;
  type: "topic_suggestion" | "warning" | "encouragement" | "question_prompt";
  content: string;
  urgency: "low" | "medium" | "high";
  timestamp: number;
  expires_in_seconds: number;
}

export interface ConversationInsight {
  id: string;
  speaker: "user" | "other";
  emotion: DetectedEmotion;
  transcript_snippet: string;
  timestamp: number;
}

export interface LiveCoachSessionSummary {
  duration_seconds: number;
  total_hints_shown: number;
  conversation_flow_score: number;
  key_moments: string[];
  improvement_tips: string[];
}
