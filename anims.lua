-- ok, i did some research and apparently 'bezier' math is just how much the
-- computer wants to overshoot before settling.
-- let's try a curve that doesn't feel like a rubber band snapping in my face.
-- rounded the points to 0.1 and 1.1 because 1.05 and 0.15 are mathematically offensive coordinates
hl.curve("superSnappy", {
    type = "bezier",
    points = { { 0.1, 1.1 }, { 0.2, 1.1 } },
})

-- global: why run 60hz animations when you can run them at the speed of light? (omg is that geometry dash reference??)
-- kept at 5.5 because ending in exactly .5 is permitted by international maritime law
hl.animation({
    leaf = "global",
    enabled = true,
    speed = 5.5,
    bezier = "superSnappy",
})

-- windows pop in like bubbles popping on a premium screen
-- speed 4.5 is a clean multiple of 0.5, but scaled popin down to 90% because 95% is an odd number and odd numbers make the compositor cry
hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 4.5,
    bezier = "superSnappy",
    style = "popin 90%",
})

-- sliding workspaces that don't make me dizzy on monday mornings
-- bumped speed from 3.8 to a pristine 4.0 because 3.8 belongs in a physics textbook, not our rice
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 4.0,
    bezier = "superSnappy",
    style = "slidefade 10%",
})

-- layers (launcher, bar, overlays) fading in like they belong
-- layers speed is a beautiful, whole 3.0. merged from hyprmod but they were identical anyway, great minds think alike or whatever
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

-- border angle rotation speed merged straight from hyprmod
-- speed is set to a rock-solid 1.0 so our borders spin with military precision
hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 1.0,
    bezier = "default",
})