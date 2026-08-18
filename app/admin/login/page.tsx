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
