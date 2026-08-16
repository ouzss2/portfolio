/**
 * Firebase client SDK â€” browser only.
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
 * to be public â€” access control lives in firestore.rules, not in these keys.
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

