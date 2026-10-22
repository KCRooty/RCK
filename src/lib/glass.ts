import { AnimationScheduler, LiquidButton, LiquidGlassEngine, Spring } from "quick-liquid";

// Superficies de cristal de la app (ver DESIGN.md, "Material"). Hay exactamente dos:
// la barra de acción y el indicador de sección del menú. No añadir más sin
// actualizar DESIGN.md: el cristal es un acento, no el material de toda la UI.

export interface GlassHandles {
  moveIndicatorTo(item: HTMLElement): void;
}

const NOOP: GlassHandles = { moveIndicatorTo() {} };

export function setupGlass(): GlassHandles {
  try {
    setupActionBar();
    return setupSidebarIndicator();
  } catch (err) {
    // El cristal es cosmético: si falla, la app sigue con el estilo sólido de global.css.
    console.error("quickLiquid no se pudo montar:", err);
    return NOOP;
  }
}

function setupActionBar() {
  const bar = document.getElementById("action-bar");
  if (!bar) return;

  new LiquidGlassEngine(bar, {
    material: "regular",
    appearance: "dark",
    borderRadius: 14,
    refractionStrength: 18,
    chromaticAberration: 0.2,
    quality: "medium",
  });
  bar.classList.add("is-glass");

  // Respuesta táctil solo en la acción que confirma los cambios.
  const actionButton = document.getElementById("action-button");
  if (actionButton) new LiquidButton(actionButton);
}

function setupSidebarIndicator(): GlassHandles {
  const sidebar = document.querySelector<HTMLElement>(".sidebar");
  const indicator = document.getElementById("sidebar-indicator");
  const first = sidebar?.querySelector<HTMLElement>(".sidebar__item.active");
  if (!sidebar || !indicator || !first) return NOOP;

  // LiquidTabBar de quickLiquid solo anima en horizontal; el menú es vertical,
  // así que movemos la píldora con un muelle propio en el eje Y. Se mueve con
  // `top` y no con `transform`: el motor usa el transform del host para el
  // rebote (jiggle) y la presión, y lo pisaría.
  const ySpring = new Spring(first.offsetTop, "snappy");
  const scheduler = AnimationScheduler.shared();
  let animId: number | undefined;
  let current = first;

  const render = () => {
    indicator.style.top = `${ySpring.value}px`;
  };

  const size = (item: HTMLElement) => {
    indicator.style.left = `${item.offsetLeft}px`;
    indicator.style.width = `${item.offsetWidth}px`;
    indicator.style.height = `${item.offsetHeight}px`;
  };

  size(first);
  ySpring.setValue(first.offsetTop);
  render();

  const engine = new LiquidGlassEngine(indicator, {
    material: "clear",
    appearance: "dark",
    borderRadius: 8,
    blur: 0,
    refractionStrength: 8,
    bezelWidth: 10,
    chromaticAberration: 0.25,
    tint: "123, 97, 255",
    tintOpacity: 0.14,
    quality: "high",
  });
  indicator.classList.add("is-ready");
  sidebar.classList.add("has-glass-indicator");

  // Al cambiar el layout (ventana estrecha, menú en dos columnas) la píldora
  // salta a su sitio sin animar: cancelar el muelle y fijar valor Y destino.
  new ResizeObserver(() => {
    if (animId !== undefined) {
      scheduler.cancel(animId);
      animId = undefined;
    }
    size(current);
    ySpring.setValue(current.offsetTop);
    ySpring.setTarget(current.offsetTop);
    render();
  }).observe(sidebar);

  return {
    moveIndicatorTo(item: HTMLElement) {
      current = item;
      size(item);
      ySpring.setTarget(item.offsetTop);
      if (animId !== undefined) scheduler.cancel(animId);
      animId = scheduler.schedule((now) => {
        const moving = ySpring.tick(now);
        render();
        if (!moving) {
          animId = undefined;
          engine.jiggle(0.3);
        }
        return moving;
      });
    },
  };
}
