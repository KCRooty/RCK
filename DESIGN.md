# RCK · Dirección de diseño

> Redactado el 2026-10-22 a partir de la dirección que dio Rooty (Static Forge): dejar el cyberpunk,
> pasar a liquid glass, mantener el morado de marca como acento. Aviso honesto: lo ha transcrito un
> agente, así que conviene revisarlo y corregir lo que no encaje. El dueño de este archivo es Rooty.

## Identidad

RCK es una herramienta de sistema para quien quiere controlar su Windows sin romperlo. La promesa
central es la **reversibilidad**: todo lo que se aplica se puede deshacer. La interfaz tiene que
transmitir control y calma, no "hacker" ni "gaming".

- **Personalidad:** precisa, tranquila, honesta. Nada de alarmismo ni de promesas de "+300% FPS".
- **Audiencia:** usuarios avanzados de Windows 10/11 y técnicos que optimizan equipos ajenos.

## Tema

Oscuro fijo. Razón: es una herramienta de sistema que convive con consolas, PowerShell y paneles
del sistema, y el oscuro ya es la identidad de RCK desde la v0.1. No hay modo claro hoy; si se
añade, tiene que funcionar entero (no a medias).

## Paleta (2 núcleos + 1 acento)

| Rol | Valor | Uso |
|---|---|---|
| Base | `#0b0c10` / `#16171d` / `#1c1d24` | fondo, superficies, tarjetas |
| Texto | `#eceef1` / `#9297a3` | principal / secundario (≥ 4.5:1 sobre las superficies) |
| **Acento** | `#7B61FF` (morado Static Forge) | solo en el momento clave: botón primario, interruptor activo, foco |
| Riesgo | verde / ámbar / naranja / rojo | **funcional**, marca el riesgo real de cada tweak; no es decoración |

Sin dorado, sin gradientes azul-morado, sin glows de fondo.

## Tipografía

`Segoe UI` (sistema). Razón: RCK es una app nativa de Windows y tiene que sentirse parte del
sistema que configura. Código y scripts en `Cascadia Code`, la mono que trae Windows Terminal.

## Material: liquid glass como acento

Librería: **quickLiquid** (`quick-liquid`). La refracción completa solo existe en Chromium; la app
de escritorio corre en WebView2 (Chromium), así que ahí se ve entera. En Firefox/Safari (versión web)
queda el fallback de desenfoque + tinte, que es aceptable.

Regla de dosis: **máximo 2 superficies de cristal por pantalla.** El cristal marca lo que flota
sobre el contenido o lo que indica dónde estás; todo lo demás es sólido.

1. **Barra de acción** (abajo, pegajosa): flota sobre la lista de tweaks, así que el cristal refracta
   el contenido real que pasa por debajo. Es la superficie que confirma "esto es lo que vas a aplicar".
2. **Indicador de sección activa** (menú lateral): una píldora de cristal que se desliza con muelle
   hasta la sección elegida. Es el **motivo de identidad**: la selección es líquida y se puede deshacer.

Prohibido: cristal en tarjetas, modales, menú entero o cabeceras.

## Diales

Dial: ENERGY 2 / RHYTHM 1 / MOTION 2

- **ENERGY 2:** herramienta seria pero con carácter propio (el cristal).
- **RHYTHM 1:** es una app de trabajo; las listas de tweaks son uniformes a propósito para escanearlas rápido.
- **MOTION 2:** movimiento solo con propósito: el indicador que viaja a la sección, la presión
  líquida del botón principal. Sin bucles infinitos. Se respeta `prefers-reduced-motion`
  (quickLiquid lo hace solo) y `prefers-reduced-transparency`.

## Pendiente (fuera del alcance de la v1 de cristal)

- Los emoji del menú y de los títulos (🧹 🔒 ⚡…) chocan con antislop R-04. Sustituirlos por iconos
  propios o quitarlos es una decisión de identidad: preguntar a Rooty.
- La landing (`index.astro`) aún no usa cristal; su copy tiene rayas largas (antislop R-02).
