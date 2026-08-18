"use client";

import { useEffect, useRef, useState } from "react";

/**
 * Entrance motion.
 *
 * A 12px rise and a fade, once, when the section enters view. Deliberately
 * small: the job is to guide the eye down the page, not to perform.
 *
 * Never wrap the hero in this - the headline and availability badge must
 * be readable the instant the page paints, and a recruiter scanning for
 * eight seconds should not be waiting on an animation.
 *
 * Elements start visible and are only hidden once the observer attaches,
 * so content still renders if JavaScript fails.
 */

export default function Reveal({
  children,
  delay = 0,
  className = "",
}: {
  children: React.ReactNode;
  delay?: number;
  className?: string;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [shown, setShown] = useState(true);
  const [armed, setArmed] = useState(false);

  useEffect(() => {
    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduced || !ref.current) return;

    setShown(false);
    setArmed(true);

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setShown(true);
          observer.disconnect();
        }
      },
      { rootMargin: "0px 0px -12% 0px", threshold: 0.05 }
    );

    observer.observe(ref.current);
    return () => observer.disconnect();
  }, []);

  return (
    <div
      ref={ref}
      className={className}
      style={
        armed
          ? {
              opacity: shown ? 1 : 0,
              transform: shown ? "translateY(0)" : "translateY(12px)",
              transition: `opacity 480ms ease-out ${delay}ms, transform 480ms cubic-bezier(0.22,1,0.36,1) ${delay}ms`,
            }
          : undefined
      }
    >
      {children}
    </div>
  );
}
