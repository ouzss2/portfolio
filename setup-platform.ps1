# ============================================================
#  Portfolio - platform colour system
#  Run from project root:  .\setup-platform.ps1
# ============================================================

$ErrorActionPreference = "Stop"
if (-not (Test-Path ".\package.json")) {
  Write-Host "ERROR: run this from the portfolio root." -ForegroundColor Red; exit 1
}
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
function Write-File($relPath, $content) {
  $full = Join-Path $PWD.Path $relPath
  $dir  = Split-Path $full -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  [System.IO.File]::WriteAllText($full, $content, $utf8NoBom)
  Write-Host ("  wrote  " + $relPath) -ForegroundColor Green
}
Write-Host "Writing platform colour system..." -ForegroundColor Cyan
Write-Host ""

$c0 = @'
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

'@
Write-File 'lib\platform.ts' $c0

$c1 = @'
"use client";

import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import DeviceFrame from "./DeviceFrame";
import type { Project, Skill } from "@/lib/types";
import { platformOf, PLATFORM_COLOR } from "@/lib/platform";

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

  const tint = PLATFORM_COLOR[platform as keyof typeof PLATFORM_COLOR].fill;

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
                  style={{
                    borderColor: PLATFORM_COLOR[platform].ink,
                    color: PLATFORM_COLOR[platform].ink,
                  }}
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

'@
Write-File 'components\FeaturedProjects.tsx' $c1

$c2 = @'
"use client";

import Link from "next/link";
import { useState, useMemo } from "react";
import type { Project, Skill } from "@/lib/types";
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

'@
Write-File 'components\ProjectsIndex.tsx' $c2

$c3 = @'
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { platformOf, PLATFORM_COLOR } from "@/lib/platform";
import {
  getProjectBySlug,
  getAllProjectSlugs,
  getPublishedProjects,
  getSkills,
} from "@/lib/queries";

export const revalidate = 3600;

/**
 * Case study.
 *
 * Structured as context, problem, role, decisions, challenges, result -
 * because that is the order a technical reader evaluates work in, and
 * because a screenshot gallery answers none of those questions.
 *
 * Sections with placeholder text are omitted rather than rendered empty.
 * A visible TODO on a live page is worse than a shorter page.
 */

function isWritten(text?: string): boolean {
  if (!text) return false;
  const t = text.trim();
  return t.length > 0 && !t.startsWith("TODO") && !t.startsWith("A REDIGER");
}

export async function generateStaticParams() {
  const slugs = await getAllProjectSlugs();
  return slugs.map((slug) => ({ slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const project = await getProjectBySlug(slug);
  if (!project) return { title: "Not found" };

  return {
    title: `${project.title.en} - Oussema Mansouri`,
    description: project.summary.en,
  };
}

export default async function Page({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const [project, skills, all] = await Promise.all([
    getProjectBySlug(slug),
    getSkills(),
    getPublishedProjects(),
  ]);

  if (!project) notFound();

  const stack = skills.filter((s) => project.skillIds.includes(s.id));
  const platform = platformOf(project, skills);
  const tint = PLATFORM_COLOR[platform];
  const related = all.filter((p) => p.id !== project.id).slice(0, 2);

  const sections = [
    { label: "Context", body: project.caseStudy.context.en },
    { label: "The problem", body: project.caseStudy.problem.en },
    { label: "My role", body: project.caseStudy.role.en },
    { label: "Technical decisions", body: project.caseStudy.technicalDecisions.en },
    { label: "Challenges", body: project.caseStudy.challenges.en },
    { label: "Result", body: project.caseStudy.result.en },
  ].filter((s) => isWritten(s.body));

  const links = Object.entries(project.links).filter(([, v]) => v);

  return (
    <main className="mx-auto max-w-3xl px-6 py-20">
      <Link href="/projects" className="link-underline text-sm">
        All projects
      </Link>

      <span
        className="eyebrow mt-10 inline-block border px-2.5 py-1"
        style={{ borderColor: tint.ink, color: tint.ink }}
      >
        {platform}
      </span>

      <h1
        className="mt-5 font-[family-name:var(--font-display)] font-bold"
        style={{
          fontSize: "clamp(2.25rem, 5vw, 3.5rem)",
          lineHeight: 0.96,
          letterSpacing: "-0.035em",
        }}
      >
        {project.title.en}
      </h1>

      <p
        className="mt-6 leading-relaxed text-[color:var(--color-ink-muted)]"
        style={{ fontSize: "var(--text-lead)" }}
      >
        {project.summary.en}
      </p>

      {project.metrics.length > 0 && (
        <div className="rule mt-12 flex flex-wrap gap-x-14 gap-y-6 pt-8">
          {project.metrics.map((m) => (
            <div key={m.label.en}>
              <p
                className="font-[family-name:var(--font-display)] font-semibold"
                style={{ fontSize: "2rem", letterSpacing: "-0.025em" }}
              >
                {m.value}
              </p>
              <p className="eyebrow mt-1">{m.label.en}</p>
            </div>
          ))}
        </div>
      )}

      {project.coverImageUrl && (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={project.coverImageUrl}
          alt={project.title.en}
          className="mt-12 w-full"
          style={{ borderRadius: "4px", border: "1px solid var(--color-line)" }}
        />
      )}

      {sections.length === 0 ? (
        <p className="rule mt-12 pt-8 text-[color:var(--color-ink-muted)]">
          The write-up for this project is still in progress.
        </p>
      ) : (
        <div className="mt-16 space-y-14">
          {sections.map((s) => (
            <section key={s.label} className="rule pt-8">
              <p className="eyebrow">{s.label}</p>
              <div className="mt-4 space-y-4 leading-relaxed">
                {s.body.split("\n\n").map((para, i) => (
                  <p key={i}>{para}</p>
                ))}
              </div>
            </section>
          ))}
        </div>
      )}

      {project.media.length > 0 && (
        <div className="mt-16 space-y-8">
          {project.media.map((m, i) => (
            <figure key={i}>
              {m.type === "video" ? (
                <video
                  src={m.url}
                  autoPlay
                  loop
                  muted
                  playsInline
                  className="w-full"
                  style={{ borderRadius: "4px" }}
                />
              ) : (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={m.url}
                  alt={m.caption.en}
                  className="w-full"
                  style={{
                    borderRadius: "4px",
                    border: "1px solid var(--color-line)",
                  }}
                />
              )}
              {m.caption.en && (
                <figcaption className="eyebrow mt-3">{m.caption.en}</figcaption>
              )}
            </figure>
          ))}
        </div>
      )}

      <section className="rule mt-16 pt-8">
        <p className="eyebrow">Stack</p>
        <div className="mt-4 flex flex-wrap gap-x-4 gap-y-2">
          {stack.map((s) => (
            <span
              key={s.id}
              className="font-[family-name:var(--font-mono)] text-sm text-[color:var(--color-ink-muted)]"
            >
              {s.name}
            </span>
          ))}
        </div>
      </section>

      {links.length > 0 && (
        <section className="rule mt-12 pt-8">
          <p className="eyebrow">Links</p>
          <div className="mt-4 flex flex-wrap gap-6">
            {links.map(([key, url]) => (
              <a
                key={key}
                href={url as string}
                target="_blank"
                rel="noreferrer"
                className="link-underline text-sm"
              >
                {key === "appStore"
                  ? "App Store"
                  : key === "playStore"
                    ? "Play Store"
                    : key === "github"
                      ? "GitHub"
                      : "Live demo"}
              </a>
            ))}
          </div>
        </section>
      )}

      {related.length > 0 && (
        <section className="rule mt-16 pt-8">
          <p className="eyebrow">Next</p>
          <div className="mt-6 space-y-5">
            {related.map((p) => (
              <Link
                key={p.id}
                href={`/projects/${p.slug}`}
                className="block hover:opacity-70"
              >
                <p
                  className="font-[family-name:var(--font-display)] font-semibold"
                  style={{ fontSize: "1.25rem", letterSpacing: "-0.015em" }}
                >
                  {p.title.en}
                </p>
                <p className="mt-1 text-sm text-[color:var(--color-ink-muted)]">
                  {p.summary.en.slice(0, 110)}...
                </p>
              </Link>
            ))}
          </div>
        </section>
      )}

      <div className="rule mt-16 pt-8">
        <Link href="/#contact" className="link-underline text-sm">
          Get in touch
        </Link>
      </div>
    </main>
  );
}

'@
Write-File 'app\projects\[slug]\page.tsx' $c3


Write-Host ""
Write-Host "Done. Run: npm run dev" -ForegroundColor Cyan
