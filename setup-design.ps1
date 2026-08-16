# ============================================================
#  Portfolio - Day 3 : home page sections
#  Run from project root:  .\setup-sections.ps1
#  Pure ASCII. Output files UTF-8 without BOM.
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
Write-Host "Writing home page sections..." -ForegroundColor Cyan
Write-Host ""

$c0 = @'
import HotReloadHero from "@/components/HotReloadHero";
import FeaturedProjects from "@/components/FeaturedProjects";
import Teaching from "@/components/Teaching";
import Skills from "@/components/Skills";
import Contact from "@/components/Contact";

import {
  getProfile,
  getFeaturedProjects,
  getSkills,
  getSkillsByCategory,
  getExperiences,
  getCertifications,
} from "@/lib/queries";

export const revalidate = 3600;

export default async function Home() {
  const [profile, projects, skills, groups, experiences, certifications] =
    await Promise.all([
      getProfile(),
      getFeaturedProjects(3),
      getSkills(),
      getSkillsByCategory(),
      getExperiences(),
      getCertifications(),
    ]);

  return (
    <main>
      <HotReloadHero
        name={profile?.fullName ?? "Oussema Mansouri"}
        role={profile?.headline.en ?? "Mobile Developer"}
        availability={profile?.availabilityStatus ?? "open"}
      />
      <FeaturedProjects projects={projects} skills={skills} />
      <Teaching experiences={experiences} />
      <Skills groups={groups} certifications={certifications} />
      <Contact profile={profile} />
    </main>
  );
}

'@
Write-File 'app\page.tsx' $c0

$c1 = @'
import Link from "next/link";
import type { Project, Skill } from "@/lib/types";

/**
 * Featured projects.
 *
 * Each card leads with the platform tag rather than a decorative number,
 * because the platform is information a recruiter is actually scanning for.
 *
 * Draft projects never reach this component - the query filters them out.
 * A project without a real narrative and a video is not ready to be seen.
 */

function platformOf(project: Project, skills: Skill[]): string {
  const names = skills
    .filter((s) => project.skillIds.includes(s.id))
    .map((s) => s.name.toLowerCase());

  if (names.some((n) => n.includes("flutter") || n.includes("dart"))) return "Flutter";
  if (names.some((n) => n.includes("swift") || n.includes("uikit"))) return "iOS";
  if (names.some((n) => n.includes("kotlin") || n.includes("java"))) return "Android";
  return "Mobile";
}

export default function FeaturedProjects({
  projects,
  skills,
}: {
  projects: Project[];
  skills: Skill[];
}) {
  if (projects.length === 0) {
    return (
      <section className="mx-auto max-w-5xl px-6 py-28">
        <p className="eyebrow">Selected work</p>
        <p className="mt-6 max-w-md text-[color:var(--color-ink-muted)]">
          No published projects yet. Write a case study in the admin and switch
          it to published - it will appear here.
        </p>
      </section>
    );
  }

  return (
    <section className="mx-auto max-w-5xl px-6 py-28">
      <div className="rule flex items-baseline justify-between pt-8">
        <p className="eyebrow">Selected work</p>
        <Link href="/projects" className="link-underline text-sm">
          All projects
        </Link>
      </div>

      <div className="mt-14 space-y-20">
        {projects.map((project) => {
          const platform = platformOf(project, skills);
          const stack = skills
            .filter((s) => project.skillIds.includes(s.id))
            .slice(0, 5);

          return (
            <article key={project.id} className="grid gap-8 md:grid-cols-[1fr_1.15fr]">
              {/* Media - the recording carries more weight than the copy */}
              <Link
                href={`/projects/${project.slug}`}
                className="group block overflow-hidden"
                style={{
                  backgroundColor: "var(--color-paper-raised)",
                  border: "1px solid var(--color-line)",
                  borderRadius: "4px",
                  aspectRatio: "4 / 3",
                }}
              >
                {project.coverImageUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={project.coverImageUrl}
                    alt={project.title.en}
                    className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-[1.02]"
                  />
                ) : (
                  <div className="flex h-full w-full items-center justify-center">
                    <p className="eyebrow">No media yet</p>
                  </div>
                )}
              </Link>

              {/* Copy */}
              <div className="flex flex-col justify-center">
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
                  <div className="mt-6 flex flex-wrap gap-x-10 gap-y-4">
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
                  className="link-underline mt-7 self-start text-sm"
                >
                  Read the case study
                </Link>
              </div>
            </article>
          );
        })}
      </div>
    </section>
  );
}

'@
Write-File 'components\FeaturedProjects.tsx' $c1

$c2 = @'
import type { Experience } from "@/lib/types";

/**
 * Teaching and mentoring.
 *
 * Placed above skills and below the featured work, deliberately high.
 * Most mid-level mobile developers are not instructors - this is the
 * strongest signal of communication ability and seniority on the CV,
 * and burying it at the bottom wastes it.
 *
 * The dark band is the only inversion on the page after the hero. It
 * marks this as the second thing worth stopping on.
 */

export default function Teaching({ experiences }: { experiences: Experience[] }) {
  const teaching = experiences.filter(
    (e) => e.company.toLowerCase().includes("tek-up") && e.endDate === null
  );

  if (teaching.length === 0) return null;

  const topics = [
    "Swift",
    "SwiftUI",
    "UIKit",
    "Flutter",
    "Dart",
    "Kotlin",
    "REST APIs",
    "Firebase",
    "Clean architecture",
    "Code review",
  ];

  return (
    <section style={{ backgroundColor: "#12151C", color: "#E6E9EE" }}>
      <div className="mx-auto max-w-5xl px-6 py-28">
        <p
          className="font-[family-name:var(--font-mono)] text-xs uppercase tracking-[0.14em]"
          style={{ color: "#6E7787" }}
        >
          Teaching
        </p>

        <h2
          className="mt-6 max-w-2xl font-[family-name:var(--font-display)] font-bold"
          style={{
            fontSize: "clamp(2rem, 4.5vw, 3.25rem)",
            lineHeight: 1.02,
            letterSpacing: "-0.03em",
          }}
        >
          I teach the stack I build in.
        </h2>

        <p className="mt-6 max-w-xl text-lg leading-relaxed" style={{ color: "#9AA3B2" }}>
          Since 2024 I have taught mobile development to engineering students at
          TEK-UP, supervised their application projects end to end, and run the
          technical reviews. Explaining an architecture decision to twenty
          students is a different skill from making it - and it makes the
          decisions better.
        </p>

        <div className="mt-16 grid gap-12 md:grid-cols-2">
          {teaching.map((role) => (
            <div key={role.id}>
              <h3
                className="font-[family-name:var(--font-display)] font-semibold"
                style={{ fontSize: "1.375rem", letterSpacing: "-0.015em" }}
              >
                {role.role.en}
              </h3>
              <p
                className="mt-1 font-[family-name:var(--font-mono)] text-xs"
                style={{ color: "#6E7787" }}
              >
                {role.company} &middot;{" "}
                {new Date(role.startDate).getFullYear()} - present
              </p>

              <ul className="mt-5 space-y-3">
                {role.achievements.map((a, i) => (
                  <li
                    key={i}
                    className="pl-4 text-sm leading-relaxed"
                    style={{
                      color: "#9AA3B2",
                      borderLeft: "1px solid #2A3140",
                    }}
                  >
                    {a.en}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="mt-16">
          <p
            className="font-[family-name:var(--font-mono)] text-xs uppercase tracking-[0.14em]"
            style={{ color: "#6E7787" }}
          >
            Taught
          </p>
          <div className="mt-4 flex flex-wrap gap-2">
            {topics.map((t) => (
              <span
                key={t}
                className="font-[family-name:var(--font-mono)] px-2.5 py-1 text-xs"
                style={{ border: "1px solid #2A3140", color: "#9AA3B2" }}
              >
                {t}
              </span>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}

'@
Write-File 'components\Teaching.tsx' $c2

$c3 = @'
import type { Skill, SkillCategory, Certification } from "@/lib/types";

/**
 * Skills and certifications.
 *
 * Levels read as "4/5 &middot; 3y", not as percentage bars. A bar claiming
 * "Swift 87%" measures nothing and recruiters have learned to skip them.
 * A number next to years of use is at least a claim someone can test in
 * an interview, which is the point.
 */

const LEVEL_MEANING: Record<number, string> = {
  1: "Learning",
  2: "Working knowledge",
  3: "Production comfortable",
  4: "Strong",
  5: "Teach it",
};

export default function Skills({
  groups,
  certifications,
}: {
  groups: Array<{ category: SkillCategory; skills: Skill[] }>;
  certifications: Certification[];
}) {
  return (
    <section className="mx-auto max-w-5xl px-6 py-28">
      <div className="rule pt-8">
        <p className="eyebrow">Stack</p>
      </div>

      <p className="mt-6 max-w-lg text-[color:var(--color-ink-muted)]">
        Levels run 1 to 5, where 3 is production comfortable and 5 means I
        teach it. Rated honestly, because an inflated number gets caught in the
        first technical round.
      </p>

      <div className="mt-14 grid gap-x-16 gap-y-14 md:grid-cols-2">
        {groups.map(({ category, skills }) => (
          <div key={category.id}>
            <h3
              className="font-[family-name:var(--font-display)] font-semibold"
              style={{ fontSize: "1.125rem", letterSpacing: "-0.01em" }}
            >
              {category.name.en}
            </h3>

            <div className="mt-4">
              {skills.map((s) => (
                <div
                  key={s.id}
                  className="rule group flex items-baseline justify-between py-2.5"
                  title={LEVEL_MEANING[s.level]}
                >
                  <span className="text-sm">{s.name}</span>
                  <span className="font-[family-name:var(--font-mono)] text-xs text-[color:var(--color-ink-muted)]">
                    {s.level}/5 &middot; {s.yearsExperience}y
                  </span>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>

      {certifications.length > 0 && (
        <div className="mt-20">
          <p className="eyebrow">Certification</p>
          <div className="mt-5 flex flex-wrap gap-8">
            {certifications.map((c) => (
              <div key={c.id}>
                <p className="font-medium">{c.name}</p>
                <p className="mt-1 font-[family-name:var(--font-mono)] text-xs text-[color:var(--color-ink-muted)]">
                  {c.issuer} &middot; {new Date(c.issueDate).getFullYear()}
                </p>
                {c.credentialUrl && (
                  <a
                    href={c.credentialUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="link-underline mt-2 inline-block text-sm"
                  >
                    Verify
                  </a>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </section>
  );
}

'@
Write-File 'components\Skills.tsx' $c3

$c4 = @'
import type { Profile } from "@/lib/types";

/**
 * Contact.
 *
 * The whole site exists to produce this action, so the section is quiet
 * and unambiguous: one filled button, direct channels underneath, and a
 * stated response time so the visitor knows what happens next.
 *
 * The form itself is wired up in the next phase - for now the direct
 * channels are live, which is what a recruiter reaches for anyway.
 */

export default function Contact({ profile }: { profile: Profile | null }) {
  if (!profile) return null;

  const channels = [
    { label: "Email", value: profile.email, href: `mailto:${profile.email}` },
    { label: "Phone", value: profile.phone, href: `tel:${profile.phone.replace(/\s/g, "")}` },
    profile.linkedinUrl
      ? { label: "LinkedIn", value: "View profile", href: profile.linkedinUrl }
      : null,
    profile.githubUrl
      ? { label: "GitHub", value: "View code", href: profile.githubUrl }
      : null,
  ].filter(Boolean) as Array<{ label: string; value: string; href: string }>;

  return (
    <section className="mx-auto max-w-5xl px-6 pb-32 pt-28">
      <div className="rule pt-8">
        <p className="eyebrow">Contact</p>
      </div>

      <h2
        className="mt-6 max-w-2xl font-[family-name:var(--font-display)] font-bold"
        style={{
          fontSize: "clamp(2rem, 4.5vw, 3.25rem)",
          lineHeight: 1.02,
          letterSpacing: "-0.03em",
        }}
      >
        Hiring, or building something mobile?
      </h2>

      <p className="mt-6 max-w-lg leading-relaxed text-[color:var(--color-ink-muted)]">
        Based in Tunis, open to remote and relocation. I reply within two
        working days.
      </p>

      <div className="mt-10 flex flex-wrap items-center gap-4">
        <a
          href={`mailto:${profile.email}`}
          className="px-6 py-3.5 text-sm font-medium transition-opacity hover:opacity-90"
          style={{
            backgroundColor: "var(--color-accent)",
            color: "var(--color-paper)",
          }}
        >
          Send an email
        </a>

        {profile.cvUrls.en && (
          <a
            href={profile.cvUrls.en}
            className="border px-6 py-3.5 text-sm font-medium transition-colors hover:bg-[color:var(--color-paper-raised)]"
            style={{ borderColor: "var(--color-ink)" }}
          >
            Download CV
          </a>
        )}
      </div>

      <dl className="mt-16 grid gap-x-12 gap-y-6 sm:grid-cols-2 md:grid-cols-4">
        {channels.map((c) => (
          <div key={c.label}>
            <dt className="eyebrow">{c.label}</dt>
            <dd className="mt-2">
              <a href={c.href} className="link-underline text-sm">
                {c.value}
              </a>
            </dd>
          </div>
        ))}
      </dl>

      <p className="mt-20 font-[family-name:var(--font-mono)] text-xs text-[color:var(--color-ink-muted)]">
        Built with Next.js and Firestore. Content managed from a custom admin
        and an iOS companion app.
      </p>
    </section>
  );
}

'@
Write-File 'components\Contact.tsx' $c4


Write-Host ""
Write-Host "Done. Run: npm run dev" -ForegroundColor Cyan