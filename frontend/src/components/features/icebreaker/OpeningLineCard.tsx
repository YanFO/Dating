import { MessageSquareQuote, Lightbulb } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import type { OpeningLine } from "@/types/api";

interface OpeningLineCardProps {
  line: OpeningLine;
}

const toneColorMap: Record<string, string> = {
  humorous: "bg-coach-humorous/10 text-coach-humorous border-coach-humorous/30",
  sincere: "bg-coach-sincere/10 text-coach-sincere border-coach-sincere/30",
  flirty: "bg-coach-flirty/10 text-coach-flirty border-coach-flirty/30",
  confident: "bg-coach-confident/10 text-coach-confident border-coach-confident/30",
};

export function OpeningLineCard({ line }: OpeningLineCardProps) {
  return (
    <Card className="overflow-hidden">
      <CardContent className="p-4 space-y-3">
        <div className="flex items-center justify-between">
          <Badge
            variant="outline"
            className={cn("capitalize", toneColorMap[line.tone])}
          >
            {line.tone}
          </Badge>
          <div className="flex items-center gap-1.5">
            <div className="h-2 w-16 rounded-full bg-muted overflow-hidden">
              <div
                className="h-full rounded-full bg-brand-500 transition-all"
                style={{ width: `${line.success_probability}%` }}
              />
            </div>
            <span className="text-xs text-muted-foreground">
              {line.success_probability}%
            </span>
          </div>
        </div>

        <div className="flex items-start gap-2">
          <MessageSquareQuote className="h-4 w-4 text-brand-400 mt-1 shrink-0" />
          <p className="text-sm leading-relaxed">{line.line}</p>
        </div>

        <div className="flex items-start gap-2 rounded-lg bg-muted/50 p-3">
          <Lightbulb className="h-4 w-4 text-coach-humorous mt-0.5 shrink-0" />
          <p className="text-xs text-muted-foreground leading-relaxed">
            {line.explanation}
          </p>
        </div>
      </CardContent>
    </Card>
  );
}
