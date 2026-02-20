import { Heart, MessageCircle, Mic } from "lucide-react";
import { FeatureCard } from "@/components/layout/FeatureCard";

export default function HomePage() {
  return (
    <div className="container mx-auto px-4 py-8">
      {/* Hero section */}
      <section className="mb-12 text-center">
        <h1 className="mb-4 text-4xl font-bold tracking-tight">
          Your AI{" "}
          <span className="text-brand-500">Dating Coach</span>
        </h1>
        <p className="mx-auto max-w-2xl text-lg text-muted-foreground">
          Not just a chat tool &mdash; a social skills coach that helps you
          understand the psychology behind every interaction.
        </p>
      </section>

      {/* Feature grid */}
      <section className="grid gap-6 md:grid-cols-3 max-w-4xl mx-auto">
        <FeatureCard
          href="/icebreaker"
          icon={Heart}
          title="Icebreaker Coach"
          description="Upload a scene photo and get context-aware opening lines with body language tips."
          accentColor="text-coach-flirty"
        />
        <FeatureCard
          href="/reply-coach"
          icon={MessageCircle}
          title="Reply Coach"
          description="Paste a chat screenshot and get multi-tone reply options with deep psychological analysis."
          accentColor="text-coach-sincere"
        />
        <FeatureCard
          href="/live-coach"
          icon={Mic}
          title="Live Voice Coach"
          description="Real-time conversation coaching during calls or dates with on-screen prompts."
          accentColor="text-coach-confident"
        />
      </section>
    </div>
  );
}
