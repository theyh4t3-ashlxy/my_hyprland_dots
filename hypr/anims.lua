-- stop teleporting in 2ms and freezing for the rest of eternity
hl.curve("snappyPop", {
    type = "bezier",
    points = { { 0.2, 1.15 }, { 0.35, 1.0 } },
})

-- buttery decel so my eyes stop bleeding on fast workspace swaps
hl.curve("smoothDecel", {
    type = "bezier",
    points = { { 0.16, 1.0 }, { 0.3, 1.0 } },
})

-- linear for the spinny shit
hl.curve("linear", {
    type = "bezier",
    points = { { 0.0, 0.0 }, { 1.0, 1.0 } },
})

-- fallback so hyprland doesn't explode
hl.animation({
    leaf = "global",
    enabled = true,
    speed = 4.0,
    bezier = "smoothDecel",
})

-- crisp pop without the weird molasses tail
hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 3.5,
    bezier = "snappyPop",
    style = "popin 80%",
})

-- fast exit so closing shit doesn't linger
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 2.5,
    bezier = "smoothDecel",
    style = "popin 85%",
})

-- moving/resizing windows shouldn't bounce like a trampoline
hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 3.5,
    bezier = "smoothDecel",
})

-- clean workspace glide
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 3.8,
    bezier = "smoothDecel",
    style = "slidefade 20%",
})

-- layers sliding and fading properly instead of flickering
hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 3.0,
    bezier = "smoothDecel",
    style = "fade",
})

-- fade shouldn't feel like a dying gpu artifact
hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 2.5,
    bezier = "smoothDecel",
})

-- border transition
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 3.0,
    bezier = "smoothDecel",
})

-- continuous spin so my brain gets dopamine
hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 25.0,
    bezier = "linear",
    style = "loop",
})