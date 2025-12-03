import type { LucideIcon } from "lucide-react";

export interface NavItem {
  title: string;
  href: string;
  icon?: LucideIcon;
  disabled?: boolean;
  external?: boolean;
  description?: string;
}

export interface NavSection {
  title: string;
  items: NavItem[];
}

export const marketingNav: NavItem[] = [
  {
    title: "Features",
    href: "/#features",
  },
  {
    title: "How it works",
    href: "/#how-it-works",
  },
  {
    title: "Pricing",
    href: "/pricing",
  },
  {
    title: "About",
    href: "/about",
  },
];

export const platformNav: NavItem[] = [
  {
    title: "Explore",
    href: "/explore",
    description: "Discover destinations and trips",
  },
  {
    title: "Chat",
    href: "/chat",
    description: "Plan with AI assistant",
  },
  {
    title: "My Trips",
    href: "/trips",
    description: "Your saved trips",
  },
];

export const footerNav: NavSection[] = [
  {
    title: "Product",
    items: [
      { title: "Features", href: "/#features" },
      { title: "Pricing", href: "/pricing" },
      { title: "How it works", href: "/#how-it-works" },
    ],
  },
  {
    title: "Company",
    items: [
      { title: "About", href: "/about" },
      { title: "Blog", href: "/blog" },
      { title: "Careers", href: "/careers" },
    ],
  },
  {
    title: "Legal",
    items: [
      { title: "Privacy", href: "/privacy" },
      { title: "Terms", href: "/terms" },
    ],
  },
];
