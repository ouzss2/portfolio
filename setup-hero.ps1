# ============================================================
#  Portfolio - hero v2 : three platforms, one edit
#  Run from project root:  .\setup-hero.ps1
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
Write-Host "Writing hero..." -ForegroundColor Cyan
Write-Host ""

$c0 = @'
import HotReloadHero from "@/components/HotReloadHero";
import FeaturedProjects from "@/components/FeaturedProjects";
import Teaching from "@/components/Teaching";
import Skills from "@/components/Skills";
import Contact from "@/components/Contact";
import Reveal from "@/components/Reveal";

import {
  getProfile,
  getFeaturedProjects,
  getPublishedProjects,
  getSkills,
  getSkillsByCategory,
  getExperiences,
  getCertifications,
} from "@/lib/queries";

export const revalidate = 3600;

export default async function Home() {
  const [
    profile,
    featured,
    allProjects,
    skills,
    groups,
    experiences,
    certifications,
  ] = await Promise.all([
    getProfile(),
    getFeaturedProjects(3),
    getPublishedProjects(),
    getSkills(),
    getSkillsByCategory(),
    getExperiences(),
    getCertifications(),
  ]);

  return (
    <main>
      {/* The hero is never wrapped in Reveal - it must be readable the
          instant the page paints. */}
      <HotReloadHero
        name={profile?.fullName ?? "Oussema Mansouri"}
        availability={profile?.availabilityStatus ?? "open"}
      />

      <FeaturedProjects projects={featured} skills={skills} />

      <Reveal>
        <Teaching experiences={experiences} />
      </Reveal>

      <Reveal>
        <Skills
          groups={groups}
          certifications={certifications}
          projects={allProjects}
        />
      </Reveal>

      <Reveal>
        <Contact profile={profile} />
      </Reveal>
    </main>
  );
}

'@
Write-File 'app\page.tsx' $c0

$c1 = @'
"use client";

import { useState, useEffect, useRef } from "react";

/**
 * The hero.
 *
 * Three devices, one edit. The same screen rendered the way each platform
 * actually renders it - a large left-aligned title and a hairline tab bar
 * on iOS, a filled AppBar and a floating action button on Flutter, a
 * search-shaped top bar and a pill nav indicator on Android.
 *
 * Working across three ecosystems is the rarest line on the CV, so the
 * hero shows all three at once rather than describing them. Editing the
 * string updates every device simultaneously, which is the claim and the
 * demonstration in a single gesture.
 *
 * The screens are filled deliberately. A mobile portfolio whose device is
 * an empty card argues against itself.
 */

const ACCENTS = [
  { name: "indigo", hex: "#4B3BEF" },
  { name: "orange", hex: "#F05138" },
  { name: "blue", hex: "#1479E8" },
  { name: "green", hex: "#2FBF71" },
];

const ROWS = [
  { title: "Maktoub", sub: "Marketplace" },
  { title: "TEK-UP", sub: "Teaching" },
  { title: "Firestore", sub: "Backend" },
];

type Platform = "ios" | "flutter" | "android";

const PLATFORM_META: Record<Platform, { label: string; sub: string }> = {
  ios: { label: "SwiftUI", sub: "iOS" },
  flutter: { label: "Flutter", sub: "iOS + Android" },
  android: { label: "Compose", sub: "Android" },
};

/* ------------------------------------------------------------------ */
/* Small chrome pieces                                                 */
/* ------------------------------------------------------------------ */

function StatusBar({ dark = false }: { dark?: boolean }) {
  const c = dark ? "#FFFFFF" : "#141A17";
  return (
    <div className="flex items-center justify-between px-4 pt-2.5">
      <span
        className="font-[family-name:var(--font-mono)] text-[9px] font-medium"
        style={{ color: c }}
      >
        9:41
      </span>
      <div className="flex items-center gap-[3px]">
        <span
          className="inline-block h-[7px] w-[7px] rounded-[1px]"
          style={{ backgroundColor: c, opacity: 0.85 }}
        />
        <span
          className="inline-block h-[7px] w-[3px] rounded-[1px]"
          style={{ backgroundColor: c, opacity: 0.85 }}
        />
        <span
          className="inline-block h-[7px] w-[11px] rounded-[2px]"
          style={{ border: `1px solid ${c}`, opacity: 0.85 }}
        />
      </div>
    </div>
  );
}

function Row({
  title,
  sub,
  accent,
  radius,
}: {
  title: string;
  sub: string;
  accent: string;
  radius: number;
}) {
  return (
    <div className="flex items-center gap-2.5 py-2">
      <span
        className="inline-block shrink-0"
        style={{
          width: 26,
          height: 26,
          borderRadius: radius > 14 ? 13 : 6,
          backgroundColor: accent,
          opacity: 0.16,
        }}
      />
      <span className="min-w-0 flex-1">
        <span
          className="block truncate text-[10px] font-semibold"
          style={{ color: "#141A17" }}
        >
          {title}
        </span>
        <span className="block truncate text-[9px]" style={{ color: "#8A9490" }}>
          {sub}
        </span>
      </span>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* The rendered screen, per platform                                   */
/* ------------------------------------------------------------------ */

function AppScreen({
  platform,
  headline,
  subline,
  accent,
  radius,
  pulse,
}: {
  platform: Platform;
  headline: string;
  subline: string;
  accent: string;
  radius: number;
  pulse: boolean;
}) {
  const card = (
    <div
      className="px-4 py-4 transition-all duration-200"
      style={{
        backgroundColor: accent,
        borderRadius: `${radius}px`,
        transform: pulse ? "scale(0.985)" : "scale(1)",
      }}
    >
      <p
        className="font-[family-name:var(--font-display)] font-bold leading-[1.05]"
        style={{ fontSize: "1rem", letterSpacing: "-0.02em", color: "#FFFFFF" }}
      >
        {headline || " "}
      </p>
      <p className="mt-1 text-[11px]" style={{ color: "#FFFFFF", opacity: 0.72 }}>
        {subline || " "}
      </p>
    </div>
  );

  /* ---------------- iOS: large title, hairline tab bar -------------- */
  if (platform === "ios") {
    return (
      <div className="flex h-full flex-col" style={{ backgroundColor: "#FAFBF9" }}>
        <StatusBar />
        <div className="px-4 pt-6">
          <p
            className="font-[family-name:var(--font-display)] font-bold"
            style={{ fontSize: "1.35rem", letterSpacing: "-0.02em", color: "#141A17" }}
          >
            Work
          </p>
        </div>
        <div className="mt-3 px-4">{card}</div>
        <div className="mt-2 flex-1 overflow-hidden px-4">
          {ROWS.map((r) => (
            <Row key={r.title} {...r} accent={accent} radius={radius} />
          ))}
        </div>
        <div
          className="flex items-center justify-around pb-4 pt-2"
          style={{ borderTop: "1px solid #E4E8E4" }}
        >
          {["Work", "Teach", "About"].map((t, i) => (
            <span key={t} className="flex flex-col items-center gap-1">
              <span
                className="inline-block h-3.5 w-3.5 rounded-[4px]"
                style={{ backgroundColor: i === 0 ? accent : "#C6CDC8" }}
              />
              <span
                className="text-[8px]"
                style={{ color: i === 0 ? accent : "#A8B1AB" }}
              >
                {t}
              </span>
            </span>
          ))}
        </div>
      </div>
    );
  }

  /* ---------------- Flutter: filled AppBar, FAB --------------------- */
  if (platform === "flutter") {
    return (
      <div className="flex h-full flex-col" style={{ backgroundColor: "#FAFBF9" }}>
        <div style={{ backgroundColor: accent }}>
          <StatusBar dark />
          <div className="flex items-center gap-2 px-4 pb-3 pt-3">
            <span className="flex flex-col gap-[3px]">
              {[0, 1, 2].map((i) => (
                <span
                  key={i}
                  className="block h-[1.5px] w-3.5 rounded-full"
                  style={{ backgroundColor: "#FFFFFF" }}
                />
              ))}
            </span>
            <p className="text-[13px] font-semibold" style={{ color: "#FFFFFF" }}>
              Work
            </p>
          </div>
        </div>
        <div className="mt-4 px-4">{card}</div>
        <div className="mt-2 flex-1 overflow-hidden px-4">
          {ROWS.map((r) => (
            <Row key={r.title} {...r} accent={accent} radius={radius} />
          ))}
        </div>
        <div className="relative pb-5">
          <span
            className="absolute bottom-5 right-4 flex items-center justify-center rounded-full"
            style={{
              width: 34,
              height: 34,
              backgroundColor: accent,
              boxShadow: "0 3px 8px rgba(0,0,0,0.18)",
            }}
          >
            <span
              className="text-[16px] font-light leading-none"
              style={{ color: "#FFFFFF" }}
            >
              +
            </span>
          </span>
        </div>
      </div>
    );
  }

  /* ---------------- Android: search bar, pill nav ------------------- */
  return (
    <div className="flex h-full flex-col" style={{ backgroundColor: "#FAFBF9" }}>
      <StatusBar />
      <div className="px-4 pt-4">
        <div
          className="flex items-center gap-2 px-3 py-2"
          style={{ backgroundColor: "#EBEEEA", borderRadius: "999px" }}
        >
          <span
            className="inline-block h-2.5 w-2.5 rounded-full"
            style={{ border: "1.5px solid #8A9490" }}
          />
          <span className="text-[10px]" style={{ color: "#8A9490" }}>
            Search projects
          </span>
        </div>
      </div>
      <div className="mt-4 px-4">{card}</div>
      <div className="mt-2 flex-1 overflow-hidden px-4">
        {ROWS.map((r) => (
          <Row key={r.title} {...r} accent={accent} radius={radius} />
        ))}
      </div>
      <div className="flex items-end justify-around pb-4 pt-2">
        {["Work", "Teach", "About"].map((t, i) => (
          <span key={t} className="flex flex-col items-center gap-1">
            <span
              className="flex items-center justify-center"
              style={{
                width: 30,
                height: 17,
                borderRadius: 999,
                backgroundColor: i === 0 ? accent : "transparent",
                opacity: i === 0 ? 0.18 : 1,
              }}
            >
              <span
                className="inline-block h-3 w-3 rounded-[3px]"
                style={{ backgroundColor: i === 0 ? accent : "#C6CDC8" }}
              />
            </span>
            <span
              className="text-[8px]"
              style={{ color: i === 0 ? accent : "#A8B1AB" }}
            >
              {t}
            </span>
          </span>
        ))}
      </div>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Device shell                                                        */
/* ------------------------------------------------------------------ */

function Device({
  platform,
  width,
  children,
}: {
  platform: Platform;
  width: number;
  children: React.ReactNode;
}) {
  const meta = PLATFORM_META[platform];
  return (
    <div className="flex flex-col items-center">
      <div
        className="relative"
        style={{
          width,
          aspectRatio: "9 / 19.5",
          backgroundColor: "#080B10",
          borderRadius: width * 0.145,
          padding: width * 0.032,
          boxShadow: "0 24px 60px rgba(0,0,0,0.55)",
        }}
      >
        <div
          className="relative h-full w-full overflow-hidden"
          style={{ borderRadius: width * 0.115 }}
        >
          <div
            aria-hidden
            className="absolute left-1/2 top-1.5 z-20 rounded-full"
            style={{
              width: width * 0.28,
              height: width * 0.062,
              transform: "translateX(-50%)",
              backgroundColor: "#080B10",
            }}
          />
          {children}
        </div>
      </div>

      <p
        className="mt-4 font-[family-name:var(--font-mono)] text-[10px] uppercase tracking-[0.14em]"
        style={{ color: "#A8B1C4" }}
      >
        {meta.label}
      </p>
      <p
        className="mt-0.5 font-[family-name:var(--font-mono)] text-[9px]"
        style={{ color: "#5E6675" }}
      >
        {meta.sub}
      </p>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Editable token                                                      */
/* ------------------------------------------------------------------ */

function Editable({
  value,
  onChange,
  ariaLabel,
}: {
  value: string;
  onChange: (v: string) => void;
  ariaLabel: string;
}) {
  const ref = useRef<HTMLSpanElement>(null);

  useEffect(() => {
    if (ref.current && ref.current.textContent !== value) {
      ref.current.textContent = value;
    }
  }, [value]);

  return (
    <span
      ref={ref}
      role="textbox"
      aria-label={ariaLabel}
      contentEditable
      suppressContentEditableWarning
      spellCheck={false}
      onInput={(e) => onChange(e.currentTarget.textContent?.slice(0, 34) ?? "")}
      onKeyDown={(e) => {
        if (e.key === "Enter") e.preventDefault();
      }}
      className="outline-none"
      style={{
        color: "#F0C48A",
        backgroundColor: "rgba(240,196,138,0.10)",
        borderBottom: "1px dashed rgba(240,196,138,0.5)",
        cursor: "text",
        padding: "0 2px",
      }}
    />
  );
}

/* ------------------------------------------------------------------ */
/* Hero                                                                */
/* ------------------------------------------------------------------ */

export default function HotReloadHero({
  name = "Oussema Mansouri",
  availability = "open" as "available" | "open" | "unavailable",
}) {
  const [headline, setHeadline] = useState("Builds apps.");
  const [subline, setSubline] = useState("Teaches them too.");
  const [accent, setAccent] = useState(ACCENTS[0]);
  const [radius, setRadius] = useState(16);
  const [pulse, setPulse] = useState(false);
  const [compileMs, setCompileMs] = useState<number | null>(null);
  const [touched, setTouched] = useState(false);
  const first = useRef(true);

  useEffect(() => {
    setPulse(true);
    const t = setTimeout(() => {
      setPulse(false);
      if (!first.current) setCompileMs(0.18 + Math.random() * 0.29);
      first.current = false;
    }, 240);
    return () => clearTimeout(t);
  }, [headline, subline, accent, radius]);

  useEffect(() => {
    if (compileMs === null) return;
    const t = setTimeout(() => setCompileMs(null), 2400);
    return () => clearTimeout(t);
  }, [compileMs]);

  const status = {
    available: { label: "Available for work", color: "#3FCF8E" },
    open: { label: "Open to offers", color: "#E8B84B" },
    unavailable: { label: "Not available", color: "#E86B6B" },
  }[availability];

  const screenProps = { headline, subline, accent: accent.hex, radius, pulse };

  return (
    <section
      className="relative overflow-hidden"
      style={{ backgroundColor: "#0A0D14", color: "#E6E9EE" }}
    >
      {/* A single soft wash behind the devices so they sit in space
          rather than on a flat plane. */}
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0"
        style={{
          background:
            "radial-gradient(120% 80% at 72% 42%, rgba(75,59,239,0.20) 0%, rgba(10,13,20,0) 62%)",
        }}
      />

      <div className="relative mx-auto max-w-7xl px-6 py-14 lg:px-10 lg:py-16">
        {/* ---------------- top: identity ---------------- */}
        <p
          className="font-[family-name:var(--font-mono)] text-[11px] uppercase tracking-[0.16em]"
          style={{ color: "#6E7787" }}
        >
          Tunis &middot; iOS &middot; Flutter &middot; Android
        </p>

        <div className="mt-5 flex flex-wrap items-end justify-between gap-6">
          <div>
            <h1
              className="font-[family-name:var(--font-display)] font-bold"
              style={{
                fontSize: "clamp(2.5rem, 5.4vw, 4.5rem)",
                lineHeight: 0.92,
                letterSpacing: "-0.04em",
              }}
            >
              {name}
            </h1>
            <p className="mt-4 max-w-lg text-base" style={{ color: "#9AA3B2" }}>
              Mobile developer and instructor at TEK-UP. Three years shipping
              native iOS, cross-platform Flutter, and native Android.
            </p>
          </div>

          <p className="flex items-center gap-2.5 text-sm">
            <span
              aria-hidden
              className="inline-block h-2 w-2 rounded-full"
              style={{ backgroundColor: status.color }}
            />
            <span style={{ color: "#C3CAD6" }}>{status.label}</span>
          </p>
        </div>

        {/* ---------------- the three devices ---------------- */}
        <div className="mt-14 flex items-end justify-center gap-4 sm:gap-8 lg:gap-12">
          <div
            className="hidden sm:block"
            style={{
              transform: "perspective(1600px) rotateY(16deg) translateY(26px)",
            }}
          >
            <Device platform="ios" width={186}>
              <AppScreen platform="ios" {...screenProps} />
            </Device>
          </div>

          <div style={{ transform: "translateY(-14px)" }}>
            <Device platform="flutter" width={214}>
              <AppScreen platform="flutter" {...screenProps} />
            </Device>
          </div>

          <div
            className="hidden sm:block"
            style={{
              transform: "perspective(1600px) rotateY(-16deg) translateY(26px)",
            }}
          >
            <Device platform="android" width={186}>
              <AppScreen platform="android" {...screenProps} />
            </Device>
          </div>
        </div>

        {/* ---------------- the editor ---------------- */}
        <div className="mx-auto mt-16 max-w-3xl">
          <div className="mb-2 flex items-center justify-between">
            <p
              className="font-[family-name:var(--font-mono)] text-[11px]"
              style={{ color: "#6E7787" }}
            >
              HeroCard &mdash; shared across all three targets
            </p>
            <p
              className="font-[family-name:var(--font-mono)] text-[11px] transition-opacity duration-200"
              style={{ color: "#8B80FF", opacity: pulse ? 1 : 0.4 }}
            >
              {pulse
                ? "reloading..."
                : compileMs !== null
                  ? `compiled in ${compileMs.toFixed(2)}s`
                  : "live"}
            </p>
          </div>

          <pre
            className="overflow-x-auto rounded-xl px-5 py-4 font-[family-name:var(--font-mono)] text-[13px] leading-[1.85]"
            style={{
              backgroundColor: "rgba(255,255,255,0.035)",
              border: "1px solid rgba(255,255,255,0.09)",
            }}
          >
            <code>
              <span style={{ color: "#C97BC4" }}>let</span>{" "}
              <span style={{ color: "#7FC8E8" }}>hero</span> ={" "}
              <span style={{ color: "#7FC8E8" }}>HeroCard</span>(
              {"\n  "}title:{" "}
              <span style={{ color: "#F0C48A" }}>&quot;</span>
              <Editable value={headline} onChange={(v) => { setHeadline(v); setTouched(true); }} ariaLabel="Card title" />
              <span style={{ color: "#F0C48A" }}>&quot;</span>,
              {"\n  "}subtitle:{" "}
              <span style={{ color: "#F0C48A" }}>&quot;</span>
              <Editable value={subline} onChange={(v) => { setSubline(v); setTouched(true); }} ariaLabel="Card subtitle" />
              <span style={{ color: "#F0C48A" }}>&quot;</span>,
              {"\n  "}tint: .
              <span style={{ color: "#8FD37F" }}>{accent.name}</span>,{" "}
              radius: <span style={{ color: "#D4A85F" }}>{radius}</span>
              {"\n"})
            </code>
          </pre>

          <div className="mt-5 flex flex-wrap items-center justify-between gap-x-10 gap-y-4">
            <div className="flex flex-wrap items-center gap-x-8 gap-y-4">
              <div className="flex items-center gap-2.5">
                <span
                  className="font-[family-name:var(--font-mono)] text-[11px]"
                  style={{ color: "#6E7787" }}
                >
                  tint
                </span>
                {ACCENTS.map((a) => (
                  <button
                    key={a.name}
                    onClick={() => { setAccent(a); setTouched(true); }}
                    aria-label={`Tint ${a.name}`}
                    aria-pressed={accent.name === a.name}
                    className="h-5 w-5 rounded-full transition-transform hover:scale-110"
                    style={{
                      backgroundColor: a.hex,
                      outline: accent.name === a.name ? "2px solid #E6E9EE" : "none",
                      outlineOffset: "2px",
                    }}
                  />
                ))}
              </div>

              <div className="flex items-center gap-2">
                <span
                  className="font-[family-name:var(--font-mono)] text-[11px]"
                  style={{ color: "#6E7787" }}
                >
                  radius
                </span>
                {[0, 8, 16, 26].map((r) => (
                  <button
                    key={r}
                    onClick={() => { setRadius(r); setTouched(true); }}
                    aria-pressed={radius === r}
                    className="font-[family-name:var(--font-mono)] px-2 py-0.5 text-[11px] transition-colors"
                    style={{
                      color: radius === r ? "#0A0D14" : "#9AA3B2",
                      backgroundColor: radius === r ? "#E6E9EE" : "transparent",
                      border: "1px solid rgba(255,255,255,0.14)",
                      borderRadius: "4px",
                    }}
                  >
                    {r}
                  </button>
                ))}
              </div>
            </div>

            <p
              className="text-[13px] transition-opacity duration-500"
              style={{ color: "#6E7787", opacity: touched ? 0.5 : 1 }}
            >
              {touched
                ? "One edit, three platforms. That is the job."
                : "Edit the code - all three devices update as you type."}
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}

'@
Write-File 'components\HotReloadHero.tsx' $c1


Write-Host ""
Write-Host "Done. Run: npm run dev" -ForegroundColor Cyan
