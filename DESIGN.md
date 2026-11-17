# RCK · Dirección de diseño

> Revisado el 2026-11-17. Sustituye a la dirección liquid glass del 2026-10-22. Dirección pedida por
> Rooty (Static Forge): una utilidad de sistema en la línea de Optimizer, Chris Titus WinUtil,
> WinScript y PowerToys. Lo ha transcrito un agente; el dueño de este archivo es Rooty.

## Identidad

RCK es una herramienta de sistema para quien quiere controlar su Windows sin romperlo. La promesa es la
**reversibilidad**. La interfaz tiene que parecer una utilidad de Windows, no una landing de producto:
densa, legible, sin adorno.

- **Personalidad:** precisa, sobria, honesta. Nada de alarmismo ni de promesas de rendimiento.
- **Audiencia:** usuarios avanzados de Windows 10/11 y técnicos que optimizan equipos ajenos.

## Qué se toma de cada referencia

- **PowerToys:** menú lateral de texto con marcador de sección actual, interruptores pequeños, filas
  agrupadas en una sola lista con separadores.
- **Chris Titus WinUtil:** densidad. Muchas opciones visibles a la vez, identificador técnico en
  monoespaciada, riesgo a la vista.
- **WinScript / Optimizer:** selección acumulada, barra de aplicar fija abajo, el script generado se
  puede ver y editar antes de ejecutarlo.

## Tema

Oscuro fijo, grises neutros (`#1c1c1c` base, `#242424` menú y barra, `#2b2b2b` filas). Razón: convive
con PowerShell y los paneles del sistema. Sin modo claro hoy; si se añade, tiene que funcionar entero.

## Color

| Rol | Valor | Uso |
|---|---|---|
| Acento | `#4cc2ff` | interruptor activo, botón primario, foco, marcador del menú |
| Texto | `#f2f2f2` / `#a8a8a8` | principal / secundario |
| Riesgo | verde / amarillo / naranja / rojo | **funcional**: marca el riesgo real de cada tweak |

Sin gradientes, sin glow, sin cristal, sin sombras. Una sola superficie elevada: la barra de aplicar.

## Forma

Radio 4 px en todo. Filas planas con separador de 1 px. Sin tarjetas flotantes ni píldoras.

## Tipografía

`Segoe UI Variable` / `Segoe UI` para la interfaz; `Cascadia Mono` para identificadores, métricas y
scripts. Es una app nativa de Windows y tiene que parecer parte del sistema.

## Copy

Sin emoji ni iconos decorativos en menús y títulos. Sin rayas largas en el texto: se usan comas,
dos puntos y puntos. El texto dice lo que hace, sin promesas.

## Movimiento

Casi nulo: 100 ms en el interruptor. Nada animado en el menú.
