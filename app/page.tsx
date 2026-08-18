import HotReloadHero from "@/components/HotReloadHero";
import FeaturedProjects from "@/components/FeaturedProjects";
import Teaching from "@/components/Teaching";
import Skills from "@/components/Skills";
import Contact from "@/components/Contact";
import Reveal from "@/components/Reveal";

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

export default async function Home() {
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
      {/* The hero is never wrapped in Reveal - it must be readable the
          instant the page paints. */}
      <HotReloadHero
        name={profile?.fullName ?? "Oussema Mansouri"}
        availability={profile?.availabilityStatus ?? "open"}
      />

      <FeaturedProjects projects={featured} skills={skills} />

      <Reveal>
        <Teaching experiences={experiences} />
      </Reveal>

      <Reveal>
        <Skills
          groups={groups}
          certifications={certifications}
          projects={allProjects}
        />
      </Reveal>

      <Reveal>
        <Contact profile={profile} />
      </Reveal>
    </main>
  );
}
