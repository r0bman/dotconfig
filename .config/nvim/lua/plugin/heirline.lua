--[[
 _          _      _ _                         _
| |__   ___(_)_ __| (_)_ __   ___   _ ____   _(_)_ __ ___
| '_ \ / _ \ | '__| | | '_ \ / _ \ | '_ \ \ / / | '_ ` _ \
| | | |  __/ | |  | | | | | |  __/_| | | \ V /| | | | | | |
|_| |_|\___|_|_|  |_|_|_| |_|\___(_)_| |_|\_/ |_|_| |_| |_|
--]]

local devicons = require 'nvim-web-devicons'

--[[/* CONSTANTS */]]

-- Defined in https://github.com/Iron-E/nvim-highlite
local BLACK        = '#202020'
local BLUE         = '#7766ff'
local CYAN         = '#33dbc3'
local GRAY_DARK    = '#353535'
local GRAY_LIGHT   = '#c0c0c0'
local GREEN        = '#22ff22'
local GREEN_DARK   = '#70d533'
local GREEN_LIGHT  = '#99ff99'
local ICE          = '#95c5ff'
local MAGENTA      = '#d5508f'
local MAGENTA_DARK = '#bb0099'
local ORANGE       = '#ff8900'
local ORANGE_LIGHT = '#f0af00'
local PINK         = '#ffa6ff'
local PINK_LIGHT   = '#ffb7b7'
local PURPLE       = '#cf55f0'
local PURPLE_LIGHT = '#af60af'
local RED          = '#ee4a59'
local RED_DARK     = '#a80000'
local RED_LIGHT    = '#ff4090'
local TAN          = '#f4c069'
local TEAL         = '#60afff'
local TURQOISE     = '#2bff99'
local WHITE        = '#ffffff'
local YELLOW       = '#f0df33'

local SIDEBAR = BLACK
local MIDBAR = GRAY_DARK
local TEXT = GRAY_LIGHT

--[[/* HELPERS */]]

--- The width of the screen
local columns = vim.api.nvim_get_option_value('columns', {})
vim.api.nvim_create_autocmd('VimResized', {
	callback = function() columns = vim.api.nvim_get_option_value('columns', {}) end,
	group = 'config',
})

do
	local command = 'doautocmd User BufEnterOrGitSignsUpdate'
	vim.api.nvim_create_autocmd('BufEnter', {command = command, group = 'config'})
	vim.api.nvim_create_autocmd('User', {command = command, group = 'config', pattern = 'GitSignsUpdate'})
end

--- Set buffer variables for file icon and color.
--- @return {color: string, icon: string}
local function buf_init_devicons()
	local icon, color = devicons.get_icon(vim.fn.expand '%:t', vim.fn.expand '%:e', {default = true})
	local dev_icons = {color = vim.api.nvim_get_hl(0, {link = false, name = color}).fg, icon = icon}

	vim.b.dev_icons = dev_icons
	return dev_icons
end

--- @return {color: string, icon: string}
local function filetype_info()
	return vim.b.dev_icons or buf_init_devicons()
end

--- Redraw the statusline
local redrawstatus = vim.schedule_wrap(function() vim.api.nvim_command 'redrawstatus' end)

--[[/* HEIRLINE CONFIG */]]

--- Components separated by this component will be padded with an equal number of spaces.
local ALIGN = {provider = '%='}

--- A left separator.
local LEFT_SEPARATOR = {provider = ''}

--- A right separator.
local RIGHT_SEPARATOR = {provider = ''}

require('heirline').setup({statusline =
{
	-- LEFT {{{
	{ -- ViMode {{{
		hl = function(self)
			vim.api.nvim_set_hl(0, self.group, {bg = SIDEBAR, fg = self.color, bold = true})
			return self.group
		end,
		init = function(self)
			if vim.g.libmodalActiveModeName then
				self.name = vim.g.libmodalActiveModeName
				self.color = self.modes[self.name]
			else
				local current_mode = self.modes[vim.api.nvim_get_mode().mode]

				self.name = current_mode[1]
				self.color = current_mode[2]
			end
		end,
		provider = function(self) return '▊ ' .. self.name .. ' ' end,
		static =
		{ -- {{{
			group = 'HeirlineViMode',
			modes =
			{
				['c']  = {'COMMAND-LINE', RED},
				['ce'] = {'NORMAL EX', RED_DARK},
				['cv'] = {'EX', RED_LIGHT},

				['i'] = {'INSERT', GREEN},

				['ic']  = {'INS-COMPLETE', GREEN_LIGHT},
				['ix']  = {'INS-COMPLETE', GREEN_LIGHT},
				['Rc']  = {'REP-COMPLETE', GREEN_LIGHT},
				['Rvc'] = {'VIRT-REP-COMPLETE', GREEN_LIGHT},
				['Rvx'] = {'VIRT-REP-COMPLETE', GREEN_LIGHT},
				['Rx']  = {'REP-COMPLETE', GREEN_LIGHT},

				['n']   = {'NORMAL', PURPLE_LIGHT},
				['niI'] = {'INS-NORMAL', PURPLE_LIGHT},
				['niR'] = {'REP-NORMAL', PURPLE_LIGHT},
				['niV'] = {'VIRT-REP-NORMAL', PURPLE_LIGHT},
				['nt']  = {'TERM-NORMAL', PURPLE_LIGHT},
				['ntT'] = {'TERM-NORMAL', PURPLE_LIGHT},

				['no']   = {'OPERATOR-PENDING', PURPLE},
				['nov']  = {'CHAR OPERATOR-PENDING', PURPLE},
				['noV']  = {'LINE OPERATOR-PENDING', PURPLE},
				['no'] = {'BLOCK OPERATOR-PENDING', PURPLE},

				['R']  = {'REPLACE', PINK},
				['Rv'] = {'VIRT-REPLACE', PINK_LIGHT},

				['r']   = {'HIT-ENTER', CYAN},
				['rm']  = {'--MORE', CYAN},
				['r?']  = {':CONFIRM', CYAN},

				['s']   = {'SELECT', TURQOISE},
				['S']   = {'SELECT LINE', TURQOISE},
				['']  = {'SELECT', TURQOISE},

				['v']   = {'VISUAL', BLUE},
				['vs']  = {'SEL-VISUAL', BLUE},
				['V']   = {'VISUAL LINE', BLUE},
				['Vs']  = {'SEL-VISUAL LINE', BLUE},
				['']  = {'VISUAL BLOCK', BLUE},
				['s'] = {'VISUAL BLOCK', BLUE},

				['t']   = {'TERMINAL', ORANGE},
				['!']   = {'SHELL', YELLOW},

				-- libmodal
				['BUFFERS'] = TEAL,
				['TABLES']  = ORANGE_LIGHT,
				['TABS']    = TAN,
			}
		}, -- }}}
		update = {'ModeChanged', callback = redrawstatus, pattern = '*:*'},
	}, -- }}}

	{ -- File Icon {{{
		hl = function(self) return {bg = SIDEBAR, fg = self.file.color} end,
		init = function(self) self.file = filetype_info() end,
		update = 'BufEnter',

		LEFT_SEPARATOR,
		{
			hl = function(self) return {bg = self.file.color, fg = SIDEBAR} end,
			provider = function(self) return ' ' .. self.file.icon .. ' %Y ' end,
		},

		RIGHT_SEPARATOR,
	}, -- }}}

	{ -- File Info {{{
		hl = {bg = SIDEBAR, bold = true, fg = TEXT},

		-- File name
		{provider = ' %t '},
		{ -- Readonly {{{
			condition = function() return vim.api.nvim_get_option_value('readonly', {buf = 0}) end,
			provider = ' ',
			update = {'OptionSet', pattern = 'readonly'},
		}, -- }}}

		{ -- Modified {{{
			condition = function() return vim.api.nvim_get_option_value('modified', {}) end,
			provider = ' ',
			update = 'BufModifiedSet',
		}, -- }}}

		{ -- File size {{{
			init = function(self) self.stat = vim.loop.fs_stat(vim.api.nvim_buf_get_name(0)) end,
			update = {'BufEnter', 'BufWritePost'},

			{
				condition = function(self) return self.stat end,
				provider = function(self)
					local size = self.stat.size

					local i = 1
					while size > self.conversion and i < #self.units do
						size = size / self.conversion
						i = i + 1
					end

					return ('%.2f%sb '):format(size, self.units[i])
				end,
				static = {conversion = 1024, units = {'', 'k', 'm', 'g', 't', 'p', 'e', 'z', 'y'}},
			},
		}, -- }}}

		{hl = {fg = MIDBAR}, LEFT_SEPARATOR},
	}, -- }}}
	-- }}}

	-- MIDDLE {{{
	{hl = {bg = MIDBAR}, ALIGN},

	{ -- Diagnostics {{{
		hl = {bg = MIDBAR, fg = SIDEBAR},
		init = function(self)
			local diagnostics = vim.diagnostic.get(0) --- @type Diagnostic[]

			if #diagnostics < 1 then
				self.diagnostics = nil
			else
				self.diagnostics = {0, 0, 0, 0}
				for _, diagnostic in ipairs(diagnostics) do
					self.diagnostics[diagnostic.severity] = self.diagnostics[diagnostic.severity] + 1
				end
			end
		end,
		update = {'BufEnter', 'DiagnosticChanged'},

		{
			condition = function(self) return self.diagnostics end,

			LEFT_SEPARATOR,
			{
				hl = {bg = SIDEBAR},
				static =
				{ -- {{{
					icons = {' ', ' ', ' ', ' '},

					--- @param severity 1|2|3|4
					--- @return nil|string
					provide = function(self, severity)
						if self.diagnostics[severity] > 0 then
							local str = self.icons[severity] .. self.diagnostics[severity]

							for i = severity + 1, #self.diagnostics do
								if self.diagnostics[i] > 0 then
									str = str .. ' '
									break
								end
							end

							return str
						end
					end,
				}, -- }}}

				{hl = {fg = RED}, provider = function(self) return self:provide(vim.diagnostic.severity.ERROR) end},
				{hl = {fg = ORANGE}, provider = function(self) return self:provide(vim.diagnostic.severity.WARN) end},
				{hl = {fg = PINK_LIGHT}, provider = function(self) return self:provide(vim.diagnostic.severity.INFO) end},
				{hl = {fg = MAGENTA}, provider = function(self) return self:provide(vim.diagnostic.severity.HINT) end},
			},

			RIGHT_SEPARATOR,
		},
	}, -- }}}
	-- }}}

	-- RIGHT {{{
	{hl = {bg = MIDBAR}, ALIGN},

	{ -- Git {{{
		init = function(self) self.status = vim.b.gitsigns_status_dict end,
		update = {'User', callback = redrawstatus, pattern = 'BufEnterOrGitSignsUpdate'},

		{ -- Diff {{{
			hl = {bg = MIDBAR},

			{
				condition = function(self) return self.status end,
				static =
				{
					--- @param sign string
					--- @param change string
					--- @return nil|string
					provide = function(self, sign, change)
						local count = self.status[change] or 0
						if count > 0 then return sign .. count end
					end,
				},

				{hl = {fg = GREEN}, provider = function(self) return self:provide('+', 'added') end},
				{hl = {fg = ORANGE_LIGHT}, provider = function(self) return self:provide('~', 'changed') end},
				{hl = {fg = RED_LIGHT}, provider = function(self) return self:provide('-', 'removed') end},
				{provider = ' '},
			},
		}, -- }}}

		{ -- Branch {{{
			hl = {bg = GREEN_DARK},

			{hl = {fg = MIDBAR}, RIGHT_SEPARATOR},
			{provider = ' '},
			{
				condition = function(self) return self.status end,
				hl = {fg = SIDEBAR, bold = true},
				provider = function(self) return ' ' .. self.status.head .. ' ' end,
			},

			{hl = {fg = SIDEBAR}, LEFT_SEPARATOR},
		}, -- }}}
	}, -- }}}

	-- Column Number
	{hl = {fg = TEXT, bg = SIDEBAR}, provider = '  %v '},

	{ -- Line Percentage {{{
		hl = {bg = MAGENTA_DARK},

		{hl = {fg = SIDEBAR}, RIGHT_SEPARATOR},
		{hl = {fg = WHITE}, provider = ' %p%% '},
	}, -- }}}

	-- }}}
}})
