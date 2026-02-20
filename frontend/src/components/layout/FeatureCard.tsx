import Link from "next/link";
import type { LucideIcon } from "lucide-react";
import { cn } from "@/lib/utils";

interface FeatureCardProps {
  href: string;
  icon: LucideIcon;
  title: string;
  description: string;
  accentColor: string;
}

export function FeatureCard({
  href,
  icon: Icon,
  title,
  description,
  accentColor,
}: FeatureCardProps) {
  return (
    <Link href={href}>
      <div className="group rounded-2xl border bg-card p-6 shadow-sm transition-all hover:shadow-md hover:border-brand-200">
        <div className={cn("mb-4 inline-flex rounded-xl bg-muted p-3", accentColor)}>
          <Icon className="h-6 w-6" />
        </div>
        <h3 className="mb-2 text-lg font-semibold">{title}</h3>
        <p className="text-sm text-muted-foreground">{description}</p>
      </div>
    </Link>
  );
}
