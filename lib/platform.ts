import type { Project, Skill } from "@/lib/types";

/**
 * Platform identity.
 *
 * Two colours per platform, because one cannot do both jobs. The "ink"
 * value is darkened until it passes WCAG AA against the paper background
 * and is the only one allowed to carry text. The "fill" value is used as
 * a background behind white text, where the brand hue can stay closer to
 * what people recognise.
 *
 * Android's brand green is around 1.8:1 on light paper - unreadable, and
 * a failure rather than a stylistic choice. That is why these exist.
 *
 * Platform colour is never used for links, buttons or focus. Those stay
 * indigo everywhere, so colour reliably answers one of two questions:
 * what is this, or what can I click. Not both.
 */

export type Platform = "iOS" | "Flutter" | "Android" | "Mobile";

export const PLATFORM_COLOR: Record<Platform, { ink: string; fill: string }> = {
  // Swift orange, darkened to about 5:1 for text
  iOS: { ink: "#B83E14", fill: "#D53C1B" },
  // Flutter blue is already dark enough to carry text
  Flutter: { ink: "#0553B1", fill: "#0553B1" },
  // Android green, darkened from #3DDC84 which fails badly on light
  Android: { ink: "#1B7A46", fill: "#1B7A46" },
  // Anything unclassified falls back to the site's own neutral
  Mobile: { ink: "#4A5568", fill: "#4A5568" },
};

export function platformOf(project: Project, skills: Skill[]): Platform {
  const names = skills
    .filter((s) => project.skillIds.includes(s.id))
    .map((s) => s.name.toLowerCase());

  // Order matters. Flutter is checked first because a Flutter project can
  // legitimately list Swift or Kotlin alongside it for platform channels,
  // and the framework is the more useful label in that case.
  if (names.some((n) => n.includes("flutter") || n.includes("dart"))) return "Flutter";
  if (names.some((n) => n.includes("swift") || n.includes("uikit"))) return "iOS";
  if (names.some((n) => n.includes("kotlin") || n.includes("java"))) return "Android";
  return "Mobile";
}
