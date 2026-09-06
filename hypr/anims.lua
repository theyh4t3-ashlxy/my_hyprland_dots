-- chaotic punch that peaks around the halfway mark and cushions the landing
hl.curve("superSnappy", {
    type = "bezier",
    points = { { 0.18, 1.25 }, { 0.4, 1.0 } },
})

-- crisp flick that rolls out its momentum instead of freezing mid-slide
hl.curve("smoothOut", {
    type = "bezier",
    points = { { 0.22, 1.0 }, { 0.42, 1.0 } },
})

hl.curve("linear", {
    type = "bezier",
    points = { { 0.0, 0.0 }, { 1.0, 1.0 } },
})

hl.animation({
    leaf = "global",
    enabled = true,
    speed = 3.8,
    bezier = "smoothOut",
})

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 3.6,
    bezier = "superSnappy",
    style = "popin 80%",
})

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 3.6,
    bezier = "smoothOut",
    style = "slidefade 15%",
})

hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 2.4,
    bezier = "smoothOut",
    style = "fade",
})

hl.animation({
    leaf = "border",
    enabled = true,
    speed = 1.8,
    bezier = "superSnappy",
})

hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 30.0,
    bezier = "linear",
    style = "loop",
})