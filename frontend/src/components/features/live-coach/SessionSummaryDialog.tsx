"use client";

import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Card, CardContent } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { Button } from "@/components/ui/button";
import { Clock, Lightbulb, TrendingUp, Star } from "lucide-react";
import { formatDuration } from "@/utils/audioUtils";
import { cn } from "@/lib/utils";
import type { LiveCoachSessionSummary } from "@/types/api";

interface SessionSummaryDialogProps {
  summary: LiveCoachSessionSummary;
  open: boolean;
  onClose: () => void;
}

export function SessionSummaryDialog({
  summary,
  open,
  onClose,
}: SessionSummaryDialogProps) {
  const scoreColor =
    summary.conversation_flow_score >= 70
      ? "text-emotion-positive"
      : summary.conversation_flow_score >= 40
        ? "text-emotion-ambiguous"
        : "text-emotion-negative";

  return (
    <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-w-md max-h-[80vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Session Summary</DialogTitle>
        </DialogHeader>

        <div className="space-y-4">
          {/* Score */}
          <div className="text-center py-4">
            <p className={cn("text-5xl font-bold", scoreColor)}>
              {summary.conversation_flow_score}
            </p>
            <p className="text-sm text-muted-foreground mt-1">
              Conversation Flow Score
            </p>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-2 gap-3">
            <Card>
              <CardContent className="flex items-center gap-2 p-3">
                <Clock className="h-4 w-4 text-brand-500" />
                <div>
                  <p className="text-sm font-semibold">
                    {formatDuration(summary.duration_seconds)}
                  </p>
                  <p className="text-[10px] text-muted-foreground">Duration</p>
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="flex items-center gap-2 p-3">
                <Lightbulb className="h-4 w-4 text-coach-humorous" />
                <div>
                  <p className="text-sm font-semibold">
                    {summary.total_hints_shown}
                  </p>
                  <p className="text-[10px] text-muted-foreground">Hints Shown</p>
                </div>
              </CardContent>
            </Card>
          </div>

          <Separator />

          {/* Key Moments */}
          <div>
            <div className="flex items-center gap-2 mb-2">
              <Star className="h-4 w-4 text-coach-humorous" />
              <p className="text-sm font-semibold">Key Moments</p>
            </div>
            <ul className="space-y-2">
              {summary.key_moments.map((moment, i) => (
                <li
                  key={i}
                  className="text-sm text-muted-foreground flex items-start gap-2"
                >
                  <span className="text-brand-500 mt-1">&#x2022;</span>
                  {moment}
                </li>
              ))}
            </ul>
          </div>

          <Separator />

          {/* Improvement Tips */}
          <div>
            <div className="flex items-center gap-2 mb-2">
              <TrendingUp className="h-4 w-4 text-coach-confident" />
              <p className="text-sm font-semibold">Tips for Next Time</p>
            </div>
            <ul className="space-y-2">
              {summary.improvement_tips.map((tip, i) => (
                <li
                  key={i}
                  className="text-sm text-muted-foreground flex items-start gap-2"
                >
                  <span className="text-coach-confident mt-1">&#x2022;</span>
                  {tip}
                </li>
              ))}
            </ul>
          </div>

          <Button onClick={onClose} className="w-full mt-2">
            Done
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
