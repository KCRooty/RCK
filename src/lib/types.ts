export type Risk = "safe" | "moderate" | "advanced" | "expert";

export interface Targets {
  services?: string[];
  registry?: string[];
}

export interface Tweak {
  id: string;
  category: string;
  risk: Risk;
  requires_restart: boolean;
  description: string;
  targets: Targets;
  script: string;
  test: string;
  apply: string;
  revert: string;
  /** Solo presente en el JSON generado para el modo web; el modo desktop no lo necesita. */
  psSource?: string;
}

export interface AppEntry {
  id: string;
  name: string;
  description: string;
  subcategory: string;
  winget?: string;
  choco?: string;
}

export type PackageManager = "winget" | "choco";
