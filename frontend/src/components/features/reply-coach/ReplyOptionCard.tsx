"use client";

import { useCallback, useState } from "react";
import { Copy, Check, ArrowRight } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import type { ReplyOption } from "@/types/api";

interface ReplyOptionCardProps {
  option: ReplyOption;
}

const toneColorMap: Record<string, string> = {
  humorous: "bg-coach-humorous/10 text-coach-humorous border-coach-humorous/30",
  sincere: "bg-coach-sincere/10 text-coach-sincere border-coach-sincere/30",
  flirty: "bg-coach-flirty/10 text-coach-flirty border-coach-flirty/30",
  confident: "bg-coach-confident/10 text-coach-confident border-coach-confident/30",
};

const riskColorMap: Record<string, string> = {
  safe: "bg-emotion-positive/10 text-emotion-positive",
  moderate: "bg-emotion-ambiguous/10 text-emotion-ambiguous",
  bold: "bg-emotion-negative/10 text-emotion-negative",
};

export function ReplyOptionCard({ option }: ReplyOptionCardProps) {
  const [copied, setCopied] = useState(false);

  const handleCopy = useCallback(async () => {
    await navigator.clipboard.writeText(option.message);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }, [option.message]);

  return (
    <Card>
      <CardContent className="p-4 space-y-3">
        <div className="flex items-center gap-2">
          <Badge
            variant="outline"
            className={cn("capitalize", toneColorMap[option.tone])}
          >
            {option.tone}
          </Badge>
          <Badge
            variant="secondary"
            className={cn("capitalize text-[10px]", riskColorMap[option.risk_level])}
          >
            {option.risk_level} risk
          </Badge>
        </div>

        <div className="relative rounded-lg bg-muted/50 p-3">
          <p className="text-sm leading-relaxed pr-8">{option.message}</p>
          <Button
            variant="ghost"
            size="icon"
            className="absolute top-2 right-2 h-7 w-7"
            onClick={handleCopy}
          >
            {copied ? (
              <Check className="h-3.5 w-3.5 text-emotion-positive" />
            ) : (
              <Copy className="h-3.5 w-3.5" />
            )}
          </Button>
        </div>

        <div className="flex items-start gap-2 text-xs text-muted-foreground">
          <ArrowRight className="h-3.5 w-3.5 mt-0.5 shrink-0" />
          <p>{option.expected_reaction}</p>
        </div>
      </CardContent>
    </Card>
  );
}
