# bar

the status bar that docks anywhere because commitment is terrifying.

top? bottom? left? right? dock it wherever your executive dysfunction feels like today. unlike archaic bars that demand a full config reload and a sacrificial prayer just to move ten pixels to the left, this thing adapts dynamically without restarting the compositor.

## components
- `StatusBar.qml`: the chameleon bar. dynamically repositions itself on whatever screen edge `Settings.barEdge` demands. supports smooth hover expansions, liquid corner docking via canvas mathematics, pill groupings with spring physics, and hot-reloading widget layouts dispatched straight from `BarStudio`.
