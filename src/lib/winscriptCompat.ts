/**
 * Compatibilidad con perfiles exportados por WinScript (winscript.app).
 *
 * WinScript exporta un JSON plano `{ "clave": true|false, ... }` donde cada
 * clave es un tweak o una app. RCK organiza lo mismo como tweaks/apps con
 * id propio (`categoria.nombre` / `apps.nombre`), así que esto es una tabla
 * de correspondencia manual, no una traducción 1:1 perfecta: a veces varias
 * claves de WinScript caen sobre un único tweak de RCK más amplio (todas
 * las claves "*access" de privacidad, por ejemplo, resuelven en
 * `privacy.restrict-app-permissions`).
 *
 * Basado en los perfiles reales `SCRIPT.json` y
 * `Script Optimizar PC By Rooty (Core).json`.
 */

export const WINSCRIPT_TWEAK_MAP: Record<string, string[]> = {
  // Debloat
  consumerfeatures: ["debloat.disable-consumer-features"],
  recall: ["debloat.disable-recall"],
  iexplorer: ["debloat.remove-legacy-features"],
  faxscan: ["debloat.remove-legacy-features"],
  onedrive: ["debloat.remove-onedrive"],
  edge: ["debloat.debloat-edge"],
  debloatedge: ["debloat.debloat-edge"],
  copilot: ["debloat.remove-copilot"],
  widgets: ["debloat.disable-widgets"],
  taskbarwidgets: ["debloat.disable-widgets"],

  // Privacidad — todas las variantes de "acceso de apps a X" convergen en
  // un único tweak de RCK que deniega por política el acceso de apps UWP.
  locationaccess: ["privacy.restrict-app-permissions"],
  cameraccess: ["privacy.restrict-app-permissions"],
  microphoneaccess: ["privacy.restrict-app-permissions"],
  accinfoaccess: ["privacy.restrict-app-permissions"],
  contactsaccess: ["privacy.restrict-app-permissions"],
  callhistoryaccess: ["privacy.restrict-app-permissions"],
  messagingaccess: ["privacy.restrict-app-permissions"],
  notificationaccess: ["privacy.restrict-app-permissions"],
  emailaccess: ["privacy.restrict-app-permissions"],
  tasksaccess: ["privacy.restrict-app-permissions"],
  diagaccess: ["privacy.restrict-app-permissions"],
  voiceactivationaccess: ["privacy.restrict-app-permissions"],
  phoneaccess: ["privacy.restrict-app-permissions"],
  trustedaccess: ["privacy.restrict-app-permissions"],
  calendaraccess: ["privacy.restrict-app-permissions"],
  motionaccess: ["privacy.restrict-app-permissions"],
  radioaccess: ["privacy.restrict-app-permissions"],
  recordingsaccess: ["privacy.restrict-app-permissions"],
  cloudsync: ["privacy.disable-clipboard-cloud-sync"],
  activityfeed: ["privacy.disable-clipboard-cloud-sync"],
  automap: ["privacy.disable-clipboard-cloud-sync"],
  clipboard: ["privacy.disable-clipboard-cloud-sync"],
  wtelemetry: ["privacy.disable-telemetry"],
  targetads: ["privacy.disable-tailored-experiences"],
  privacyconsent: ["privacy.disable-tailored-experiences"],

  // Rendimiento
  fullscreenoptimizations: ["performance.gaming-mode"],
  gamebar: ["performance.gaming-mode"],
  gamemode: ["performance.gaming-mode"],
  mpo: ["performance.gaming-mode"],
  mouseacc: ["performance.disable-mouse-acceleration"],
  mousedelay: ["performance.disable-mouse-acceleration"],
  hags: ["performance.enable-hags"],
  disableprefetch: ["performance.disable-prefetch-superfetch"],
  storagesense: ["performance.disable-storage-sense"],
  ultimateperformance: ["performance.enable-ultimate-performance-plan"],

  // Servicios / red / actualizaciones
  manualservices: ["services.set-nonessential-manual"],
  cloudflaredns: ["network.set-dns-cloudflare"],
  thirdparty: ["updates.pause-third-party-updates"],
  googleupdates: ["updates.pause-third-party-updates"],
  adobeupdates: ["updates.pause-third-party-updates"],
  resetnetwork: ["tools.optimize-network-stack"],

  // Apariencia / sistema
  transparency: ["appearance.disable-transparency"],
  darkmode: ["appearance.enable-dark-mode"],
  taskbarleft: ["appearance.taskbar-align-left"],
  classicmenu: ["appearance.classic-context-menu"],
  disablehibernation: ["system.disable-hibernation"],
  detailedbsod: ["system.show-detailed-bsod"],
  numlockstartup: ["system.numlock-on-startup"],
  filextensions: ["system.show-file-extensions"],
  extensions: ["system.show-file-extensions"],
  cleantemp: ["tools.clear-temp-files"],
  cleanmgr: ["tools.clear-temp-files"],
  emptyrecycle: ["tools.empty-recycle-bin"],
  stickykeys: ["system.disable-sticky-keys"],
  snapflyout: ["appearance.disable-snap-flyout"],
};

/**
 * Claves de WinScript que RCK reconoce pero rechaza a propósito por tocar
 * componentes de la lista negra (ver docs/BLACKLIST.md) — se listan aparte
 * para poder explicarle al usuario por qué no se importaron, en vez de
 * ignorarlas en silencio como el resto de claves no soportadas.
 */
export const WINSCRIPT_PROTECTED_KEYS = ["limitdefender", "coreisolation", "ipv6", "updatepause", "wupdate"];

export const WINSCRIPT_APP_MAP: Record<string, string> = {
  Brave: "apps.brave",
  Chrome: "apps.chrome",
  Firefox: "apps.firefox",
  LibreWolf: "apps.librewolf",
  Opera: "apps.opera",
  Tor: "apps.tor-browser",
  Vivaldi: "apps.vivaldi",
  Waterfox: "apps.waterfox",
  "7Zip": "apps.7zip",
  WinRAR: "apps.winrar",
  EpicGames: "apps.epicgames",
  GOGGalaxy: "apps.gog-galaxy",
  Minecraft: "apps.minecraft",
  PrismLauncher: "apps.prismlauncher",
  Steam: "apps.steam",
  UbisoftConnect: "apps.ubisoft-connect",
  AnyDesk: "apps.anydesk",
  AutoHotkey: "apps.autohotkey",
  BitWarden: "apps.bitwarden",
  CCleaner: "apps.ccleaner",
  "CPU-Z": "apps.cpu-z",
  Everything: "apps.everything",
  FlowLauncher: "apps.flow-launcher",
  "GPU-Z": "apps.gpu-z",
  HWInfo: "apps.hwinfo",
  KeePass: "apps.keepassxc",
  Afterburner: "apps.afterburner",
  qBitTorrent: "apps.qbittorrent",
  Rainmeter: "apps.rainmeter",
  TeamViewer: "apps.teamviewer",
  WinDirStat: "apps.windirstat",
  MullvadVPN: "apps.mullvadvpn",
  ProtonVPN: "apps.protonvpn",
  PuTTY: "apps.putty",
  WireShark: "apps.wireshark",
  WireGuard: "apps.wireguard",
  PowerToys: "apps.powertoys",
  WinTerminal: "apps.windows-terminal",
  foobar2000: "apps.foobar2000",
  HandBrake: "apps.handbrake",
  OBS: "apps.obs-studio",
  Spotify: "apps.spotify",
  VLC: "apps.vlc",
  Discord: "apps.discord",
  Signal: "apps.signal",
  Slack: "apps.slack",
  Teams: "apps.teams",
  Telegram: "apps.telegram",
  Zoom: "apps.zoom",
  Blender: "apps.blender",
  GIMP: "apps.gimp",
  Greenshot: "apps.greenshot",
  inkScape: "apps.inkscape",
  Krita: "apps.krita",
  ShareX: "apps.sharex",
  AdobeReader: "apps.adobe-acrobat-reader",
  LibreOffice: "apps.libreoffice",
  Obsidian: "apps.obsidian",
  SumatraPDF: "apps.sumatrapdf",
  MalwareBytes: "apps.malwarebytes",
  Docker: "apps.docker-desktop",
  Git: "apps.git",
  Go: "apps.go",
  NodeJS: "apps.nodejs",
  "Notepad++": "apps.notepadplusplus",
  OhMyPosh: "apps.ohmyposh",
  Postman: "apps.postman",
  Python3: "apps.python",
  Rust: "apps.rust",
  SublimeText: "apps.sublimetext",
  VSCode: "apps.vscode",
  Spicetify: "apps.spicetify",
  Audacity: "apps.audacity",
  EqualizerAPO: "apps.equalizerapo",
  FFmpeg: "apps.ffmpeg",
  "yt-dlp": "apps.yt-dlp",
  GitExtensions: "apps.gitextensions",
  KLite: "apps.klite-codec-pack",
  Godot: "apps.godot",
  WinMerge: "apps.winmerge",
  NET8: "apps.dotnet-desktop-runtime",
};

export interface WinScriptImportResult {
  tweaks: string[];
  apps: string[];
  matchedKeys: string[];
  protectedKeys: string[];
  unsupportedKeys: string[];
}

/** Heurística: un perfil de WinScript es un objeto plano de solo booleanos. */
export function isWinScriptProfile(data: unknown): data is Record<string, boolean> {
  if (typeof data !== "object" || data === null || Array.isArray(data)) {
    return false;
  }
  const values = Object.values(data as Record<string, unknown>);
  return values.length > 0 && values.every((v) => typeof v === "boolean");
}

export function importWinScriptProfile(data: Record<string, boolean>): WinScriptImportResult {
  const tweaks = new Set<string>();
  const apps = new Set<string>();
  const matchedKeys: string[] = [];
  const protectedKeys: string[] = [];
  const unsupportedKeys: string[] = [];

  for (const [key, enabled] of Object.entries(data)) {
    if (!enabled) continue;

    if (WINSCRIPT_TWEAK_MAP[key]) {
      WINSCRIPT_TWEAK_MAP[key].forEach((id) => tweaks.add(id));
      matchedKeys.push(key);
    } else if (WINSCRIPT_APP_MAP[key]) {
      apps.add(WINSCRIPT_APP_MAP[key]);
      matchedKeys.push(key);
    } else if (WINSCRIPT_PROTECTED_KEYS.includes(key)) {
      protectedKeys.push(key);
    } else {
      unsupportedKeys.push(key);
    }
  }

  return { tweaks: [...tweaks], apps: [...apps], matchedKeys, protectedKeys, unsupportedKeys };
}

/** Exporta la selección actual de RCK como un perfil plano estilo WinScript. */
export function exportWinScriptProfile(selection: { tweaks: string[]; apps: string[] }): Record<string, boolean> {
  const result: Record<string, boolean> = {};
  const tweakSet = new Set(selection.tweaks);
  const appSet = new Set(selection.apps);

  for (const [key, ids] of Object.entries(WINSCRIPT_TWEAK_MAP)) {
    result[key] = ids.some((id) => tweakSet.has(id));
  }
  for (const [key, id] of Object.entries(WINSCRIPT_APP_MAP)) {
    result[key] = appSet.has(id);
  }
  return result;
}
