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
