"use client";

import { cn } from "@/lib/utils";

interface AudioVisualizerProps {
  isActive: boolean;
}

export function AudioVisualizer({ isActive }: AudioVisualizerProps) {
  const bars = 24;

  return (
    <div className="flex items-center justify-center gap-[3px] h-16">
      {Array.from({ length: bars }).map((_, i) => (
        <div
          key={i}
          className={cn(
            "w-1 rounded-full bg-brand-500 transition-all",
            isActive ? "animate-pulse" : "h-1"
          )}
          style={
            isActive
              ? {
                  height: `${Math.random() * 48 + 8}px`,
                  animationDelay: `${i * 0.05}s`,
                  animationDuration: `${0.4 + Math.random() * 0.4}s`,
                }
              : { height: "4px" }
          }
        />
      ))}
    </div>
  );
}
