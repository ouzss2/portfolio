import type { Locale } from "@/lib/types";

/**
 * Interface strings.
 *
 * Only chrome lives here - section labels, buttons, the few sentences not
 * stored in Firestore. Everything substantive (bio, project narratives,
 * achievements) is already bilingual in the database, so this file stays
 * small on purpose.
 *
 * Typed against the English keys, so a missing French string is a build
 * error rather than an English word appearing on a French page.
 */

export const LOCALES: Locale[] = ["en", "fr"];
export const DEFAULT_LOCALE: Locale = "en";

export function isLocale(value: string): value is Locale {
  return LOCALES.includes(value as Locale);
}

const en = {
  // hero
  heroSub:
    "Mobile developer and instructor at TEK-UP. Three years shipping native iOS, cross-platform Flutter, and native Android.",
  heroEditorNote: "HeroCard - shared across all three targets",
  heroHint: "Edit the code - all three devices update as you type",
  heroHintTouched: "One edit, three platforms. That is the job.",
  reloading: "reloading...",
  live: "live",
  compiledIn: "compiled in",
  tint: "tint",
  radius: "radius",

  // availability
  available: "Available for work",
  open: "Open to offers",
  unavailable: "Not available",

  // sections
  selectedWork: "Selected work",
  allProjects: "All projects",
  readCaseStudy: "Read the case study",
  noProjects:
    "No published projects yet. Case studies appear once they have a real narrative and a recording of the app running.",

  teaching: "Teaching",
  teachingTitle: "I teach the stack I build in.",
  teachingBody:
    "Since 2024 I have taught mobile development to engineering students at TEK-UP, supervised their application projects end to end, and run the technical reviews. Explaining an architecture decision to twenty students is a different skill from making it, and it makes the decisions better.",
  taught: "Taught",
  present: "present",

  stack: "Stack",
  stackNote:
    "Levels run 1 to 5, where 3 is production comfortable and 5 means I teach it. Rated honestly, because an inflated number gets caught in the first technical round.",
  certification: "Certification",
  verify: "Verify",

  // contact
  contact: "Contact",
  contactTitle: "Hiring, or building something mobile?",
  contactBody:
    "Based in Tunis, open to remote and relocation. I reply within two working days.",
  name: "Name",
  email: "Email",
  company: "Company",
  optional: "(optional)",
  about: "About",
  message: "Message",
  send: "Send message",
  sending: "Sending...",
  sent: "Message received.",
  sentBody: "I reply within two working days. If it is urgent, email me directly at",
  sendFailed: "That did not send. Email me directly at",
  subjectJob: "A role",
  subjectFreelance: "Freelance work",
  subjectTraining: "Training",
  subjectOther: "Something else",
  downloadCv: "Download CV",
  builtWith:
    "Built with Next.js and Firestore. Content managed from a custom admin.",

  // projects pages
  projects: "Projects",
  back: "Back",
  all: "All",
  nothingHere:
    "Nothing published here yet. Case studies appear once they have a real narrative and a recording of the app running.",
  context: "Context",
  problem: "The problem",
  role: "My role",
  decisions: "Technical decisions",
  challenges: "Challenges",
  result: "Result",
  links: "Links",
  next: "Next",
  getInTouch: "Get in touch",
  writeupInProgress: "The write-up for this project is still in progress.",
} as const;

const fr: Record<keyof typeof en, string> = {
  heroSub:
    "D\u00e9veloppeur mobile et formateur \u00e0 TEK-UP. Trois ans \u00e0 livrer de l'iOS natif, du Flutter multiplateforme et de l'Android natif.",
  heroEditorNote: "HeroCard - partag\u00e9 par les trois cibles",
  heroHint: "Modifiez le code - les trois appareils se mettent \u00e0 jour",
  heroHintTouched: "Une modification, trois plateformes. C'est le m\u00e9tier.",
  reloading: "rechargement...",
  live: "en direct",
  compiledIn: "compil\u00e9 en",
  tint: "teinte",
  radius: "rayon",

  available: "Disponible",
  open: "Ouvert aux opportunit\u00e9s",
  unavailable: "Non disponible",

  selectedWork: "Travaux s\u00e9lectionn\u00e9s",
  allProjects: "Tous les projets",
  readCaseStudy: "Lire l'\u00e9tude de cas",
  noProjects:
    "Aucun projet publi\u00e9 pour l'instant. Les \u00e9tudes de cas apparaissent une fois qu'elles ont un vrai r\u00e9cit et un enregistrement de l'application.",

  teaching: "Enseignement",
  teachingTitle: "J'enseigne la stack que je pratique.",
  teachingBody:
    "Depuis 2024, j'enseigne le d\u00e9veloppement mobile aux \u00e9l\u00e8ves ing\u00e9nieurs de TEK-UP, j'encadre leurs projets applicatifs de bout en bout et j'anime les revues techniques. Expliquer une d\u00e9cision d'architecture \u00e0 vingt \u00e9tudiants est une comp\u00e9tence diff\u00e9rente de celle de la prendre, et cela rend les d\u00e9cisions meilleures.",
  taught: "Enseign\u00e9",
  present: "aujourd'hui",

  stack: "Stack",
  stackNote:
    "Les niveaux vont de 1 \u00e0 5, o\u00f9 3 signifie \u00e0 l'aise en production et 5 signifie que je l'enseigne. \u00c9valu\u00e9s honn\u00eatement, car un chiffre gonfl\u00e9 se voit d\u00e8s le premier entretien technique.",
  certification: "Certification",
  verify: "V\u00e9rifier",

  contact: "Contact",
  contactTitle: "Vous recrutez, ou vous construisez du mobile ?",
  contactBody:
    "Bas\u00e9 \u00e0 Tunis, ouvert au distanciel et \u00e0 la mobilit\u00e9. Je r\u00e9ponds sous deux jours ouvr\u00e9s.",
  name: "Nom",
  email: "Email",
  company: "Entreprise",
  optional: "(facultatif)",
  about: "Sujet",
  message: "Message",
  send: "Envoyer",
  sending: "Envoi...",
  sent: "Message bien re\u00e7u.",
  sentBody:
    "Je r\u00e9ponds sous deux jours ouvr\u00e9s. Si c'est urgent, \u00e9crivez-moi directement \u00e0",
  sendFailed: "L'envoi a \u00e9chou\u00e9. \u00c9crivez-moi directement \u00e0",
  subjectJob: "Un poste",
  subjectFreelance: "Une mission freelance",
  subjectTraining: "Une formation",
  subjectOther: "Autre chose",
  downloadCv: "T\u00e9l\u00e9charger le CV",
  builtWith:
    "R\u00e9alis\u00e9 avec Next.js et Firestore. Contenu g\u00e9r\u00e9 depuis un back-office sur mesure.",

  projects: "Projets",
  back: "Retour",
  all: "Tous",
  nothingHere:
    "Rien de publi\u00e9 ici pour l'instant. Les \u00e9tudes de cas apparaissent une fois qu'elles ont un vrai r\u00e9cit et un enregistrement de l'application.",
  context: "Contexte",
  problem: "Le probl\u00e8me",
  role: "Mon r\u00f4le",
  decisions: "D\u00e9cisions techniques",
  challenges: "Difficult\u00e9s",
  result: "R\u00e9sultat",
  links: "Liens",
  next: "Suite",
  getInTouch: "Me contacter",
  writeupInProgress: "La r\u00e9daction de ce projet est encore en cours.",
};

export type Dict = typeof en;

const DICTS: Record<Locale, Dict> = { en, fr: fr as Dict };

export function getDict(locale: Locale): Dict {
  return DICTS[locale] ?? DICTS.en;
}

/** Swap the locale segment of a path, for the language toggle. */
export function switchLocalePath(pathname: string, next: Locale): string {
  const parts = pathname.split("/").filter(Boolean);
  if (parts.length > 0 && isLocale(parts[0])) {
    parts[0] = next;
    return "/" + parts.join("/");
  }
  return `/${next}${pathname}`;
}
