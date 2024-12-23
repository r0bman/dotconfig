local Highlite = require 'highlite' --- @type Highlite

local palette, terminal_palette = Highlite.palette 'highlite'
local groups = Highlite.groups('highlite', palette)

groups.CursorLineNr = {fg = palette.label}
groups.MsgSeparator = {fg = palette.text_contrast_bg_high}

Highlite.generate('highlite-custom', groups, terminal_palette)
