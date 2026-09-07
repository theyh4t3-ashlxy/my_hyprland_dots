# notifications

do not disturb is for the weak, but notification spam is an attack vector on your sanity.

dunst and mako are ancient relics. here, notifications are native wayland surfaces that glide onto your screen like silk, display rich action buttons, and vanish without cluttering your system memory.

## the dispatchers
- `NotificationToasts.qml`: stack manager positioning floating toast cards in the corner of your active monitor. handles automatic expiration timers, swipe-to-dismiss drag physics, and smooth entry/exit spring transitions.
- `NotificationCard.qml`: the visual payload. renders the app icon, title, message body, urgency highlights, timestamp, and clickable freedesktop action buttons.
