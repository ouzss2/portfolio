/**
 * Firebase Admin SDK â€” server only.
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

