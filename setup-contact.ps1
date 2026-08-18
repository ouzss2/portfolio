# ============================================================
#  Portfolio - contact form + admin inbox
#  Run from project root:  .\setup-contact.ps1
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
Write-Host "Writing contact form and inbox..." -ForegroundColor Cyan
Write-Host ""

$c0 = @'
"use client";

import { useState } from "react";
import { collection, addDoc } from "firebase/firestore";
import { db } from "@/lib/firebase/client";

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

const SUBJECTS = [
  { value: "job", label: "A role" },
  { value: "freelance", label: "Freelance work" },
  { value: "training", label: "Training" },
  { value: "other", label: "Something else" },
] as const;

type State = "idle" | "sending" | "sent" | "error";

export default function ContactForm() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [company, setCompany] = useState("");
  const [subjectType, setSubjectType] =
    useState<(typeof SUBJECTS)[number]["value"]>("job");
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
      setError(
        "That did not send. Email me directly at oussemamansouri4@gmail.com."
      );
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
          Message received.
        </p>
        <p className="mt-3 text-[color:var(--color-ink-muted)]">
          I reply within two working days. If it is urgent, email me directly
          at oussemamansouri4@gmail.com.
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
            Name
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
            Email
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
          Company <span style={{ textTransform: "none" }}>(optional)</span>
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
        <legend className="eyebrow">About</legend>
        <div className="mt-3 flex flex-wrap gap-2">
          {SUBJECTS.map((s) => {
            const on = subjectType === s.value;
            return (
              <button
                key={s.value}
                type="button"
                onClick={() => setSubjectType(s.value)}
                aria-pressed={on}
                className="border px-3 py-1.5 text-sm transition-colors"
                style={{
                  borderColor: on ? "var(--color-ink)" : "var(--color-line)",
                  backgroundColor: on ? "var(--color-ink)" : "transparent",
                  color: on ? "var(--color-paper)" : "var(--color-ink-muted)",
                }}
              >
                {s.label}
              </button>
            );
          })}
        </div>
      </fieldset>

      <div className="mt-6">
        <label className="eyebrow block" htmlFor="c-message">
          Message
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
        {state === "sending" ? "Sending..." : "Send message"}
      </button>
    </div>
  );
}

'@
Write-File 'components\ContactForm.tsx' $c0

$c1 = @'
import type { Profile } from "@/lib/types";
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
    <section id="contact" className="mx-auto max-w-5xl px-6 pb-32 pt-28">
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

      <ContactForm />

      {profile.cvUrls.en && (
        <div className="mt-8">
          <a
            href={profile.cvUrls.en}
            className="border px-6 py-3.5 text-sm font-medium transition-colors hover:bg-[color:var(--color-paper-raised)]"
            style={{ borderColor: "var(--color-ink)" }}
          >
            Download CV
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
        Built with Next.js and Firestore. Content managed from a custom admin
        and an iOS companion app.
      </p>
    </section>
  );
}

'@
Write-File 'components\Contact.tsx' $c1

$c2 = @'
"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import {
  collection,
  getDocs,
  doc,
  updateDoc,
  deleteDoc,
  query,
  orderBy,
} from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import type { ContactMessage } from "@/lib/types";

/**
 * Inbox.
 *
 * Only this UID can read the messages collection - the public side is
 * write-only. Opening a message marks it read; replying opens the mail
 * client with the address and a subject already filled in, because the
 * point is to answer quickly, not to build an email client.
 */

const SUBJECT_LABEL: Record<string, string> = {
  job: "A role",
  freelance: "Freelance",
  training: "Training",
  other: "Other",
};

export default function Inbox() {
  const [messages, setMessages] = useState<ContactMessage[]>([]);
  const [loading, setLoading] = useState(true);
  const [open, setOpen] = useState<string | null>(null);

  const load = async () => {
    const snap = await getDocs(
      query(collection(db, "messages"), orderBy("createdAt", "desc"))
    );
    setMessages(
      snap.docs.map((d) => ({ id: d.id, ...d.data() }) as ContactMessage)
    );
    setLoading(false);
  };

  useEffect(() => {
    load();
  }, []);

  const openMessage = async (m: ContactMessage) => {
    setOpen(open === m.id ? null : m.id);
    if (m.status === "unread") {
      await updateDoc(doc(db, "messages", m.id), { status: "read" });
      setMessages((prev) =>
        prev.map((x) => (x.id === m.id ? { ...x, status: "read" } : x))
      );
    }
  };

  const remove = async (id: string) => {
    await deleteDoc(doc(db, "messages", id));
    setMessages((prev) => prev.filter((m) => m.id !== id));
  };

  const unread = messages.filter((m) => m.status === "unread").length;

  if (loading) {
    return (
      <main className="mx-auto max-w-3xl px-6 py-12">
        <p className="font-[family-name:var(--font-mono)] text-sm text-[color:var(--color-ink-muted)]">
          Loading...
        </p>
      </main>
    );
  }

  return (
    <main className="mx-auto max-w-3xl px-6 py-12">
      <Link href="/admin" className="link-underline text-sm">
        Projects
      </Link>

      <h1
        className="mt-8 font-[family-name:var(--font-display)] font-bold"
        style={{ fontSize: "2rem", letterSpacing: "-0.03em" }}
      >
        Inbox
      </h1>

      <p className="mt-2 font-[family-name:var(--font-mono)] text-xs text-[color:var(--color-ink-muted)]">
        {messages.length} total, {unread} unread
      </p>

      {messages.length === 0 ? (
        <p className="mt-10 text-[color:var(--color-ink-muted)]">
          Nothing yet.
        </p>
      ) : (
        <div className="mt-10">
          {messages.map((m) => {
            const isOpen = open === m.id;
            return (
              <div key={m.id} className="rule py-4">
                <button
                  onClick={() => openMessage(m)}
                  className="flex w-full items-baseline justify-between gap-4 text-left"
                >
                  <span className="min-w-0 flex-1">
                    <span className="flex items-center gap-2">
                      {m.status === "unread" && (
                        <span
                          aria-hidden
                          className="inline-block h-1.5 w-1.5 rounded-full"
                          style={{ backgroundColor: "var(--color-accent)" }}
                        />
                      )}
                      <span
                        className={
                          m.status === "unread" ? "font-semibold" : "font-normal"
                        }
                      >
                        {m.name}
                      </span>
                      {m.company && (
                        <span className="text-sm text-[color:var(--color-ink-muted)]">
                          {m.company}
                        </span>
                      )}
                    </span>
                    <span className="mt-1 block truncate text-sm text-[color:var(--color-ink-muted)]">
                      {m.message.slice(0, 90)}
                    </span>
                  </span>

                  <span className="shrink-0 text-right">
                    <span className="eyebrow block">
                      {SUBJECT_LABEL[m.subjectType] ?? m.subjectType}
                    </span>
                    <span className="mt-1 block font-[family-name:var(--font-mono)] text-[11px] text-[color:var(--color-ink-muted)]">
                      {new Date(m.createdAt).toLocaleDateString()}
                    </span>
                  </span>
                </button>

                {isOpen && (
                  <div className="mt-5 pl-4" style={{ borderLeft: "1px solid var(--color-line)" }}>
                    <p className="whitespace-pre-wrap text-sm leading-relaxed">
                      {m.message}
                    </p>
                    <div className="mt-5 flex flex-wrap gap-5">
                      <a
                        href={`mailto:${m.email}?subject=Re: your message`}
                        className="link-underline text-sm"
                      >
                        Reply to {m.email}
                      </a>
                      <button
                        onClick={() => remove(m.id)}
                        className="text-sm"
                        style={{ color: "var(--color-status-closed)" }}
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </main>
  );
}

'@
Write-File 'app\admin\messages\page.tsx' $c2

$c3 = @'
"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect } from "react";
import { AuthProvider, useAuth } from "@/lib/firebase/auth-context";

/**
 * Admin shell.
 *
 * Deliberately plain. This is a tool, not a portfolio piece - the visual
 * effort belongs on the public site, and every minute spent styling the
 * admin is a minute not spent writing case studies.
 */

function Shell({ children }: { children: React.ReactNode }) {
  const { user, loading, signOut } = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const isLogin = pathname === "/admin/login";

  useEffect(() => {
    if (!loading && !user && !isLogin) router.replace("/admin/login");
    if (!loading && user && isLogin) router.replace("/admin");
  }, [user, loading, isLogin, router]);

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <p className="font-[family-name:var(--font-mono)] text-sm text-[color:var(--color-ink-muted)]">
          Loading...
        </p>
      </div>
    );
  }

  if (isLogin) return <>{children}</>;
  if (!user) return null;

  return (
    <div className="min-h-screen">
      <header
        className="sticky top-0 z-10 flex items-center justify-between px-6 py-4"
        style={{
          backgroundColor: "var(--color-paper)",
          borderBottom: "1px solid var(--color-line)",
        }}
      >
        <nav className="flex items-center gap-6">
          <Link href="/admin" className="font-[family-name:var(--font-mono)] text-sm">
            Admin
          </Link>
          <Link href="/admin/messages" className="link-underline text-sm">
            Inbox
          </Link>
          <Link href="/" className="link-underline text-sm" target="_blank">
            View site
          </Link>
        </nav>

        <div className="flex items-center gap-5">
          <span className="font-[family-name:var(--font-mono)] text-xs text-[color:var(--color-ink-muted)]">
            {user.email}
          </span>
          <button onClick={() => signOut()} className="link-underline text-sm">
            Sign out
          </button>
        </div>
      </header>

      {children}
    </div>
  );
}

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <AuthProvider>
      <Shell>{children}</Shell>
    </AuthProvider>
  );
}

'@
Write-File 'app\admin\layout.tsx' $c3


Write-Host ""
Write-Host "Done. Run: npm run dev" -ForegroundColor Cyan
