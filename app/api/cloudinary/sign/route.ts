import { NextResponse } from "next/server";
import crypto from "crypto";
import { adminAuth } from "@/lib/firebase/admin";

/**
 * Cloudinary upload signature.
 *
 * The browser uploads the file straight to Cloudinary, but only after
 * this route signs the request. That keeps the API secret on the server
 * while avoiding proxying large video files through Vercel, which has a
 * request body limit that app recordings would exceed.
 *
 * The caller must present a valid Firebase ID token belonging to the
 * owner UID. Without that check, an unsigned preset would let anyone who
 * found the cloud name fill the account with files.
 */

export async function POST(request: Request) {
  const secret = process.env.CLOUDINARY_API_SECRET;
  const apiKey = process.env.CLOUDINARY_API_KEY;
  const ownerUid = process.env.ADMIN_UID;

  if (!secret || !apiKey || !ownerUid) {
    return NextResponse.json(
      { error: "Cloudinary or admin environment variables are missing" },
      { status: 500 }
    );
  }

  // --- authenticate ------------------------------------------------
  const header = request.headers.get("authorization") ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) {
    return NextResponse.json({ error: "Not signed in" }, { status: 401 });
  }

  try {
    const decoded = await adminAuth.verifyIdToken(token);
    if (decoded.uid !== ownerUid) {
      return NextResponse.json({ error: "Not permitted" }, { status: 403 });
    }
  } catch {
    return NextResponse.json({ error: "Invalid session" }, { status: 401 });
  }

  // --- sign --------------------------------------------------------
  const body = (await request.json().catch(() => ({}))) as {
    folder?: string;
  };
  const folder = body.folder ?? "portfolio";
  const timestamp = Math.round(Date.now() / 1000);

  // Cloudinary signs the alphabetically sorted parameter string.
  const toSign = `folder=${folder}&timestamp=${timestamp}`;
  const signature = crypto
    .createHash("sha1")
    .update(toSign + secret)
    .digest("hex");

  return NextResponse.json({
    signature,
    timestamp,
    folder,
    apiKey,
    cloudName: process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME,
  });
}
