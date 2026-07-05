import { invoke } from "@tauri-apps/api/core";
import type { PackageManager } from "./types";

export const desktop = {
  getTweakStatus: (id: string) => invoke<boolean>("get_tweak_status", { id }),
  applyTweak: (id: string) => invoke<void>("apply_tweak", { id }),
  revertTweak: (id: string) => invoke<void>("revert_tweak", { id }),
  createRestorePoint: (description: string) => invoke<void>("create_restore_point_cmd", { description }),
  getAppStatus: (id: string, manager: PackageManager) => invoke<boolean>("get_app_status", { id, manager }),
  installApp: (id: string, manager: PackageManager) => invoke<void>("install_app", { id, manager }),
  uninstallApp: (id: string, manager: PackageManager) => invoke<void>("uninstall_app", { id, manager }),
};
