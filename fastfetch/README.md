# fastfetch

the neofetch killer because we need system flex stats in 0.002 milliseconds or our fragile developer egos collapse.

neofetch was abandoned and slow. fastfetch is written in c and queries your hardware directly through kernel interfaces so fast you can't even see the syscall happen.

### output

```zsh
╭─[ you at nixos in hell ]
╰─ ❯ fastfetch                                                                                                                                                                                             18:45
          ▗▄▄▄       ▗▄▄▄▄    ▄▄▄▖             ashley@lost
          ▜███▙       ▜███▙  ▟███▛             -----------
           ▜███▙       ▜███▙▟███▛               os 󰅂       NixOS 24.25 (Patrick says 25 is funnier than 24) x86_64
            ▜███▙       ▜██████▛               󰌢 host 󰅂     preferably a thinkpad
     ▟█████████████████▙ ▜████▛     ▟▙         󰌽 kernel 󰅂   Linux idk
    ▟███████████████████▙ ▜███▙    ▟██▙        󰅐 uptime 󰅂   61.55 days (should be 5318005 honestly)
           ▄▄▄▄▖           ▜███▙  ▟███▛        󰏖 pkgs 󰅂     15 (flatpak-system), 1 (flatpak-user), 80 (nix-system), 390 (nix-user)
          ▟███▛             ▜██▛ ▟███▛         󰞷 shell 󰅂    zsh
         ▟███▛               ▜▛ ▟███▛          󱂬 wm 󰅂       Hyprland 8.00.8.5 (Wayland)
▟███████████▛                  ▟██████████▙    󰞍 term 󰅂     kitty 0.48.2
▜██████████▛                  ▟███████████▛    󰍛 cpu 󰅂      12th Gen Intel® Core™ i7-1260P (16) @ 4.20 GHz
      ▟███▛ ▟▙               ▟███▛             󰘚 mem 󰅂      6.94 GiB / 15.29 GiB (30%)
     ▟███▛ ▟██▙             ▟███▛              󰋊 disk 󰅂     12 GiB / 420.69 GiB (5%) - btrfs
    ▟███▛  ▜███▙           ▝▀▀▀▀               󰂄 bat 󰅂      69% [AC Connected, Charging]
    ▜██▛    ▜███▙ ▜██████████████████▛
     ▜▛     ▟████▙ ▜████████████████▛          ● ● ● ● ● ● ● ●
           ▟██████▙         ▜███▙
          ▟███▛▜███▙         ▜███▙
         ▟███▛  ▜███▙         ▜███▙
         ▝▀▀▀    ▀▀▀▀▘         ▀▀▀▘

╭─[ you at nixos in hell ]
╰─ ❯                                                                                                                                                                                                       18:45
```

matugen dumps fresh accent colors into this every time you change wallpapers, which means that you will get colors that make windows noobs go "wow how do i get that"  
and u say:  
"u dont."  
