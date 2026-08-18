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
