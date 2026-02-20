"use client";

import { useCallback } from "react";
import { ArrowLeft, Sparkles, RotateCcw } from "lucide-react";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Skeleton } from "@/components/ui/skeleton";
import { ImageUploader } from "@/components/features/ImageUploader";
import { InputMethodToggle } from "@/components/features/InputMethodToggle";
import { IcebreakerResultPanel } from "@/components/features/icebreaker/IcebreakerResultPanel";
import { useAppStore } from "@/store/useAppStore";
import { coachService } from "@/services/coachService";
import type { InputMethod } from "@/types/api";

export default function IcebreakerPage() {
  const icebreaker = useAppStore((s) => s.icebreaker);
  const setIcebreakerInput = useAppStore((s) => s.setIcebreakerInput);
  const setIcebreakerResult = useAppStore((s) => s.setIcebreakerResult);
  const resetIcebreaker = useAppStore((s) => s.resetIcebreaker);

  const { inputMethod, imagePreview, sceneDescription, result } = icebreaker;

  const canSubmit =
    result.status !== "loading" &&
    (imagePreview || sceneDescription.trim().length > 0);

  const handleAnalyze = useCallback(async () => {
    setIcebreakerResult({ status: "loading" });
    try {
      const response = await coachService.analyzeScene({
        image_base64: imagePreview ?? undefined,
        scene_description: sceneDescription || undefined,
        input_method: inputMethod,
      });
      if (response.success && response.data) {
        setIcebreakerResult({ status: "success", data: response.data });
      } else {
        setIcebreakerResult({
          status: "error",
          message: response.error?.message ?? "Analysis failed",
        });
      }
    } catch {
      setIcebreakerResult({
        status: "error",
        message: "An unexpected error occurred",
      });
    }
  }, [imagePreview, sceneDescription, inputMethod, setIcebreakerResult]);

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
          <h1 className="text-2xl font-bold">Icebreaker Coach</h1>
          <p className="text-sm text-muted-foreground">
            Describe the scene and get context-aware opening lines
          </p>
        </div>
      </div>

      {/* Input Section */}
      {result.status === "idle" || result.status === "loading" ? (
        <div className="space-y-4">
          <InputMethodToggle
            value={inputMethod}
            onChange={(m: InputMethod) => setIcebreakerInput({ inputMethod: m })}
          />

          {(inputMethod === "photo" || inputMethod === "both") && (
            <ImageUploader
              imagePreview={imagePreview}
              onImageSelect={(dataUrl) =>
                setIcebreakerInput({ imagePreview: dataUrl })
              }
              onImageClear={() => setIcebreakerInput({ imagePreview: null })}
              placeholder="Upload a photo of the scene or the person"
            />
          )}

          {(inputMethod === "text" || inputMethod === "both") && (
            <Textarea
              placeholder="Describe the scene... (e.g., 'Coffee shop, she's reading a book, wearing a vintage t-shirt')"
              value={sceneDescription}
              onChange={(e) =>
                setIcebreakerInput({ sceneDescription: e.target.value })
              }
              rows={4}
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
                Analyze Scene
              </span>
            )}
          </Button>

          {/* Loading skeleton */}
          {result.status === "loading" && (
            <div className="space-y-4 mt-6">
              <Skeleton className="h-40 w-full rounded-xl" />
              <Skeleton className="h-32 w-full rounded-xl" />
              <Skeleton className="h-32 w-full rounded-xl" />
            </div>
          )}
        </div>
      ) : result.status === "success" ? (
        <div className="space-y-4">
          <Button
            variant="outline"
            onClick={resetIcebreaker}
            className="gap-2"
          >
            <RotateCcw className="h-4 w-4" />
            Start Over
          </Button>
          <IcebreakerResultPanel result={result.data} />
        </div>
      ) : (
        <div className="text-center py-12 space-y-4">
          <p className="text-emotion-negative">{result.message}</p>
          <Button variant="outline" onClick={resetIcebreaker}>
            Try Again
          </Button>
        </div>
      )}
    </div>
  );
}
