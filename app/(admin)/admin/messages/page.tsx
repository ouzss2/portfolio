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
