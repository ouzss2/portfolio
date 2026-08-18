import { NextResponse, type NextRequest } from "next/server";

/**
 * Locale routing.
 *
 * Every public URL carries its language: /en/projects, /fr/projets-style
 * paths stay the same slug but the prefix differs. A bare / redirects to
 * the visitor's preferred language if we serve it, English otherwise.
 *
 * Real URLs rather than a client-side toggle, because the point of the
 * French version is that a recruiter searching in French can find it.
 * A toggle that never changes the URL is invisible to a search engine.
 */

const LOCALES = ["en", "fr"];
const DEFAULT = "en";

function preferred(request: NextRequest): string {
  const header = request.headers.get("accept-language");
  if (!header) return DEFAULT;
  // "fr-FR,fr;q=0.9,en;q=0.8" - first match wins
  for (const part of header.split(",")) {
    const tag = part.split(";")[0].trim().slice(0, 2).toLowerCase();
    if (LOCALES.includes(tag)) return tag;
  }
  return DEFAULT;
}

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  const hasLocale = LOCALES.some(
    (l) => pathname === `/${l}` || pathname.startsWith(`/${l}/`)
  );
  if (hasLocale) return NextResponse.next();

  const url = request.nextUrl.clone();
  url.pathname = `/${preferred(request)}${pathname === "/" ? "" : pathname}`;
  return NextResponse.redirect(url);
}

export const config = {
  // Admin, API, static assets and files with extensions are left alone.
  matcher: ["/((?!admin|api|_next|favicon.ico|.*\\..*).*)"],
};
