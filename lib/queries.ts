/**
 * Server-side data access layer.
 *
 * Every function here runs at build time (ISR) or in a server component.
 * Public pages are statically generated, so a visitor costs zero Firestore
 * reads â€” only rebuilds do.
 *
 * Import from server components only.
 */

import "server-only";
import { adminDb } from "./firebase/admin";
import { COLLECTIONS } from "./types";
import type {
  Profile,
  Project,
  Skill,
  SkillCategory,
  Experience,
  Education,
  Certification,
  Article,
  Testimonial,
  Service,
} from "./types";

/** Revalidate ISR pages every hour; admin writes also trigger on-demand. */
export const REVALIDATE_SECONDS = 3600;

/** Firestore docs come back untyped â€” attach the id and cast. */
function withId<T>(doc: FirebaseFirestore.QueryDocumentSnapshot): T {
  return { id: doc.id, ...doc.data() } as T;
}

/* ------------------------------------------------------------------ */
/* Profile                                                             */
/* ------------------------------------------------------------------ */

export async function getProfile(): Promise<Profile | null> {
  const snap = await adminDb.collection(COLLECTIONS.settings).doc("profile").get();
  return snap.exists ? (snap.data() as Profile) : null;
}

/* ------------------------------------------------------------------ */
/* Projects                                                            */
/* ------------------------------------------------------------------ */

export async function getPublishedProjects(): Promise<Project[]> {
  const snap = await adminDb
    .collection(COLLECTIONS.projects)
    .where("status", "==", "published")
    .orderBy("order", "asc")
    .get();
  return snap.docs.map((d) => withId<Project>(d));
}

export async function getFeaturedProjects(limit = 3): Promise<Project[]> {
  const snap = await adminDb
    .collection(COLLECTIONS.projects)
    .where("status", "==", "published")
    .where("featured", "==", true)
    .orderBy("order", "asc")
    .limit(limit)
    .get();
  return snap.docs.map((d) => withId<Project>(d));
}

export async function getProjectBySlug(slug: string): Promise<Project | null> {
  const snap = await adminDb
    .collection(COLLECTIONS.projects)
    .where("slug", "==", slug)
    .where("status", "==", "published")
    .limit(1)
    .get();
  return snap.empty ? null : withId<Project>(snap.docs[0]);
}

/** For generateStaticParams() on the project detail route. */
export async function getAllProjectSlugs(): Promise<string[]> {
  const snap = await adminDb
    .collection(COLLECTIONS.projects)
    .where("status", "==", "published")
    .select("slug")
    .get();
  return snap.docs.map((d) => d.data().slug as string);
}

/* ------------------------------------------------------------------ */
/* Skills                                                              */
/* ------------------------------------------------------------------ */

export async function getSkillCategories(): Promise<SkillCategory[]> {
  const snap = await adminDb
    .collection(COLLECTIONS.skillCategories)
    .orderBy("order", "asc")
    .get();
  return snap.docs.map((d) => withId<SkillCategory>(d));
}

export async function getSkills(): Promise<Skill[]> {
  const snap = await adminDb.collection(COLLECTIONS.skills).orderBy("order", "asc").get();
  return snap.docs.map((d) => withId<Skill>(d));
}

/** Skills grouped under their category, ready to render. */
export async function getSkillsByCategory(): Promise<
  Array<{ category: SkillCategory; skills: Skill[] }>
> {
  const [categories, skills] = await Promise.all([getSkillCategories(), getSkills()]);
  return categories.map((category) => ({
    category,
    skills: skills.filter((s) => s.categoryId === category.id),
  }));
}

/* ------------------------------------------------------------------ */
/* Experience / Education / Certifications                             */
/* ------------------------------------------------------------------ */

export async function getExperiences(): Promise<Experience[]> {
  const snap = await adminDb
    .collection(COLLECTIONS.experiences)
    .orderBy("order", "asc")
    .get();
  return snap.docs.map((d) => withId<Experience>(d));
}

export async function getEducation(): Promise<Education[]> {
  const snap = await adminDb.collection(COLLECTIONS.education).orderBy("order", "asc").get();
  return snap.docs.map((d) => withId<Education>(d));
}

export async function getCertifications(): Promise<Certification[]> {
  const snap = await adminDb
    .collection(COLLECTIONS.certifications)
    .orderBy("order", "asc")
    .get();
  return snap.docs.map((d) => withId<Certification>(d));
}

/* ------------------------------------------------------------------ */
/* Articles / Testimonials / Services                                  */
/* ------------------------------------------------------------------ */

export async function getPublishedArticles(): Promise<Article[]> {
  const snap = await adminDb
    .collection(COLLECTIONS.articles)
    .where("status", "==", "published")
    .orderBy("publishedAt", "desc")
    .get();
  return snap.docs.map((d) => withId<Article>(d));
}

export async function getArticleBySlug(slug: string): Promise<Article | null> {
  const snap = await adminDb
    .collection(COLLECTIONS.articles)
    .where("slug", "==", slug)
    .where("status", "==", "published")
    .limit(1)
    .get();
  return snap.empty ? null : withId<Article>(snap.docs[0]);
}

export async function getTestimonials(): Promise<Testimonial[]> {
  const snap = await adminDb
    .collection(COLLECTIONS.testimonials)
    .where("status", "==", "published")
    .orderBy("order", "asc")
    .get();
  return snap.docs.map((d) => withId<Testimonial>(d));
}

export async function getServices(): Promise<Service[]> {
  const snap = await adminDb.collection(COLLECTIONS.services).orderBy("order", "asc").get();
  return snap.docs.map((d) => withId<Service>(d));
}

/* ------------------------------------------------------------------ */
/* Aggregate â€” one call for the home page                              */
/* ------------------------------------------------------------------ */

export async function getHomePageData() {
  const [profile, featuredProjects, skillGroups, experiences, certifications] =
    await Promise.all([
      getProfile(),
      getFeaturedProjects(3),
      getSkillsByCategory(),
      getExperiences(),
      getCertifications(),
    ]);

  return { profile, featuredProjects, skillGroups, experiences, certifications };
}

