"use client";

import { Mic, MicOff, Pause, Square } from "lucide-react";
import { Button } from "@/components/ui/button";
import { formatDuration } from "@/utils/audioUtils";
import { cn } from "@/lib/utils";
import type { RecordingState } from "@/types/api";

interface RecordingControlsProps {
  recording: RecordingState;
  onStart: () => void;
  onStop: () => void;
  onPause: () => void;
}

export function RecordingControls({
  recording,
  onStart,
  onStop,
  onPause,
}: RecordingControlsProps) {
  const isRecording = recording.status === "recording";
  const isPaused = recording.status === "paused";
  const isRequesting = recording.status === "requesting_permission";
  const duration =
    recording.status === "recording" || recording.status === "paused"
      ? recording.duration_seconds
      : 0;

  return (
    <div className="flex flex-col items-center gap-4">
      {/* Duration display */}
      {(isRecording || isPaused) && (
        <div className="text-center">
          <p className="text-3xl font-mono font-bold tabular-nums">
            {formatDuration(duration)}
          </p>
          <p
            className={cn(
              "text-xs mt-1",
              isRecording ? "text-emotion-negative" : "text-emotion-ambiguous"
            )}
          >
            {isRecording ? "Recording..." : "Paused"}
          </p>
        </div>
      )}

      {/* Controls */}
      <div className="flex items-center gap-4">
        {recording.status === "idle" && (
          <Button
            size="lg"
            className="h-16 w-16 rounded-full bg-brand-500 hover:bg-brand-600"
            onClick={onStart}
          >
            <Mic className="h-6 w-6" />
          </Button>
        )}

        {isRequesting && (
          <Button size="lg" className="h-16 w-16 rounded-full" disabled>
            <Mic className="h-6 w-6 animate-pulse" />
          </Button>
        )}

        {isRecording && (
          <>
            <Button
              variant="outline"
              size="icon"
              className="h-12 w-12 rounded-full"
              onClick={onPause}
            >
              <Pause className="h-5 w-5" />
            </Button>
            <Button
              size="icon"
              className="h-16 w-16 rounded-full bg-emotion-negative hover:bg-emotion-negative/90"
              onClick={onStop}
            >
              <Square className="h-6 w-6" />
            </Button>
          </>
        )}

        {isPaused && (
          <>
            <Button
              size="icon"
              className="h-12 w-12 rounded-full bg-brand-500 hover:bg-brand-600"
              onClick={onStart}
            >
              <Mic className="h-5 w-5" />
            </Button>
            <Button
              size="icon"
              className="h-16 w-16 rounded-full bg-emotion-negative hover:bg-emotion-negative/90"
              onClick={onStop}
            >
              <Square className="h-6 w-6" />
            </Button>
          </>
        )}

        {recording.status === "error" && (
          <div className="text-center space-y-2">
            <MicOff className="h-8 w-8 text-emotion-negative mx-auto" />
            <p className="text-sm text-emotion-negative">{recording.message}</p>
            <Button variant="outline" onClick={onStart}>
              Retry
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}
