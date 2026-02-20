"use client";

import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ChatPreview } from "./ChatPreview";
import { SentimentCard } from "./SentimentCard";
import { ReplyOptionCard } from "./ReplyOptionCard";
import { CoachAnalysisPanel } from "./CoachAnalysisPanel";
import type { ReplyCoachResponse } from "@/types/api";

interface ReplyCoachResultPanelProps {
  result: ReplyCoachResponse;
}

export function ReplyCoachResultPanel({ result }: ReplyCoachResultPanelProps) {
  return (
    <Tabs defaultValue="replies" className="w-full">
      <TabsList className="grid w-full grid-cols-2">
        <TabsTrigger value="replies">Replies</TabsTrigger>
        <TabsTrigger value="analysis">Coach Analysis</TabsTrigger>
      </TabsList>

      <TabsContent value="replies" className="space-y-4 mt-4">
        <ChatPreview messages={result.parsed_messages} />
        <SentimentCard sentiment={result.sentiment} />
        <div>
          <h3 className="mb-3 text-base font-semibold">Suggested Replies</h3>
          <div className="space-y-3">
            {result.reply_options.map((option) => (
              <ReplyOptionCard key={option.id} option={option} />
            ))}
          </div>
        </div>
      </TabsContent>

      <TabsContent value="analysis" className="mt-4">
        <CoachAnalysisPanel analysis={result.coach_analysis} />
      </TabsContent>
    </Tabs>
  );
}
