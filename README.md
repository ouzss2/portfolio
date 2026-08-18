# Portfolio

A bilingual portfolio platform for a mobile developer, built so that every piece of content is editable without touching code.

**Live:** [oussemamansouri.vercel.app](https://oussemamansouri.vercel.app)

---

## What this is

Next.js 15 App Router, TypeScript, Tailwind CSS. Content lives in Cloud Firestore and is managed through a custom admin at `/admin`. Media goes to Cloudinary. Deployed on Vercel.

Public pages are statically generated with on-demand revalidation, so a visitor triggers zero database reads and an admin save appears on the site immediately.

---

## Architecture

```
Browser ──> Vercel (Next.js, ISR)
                │
                ├── build time: Firebase Admin SDK ──> Firestore
                └── /admin:     Firebase Client SDK ──> Firestore
                                                        (writes gated by
                                                         security rules)
Media ─────> Cloudinary (signed uploads, delivery transforms)
```

**Reads** happen at build time through the Admin SDK. **Writes** happen from the browser through the client SDK, constrained by Firestore security rules rather than by an API layer.

---

## Decisions worth explaining

### Next.js rather than Flutter Web

The obvious choice for a mobile developer's portfolio would have been Flutter Web. It was the wrong one. Flutter Web ships a large initial bundle, renders to canvas, and is poorly indexed by search engines. The entire purpose of this site is to be found by someone searching for a mobile developer, so server-rendered HTML was non-negotiable.

### Firestore rules as the security boundary

The admin writes directly to Firestore from the browser. There is no API layer in between, because there does not need to be: `firestore.rules` permits writes only from one specific auth UID, and public reads only where `status == "published"`. Hiding the admin UI behind a login is convenience. The rules are the actual protection.

### Cloudinary instead of Firebase Storage

Since February 2026, Cloud Storage for Firebase requires a linked billing account even inside the free tier. Cloudinary is free without a card, and more importantly transcodes video on delivery. The strongest content on a mobile portfolio is a recording of an app running, and a raw phone capture is unusable at its original size.

PDFs upload as `raw` rather than `image`. The image pipeline rasterises a PDF, so `f_auto` returns a JPEG of page one instead of the document.

### Uploads signed, not proxied

Files go from the browser straight to Cloudinary, signed by a route that verifies a Firebase ID token belongs to the owner UID. Proxying video through Vercel would hit the request body limit; an unsigned preset would let anyone who found the cloud name fill the account.

### Locale routing rather than a toggle

`/en` and `/fr` are separate indexable URLs with `hreflang` alternates and a sitemap listing both. A client-side language switch would be invisible to a search engine, which defeats the point of having a French version. Middleware reads `Accept-Language` and redirects a bare `/` accordingly.

Two root layouts via route groups: the public site sets `<html lang>` per locale, the admin stays English and is marked `noindex`.

### Publish gating

A project cannot be published until four of its six case study sections are written. The constraint is deliberate: an unfinished case study on a live portfolio is worse than no case study, and the easiest way to damage the site is to ship placeholder text.

### Encoding

Every source file is pure ASCII. Accented characters are written as `\uXXXX` escapes and special characters as HTML entities. This is not stylistic. The build tooling runs on Windows PowerShell 5.1, which guesses Windows-1252 for files without a BOM, and Firestore's rules parser rejects files with one. French is roughly one in eight characters accented, so a pipeline that cannot carry `é` safely cannot carry the site.

---

## Data model

Firestore, document-oriented. Bilingual fields are nested maps rather than parallel documents:

```
settings/profile          headline: { en, fr }, availabilityStatus, cvUrls
projects/{id}             caseStudy: { context, problem, role,
                            technicalDecisions, challenges, result }
                          each of which is { en, fr }
                          skillIds: [] denormalised join
skills/{id}               categoryId, level 1-5, yearsExperience
skillCategories/{id}      name: { en, fr }, order
experiences/{id}          achievements: [{ en, fr }]
education, certifications, services, articles, testimonials
messages/{id}             write-only from the public side
```

Ordering is explicit (`order` field), never document ID order. Six composite indexes are declared in `firestore.indexes.json` and deployed from it.

---

## Local setup

```bash
git clone https://github.com/ouzss2/portfolio
cd portfolio
npm install
cp .env.local.example .env.local   # then fill it in
npm run seed                       # populate Firestore
npm run dev
```

### Environment

| Variable | Where it comes from |
|---|---|
| `NEXT_PUBLIC_FIREBASE_*` | Firebase console, web app config. Public by design. |
| `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` | Service account JSON. Server only. |
| `NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME` | Cloudinary dashboard |
| `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` | Cloudinary dashboard. Server only. |
| `ADMIN_UID` | Firebase Authentication user UID |
| `NEXT_PUBLIC_SITE_URL` | Deployed origin, used for sitemap and hreflang |

`FIREBASE_PRIVATE_KEY` must stay on one line with literal `\n` sequences.

### Deploying rules and indexes

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

Do not run `firebase firestore:indexes > firestore.indexes.json`. It overwrites the file with whatever currently exists, and the next deploy then deletes any index missing from it.

---

## Scripts

| Command | Does |
|---|---|
| `npm run dev` | Development server |
| `npm run build` | Production build, including type check |
| `npm run seed` | Populate Firestore, idempotent |
| `npm run seed:reset` | Wipe collections, then seed |
| `npx tsc --noEmit` | Type check alone |

`next dev` does not type check. Run `tsc --noEmit` before pushing.

---

## Notable implementation details

**The hero** renders three device frames showing the same screen in iOS, Flutter and Android idioms — large title and hairline tab bar, filled AppBar and floating action button, search bar and Material 3 pill indicator respectively. Editing the code updates all three simultaneously.

**The projects section** pins a device that changes screen as each project scrolls into view, driven by `IntersectionObserver` weighted toward the middle of the viewport so it does not flicker between two partly visible entries.

**Platform colour** is informational, never interactive. Links, buttons and focus rings are always the site accent. Each platform has two tokens: a darkened one that passes WCAG AA as text on the paper background, and a brand-adjacent one used behind white text. Android's brand green measures about 1.6:1 on light and is unusable for text.

**Motion** is entrance-only, respects `prefers-reduced-motion`, and never wraps the hero — the headline must be readable the instant the page paints.

---

## Licence

Code is available to read and learn from. Content, copy and images are not licensed for reuse.
