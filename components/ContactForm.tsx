"use client";

import { useState } from "react";
import { collection, addDoc } from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import type { Locale } from "@/lib/types";
import { getDict } from "@/lib/i18n";

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

const SUBJECT_VALUES = ["job", "freelance", "training", "other"] as const;

type State = "idle" | "sending" | "sent" | "error";

export default function ContactForm({ locale }: { locale: Locale }) {
  const d = getDict(locale);
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [company, setCompany] = useState("");
  const [subjectType, setSubjectType] =
    useState<(typeof SUBJECT_VALUES)[number]>("job");
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
      setError(`${d.sendFailed} oussemamansouri4@gmail.com`);
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
          {d.sent}
        </p>
        <p className="mt-3 text-[color:var(--color-ink-muted)]">
          {d.sentBody} oussemamansouri4@gmail.com
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
            {d.name}
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
            {d.email}
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
          {d.company} <span style={{ textTransform: "none" }}>{d.optional}</span>
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
        <legend className="eyebrow">{d.about}</legend>
        <div className="mt-3 flex flex-wrap gap-2">
          {SUBJECT_VALUES.map((v) => {
            const on = subjectType === v;
            const label = {
              job: d.subjectJob,
              freelance: d.subjectFreelance,
              training: d.subjectTraining,
              other: d.subjectOther,
            }[v];
            return (
              <button
                key={v}
                type="button"
                onClick={() => setSubjectType(v)}
                aria-pressed={on}
                className="border px-3 py-1.5 text-sm transition-colors"
                style={{
                  borderColor: on ? "var(--color-ink)" : "var(--color-line)",
                  backgroundColor: on ? "var(--color-ink)" : "transparent",
                  color: on ? "var(--color-paper)" : "var(--color-ink-muted)",
                }}
              >
                {label}
              </button>
            );
          })}
        </div>
      </fieldset>

      <div className="mt-6">
        <label className="eyebrow block" htmlFor="c-message">
          {d.message}
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
        {state === "sending" ? d.sending : d.send}
      </button>
    </div>
  );
}
