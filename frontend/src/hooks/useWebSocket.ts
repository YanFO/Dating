"use client";

import { useCallback, useRef, useEffect } from "react";
import { useAppStore } from "@/store/useAppStore";
import { MOCK_LIVE_COACH_HINTS } from "@/services/mockData";

export function useWebSocket() {
  const connection = useAppStore((s) => s.liveCoach.connection);
  const setLiveCoachConnection = useAppStore((s) => s.setLiveCoachConnection);
  const addHint = useAppStore((s) => s.addHint);

  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const connect = useCallback(() => {
    setLiveCoachConnection({ status: "connecting" });

    // Phase 1: simulate connection delay
    setTimeout(() => {
      setLiveCoachConnection({
        status: "connected",
        session_id: crypto.randomUUID(),
      });

      // Simulate receiving hints every 5-8 seconds
      intervalRef.current = setInterval(() => {
        const source =
          MOCK_LIVE_COACH_HINTS[
            Math.floor(Math.random() * MOCK_LIVE_COACH_HINTS.length)
          ];
        const randomHint = {
          ...source,
          id: crypto.randomUUID(),
          timestamp: Date.now(),
        };
        addHint(randomHint);
      }, 5000 + Math.random() * 3000);
    }, 1000);
  }, [setLiveCoachConnection, addHint]);

  const disconnect = useCallback(() => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }
    setLiveCoachConnection({ status: "disconnected" });
  }, [setLiveCoachConnection]);

  useEffect(() => {
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, []);

  return { connection, connect, disconnect };
}
