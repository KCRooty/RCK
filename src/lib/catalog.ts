import generated from "../data/catalog.generated.json";
import type { AppEntry, Tweak } from "./types";

const data = generated as unknown as { generatedAt: string; tweaks: Tweak[]; apps: AppEntry[] };

export const tweaks: Tweak[] = data.tweaks;
export const apps: AppEntry[] = data.apps;

export function tweaksByCategory(category: string): Tweak[] {
  return tweaks.filter((t) => t.category === category);
}

export function appsBySubcategory(subcategory: string): AppEntry[] {
  return apps.filter((a) => a.subcategory === subcategory);
}

export const TWEAK_CATEGORIES = [
  "debloat",
  "privacy",
  "performance",
  "services",
  "network",
  "appearance",
  "updates",
  "system",
] as const;

export const APP_SUBCATEGORIES = ["browsers", "dev-tools", "utilities", "media", "communication"] as const;
