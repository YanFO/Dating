"use client";

import { useCallback, useState } from "react";
import { ArrowLeft, Mic, Wifi, WifiOff } from "lucide-react";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { AudioVisualizer } from "@/components/features/live-coach/AudioVisualizer";
import { RecordingControls } from "@/components/features/live-coach/RecordingControls";
import { HintStream } from "@/components/features/live-coach/HintStream";
import { SessionSummaryDialog } from "@/components/features/live-coach/SessionSummaryDialog";
import { useAppStore } from "@/store/useAppStore";
import { useAudioRecorder } from "@/hooks/useAudioRecorder";
import { useWebSocket } from "@/hooks/useWebSocket";
import { coachService } from "@/services/coachService";
import { cn } from "@/lib/utils";

export default function LiveCoachPage() {
  const liveCoach = useAppStore((s) => s.liveCoach);
  const dismissHint = useAppStore((s) => s.dismissHint);
  const setSessionSummary = useAppStore((s) => s.setSessionSummary);
  const resetLiveCoach = useAppStore((s) => s.resetLiveCoach);

  const { recording, startRecording, stopRecording, pauseRecording } =
    useAudioRecorder();
  const { connection, connect, disconnect } = useWebSocket();

  const [showSummary, setShowSummary] = useState(false);

  const isSessionActive =
    connection.status === "connected" ||
    connection.status === "connecting";
  const isRecordingActive =
    recording.status === "recording" || recording.status === "paused";

  const handleStartSession = useCallback(() => {
    connect();
    startRecording();
  }, [connect, startRecording]);

  const handleEndSession = useCallback(async () => {
    stopRecording();
    disconnect();

    setSessionSummary({ status: "loading" });
    try {
      const response = await coachService.getSessionSummary();
      if (response.success && response.data) {
        setSessionSummary({ status: "success", data: response.data });
        setShowSummary(true);
      }
    } catch {
      setSessionSummary({
        status: "error",
        message: "Failed to load summary",
      });
    }
  }, [stopRecording, disconnect, setSessionSummary]);

  const handleCloseSummary = useCallback(() => {
    setShowSummary(false);
    resetLiveCoach();
  }, [resetLiveCoach]);

  return (
    <div className="container mx-auto px-4 py-6 max-w-2xl">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <Link href="/">
            <Button variant="ghost" size="icon">
              <ArrowLeft className="h-5 w-5" />
            </Button>
          </Link>
          <div>
            <h1 className="text-2xl font-bold">Live Voice Coach</h1>
            <p className="text-sm text-muted-foreground">
              Real-time coaching during calls or dates
            </p>
          </div>
        </div>

        {/* Connection status */}
        <Badge
          variant="outline"
          className={cn(
            "gap-1",
            connection.status === "connected"
              ? "text-emotion-positive border-emotion-positive"
              : connection.status === "connecting"
                ? "text-emotion-ambiguous border-emotion-ambiguous"
                : "text-muted-foreground"
          )}
        >
          {connection.status === "connected" ? (
            <Wifi className="h-3 w-3" />
          ) : (
            <WifiOff className="h-3 w-3" />
          )}
          {connection.status === "connected"
            ? "Connected"
            : connection.status === "connecting"
              ? "Connecting..."
              : "Offline"}
        </Badge>
      </div>

      {/* Idle State */}
      {!isSessionActive && !isRecordingActive && (
        <div className="flex flex-col items-center justify-center py-16 space-y-8">
          <div className="relative">
            <div className="h-32 w-32 rounded-full bg-brand-50 flex items-center justify-center">
              <Mic className="h-12 w-12 text-brand-500" />
            </div>
          </div>

          <div className="text-center space-y-2">
            <h2 className="text-xl font-semibold">Ready to Coach</h2>
            <p className="text-sm text-muted-foreground max-w-sm">
              Start a session before your call or date. The AI will listen and
              provide real-time hints and suggestions.
            </p>
          </div>

          <Button
            size="lg"
            className="bg-brand-500 hover:bg-brand-600 gap-2 px-8"
            onClick={handleStartSession}
          >
            <Mic className="h-5 w-5" />
            Start Session
          </Button>
        </div>
      )}

      {/* Active Session */}
      {(isSessionActive || isRecordingActive) && (
        <div className="space-y-6">
          {/* Audio Visualizer */}
          <div className="rounded-xl border bg-card p-4">
            <AudioVisualizer isActive={recording.status === "recording"} />
          </div>

          {/* Recording Controls */}
          <RecordingControls
            recording={recording}
            onStart={startRecording}
            onStop={handleEndSession}
            onPause={pauseRecording}
          />

          {/* Hints */}
          <div>
            <h3 className="text-sm font-medium mb-3">Live Hints</h3>
            <HintStream
              hints={liveCoach.activeHints}
              onDismiss={dismissHint}
            />
          </div>
        </div>
      )}

      {/* Session Summary Dialog */}
      {liveCoach.sessionSummary.status === "success" && (
        <SessionSummaryDialog
          summary={liveCoach.sessionSummary.data}
          open={showSummary}
          onClose={handleCloseSummary}
        />
      )}
    </div>
  );
}
