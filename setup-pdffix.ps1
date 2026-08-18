# ============================================================
#  Portfolio - PDF upload fix + unsaved changes warning
#  Run from project root:  .\setup-pdffix.ps1
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

$c0 = @'
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
    accept === "image"
      ? "image/*"
      : accept === "video"
        ? "video/*"
        : "image/*,video/*,application/pdf";

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

      // Three resource types, not two. PDFs must go to "raw": the image
      // pipeline treats a PDF as something to rasterise, so f_auto would
      // return a JPEG of page one instead of the document. Raw delivery
      // also sidesteps Cloudinary's default block on PDF delivery.
      const isVideo = file.type.startsWith("video");
      const isRaw =
        file.type === "application/pdf" ||
        (!isVideo && !file.type.startsWith("image"));
      const resourceType = isVideo ? "video" : isRaw ? "raw" : "image";

      const form = new FormData();
      form.append("file", file);
      form.append("api_key", apiKey);
      form.append("timestamp", String(timestamp));
      form.append("signature", signature);
      form.append("folder", folder);

      const url = `https://api.cloudinary.com/v1_1/${cloudName}/${resourceType}/upload`;

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

      // Insert delivery transformations so the page never serves the
      // original file. Raw files are delivered untouched - a CV must
      // arrive as the PDF it was uploaded as.
      const optimised = isRaw
        ? secureUrl
        : secureUrl.replace(
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
Write-File 'components\admin\MediaUpload.tsx' $c0

$c1 = @'
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

const FIELD_STYLE: React.CSSProperties = {
  border: "1px solid var(--color-line)",
  backgroundColor: "var(--color-paper-raised)",
};

/**
 * Defined at module scope, not inside Settings. A component declared in
 * the render body is a new type on every render, so React unmounts and
 * remounts it - dropping focus after every keystroke.
 */
function Text({
  label,
  value,
  onChange,
  placeholder,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
}) {
  return (
    <div>
      <label className="eyebrow block">{label}</label>
      <input
        value={value}
        placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
        className="mt-2 w-full px-3 py-2 text-sm"
        style={FIELD_STYLE}
      />
    </div>
  );
}

const AVAILABILITY: Array<{ value: AvailabilityStatus; label: string }> = [
  { value: "available", label: "Available for work" },
  { value: "open", label: "Open to offers" },
  { value: "unavailable", label: "Not available" },
];

export default function Settings() {
  const [profile, setProfile] = useState<Profile | null>(null);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [dirty, setDirty] = useState(false);

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
    setDirty(false);
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

  const set = <K extends keyof Profile>(k: K, v: Profile[K]) => {
    setProfile({ ...profile, [k]: v });
    setDirty(true);
  };


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
                style={FIELD_STYLE}
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
        {dirty && !saving && (
          <span
            className="font-[family-name:var(--font-mono)] text-xs"
            style={{ color: "var(--color-status-open)" }}
          >
            Unsaved changes
          </span>
        )}
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
Write-File 'app\(admin)\admin\settings\page.tsx' $c1


Write-Host ""
Write-Host "Restart dev server, then re-upload the CV." -ForegroundColor Yellow
