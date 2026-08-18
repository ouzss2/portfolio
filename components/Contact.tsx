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
