"use client";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";
import { Textarea } from "@/components/ui/textarea";

const brandColors = [
  { name: "50", className: "bg-brand-50" },
  { name: "100", className: "bg-brand-100" },
  { name: "200", className: "bg-brand-200" },
  { name: "300", className: "bg-brand-300" },
  { name: "400", className: "bg-brand-400" },
  { name: "500", className: "bg-brand-500" },
  { name: "600", className: "bg-brand-600" },
  { name: "700", className: "bg-brand-700" },
  { name: "800", className: "bg-brand-800" },
  { name: "900", className: "bg-brand-900" },
];

const coachColors = [
  { name: "Humorous", className: "bg-coach-humorous" },
  { name: "Sincere", className: "bg-coach-sincere" },
  { name: "Flirty", className: "bg-coach-flirty" },
  { name: "Confident", className: "bg-coach-confident" },
];

const emotionColors = [
  { name: "Positive", className: "bg-emotion-positive" },
  { name: "Neutral", className: "bg-emotion-neutral" },
  { name: "Negative", className: "bg-emotion-negative" },
  { name: "Ambiguous", className: "bg-emotion-ambiguous" },
];

export default function DesignSystemPage() {
  return (
    <div className="container mx-auto px-4 py-8 max-w-4xl space-y-12">
      <div>
        <h1 className="text-3xl font-bold mb-2">Design System</h1>
        <p className="text-muted-foreground">
          Single source of truth for all visual components and design tokens.
        </p>
      </div>

      {/* Color Palette */}
      <section className="space-y-6">
        <h2 className="text-2xl font-semibold">Color Palette</h2>

        <div>
          <h3 className="text-lg font-medium mb-3">Brand Colors</h3>
          <div className="flex gap-2 flex-wrap">
            {brandColors.map((c) => (
              <div key={c.name} className="flex flex-col items-center gap-1">
                <div className={`h-12 w-12 rounded-lg ${c.className}`} />
                <span className="text-xs text-muted-foreground">{c.name}</span>
              </div>
            ))}
          </div>
        </div>

        <div>
          <h3 className="text-lg font-medium mb-3">Coach Tone Colors</h3>
          <div className="flex gap-4 flex-wrap">
            {coachColors.map((c) => (
              <div key={c.name} className="flex items-center gap-2">
                <div className={`h-8 w-8 rounded-lg ${c.className}`} />
                <span className="text-sm">{c.name}</span>
              </div>
            ))}
          </div>
        </div>

        <div>
          <h3 className="text-lg font-medium mb-3">Emotion Colors</h3>
          <div className="flex gap-4 flex-wrap">
            {emotionColors.map((c) => (
              <div key={c.name} className="flex items-center gap-2">
                <div className={`h-8 w-8 rounded-lg ${c.className}`} />
                <span className="text-sm">{c.name}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      <Separator />

      {/* Typography */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Typography</h2>
        <div className="space-y-3">
          <h1 className="text-4xl font-bold">Heading 1 (4xl bold)</h1>
          <h2 className="text-3xl font-bold">Heading 2 (3xl bold)</h2>
          <h3 className="text-2xl font-semibold">Heading 3 (2xl semibold)</h3>
          <h4 className="text-xl font-semibold">Heading 4 (xl semibold)</h4>
          <h5 className="text-lg font-medium">Heading 5 (lg medium)</h5>
          <p className="text-base">Body text (base)</p>
          <p className="text-sm">Small text (sm)</p>
          <p className="text-xs text-muted-foreground">
            Muted text (xs muted-foreground)
          </p>
        </div>
      </section>

      <Separator />

      {/* Spacing */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Spacing Scale</h2>
        <div className="flex items-end gap-2 flex-wrap">
          {[1, 2, 3, 4, 6, 8, 12, 16].map((s) => (
            <div key={s} className="flex flex-col items-center gap-1">
              <div
                className="bg-brand-200 rounded"
                style={{ width: `${s * 4}px`, height: `${s * 4}px` }}
              />
              <span className="text-xs text-muted-foreground">{s}</span>
            </div>
          ))}
        </div>
      </section>

      <Separator />

      {/* Border Radius */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Border Radius</h2>
        <div className="flex gap-4 flex-wrap">
          {[
            { name: "sm", className: "rounded-sm" },
            { name: "md", className: "rounded-md" },
            { name: "lg", className: "rounded-lg" },
            { name: "xl", className: "rounded-xl" },
            { name: "2xl", className: "rounded-2xl" },
            { name: "bubble", className: "rounded-bubble" },
            { name: "full", className: "rounded-full" },
          ].map((r) => (
            <div key={r.name} className="flex flex-col items-center gap-1">
              <div className={`h-16 w-16 bg-brand-100 border ${r.className}`} />
              <span className="text-xs text-muted-foreground">{r.name}</span>
            </div>
          ))}
        </div>
      </section>

      <Separator />

      {/* Buttons */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Buttons</h2>
        <div className="flex gap-3 flex-wrap items-center">
          <Button>Default</Button>
          <Button variant="secondary">Secondary</Button>
          <Button variant="destructive">Destructive</Button>
          <Button variant="outline">Outline</Button>
          <Button variant="ghost">Ghost</Button>
          <Button variant="link">Link</Button>
        </div>
        <div className="flex gap-3 flex-wrap items-center">
          <Button size="sm">Small</Button>
          <Button size="default">Default</Button>
          <Button size="lg">Large</Button>
          <Button size="icon">A</Button>
        </div>
        <div className="flex gap-3 flex-wrap items-center">
          <Button className="bg-brand-500 hover:bg-brand-600">Brand Primary</Button>
          <Button disabled>Disabled</Button>
        </div>
      </section>

      <Separator />

      {/* Badges */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Badges</h2>
        <div className="flex gap-3 flex-wrap">
          <Badge>Default</Badge>
          <Badge variant="secondary">Secondary</Badge>
          <Badge variant="destructive">Destructive</Badge>
          <Badge variant="outline">Outline</Badge>
        </div>
        <div>
          <h3 className="text-sm font-medium mb-2">Tone Badges</h3>
          <div className="flex gap-3 flex-wrap">
            <Badge variant="outline" className="bg-coach-humorous/10 text-coach-humorous border-coach-humorous/30">
              Humorous
            </Badge>
            <Badge variant="outline" className="bg-coach-sincere/10 text-coach-sincere border-coach-sincere/30">
              Sincere
            </Badge>
            <Badge variant="outline" className="bg-coach-flirty/10 text-coach-flirty border-coach-flirty/30">
              Flirty
            </Badge>
            <Badge variant="outline" className="bg-coach-confident/10 text-coach-confident border-coach-confident/30">
              Confident
            </Badge>
          </div>
        </div>
        <div>
          <h3 className="text-sm font-medium mb-2">Risk Badges</h3>
          <div className="flex gap-3 flex-wrap">
            <Badge variant="secondary" className="bg-emotion-positive/10 text-emotion-positive">
              Safe
            </Badge>
            <Badge variant="secondary" className="bg-emotion-ambiguous/10 text-emotion-ambiguous">
              Moderate
            </Badge>
            <Badge variant="secondary" className="bg-emotion-negative/10 text-emotion-negative">
              Bold
            </Badge>
          </div>
        </div>
      </section>

      <Separator />

      {/* Cards */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Cards</h2>
        <div className="grid gap-4 md:grid-cols-2">
          <Card>
            <CardHeader>
              <CardTitle>Default Card</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">
                This is a standard card with header and content.
              </p>
            </CardContent>
          </Card>
          <Card className="border-l-4 border-l-brand-500">
            <CardHeader>
              <CardTitle>Accent Card</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">
                Card with a left accent border.
              </p>
            </CardContent>
          </Card>
        </div>
      </section>

      <Separator />

      {/* Chat Bubbles */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Chat Bubbles</h2>
        <div className="max-w-sm space-y-3">
          <div className="flex justify-end">
            <div className="max-w-[75%] rounded-bubble rounded-br-sm bg-brand-500 text-white px-4 py-2.5 text-sm">
              Hey! How are you?
            </div>
          </div>
          <div className="flex justify-start">
            <div className="max-w-[75%] rounded-bubble rounded-bl-sm bg-muted px-4 py-2.5 text-sm">
              I&apos;m good, thanks!
            </div>
          </div>
        </div>
      </section>

      <Separator />

      {/* Form Controls */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Form Controls</h2>
        <div className="max-w-md space-y-3">
          <Textarea placeholder="Enter text here..." rows={3} />
        </div>
      </section>

      <Separator />

      {/* Loading States */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Loading States</h2>
        <div className="space-y-3">
          <Skeleton className="h-8 w-48" />
          <Skeleton className="h-32 w-full rounded-xl" />
          <div className="flex gap-3">
            <Skeleton className="h-12 w-12 rounded-full" />
            <div className="space-y-2 flex-1">
              <Skeleton className="h-4 w-3/4" />
              <Skeleton className="h-4 w-1/2" />
            </div>
          </div>
        </div>
        <div className="flex items-center gap-4">
          <div className="h-6 w-6 animate-spin rounded-full border-2 border-brand-500 border-t-transparent" />
          <span className="text-sm text-muted-foreground">Spinner</span>
        </div>
      </section>

      <Separator />

      {/* Animations */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Animations</h2>
        <div className="flex gap-6 items-center">
          <div className="flex flex-col items-center gap-2">
            <div className="h-8 w-8 rounded-full bg-brand-500 animate-pulse" />
            <span className="text-xs text-muted-foreground">pulse</span>
          </div>
          <div className="flex flex-col items-center gap-2">
            <div
              className="h-8 w-8 rounded-full bg-brand-500"
              style={{ animation: "pulse-slow 3s cubic-bezier(0.4, 0, 0.6, 1) infinite" }}
            />
            <span className="text-xs text-muted-foreground">pulse-slow</span>
          </div>
          <div className="flex flex-col items-center gap-2">
            <div
              className="h-8 w-8 rounded-full bg-emotion-negative"
              style={{ animation: "flash-hint 1.5s ease-in-out infinite" }}
            />
            <span className="text-xs text-muted-foreground">flash-hint</span>
          </div>
          <div className="flex flex-col items-center gap-2">
            <div className="h-6 w-6 animate-spin rounded-full border-2 border-brand-500 border-t-transparent" />
            <span className="text-xs text-muted-foreground">spin</span>
          </div>
        </div>
      </section>
    </div>
  );
}
