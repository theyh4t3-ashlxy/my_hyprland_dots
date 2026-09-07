-- don't let hyprland cook your solid borders and corners
hl.layer_rule({
    match = { namespace = "^quickshell:(?!corners|border).*" },
    blur = true,
    ignore_alpha = 0.1,
})

hl.layer_rule({
    match = { namespace = "^quickshell:corners$" },
    no_anim = true,
})

-- pipewire controller shouldn't take up your entire display when you just want to tweak a slider
hl.window_rule({
    name = "pipewire-controller-float",
    match = { class = "^io.github.knightinfected.PipeWireControlCenter$" },
    float = true,
})