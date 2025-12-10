"use client";

import { cn } from "@/lib/utils";
import { Menu, X } from "lucide-react";
import { AnimatePresence, motion } from "framer-motion";
import Link, { LinkProps } from "next/link";
import React, { createContext, useContext, useState } from "react";

interface Links {
  label: string;
  href: string;
  icon: React.JSX.Element | React.ReactNode;
}

interface SidebarContextProps {
  open: boolean;
  setOpen: React.Dispatch<React.SetStateAction<boolean>>;
  animate: boolean;
}

const SidebarContext = createContext<SidebarContextProps | undefined>(
  undefined
);

export const useSidebar = () => {
  const context = useContext(SidebarContext);
  if (!context) {
    throw new Error("useSidebar must be used within a SidebarProvider");
  }
  return context;
};

export const SidebarProvider = ({
  children,
  open: openProp,
  setOpen: setOpenProp,
  animate = true,
}: {
  children: React.ReactNode;
  open?: boolean;
  setOpen?: React.Dispatch<React.SetStateAction<boolean>>;
  animate?: boolean;
}) => {
  const [openState, setOpenState] = useState(false);

  const open = openProp !== undefined ? openProp : openState;
  const setOpen = setOpenProp !== undefined ? setOpenProp : setOpenState;

  return (
    <SidebarContext.Provider value={{ open, setOpen, animate }}>
      {children}
    </SidebarContext.Provider>
  );
};

export const Sidebar = ({
  children,
  open,
  setOpen,
  animate,
}: {
  children: React.ReactNode;
  open?: boolean;
  setOpen?: React.Dispatch<React.SetStateAction<boolean>>;
  animate?: boolean;
}) => {
  return (
    <SidebarProvider open={open} setOpen={setOpen} animate={animate}>
      {children}
    </SidebarProvider>
  );
};

export const SidebarBody = (props: React.ComponentProps<typeof motion.div>) => {
  return (
    <>
      <DesktopSidebar {...props} />
      <MobileSidebar {...(props as React.ComponentProps<"div">)} />
    </>
  );
};

export const DesktopSidebar = ({
  className,
  children,
  ...props
}: React.ComponentProps<typeof motion.div>) => {
  const { open, setOpen, animate } = useSidebar();
  return (
    <motion.div
      className={cn(
        "h-full px-4 py-4 hidden md:flex md:flex-col bg-muted/30 dark:bg-muted/20 flex-shrink-0 border-r border-border",
        className
      )}
      animate={{
        width: animate ? (open ? "256px" : "68px") : "256px",
      }}
      transition={{
        duration: 0.3,
        ease: "easeInOut",
      }}
      onMouseEnter={() => setOpen(true)}
      onMouseLeave={() => setOpen(false)}
      {...props}
    >
      {children}
    </motion.div>
  );
};

export const MobileSidebar = ({
  className,
  children,
  ...props
}: React.ComponentProps<"div">) => {
  const { open, setOpen } = useSidebar();
  return (
    <div
      className={cn("flex flex-col md:hidden")}
      {...props}
    >
      <div className="flex justify-start z-20 w-full px-4 py-3">
        <Menu
          className="h-5 w-5 text-foreground cursor-pointer"
          onClick={() => setOpen(!open)}
        />
      </div>
      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ x: "-100%", opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            exit={{ x: "-100%", opacity: 0 }}
            transition={{
              duration: 0.3,
              ease: "easeInOut",
            }}
            className={cn(
              "fixed inset-0 bg-background z-[100] flex flex-col",
              className
            )}
          >
            <div className="flex justify-between items-center p-4 border-b border-border">
              <h2 className="text-lg font-semibold">Menu</h2>
              <X
                className="h-5 w-5 text-foreground cursor-pointer"
                onClick={() => setOpen(false)}
              />
            </div>
            <div className="flex-1 overflow-y-auto p-4">
              {children}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export const SidebarLink = ({
  link,
  className,
  active,
  ...props
}: {
  link: Links;
  className?: string;
  active?: boolean;
} & Omit<LinkProps, 'href'>) => {
  const { open, animate } = useSidebar();
  return (
    <Link
      href={link.href}
      className={cn(
        "flex items-center justify-start gap-2 group/sidebar py-2 px-2 rounded-lg transition-colors",
        "hover:bg-muted text-muted-foreground hover:text-foreground",
        active && "bg-muted text-foreground",
        className
      )}
      {...props}
    >
      {link.icon}
      <motion.span
        animate={{
          display: animate ? (open ? "inline-block" : "none") : "inline-block",
          opacity: animate ? (open ? 1 : 0) : 1,
        }}
        transition={{
          duration: 0.2,
          ease: "easeInOut",
        }}
        className="text-sm group-hover/sidebar:translate-x-1 transition duration-150 whitespace-pre inline-block !p-0 !m-0"
      >
        {link.label}
      </motion.span>
    </Link>
  );
};

export const SidebarButton = ({
  icon,
  label,
  onClick,
  className,
  variant = "default",
}: {
  icon: React.ReactNode;
  label: string;
  onClick?: () => void;
  className?: string;
  variant?: "default" | "outline";
}) => {
  const { open, animate } = useSidebar();
  return (
    <button
      onClick={onClick}
      className={cn(
        "flex items-center justify-start gap-2 group/sidebar py-2 px-2 rounded-lg transition-colors w-full",
        variant === "default" && "hover:bg-muted text-muted-foreground hover:text-foreground",
        variant === "outline" && "border border-dashed border-border hover:border-primary hover:bg-primary/5",
        className
      )}
    >
      {icon}
      <motion.span
        animate={{
          display: animate ? (open ? "inline-block" : "none") : "inline-block",
          opacity: animate ? (open ? 1 : 0) : 1,
        }}
        transition={{
          duration: 0.2,
          ease: "easeInOut",
        }}
        className="text-sm group-hover/sidebar:translate-x-1 transition duration-150 whitespace-pre inline-block !p-0 !m-0"
      >
        {label}
      </motion.span>
    </button>
  );
};

export const SidebarLabel = ({
  label,
  className,
}: {
  label: string;
  className?: string;
}) => {
  const { open, animate } = useSidebar();
  return (
    <motion.span
      animate={{
        display: animate ? (open ? "block" : "none") : "block",
        opacity: animate ? (open ? 1 : 0) : 1,
      }}
      transition={{
        duration: 0.2,
        ease: "easeInOut",
      }}
      className={cn(
        "text-xs font-medium text-muted-foreground px-2 mb-2",
        className
      )}
    >
      {label}
    </motion.span>
  );
};
