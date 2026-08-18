"use client";

import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import DeviceFrame from "./DeviceFrame";
import type { Project, Skill } from "@/lib/types";

/**
 * Selected work.
 *
 * The device from the hero does not scroll away - it pins here and its
 * screen changes as each project comes into view. That keeps one object
 * running down the page instead of a hero trick seen once, and it puts
 * the app itself beside whatever the reader is reading about.
 *
 * When a project has no media yet the screen renders a synthesised card
 * from its own title and stack, so the section reads as unfinished rather
 * than broken. Real recordings replace it the moment they exist.
 */

const PLATFORM_TINT: Record<string, string> = {
  iOS: "#3B2FBF",
  Flutter: "#0553B1",
  Android: "#2E9E63",
  Mobile: "#4A5568",
};

function platformOf(project: Project, skills: Skill[]): string {
  const names = skills
    .filter((s) => project.skillIds.includes(s.id))
    .map((s) => s.name.toLowerCase());
  if (names.some((n) => n.includes("flutter") || n.includes("dart"))) return "Flutter";
  if (names.some((n) => n.includes("swift") || n.includes("uikit"))) return "iOS";
  if (names.some((n) => n.includes("kotlin") || n.includes("java"))) return "Android";
  return "Mobile";
}

function Screen({
  project,
  platform,
  stack,
}: {
  project: Project;
  platform: string;
  stack: Skill[];
}) {
  if (project.coverImageUrl) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={project.coverImageUrl}
        alt={project.title.en}
        className="h-full w-full object-cover"
      />
    );
  }

  const tint = PLATFORM_TINT[platform] ?? PLATFORM_TINT.Mobile;

  return (
    <div className="flex h-full flex-col px-5 pb-6 pt-14">
      <p
        className="font-[family-name:var(--font-mono)] text-[10px] uppercase tracking-[0.14em]"
        style={{ color: "#8A9490" }}
      >
        {platform}
      </p>

      <p
        className="mt-2 font-[family-name:var(--font-display)] font-bold leading-[1.05]"
        style={{ fontSize: "1.5rem", letterSpacing: "-0.02em", color: "#141A17" }}
      >
        {project.title.en}
      </p>

      <div
        className="mt-5 flex-1 overflow-hidden p-4"
        style={{ backgroundColor: tint, borderRadius: "18px" }}
      >
        <p
          className="text-[13px] leading-relaxed"
          style={{ color: "#FFFFFF", opacity: 0.92 }}
        >
          {project.summary.en.slice(0, 150)}
        </p>
      </div>

      <div className="mt-4 flex flex-wrap gap-1.5">
        {stack.slice(0, 4).map((s) => (
          <span
            key={s.id}
            className="font-[family-name:var(--font-mono)] px-1.5 py-0.5 text-[10px]"
            style={{ border: "1px solid #DDE2DE", color: "#6B7A72" }}
          >
            {s.name}
          </span>
        ))}
      </div>
    </div>
  );
}

export default function FeaturedProjects({
  projects,
  skills,
}: {
  projects: Project[];
  skills: Skill[];
}) {
  const [active, setActive] = useState(0);
  const blocks = useRef<Array<HTMLElement | null>>([]);

  useEffect(() => {
    if (projects.length === 0) return;

    const observer = new IntersectionObserver(
      (entries) => {
        // Whichever block occupies most of the middle band wins, so the
        // device never flickers between two partly visible projects.
        const best = entries
          .filter((e) => e.isIntersecting)
          .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];
        if (best) {
          const i = blocks.current.indexOf(best.target as HTMLElement);
          if (i >= 0) setActive(i);
        }
      },
      { rootMargin: "-35% 0px -35% 0px", threshold: [0.1, 0.5, 0.9] }
    );

    blocks.current.forEach((b) => b && observer.observe(b));
    return () => observer.disconnect();
  }, [projects.length]);

  if (projects.length === 0) {
    return (
      <section className="mx-auto max-w-5xl px-6 py-28">
        <div className="rule pt-8">
          <p className="eyebrow">Selected work</p>
        </div>
        <p className="mt-6 max-w-md text-[color:var(--color-ink-muted)]">
          No published projects yet. Write a case study in the admin and switch
          it to published - it will appear here.
        </p>
      </section>
    );
  }

  const current = projects[active] ?? projects[0];
  const currentPlatform = platformOf(current, skills);
  const currentStack = skills.filter((s) => current.skillIds.includes(s.id));

  return (
    <section className="mx-auto max-w-6xl px-6 py-24">
      <div className="rule flex items-baseline justify-between pt-8">
        <p className="eyebrow">Selected work</p>
        <Link href="/projects" className="link-underline text-sm">
          All projects
        </Link>
      </div>

      <div className="mt-12 grid gap-12 lg:grid-cols-[1fr_auto]">
        <div>
          {projects.map((project, i) => {
            const platform = platformOf(project, skills);
            const stack = skills.filter((s) => project.skillIds.includes(s.id));
            const isActive = i === active;

            return (
              <article
                key={project.id}
                ref={(el) => {
                  blocks.current[i] = el;
                }}
                className="flex min-h-[62vh] flex-col justify-center py-10 transition-opacity duration-500"
                style={{ opacity: isActive ? 1 : 0.42 }}
              >
                <span
                  className="eyebrow inline-block self-start border px-2.5 py-1"
                  style={{ borderColor: "var(--color-line)" }}
                >
                  {platform}
                </span>

                <h3
                  className="mt-5 font-[family-name:var(--font-display)] font-semibold"
                  style={{
                    fontSize: "var(--text-title)",
                    lineHeight: "var(--text-title--line-height)",
                    letterSpacing: "var(--text-title--letter-spacing)",
                  }}
                >
                  <Link href={`/projects/${project.slug}`} className="hover:opacity-70">
                    {project.title.en}
                  </Link>
                </h3>

                <p className="mt-4 max-w-md leading-relaxed text-[color:var(--color-ink-muted)]">
                  {project.summary.en}
                </p>

                {project.metrics.length > 0 && (
                  <div className="mt-7 flex flex-wrap gap-x-10 gap-y-4">
                    {project.metrics.slice(0, 3).map((m) => (
                      <div key={m.label.en}>
                        <p
                          className="font-[family-name:var(--font-display)] font-semibold"
                          style={{ fontSize: "1.5rem", letterSpacing: "-0.02em" }}
                        >
                          {m.value}
                        </p>
                        <p className="eyebrow mt-1">{m.label.en}</p>
                      </div>
                    ))}
                  </div>
                )}

                <div className="mt-6 flex flex-wrap gap-x-3 gap-y-1">
                  {stack.slice(0, 6).map((s) => (
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
                  className="link-underline mt-7 self-start text-sm"
                >
                  Read the case study
                </Link>
              </article>
            );
          })}
        </div>

        <div className="hidden lg:block">
          <div className="sticky top-0 flex h-screen items-center">
            <div className="flex flex-col items-center">
              <DeviceFrame width={280}>
                <div
                  key={current.id}
                  className="h-full w-full"
                  style={{ animation: "screenIn 380ms cubic-bezier(0.22,1,0.36,1)" }}
                >
                  <Screen
                    project={current}
                    platform={currentPlatform}
                    stack={currentStack}
                  />
                </div>
              </DeviceFrame>

              <div className="mt-6 flex gap-1.5">
                {projects.map((p, i) => (
                  <span
                    key={p.id}
                    className="h-0.5 w-6 transition-colors duration-300"
                    style={{
                      backgroundColor:
                        i === active ? "var(--color-ink)" : "var(--color-line)",
                    }}
                  />
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
