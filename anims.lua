-- ok, i did some research and apparently 'bezier' math is just how much the
-- computer wants to overshoot before settling.
-- let's try a curve that doesn't feel like a rubber band snapping in my face.

hl.curve("superSnappy", {
    type = "bezier",
    points = { { 0.1, 1.05 }, { 0.15, 1.05 } },
})

-- global: why run 60hz animations when you can run them at hyperspeed?
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
    style = "popin 93%",
})

-- sliding workspaces that don't make me dizzy on monday mornings
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 3.8,
    bezier = "superSnappy",
    style = "slidefade 12%",
})

-- layers (launcher, bar, overlays) fading in like they belong
hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 3.2,
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