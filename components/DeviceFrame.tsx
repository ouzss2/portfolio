"use client";

import { useRef, useState, useCallback } from "react";

/**
 * The device.
 *
 * Shared by the hero and the projects section so it reads as one object
 * that persists down the page, rather than two separate props.
 *
 * Carries the simulator touch indicator: inside the screen the cursor is
 * replaced by a translucent circle, the way the iOS Simulator shows a
 * touch. Anyone who has used Xcode recognises it immediately; anyone who
 * has not still gets a pleasant pointer. Pointer-coarse devices skip it,
 * since a finger already is the indicator.
 */

export default function DeviceFrame({
  children,
  width = 300,
  label,
}: {
  children: React.ReactNode;
  width?: number;
  label?: string;
}) {
  const screenRef = useRef<HTMLDivElement>(null);
  const [touch, setTouch] = useState<{ x: number; y: number } | null>(null);
  const [pressed, setPressed] = useState(false);

  const onMove = useCallback((e: React.PointerEvent) => {
    if (e.pointerType !== "mouse") return;
    const rect = screenRef.current?.getBoundingClientRect();
    if (!rect) return;
    setTouch({ x: e.clientX - rect.left, y: e.clientY - rect.top });
  }, []);

  return (
    <div className="flex flex-col items-center">
      <div
        className="relative"
        style={{
          width: `min(${width}px, 78vw)`,
          aspectRatio: "9 / 19.5",
          backgroundColor: "#0C0F15",
          borderRadius: "44px",
          padding: "11px",
        }}
      >
        <div
          ref={screenRef}
          onPointerMove={onMove}
          onPointerLeave={() => {
            setTouch(null);
            setPressed(false);
          }}
          onPointerDown={() => setPressed(true)}
          onPointerUp={() => setPressed(false)}
          className="relative h-full w-full overflow-hidden [@media(pointer:fine)]:cursor-none"
          style={{ backgroundColor: "#FAFBF9", borderRadius: "34px" }}
        >
          <div
            aria-hidden
            className="absolute left-1/2 top-2 z-20 h-6 w-24 -translate-x-1/2 rounded-full"
            style={{ backgroundColor: "#0C0F15" }}
          />

          {children}

          {touch && (
            <span
              aria-hidden
              className="pointer-events-none absolute z-30 rounded-full transition-[width,height,opacity] duration-150"
              style={{
                left: touch.x,
                top: touch.y,
                width: pressed ? 34 : 42,
                height: pressed ? 34 : 42,
                marginLeft: pressed ? -17 : -21,
                marginTop: pressed ? -17 : -21,
                backgroundColor: "rgba(20,26,23,0.16)",
                border: "1px solid rgba(20,26,23,0.28)",
              }}
            />
          )}
        </div>
      </div>

      {label && (
        <p
          className="mt-5 font-[family-name:var(--font-mono)] text-[11px] uppercase tracking-[0.12em]"
          style={{ color: "var(--color-ink-muted)" }}
        >
          {label}
        </p>
      )}
    </div>
  );
}
