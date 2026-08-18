import { notFound } from "next/navigation";
import HotReloadHero from "@/components/HotReloadHero";
import FeaturedProjects from "@/components/FeaturedProjects";
import Teaching from "@/components/Teaching";
import Skills from "@/components/Skills";
import Contact from "@/components/Contact";
import Reveal from "@/components/Reveal";
import { isLocale } from "@/lib/i18n";
import { t as tr } from "@/lib/types";

import {
  getProfile,
  getFeaturedProjects,
  getPublishedProjects,
  getSkills,
  getSkillsByCategory,
  getExperiences,
  getCertifications,
} from "@/lib/queries";

export const revalidate = 3600;

export default async function Home({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!isLocale(locale)) notFound();

  const [
    profile,
    featured,
    allProjects,
    skills,
    groups,
    experiences,
    certifications,
  ] = await Promise.all([
    getProfile(),
    getFeaturedProjects(3),
    getPublishedProjects(),
    getSkills(),
    getSkillsByCategory(),
    getExperiences(),
    getCertifications(),
  ]);

  return (
    <main>
      {/* Never wrapped in Reveal - the headline and availability badge
          must be readable the instant the page paints. */}
      <HotReloadHero
        name={profile?.fullName ?? "Oussema Mansouri"}
        availability={profile?.availabilityStatus ?? "open"}
        locale={locale}
      />

      <FeaturedProjects projects={featured} skills={skills} locale={locale} />

      <Reveal>
        <Teaching experiences={experiences} locale={locale} />
      </Reveal>

      <Reveal>
        <Skills
          groups={groups}
          certifications={certifications}
          projects={allProjects}
          locale={locale}
        />
      </Reveal>

      <Reveal>
        <Contact profile={profile} locale={locale} />
      </Reveal>
    </main>
  );
}
