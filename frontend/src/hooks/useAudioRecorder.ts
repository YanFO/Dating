"use client";

import { useCallback, useRef, useEffect } from "react";
import { useAppStore } from "@/store/useAppStore";

export function useAudioRecorder() {
  const recording = useAppStore((s) => s.liveCoach.recording);
  const setRecordingState = useAppStore((s) => s.setRecordingState);

  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const startRecording = useCallback(() => {
    setRecordingState({ status: "requesting_permission" });

    // Phase 1: simulate permission granted after 500ms
    setTimeout(() => {
      setRecordingState({ status: "recording", duration_seconds: 0 });

      timerRef.current = setInterval(() => {
        useAppStore.setState((s) => {
          if (s.liveCoach.recording.status === "recording") {
            return {
              liveCoach: {
                ...s.liveCoach,
                recording: {
                  status: "recording" as const,
                  duration_seconds: s.liveCoach.recording.duration_seconds + 1,
                },
              },
            };
          }
          return s;
        });
      }, 1000);
    }, 500);
  }, [setRecordingState]);

  const stopRecording = useCallback(() => {
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
    setRecordingState({ status: "idle" });
  }, [setRecordingState]);

  const pauseRecording = useCallback(() => {
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
    if (recording.status === "recording") {
      setRecordingState({
        status: "paused",
        duration_seconds: recording.duration_seconds,
      });
    }
  }, [recording, setRecordingState]);

  useEffect(() => {
    return () => {
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
    };
  }, []);

  return { recording, startRecording, stopRecording, pauseRecording };
}
