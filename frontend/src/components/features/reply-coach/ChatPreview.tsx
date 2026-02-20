import { ScrollArea } from "@/components/ui/scroll-area";
import { ChatBubble } from "./ChatBubble";
import type { ChatMessage } from "@/types/api";

interface ChatPreviewProps {
  messages: ChatMessage[];
}

export function ChatPreview({ messages }: ChatPreviewProps) {
  return (
    <div className="rounded-xl border bg-card">
      <div className="border-b px-4 py-3">
        <p className="text-sm font-medium">Chat Preview</p>
        <p className="text-xs text-muted-foreground">
          {messages.length} messages analyzed
        </p>
      </div>
      <ScrollArea className="h-72 p-4">
        <div className="space-y-3">
          {messages.map((msg) => (
            <ChatBubble key={msg.id} message={msg} />
          ))}
        </div>
      </ScrollArea>
    </div>
  );
}
