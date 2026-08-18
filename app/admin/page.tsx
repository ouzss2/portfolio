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
