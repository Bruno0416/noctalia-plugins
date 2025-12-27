Este está enfocado en la configuración de monitores que mostraste en tu `manifest.json`.

```markdown
# 💊 Workspaces Pill

Un módulo de espacios de trabajo (workspaces) limpio, moderno y minimalista para Hyprland en Noctalia. Diseñado con forma de "píldora" para ocupar poco espacio visual mientras ofrece máxima utilidad.

![Preview](https://via.placeholder.com/800x200?text=Workspaces+Preview)

## ✨ Características

- **Diseño Flotante:** Estilo "Pill" moderno y animado.
- **Soporte Multi-Monitor:** Configura rangos de workspaces específicos para cada pantalla.
- **Animaciones Suaves:** Transiciones fluidas al cambiar de escritorio.
- **Indicadores de Estado:** Muestra workspaces activos, vacíos y ocupados.

## 🔧 Configuración

Para que el widget sepa qué workspaces mostrar en cada monitor, edita la configuración en Noctalia o en el `manifest.json`:

```json
"defaultSettings": {
    "monitors": {
        "DP-1": [1, 2, 3, 4, 5],
        "HDMI-A-1": [6, 7, 8, 9]
    }
}