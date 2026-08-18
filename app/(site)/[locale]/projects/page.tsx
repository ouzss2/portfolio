import type { Metadata } from "next";
import ProjectsIndex from "@/components/ProjectsIndex";
import { notFound } from "next/navigation";
import { isLocale } from "@/lib/i18n";
import { getPublishedProjects, getSkills } from "@/lib/queries";

export const revalidate = 3600;

export const metadata: Metadata = {
  title: "Projects - Oussema Mansouri",
  description:
    "Mobile application case studies: native iOS with Swift and SwiftUI, cross-platform Flutter, native Android.",
};

export default async function Page({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!isLocale(locale)) notFound();

  const [projects, skills] = await Promise.all([
    getPublishedProjects(),
    getSkills(),
  ]);

  return <ProjectsIndex projects={projects} skills={skills} locale={locale} />;
}
