-- snappy punch with an actual smooth decel so it doesn't hit a brick wall
hl.curve("superSnappy", {
    type = "bezier",
    points = { { 0.05, 0.9 }, { 0.1, 1.05 } },
})

-- clean decel without overshoot so the whole screen doesn't vibrate my retinas
hl.curve("smoothOut", {
    type = "bezier",
    points = { { 0.16, 1.0 }, { 0.3, 1.0 } },
})

-- straight linear for spinning garbage
hl.curve("linear", {
    type = "bezier",
    points = { { 0.0, 0.0 }, { 1.0, 1.0 } },
})

-- global fallback baseline
hl.animation({
    leaf = "global",
    enabled = true,
    speed = 4.0,
    bezier = "smoothOut",
})

-- popin needs actual room to breathe or it just looks like a screen glitch
hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 3.5,
    bezier = "superSnappy",
    style = "popin 80%",
})

-- workspaces gliding without snapping my neck
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 3.8,
    bezier = "smoothOut",
    style = "slidefade 15%",
})

-- layers fading cleanly instead of choking on alpha values
hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 2.5,
    bezier = "smoothOut",
    style = "fade",
})

-- instant feedback so my click feels registered
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 2.0,
    bezier = "superSnappy",
})

-- if this hitches again im turning off borders forever
hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 30.0,
    bezier = "linear",
})