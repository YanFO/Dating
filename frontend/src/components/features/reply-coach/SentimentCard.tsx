import { Brain, Smile } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import type { SentimentAnalysis, DetectedEmotion } from "@/types/api";

interface SentimentCardProps {
  sentiment: SentimentAnalysis;
}

const emotionColorMap: Record<DetectedEmotion, string> = {
  happy: "bg-emotion-positive/10 text-emotion-positive",
  interested: "bg-emotion-positive/10 text-emotion-positive",
  neutral: "bg-emotion-neutral/10 text-emotion-neutral",
  impatient: "bg-emotion-ambiguous/10 text-emotion-ambiguous",
  annoyed: "bg-emotion-negative/10 text-emotion-negative",
  testing: "bg-emotion-ambiguous/10 text-emotion-ambiguous",
  cold: "bg-emotion-negative/10 text-emotion-negative",
};

export function SentimentCard({ sentiment }: SentimentCardProps) {
  return (
    <Card>
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="text-base">Sentiment Analysis</CardTitle>
          <Badge
            variant="outline"
            className={cn("capitalize", emotionColorMap[sentiment.overall_emotion])}
          >
            {sentiment.overall_emotion}
          </Badge>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex items-center gap-2">
          <span className="text-xs text-muted-foreground">Confidence:</span>
          <div className="h-2 w-24 rounded-full bg-muted overflow-hidden">
            <div
              className="h-full rounded-full bg-brand-500"
              style={{ width: `${sentiment.confidence * 100}%` }}
            />
          </div>
          <span className="text-xs text-muted-foreground">
            {Math.round(sentiment.confidence * 100)}%
          </span>
        </div>

        <div className="flex items-start gap-2">
          <Brain className="h-4 w-4 text-brand-500 mt-0.5 shrink-0" />
          <div>
            <p className="text-xs font-medium mb-1">Hidden Subtext</p>
            <p className="text-sm text-muted-foreground leading-relaxed">
              {sentiment.subtext}
            </p>
          </div>
        </div>

        {sentiment.emoji_analysis && (
          <div className="flex items-start gap-2">
            <Smile className="h-4 w-4 text-coach-humorous mt-0.5 shrink-0" />
            <div>
              <p className="text-xs font-medium mb-1">Emoji Analysis</p>
              <p className="text-sm text-muted-foreground leading-relaxed">
                {sentiment.emoji_analysis}
              </p>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
