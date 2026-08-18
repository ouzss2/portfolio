import { Public_Sans, JetBrains_Mono, Bricolage_Grotesque } from "next/font/google";
import "../globals.css";

/**
 * Admin root layout.
 *
 * A separate root from the public site because the site's html lang
 * changes per locale and the admin does not. Route groups let both exist
 * without one nesting inside the other.
 */

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

export const metadata = {
  title: "Admin",
  robots: { index: false, follow: false },
};

export default function AdminRootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body
        className={`${bricolage.variable} ${publicSans.variable} ${jetbrains.variable}`}
      >
        {children}
      </body>
    </html>
  );
}
