import { HintCard } from "./HintCard";
import type { LiveCoachHint } from "@/types/api";

interface HintStreamProps {
  hints: LiveCoachHint[];
  onDismiss: (id: string) => void;
}

export function HintStream({ hints, onDismiss }: HintStreamProps) {
  if (hints.length === 0) {
    return (
      <div className="text-center py-8">
        <p className="text-sm text-muted-foreground">
          Listening... hints will appear here
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {hints.map((hint) => (
        <HintCard key={hint.id} hint={hint} onDismiss={onDismiss} />
      ))}
    </div>
  );
}
