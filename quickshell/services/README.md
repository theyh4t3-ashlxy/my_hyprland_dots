# services

the unholy singletons talking to linux subsystems so your ui doesn't have to get its hands dirty.

if the widgets are the glossy face of the setup, this directory is the central nervous system. dbus listeners, wireplumber audio pipes, network status probes, backlight sysfs readers, and persistent storage engines all live here as shared singletons.

## the daemon council
- `Settings.qml`: the config kingpin. persists bar positions, widget orders, colors, and the newly anointed `fontMaterial` settings to disk without corrupting your config.
- `NotificationService.qml`: native freedesktop `org.freedesktop.Notifications` dbus implementation. catches alerts before they get lost in void space.
- `NetworkService.qml`: listens to networkmanager dbus signals to report real-time wifi ssids, ethernet connectivity, and signal strength.
- `BrightnessService.qml`: talks directly to `/sys/class/backlight` so your display brightness slider actually slides.
- `IdleService.qml`: hooks into hypridle and idle-inhibition protocols so your monitor doesn't shut down during code compilation or movies.
- `WallpaperService.qml`: monitors active wallpapers and drives the background generation pipelines.
