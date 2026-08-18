# ============================================================
#  Portfolio - French locale routing (/en and /fr)
#  Run from project root:  .\setup-i18n.ps1
#
#  This MOVES files. It deletes the old app/layout.tsx,
#  app/projects and app/styleguide, and relocates app/admin
#  into a route group. Commit before running.
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

Write-Host "Restructuring routes..." -ForegroundColor Cyan

# Move admin into its own route group so the public site can have a
# locale-aware root layout of its own.
if (Test-Path ".\app\admin") {
  New-Item -ItemType Directory -Force -Path ".\app\(admin)" | Out-Null
  Move-Item ".\app\admin" ".\app\(admin)\admin" -Force
  Write-Host "  moved  app\admin -> app\(admin)\admin" -ForegroundColor DarkGray
}

# The old single root layout and unprefixed routes are replaced.
foreach ($p in @(".\app\layout.tsx", ".\app\projects", ".\app\page.tsx", ".\app\styleguide")) {
  if (Test-Path $p) {
    Remove-Item $p -Recurse -Force
    Write-Host ("  removed " + $p) -ForegroundColor DarkGray
  }
}

Write-Host ""

$c0 = @'
import { NextResponse, type NextRequest } from "next/server";

/**
 * Locale routing.
 *
 * Every public URL carries its language: /en/projects, /fr/projets-style
 * paths stay the same slug but the prefix differs. A bare / redirects to
 * the visitor's preferred language if we serve it, English otherwise.
 *
 * Real URLs rather than a client-side toggle, because the point of the
 * French version is that a recruiter searching in French can find it.
 * A toggle that never changes the URL is invisible to a search engine.
 */

const LOCALES = ["en", "fr"];
const DEFAULT = "en";

function preferred(request: NextRequest): string {
  const header = request.headers.get("accept-language");
  if (!header) return DEFAULT;
  // "fr-FR,fr;q=0.9,en;q=0.8" - first match wins
  for (const part of header.split(",")) {
    const tag = part.split(";")[0].trim().slice(0, 2).toLowerCase();
    if (LOCALES.includes(tag)) return tag;
  }
  return DEFAULT;
}

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  const hasLocale = LOCALES.some(
    (l) => pathname === `/${l}` || pathname.startsWith(`/${l}/`)
  );
  if (hasLocale) return NextResponse.next();

  const url = request.nextUrl.clone();
  url.pathname = `/${preferred(request)}${pathname === "/" ? "" : pathname}`;
  return NextResponse.redirect(url);
}

export const config = {
  // Admin, API, static assets and files with extensions are left alone.
  matcher: ["/((?!admin|api|_next|favicon.ico|.*\\..*).*)"],
};

'@
Write-File 'middleware.ts' $c0

$c1 = @'
import type { Locale } from "@/lib/types";

/**
 * Interface strings.
 *
 * Only chrome lives here - section labels, buttons, the few sentences not
 * stored in Firestore. Everything substantive (bio, project narratives,
 * achievements) is already bilingual in the database, so this file stays
 * small on purpose.
 *
 * Typed against the English keys, so a missing French string is a build
 * error rather than an English word appearing on a French page.
 */

export const LOCALES: Locale[] = ["en", "fr"];
export const DEFAULT_LOCALE: Locale = "en";

export function isLocale(value: string): value is Locale {
  return LOCALES.includes(value as Locale);
}

const en = {
  // hero
  heroSub:
    "Mobile developer and instructor at TEK-UP. Three years shipping native iOS, cross-platform Flutter, and native Android.",
  heroEditorNote: "HeroCard - shared across all three targets",
  heroHint: "Edit the code - all three devices update as you type",
  heroHintTouched: "One edit, three platforms. That is the job.",
  reloading: "reloading...",
  live: "live",
  compiledIn: "compiled in",
  tint: "tint",
  radius: "radius",

  // availability
  available: "Available for work",
  open: "Open to offers",
  unavailable: "Not available",

  // sections
  selectedWork: "Selected work",
  allProjects: "All projects",
  readCaseStudy: "Read the case study",
  noProjects:
    "No published projects yet. Case studies appear once they have a real narrative and a recording of the app running.",

  teaching: "Teaching",
  teachingTitle: "I teach the stack I build in.",
  teachingBody:
    "Since 2024 I have taught mobile development to engineering students at TEK-UP, supervised their application projects end to end, and run the technical reviews. Explaining an architecture decision to twenty students is a different skill from making it, and it makes the decisions better.",
  taught: "Taught",
  present: "present",

  stack: "Stack",
  stackNote:
    "Levels run 1 to 5, where 3 is production comfortable and 5 means I teach it. Rated honestly, because an inflated number gets caught in the first technical round.",
  certification: "Certification",
  verify: "Verify",

  // contact
  contact: "Contact",
  contactTitle: "Hiring, or building something mobile?",
  contactBody:
    "Based in Tunis, open to remote and relocation. I reply within two working days.",
  name: "Name",
  email: "Email",
  company: "Company",
  optional: "(optional)",
  about: "About",
  message: "Message",
  send: "Send message",
  sending: "Sending...",
  sent: "Message received.",
  sentBody: "I reply within two working days. If it is urgent, email me directly at",
  sendFailed: "That did not send. Email me directly at",
  subjectJob: "A role",
  subjectFreelance: "Freelance work",
  subjectTraining: "Training",
  subjectOther: "Something else",
  downloadCv: "Download CV",
  builtWith:
    "Built with Next.js and Firestore. Content managed from a custom admin.",

  // projects pages
  projects: "Projects",
  back: "Back",
  all: "All",
  nothingHere:
    "Nothing published here yet. Case studies appear once they have a real narrative and a recording of the app running.",
  context: "Context",
  problem: "The problem",
  role: "My role",
  decisions: "Technical decisions",
  challenges: "Challenges",
  result: "Result",
  links: "Links",
  next: "Next",
  getInTouch: "Get in touch",
  writeupInProgress: "The write-up for this project is still in progress.",
} as const;

const fr: Record<keyof typeof en, string> = {
  heroSub:
    "D\u00e9veloppeur mobile et formateur \u00e0 TEK-UP. Trois ans \u00e0 livrer de l'iOS natif, du Flutter multiplateforme et de l'Android natif.",
  heroEditorNote: "HeroCard - partag\u00e9 par les trois cibles",
  heroHint: "Modifiez le code - les trois appareils se mettent \u00e0 jour",
  heroHintTouched: "Une modification, trois plateformes. C'est le m\u00e9tier.",
  reloading: "rechargement...",
  live: "en direct",
  compiledIn: "compil\u00e9 en",
  tint: "teinte",
  radius: "rayon",

  available: "Disponible",
  open: "Ouvert aux opportunit\u00e9s",
  unavailable: "Non disponible",

  selectedWork: "Travaux s\u00e9lectionn\u00e9s",
  allProjects: "Tous les projets",
  readCaseStudy: "Lire l'\u00e9tude de cas",
  noProjects:
    "Aucun projet publi\u00e9 pour l'instant. Les \u00e9tudes de cas apparaissent une fois qu'elles ont un vrai r\u00e9cit et un enregistrement de l'application.",

  teaching: "Enseignement",
  teachingTitle: "J'enseigne la stack que je pratique.",
  teachingBody:
    "Depuis 2024, j'enseigne le d\u00e9veloppement mobile aux \u00e9l\u00e8ves ing\u00e9nieurs de TEK-UP, j'encadre leurs projets applicatifs de bout en bout et j'anime les revues techniques. Expliquer une d\u00e9cision d'architecture \u00e0 vingt \u00e9tudiants est une comp\u00e9tence diff\u00e9rente de celle de la prendre, et cela rend les d\u00e9cisions meilleures.",
  taught: "Enseign\u00e9",
  present: "aujourd'hui",

  stack: "Stack",
  stackNote:
    "Les niveaux vont de 1 \u00e0 5, o\u00f9 3 signifie \u00e0 l'aise en production et 5 signifie que je l'enseigne. \u00c9valu\u00e9s honn\u00eatement, car un chiffre gonfl\u00e9 se voit d\u00e8s le premier entretien technique.",
  certification: "Certification",
  verify: "V\u00e9rifier",

  contact: "Contact",
  contactTitle: "Vous recrutez, ou vous construisez du mobile ?",
  contactBody:
    "Bas\u00e9 \u00e0 Tunis, ouvert au distanciel et \u00e0 la mobilit\u00e9. Je r\u00e9ponds sous deux jours ouvr\u00e9s.",
  name: "Nom",
  email: "Email",
  company: "Entreprise",
  optional: "(facultatif)",
  about: "Sujet",
  message: "Message",
  send: "Envoyer",
  sending: "Envoi...",
  sent: "Message bien re\u00e7u.",
  sentBody:
    "Je r\u00e9ponds sous deux jours ouvr\u00e9s. Si c'est urgent, \u00e9crivez-moi directement \u00e0",
  sendFailed: "L'envoi a \u00e9chou\u00e9. \u00c9crivez-moi directement \u00e0",
  subjectJob: "Un poste",
  subjectFreelance: "Une mission freelance",
  subjectTraining: "Une formation",
  subjectOther: "Autre chose",
  downloadCv: "T\u00e9l\u00e9charger le CV",
  builtWith:
    "R\u00e9alis\u00e9 avec Next.js et Firestore. Contenu g\u00e9r\u00e9 depuis un back-office sur mesure.",

  projects: "Projets",
  back: "Retour",
  all: "Tous",
  nothingHere:
    "Rien de publi\u00e9 ici pour l'instant. Les \u00e9tudes de cas apparaissent une fois qu'elles ont un vrai r\u00e9cit et un enregistrement de l'application.",
  context: "Contexte",
  problem: "Le probl\u00e8me",
  role: "Mon r\u00f4le",
  decisions: "D\u00e9cisions techniques",
  challenges: "Difficult\u00e9s",
  result: "R\u00e9sultat",
  links: "Liens",
  next: "Suite",
  getInTouch: "Me contacter",
  writeupInProgress: "La r\u00e9daction de ce projet est encore en cours.",
};

export type Dict = typeof en;

const DICTS: Record<Locale, Dict> = { en, fr: fr as Dict };

export function getDict(locale: Locale): Dict {
  return DICTS[locale] ?? DICTS.en;
}

/** Swap the locale segment of a path, for the language toggle. */
export function switchLocalePath(pathname: string, next: Locale): string {
  const parts = pathname.split("/").filter(Boolean);
  if (parts.length > 0 && isLocale(parts[0])) {
    parts[0] = next;
    return "/" + parts.join("/");
  }
  return `/${next}${pathname}`;
}

'@
Write-File 'lib\i18n.ts' $c1

$c2 = @'
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { LOCALES, switchLocalePath } from "@/lib/i18n";
import type { Locale } from "@/lib/types";

/**
 * Language switch.
 *
 * A real link to the equivalent URL, not a state toggle - so it can be
 * opened in a new tab, shared, bookmarked and crawled. The inactive
 * language is always visible rather than hidden behind a dropdown,
 * because two options do not need a menu.
 */

export default function LocaleToggle({ current }: { current: Locale }) {
  const pathname = usePathname();

  return (
    <div className="fixed right-5 top-5 z-50 flex items-center gap-1">
      {LOCALES.map((l) => {
        const active = l === current;
        return (
          <Link
            key={l}
            href={switchLocalePath(pathname, l)}
            hrefLang={l}
            aria-current={active ? "true" : undefined}
            className="font-[family-name:var(--font-mono)] px-2 py-1 text-[11px] uppercase tracking-[0.1em] transition-opacity"
            style={{
              color: active ? "#E6E9EE" : "#8A93A5",
              backgroundColor: active ? "rgba(255,255,255,0.12)" : "transparent",
              borderRadius: "3px",
              opacity: active ? 1 : 0.75,
            }}
          >
            {l}
          </Link>
        );
      })}
    </div>
  );
}

'@
Write-File 'components\LocaleToggle.tsx' $c2

$c3 = @'
import type { Metadata } from "next";
import { Bricolage_Grotesque, Public_Sans, JetBrains_Mono } from "next/font/google";
import { notFound } from "next/navigation";
import { isLocale, LOCALES } from "@/lib/i18n";
import LocaleToggle from "@/components/LocaleToggle";
import "../../globals.css";

const bricolage = Bricolage_Grotesque({
  variable: "--font-bricolage",
  subsets: ["latin"],
  display: "swap",
  weight: ["400", "600", "700"],
});
const publicSans = Public_Sans({
  variable: "--font-public-sans",
  subsets: ["latin"],
  display: "swap",
});
const jetbrains = JetBrains_Mono({
  variable: "--font-jetbrains",
  subsets: ["latin"],
  display: "swap",
  weight: ["400", "500"],
});

export function generateStaticParams() {
  return LOCALES.map((locale) => ({ locale }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const site = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";

  const meta = {
    en: {
      title: "Oussema Mansouri - Mobile Developer (iOS, Flutter, Android)",
      description:
        "Mobile developer and instructor in Tunis. Native iOS with Swift and SwiftUI, cross-platform Flutter, native Android. AWS Certified Cloud Practitioner.",
    },
    fr: {
      title: "Oussema Mansouri - D\u00e9veloppeur Mobile (iOS, Flutter, Android)",
      description:
        "D\u00e9veloppeur mobile et formateur \u00e0 Tunis. iOS natif avec Swift et SwiftUI, Flutter multiplateforme, Android natif. AWS Certified Cloud Practitioner.",
    },
  }[locale === "fr" ? "fr" : "en"];

  return {
    title: meta.title,
    description: meta.description,
    metadataBase: new URL(site),
    alternates: {
      canonical: `${site}/${locale}`,
      // hreflang tells Google these are translations of one page rather
      // than duplicate content competing with each other.
      languages: {
        en: `${site}/en`,
        fr: `${site}/fr`,
        "x-default": `${site}/en`,
      },
    },
    openGraph: {
      title: meta.title,
      description: meta.description,
      locale: locale === "fr" ? "fr_FR" : "en_US",
      type: "profile",
    },
  };
}

export default async function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!isLocale(locale)) notFound();

  return (
    <html lang={locale}>
      <body
        className={`${bricolage.variable} ${publicSans.variable} ${jetbrains.variable}`}
      >
        <LocaleToggle current={locale} />
        {children}
      </body>
    </html>
  );
}

'@
Write-File 'app\(site)\[locale]\layout.tsx' $c3

$c4 = @'
import { notFound } from "next/navigation";
import HotReloadHero from "@/components/HotReloadHero";
import FeaturedProjects from "@/components/FeaturedProjects";
import Teaching from "@/components/Teaching";
import Skills from "@/components/Skills";
import Contact from "@/components/Contact";
import Reveal from "@/components/Reveal";
import { isLocale } from "@/lib/i18n";
import { t as tr } from "@/lib/types";

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

export default async function Home({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!isLocale(locale)) notFound();

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
      {/* Never wrapped in Reveal - the headline and availability badge
          must be readable the instant the page paints. */}
      <HotReloadHero
        name={profile?.fullName ?? "Oussema Mansouri"}
        availability={profile?.availabilityStatus ?? "open"}
        locale={locale}
      />

      <FeaturedProjects projects={featured} skills={skills} locale={locale} />

      <Reveal>
        <Teaching experiences={experiences} locale={locale} />
      </Reveal>

      <Reveal>
        <Skills
          groups={groups}
          certifications={certifications}
          projects={allProjects}
          locale={locale}
        />
      </Reveal>

      <Reveal>
        <Contact profile={profile} locale={locale} />
      </Reveal>
    </main>
  );
}

'@
Write-File 'app\(site)\[locale]\page.tsx' $c4

$c5 = @'
import type { Metadata } from "next";
import ProjectsIndex from "@/components/ProjectsIndex";
import { notFound } from "next/navigation";
import { isLocale } from "@/lib/i18n";
import { getPublishedProjects, getSkills } from "@/lib/queries";

export const revalidate = 3600;

export const metadata: Metadata = {
  title: "Projects - Oussema Mansouri",
  description:
    "Mobile application case studies: native iOS with Swift and SwiftUI, cross-platform Flutter, native Android.",
};

export default async function Page({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!isLocale(locale)) notFound();

  const [projects, skills] = await Promise.all([
    getPublishedProjects(),
    getSkills(),
  ]);

  return <ProjectsIndex projects={projects} skills={skills} locale={locale} />;
}

'@
Write-File 'app\(site)\[locale]\projects\page.tsx' $c5

$c6 = @'
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { platformOf, PLATFORM_COLOR } from "@/lib/platform";
import { isLocale, getDict, LOCALES } from "@/lib/i18n";
import { t as tr } from "@/lib/types";
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
  return LOCALES.flatMap((locale) => slugs.map((slug) => ({ locale, slug })));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string; slug: string }>;
}): Promise<Metadata> {
  const { locale, slug } = await params;
  const project = await getProjectBySlug(slug);
  if (!project) return { title: "Not found" };

  const lang = isLocale(locale) ? locale : "en";
  const site = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";

  return {
    title: `${tr(project.title, lang)} - Oussema Mansouri`,
    description: tr(project.summary, lang),
    alternates: {
      canonical: `${site}/${lang}/projects/${slug}`,
      languages: {
        en: `${site}/en/projects/${slug}`,
        fr: `${site}/fr/projects/${slug}`,
      },
    },
  };
}

export default async function Page({
  params,
}: {
  params: Promise<{ locale: string; slug: string }>;
}) {
  const { locale, slug } = await params;
  if (!isLocale(locale)) notFound();
  const d = getDict(locale);
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
    { label: d.context, body: tr(project.caseStudy.context, locale) },
    { label: d.problem, body: tr(project.caseStudy.problem, locale) },
    { label: d.role, body: tr(project.caseStudy.role, locale) },
    { label: d.decisions, body: tr(project.caseStudy.technicalDecisions, locale) },
    { label: d.challenges, body: tr(project.caseStudy.challenges, locale) },
    { label: d.result, body: tr(project.caseStudy.result, locale) },
  ].filter((s) => isWritten(s.body));

  const links = Object.entries(project.links).filter(([, v]) => v);

  return (
    <main className="mx-auto max-w-3xl px-6 py-20">
      <Link href={`/${locale}/projects`} className="link-underline text-sm">
        {d.allProjects}
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
        {tr(project.title, locale)}
      </h1>

      <p
        className="mt-6 leading-relaxed text-[color:var(--color-ink-muted)]"
        style={{ fontSize: "var(--text-lead)" }}
      >
        {tr(project.summary, locale)}
      </p>

      {project.metrics.length > 0 && (
        <div className="rule mt-12 flex flex-wrap gap-x-14 gap-y-6 pt-8">
          {project.metrics.map((m) => (
            <div key={tr(m.label, locale)}>
              <p
                className="font-[family-name:var(--font-display)] font-semibold"
                style={{ fontSize: "2rem", letterSpacing: "-0.025em" }}
              >
                {m.value}
              </p>
              <p className="eyebrow mt-1">{tr(m.label, locale)}</p>
            </div>
          ))}
        </div>
      )}

      {project.coverImageUrl && (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={project.coverImageUrl}
          alt={tr(project.title, locale)}
          className="mt-12 w-full"
          style={{ borderRadius: "4px", border: "1px solid var(--color-line)" }}
        />
      )}

      {sections.length === 0 ? (
        <p className="rule mt-12 pt-8 text-[color:var(--color-ink-muted)]">
          {d.writeupInProgress}
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
                  alt={tr(m.caption, locale)}
                  className="w-full"
                  style={{
                    borderRadius: "4px",
                    border: "1px solid var(--color-line)",
                  }}
                />
              )}
              {tr(m.caption, locale) && (
                <figcaption className="eyebrow mt-3">{tr(m.caption, locale)}</figcaption>
              )}
            </figure>
          ))}
        </div>
      )}

      <section className="rule mt-16 pt-8">
        <p className="eyebrow">{d.stack}</p>
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
          <p className="eyebrow">{d.links}</p>
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
          <p className="eyebrow">{d.next}</p>
          <div className="mt-6 space-y-5">
            {related.map((p) => (
              <Link
                key={p.id}
                href={`/${locale}/projects/${p.slug}`}
                className="block hover:opacity-70"
              >
                <p
                  className="font-[family-name:var(--font-display)] font-semibold"
                  style={{ fontSize: "1.25rem", letterSpacing: "-0.015em" }}
                >
                  {tr(p.title, locale)}
                </p>
                <p className="mt-1 text-sm text-[color:var(--color-ink-muted)]">
                  {tr(p.summary, locale).slice(0, 110)}...
                </p>
              </Link>
            ))}
          </div>
        </section>
      )}

      <div className="rule mt-16 pt-8">
        <Link href={`/${locale}#contact`} className="link-underline text-sm">
          {d.getInTouch}
        </Link>
      </div>
    </main>
  );
}

'@
Write-File 'app\(site)\[locale]\projects\[slug]\page.tsx' $c6

$c7 = @'
import type { MetadataRoute } from "next";
import { getAllProjectSlugs } from "@/lib/queries";
import { LOCALES } from "@/lib/i18n";

/**
 * Sitemap.
 *
 * Every page listed once per locale, with alternates pointing at each
 * other. Without this, Google has to discover the French version by
 * crawling, and may treat it as duplicate content rather than a
 * translation.
 */

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const site = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";
  const slugs = await getAllProjectSlugs();

  const paths = ["", "/projects", ...slugs.map((s) => `/projects/${s}`)];

  return paths.flatMap((path) =>
    LOCALES.map((locale) => ({
      url: `${site}/${locale}${path}`,
      lastModified: new Date(),
      changeFrequency: "weekly" as const,
      priority: path === "" ? 1 : 0.8,
      alternates: {
        languages: Object.fromEntries(
          LOCALES.map((l) => [l, `${site}/${l}${path}`])
        ),
      },
    }))
  );
}

'@
Write-File 'app\(site)\sitemap.ts' $c7

$c8 = @'
import type { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
  const site = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";
  return {
    rules: [{ userAgent: "*", allow: "/", disallow: "/admin" }],
    sitemap: `${site}/sitemap.xml`,
  };
}

'@
Write-File 'app\(site)\robots.ts' $c8

$c9 = @'
import { Public_Sans, JetBrains_Mono, Bricolage_Grotesque } from "next/font/google";
import "../globals.css";

/**
 * Admin root layout.
 *
 * A separate root from the public site because the site's html lang
 * changes per locale and the admin does not. Route groups let both exist
 * without one nesting inside the other.
 */

const bricolage = Bricolage_Grotesque({
  variable: "--font-bricolage",
  subsets: ["latin"],
  display: "swap",
  weight: ["400", "600", "700"],
});
const publicSans = Public_Sans({
  variable: "--font-public-sans",
  subsets: ["latin"],
  display: "swap",
});
const jetbrains = JetBrains_Mono({
  variable: "--font-jetbrains",
  subsets: ["latin"],
  display: "swap",
  weight: ["400", "500"],
});

export const metadata = {
  title: "Admin",
  robots: { index: false, follow: false },
};

export default function AdminRootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body
        className={`${bricolage.variable} ${publicSans.variable} ${jetbrains.variable}`}
      >
        {children}
      </body>
    </html>
  );
}

'@
Write-File 'app\(admin)\layout.tsx' $c9

$c10 = @'
"use client";

import { useState, useEffect, useRef } from "react";
import type { Locale } from "@/lib/types";
import { getDict } from "@/lib/i18n";

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
  locale = "en" as Locale,
}) {
  const d = getDict(locale);
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
    available: { label: d.available, color: "#3FCF8E" },
    open: { label: d.open, color: "#E8B84B" },
    unavailable: { label: d.unavailable, color: "#E86B6B" },
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
              {d.heroSub}
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
              {d.heroEditorNote}
            </p>
            <p
              className="font-[family-name:var(--font-mono)] text-[11px] transition-opacity duration-200"
              style={{ color: "#8B80FF", opacity: pulse ? 1 : 0.4 }}
            >
              {pulse
                ? d.reloading
                : compileMs !== null
                  ? `${d.compiledIn} ${compileMs.toFixed(2)}s`
                  : d.live}
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
                  {d.tint}
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
                  {d.radius}
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
              {touched ? d.heroHintTouched : d.heroHint}
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}

'@
Write-File 'components\HotReloadHero.tsx' $c10

$c11 = @'
"use client";

import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import DeviceFrame from "./DeviceFrame";
import type { Project, Skill, Locale } from "@/lib/types";
import { t as tr } from "@/lib/types";
import { getDict } from "@/lib/i18n";
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
  locale,
}: {
  project: Project;
  platform: string;
  stack: Skill[];
  locale: Locale;
}) {
  if (project.coverImageUrl) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={project.coverImageUrl}
        alt={tr(project.title, locale)}
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
        {tr(project.title, locale)}
      </p>

      <div
        className="mt-5 flex-1 overflow-hidden p-4"
        style={{ backgroundColor: tint, borderRadius: "18px" }}
      >
        <p
          className="text-[13px] leading-relaxed"
          style={{ color: "#FFFFFF", opacity: 0.92 }}
        >
          {tr(project.summary, locale).slice(0, 150)}
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
  locale,
}: {
  projects: Project[];
  skills: Skill[];
  locale: Locale;
}) {
  const d = getDict(locale);
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
          <p className="eyebrow">{d.selectedWork}</p>
        </div>
        <p className="mt-6 max-w-md text-[color:var(--color-ink-muted)]">
          {d.noProjects}
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
        <p className="eyebrow">{d.selectedWork}</p>
        <Link href={`/${locale}/projects`} className="link-underline text-sm">
          {d.allProjects}
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
                  <Link href={`/${locale}/projects/${project.slug}`} className="hover:opacity-70">
                    {tr(project.title, locale)}
                  </Link>
                </h3>

                <p className="mt-4 max-w-md leading-relaxed text-[color:var(--color-ink-muted)]">
                  {tr(project.summary, locale)}
                </p>

                {project.metrics.length > 0 && (
                  <div className="mt-7 flex flex-wrap gap-x-10 gap-y-4">
                    {project.metrics.slice(0, 3).map((m) => (
                      <div key={tr(m.label, locale)}>
                        <p
                          className="font-[family-name:var(--font-display)] font-semibold"
                          style={{ fontSize: "1.5rem", letterSpacing: "-0.02em" }}
                        >
                          {m.value}
                        </p>
                        <p className="eyebrow mt-1">{tr(m.label, locale)}</p>
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
                  href={`/${locale}/projects/${project.slug}`}
                  className="link-underline mt-7 self-start text-sm"
                >
                  {d.readCaseStudy}
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
                    locale={locale}
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
Write-File 'components\FeaturedProjects.tsx' $c11

$c12 = @'
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

'@
Write-File 'components\ProjectsIndex.tsx' $c12

$c13 = @'
import type { Experience, Locale } from "@/lib/types";
import { t as tr } from "@/lib/types";
import { getDict } from "@/lib/i18n";

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

export default function Teaching({
  experiences,
  locale,
}: {
  experiences: Experience[];
  locale: Locale;
}) {
  const d = getDict(locale);
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
          {d.teaching}
        </p>

        <h2
          className="mt-6 max-w-2xl font-[family-name:var(--font-display)] font-bold"
          style={{
            fontSize: "clamp(2rem, 4.5vw, 3.25rem)",
            lineHeight: 1.02,
            letterSpacing: "-0.03em",
          }}
        >
          {d.teachingTitle}
        </h2>

        <p className="mt-6 max-w-xl text-lg leading-relaxed" style={{ color: "#9AA3B2" }}>
          {d.teachingBody}
        </p>

        <div className="mt-16 grid gap-12 md:grid-cols-2">
          {teaching.map((role) => (
            <div key={role.id}>
              <h3
                className="font-[family-name:var(--font-display)] font-semibold"
                style={{ fontSize: "1.375rem", letterSpacing: "-0.015em" }}
              >
                {tr(role.role, locale)}
              </h3>
              <p
                className="mt-1 font-[family-name:var(--font-mono)] text-xs"
                style={{ color: "#6E7787" }}
              >
                {role.company} &middot;{" "}
                {new Date(role.startDate).getFullYear()} - {d.present}
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
                    {tr(a, locale)}
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
            {d.taught}
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
Write-File 'components\Teaching.tsx' $c13

$c14 = @'
"use client";

import { useState } from "react";
import type { Skill, SkillCategory, Certification, Project, Locale } from "@/lib/types";
import { t as tr } from "@/lib/types";
import { getDict } from "@/lib/i18n";

/**
 * Stack.
 *
 * Levels read as "4/5 - 3y", not as percentage bars. A bar claiming
 * "Swift 87%" measures nothing and recruiters have learned to skip them.
 * A number beside years of use is at least a claim someone can test in
 * an interview, which is the point.
 *
 * Hovering or focusing a skill names the projects that use it. That turns
 * a list of assertions into a list of evidence, which is the difference
 * between a CV and a portfolio.
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
  projects = [],
  locale,
}: {
  groups: Array<{ category: SkillCategory; skills: Skill[] }>;
  certifications: Certification[];
  projects?: Project[];
  locale: Locale;
}) {
  const [hovered, setHovered] = useState<string | null>(null);
  const d = getDict(locale);

  const proofFor = (skillId: string) =>
    projects.filter((p) => p.skillIds.includes(skillId));

  return (
    <section className="mx-auto max-w-5xl px-6 py-28">
      <div className="rule pt-8">
        <p className="eyebrow">{d.stack}</p>
      </div>

      <p className="mt-6 max-w-lg text-[color:var(--color-ink-muted)]">
        {d.stackNote}
      </p>

      <div className="mt-14 grid gap-x-16 gap-y-14 md:grid-cols-2">
        {groups.map(({ category, skills }) => (
          <div key={category.id}>
            <h3
              className="font-[family-name:var(--font-display)] font-semibold"
              style={{ fontSize: "1.125rem", letterSpacing: "-0.01em" }}
            >
              {tr(category.name, locale)}
            </h3>

            <div className="mt-4">
              {skills.map((s) => {
                const proof = proofFor(s.id);
                const open = hovered === s.id && proof.length > 0;

                return (
                  <div
                    key={s.id}
                    className="rule"
                    onMouseEnter={() => setHovered(s.id)}
                    onMouseLeave={() => setHovered(null)}
                  >
                    <button
                      onFocus={() => setHovered(s.id)}
                      onBlur={() => setHovered(null)}
                      className="flex w-full items-baseline justify-between py-2.5 text-left"
                      title={LEVEL_MEANING[s.level]}
                      aria-expanded={open}
                    >
                      <span className="text-sm">{s.name}</span>
                      <span className="font-[family-name:var(--font-mono)] text-xs text-[color:var(--color-ink-muted)]">
                        {s.level}/5 &middot; {s.yearsExperience}y
                      </span>
                    </button>

                    <div
                      className="overflow-hidden transition-all duration-300"
                      style={{
                        maxHeight: open ? "6rem" : "0",
                        opacity: open ? 1 : 0,
                      }}
                    >
                      <p
                        className="pb-3 font-[family-name:var(--font-mono)] text-[11px] leading-relaxed"
                        style={{ color: "var(--color-accent)" }}
                      >
                        {proof.map((p) => tr(p.title, locale)).join(" / ")}
                      </p>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        ))}
      </div>

      {certifications.length > 0 && (
        <div className="mt-20">
          <p className="eyebrow">{d.certification}</p>
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
                    {d.verify}
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
Write-File 'components\Skills.tsx' $c14

$c15 = @'
import type { Profile, Locale } from "@/lib/types";
import { getDict } from "@/lib/i18n";
import ContactForm from "./ContactForm";

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

export default function Contact({
  profile,
  locale,
}: {
  profile: Profile | null;
  locale: Locale;
}) {
  if (!profile) return null;
  const d = getDict(locale);

  const channels = [
    { label: d.email, value: profile.email, href: `mailto:${profile.email}` },
    { label: "Phone", value: profile.phone, href: `tel:${profile.phone.replace(/\s/g, "")}` },
    profile.linkedinUrl
      ? { label: "LinkedIn", value: "View profile", href: profile.linkedinUrl }
      : null,
    profile.githubUrl
      ? { label: "GitHub", value: "View code", href: profile.githubUrl }
      : null,
  ].filter(Boolean) as Array<{ label: string; value: string; href: string }>;

  return (
    <section id="contact" className="mx-auto max-w-5xl px-6 pb-32 pt-28">
      <div className="rule pt-8">
        <p className="eyebrow">{d.contact}</p>
      </div>

      <h2
        className="mt-6 max-w-2xl font-[family-name:var(--font-display)] font-bold"
        style={{
          fontSize: "clamp(2rem, 4.5vw, 3.25rem)",
          lineHeight: 1.02,
          letterSpacing: "-0.03em",
        }}
      >
        {d.contactTitle}
      </h2>

      <p className="mt-6 max-w-lg leading-relaxed text-[color:var(--color-ink-muted)]">
        {d.contactBody}
      </p>

      <ContactForm locale={locale} />

      {profile.cvUrls.en && (
        <div className="mt-8">
          <a
            href={locale === "fr" && profile.cvUrls.fr ? profile.cvUrls.fr : profile.cvUrls.en}
            className="border px-6 py-3.5 text-sm font-medium transition-colors hover:bg-[color:var(--color-paper-raised)]"
            style={{ borderColor: "var(--color-ink)" }}
          >
            {d.downloadCv}
          </a>
        </div>
      )}

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
        {d.builtWith}
      </p>
    </section>
  );
}

'@
Write-File 'components\Contact.tsx' $c15

$c16 = @'
"use client";

import { useState } from "react";
import { collection, addDoc } from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import type { Locale } from "@/lib/types";
import { getDict } from "@/lib/i18n";

/**
 * Contact form.
 *
 * Writes directly to the messages collection. Anonymous creates are
 * allowed by firestore.rules, but only in a narrow shape - the rules
 * check field presence, message length, email format and that status is
 * "unread". Client validation here mirrors those constraints so a real
 * person gets a useful error instead of a permission denial.
 *
 * Only Oussema's UID can read the collection back, so submissions are
 * write-only from the public side.
 *
 * The subject field is a honeypot. It is positioned off-screen and hidden
 * from assistive technology; a human never sees it, and most bots fill
 * every input they find.
 */

const SUBJECT_VALUES = ["job", "freelance", "training", "other"] as const;

type State = "idle" | "sending" | "sent" | "error";

export default function ContactForm({ locale }: { locale: Locale }) {
  const d = getDict(locale);
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [company, setCompany] = useState("");
  const [subjectType, setSubjectType] =
    useState<(typeof SUBJECT_VALUES)[number]>("job");
  const [message, setMessage] = useState("");
  const [honeypot, setHoneypot] = useState("");
  const [state, setState] = useState<State>("idle");
  const [error, setError] = useState("");

  const emailValid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  const canSend =
    name.trim().length > 0 &&
    name.trim().length <= 120 &&
    emailValid &&
    message.trim().length > 10 &&
    message.trim().length <= 5000;

  const submit = async () => {
    if (!canSend || state === "sending") return;

    // A filled honeypot is almost certainly a bot. Show the success state
    // rather than an error - a bot that knows it failed will retry.
    if (honeypot) {
      setState("sent");
      return;
    }

    setState("sending");
    setError("");

    try {
      await addDoc(collection(db, "messages"), {
        name: name.trim(),
        email: email.trim(),
        company: company.trim(),
        subjectType,
        message: message.trim(),
        status: "unread",
        createdAt: new Date().toISOString(),
      });
      setState("sent");
    } catch {
      setState("error");
      setError(`${d.sendFailed} oussemamansouri4@gmail.com`);
    }
  };

  if (state === "sent") {
    return (
      <div
        className="mt-10 p-8"
        style={{
          border: "1px solid var(--color-line)",
          backgroundColor: "var(--color-paper-raised)",
        }}
      >
        <p
          className="font-[family-name:var(--font-display)] font-semibold"
          style={{ fontSize: "1.375rem", letterSpacing: "-0.015em" }}
        >
          {d.sent}
        </p>
        <p className="mt-3 text-[color:var(--color-ink-muted)]">
          {d.sentBody} oussemamansouri4@gmail.com
        </p>
      </div>
    );
  }

  const field: React.CSSProperties = {
    border: "1px solid var(--color-line)",
    backgroundColor: "var(--color-paper-raised)",
  };

  return (
    <div className="mt-10 max-w-xl">
      {/* Honeypot. Off-screen rather than display:none, because some bots
          skip inputs that are not rendered. */}
      <div
        aria-hidden
        style={{
          position: "absolute",
          left: "-9999px",
          width: 1,
          height: 1,
          overflow: "hidden",
        }}
      >
        <label htmlFor="subject-line">Subject</label>
        <input
          id="subject-line"
          name="subject-line"
          tabIndex={-1}
          autoComplete="off"
          value={honeypot}
          onChange={(e) => setHoneypot(e.target.value)}
        />
      </div>

      <div className="grid gap-5 sm:grid-cols-2">
        <div>
          <label className="eyebrow block" htmlFor="c-name">
            {d.name}
          </label>
          <input
            id="c-name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            maxLength={120}
            className="mt-2 w-full px-3 py-2.5 text-sm"
            style={field}
          />
        </div>

        <div>
          <label className="eyebrow block" htmlFor="c-email">
            {d.email}
          </label>
          <input
            id="c-email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="mt-2 w-full px-3 py-2.5 text-sm"
            style={{
              ...field,
              borderColor:
                email.length > 0 && !emailValid
                  ? "var(--color-status-open)"
                  : "var(--color-line)",
            }}
          />
        </div>
      </div>

      <div className="mt-5">
        <label className="eyebrow block" htmlFor="c-company">
          {d.company} <span style={{ textTransform: "none" }}>{d.optional}</span>
        </label>
        <input
          id="c-company"
          value={company}
          onChange={(e) => setCompany(e.target.value)}
          className="mt-2 w-full px-3 py-2.5 text-sm"
          style={field}
        />
      </div>

      <fieldset className="mt-6">
        <legend className="eyebrow">{d.about}</legend>
        <div className="mt-3 flex flex-wrap gap-2">
          {SUBJECT_VALUES.map((v) => {
            const on = subjectType === v;
            const label = {
              job: d.subjectJob,
              freelance: d.subjectFreelance,
              training: d.subjectTraining,
              other: d.subjectOther,
            }[v];
            return (
              <button
                key={v}
                type="button"
                onClick={() => setSubjectType(v)}
                aria-pressed={on}
                className="border px-3 py-1.5 text-sm transition-colors"
                style={{
                  borderColor: on ? "var(--color-ink)" : "var(--color-line)",
                  backgroundColor: on ? "var(--color-ink)" : "transparent",
                  color: on ? "var(--color-paper)" : "var(--color-ink-muted)",
                }}
              >
                {label}
              </button>
            );
          })}
        </div>
      </fieldset>

      <div className="mt-6">
        <label className="eyebrow block" htmlFor="c-message">
          {d.message}
        </label>
        <textarea
          id="c-message"
          rows={6}
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          maxLength={5000}
          className="mt-2 w-full px-3 py-2.5 text-sm leading-relaxed"
          style={field}
        />
        <p className="mt-1.5 font-[family-name:var(--font-mono)] text-[11px] text-[color:var(--color-ink-muted)]">
          {message.trim().length}/5000
        </p>
      </div>

      {error && (
        <p className="mt-4 text-sm" style={{ color: "var(--color-status-closed)" }}>
          {error}
        </p>
      )}

      <button
        type="button"
        onClick={submit}
        disabled={!canSend || state === "sending"}
        className="mt-6 px-6 py-3.5 text-sm font-medium transition-opacity hover:opacity-90 disabled:opacity-40"
        style={{
          backgroundColor: "var(--color-accent)",
          color: "var(--color-paper)",
        }}
      >
        {state === "sending" ? d.sending : d.send}
      </button>
    </div>
  );
}

'@
Write-File 'components\ContactForm.tsx' $c16


Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
Write-Host "  npm run dev" -ForegroundColor Yellow
Write-Host "  http://localhost:3000/en" -ForegroundColor Yellow
Write-Host "  http://localhost:3000/fr" -ForegroundColor Yellow
