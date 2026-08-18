"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { LOCALES, switchLocalePath } from "@/lib/i18n";
import type { Locale } from "@/lib/types";

/**
 * Language switch.
 *
 * A real link to the equivalent URL, not a state toggle - so it can be
 * opened in a new tab, shared, bookmarked and crawled. The inactive
 * language is always visible rather than hidden behind a dropdown,
 * because two options do not need a menu.
 */

export default function LocaleToggle({ current }: { current: Locale }) {
  const pathname = usePathname();

  return (
    <div className="fixed right-5 top-5 z-50 flex items-center gap-1">
      {LOCALES.map((l) => {
        const active = l === current;
        return (
          <Link
            key={l}
            href={switchLocalePath(pathname, l)}
            hrefLang={l}
            aria-current={active ? "true" : undefined}
            className="font-[family-name:var(--font-mono)] px-2 py-1 text-[11px] uppercase tracking-[0.1em] transition-opacity"
            style={{
              color: active ? "#E6E9EE" : "#8A93A5",
              backgroundColor: active ? "rgba(255,255,255,0.12)" : "transparent",
              borderRadius: "3px",
              opacity: active ? 1 : 0.75,
            }}
          >
            {l}
          </Link>
        );
      })}
    </div>
  );
}
