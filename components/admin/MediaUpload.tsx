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
