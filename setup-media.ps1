# ============================================================
#  Portfolio - media upload + profile settings
#  Run from project root:  .\setup-media.ps1
#
#  Requires three new environment variables - see the note the
#  script prints when it finishes.
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
Write-Host "Writing media upload..." -ForegroundColor Cyan
Write-Host ""

$c0 = @'
import { NextResponse } from "next/server";
import crypto from "crypto";
import { adminAuth } from "@/lib/firebase/admin";

/**
 * Cloudinary upload signature.
 *
 * The browser uploads the file straight to Cloudinary, but only after
 * this route signs the request. That keeps the API secret on the server
 * while avoiding proxying large video files through Vercel, which has a
 * request body limit that app recordings would exceed.
 *
 * The caller must present a valid Firebase ID token belonging to the
 * owner UID. Without that check, an unsigned preset would let anyone who
 * found the cloud name fill the account with files.
 */

export async function POST(request: Request) {
  const secret = process.env.CLOUDINARY_API_SECRET;
  const apiKey = process.env.CLOUDINARY_API_KEY;
  const ownerUid = process.env.ADMIN_UID;

  if (!secret || !apiKey || !ownerUid) {
    return NextResponse.json(
      { error: "Cloudinary or admin environment variables are missing" },
      { status: 500 }
    );
  }

  // --- authenticate ------------------------------------------------
  const header = request.headers.get("authorization") ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) {
    return NextResponse.json({ error: "Not signed in" }, { status: 401 });
  }

  try {
    const decoded = await adminAuth.verifyIdToken(token);
    if (decoded.uid !== ownerUid) {
      return NextResponse.json({ error: "Not permitted" }, { status: 403 });
    }
  } catch {
    return NextResponse.json({ error: "Invalid session" }, { status: 401 });
  }

  // --- sign --------------------------------------------------------
  const body = (await request.json().catch(() => ({}))) as {
    folder?: string;
  };
  const folder = body.folder ?? "portfolio";
  const timestamp = Math.round(Date.now() / 1000);

  // Cloudinary signs the alphabetically sorted parameter string.
  const toSign = `folder=${folder}&timestamp=${timestamp}`;
  const signature = crypto
    .createHash("sha1")
    .update(toSign + secret)
    .digest("hex");

  return NextResponse.json({
    signature,
    timestamp,
    folder,
    apiKey,
    cloudName: process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME,
  });
}

'@
Write-File 'app\api\cloudinary\sign\route.ts' $c0

$c1 = @'
"use client";

import { useState, useRef } from "react";
import { auth } from "@/lib/firebase/client";

/**
 * Media upload.
 *
 * Files go from the browser straight to Cloudinary using a signature
 * this app issues, so large video never passes through Vercel.
 *
 * Cloudinary transcodes on delivery: q_auto picks a quality the file can
 * survive, f_auto serves webm or mp4 depending on the browser. A raw
 * phone recording is often 60 MB and unusable on the page; the delivered
 * version is a fraction of that.
 */

type Kind = "image" | "video";

export default function MediaUpload({
  folder = "portfolio",
  accept = "image",
  onUploaded,
}: {
  folder?: string;
  accept?: Kind | "both";
  onUploaded: (url: string, kind: Kind) => void;
}) {
  const [busy, setBusy] = useState(false);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState("");
  const input = useRef<HTMLInputElement>(null);

  const acceptAttr =
    accept === "image" ? "image/*" : accept === "video" ? "video/*" : "image/*,video/*";

  const upload = async (file: File) => {
    setError("");
    setBusy(true);
    setProgress(0);

    try {
      const token = await auth.currentUser?.getIdToken();
      if (!token) throw new Error("Not signed in");

      const signRes = await fetch("/api/cloudinary/sign", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ folder }),
      });
      if (!signRes.ok) throw new Error((await signRes.json()).error ?? "Sign failed");

      const { signature, timestamp, apiKey, cloudName } = await signRes.json();
      const isVideo = file.type.startsWith("video");

      const form = new FormData();
      form.append("file", file);
      form.append("api_key", apiKey);
      form.append("timestamp", String(timestamp));
      form.append("signature", signature);
      form.append("folder", folder);

      const url = `https://api.cloudinary.com/v1_1/${cloudName}/${
        isVideo ? "video" : "image"
      }/upload`;

      // XHR rather than fetch, because fetch cannot report upload progress
      // and a 60 MB recording with no feedback looks like a hang.
      const secureUrl: string = await new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.open("POST", url);
        xhr.upload.onprogress = (e) => {
          if (e.lengthComputable) setProgress(Math.round((e.loaded / e.total) * 100));
        };
        xhr.onload = () => {
          if (xhr.status >= 200 && xhr.status < 300) {
            resolve(JSON.parse(xhr.responseText).secure_url);
          } else {
            reject(new Error("Upload rejected by Cloudinary"));
          }
        };
        xhr.onerror = () => reject(new Error("Network error during upload"));
        xhr.send(form);
      });

      // Insert delivery transformations into the URL so the page never
      // serves the original file.
      const optimised = secureUrl.replace(
        "/upload/",
        isVideo ? "/upload/q_auto,f_auto,w_900/" : "/upload/q_auto,f_auto,w_1400/"
      );

      onUploaded(optimised, isVideo ? "video" : "image");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Upload failed");
    } finally {
      setBusy(false);
      setProgress(0);
      if (input.current) input.current.value = "";
    }
  };

  return (
    <div>
      <input
        ref={input}
        type="file"
        accept={acceptAttr}
        disabled={busy}
        onChange={(e) => {
          const f = e.target.files?.[0];
          if (f) upload(f);
        }}
        className="block w-full text-xs file:mr-3 file:border file:px-3 file:py-1.5 file:text-xs"
      />

      {busy && (
        <div className="mt-2">
          <div
            className="h-0.5 w-full"
            style={{ backgroundColor: "var(--color-line)" }}
          >
            <div
              className="h-0.5 transition-all"
              style={{
                width: `${progress}%`,
                backgroundColor: "var(--color-accent)",
              }}
            />
          </div>
          <p className="mt-1 font-[family-name:var(--font-mono)] text-[11px] text-[color:var(--color-ink-muted)]">
            {progress}%
          </p>
        </div>
      )}

      {error && (
        <p className="mt-2 text-xs" style={{ color: "var(--color-status-closed)" }}>
          {error}
        </p>
      )}
    </div>
  );
}

'@
Write-File 'components\admin\MediaUpload.tsx' $c1

$c2 = @'
"use client";

import { useEffect, useState, use } from "react";
import { useRouter } from "next/navigation";
import { doc, getDoc, updateDoc, collection, getDocs } from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import type { Project, Skill, Localized, MediaItem } from "@/lib/types";
import MediaUpload from "@/components/admin/MediaUpload";

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
      {/* --- cover ------------------------------------------------ */}
      <div className="rule mt-8 pt-6">
        <label className="eyebrow">Cover</label>
        <p className="mt-1.5 text-xs text-[color:var(--color-ink-muted)]">
          Shown on the home page and in the pinned device. A still frame from
          the app beats a logo.
        </p>

        {project.coverImageUrl && (
          <div className="mt-3 flex items-start gap-4">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={project.coverImageUrl}
              alt=""
              className="h-28 w-28 object-cover"
              style={{ border: "1px solid var(--color-line)" }}
            />
            <button
              onClick={() => set("coverImageUrl", "")}
              className="text-xs"
              style={{ color: "var(--color-status-closed)" }}
            >
              Remove
            </button>
          </div>
        )}

        <div className="mt-3">
          <MediaUpload
            label={project.coverImageUrl ? "Replace cover" : "Upload cover"}
            accept="image/*"
            onUploaded={(url) => set("coverImageUrl", url)}
          />
        </div>
      </div>

      {/* --- gallery ---------------------------------------------- */}
      <div className="rule mt-6 pt-6">
        <label className="eyebrow">Media</label>
        <p className="mt-1.5 text-xs text-[color:var(--color-ink-muted)]">
          Screenshots and screen recordings. A 15 second video of the app
          running is worth more than five static screens.
        </p>

        {project.media.length > 0 && (
          <div className="mt-4 space-y-3">
            {project.media.map((m, i) => (
              <div key={i} className="flex items-start gap-4">
                {m.type === "video" ? (
                  <video
                    src={m.url}
                    muted
                    loop
                    className="h-24 w-24 object-cover"
                    style={{ border: "1px solid var(--color-line)" }}
                  />
                ) : (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={m.url}
                    alt=""
                    className="h-24 w-24 object-cover"
                    style={{ border: "1px solid var(--color-line)" }}
                  />
                )}

                <div className="flex-1 space-y-2">
                  {(["en", "fr"] as const).map((lang) => (
                    <input
                      key={lang}
                      value={m.caption[lang]}
                      placeholder={`Caption (${lang})`}
                      onChange={(e) => {
                        const next = [...project.media];
                        next[i] = {
                          ...m,
                          caption: { ...m.caption, [lang]: e.target.value },
                        };
                        set("media", next);
                      }}
                      className="w-full px-3 py-1.5 text-sm"
                      style={{
                        border: "1px solid var(--color-line)",
                        backgroundColor: "var(--color-paper-raised)",
                      }}
                    />
                  ))}
                </div>

                <button
                  onClick={() =>
                    set(
                      "media",
                      project.media.filter((_, x) => x !== i)
                    )
                  }
                  className="text-xs"
                  style={{ color: "var(--color-status-closed)" }}
                >
                  Remove
                </button>
              </div>
            ))}
          </div>
        )}

        <div className="mt-4">
          <MediaUpload
            label="Add screenshot or recording"
            onUploaded={(url, type) => {
              const item: MediaItem = {
                url,
                type,
                caption: { en: "", fr: "" },
              };
              set("media", [...project.media, item]);
            }}
          />
        </div>
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
Write-File 'app\(admin)\admin\projects\[id]\page.tsx' $c2

$c3 = @'
"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { doc, getDoc, setDoc } from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import MediaUpload from "@/components/admin/MediaUpload";
import type { Profile, AvailabilityStatus } from "@/lib/types";

/**
 * Profile and settings.
 *
 * These fields are small but several of them are currently empty and each
 * one is a visible hole on the public site: no photo, no LinkedIn, no
 * GitHub, no CV to download. The contact section renders links only when
 * they exist, so filling these in makes them appear.
 */

const AVAILABILITY: Array<{ value: AvailabilityStatus; label: string }> = [
  { value: "available", label: "Available for work" },
  { value: "open", label: "Open to offers" },
  { value: "unavailable", label: "Not available" },
];

export default function Settings() {
  const [profile, setProfile] = useState<Profile | null>(null);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    (async () => {
      const snap = await getDoc(doc(db, "settings", "profile"));
      if (snap.exists()) setProfile(snap.data() as Profile);
    })();
  }, []);

  const save = async () => {
    if (!profile) return;
    setSaving(true);
    await setDoc(doc(db, "settings", "profile"), {
      ...profile,
      updatedAt: new Date().toISOString(),
    });
    await fetch("/api/revalidate", { method: "POST" }).catch(() => {});
    setSaving(false);
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  if (!profile) {
    return (
      <main className="mx-auto max-w-3xl px-6 py-12">
        <p className="font-[family-name:var(--font-mono)] text-sm text-[color:var(--color-ink-muted)]">
          Loading...
        </p>
      </main>
    );
  }

  const set = <K extends keyof Profile>(k: K, v: Profile[K]) =>
    setProfile({ ...profile, [k]: v });

  const field: React.CSSProperties = {
    border: "1px solid var(--color-line)",
    backgroundColor: "var(--color-paper-raised)",
  };

  const Text = ({
    label,
    value,
    onChange,
    placeholder,
  }: {
    label: string;
    value: string;
    onChange: (v: string) => void;
    placeholder?: string;
  }) => (
    <div>
      <label className="eyebrow block">{label}</label>
      <input
        value={value}
        placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
        className="mt-2 w-full px-3 py-2 text-sm"
        style={field}
      />
    </div>
  );

  return (
    <main className="mx-auto max-w-3xl px-6 py-12 pb-32">
      <Link href="/admin" className="link-underline text-sm">
        Projects
      </Link>

      <h1
        className="mt-8 font-[family-name:var(--font-display)] font-bold"
        style={{ fontSize: "2rem", letterSpacing: "-0.03em" }}
      >
        Profile
      </h1>

      {/* --- availability -------------------------------------- */}
      <div className="rule mt-10 pt-6">
        <label className="eyebrow">Availability</label>
        <p className="mt-1.5 text-xs text-[color:var(--color-ink-muted)]">
          Appears beside your name in the hero. Keep it current - a stale
          badge is worse than none.
        </p>
        <div className="mt-3 flex flex-wrap gap-2">
          {AVAILABILITY.map((a) => {
            const on = profile.availabilityStatus === a.value;
            return (
              <button
                key={a.value}
                onClick={() => set("availabilityStatus", a.value)}
                className="border px-3 py-1.5 text-sm"
                style={{
                  borderColor: on ? "var(--color-ink)" : "var(--color-line)",
                  backgroundColor: on ? "var(--color-ink)" : "transparent",
                  color: on ? "var(--color-paper)" : "var(--color-ink-muted)",
                }}
              >
                {a.label}
              </button>
            );
          })}
        </div>
      </div>

      {/* --- photo --------------------------------------------- */}
      <div className="rule mt-6 pt-6">
        <label className="eyebrow">Photo</label>
        {profile.photoUrl && (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={profile.photoUrl}
            alt=""
            className="mt-3 h-28 w-28 object-cover"
            style={{ border: "1px solid var(--color-line)" }}
          />
        )}
        <div className="mt-3">
          <MediaUpload
            folder="portfolio/profile"
            accept="image"
            onUploaded={(url) => set("photoUrl", url)}
          />
        </div>
      </div>

      {/* --- CV ------------------------------------------------- */}
      <div className="rule mt-6 pt-6">
        <label className="eyebrow">CV</label>
        <p className="mt-1.5 text-xs text-[color:var(--color-ink-muted)]">
          The download button only appears on the site once a file exists.
          Upload the PDF for each language.
        </p>
        <div className="mt-3 grid gap-4 sm:grid-cols-2">
          {(["en", "fr"] as const).map((lang) => (
            <div key={lang}>
              <span className="font-[family-name:var(--font-mono)] text-[10px] uppercase tracking-[0.12em] text-[color:var(--color-ink-muted)]">
                {lang}
              </span>
              {profile.cvUrls[lang] && (
                <a
                  href={profile.cvUrls[lang]}
                  target="_blank"
                  rel="noreferrer"
                  className="link-underline mt-1 block text-xs"
                >
                  Current file
                </a>
              )}
              <div className="mt-2">
                <MediaUpload
                  folder="portfolio/cv"
                  accept="both"
                  onUploaded={(url) =>
                    set("cvUrls", { ...profile.cvUrls, [lang]: url })
                  }
                />
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* --- links --------------------------------------------- */}
      <div className="rule mt-6 space-y-4 pt-6">
        <Text
          label="LinkedIn"
          value={profile.linkedinUrl}
          onChange={(v) => set("linkedinUrl", v)}
          placeholder="https://www.linkedin.com/in/..."
        />
        <Text
          label="GitHub"
          value={profile.githubUrl}
          onChange={(v) => set("githubUrl", v)}
          placeholder="https://github.com/..."
        />
        <Text label="Email" value={profile.email} onChange={(v) => set("email", v)} />
        <Text label="Phone" value={profile.phone} onChange={(v) => set("phone", v)} />
        <Text
          label="Location"
          value={profile.location}
          onChange={(v) => set("location", v)}
        />
      </div>

      {/* --- bio ------------------------------------------------ */}
      <div className="rule mt-6 pt-6">
        <label className="eyebrow">Bio</label>
        <div className="mt-3 grid gap-4 md:grid-cols-2">
          {(["en", "fr"] as const).map((lang) => (
            <div key={lang}>
              <span className="font-[family-name:var(--font-mono)] text-[10px] uppercase tracking-[0.12em] text-[color:var(--color-ink-muted)]">
                {lang}
              </span>
              <textarea
                rows={6}
                value={profile.bio[lang]}
                onChange={(e) =>
                  set("bio", { ...profile.bio, [lang]: e.target.value })
                }
                className="mt-1.5 w-full px-3 py-2 text-sm leading-relaxed"
                style={field}
              />
            </div>
          ))}
        </div>
      </div>

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
Write-File 'app\(admin)\admin\settings\page.tsx' $c3

$c4 = @'
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
          <Link href="/admin/settings" className="link-underline text-sm">
            Profile
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
Write-File 'app\(admin)\admin\layout.tsx' $c4


Write-Host ""
Write-Host "Add these to .env.local AND to Vercel:" -ForegroundColor Yellow
Write-Host "  NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME="
Write-Host "  CLOUDINARY_API_KEY="
Write-Host "  CLOUDINARY_API_SECRET="
Write-Host "  ADMIN_UID=            (your Firebase Auth UID)"
Write-Host ""
Write-Host "Then: npm run dev" -ForegroundColor Cyan
