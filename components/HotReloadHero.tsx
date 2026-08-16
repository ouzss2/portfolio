"use client";

import { useState, useEffect, useRef } from "react";

/**
 * The signature element.
 *
 * A SwiftUI-flavoured editor beside a live device. The visitor edits the
 * code, the phone re-renders. Hot reload is the mobile developer's daily
 * experience, so the hero demonstrates the craft rather than describing it.
 *
 * Deliberately not a real compiler - a handful of bound values, rendered
 * honestly. Robustness matters more than the illusion of depth here.
 */

const ACCENTS = [
  { name: "indigo", hex: "#3B2FBF" },
  { name: "swift", hex: "#F05138" },
  { name: "flutter", hex: "#0553B1" },
  { name: "android", hex: "#3DDC84" },
];

const CORNER_STEPS = [0, 8, 16, 28];

/** Editable token inside the code block. */
function Editable({
  value,
  onChange,
  ariaLabel,
}: {
  value: string;
  onChange: (v: string) => void;
  ariaLabel: string;
}) {
  const ref = useRef<HTMLSpanElement>(null);

  // Only write into the DOM when the value diverges, otherwise the caret
  // jumps to the start on every keystroke.
  useEffect(() => {
    if (ref.current && ref.current.textContent !== value) {
      ref.current.textContent = value;
    }
  }, [value]);

  return (
    <span
      ref={ref}
      role="textbox"
      aria-label={ariaLabel}
      contentEditable
      suppressContentEditableWarning
      spellCheck={false}
      onInput={(e) => onChange(e.currentTarget.textContent?.slice(0, 42) ?? "")}
      onKeyDown={(e) => {
        if (e.key === "Enter") e.preventDefault();
      }}
      className="outline-none"
      style={{
        color: "#E4B77F",
        borderBottom: "1px dashed rgba(228,183,127,0.45)",
        cursor: "text",
        padding: "0 1px",
      }}
    />
  );
}

export default function HotReloadHero({
  name = "Oussema Mansouri",
  role = "Mobile Developer",
  availability = "open" as "available" | "open" | "unavailable",
}) {
  const [headline, setHeadline] = useState("Builds apps.");
  const [subline, setSubline] = useState("Teaches them too.");
  const [accent, setAccent] = useState(ACCENTS[0]);
  const [corner, setCorner] = useState(28);
  const [reloading, setReloading] = useState(false);
  const [touched, setTouched] = useState(false);

  // Flash the reload indicator on every change, the way Xcode's canvas
  // and Flutter's hot reload both do.
  useEffect(() => {
    setReloading(true);
    const t = setTimeout(() => setReloading(false), 260);
    return () => clearTimeout(t);
  }, [headline, subline, accent, corner]);

  const status = {
    available: { label: "Available for work", color: "#1E7A4A" },
    open: { label: "Open to offers", color: "#8A6A12" },
    unavailable: { label: "Not available", color: "#7A2F2F" },
  }[availability];

  return (
    <section className="grid min-h-[100svh] grid-cols-1 lg:grid-cols-[1.05fr_0.95fr]">
      {/* ============================================================
          Left - the editor. Dark, because code lives in dark.
          ============================================================ */}
      <div
        className="flex flex-col justify-between px-6 py-14 sm:px-10 lg:px-14 lg:py-16"
        style={{ backgroundColor: "#12151C", color: "#E6E9EE" }}
      >
        <div>
          <p
            className="font-[family-name:var(--font-mono)] text-xs uppercase tracking-[0.14em]"
            style={{ color: "#6E7787" }}
          >
            Tunis &middot; iOS &middot; Flutter &middot; Android
          </p>

          <h1
            className="mt-7 font-[family-name:var(--font-display)] font-bold"
            style={{
              fontSize: "clamp(2.75rem, 6vw, 4.25rem)",
              lineHeight: 0.94,
              letterSpacing: "-0.035em",
            }}
          >
            {name}
          </h1>

          <p className="mt-4 text-lg" style={{ color: "#9AA3B2" }}>
            {role} and instructor at TEK-UP. Three years shipping native iOS,
            cross-platform Flutter, and native Android.
          </p>

          <p className="mt-5 flex items-center gap-2.5 text-sm">
            <span
              aria-hidden
              className="inline-block h-2 w-2 rounded-full"
              style={{ backgroundColor: status.color }}
            />
            <span style={{ color: "#C3CAD6" }}>{status.label}</span>
          </p>
        </div>

        {/* --- the editor ---------------------------------------- */}
        <div className="mt-12">
          <div className="mb-3 flex items-center justify-between">
            <p
              className="font-[family-name:var(--font-mono)] text-xs"
              style={{ color: "#6E7787" }}
            >
              HeroCard.swift
            </p>
            <p
              className="font-[family-name:var(--font-mono)] text-xs transition-opacity duration-200"
              style={{
                color: accent.hex === "#3B2FBF" ? "#8B80FF" : accent.hex,
                opacity: reloading ? 1 : 0.35,
              }}
            >
              {reloading ? "reloading..." : "live"}
            </p>
          </div>

          <pre
            className="overflow-x-auto rounded-lg p-5 font-[family-name:var(--font-mono)] text-[13px] leading-[1.75]"
            style={{ backgroundColor: "#0C0F15", border: "1px solid #1E2430" }}
          >
            <code>
              <span style={{ color: "#C97BC4" }}>struct</span>{" "}
              <span style={{ color: "#7FC8E8" }}>HeroCard</span>:{" "}
              <span style={{ color: "#7FC8E8" }}>View</span> {"{"}
              {"\n  "}
              <span style={{ color: "#C97BC4" }}>var</span> body:{" "}
              <span style={{ color: "#C97BC4" }}>some</span>{" "}
              <span style={{ color: "#7FC8E8" }}>View</span> {"{"}
              {"\n    "}
              <span style={{ color: "#7FC8E8" }}>VStack</span>(alignment: .leading) {"{"}
              {"\n      "}
              <span style={{ color: "#7FC8E8" }}>Text</span>(
              <span style={{ color: "#E4B77F" }}>&quot;</span>
              <Editable
                value={headline}
                onChange={(v) => {
                  setHeadline(v);
                  setTouched(true);
                }}
                ariaLabel="Headline text"
              />
              <span style={{ color: "#E4B77F" }}>&quot;</span>)
              {"\n        "}.<span style={{ color: "#8FD37F" }}>font</span>(.largeTitle)
              {"\n      "}
              <span style={{ color: "#7FC8E8" }}>Text</span>(
              <span style={{ color: "#E4B77F" }}>&quot;</span>
              <Editable
                value={subline}
                onChange={(v) => {
                  setSubline(v);
                  setTouched(true);
                }}
                ariaLabel="Subline text"
              />
              <span style={{ color: "#E4B77F" }}>&quot;</span>)
              {"\n        "}.<span style={{ color: "#8FD37F" }}>opacity</span>(
              <span style={{ color: "#D4A85F" }}>0.7</span>)
              {"\n    "}
              {"}"}
              {"\n    "}.<span style={{ color: "#8FD37F" }}>background</span>(
              <span style={{ color: "#7FC8E8" }}>Color</span>.
              <span style={{ color: "#8FD37F" }}>{accent.name}</span>)
              {"\n    "}.<span style={{ color: "#8FD37F" }}>cornerRadius</span>(
              <span style={{ color: "#D4A85F" }}>{corner}</span>)
              {"\n  "}
              {"}"}
              {"\n"}
              {"}"}
            </code>
          </pre>

          {/* --- controls --------------------------------------- */}
          <div className="mt-5 flex flex-wrap items-center gap-x-8 gap-y-4">
            <div className="flex items-center gap-2.5">
              <span
                className="font-[family-name:var(--font-mono)] text-xs"
                style={{ color: "#6E7787" }}
              >
                Color
              </span>
              {ACCENTS.map((a) => (
                <button
                  key={a.name}
                  onClick={() => {
                    setAccent(a);
                    setTouched(true);
                  }}
                  aria-label={`Accent ${a.name}`}
                  aria-pressed={accent.name === a.name}
                  className="h-5 w-5 rounded-full transition-transform hover:scale-110"
                  style={{
                    backgroundColor: a.hex,
                    outline:
                      accent.name === a.name ? "2px solid #E6E9EE" : "none",
                    outlineOffset: "2px",
                  }}
                />
              ))}
            </div>

            <div className="flex items-center gap-2.5">
              <span
                className="font-[family-name:var(--font-mono)] text-xs"
                style={{ color: "#6E7787" }}
              >
                Radius
              </span>
              {CORNER_STEPS.map((c) => (
                <button
                  key={c}
                  onClick={() => {
                    setCorner(c);
                    setTouched(true);
                  }}
                  aria-pressed={corner === c}
                  className="font-[family-name:var(--font-mono)] px-2 py-0.5 text-xs transition-colors"
                  style={{
                    color: corner === c ? "#12151C" : "#9AA3B2",
                    backgroundColor: corner === c ? "#E6E9EE" : "transparent",
                    border: "1px solid #2A3140",
                    borderRadius: "3px",
                  }}
                >
                  {c}
                </button>
              ))}
            </div>
          </div>

          <p
            className="mt-5 text-sm transition-opacity duration-500"
            style={{ color: "#6E7787", opacity: touched ? 0.45 : 1 }}
          >
            {touched
              ? "That's hot reload. It's how the apps get built."
              : "Edit the code - the phone updates as you type."}
          </p>
        </div>
      </div>

      {/* ============================================================
          Right - the device. Light, because that's the simulator.
          ============================================================ */}
      <div
        className="flex items-center justify-center px-6 py-16"
        style={{ backgroundColor: "var(--color-paper)" }}
      >
        <div
          className="relative"
          style={{
            width: "min(300px, 78vw)",
            aspectRatio: "9 / 19.5",
            backgroundColor: "#0C0F15",
            borderRadius: "44px",
            padding: "11px",
            boxShadow: "0 1px 0 rgba(0,0,0,0.12)",
          }}
        >
          {/* screen */}
          <div
            className="relative h-full w-full overflow-hidden"
            style={{ backgroundColor: "#FAFBF9", borderRadius: "34px" }}
          >
            {/* notch */}
            <div
              aria-hidden
              className="absolute left-1/2 top-2 h-6 w-24 -translate-x-1/2 rounded-full"
              style={{ backgroundColor: "#0C0F15" }}
            />

            {/* the rendered card */}
            <div className="flex h-full flex-col justify-center p-5">
              <div
                className="p-6 transition-all duration-200"
                style={{
                  backgroundColor: accent.hex,
                  borderRadius: `${corner}px`,
                  transform: reloading ? "scale(0.985)" : "scale(1)",
                }}
              >
                <p
                  className="font-[family-name:var(--font-display)] font-bold leading-[1.05]"
                  style={{
                    fontSize: "1.75rem",
                    letterSpacing: "-0.02em",
                    color: accent.name === "android" ? "#0C0F15" : "#FFFFFF",
                  }}
                >
                  {headline || " "}
                </p>
                <p
                  className="mt-1.5 text-base"
                  style={{
                    color: accent.name === "android" ? "#0C0F15" : "#FFFFFF",
                    opacity: 0.7,
                  }}
                >
                  {subline || " "}
                </p>
              </div>

              <p
                className="mt-5 font-[family-name:var(--font-mono)] text-[11px] uppercase tracking-[0.12em]"
                style={{ color: "var(--color-ink-muted)" }}
              >
                Preview &middot; iPhone 15
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
