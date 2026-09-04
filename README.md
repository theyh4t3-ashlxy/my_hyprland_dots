> [!WARNING]
> THERE IS AI SLOP ALL OVER THIS REPO!! you have been warned!

hi! this is my hyprland dots.   
gemini through antigravity and ai studio vibecoded this.  
(sometimes it just halucinates BAD, hence why ai studio exists)

ok actual shell starts here dont cry

# what got fixed & unfucked

- [x] bar got unfucked, 4-way docking works seamlessly in top, bottom, left, and right with dynamic transforms
- [x] widget loader visibility deadlock dead and buried (all 15 widgets load instantly)
- [x] native layer-shell osd overlay for volume, mic mute, and brightness changes
- [x] dynamic multi-tier battery glyphs (11 levels, charging, saver, and vertical bar orientation)
- [x] multi-pack iconography: Microsoft Segoe Fluent Icons, Material Design, and Font Awesome with automatic nerd font fallback
- [x] screen corner scoops match matugen theme instead of pitch black bars
- [x] screen corners auto-hide in fullscreen so movies and games aren't cursed
- [x] local wi-fi ssid renaming right inside the network status card
- [x] lock screen running on native `PamContext` (hyprlock nuked)
- [x] `nmcli` script hacks eradicated in favor of native `Quickshell.Networking`
- [x] settings organized into clean categorized groups with 100% synchronous `FileView` persistence
- [x] calendar day header token bug squashed (no more "day DDD of 2026")
- [x] hyprland 0.55 lua dispatch syntax restored for workspaces
- [x] zsh overhauled: compinit cached, bytecode auto-compilation, zero dead imports, 50+ existential roasts

this section is cursed do not linger

# known issues rn
*(will fix when claude models go back in antigravity, which is in like 2 hours. idk)*

- [ ] inconsistencies around the ui (specifically animations, but also some refinements)
- [ ] animations not matching. [settings](quickshell/widgets/QuickSettings.qml) (technically its all animation presets not just hyprland anims file)

# will refine

- [ ] interactive physics lab in motion sandbox
- [ ] give me ideas too  

# how to complain (or "contribute")

make an issue. i'll eventually pass it on to antigravity or google jules. whatever works.  
when jules is done codin, i'll accept its changes.  
(be rude to it, or dont. idc)  

# if you wanna be a human coder and fix the hallucinations 
*(which the ai will call u out and say its incorrect)*  

make a pull request, and i'll accept the changes. or fork and make ur own distro outta dots. idgaf  
