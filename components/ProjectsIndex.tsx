"use client";

import Link from "next/link";
import { useState, useMemo } from "react";
import type { Project, Skill } from "@/lib/types";

/**
 * Projects index.
 *
 * Filtered by platform rather than by an invented taxonomy, because
 * platform is what a recruiter is scanning for - they arrived looking for
 * an iOS developer or a Flutter developer, and the filter should answer
 * that question in one click.
 */

const FILTERS = ["All", "iOS", "Flutter", "Android"] as const;

function platformOf(project: Project, skills: Skill[]): string {
  const names = skills
    .filter((s) => project.skillIds.includes(s.id))
    .map((s) => s.name.toLowerCase());
  if (names.some((n) => n.includes("flutter") || n.includes("dart"))) return "Flutter";
  if (names.some((n) => n.includes("swift") || n.includes("uikit"))) return "iOS";
  if (names.some((n) => n.includes("kotlin") || n.includes("java"))) return "Android";
  return "Mobile";
}

export default function ProjectsIndex({
  projects,
  skills,
}: {
  projects: Project[];
  skills: Skill[];
}) {
  const [filter, setFilter] = useState<(typeof FILTERS)[number]>("All");

  const tagged = useMemo(
    () => projects.map((p) => ({ project: p, platform: platformOf(p, skills) })),
    [projects, skills]
  );

  const visible = tagged.filter(
    (t) => filter === "All" || t.platform === filter
  );

  return (
    <main className="mx-auto max-w-5xl px-6 py-20">
      <Link href="/" className="link-underline text-sm">
        Back
      </Link>

      <h1
        className="mt-10 font-[family-name:var(--font-display)] font-bold"
        style={{
          fontSize: "clamp(2.25rem, 5vw, 3.5rem)",
          lineHeight: 0.96,
          letterSpacing: "-0.035em",
        }}
      >
        Projects
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
                borderColor: active ? "var(--color-ink)" : "var(--color-line)",
                backgroundColor: active ? "var(--color-ink)" : "transparent",
                color: active ? "var(--color-paper)" : "var(--color-ink-muted)",
              }}
            >
              {f} ({count})
            </button>
          );
        })}
      </div>

      {visible.length === 0 ? (
        <p className="mt-16 max-w-md text-[color:var(--color-ink-muted)]">
          Nothing published here yet. Case studies appear once they have a real
          narrative and a recording of the app running.
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
                    style={{ borderColor: "var(--color-line)" }}
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
                      href={`/projects/${project.slug}`}
                      className="hover:opacity-70"
                    >
                      {project.title.en}
                    </Link>
                  </h2>

                  <p className="mt-3 max-w-xl leading-relaxed text-[color:var(--color-ink-muted)]">
                    {project.summary.en}
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
                    href={`/projects/${project.slug}`}
                    className="link-underline mt-6 inline-block text-sm"
                  >
                    Read the case study
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
