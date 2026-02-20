import { MapPin, Eye, Cloud } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import type { SceneAnalysis } from "@/types/api";

interface SceneAnalysisCardProps {
  analysis: SceneAnalysis;
}

export function SceneAnalysisCard({ analysis }: SceneAnalysisCardProps) {
  return (
    <Card>
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="text-base">Scene Analysis</CardTitle>
          <Badge variant="secondary">
            {Math.round(analysis.confidence * 100)}% confidence
          </Badge>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex items-start gap-3">
          <MapPin className="h-5 w-5 text-brand-500 mt-0.5 shrink-0" />
          <div>
            <p className="text-sm font-medium">Location</p>
            <p className="text-sm text-muted-foreground capitalize">
              {analysis.location_type.replace(/_/g, " ")}
            </p>
          </div>
        </div>

        <div className="flex items-start gap-3">
          <Eye className="h-5 w-5 text-brand-500 mt-0.5 shrink-0" />
          <div>
            <p className="text-sm font-medium">Observed Details</p>
            <ul className="mt-1 space-y-1">
              {analysis.observed_details.map((detail, i) => (
                <li key={i} className="text-sm text-muted-foreground">
                  {detail}
                </li>
              ))}
            </ul>
          </div>
        </div>

        <div className="flex items-start gap-3">
          <Cloud className="h-5 w-5 text-brand-500 mt-0.5 shrink-0" />
          <div>
            <p className="text-sm font-medium">Atmosphere</p>
            <p className="text-sm text-muted-foreground">{analysis.atmosphere}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
