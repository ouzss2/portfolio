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
