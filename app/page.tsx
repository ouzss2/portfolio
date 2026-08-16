import HotReloadHero from "@/components/HotReloadHero";
import FeaturedProjects from "@/components/FeaturedProjects";
import Teaching from "@/components/Teaching";
import Skills from "@/components/Skills";
import Contact from "@/components/Contact";

import {
  getProfile,
  getFeaturedProjects,
  getSkills,
  getSkillsByCategory,
  getExperiences,
  getCertifications,
} from "@/lib/queries";

export const revalidate = 3600;

export default async function Home() {
  const [profile, projects, skills, groups, experiences, certifications] =
    await Promise.all([
      getProfile(),
      getFeaturedProjects(3),
      getSkills(),
      getSkillsByCategory(),
      getExperiences(),
      getCertifications(),
    ]);

  return (
    <main>
      <HotReloadHero
        name={profile?.fullName ?? "Oussema Mansouri"}
        role={profile?.headline.en ?? "Mobile Developer"}
        availability={profile?.availabilityStatus ?? "open"}
      />
      <FeaturedProjects projects={projects} skills={skills} />
      <Teaching experiences={experiences} />
      <Skills groups={groups} certifications={certifications} />
      <Contact profile={profile} />
    </main>
  );
}
