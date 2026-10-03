# fastfetch

the neofetch killer because we need system flex stats in 0.002 milliseconds or our fragile developer egos collapse.

neofetch was abandoned and slow. fastfetch is written in c and queries your hardware directly through kernel interfaces so fast you can't even see the syscall happen.

### output

```zsh
╭─[ you at nixos in hell ]
╰─ ❯ fastfetch                                                                                                                                                                                             13:37
          ▗▄▄▄       ▗▄▄▄▄    ▄▄▄▖             ashley@lost
          ▜███▙       ▜███▙  ▟███▛             -----------
           ▜███▙       ▜███▙▟███▛               os 󰅂       NixOS 24.25 (Patrick says 25 is funnier than 24) x86_64
            ▜███▙       ▜██████▛               󰌢 host 󰅂     preferably a thinkpad t42 (404 not found)
     ▟█████████████████▙ ▜████▛     ▟▙         󰌽 kernel 󰅂   Linux 6.6.6-idk
    ▟███████████████████▙ ▜███▙    ▟██▙        󰅐 uptime 󰅂   42 days, 13 hours, 37 mins
           ▄▄▄▄▖           ▜███▙  ▟███▛        󰏖 pkgs 󰅂     1337 (nix-user [777], nix-system [418], flatpak-system [73], flatpak-user [69])
          ▟███▛             ▜██▛ ▟███▛         󰞷 shell 󰅂    zsh 5.9
         ▟███▛               ▜▛ ▟███▛          󱂬 wm 󰅂       Hyprland 8.00.85 (Wayland)
▟███████████▛                  ▟██████████▙    󰞍 term 󰅂     kitty 0.49.2
▜██████████▛                  ▟███████████▛    󰍛 cpu 󰅂      12th Gen Intel® Core™ i7-1260P (16) @ 4.20 GHz [66.6°C]
      ▟███▛ ▟▙               ▟███▛             󰘚 mem 󰅂      6.94 GiB / 15.29 GiB (45%)
     ▟███▛ ▟██▙             ▟███▛              󰋊 disk 󰅂     13.37 GiB / 420.69 GiB (3%) - btrfs
    ▟███▛  ▜███▙           ▝▀▀▀▀               󰂄 bat 󰅂      69% [AC Connected, Charging]
    ▜██▛    ▜███▙ ▜██████████████████▛
     ▜▛     ▟████▙ ▜████████████████▛          ● ● ● ● ● ● ● ●
           ▟██████▙         ▜███▙
          ▟███▛▜███▙         ▜███▙
         ▟███▛  ▜███▙         ▜███▙
         ▝▀▀▀    ▀▀▀▀▘         ▀▀▀▘

╭─[ you at nixos in hell ]
╰─ ❯                                                                                                                                                                                                       13:37                                                                                                                                                                                           18:45
```

matugen dumps fresh accent colors into this every time you change wallpapers, which means that you will get colors that make windows noobs go "wow how do i get that"  
and u say:  
"u dont."  
