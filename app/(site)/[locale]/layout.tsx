import type { Metadata } from "next";
import { Bricolage_Grotesque, Public_Sans, JetBrains_Mono } from "next/font/google";
import { notFound } from "next/navigation";
import { isLocale, LOCALES } from "@/lib/i18n";
import LocaleToggle from "@/components/LocaleToggle";
import "../../globals.css";

const bricolage = Bricolage_Grotesque({
  variable: "--font-bricolage",
  subsets: ["latin"],
  display: "swap",
  weight: ["400", "600", "700"],
});
const publicSans = Public_Sans({
  variable: "--font-public-sans",
  subsets: ["latin"],
  display: "swap",
});
const jetbrains = JetBrains_Mono({
  variable: "--font-jetbrains",
  subsets: ["latin"],
  display: "swap",
  weight: ["400", "500"],
});

export function generateStaticParams() {
  return LOCALES.map((locale) => ({ locale }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const site = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";

  const meta = {
    en: {
      title: "Oussema Mansouri - Mobile Developer (iOS, Flutter, Android)",
      description:
        "Mobile developer and instructor in Tunis. Native iOS with Swift and SwiftUI, cross-platform Flutter, native Android. AWS Certified Cloud Practitioner.",
    },
    fr: {
      title: "Oussema Mansouri - D\u00e9veloppeur Mobile (iOS, Flutter, Android)",
      description:
        "D\u00e9veloppeur mobile et formateur \u00e0 Tunis. iOS natif avec Swift et SwiftUI, Flutter multiplateforme, Android natif. AWS Certified Cloud Practitioner.",
    },
  }[locale === "fr" ? "fr" : "en"];

  return {
    title: meta.title,
    description: meta.description,
    metadataBase: new URL(site),
    alternates: {
      canonical: `${site}/${locale}`,
      // hreflang tells Google these are translations of one page rather
      // than duplicate content competing with each other.
      languages: {
        en: `${site}/en`,
        fr: `${site}/fr`,
        "x-default": `${site}/en`,
      },
    },
    openGraph: {
      title: meta.title,
      description: meta.description,
      locale: locale === "fr" ? "fr_FR" : "en_US",
      type: "profile",
    },
  };
}

export default async function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!isLocale(locale)) notFound();

  return (
    <html lang={locale}>
      <body
        className={`${bricolage.variable} ${publicSans.variable} ${jetbrains.variable}`}
      >
        <LocaleToggle current={locale} />
        {children}
      </body>
    </html>
  );
}
