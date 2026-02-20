import { User, Move, Clock, Smile } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import type { NonVerbalTip } from "@/types/api";

interface NonVerbalTipsListProps {
  tips: NonVerbalTip[];
}

const categoryIcons: Record<string, React.ElementType> = {
  body_language: User,
  positioning: Move,
  timing: Clock,
  expression: Smile,
};

const importanceColors: Record<string, string> = {
  high: "bg-emotion-negative/10 text-emotion-negative",
  medium: "bg-emotion-ambiguous/10 text-emotion-ambiguous",
  low: "bg-emotion-positive/10 text-emotion-positive",
};

export function NonVerbalTipsList({ tips }: NonVerbalTipsListProps) {
  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-base">Non-Verbal Tips</CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        {tips.map((tip) => {
          const Icon = categoryIcons[tip.category] ?? User;
          return (
            <div key={tip.id} className="flex items-start gap-3">
              <Icon className="h-5 w-5 text-brand-500 mt-0.5 shrink-0" />
              <div className="flex-1 space-y-1">
                <div className="flex items-center gap-2">
                  <span className="text-sm font-medium capitalize">
                    {tip.category.replace(/_/g, " ")}
                  </span>
                  <Badge
                    variant="secondary"
                    className={cn("text-[10px] px-1.5 py-0", importanceColors[tip.importance])}
                  >
                    {tip.importance}
                  </Badge>
                </div>
                <p className="text-sm text-muted-foreground">{tip.tip}</p>
              </div>
            </div>
          );
        })}
      </CardContent>
    </Card>
  );
}
