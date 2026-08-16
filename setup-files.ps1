# ============================================================
#  Portfolio - Day 1 file scaffolding
#  Run from the project root: C:\Users\pc\dev\portfolio
#  Usage:  .\setup-files.ps1
# ============================================================

$ErrorActionPreference = "Stop"

if (-not (Test-Path ".\package.json")) {
  Write-Host "ERROR: run this from the portfolio root (where package.json is)." -ForegroundColor Red
  exit 1
}

# Remove the stray nested folder if it is still there
if (Test-Path ".\portfolio") {
  Remove-Item -Recurse -Force ".\portfolio"
  Write-Host "  removed stray .\portfolio folder" -ForegroundColor DarkGray
}

New-Item -ItemType Directory -Force -Path ".\lib" | Out-Null
New-Item -ItemType Directory -Force -Path ".\lib\firebase" | Out-Null
New-Item -ItemType Directory -Force -Path ".\scripts" | Out-Null
Write-Host "Folders ready." -ForegroundColor Cyan
Write-Host ""

$f0 = @'
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // ----------------------------------------------------------------
    // Helpers
    // ----------------------------------------------------------------

    // Replace with your Firebase Auth UID after creating the admin user.
    // Find it in Firebase Console > Authentication > Users.
    function isOwner() {
      return request.auth != null
             && request.auth.uid == 'REPLACE_WITH_YOUR_UID';
    }

    function isPublished() {
      return resource.data.status == 'published';
    }

    // ----------------------------------------------------------------
    // Gated content — public sees published only, owner sees everything
    // ----------------------------------------------------------------

    match /projects/{projectId} {
      allow read: if isPublished() || isOwner();
      allow create, update, delete: if isOwner();
    }

    match /articles/{articleId} {
      allow read: if isPublished() || isOwner();
      allow create, update, delete: if isOwner();
    }

    match /testimonials/{testimonialId} {
      allow read: if isPublished() || isOwner();
      allow create, update, delete: if isOwner();
    }

    // ----------------------------------------------------------------
    // Always-public reference data
    // ----------------------------------------------------------------

    match /skills/{skillId} {
      allow read: if true;
      allow write: if isOwner();
    }

    match /skillCategories/{categoryId} {
      allow read: if true;
      allow write: if isOwner();
    }

    match /experiences/{experienceId} {
      allow read: if true;
      allow write: if isOwner();
    }

    match /education/{educationId} {
      allow read: if true;
      allow write: if isOwner();
    }

    match /certifications/{certificationId} {
      allow read: if true;
      allow write: if isOwner();
    }

    match /services/{serviceId} {
      allow read: if true;
      allow write: if isOwner();
    }

    match /settings/{docId} {
      allow read: if true;
      allow write: if isOwner();
    }

    // ----------------------------------------------------------------
    // Contact form — anyone may submit, only owner may read
    // ----------------------------------------------------------------

    match /messages/{messageId} {
      allow create: if request.resource.data.keys().hasAll(
                         ['name', 'email', 'message', 'subjectType', 'status', 'createdAt']
                       )
                    && request.resource.data.name is string
                    && request.resource.data.name.size() > 0
                    && request.resource.data.name.size() <= 120
                    && request.resource.data.email is string
                    && request.resource.data.email.matches('.+@.+\\..+')
                    && request.resource.data.message is string
                    && request.resource.data.message.size() > 10
                    && request.resource.data.message.size() <= 5000
                    && request.resource.data.subjectType in
                         ['job', 'freelance', 'training', 'other']
                    && request.resource.data.status == 'unread';

      allow read, update, delete: if isOwner();
    }

    // ----------------------------------------------------------------
    // Counters
    // ----------------------------------------------------------------

    match /stats/{docId} {
      allow read: if true;
      allow write: if isOwner();
    }

    // ----------------------------------------------------------------
    // Deny anything not matched above
    // ----------------------------------------------------------------

    match /{document=**} {
      allow read, write: if false;
    }
  }
}

'@
Set-Content -Path '.\firestore.rules' -Value $f0 -Encoding UTF8
Write-Host '  created firestore.rules' -ForegroundColor Green

$f1 = @'
/**
 * Firestore data model — TypeScript definitions.
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
/* settings/profile — single document                                  */
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

'@
Set-Content -Path '.\lib\types.ts' -Value $f1 -Encoding UTF8
Write-Host '  created lib\types.ts' -ForegroundColor Green

$f2 = @'
/**
 * Server-side data access layer.
 *
 * Every function here runs at build time (ISR) or in a server component.
 * Public pages are statically generated, so a visitor costs zero Firestore
 * reads — only rebuilds do.
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

/** Firestore docs come back untyped — attach the id and cast. */
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
/* Aggregate — one call for the home page                              */
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

'@
Set-Content -Path '.\lib\queries.ts' -Value $f2 -Encoding UTF8
Write-Host '  created lib\queries.ts' -ForegroundColor Green

$f3 = @'
/**
 * Firebase client SDK — browser only.
 *
 * Used by the /admin dashboard for authentication and writes.
 * Public pages never import this: they read through the Admin SDK at build
 * time (see admin.ts), so visitors trigger zero client-side Firestore reads.
 *
 * NOTE: Firebase Storage is deliberately NOT used. Since February 2026,
 * Cloud Storage for Firebase requires the Blaze plan and a linked billing
 * account even within the free tier. Media is handled by Cloudinary instead
 * (free tier, no card, plus image optimization and video transcoding).
 *
 * The NEXT_PUBLIC_* values below are not secrets. Firebase config is designed
 * to be public — access control lives in firestore.rules, not in these keys.
 */

import { initializeApp, getApps, getApp, type FirebaseApp } from "firebase/app";
import { getAuth, type Auth } from "firebase/auth";
import { getFirestore, type Firestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};

// Next.js hot-reloads modules in dev; re-initializing would throw.
const app: FirebaseApp = getApps().length ? getApp() : initializeApp(firebaseConfig);

export const auth: Auth = getAuth(app);
export const db: Firestore = getFirestore(app);
export default app;

'@
Set-Content -Path '.\lib\firebase\client.ts' -Value $f3 -Encoding UTF8
Write-Host '  created lib\firebase\client.ts' -ForegroundColor Green

$f4 = @'
/**
 * Firebase Admin SDK — server only.
 *
 * Never import this from a "use client" component. It carries a service
 * account private key and would leak into the browser bundle.
 *
 * Used by:
 *   - Server components / ISR page generation (public site reads)
 *   - Route handlers (contact form writes, revalidation hooks)
 *   - The seed script
 *
 * Admin SDK bypasses Firestore security rules entirely, which is exactly
 * what we want for build-time reads of published content.
 */

import "server-only";
import { initializeApp, getApps, getApp, cert, type App } from "firebase-admin/app";
import { getFirestore, type Firestore } from "firebase-admin/firestore";
import { getAuth, type Auth } from "firebase-admin/auth";

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(
      `Missing environment variable: ${name}. ` +
        `Add it to .env.local locally and to Vercel project settings for deploys.`
    );
  }
  return value;
}

function createAdminApp(): App {
  // The private key is stored with literal "\n" sequences because env vars
  // are single-line. Convert them back to real newlines.
  const privateKey = requireEnv("FIREBASE_PRIVATE_KEY").replace(/\\n/g, "\n");

  return initializeApp({
    credential: cert({
      projectId: requireEnv("FIREBASE_PROJECT_ID"),
      clientEmail: requireEnv("FIREBASE_CLIENT_EMAIL"),
      privateKey,
    }),
  });
}

const adminApp: App = getApps().length ? getApp() : createAdminApp();

export const adminDb: Firestore = getFirestore(adminApp);
export const adminAuth: Auth = getAuth(adminApp);
export default adminApp;

'@
Set-Content -Path '.\lib\firebase\admin.ts' -Value $f4 -Encoding UTF8
Write-Host '  created lib\firebase\admin.ts' -ForegroundColor Green

$f5 = @'
/**
 * Firestore seed script.
 *
 * Populates every collection with Oussema's real CV data so the site has
 * something true to render from day one.
 *
 * Run:  npx tsx scripts/seed.ts
 * Wipe: npx tsx scripts/seed.ts --reset
 *
 * Idempotent: documents use fixed IDs, so re-running overwrites rather than
 * duplicating. Case study fields are deliberately left as TODO markers —
 * fill them from the admin once the real narratives are written.
 */

import { config } from "dotenv";
import { initializeApp, cert } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

config({ path: ".env.local" });

const app = initializeApp({
  credential: cert({
    projectId: process.env.FIREBASE_PROJECT_ID!,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL!,
    privateKey: process.env.FIREBASE_PRIVATE_KEY!.replace(/\\n/g, "\n"),
  }),
});

const db = getFirestore(app);
const now = new Date().toISOString();

/* ================================================================== */
/* PROFILE                                                            */
/* ================================================================== */

const profile = {
  fullName: "Oussema Mansouri",
  headline: {
    en: "Mobile Developer & Engineering Educator",
    fr: "Développeur Mobile & Formateur en Ingénierie",
  },
  bio: {
    en: "Mobile developer with 3+ years building native iOS applications with Swift and SwiftUI, cross-platform apps with Flutter, and native Android. I also teach mobile development at TEK-UP, where I supervise student projects and run technical reviews. I care about clean architecture, responsive interfaces, and code other people can maintain.",
    fr: "Développeur mobile avec plus de 3 ans d'expérience dans la création d'applications iOS natives avec Swift et SwiftUI, d'applications multiplateformes avec Flutter, et d'Android natif. J'enseigne également le développement mobile à TEK-UP, où j'encadre des projets étudiants et anime des revues techniques. J'accorde de l'importance à l'architecture propre, aux interfaces réactives et à un code maintenable.",
  },
  photoUrl: "", // TODO: upload via admin
  location: "Tunis, Tunisia",
  email: "oussemamansouri4@gmail.com",
  phone: "+216 53 072 192",
  linkedinUrl: "", // TODO: paste full LinkedIn URL
  githubUrl: "", // TODO: paste GitHub URL
  availabilityStatus: "open" as const,
  cvUrls: { en: "", fr: "" },
  seoDefaults: {
    title: {
      en: "Oussema Mansouri — Mobile Developer (iOS, Flutter, Android) | Tunis",
      fr: "Oussema Mansouri — Développeur Mobile (iOS, Flutter, Android) | Tunis",
    },
    description: {
      en: "Mobile developer and instructor in Tunis. Native iOS with Swift & SwiftUI, cross-platform Flutter, native Android. AWS Certified Cloud Practitioner.",
      fr: "Développeur mobile et formateur à Tunis. iOS natif avec Swift & SwiftUI, Flutter multiplateforme, Android natif. AWS Certified Cloud Practitioner.",
    },
    ogImage: "",
  },
  updatedAt: now,
};

/* ================================================================== */
/* SKILL CATEGORIES                                                   */
/* ================================================================== */

const skillCategories = [
  { id: "mobile", name: { en: "Mobile Development", fr: "Développement Mobile" }, icon: "smartphone", order: 1 },
  { id: "architecture", name: { en: "Mobile Architecture", fr: "Architecture Mobile" }, icon: "layers", order: 2 },
  { id: "backend", name: { en: "Backend & APIs", fr: "Backend & APIs" }, icon: "server", order: 3 },
  { id: "cloud", name: { en: "Cloud & DevOps", fr: "Cloud & DevOps" }, icon: "cloud", order: 4 },
  { id: "tools", name: { en: "Tools & Practices", fr: "Outils & Pratiques" }, icon: "wrench", order: 5 },
];

/* ================================================================== */
/* SKILLS                                                             */
/* Levels: 1 learning · 3 production-comfortable · 5 teach it          */
/* Adjust these honestly from the admin — inflated levels get caught   */
/* in technical interviews.                                            */
/* ================================================================== */

const skills = [
  // Mobile
  { id: "swift", categoryId: "mobile", name: "Swift", level: 5, yearsExperience: 3, icon: "swift", order: 1 },
  { id: "swiftui", categoryId: "mobile", name: "SwiftUI", level: 5, yearsExperience: 3, icon: "swiftui", order: 2 },
  { id: "uikit", categoryId: "mobile", name: "UIKit", level: 4, yearsExperience: 3, icon: "uikit", order: 3 },
  { id: "swift-concurrency", categoryId: "mobile", name: "Swift Concurrency", level: 4, yearsExperience: 2, icon: "async", order: 4 },
  { id: "flutter", categoryId: "mobile", name: "Flutter", level: 5, yearsExperience: 3, icon: "flutter", order: 5 },
  { id: "dart", categoryId: "mobile", name: "Dart", level: 5, yearsExperience: 3, icon: "dart", order: 6 },
  { id: "kotlin", categoryId: "mobile", name: "Kotlin", level: 4, yearsExperience: 2, icon: "kotlin", order: 7 },
  { id: "java-android", categoryId: "mobile", name: "Java (Android)", level: 4, yearsExperience: 3, icon: "java", order: 8 },

  // Architecture
  { id: "mvvm", categoryId: "architecture", name: "MVVM", level: 5, yearsExperience: 3, icon: "diagram", order: 1 },
  { id: "clean-arch", categoryId: "architecture", name: "Clean Architecture", level: 4, yearsExperience: 2, icon: "layers", order: 2 },
  { id: "provider", categoryId: "architecture", name: "Provider", level: 4, yearsExperience: 2, icon: "state", order: 3 },
  { id: "bloc", categoryId: "architecture", name: "Bloc", level: 4, yearsExperience: 2, icon: "state", order: 4 },
  { id: "ui-components", categoryId: "architecture", name: "UI Component Design", level: 5, yearsExperience: 3, icon: "component", order: 5 },

  // Backend
  { id: "rest", categoryId: "backend", name: "REST APIs", level: 5, yearsExperience: 3, icon: "api", order: 1 },
  { id: "json", categoryId: "backend", name: "JSON", level: 5, yearsExperience: 3, icon: "braces", order: 2 },
  { id: "firebase-auth", categoryId: "backend", name: "Firebase Authentication", level: 5, yearsExperience: 3, icon: "firebase", order: 3 },
  { id: "firestore", categoryId: "backend", name: "Cloud Firestore", level: 5, yearsExperience: 3, icon: "firebase", order: 4 },
  { id: "firebase-storage", categoryId: "backend", name: "Firebase Storage", level: 4, yearsExperience: 3, icon: "firebase", order: 5 },

  // Cloud & DevOps
  { id: "aws", categoryId: "cloud", name: "AWS", level: 3, yearsExperience: 2, icon: "aws", order: 1 },
  { id: "docker", categoryId: "cloud", name: "Docker", level: 3, yearsExperience: 2, icon: "docker", order: 2 },
  { id: "cicd", categoryId: "cloud", name: "CI/CD", level: 3, yearsExperience: 2, icon: "pipeline", order: 3 },
  { id: "devsecops", categoryId: "cloud", name: "DevSecOps Practices", level: 3, yearsExperience: 1, icon: "shield", order: 4 },

  // Tools
  { id: "git", categoryId: "tools", name: "Git", level: 5, yearsExperience: 4, icon: "git", order: 1 },
  { id: "gitlab", categoryId: "tools", name: "GitLab", level: 4, yearsExperience: 3, icon: "gitlab", order: 2 },
  { id: "xcode", categoryId: "tools", name: "Xcode", level: 5, yearsExperience: 3, icon: "xcode", order: 3 },
  { id: "android-studio", categoryId: "tools", name: "Android Studio", level: 5, yearsExperience: 3, icon: "android", order: 4 },
  { id: "agile", categoryId: "tools", name: "Agile / Scrum", level: 4, yearsExperience: 3, icon: "kanban", order: 5 },
  { id: "code-review", categoryId: "tools", name: "Code Review", level: 5, yearsExperience: 2, icon: "review", order: 6 },
];

/* ================================================================== */
/* EXPERIENCES                                                        */
/* ================================================================== */

const experiences = [
  {
    id: "tekup-instructor",
    company: "TEK-UP",
    role: {
      en: "Mobile Development Instructor (Flutter, iOS, Android)",
      fr: "Formateur en Développement Mobile (Flutter, iOS, Android)",
    },
    location: "Tunis, Tunisia",
    startDate: "2024-01-01",
    endDate: null,
    description: {
      en: "Teaching mobile development to engineering students across three ecosystems, and supervising their application projects end to end.",
      fr: "Enseignement du développement mobile aux élèves ingénieurs sur trois écosystèmes, et encadrement de leurs projets applicatifs de bout en bout.",
    },
    achievements: [
      { en: "Delivered courses covering Flutter, Swift, SwiftUI, UIKit, Android, REST APIs and Firebase.", fr: "Animé des cours couvrant Flutter, Swift, SwiftUI, UIKit, Android, les APIs REST et Firebase." },
      { en: "Designed practical projects and supervised student mobile application development.", fr: "Conçu des projets pratiques et encadré le développement d'applications mobiles étudiantes." },
      { en: "Guided students in software architecture principles, clean code practices and debugging techniques.", fr: "Guidé les étudiants sur les principes d'architecture logicielle, les bonnes pratiques de code propre et les techniques de débogage." },
      { en: "Conducted technical reviews and supported developers in improving code quality.", fr: "Mené des revues techniques et accompagné les développeurs dans l'amélioration de la qualité du code." },
    ],
    skillIds: ["flutter", "swift", "swiftui", "uikit", "kotlin", "firestore", "code-review"],
    projectIds: [],
    order: 1,
  },
  {
    id: "tekup-ssir",
    company: "TEK-UP",
    role: { en: "SSIR Branch Coordinator", fr: "Coordinateur de la Filière SSIR" },
    location: "Tunis, Tunisia",
    startDate: "2024-01-01",
    endDate: null,
    description: {
      en: "Coordinating academic and technical activities for engineering students, with responsibility for project quality and cross-team collaboration.",
      fr: "Coordination des activités académiques et techniques des élèves ingénieurs, avec responsabilité sur la qualité des projets et la collaboration entre équipes.",
    },
    achievements: [
      { en: "Coordinated academic and technical activities for engineering students.", fr: "Coordonné les activités académiques et techniques des élèves ingénieurs." },
      { en: "Supervised software projects and ensured technical quality and feasibility.", fr: "Supervisé les projets logiciels en garantissant leur qualité technique et leur faisabilité." },
      { en: "Managed collaboration between students, instructors and administration teams.", fr: "Géré la collaboration entre étudiants, formateurs et équipes administratives." },
      { en: "Supported project planning, evaluation and continuous improvement processes.", fr: "Accompagné la planification, l'évaluation et les processus d'amélioration continue des projets." },
    ],
    skillIds: ["agile", "code-review"],
    projectIds: [],
    order: 2,
  },
  {
    id: "mosofty-ios",
    company: "Mosofty",
    role: { en: "iOS Developer", fr: "Développeur iOS" },
    location: "Tunisia",
    startDate: "2023-01-01",
    endDate: "2023-12-31",
    description: {
      en: "Built Maktoub, a mobile marketplace application for iOS, from interface design through API integration.",
      fr: "Développement de Maktoub, une application marketplace mobile pour iOS, de la conception d'interface à l'intégration des APIs.",
    },
    achievements: [
      { en: "Developed an iOS marketplace application using SwiftUI.", fr: "Développé une application marketplace iOS avec SwiftUI." },
      { en: "Designed smooth and responsive interfaces following Apple's Human Interface Guidelines.", fr: "Conçu des interfaces fluides et réactives suivant les Human Interface Guidelines d'Apple." },
      { en: "Integrated APIs and multimedia features supporting core application functionality.", fr: "Intégré les APIs et fonctionnalités multimédia soutenant les fonctionnalités principales." },
      { en: "Improved user experience through UI optimization and performance work.", fr: "Amélioré l'expérience utilisateur par l'optimisation de l'UI et des performances." },
    ],
    skillIds: ["swift", "swiftui", "rest", "mvvm"],
    projectIds: ["maktoub"],
    order: 3,
  },
];

/* ================================================================== */
/* PROJECTS                                                           */
/* Case study fields are placeholders — this is the content work that  */
/* actually converts recruiters. Write them properly in the admin.     */
/* ================================================================== */

const TODO_EN = "TODO — write this section.";
const TODO_FR = "À RÉDIGER.";
const todo = { en: TODO_EN, fr: TODO_FR };

const projects = [
  {
    id: "maktoub",
    slug: "maktoub-marketplace",
    title: { en: "Maktoub — Mobile Marketplace", fr: "Maktoub — Marketplace Mobile" },
    summary: {
      en: "An iOS marketplace application built with SwiftUI, featuring API-driven listings, multimedia content and a responsive interface following Apple design principles.",
      fr: "Une application marketplace iOS développée avec SwiftUI, avec des annonces pilotées par API, du contenu multimédia et une interface réactive suivant les principes de design d'Apple.",
    },
    caseStudy: {
      context: todo,
      problem: todo,
      role: {
        en: "iOS Developer — responsible for the SwiftUI interface layer, API integration and performance optimization.",
        fr: "Développeur iOS — responsable de la couche d'interface SwiftUI, de l'intégration des APIs et de l'optimisation des performances.",
      },
      technicalDecisions: todo,
      challenges: todo,
      result: todo,
    },
    type: "professional" as const,
    featured: true,
    order: 1,
    coverImageUrl: "",
    media: [],
    metrics: [],
    links: {},
    skillIds: ["swift", "swiftui", "rest", "mvvm", "ui-components"],
    status: "draft" as const,
    createdAt: now,
    publishedAt: null,
  },
  {
    id: "ios-swiftui-firebase",
    slug: "ios-swiftui-firebase-apps",
    title: { en: "iOS Applications — SwiftUI & Firebase", fr: "Applications iOS — SwiftUI & Firebase" },
    summary: {
      en: "A set of iOS applications built with Swift and SwiftUI, using Firebase Authentication for user management, with animations, form validation and state management.",
      fr: "Un ensemble d'applications iOS développées avec Swift et SwiftUI, utilisant Firebase Authentication pour la gestion des utilisateurs, avec animations, validation de formulaires et gestion d'état.",
    },
    caseStudy: {
      context: todo,
      problem: todo,
      role: { en: "Sole developer.", fr: "Développeur unique." },
      technicalDecisions: todo,
      challenges: todo,
      result: todo,
    },
    type: "personal" as const,
    featured: true,
    order: 2,
    coverImageUrl: "",
    media: [],
    metrics: [],
    links: {},
    skillIds: ["swift", "swiftui", "firebase-auth", "firestore", "swift-concurrency"],
    status: "draft" as const,
    createdAt: now,
    publishedAt: null,
  },
  {
    id: "flutter-cross-platform",
    slug: "flutter-cross-platform-apps",
    title: { en: "Cross-Platform Applications — Flutter", fr: "Applications Multiplateformes — Flutter" },
    summary: {
      en: "Android and iOS applications built with Flutter and Dart, using reusable UI components, Provider and Bloc state management, REST API integration and clean architecture principles.",
      fr: "Applications Android et iOS développées avec Flutter et Dart, avec des composants UI réutilisables, la gestion d'état Provider et Bloc, l'intégration d'APIs REST et les principes d'architecture propre.",
    },
    caseStudy: {
      context: todo,
      problem: todo,
      role: { en: "Sole developer.", fr: "Développeur unique." },
      technicalDecisions: todo,
      challenges: todo,
      result: todo,
    },
    type: "personal" as const,
    featured: true,
    order: 3,
    coverImageUrl: "",
    media: [],
    metrics: [],
    links: {},
    skillIds: ["flutter", "dart", "provider", "bloc", "clean-arch", "rest"],
    status: "draft" as const,
    createdAt: now,
    publishedAt: null,
  },
  {
    id: "android-native",
    slug: "android-native-apps",
    title: { en: "Native Android Applications — Java & Kotlin", fr: "Applications Android Natives — Java & Kotlin" },
    summary: {
      en: "Native Android applications built with Java and Kotlin, covering UI components, navigation, local storage and API integration.",
      fr: "Applications Android natives développées avec Java et Kotlin, couvrant les composants UI, la navigation, le stockage local et l'intégration d'APIs.",
    },
    caseStudy: {
      context: todo,
      problem: todo,
      role: { en: "Sole developer.", fr: "Développeur unique." },
      technicalDecisions: todo,
      challenges: todo,
      result: todo,
    },
    type: "personal" as const,
    featured: false,
    order: 4,
    coverImageUrl: "",
    media: [],
    metrics: [],
    links: {},
    skillIds: ["kotlin", "java-android", "rest"],
    status: "draft" as const,
    createdAt: now,
    publishedAt: null,
  },
];

/* ================================================================== */
/* EDUCATION / CERTIFICATIONS / SERVICES                              */
/* ================================================================== */

const education = [
  {
    id: "tekup-engineering",
    institution: "TEK-UP College of Engineering & Technology",
    degree: { en: "Engineering Degree in Computer Science", fr: "Diplôme d'Ingénieur en Informatique" },
    specialization: {
      en: "Web, Mobile & Multimedia Development",
      fr: "Développement Web, Mobile & Multimédia",
    },
    startYear: 2020,
    endYear: 2023,
    order: 1,
  },
  {
    id: "iset-mahdia",
    institution: "ISET Mahdia",
    degree: { en: "Bachelor's Degree in Information Technology", fr: "Licence en Technologies de l'Information" },
    specialization: { en: "", fr: "" },
    startYear: 2017,
    endYear: 2020,
    order: 2,
  },
];

const certifications = [
  {
    id: "aws-ccp",
    name: "AWS Certified Cloud Practitioner",
    issuer: "Amazon Web Services",
    issueDate: "2023-01-01",
    credentialUrl: "", // TODO: paste Credly badge URL — verifiable beats claimed
    badgeImageUrl: "",
    order: 1,
  },
];

const services = [
  {
    id: "mobile-development",
    title: { en: "Mobile Application Development", fr: "Développement d'Applications Mobiles" },
    description: {
      en: "Native iOS applications with Swift and SwiftUI, or cross-platform apps with Flutter — from architecture through App Store delivery.",
      fr: "Applications iOS natives avec Swift et SwiftUI, ou applications multiplateformes avec Flutter — de l'architecture à la publication sur l'App Store.",
    },
    deliverables: [
      { en: "Architecture and technical specification", fr: "Architecture et spécification technique" },
      { en: "Production application, iOS and/or Android", fr: "Application en production, iOS et/ou Android" },
      { en: "API and Firebase integration", fr: "Intégration API et Firebase" },
      { en: "Store submission support", fr: "Accompagnement à la publication sur les stores" },
    ],
    icon: "smartphone",
    order: 1,
  },
  {
    id: "technical-training",
    title: { en: "Technical Training & Workshops", fr: "Formation Technique & Ateliers" },
    description: {
      en: "Mobile development training for teams and cohorts — Flutter, Swift/SwiftUI, Android — built around practical projects rather than slides.",
      fr: "Formation en développement mobile pour équipes et promotions — Flutter, Swift/SwiftUI, Android — construite autour de projets pratiques plutôt que de diapositives.",
    },
    deliverables: [
      { en: "Tailored curriculum", fr: "Programme sur mesure" },
      { en: "Hands-on project work", fr: "Travaux pratiques sur projet" },
      { en: "Code review sessions", fr: "Sessions de revue de code" },
      { en: "Course materials", fr: "Supports de cours" },
    ],
    icon: "graduation-cap",
    order: 2,
  },
  {
    id: "code-review-consulting",
    title: { en: "Code Review & Consulting", fr: "Revue de Code & Conseil" },
    description: {
      en: "Architecture review and code quality auditing for existing mobile codebases, with a written report and prioritized recommendations.",
      fr: "Revue d'architecture et audit de qualité de code pour bases de code mobiles existantes, avec rapport écrit et recommandations priorisées.",
    },
    deliverables: [
      { en: "Architecture assessment", fr: "Évaluation de l'architecture" },
      { en: "Written audit report", fr: "Rapport d'audit écrit" },
      { en: "Prioritized action list", fr: "Liste d'actions priorisées" },
    ],
    icon: "search-check",
    order: 3,
  },
];

/* ================================================================== */
/* RUNNER                                                             */
/* ================================================================== */

async function writeCollection(name: string, docs: Array<{ id: string } & Record<string, unknown>>) {
  const batch = db.batch();
  for (const { id, ...data } of docs) {
    batch.set(db.collection(name).doc(id), data, { merge: false });
  }
  await batch.commit();
  console.log(`  ${name.padEnd(18)} ${docs.length} document(s)`);
}

async function resetCollections() {
  const names = [
    "projects", "skills", "skillCategories", "experiences",
    "education", "certifications", "services", "settings", "stats",
  ];
  console.log("Wiping collections...");
  for (const name of names) {
    const snap = await db.collection(name).get();
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    console.log(`  cleared ${name} (${snap.size})`);
  }
}

async function seed() {
  if (process.argv.includes("--reset")) {
    await resetCollections();
    console.log("");
  }

  console.log("Seeding Firestore...\n");

  await db.collection("settings").doc("profile").set(profile);
  console.log(`  settings/profile   1 document`);

  await writeCollection("skillCategories", skillCategories);
  await writeCollection("skills", skills);
  await writeCollection("experiences", experiences);
  await writeCollection("projects", projects);
  await writeCollection("education", education);
  await writeCollection("certifications", certifications);
  await writeCollection("services", services);

  await db.collection("stats").doc("counters").set({
    cvDownloads: { en: 0, fr: 0 },
    projectViews: {},
  });
  console.log(`  stats/counters     1 document`);

  console.log("\nDone.\n");
  console.log("Next steps:");
  console.log("  1. Fill in linkedinUrl, githubUrl and the AWS credentialUrl");
  console.log("  2. Write the Maktoub case study — it is the strongest asset on the site");
  console.log("  3. Flip projects from draft to published once they have real media");
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("\nSeed failed:", err);
    process.exit(1);
  });

'@
Set-Content -Path '.\scripts\seed.ts' -Value $f5 -Encoding UTF8
Write-Host '  created scripts\seed.ts' -ForegroundColor Green


Write-Host ""
Write-Host "Done. Files created:" -ForegroundColor Cyan
Get-ChildItem -Recurse -Path ".\lib",".\scripts",".\firestore.rules" -File |
  Select-Object @{n='File';e={$_.FullName.Replace($PWD.Path + '\','')}}, Length |
  Format-Table -AutoSize

Write-Host "NEXT: open firestore.rules and replace REPLACE_WITH_YOUR_UID" -ForegroundColor Yellow
