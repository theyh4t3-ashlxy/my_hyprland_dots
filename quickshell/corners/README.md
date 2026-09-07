# corners

sharp ninety-degree monitor corners are a hate crime against aesthetic integrity.

why look at raw monitor bezels when you can have liquid curved display cutouts like a modern handheld or sleek workstation? this directory creates true curved display bezels using wayland layer-shell subsurfaces.

## the magic
- `ConcaveCorner.qml`: canvas element calculating and painting inverted arc fillets. it dynamically sizes itself based on your bar thickness and desired corner radius.
- `ScreenCorners.qml`: the maestro that anchors to all four monitor corners. includes continuous monitor border lines and, crucially, exact input region masking so your clicks pass straight through the transparency into underlying hyprland windows instead of leaving you clicking in blind rage.
