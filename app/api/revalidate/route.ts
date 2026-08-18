import { revalidatePath } from "next/cache";
import { NextResponse } from "next/server";

/**
 * On-demand revalidation.
 *
 * Public pages are statically generated with a one hour window. Without
 * this, an edit in the admin would not appear on the site until that
 * window expired. The admin calls this after every save so the change is
 * live immediately.
 */

export async function POST() {
  revalidatePath("/", "layout");
  return NextResponse.json({ revalidated: true, at: Date.now() });
}
