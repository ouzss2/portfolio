# ============================================================
#  Portfolio - admin panel
#  Run from project root:  .\setup-admin.ps1
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
Write-Host "Writing admin panel..." -ForegroundColor Cyan
Write-Host ""

$c0 = @'
"use client";

import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut as fbSignOut,
  type User,
} from "firebase/auth";
import { auth } from "./client";

/**
 * Admin authentication.
 *
 * Writes go straight from the browser to Firestore using the client SDK.
 * That is safe here because firestore.rules only permits writes from one
 * specific UID - the rules are the security boundary, not this component.
 * Hiding the UI from a signed-out visitor is convenience, not protection.
 */

interface AuthState {
  user: User | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthState>({
  user: null,
  loading: true,
  signIn: async () => {},
  signOut: async () => {},
});

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    return onAuthStateChanged(auth, (u) => {
      setUser(u);
      setLoading(false);
    });
  }, []);

  const signIn = async (email: string, password: string) => {
    await signInWithEmailAndPassword(auth, email, password);
  };

  const signOut = async () => {
    await fbSignOut(auth);
  };

  return (
    <AuthContext.Provider value={{ user, loading, signIn, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);

'@
Write-File 'lib\firebase\auth-context.tsx' $c0

$c1 = @'
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
Write-File 'app\admin\layout.tsx' $c1

$c2 = @'
"use client";

import { useState } from "react";
import { useAuth } from "@/lib/firebase/auth-context";

export default function Login() {
  const { signIn } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  const submit = async () => {
    setError("");
    setBusy(true);
    try {
      await signIn(email, password);
    } catch {
      // Deliberately vague - a precise error tells an attacker which half
      // of the credential pair was right.
      setError("Sign in failed. Check the email and password.");
    } finally {
      setBusy(false);
    }
  };

  return (
    <main className="flex min-h-screen items-center justify-center px-6">
      <div className="w-full max-w-sm">
        <h1
          className="font-[family-name:var(--font-display)] font-bold"
          style={{ fontSize: "2rem", letterSpacing: "-0.03em" }}
        >
          Admin
        </h1>

        <div className="mt-8 space-y-4">
          <div>
            <label className="eyebrow block" htmlFor="email">
              Email
            </label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && submit()}
              className="mt-2 w-full px-3 py-2.5 text-sm"
              style={{
                border: "1px solid var(--color-line)",
                backgroundColor: "var(--color-paper-raised)",
              }}
            />
          </div>

          <div>
            <label className="eyebrow block" htmlFor="password">
              Password
            </label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && submit()}
              className="mt-2 w-full px-3 py-2.5 text-sm"
              style={{
                border: "1px solid var(--color-line)",
                backgroundColor: "var(--color-paper-raised)",
              }}
            />
          </div>

          {error && (
            <p className="text-sm" style={{ color: "var(--color-status-closed)" }}>
              {error}
            </p>
          )}

          <button
            onClick={submit}
            disabled={busy || !email || !password}
            className="w-full px-5 py-3 text-sm font-medium disabled:opacity-45"
            style={{
              backgroundColor: "var(--color-accent)",
              color: "var(--color-paper)",
            }}
          >
            {busy ? "Signing in..." : "Sign in"}
          </button>
        </div>
      </div>
    </main>
  );
}

'@
Write-File 'app\admin\login\page.tsx' $c2

$c3 = @'
"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import {
  collection,
  getDocs,
  doc,
  updateDoc,
  orderBy,
  query,
} from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import type { Project } from "@/lib/types";

/**
 * Project list.
 *
 * Publishing is a one-click toggle, but the row shows how complete the
 * case study is first. Publishing a project whose narrative is still
 * TODO is the single easiest way to damage the site, so the count is
 * shown before the button rather than after.
 */

const CASE_FIELDS = [
  "context",
  "problem",
  "role",
  "technicalDecisions",
  "challenges",
  "result",
] as const;

function writtenCount(p: Project): number {
  return CASE_FIELDS.filter((f) => {
    const t = p.caseStudy?.[f]?.en?.trim() ?? "";
    return t.length > 0 && !t.startsWith("TODO");
  }).length;
}

export default function AdminHome() {
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState<string | null>(null);

  const load = async () => {
    const snap = await getDocs(
      query(collection(db, "projects"), orderBy("order", "asc"))
    );
    setProjects(
      snap.docs.map((d) => ({ id: d.id, ...d.data() }) as Project)
    );
    setLoading(false);
  };

  useEffect(() => {
    load();
  }, []);

  const togglePublish = async (p: Project) => {
    const next = p.status === "published" ? "draft" : "published";
    setBusy(p.id);
    await updateDoc(doc(db, "projects", p.id), {
      status: next,
      publishedAt: next === "published" ? new Date().toISOString() : null,
    });
    await fetch("/api/revalidate", { method: "POST" }).catch(() => {});
    await load();
    setBusy(null);
  };

  const move = async (index: number, dir: -1 | 1) => {
    const target = index + dir;
    if (target < 0 || target >= projects.length) return;
    const a = projects[index];
    const b = projects[target];
    setBusy(a.id);
    await Promise.all([
      updateDoc(doc(db, "projects", a.id), { order: b.order }),
      updateDoc(doc(db, "projects", b.id), { order: a.order }),
    ]);
    await load();
    setBusy(null);
  };

  if (loading) {
    return (
      <main className="mx-auto max-w-4xl px-6 py-12">
        <p className="font-[family-name:var(--font-mono)] text-sm text-[color:var(--color-ink-muted)]">
          Loading projects...
        </p>
      </main>
    );
  }

  return (
    <main className="mx-auto max-w-4xl px-6 py-12">
      <h1
        className="font-[family-name:var(--font-display)] font-bold"
        style={{ fontSize: "2rem", letterSpacing: "-0.03em" }}
      >
        Projects
      </h1>

      <p className="mt-3 max-w-lg text-sm text-[color:var(--color-ink-muted)]">
        A project needs a written narrative before it earns a place on the
        site. The count shows how many of the six case study sections are
        filled in.
      </p>

      <div className="mt-10">
        {projects.map((p, i) => {
          const written = writtenCount(p);
          const ready = written >= 4;
          const isPublished = p.status === "published";

          return (
            <div
              key={p.id}
              className="rule flex flex-wrap items-center gap-x-5 gap-y-3 py-4"
            >
              <div className="flex flex-col gap-0.5">
                <button
                  onClick={() => move(i, -1)}
                  disabled={i === 0 || busy !== null}
                  className="px-1.5 text-xs disabled:opacity-25"
                  aria-label="Move up"
                >
                  UP
                </button>
                <button
                  onClick={() => move(i, 1)}
                  disabled={i === projects.length - 1 || busy !== null}
                  className="px-1.5 text-xs disabled:opacity-25"
                  aria-label="Move down"
                >
                  DN
                </button>
              </div>

              <div className="min-w-0 flex-1">
                <Link
                  href={`/admin/projects/${p.id}`}
                  className="font-medium hover:opacity-70"
                >
                  {p.title.en}
                </Link>
                <p className="mt-1 font-[family-name:var(--font-mono)] text-xs text-[color:var(--color-ink-muted)]">
                  {written}/6 sections
                  {p.featured ? " - featured" : ""}
                  {p.coverImageUrl ? "" : " - no media"}
                </p>
              </div>

              <span
                className="font-[family-name:var(--font-mono)] text-xs"
                style={{
                  color: isPublished
                    ? "var(--color-status-available)"
                    : "var(--color-ink-muted)",
                }}
              >
                {isPublished ? "published" : "draft"}
              </span>

              <button
                onClick={() => togglePublish(p)}
                disabled={busy !== null || (!isPublished && !ready)}
                title={
                  !isPublished && !ready
                    ? "Write at least four case study sections first"
                    : ""
                }
                className="border px-3 py-1.5 text-xs disabled:opacity-35"
                style={{ borderColor: "var(--color-ink)" }}
              >
                {busy === p.id
                  ? "..."
                  : isPublished
                    ? "Unpublish"
                    : "Publish"}
              </button>

              <Link
                href={`/admin/projects/${p.id}`}
                className="link-underline text-xs"
              >
                Edit
              </Link>
            </div>
          );
        })}
      </div>
    </main>
  );
}

'@
Write-File 'app\admin\page.tsx' $c3

$c4 = @'
"use client";

import { useEffect, useState, use } from "react";
import { useRouter } from "next/navigation";
import { doc, getDoc, updateDoc, collection, getDocs } from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import type { Project, Skill, Localized } from "@/lib/types";

/**
 * Project editor.
 *
 * English and French sit side by side on every field rather than behind a
 * language tab. Translating while the source sentence is visible produces
 * better French than translating from memory later, and a missing
 * translation is obvious instead of hidden one click away.
 */

const CASE_SECTIONS = [
  { key: "context", label: "Context", hint: "What was this, who was it for, when?" },
  { key: "problem", label: "The problem", hint: "What was actually hard or unsolved?" },
  { key: "role", label: "My role", hint: "What did you personally build?" },
  {
    key: "technicalDecisions",
    label: "Technical decisions",
    hint: "One real decision and the trade-off it cost. This is the section engineers read.",
  },
  { key: "challenges", label: "Challenges", hint: "What went wrong and how you handled it." },
  { key: "result", label: "Result", hint: "What changed. A number if you have one." },
] as const;

function Bilingual({
  label,
  hint,
  value,
  onChange,
  rows = 4,
}: {
  label: string;
  hint?: string;
  value: Localized;
  onChange: (v: Localized) => void;
  rows?: number;
}) {
  const isTodo = (t: string) => t.trim().startsWith("TODO") || t.trim().startsWith("A REDIGER");

  return (
    <div className="rule pt-6">
      <label className="eyebrow">{label}</label>
      {hint && (
        <p className="mt-1.5 text-xs text-[color:var(--color-ink-muted)]">{hint}</p>
      )}

      <div className="mt-3 grid gap-4 md:grid-cols-2">
        {(["en", "fr"] as const).map((lang) => (
          <div key={lang}>
            <span className="font-[family-name:var(--font-mono)] text-[10px] uppercase tracking-[0.12em] text-[color:var(--color-ink-muted)]">
              {lang}
            </span>
            <textarea
              rows={rows}
              value={value[lang]}
              onChange={(e) => onChange({ ...value, [lang]: e.target.value })}
              className="mt-1.5 w-full px-3 py-2 text-sm leading-relaxed"
              style={{
                border: `1px solid ${
                  isTodo(value[lang])
                    ? "var(--color-status-open)"
                    : "var(--color-line)"
                }`,
                backgroundColor: "var(--color-paper-raised)",
              }}
            />
          </div>
        ))}
      </div>
    </div>
  );
}

export default function ProjectEditor({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = use(params);
  const router = useRouter();
  const [project, setProject] = useState<Project | null>(null);
  const [skills, setSkills] = useState<Skill[]>([]);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    (async () => {
      const [snap, skillSnap] = await Promise.all([
        getDoc(doc(db, "projects", id)),
        getDocs(collection(db, "skills")),
      ]);
      if (snap.exists()) {
        setProject({ id: snap.id, ...snap.data() } as Project);
      }
      setSkills(
        skillSnap.docs.map((d) => ({ id: d.id, ...d.data() }) as Skill)
      );
    })();
  }, [id]);

  const save = async () => {
    if (!project) return;
    setSaving(true);
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { id: _drop, ...data } = project;
    await updateDoc(doc(db, "projects", id), data);
    await fetch("/api/revalidate", { method: "POST" }).catch(() => {});
    setSaving(false);
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  if (!project) {
    return (
      <main className="mx-auto max-w-4xl px-6 py-12">
        <p className="font-[family-name:var(--font-mono)] text-sm text-[color:var(--color-ink-muted)]">
          Loading...
        </p>
      </main>
    );
  }

  const set = <K extends keyof Project>(key: K, value: Project[K]) =>
    setProject({ ...project, [key]: value });

  const setCase = (key: string, value: Localized) =>
    setProject({
      ...project,
      caseStudy: { ...project.caseStudy, [key]: value },
    });

  const toggleSkill = (skillId: string) =>
    set(
      "skillIds",
      project.skillIds.includes(skillId)
        ? project.skillIds.filter((s) => s !== skillId)
        : [...project.skillIds, skillId]
    );

  return (
    <main className="mx-auto max-w-4xl px-6 py-12 pb-32">
      <button onClick={() => router.push("/admin")} className="link-underline text-sm">
        Back
      </button>

      <h1
        className="mt-8 font-[family-name:var(--font-display)] font-bold"
        style={{ fontSize: "2rem", letterSpacing: "-0.03em" }}
      >
        {project.title.en}
      </h1>

      <div className="mt-10 space-y-2">
        <Bilingual
          label="Title"
          value={project.title}
          onChange={(v) => set("title", v)}
          rows={1}
        />

        <Bilingual
          label="Summary"
          hint="Two sentences. This is what appears on the home page."
          value={project.summary}
          onChange={(v) => set("summary", v)}
          rows={3}
        />

        {CASE_SECTIONS.map((s) => (
          <Bilingual
            key={s.key}
            label={s.label}
            hint={s.hint}
            value={project.caseStudy[s.key]}
            onChange={(v) => setCase(s.key, v)}
          />
        ))}
      </div>

      {/* --- meta ------------------------------------------------- */}
      <div className="rule mt-8 pt-6">
        <label className="eyebrow">Cover image URL</label>
        <input
          value={project.coverImageUrl}
          onChange={(e) => set("coverImageUrl", e.target.value)}
          placeholder="https://res.cloudinary.com/..."
          className="mt-2 w-full px-3 py-2 text-sm"
          style={{
            border: "1px solid var(--color-line)",
            backgroundColor: "var(--color-paper-raised)",
          }}
        />
      </div>

      <div className="rule mt-6 pt-6">
        <label className="eyebrow">Links</label>
        <div className="mt-3 grid gap-3 sm:grid-cols-2">
          {(["appStore", "playStore", "github", "demo"] as const).map((k) => (
            <div key={k}>
              <span className="font-[family-name:var(--font-mono)] text-[10px] uppercase tracking-[0.12em] text-[color:var(--color-ink-muted)]">
                {k}
              </span>
              <input
                value={project.links[k] ?? ""}
                onChange={(e) =>
                  set("links", { ...project.links, [k]: e.target.value })
                }
                className="mt-1 w-full px-3 py-2 text-sm"
                style={{
                  border: "1px solid var(--color-line)",
                  backgroundColor: "var(--color-paper-raised)",
                }}
              />
            </div>
          ))}
        </div>
      </div>

      <div className="rule mt-6 pt-6">
        <label className="eyebrow">Stack</label>
        <div className="mt-3 flex flex-wrap gap-2">
          {skills.map((s) => {
            const on = project.skillIds.includes(s.id);
            return (
              <button
                key={s.id}
                onClick={() => toggleSkill(s.id)}
                className="border px-2.5 py-1 text-xs transition-colors"
                style={{
                  borderColor: on ? "var(--color-ink)" : "var(--color-line)",
                  backgroundColor: on ? "var(--color-ink)" : "transparent",
                  color: on ? "var(--color-paper)" : "var(--color-ink-muted)",
                }}
              >
                {s.name}
              </button>
            );
          })}
        </div>
      </div>

      <div className="rule mt-6 flex flex-wrap items-center gap-6 pt-6">
        <label className="flex items-center gap-2 text-sm">
          <input
            type="checkbox"
            checked={project.featured}
            onChange={(e) => set("featured", e.target.checked)}
          />
          Featured on home page
        </label>

        <span className="font-[family-name:var(--font-mono)] text-xs text-[color:var(--color-ink-muted)]">
          status: {project.status}
        </span>
      </div>

      {/* --- save bar --------------------------------------------- */}
      <div
        className="fixed bottom-0 left-0 right-0 flex items-center justify-end gap-4 px-6 py-4"
        style={{
          backgroundColor: "var(--color-paper)",
          borderTop: "1px solid var(--color-line)",
        }}
      >
        {saved && (
          <span
            className="font-[family-name:var(--font-mono)] text-xs"
            style={{ color: "var(--color-status-available)" }}
          >
            Saved
          </span>
        )}
        <button
          onClick={save}
          disabled={saving}
          className="px-6 py-2.5 text-sm font-medium disabled:opacity-45"
          style={{
            backgroundColor: "var(--color-accent)",
            color: "var(--color-paper)",
          }}
        >
          {saving ? "Saving..." : "Save"}
        </button>
      </div>
    </main>
  );
}

'@
Write-File 'app\admin\projects\[id]\page.tsx' $c4

$c5 = @'
import { revalidatePath } from "next/cache";
import { NextResponse } from "next/server";

/**
 * On-demand revalidation.
 *
 * Public pages are statically generated with a one hour window. Without
 * this, an edit in the admin would not appear on the site until that
 * window expired. The admin calls this after every save so the change is
 * live immediately.
 */

export async function POST() {
  revalidatePath("/", "layout");
  return NextResponse.json({ revalidated: true, at: Date.now() });
}

'@
Write-File 'app\api\revalidate\route.ts' $c5


Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
Write-Host "  npm run dev" -ForegroundColor Yellow
Write-Host "  http://localhost:3000/admin" -ForegroundColor Yellow
