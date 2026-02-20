import type {
  IcebreakerRequest,
  IcebreakerResponse,
  ReplyCoachRequest,
  ReplyCoachResponse,
  LiveCoachHint,
  LiveCoachSessionSummary,
  ApiResponse,
} from "@/types/api";
import {
  simulateDelay,
  MOCK_ICEBREAKER_RESPONSE,
  MOCK_REPLY_COACH_RESPONSE,
  MOCK_LIVE_COACH_HINTS,
  MOCK_SESSION_SUMMARY,
} from "./mockData";

function wrapResponse<T>(data: T): ApiResponse<T> {
  return {
    success: true,
    request_id: crypto.randomUUID(),
    data,
    error: null,
  };
}

export const coachService = {
  async analyzeScene(
    _request: IcebreakerRequest
  ): Promise<ApiResponse<IcebreakerResponse>> {
    await simulateDelay(2000);
    return wrapResponse(MOCK_ICEBREAKER_RESPONSE);
  },

  async analyzeChat(
    _request: ReplyCoachRequest
  ): Promise<ApiResponse<ReplyCoachResponse>> {
    await simulateDelay(2500);
    return wrapResponse(MOCK_REPLY_COACH_RESPONSE);
  },

  async getLiveCoachHint(): Promise<ApiResponse<LiveCoachHint>> {
    await simulateDelay(3000);
    const randomHint =
      MOCK_LIVE_COACH_HINTS[
        Math.floor(Math.random() * MOCK_LIVE_COACH_HINTS.length)
      ];
    return wrapResponse(randomHint);
  },

  async getSessionSummary(): Promise<ApiResponse<LiveCoachSessionSummary>> {
    await simulateDelay(1000);
    return wrapResponse(MOCK_SESSION_SUMMARY);
  },
};
