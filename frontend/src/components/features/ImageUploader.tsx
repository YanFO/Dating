"use client";

import { useCallback, useRef } from "react";
import { Upload, X, Camera } from "lucide-react";
import { fileToDataUrl } from "@/utils/fileToDataUrl";
import { cn } from "@/lib/utils";

interface ImageUploaderProps {
  imagePreview: string | null;
  onImageSelect: (dataUrl: string) => void;
  onImageClear: () => void;
  placeholder?: string;
  className?: string;
}

export function ImageUploader({
  imagePreview,
  onImageSelect,
  onImageClear,
  placeholder = "Upload a photo or take a picture",
  className,
}: ImageUploaderProps) {
  const inputRef = useRef<HTMLInputElement>(null);

  const handleFileChange = useCallback(
    async (e: React.ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0];
      if (!file) return;
      const dataUrl = await fileToDataUrl(file);
      onImageSelect(dataUrl);
    },
    [onImageSelect]
  );

  if (imagePreview) {
    return (
      <div className={cn("relative rounded-xl overflow-hidden", className)}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src={imagePreview}
          alt="Uploaded preview"
          className="w-full h-64 object-cover"
        />
        <button
          onClick={onImageClear}
          className="absolute top-2 right-2 rounded-full bg-black/50 p-1.5 text-white hover:bg-black/70 transition-colors"
        >
          <X className="h-4 w-4" />
        </button>
      </div>
    );
  }

  return (
    <button
      onClick={() => inputRef.current?.click()}
      className={cn(
        "flex w-full flex-col items-center justify-center gap-3 rounded-xl border-2 border-dashed border-muted-foreground/25 bg-muted/50 p-8 transition-colors hover:border-brand-300 hover:bg-brand-50/50",
        className
      )}
    >
      <div className="flex gap-2">
        <Upload className="h-8 w-8 text-muted-foreground" />
        <Camera className="h-8 w-8 text-muted-foreground" />
      </div>
      <p className="text-sm text-muted-foreground">{placeholder}</p>
      <input
        ref={inputRef}
        type="file"
        accept="image/*"
        capture="environment"
        onChange={handleFileChange}
        className="hidden"
      />
    </button>
  );
}
