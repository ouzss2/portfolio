import type { MetadataRoute } from "next";
import { getAllProjectSlugs } from "@/lib/queries";
import { LOCALES } from "@/lib/i18n";

/**
 * Sitemap.
 *
 * Every page listed once per locale, with alternates pointing at each
 * other. Without this, Google has to discover the French version by
 * crawling, and may treat it as duplicate content rather than a
 * translation.
 */

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const site = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";
  const slugs = await getAllProjectSlugs();

  const paths = ["", "/projects", ...slugs.map((s) => `/projects/${s}`)];

  return paths.flatMap((path) =>
    LOCALES.map((locale) => ({
      url: `${site}/${locale}${path}`,
      lastModified: new Date(),
      changeFrequency: "weekly" as const,
      priority: path === "" ? 1 : 0.8,
      alternates: {
        languages: Object.fromEntries(
          LOCALES.map((l) => [l, `${site}/${l}${path}`])
        ),
      },
    }))
  );
}
