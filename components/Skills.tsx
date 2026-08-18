"use client";

import { useState } from "react";
import type { Skill, SkillCategory, Certification, Project } from "@/lib/types";

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
}: {
  groups: Array<{ category: SkillCategory; skills: Skill[] }>;
  certifications: Certification[];
  projects?: Project[];
}) {
  const [hovered, setHovered] = useState<string | null>(null);

  const proofFor = (skillId: string) =>
    projects.filter((p) => p.skillIds.includes(skillId));

  return (
    <section className="mx-auto max-w-5xl px-6 py-28">
      <div className="rule pt-8">
        <p className="eyebrow">Stack</p>
      </div>

      <p className="mt-6 max-w-lg text-[color:var(--color-ink-muted)]">
        Levels run 1 to 5, where 3 is production comfortable and 5 means I
        teach it. Rated honestly, because an inflated number gets caught in
        the first technical round.
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
                        {proof.map((p) => p.title.en).join(" / ")}
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
