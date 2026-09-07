# fastfetch

the neofetch killer because we need system flex stats in 0.002 milliseconds or our fragile developer egos collapse.

neofetch was abandoned and slow. fastfetch is written in c and queries your hardware directly through kernel interfaces so fast you can't even see the syscall happen.

## structure
- `config.jsonc`: json with comments because fastfetch actually has taste and standard json is a crime against humanity. defines distro banners, kernel versions, uptime, package counts, active shell, wm details, memory consumption, and dynamic color blocks.

matugen dumps fresh accent colors into this every time you change wallpapers, ensuring your terminal flex screenshots look immaculate when posted to people who do not care.
