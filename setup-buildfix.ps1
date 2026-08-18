# ============================================================
#  Portfolio - build fix (MediaUpload props)
#  Run from project root:  .\setup-buildfix.ps1
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
  label,
  onUploaded,
}: {
  folder?: string;
  /** "image" | "video" | "both". Note this is a Kind, not a MIME pattern. */
  accept?: Kind | "both";
  label?: string;
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
      {label && (
        <p className="mb-2 text-xs text-[color:var(--color-ink-muted)]">
          {label}
        </p>
      )}
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


# Fix the call site: accept takes a Kind, not a MIME pattern.
$editor = ".\app\(admin)\admin\projects\[id]\page.tsx"
if (Test-Path $editor) {
  $c = [System.IO.File]::ReadAllText((Resolve-Path $editor).Path)
  $c = $c.Replace('accept="image/*"', 'accept="image"')
  $c = $c.Replace('accept="video/*"', 'accept="video"')
  $c = $c.Replace('accept="image/*,video/*"', 'accept="both"')
  [System.IO.File]::WriteAllText((Resolve-Path $editor).Path, $c, $utf8NoBom)
  Write-Host "  fixed  accept props in project editor" -ForegroundColor Green
}

# Stale generated types still reference routes deleted during the i18n
# restructure. They regenerate on the next build.
if (Test-Path ".\.next") {
  Remove-Item -Recurse -Force ".\.next"
  Write-Host "  cleared .next cache" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Now run:  npx tsc --noEmit" -ForegroundColor Yellow
Write-Host "It should report no errors. Then commit and push." -ForegroundColor Yellow
