-- dynamic roast engine for breaking arrow key habits and learning IJKL
local M = {}

M.enabled = true
M.cooldown_ms = 2500
M.last_roast = 0

local roasts = {
    "⚠️ Arrow keys detected! What is this, 1998? Use IJKL.",
    "🚨 Bill Gates called. Even he thinks you should be using IJKL.",
    "💀 Arrow keys? Did GTA 6 drop while I wasn't looking? Use IJKL.",
    "🛑 Your fingers are literally 2 inches away from IJKL. Don't reach for the arrow keys!",
    "📉 My brother in Christ, you literally asked for IJKL. Use it!",
    "🤦 Reaching for the arrow keys like it's Microsoft Excel. Keep your hands on the home row.",
    "🎮 This isn't CoolMathGames. Use IJKL like a true Neovim artisan.",
    "🙅‍♂️ Arrow keys rejected. Muscle memory under active reconstruction.",
    "👀 I saw that. I (up), J (left), K (down), L (right). It's that simple.",
    "⚡ Break the habit before GTA 6 comes out. Hands back on IJKL!",
}

function M.roast()
    if not M.enabled then return end

    local now = vim.uv.now()
    if now - M.last_roast < M.cooldown_ms then
        return
    end
    M.last_roast = now

    local idx = math.random(1, #roasts)
    local msg = roasts[idx]
    vim.notify(msg, vim.log.levels.WARN, { title = "Roast Mode 🔥" })
end

function M.toggle()
    M.enabled = not M.enabled
    local state = M.enabled and "ENABLED 🔥" or "DISABLED 😴"
    vim.notify("Roast Mode is now " .. state, vim.log.levels.INFO, { title = "Roast Mode" })
end

-- command and user mapping
vim.api.nvim_create_user_command("RoastToggle", M.toggle, { desc = "Toggle arrow key roasting" })

-- bind arrow keys across normal, visual, and insert modes to trigger roast
local modes = { "n", "v", "i" }
local arrows = { "<Up>", "<Down>", "<Left>", "<Right>" }

for _, mode in ipairs(modes) do
    for _, arrow in ipairs(arrows) do
        vim.keymap.set(mode, arrow, function()
            M.roast()
        end, { desc = "arrow key roast reminder", silent = true })
    end
end

return M
