# post-hook-scripts

scripts that wake up apps after matugen paints their config files.

writing new colors to a config file on disk is useless if the running process doesn't notice. this directory houses the blunt-force instruments that slap running daemons across the face until they reload.

## the enforcers
- `gtk-themes-reload.zsh`: toggles gsettings and sends reload events to gtk3 and gtk4 so apps don't end up stuck in a half-dark, half-clown mode existential crisis.
