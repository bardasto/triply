"use client";

import { useRef, useEffect, useLayoutEffect } from "react";

interface AnimatedCollapseProps {
  isOpen: boolean;
  children: React.ReactNode;
}

export function AnimatedCollapse({ isOpen, children }: AnimatedCollapseProps) {
  const contentRef = useRef<HTMLDivElement>(null);
  const wrapperRef = useRef<HTMLDivElement>(null);

  useLayoutEffect(() => {
    const wrapper = wrapperRef.current;
    const content = contentRef.current;
    if (!wrapper || !content) return;

    if (isOpen) {
      const contentHeight = content.scrollHeight;
      wrapper.style.height = `${contentHeight}px`;
      const timer = setTimeout(() => {
        wrapper.style.height = "auto";
      }, 300);
      return () => clearTimeout(timer);
    } else {
      const contentHeight = content.scrollHeight;
      wrapper.style.height = `${contentHeight}px`;
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          wrapper.style.height = "0px";
        });
      });
    }
  }, [isOpen]);

  return (
    <div
      ref={wrapperRef}
      style={{
        height: isOpen ? "auto" : 0,
        overflow: "hidden",
        transition: "height 300ms cubic-bezier(0.4, 0, 0.2, 1)",
      }}
    >
      <div ref={contentRef}>{children}</div>
    </div>
  );
}
