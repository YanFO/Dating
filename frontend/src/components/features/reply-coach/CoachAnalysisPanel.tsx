import {
  AlertTriangle,
  TrendingUp,
  Brain,
  CheckCircle2,
  XCircle,
  Lightbulb,
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import type { CoachAnalysis } from "@/types/api";

interface CoachAnalysisPanelProps {
  analysis: CoachAnalysis;
}

export function CoachAnalysisPanel({ analysis }: CoachAnalysisPanelProps) {
  return (
    <div className="space-y-4">
      {/* Situation Summary */}
      <Card>
        <CardHeader className="pb-3">
          <div className="flex items-center gap-2">
            <Brain className="h-5 w-5 text-brand-500" />
            <CardTitle className="text-base">Situation Summary</CardTitle>
          </div>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground leading-relaxed">
            {analysis.situation_summary}
          </p>
        </CardContent>
      </Card>

      {/* Detected Patterns */}
      <Card>
        <CardHeader className="pb-3">
          <div className="flex items-center gap-2">
            <AlertTriangle className="h-5 w-5 text-emotion-ambiguous" />
            <CardTitle className="text-base">Detected Patterns</CardTitle>
          </div>
        </CardHeader>
        <CardContent>
          <ul className="space-y-2">
            {analysis.detected_patterns.map((pattern, i) => (
              <li key={i} className="flex items-start gap-2 text-sm text-muted-foreground">
                <span className="text-emotion-ambiguous mt-1">&#x2022;</span>
                {pattern}
              </li>
            ))}
          </ul>
        </CardContent>
      </Card>

      {/* Strategy & Insight */}
      <Card>
        <CardHeader className="pb-3">
          <div className="flex items-center gap-2">
            <TrendingUp className="h-5 w-5 text-coach-confident" />
            <CardTitle className="text-base">Recommended Strategy</CardTitle>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-muted-foreground leading-relaxed">
            {analysis.recommended_strategy}
          </p>
          <Separator />
          <div className="flex items-start gap-2">
            <Lightbulb className="h-4 w-4 text-coach-humorous mt-0.5 shrink-0" />
            <div>
              <p className="text-xs font-medium mb-1">Psychological Insight</p>
              <p className="text-sm text-muted-foreground leading-relaxed">
                {analysis.psychological_insight}
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Do / Don't Lists */}
      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader className="pb-3">
            <div className="flex items-center gap-2">
              <CheckCircle2 className="h-5 w-5 text-emotion-positive" />
              <CardTitle className="text-base">Do</CardTitle>
            </div>
          </CardHeader>
          <CardContent>
            <ul className="space-y-2">
              {analysis.do_list.map((item, i) => (
                <li key={i} className="flex items-start gap-2 text-sm text-muted-foreground">
                  <CheckCircle2 className="h-3.5 w-3.5 text-emotion-positive mt-1 shrink-0" />
                  {item}
                </li>
              ))}
            </ul>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-3">
            <div className="flex items-center gap-2">
              <XCircle className="h-5 w-5 text-emotion-negative" />
              <CardTitle className="text-base">Don&apos;t</CardTitle>
            </div>
          </CardHeader>
          <CardContent>
            <ul className="space-y-2">
              {analysis.dont_list.map((item, i) => (
                <li key={i} className="flex items-start gap-2 text-sm text-muted-foreground">
                  <XCircle className="h-3.5 w-3.5 text-emotion-negative mt-1 shrink-0" />
                  {item}
                </li>
              ))}
            </ul>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
