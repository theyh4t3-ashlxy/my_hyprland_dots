-- superSnappy: keeping the exact 0.1/1.1 punch from the old curve, but smoothed the tail landing so it doesnt clunk at the last frame
hl.curve("superSnappy", {
    type = "bezier",
    points = { { 0.1, 1.1 }, { 0.2, 1.0 } },
})

-- global: speed of light
hl.animation({
    leaf = "global",
    enabled = true,
    speed = 5.5,
    bezier = "superSnappy",
})

-- windows pop in like bubbles popping on a premium screen
hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 4.5,
    bezier = "superSnappy",
    style = "popin 90%",
})

-- sliding workspaces
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 4.0,
    bezier = "superSnappy",
    style = "slidefade 10%",
})

-- layers (launcher, bar, overlays) fading in like they belong
hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 3.0,
    bezier = "superSnappy",
    style = "fade",
})

-- border color transition speed
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 4.0,
    bezier = "superSnappy",
})

-- border angle rotation speed
hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 1.0,
    bezier = "default",
})