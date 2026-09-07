# gtk-3.0

legacy gnome baggage that refuses to die peacefully.

why does css have to infect every corner of computing? nobody knows. but gtk3 applications still haunt our system (file pickers, legacy browsers, older tools), and if left unattended, they will render blinding white frames that burn your retinas.

## the damage control
- `settings.ini`: orders gtk3 to stop using adwaita light and enforce a dark color scheme alongside proper cursor and font scales.
- `gtk.css`: imports generated color palettes and strips away ugly borders.
- `colors.css`: matugen's victim. dynamically generated css variables extracted straight from your current wallpaper.
- `bookmarks`: quick file picker paths so you don't have to wander through `/home` like an archaeologist lost in a cave.
