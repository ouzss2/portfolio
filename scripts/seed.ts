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
 * duplicating. Case study fields are deliberately left as TODO markers â€”
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
    fr: "DÃ©veloppeur Mobile & Formateur en IngÃ©nierie",
  },
  bio: {
    en: "Mobile developer with 3+ years building native iOS applications with Swift and SwiftUI, cross-platform apps with Flutter, and native Android. I also teach mobile development at TEK-UP, where I supervise student projects and run technical reviews. I care about clean architecture, responsive interfaces, and code other people can maintain.",
    fr: "DÃ©veloppeur mobile avec plus de 3 ans d'expÃ©rience dans la crÃ©ation d'applications iOS natives avec Swift et SwiftUI, d'applications multiplateformes avec Flutter, et d'Android natif. J'enseigne Ã©galement le dÃ©veloppement mobile Ã  TEK-UP, oÃ¹ j'encadre des projets Ã©tudiants et anime des revues techniques. J'accorde de l'importance Ã  l'architecture propre, aux interfaces rÃ©actives et Ã  un code maintenable.",
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
      en: "Oussema Mansouri â€” Mobile Developer (iOS, Flutter, Android) | Tunis",
      fr: "Oussema Mansouri â€” DÃ©veloppeur Mobile (iOS, Flutter, Android) | Tunis",
    },
    description: {
      en: "Mobile developer and instructor in Tunis. Native iOS with Swift & SwiftUI, cross-platform Flutter, native Android. AWS Certified Cloud Practitioner.",
      fr: "DÃ©veloppeur mobile et formateur Ã  Tunis. iOS natif avec Swift & SwiftUI, Flutter multiplateforme, Android natif. AWS Certified Cloud Practitioner.",
    },
    ogImage: "",
  },
  updatedAt: now,
};

/* ================================================================== */
/* SKILL CATEGORIES                                                   */
/* ================================================================== */

const skillCategories = [
  { id: "mobile", name: { en: "Mobile Development", fr: "DÃ©veloppement Mobile" }, icon: "smartphone", order: 1 },
  { id: "architecture", name: { en: "Mobile Architecture", fr: "Architecture Mobile" }, icon: "layers", order: 2 },
  { id: "backend", name: { en: "Backend & APIs", fr: "Backend & APIs" }, icon: "server", order: 3 },
  { id: "cloud", name: { en: "Cloud & DevOps", fr: "Cloud & DevOps" }, icon: "cloud", order: 4 },
  { id: "tools", name: { en: "Tools & Practices", fr: "Outils & Pratiques" }, icon: "wrench", order: 5 },
];

/* ================================================================== */
/* SKILLS                                                             */
/* Levels: 1 learning Â· 3 production-comfortable Â· 5 teach it          */
/* Adjust these honestly from the admin â€” inflated levels get caught   */
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
      fr: "Formateur en DÃ©veloppement Mobile (Flutter, iOS, Android)",
    },
    location: "Tunis, Tunisia",
    startDate: "2024-01-01",
    endDate: null,
    description: {
      en: "Teaching mobile development to engineering students across three ecosystems, and supervising their application projects end to end.",
      fr: "Enseignement du dÃ©veloppement mobile aux Ã©lÃ¨ves ingÃ©nieurs sur trois Ã©cosystÃ¨mes, et encadrement de leurs projets applicatifs de bout en bout.",
    },
    achievements: [
      { en: "Delivered courses covering Flutter, Swift, SwiftUI, UIKit, Android, REST APIs and Firebase.", fr: "AnimÃ© des cours couvrant Flutter, Swift, SwiftUI, UIKit, Android, les APIs REST et Firebase." },
      { en: "Designed practical projects and supervised student mobile application development.", fr: "ConÃ§u des projets pratiques et encadrÃ© le dÃ©veloppement d'applications mobiles Ã©tudiantes." },
      { en: "Guided students in software architecture principles, clean code practices and debugging techniques.", fr: "GuidÃ© les Ã©tudiants sur les principes d'architecture logicielle, les bonnes pratiques de code propre et les techniques de dÃ©bogage." },
      { en: "Conducted technical reviews and supported developers in improving code quality.", fr: "MenÃ© des revues techniques et accompagnÃ© les dÃ©veloppeurs dans l'amÃ©lioration de la qualitÃ© du code." },
    ],
    skillIds: ["flutter", "swift", "swiftui", "uikit", "kotlin", "firestore", "code-review"],
    projectIds: [],
    order: 1,
  },
  {
    id: "tekup-ssir",
    company: "TEK-UP",
    role: { en: "SSIR Branch Coordinator", fr: "Coordinateur de la FiliÃ¨re SSIR" },
    location: "Tunis, Tunisia",
    startDate: "2024-01-01",
    endDate: null,
    description: {
      en: "Coordinating academic and technical activities for engineering students, with responsibility for project quality and cross-team collaboration.",
      fr: "Coordination des activitÃ©s acadÃ©miques et techniques des Ã©lÃ¨ves ingÃ©nieurs, avec responsabilitÃ© sur la qualitÃ© des projets et la collaboration entre Ã©quipes.",
    },
    achievements: [
      { en: "Coordinated academic and technical activities for engineering students.", fr: "CoordonnÃ© les activitÃ©s acadÃ©miques et techniques des Ã©lÃ¨ves ingÃ©nieurs." },
      { en: "Supervised software projects and ensured technical quality and feasibility.", fr: "SupervisÃ© les projets logiciels en garantissant leur qualitÃ© technique et leur faisabilitÃ©." },
      { en: "Managed collaboration between students, instructors and administration teams.", fr: "GÃ©rÃ© la collaboration entre Ã©tudiants, formateurs et Ã©quipes administratives." },
      { en: "Supported project planning, evaluation and continuous improvement processes.", fr: "AccompagnÃ© la planification, l'Ã©valuation et les processus d'amÃ©lioration continue des projets." },
    ],
    skillIds: ["agile", "code-review"],
    projectIds: [],
    order: 2,
  },
  {
    id: "mosofty-ios",
    company: "Mosofty",
    role: { en: "iOS Developer", fr: "DÃ©veloppeur iOS" },
    location: "Tunisia",
    startDate: "2023-01-01",
    endDate: "2023-12-31",
    description: {
      en: "Built Maktoub, a mobile marketplace application for iOS, from interface design through API integration.",
      fr: "DÃ©veloppement de Maktoub, une application marketplace mobile pour iOS, de la conception d'interface Ã  l'intÃ©gration des APIs.",
    },
    achievements: [
      { en: "Developed an iOS marketplace application using SwiftUI.", fr: "DÃ©veloppÃ© une application marketplace iOS avec SwiftUI." },
      { en: "Designed smooth and responsive interfaces following Apple's Human Interface Guidelines.", fr: "ConÃ§u des interfaces fluides et rÃ©actives suivant les Human Interface Guidelines d'Apple." },
      { en: "Integrated APIs and multimedia features supporting core application functionality.", fr: "IntÃ©grÃ© les APIs et fonctionnalitÃ©s multimÃ©dia soutenant les fonctionnalitÃ©s principales." },
      { en: "Improved user experience through UI optimization and performance work.", fr: "AmÃ©liorÃ© l'expÃ©rience utilisateur par l'optimisation de l'UI et des performances." },
    ],
    skillIds: ["swift", "swiftui", "rest", "mvvm"],
    projectIds: ["maktoub"],
    order: 3,
  },
];

/* ================================================================== */
/* PROJECTS                                                           */
/* Case study fields are placeholders â€” this is the content work that  */
/* actually converts recruiters. Write them properly in the admin.     */
/* ================================================================== */

const TODO_EN = "TODO â€” write this section.";
const TODO_FR = "Ã€ RÃ‰DIGER.";
const todo = { en: TODO_EN, fr: TODO_FR };

const projects = [
  {
    id: "maktoub",
    slug: "maktoub-marketplace",
    title: { en: "Maktoub â€” Mobile Marketplace", fr: "Maktoub â€” Marketplace Mobile" },
    summary: {
      en: "An iOS marketplace application built with SwiftUI, featuring API-driven listings, multimedia content and a responsive interface following Apple design principles.",
      fr: "Une application marketplace iOS dÃ©veloppÃ©e avec SwiftUI, avec des annonces pilotÃ©es par API, du contenu multimÃ©dia et une interface rÃ©active suivant les principes de design d'Apple.",
    },
    caseStudy: {
      context: todo,
      problem: todo,
      role: {
        en: "iOS Developer â€” responsible for the SwiftUI interface layer, API integration and performance optimization.",
        fr: "DÃ©veloppeur iOS â€” responsable de la couche d'interface SwiftUI, de l'intÃ©gration des APIs et de l'optimisation des performances.",
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
    title: { en: "iOS Applications â€” SwiftUI & Firebase", fr: "Applications iOS â€” SwiftUI & Firebase" },
    summary: {
      en: "A set of iOS applications built with Swift and SwiftUI, using Firebase Authentication for user management, with animations, form validation and state management.",
      fr: "Un ensemble d'applications iOS dÃ©veloppÃ©es avec Swift et SwiftUI, utilisant Firebase Authentication pour la gestion des utilisateurs, avec animations, validation de formulaires et gestion d'Ã©tat.",
    },
    caseStudy: {
      context: todo,
      problem: todo,
      role: { en: "Sole developer.", fr: "DÃ©veloppeur unique." },
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
    title: { en: "Cross-Platform Applications â€” Flutter", fr: "Applications Multiplateformes â€” Flutter" },
    summary: {
      en: "Android and iOS applications built with Flutter and Dart, using reusable UI components, Provider and Bloc state management, REST API integration and clean architecture principles.",
      fr: "Applications Android et iOS dÃ©veloppÃ©es avec Flutter et Dart, avec des composants UI rÃ©utilisables, la gestion d'Ã©tat Provider et Bloc, l'intÃ©gration d'APIs REST et les principes d'architecture propre.",
    },
    caseStudy: {
      context: todo,
      problem: todo,
      role: { en: "Sole developer.", fr: "DÃ©veloppeur unique." },
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
    title: { en: "Native Android Applications â€” Java & Kotlin", fr: "Applications Android Natives â€” Java & Kotlin" },
    summary: {
      en: "Native Android applications built with Java and Kotlin, covering UI components, navigation, local storage and API integration.",
      fr: "Applications Android natives dÃ©veloppÃ©es avec Java et Kotlin, couvrant les composants UI, la navigation, le stockage local et l'intÃ©gration d'APIs.",
    },
    caseStudy: {
      context: todo,
      problem: todo,
      role: { en: "Sole developer.", fr: "DÃ©veloppeur unique." },
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
    degree: { en: "Engineering Degree in Computer Science", fr: "DiplÃ´me d'IngÃ©nieur en Informatique" },
    specialization: {
      en: "Web, Mobile & Multimedia Development",
      fr: "DÃ©veloppement Web, Mobile & MultimÃ©dia",
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
    credentialUrl: "", // TODO: paste Credly badge URL â€” verifiable beats claimed
    badgeImageUrl: "",
    order: 1,
  },
];

const services = [
  {
    id: "mobile-development",
    title: { en: "Mobile Application Development", fr: "DÃ©veloppement d'Applications Mobiles" },
    description: {
      en: "Native iOS applications with Swift and SwiftUI, or cross-platform apps with Flutter â€” from architecture through App Store delivery.",
      fr: "Applications iOS natives avec Swift et SwiftUI, ou applications multiplateformes avec Flutter â€” de l'architecture Ã  la publication sur l'App Store.",
    },
    deliverables: [
      { en: "Architecture and technical specification", fr: "Architecture et spÃ©cification technique" },
      { en: "Production application, iOS and/or Android", fr: "Application en production, iOS et/ou Android" },
      { en: "API and Firebase integration", fr: "IntÃ©gration API et Firebase" },
      { en: "Store submission support", fr: "Accompagnement Ã  la publication sur les stores" },
    ],
    icon: "smartphone",
    order: 1,
  },
  {
    id: "technical-training",
    title: { en: "Technical Training & Workshops", fr: "Formation Technique & Ateliers" },
    description: {
      en: "Mobile development training for teams and cohorts â€” Flutter, Swift/SwiftUI, Android â€” built around practical projects rather than slides.",
      fr: "Formation en dÃ©veloppement mobile pour Ã©quipes et promotions â€” Flutter, Swift/SwiftUI, Android â€” construite autour de projets pratiques plutÃ´t que de diapositives.",
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
      fr: "Revue d'architecture et audit de qualitÃ© de code pour bases de code mobiles existantes, avec rapport Ã©crit et recommandations priorisÃ©es.",
    },
    deliverables: [
      { en: "Architecture assessment", fr: "Ã‰valuation de l'architecture" },
      { en: "Written audit report", fr: "Rapport d'audit Ã©crit" },
      { en: "Prioritized action list", fr: "Liste d'actions priorisÃ©es" },
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
  console.log("  2. Write the Maktoub case study â€” it is the strongest asset on the site");
  console.log("  3. Flip projects from draft to published once they have real media");
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("\nSeed failed:", err);
    process.exit(1);
  });

