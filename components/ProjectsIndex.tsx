"use client";

import Link from "next/link";
import { useState, useMemo } from "react";
import type { Project, Skill, Locale } from "@/lib/types";
import { t as tr } from "@/lib/types";
import { getDict } from "@/lib/i18n";
import { platformOf, PLATFORM_COLOR, type Platform } from "@/lib/platform";

/**
 * Projects index.
 *
 * Filtered by platform rather than by an invented taxonomy, because
 * platform is what a recruiter is scanning for - they arrived looking for
 * an iOS developer or a Flutter developer, and the filter should answer
 * that question in one click.
 */

const FILTERS = ["All", "iOS", "Flutter", "Android"] as const;

export default function ProjectsIndex({
  projects,
  skills,
  locale,
}: {
  projects: Project[];
  skills: Skill[];
  locale: Locale;
}) {
  const [filter, setFilter] = useState<(typeof FILTERS)[number]>("All");
  const d = getDict(locale);

  const tagged = useMemo(
    () => projects.map((p) => ({ project: p, platform: platformOf(p, skills) })),
    [projects, skills]
  );

  const visible = tagged.filter(
    (t) => filter === "All" || t.platform === filter
  );

  return (
    <main className="mx-auto max-w-5xl px-6 py-20">
      <Link href={`/${locale}`} className="link-underline text-sm">
        {d.back}
      </Link>

      <h1
        className="mt-10 font-[family-name:var(--font-display)] font-bold"
        style={{
          fontSize: "clamp(2.25rem, 5vw, 3.5rem)",
          lineHeight: 0.96,
          letterSpacing: "-0.035em",
        }}
      >
        {d.projects}
      </h1>

      <div className="mt-10 flex flex-wrap gap-2">
        {FILTERS.map((f) => {
          const count =
            f === "All"
              ? tagged.length
              : tagged.filter((t) => t.platform === f).length;
          const active = filter === f;

          return (
            <button
              key={f}
              onClick={() => setFilter(f)}
              disabled={count === 0}
              aria-pressed={active}
              className="eyebrow border px-3 py-1.5 transition-colors disabled:opacity-35"
              style={{
                borderColor:
                  f === "All"
                    ? "var(--color-ink)"
                    : PLATFORM_COLOR[f as Platform].ink,
                backgroundColor: active
                  ? f === "All"
                    ? "var(--color-ink)"
                    : PLATFORM_COLOR[f as Platform].ink
                  : "transparent",
                color: active
                  ? "var(--color-paper)"
                  : f === "All"
                    ? "var(--color-ink-muted)"
                    : PLATFORM_COLOR[f as Platform].ink,
              }}
            >
              {f === "All" ? d.all : f} ({count})
            </button>
          );
        })}
      </div>

      {visible.length === 0 ? (
        <p className="mt-16 max-w-md text-[color:var(--color-ink-muted)]">
          {d.nothingHere}
        </p>
      ) : (
        <div className="mt-16 space-y-16">
          {visible.map(({ project, platform }) => {
            const stack = skills.filter((s) => project.skillIds.includes(s.id));

            return (
              <article
                key={project.id}
                className="rule grid gap-6 pt-8 md:grid-cols-[180px_1fr]"
              >
                <div>
                  <span
                    className="eyebrow inline-block border px-2.5 py-1"
                    style={{
                      borderColor: PLATFORM_COLOR[platform].ink,
                      color: PLATFORM_COLOR[platform].ink,
                    }}
                  >
                    {platform}
                  </span>
                  <p className="eyebrow mt-3">
                    {new Date(project.createdAt).getFullYear()}
                  </p>
                </div>

                <div>
                  <h2
                    className="font-[family-name:var(--font-display)] font-semibold"
                    style={{ fontSize: "1.75rem", letterSpacing: "-0.02em" }}
                  >
                    <Link
                      href={`/${locale}/projects/${project.slug}`}
                      className="hover:opacity-70"
                    >
                      {tr(project.title, locale)}
                    </Link>
                  </h2>

                  <p className="mt-3 max-w-xl leading-relaxed text-[color:var(--color-ink-muted)]">
                    {tr(project.summary, locale)}
                  </p>

                  <div className="mt-5 flex flex-wrap gap-x-3 gap-y-1">
                    {stack.map((s) => (
                      <span
                        key={s.id}
                        className="font-[family-name:var(--font-mono)] text-xs text-[color:var(--color-ink-muted)]"
                      >
                        {s.name}
                      </span>
                    ))}
                  </div>

                  <Link
                    href={`/${locale}/projects/${project.slug}`}
                    className="link-underline mt-6 inline-block text-sm"
                  >
                    {d.readCaseStudy}
                  </Link>
                </div>
              </article>
            );
          })}
        </div>
      )}
    </main>
  );
}
