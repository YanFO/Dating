"use client";

import { useCallback } from "react";
import { ArrowLeft, Sparkles, RotateCcw } from "lucide-react";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Skeleton } from "@/components/ui/skeleton";
import { ImageUploader } from "@/components/features/ImageUploader";
import { InputMethodToggle } from "@/components/features/InputMethodToggle";
import { ReplyCoachResultPanel } from "@/components/features/reply-coach/ReplyCoachResultPanel";
import { useAppStore } from "@/store/useAppStore";
import { coachService } from "@/services/coachService";
import type { InputMethod } from "@/types/api";

export default function ReplyCoachPage() {
  const replyCoach = useAppStore((s) => s.replyCoach);
  const setReplyCoachInput = useAppStore((s) => s.setReplyCoachInput);
  const setReplyCoachResult = useAppStore((s) => s.setReplyCoachResult);
  const resetReplyCoach = useAppStore((s) => s.resetReplyCoach);

  const { inputMethod, imagePreview, chatText, result } = replyCoach;

  const canSubmit =
    result.status !== "loading" &&
    (imagePreview || chatText.trim().length > 0);

  const handleAnalyze = useCallback(async () => {
    setReplyCoachResult({ status: "loading" });
    try {
      const response = await coachService.analyzeChat({
        image_base64: imagePreview ?? undefined,
        chat_text: chatText || undefined,
        input_method: inputMethod,
      });
      if (response.success && response.data) {
        setReplyCoachResult({ status: "success", data: response.data });
      } else {
        setReplyCoachResult({
          status: "error",
          message: response.error?.message ?? "Analysis failed",
        });
      }
    } catch {
      setReplyCoachResult({
        status: "error",
        message: "An unexpected error occurred",
      });
    }
  }, [imagePreview, chatText, inputMethod, setReplyCoachResult]);

  return (
    <div className="container mx-auto px-4 py-6 max-w-2xl">
      {/* Header */}
      <div className="flex items-center gap-3 mb-6">
        <Link href="/">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-5 w-5" />
          </Button>
        </Link>
        <div>
          <h1 className="text-2xl font-bold">Reply Coach</h1>
          <p className="text-sm text-muted-foreground">
            Upload a chat screenshot or paste text for analysis
          </p>
        </div>
      </div>

      {/* Input Section */}
      {result.status === "idle" || result.status === "loading" ? (
        <div className="space-y-4">
          <InputMethodToggle
            value={inputMethod}
            onChange={(m: InputMethod) => setReplyCoachInput({ inputMethod: m })}
          />

          {(inputMethod === "photo" || inputMethod === "both") && (
            <ImageUploader
              imagePreview={imagePreview}
              onImageSelect={(dataUrl) =>
                setReplyCoachInput({ imagePreview: dataUrl })
              }
              onImageClear={() => setReplyCoachInput({ imagePreview: null })}
              placeholder="Upload a screenshot of the chat conversation"
            />
          )}

          {(inputMethod === "text" || inputMethod === "both") && (
            <Textarea
              placeholder="Paste the conversation text here... (include both your messages and theirs)"
              value={chatText}
              onChange={(e) =>
                setReplyCoachInput({ chatText: e.target.value })
              }
              rows={6}
            />
          )}

          <Button
            className="w-full bg-brand-500 hover:bg-brand-600"
            size="lg"
            disabled={!canSubmit}
            onClick={handleAnalyze}
          >
            {result.status === "loading" ? (
              <span className="flex items-center gap-2">
                <span className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                Analyzing...
              </span>
            ) : (
              <span className="flex items-center gap-2">
                <Sparkles className="h-4 w-4" />
                Analyze Chat
              </span>
            )}
          </Button>

          {result.status === "loading" && (
            <div className="space-y-4 mt-6">
              <Skeleton className="h-72 w-full rounded-xl" />
              <Skeleton className="h-40 w-full rounded-xl" />
              <Skeleton className="h-32 w-full rounded-xl" />
            </div>
          )}
        </div>
      ) : result.status === "success" ? (
        <div className="space-y-4">
          <Button
            variant="outline"
            onClick={resetReplyCoach}
            className="gap-2"
          >
            <RotateCcw className="h-4 w-4" />
            Start Over
          </Button>
          <ReplyCoachResultPanel result={result.data} />
        </div>
      ) : (
        <div className="text-center py-12 space-y-4">
          <p className="text-emotion-negative">{result.message}</p>
          <Button variant="outline" onClick={resetReplyCoach}>
            Try Again
          </Button>
        </div>
      )}
    </div>
  );
}
