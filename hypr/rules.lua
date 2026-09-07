-- don't let hyprland cook your solid borders and corners
hl.layer_rule({
    match = { namespace = "^quickshell:(?!corners|border).*" },
    blur = true,
    ignore_alpha = 0.5,
})

hl.layer_rule({
    match = { namespace = "^quickshell:corners$" },
    no_anim = true,
})