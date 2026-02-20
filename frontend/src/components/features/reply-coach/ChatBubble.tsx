import { cn } from "@/lib/utils";
import type { ChatMessage } from "@/types/api";

interface ChatBubbleProps {
  message: ChatMessage;
}

export function ChatBubble({ message }: ChatBubbleProps) {
  const isUser = message.sender === "user";

  return (
    <div className={cn("flex", isUser ? "justify-end" : "justify-start")}>
      <div
        className={cn(
          "max-w-[75%] rounded-bubble px-4 py-2.5 text-sm",
          isUser
            ? "bg-brand-500 text-white rounded-br-sm"
            : "bg-muted text-foreground rounded-bl-sm"
        )}
      >
        <p>{message.text}</p>
        <p
          className={cn(
            "mt-1 text-[10px]",
            isUser ? "text-white/60" : "text-muted-foreground"
          )}
        >
          {new Date(message.timestamp).toLocaleTimeString([], {
            hour: "2-digit",
            minute: "2-digit",
          })}
        </p>
      </div>
    </div>
  );
}
