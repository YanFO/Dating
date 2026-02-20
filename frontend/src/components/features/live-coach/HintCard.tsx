"use client";

import { useEffect, useState } from "react";
import {
  Lightbulb,
  AlertTriangle,
  ThumbsUp,
  HelpCircle,
  X,
} from "lucide-react";
import { cn } from "@/lib/utils";
import type { LiveCoachHint } from "@/types/api";

interface HintCardProps {
  hint: LiveCoachHint;
  onDismiss: (id: string) => void;
}

const hintConfig: Record<
  LiveCoachHint["type"],
  { icon: React.ElementType; borderColor: string; bgColor: string }
> = {
  topic_suggestion: {
    icon: Lightbulb,
    borderColor: "border-coach-humorous",
    bgColor: "bg-coach-humorous/5",
  },
  warning: {
    icon: AlertTriangle,
    borderColor: "border-emotion-negative",
    bgColor: "bg-emotion-negative/5",
  },
  encouragement: {
    icon: ThumbsUp,
    borderColor: "border-emotion-positive",
    bgColor: "bg-emotion-positive/5",
  },
  question_prompt: {
    icon: HelpCircle,
    borderColor: "border-coach-sincere",
    bgColor: "bg-coach-sincere/5",
  },
};

const urgencyColors: Record<string, string> = {
  high: "text-emotion-negative",
  medium: "text-emotion-ambiguous",
  low: "text-emotion-positive",
};

export function HintCard({ hint, onDismiss }: HintCardProps) {
  const [timeLeft, setTimeLeft] = useState(hint.expires_in_seconds);
  const config = hintConfig[hint.type];
  const Icon = config.icon;

  useEffect(() => {
    const interval = setInterval(() => {
      setTimeLeft((prev) => {
        if (prev <= 1) {
          onDismiss(hint.id);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
    return () => clearInterval(interval);
  }, [hint.id, onDismiss]);

  return (
    <div
      className={cn(
        "relative rounded-xl border-l-4 p-4 shadow-sm transition-all",
        config.borderColor,
        config.bgColor
      )}
    >
      <button
        onClick={() => onDismiss(hint.id)}
        className="absolute top-2 right-2 rounded-full p-1 hover:bg-black/5 transition-colors"
      >
        <X className="h-3.5 w-3.5 text-muted-foreground" />
      </button>

      <div className="flex items-start gap-3 pr-6">
        <Icon className={cn("h-5 w-5 mt-0.5 shrink-0", urgencyColors[hint.urgency])} />
        <div className="flex-1">
          <p className="text-sm leading-relaxed">{hint.content}</p>
          <div className="mt-2 flex items-center gap-2">
            <div className="h-1 flex-1 rounded-full bg-muted overflow-hidden">
              <div
                className={cn("h-full rounded-full transition-all duration-1000", {
                  "bg-emotion-negative": hint.urgency === "high",
                  "bg-emotion-ambiguous": hint.urgency === "medium",
                  "bg-emotion-positive": hint.urgency === "low",
                })}
                style={{
                  width: `${(timeLeft / hint.expires_in_seconds) * 100}%`,
                }}
              />
            </div>
            <span className="text-[10px] text-muted-foreground tabular-nums">
              {timeLeft}s
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
