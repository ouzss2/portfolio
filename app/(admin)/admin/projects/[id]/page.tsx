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
            accept="image"
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
