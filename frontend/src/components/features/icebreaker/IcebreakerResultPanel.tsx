import { Target } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { SceneAnalysisCard } from "./SceneAnalysisCard";
import { OpeningLineCard } from "./OpeningLineCard";
import { NonVerbalTipsList } from "./NonVerbalTipsList";
import type { IcebreakerResponse } from "@/types/api";

interface IcebreakerResultPanelProps {
  result: IcebreakerResponse;
}

export function IcebreakerResultPanel({ result }: IcebreakerResultPanelProps) {
  return (
    <div className="space-y-6">
      <SceneAnalysisCard analysis={result.scene_analysis} />

      <div>
        <h3 className="mb-3 text-base font-semibold">Opening Lines</h3>
        <div className="space-y-3">
          {result.opening_lines.map((line) => (
            <OpeningLineCard key={line.id} line={line} />
          ))}
        </div>
      </div>

      <NonVerbalTipsList tips={result.non_verbal_tips} />

      <Card>
        <CardHeader className="pb-3">
          <div className="flex items-center gap-2">
            <Target className="h-5 w-5 text-brand-500" />
            <CardTitle className="text-base">Overall Strategy</CardTitle>
          </div>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground leading-relaxed">
            {result.overall_strategy}
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
