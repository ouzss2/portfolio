import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
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

      <h1
        className="mt-10 font-[family-name:var(--font-display)] font-bold"
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
