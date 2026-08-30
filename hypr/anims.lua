-- superSnappy: snappy overshoot with zero-velocity landing so windows glide smoothly into rest
hl.curve("superSnappy", {
    type = "bezier",
    points = { { 0.2, 1.08 }, { 0.35, 1.0 } },
})

-- smoothOut: clean ease-out curve for workspaces and layers (no rubber-band jitter)
hl.curve("smoothOut", {
    type = "bezier",
    points = { { 0.16, 1.0 }, { 0.3, 1.0 } },
})

-- global fallback
hl.animation({
    leaf = "global",
    enabled = true,
    speed = 5.0,
    bezier = "smoothOut",
})

-- windows pop in like bubbles popping on a premium screen
hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 4.5,
    bezier = "superSnappy",
    style = "popin 85%",
})

-- sliding workspaces that glide without abrupt stops
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 4.0,
    bezier = "smoothOut",
    style = "slidefade 15%",
})

-- layers (launcher, bar, overlays) fading in like they belong
hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 3.2,
    bezier = "smoothOut",
    style = "fade",
})

-- border color transition speed
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 4.0,
    bezier = "smoothOut",
})

-- border angle rotation speed
hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 1.0,
    bezier = "default",
})