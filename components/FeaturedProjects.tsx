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
