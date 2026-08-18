import type { Metadata } from "next";
import ProjectsIndex from "@/components/ProjectsIndex";
import { getPublishedProjects, getSkills } from "@/lib/queries";

export const revalidate = 3600;

export const metadata: Metadata = {
  title: "Projects - Oussema Mansouri",
  description:
    "Mobile application case studies: native iOS with Swift and SwiftUI, cross-platform Flutter, native Android.",
};

export default async function Page() {
  const [projects, skills] = await Promise.all([
    getPublishedProjects(),
    getSkills(),
  ]);

  return <ProjectsIndex projects={projects} skills={skills} />;
}
