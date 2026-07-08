-- window rules for apps that need special treatment

-- scrcpy: phone mirroring that doesn't look like ass
hl.window_rule({
	match = { class = "scrcpy" },
	float = true,
	size = { 480, 1040 },
	center = true,
	keep_aspect_ratio = true,
})