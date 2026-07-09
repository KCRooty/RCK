import { invoke } from "@tauri-apps/api/core";
import type { PackageManager, ServiceInfo, SystemInfo } from "./types";

export const desktop = {
  getTweakStatus: (id: string) => invoke<boolean>("get_tweak_status", { id }),
  applyTweak: (id: string) => invoke<void>("apply_tweak", { id }),
  revertTweak: (id: string) => invoke<void>("revert_tweak", { id }),
  createRestorePoint: (description: string) => invoke<void>("create_restore_point_cmd", { description }),
  getAppStatus: (id: string, manager: PackageManager) => invoke<boolean>("get_app_status", { id, manager }),
  installApp: (id: string, manager: PackageManager) => invoke<void>("install_app", { id, manager }),
  uninstallApp: (id: string, manager: PackageManager) => invoke<void>("uninstall_app", { id, manager }),
  runTool: (id: string) => invoke<void>("run_tool", { id }),
  getSystemInfo: () => invoke<SystemInfo>("get_system_info"),
  listServices: () => invoke<ServiceInfo[]>("list_services"),
  setServiceStartup: (name: string, startType: string) => invoke<void>("set_service_startup", { name, startType }),
  runRawScript: (script: string) => invoke<string>("run_raw_script", { script }),
};
