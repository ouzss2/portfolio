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
