"use client";

import { useMemo } from "react";
import { useAppStore } from "@/store/useAppStore";
import type { ChatMessage } from "@/types/api";

export function useChatHistory() {
  const result = useAppStore((s) => s.replyCoach.result);

  const messages: ChatMessage[] = useMemo(() => {
    if (result.status === "success") {
      return result.data.parsed_messages;
    }
    return [];
  }, [result]);

  const messageCount = messages.length;
  const lastMessage = messages.length > 0 ? messages[messages.length - 1] : null;

  return { messages, messageCount, lastMessage };
}
