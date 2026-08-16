/**
 * Firestore data model â€” TypeScript definitions.
 * Every bilingual field is a nested map so EN/FR stay together in one document.
 */

export type Locale = "en" | "fr";

/** Bilingual string. Both locales required at the type level so the admin form
 *  can't silently ship a half-translated document. */
export interface Localized {
  en: string;
  fr: string;
}

export type PublishStatus = "draft" | "published";
export type AvailabilityStatus = "available" | "open" | "unavailable";
export type ProjectType = "professional" | "personal" | "academic";
export type SubjectType = "job" | "freelance" | "training" | "other";
export type MessageStatus = "unread" | "read" | "archived";

/* ------------------------------------------------------------------ */
/* settings/profile â€” single document                                  */
/* ------------------------------------------------------------------ */

export interface Profile {
  fullName: string;
  headline: Localized;
  bio: Localized;
  photoUrl: string;
  location: string;
  email: string;
  phone: string;
  linkedinUrl: string;
  githubUrl: string;
  availabilityStatus: AvailabilityStatus;
  cvUrls: { en: string; fr: string };
  seoDefaults: {
    title: Localized;
    description: Localized;
    ogImage: string;
  };
  updatedAt: string; // ISO 8601
}

/* ------------------------------------------------------------------ */
/* projects/{id}                                                       */
/* ------------------------------------------------------------------ */

export interface MediaItem {
  url: string;
  type: "image" | "video";
  caption: Localized;
}

export interface Metric {
  label: Localized;
  value: string;
}

export interface CaseStudy {
  context: Localized;
  problem: Localized;
  role: Localized;
  technicalDecisions: Localized;
  challenges: Localized;
  result: Localized;
}

export interface ProjectLinks {
  appStore?: string;
  playStore?: string;
  github?: string;
  demo?: string;
}

export interface Project {
  id: string;
  slug: string;
  title: Localized;
  summary: Localized;
  caseStudy: CaseStudy;
  type: ProjectType;
  featured: boolean;
  order: number;
  coverImageUrl: string;
  media: MediaItem[];
  metrics: Metric[];
  links: ProjectLinks;
  skillIds: string[];
  status: PublishStatus;
  createdAt: string;
  publishedAt: string | null;
}

/* ------------------------------------------------------------------ */
/* skills                                                              */
/* ------------------------------------------------------------------ */

export interface SkillCategory {
  id: string;
  name: Localized;
  icon: string;
  order: number;
}

/** 1 = learning, 3 = production-comfortable, 5 = teach it to others. */
export type SkillLevel = 1 | 2 | 3 | 4 | 5;

export interface Skill {
  id: string;
  categoryId: string;
  name: string;
  level: SkillLevel;
  yearsExperience: number;
  icon: string;
  order: number;
}

/* ------------------------------------------------------------------ */
/* experience / education / certifications                             */
/* ------------------------------------------------------------------ */

export interface Experience {
  id: string;
  company: string;
  role: Localized;
  location: string;
  startDate: string; // ISO 8601
  endDate: string | null; // null = current
  description: Localized;
  achievements: Localized[];
  skillIds: string[];
  projectIds: string[];
  order: number;
}

export interface Education {
  id: string;
  institution: string;
  degree: Localized;
  specialization: Localized;
  startYear: number;
  endYear: number;
  order: number;
}

export interface Certification {
  id: string;
  name: string;
  issuer: string;
  issueDate: string;
  credentialUrl: string;
  badgeImageUrl: string;
  order: number;
}

/* ------------------------------------------------------------------ */
/* articles / testimonials / services                                  */
/* ------------------------------------------------------------------ */

export interface Article {
  id: string;
  slug: string;
  title: Localized;
  excerpt: Localized;
  content: Localized; // MDX source
  coverImageUrl: string;
  tags: string[];
  readingTime: number; // minutes
  status: PublishStatus;
  publishedAt: string | null;
}

export interface Testimonial {
  id: string;
  authorName: string;
  authorRole: string;
  authorCompany: string;
  authorPhotoUrl: string;
  content: Localized;
  order: number;
  status: PublishStatus;
}

export interface Service {
  id: string;
  title: Localized;
  description: Localized;
  deliverables: Localized[];
  icon: string;
  order: number;
}

/* ------------------------------------------------------------------ */
/* messages / stats                                                    */
/* ------------------------------------------------------------------ */

export interface ContactMessage {
  id: string;
  name: string;
  email: string;
  company: string;
  subjectType: SubjectType;
  message: string;
  status: MessageStatus;
  createdAt: string;
}

export interface Counters {
  cvDownloads: { en: number; fr: number };
  projectViews: Record<string, number>;
}

/* ------------------------------------------------------------------ */
/* Helpers                                                             */
/* ------------------------------------------------------------------ */

/** Pull one locale out of a bilingual field, falling back to EN. */
export function t(field: Localized | undefined, locale: Locale): string {
  if (!field) return "";
  return field[locale] || field.en || "";
}

export const COLLECTIONS = {
  settings: "settings",
  projects: "projects",
  skillCategories: "skillCategories",
  skills: "skills",
  experiences: "experiences",
  education: "education",
  certifications: "certifications",
  articles: "articles",
  testimonials: "testimonials",
  services: "services",
  messages: "messages",
  stats: "stats",
} as const;

