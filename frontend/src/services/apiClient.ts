const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000";

/** Base API client -- Phase 2 will add fetch with interceptors */
export const apiClient = {
  baseUrl: API_BASE_URL,
};
