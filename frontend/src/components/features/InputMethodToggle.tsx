"use client";

import type { InputMethod } from "@/types/api";
import { cn } from "@/lib/utils";

interface InputMethodToggleProps {
  value: InputMethod;
  onChange: (method: InputMethod) => void;
}

const methods: { value: InputMethod; label: string }[] = [
  { value: "photo", label: "Photo" },
  { value: "text", label: "Text" },
  { value: "both", label: "Both" },
];

export function InputMethodToggle({ value, onChange }: InputMethodToggleProps) {
  return (
    <div className="inline-flex rounded-lg bg-muted p-1">
      {methods.map((m) => (
        <button
          key={m.value}
          onClick={() => onChange(m.value)}
          className={cn(
            "rounded-md px-4 py-2 text-sm font-medium transition-colors",
            value === m.value
              ? "bg-background text-foreground shadow-sm"
              : "text-muted-foreground hover:text-foreground"
          )}
        >
          {m.label}
        </button>
      ))}
    </div>
  );
}
