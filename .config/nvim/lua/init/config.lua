--[[
 __  __ _             _____             __ _
|  \/  (_)           / ____|           / _(_)
| \  / |_ ___  ___  | |     ___  _ __ | |_ _  __ _
| |\/| | / __|/ __| | |    / _ \| '_ \|  _| |/ _` |
| |  | | \__ \ (__  | |___| (_) | | | | | | | (_| |
|_|  |_|_|___/\___|  \_____\___/|_| |_|_| |_|\__, |
                                              __/ |
                                             |___/
--]]

vim.api.nvim_set_option_value('background', 'dark', {})      -- Use a dark background
vim.api.nvim_set_option_value('breakindent', true, {})       -- Preserve tabs when wrapping lines.
vim.opt.completeopt = {'menuone', 'noinsert', 'noselect'}    -- Completion visual settings
vim.api.nvim_set_option_value('concealcursor', 'nc', {})     -- Don't unconceal in normal or command mode
vim.api.nvim_set_option_value('cursorline', true, {})        -- Highlight current line
vim.opt.diffopt:append 'linematch:60'                        -- Highlight inline diffs
vim.opt.fillchars = {fold = ' ', msgsep = '▔'}               -- Set folds to not trail dots
vim.api.nvim_set_option_value('foldexpr', 'v:lua.vim.treesitter.foldexpr()', {}) -- Use treesitter for folds
vim.api.nvim_set_option_value('foldmethod', 'expr', {})      -- Set folding to occur from a marker
vim.api.nvim_set_option_value('foldtext', 'v:lua.NeatFoldText()', {}) -- Set text of folds
vim.api.nvim_set_option_value('grepprg', 'rg --vimgrep', {}) -- Use ripgrep instead of grep.
vim.api.nvim_set_option_value('guicursor', '', {})           -- Remove vertical cursor from insert mode
vim.api.nvim_set_option_value('ignorecase', true, {})        -- Case insensitive search by default
vim.api.nvim_set_option_value('inccommand', 'split', {})     -- Show regular expression previews in a split
vim.api.nvim_set_option_value('laststatus', 3, {})           -- Only show a statusline at the bottom of the screen
vim.api.nvim_set_option_value('lazyredraw', true, {})        -- Redraw screen less often
vim.api.nvim_set_option_value('linebreak', true, {})         -- Break lines at whole words
vim.api.nvim_set_option_value('number', true, {})            -- Show the current line number
vim.api.nvim_set_option_value('relativenumber', true, {})    -- Line numbers relative to current line
vim.api.nvim_set_option_value('shiftwidth', 0, {})           -- Use tabstop
vim.api.nvim_set_option_value('showmode', false, {})         -- Don't show the mode name under the statusline
vim.api.nvim_set_option_value('showtabline', 0, {})          -- Don't show the tabline until tabline plugins load
vim.api.nvim_set_option_value('smartcase', true, {})         -- Case sensitive when a capital is provided
vim.api.nvim_set_option_value('smartindent', true, {})       -- More intelligent 'autoindent' preset
vim.api.nvim_set_option_value('softtabstop', -1, {})         -- Use shiftwidth
vim.api.nvim_set_option_value('spell', true, {})             -- Check spelling
vim.api.nvim_set_option_value('splitbelow', true, {})        -- Splits open below
vim.api.nvim_set_option_value('splitright', true, {})        -- Splits open to the right
vim.api.nvim_set_option_value('tabstop', 3, {})              -- How many spaces a tab is worth
vim.api.nvim_set_option_value('termguicolors', true, {})     -- Set color mode
vim.api.nvim_set_option_value('undodir', vim.fn.stdpath('state') .. '/undodir', {}) -- Put undo history in the state dir
vim.api.nvim_set_option_value('undofile', true, {})          -- Persist undo history
vim.opt.viewoptions = {'cursor', 'folds'}                    -- Save cursor position and folds in `:mkview`
vim.api.nvim_set_option_value('visualbell', true, {})        -- Disable beeping
vim.opt.wildignore = {'*.bak', '*.cache', '*/.git/**/*', '*.min.*', '*/node_modules/**/*', '*.pyc', '*.swp'}
vim.api.nvim_set_option_value('wildignorecase', true, {})    -- Ignore case for command completions
vim.opt.wildmode = {'longest:full', 'full'}                  -- Command completion mode

if _G['nvim >= 0.10'] then
	vim.api.nvim_set_option_value('smoothscroll', true, {})
end

-- WARN: Providers (MUST be `0`, not `false`)
vim.g.loaded_node_provider = 0 -- disable javascript
vim.g.loaded_perl_provider = 0 -- disable Perl
vim.g.loaded_python3_provider = 0 -- disable Python 3
vim.g.loaded_ruby_provider = 0 -- disable Ruby

--[[
   ___       __                                         __
  / _ |__ __/ /____  _______  __ _  __ _  ___ ____  ___/ /__
 / __ / // / __/ _ \/ __/ _ \/  ' \/  ' \/ _ `/ _ \/ _  (_-<
/_/ |_\_,_/\__/\___/\__/\___/_/_/_/_/_/_/\_,_/_//_/\_,_/___/
--]]
local augroup = vim.api.nvim_create_augroup('config', {clear = false})

--- Reset my indent guide settings
vim.api.nvim_create_autocmd({'BufWinEnter', 'BufWritePost', 'InsertLeave'},
{
	callback = function()
		vim.api.nvim_set_option_value('list', true, {})
		vim.opt.listchars = {nbsp = '␣', tab = '│ ', trail = '•'}
		vim.api.nvim_set_option_value('showbreak', '└ ', {})
	end,
	group = augroup,
})

--- Sync syntax when not editing text
vim.api.nvim_create_autocmd('CursorHold',
{
	callback = function(event)
		if vim.api.nvim_get_option_value('syntax', { buf = event.buf }) ~= '' then
			vim.api.nvim_command 'syntax sync fromstart'
		end

		if vim.lsp.semantic_tokens then
			vim.lsp.semantic_tokens.force_refresh(event.buf)
		end
	end,
	group = augroup,
})

vim.api.nvim_create_autocmd('BufWinEnter', {
	callback = function(event)
		local buf = event.buf == 0 and vim.api.nvim_get_current_buf() or event.buf
		local win = vim.api.nvim_get_current_win()
		vim.defer_fn(function() -- because editorconfigs can change this setting
			if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_win_is_valid(win) then
				local textwidth = vim.api.nvim_get_option_value('textwidth', { buf = buf })
				vim.api.nvim_set_option_value('colorcolumn', tostring(textwidth), { win = win })
			end
		end, 100)
	end,
	group = augroup,
})

vim.api.nvim_create_autocmd({'FocusGained', 'VimResume'}, {command = 'checktime', group = augroup})

--- Highlight yanks
vim.api.nvim_create_autocmd('TextYankPost',
{
	callback = function() vim.highlight.on_yank() end,
	group = augroup,
})

if vim.fn.has 'wsl' == 1 then
	vim.api.nvim_create_autocmd('TextYankPost',
	{
		command = [[call system('clip.exe ',@")]],
		group = augroup,
	})
end

--[[
  _____                              __
 / ___/__  __ _  __ _  ___ ____  ___/ /__
/ /__/ _ \/  ' \/  ' \/ _ `/ _ \/ _  (_-<
\___/\___/_/_/_/_/_/_/\_,_/_//_/\_,_/___/
--]]
do -- Brightness
	--- @param count number
	local function cmd(count)
		local opts = {'brightnessctl', 'set', math.abs(count * 5) .. '%' .. (count > -1 and '+' or '-')}
		if _G['nvim >= 0.10'] then
			vim.system(opts, {}, vim.schedule_wrap(function(shell)
				vim.notify(vim.trim(vim.split(shell.stdout, '\n', {trimpempty = true})[3]))
			end))
		else
			vim.fn.systemlist(opts)
		end
	end

	local opts = {count = 1, force = true}
	vim.api.nvim_create_user_command('BrightnessCtl', function(tbl) cmd(tbl.count) end, opts)
	vim.api.nvim_create_user_command('DarknessCtl', function(tbl) cmd(-tbl.count) end, opts)
end

vim.api.nvim_create_user_command('Win',
	function(tbl)
		local bufwinnr = vim.fn.bufwinid(tbl.args)
		vim.api.nvim_set_current_win(bufwinnr)
	end,
	{
		complete = function()
			return vim.iter(vim.api.nvim_list_bufs())
				:filter(function(bufnr) return vim.fn.bufwinid(bufnr) ~= -1 end)
				:map(vim.fn.bufname)
				:totable()
		end,
		desc = 'Focus the given window',
		nargs = 1,
	}
)

do -- Redshift
	local REDSHIFT_COLORS = {b = 5500, o = 2000, r = 1300, y = 3750}

	--- @param color string
	local function cmd(color)
		local opts = {'redshift', '-PO', REDSHIFT_COLORS[color:sub(1, 1)]}
		if _G['nvim >= 0.10'] then
			vim.system(opts)
		else
			vim.fn.systemlist(opts)
		end
	end

	vim.api.nvim_create_user_command('Redshift', function(tbl) cmd(tbl.args) end, {
		complete = function() return {'blue', 'orange', 'red', 'yellow'} end,
		force = true,
		nargs = 1,
	})
end

-- Space-Tab Conversion
vim.api.nvim_create_user_command(
	'SpacesToTabs',
	function(tbl)
		vim.api.nvim_set_option_value('expandtab', false, {scope = 'local'})
		local previous_tabstop = vim.api.nvim_get_option_value('tabstop', {})
		vim.api.nvim_set_option_value('tabstop', tonumber(tbl.args), {scope = 'local'})
		vim.api.nvim_command 'retab!'
		vim.api.nvim_set_option_value('tabstop', previous_tabstop, {scope = 'local'})
	end,
	{force = true, nargs = 1}
)

vim.api.nvim_create_user_command(
	'Typora',
	_G['nvim >= 0.10'] and function(tbl)
		vim.system({'typora', tbl.args == '' and vim.api.nvim_buf_get_name(0) or tbl.args}, {detach = true})
	end or function(tbl)
		vim.fn.systemlist({'typora', tbl.args == '' and vim.api.nvim_buf_get_name(0) or tbl.args, '&'})
	end,
	{complete = 'file', nargs = '?'}
)

vim.api.nvim_create_user_command(
	'TabsToSpaces',
	function(tbl)
		vim.api.nvim_set_option_value('expandtab', true, {scope = 'local'})
		local previous_tabstop = vim.api.nvim_get_option_value('tabstop', {scope = 'local'})
		vim.api.nvim_set_option_value('tabstop', tonumber(tbl.args), {scope = 'local'})
		vim.api.nvim_command 'retab'
		vim.api.nvim_set_option_value('tabstop', previous_tabstop, {scope = 'local'})
	end,
	{force = true, nargs = 1}
)

-- Fat fingering
vim.api.nvim_create_user_command('W', 'w', {})
vim.api.nvim_create_user_command('Wq', 'wq', {})
vim.api.nvim_create_user_command('Wqa', 'wqa', {})
vim.api.nvim_create_user_command('X', 'x', {})
vim.api.nvim_create_user_command('Xa', 'xa', {})

--[[
   ____              __  _
  / __/_ _____  ____/ /_(_)__  ___  ___
 / _// // / _ \/ __/ __/ / _ \/ _ \(_-<
/_/  \_,_/_//_/\__/\__/_/\___/_//_/___/
--]]

--- Benchmark some `fn`, printing the average time it takes to run given the number of `loops`.
--- @param fn fun(i: integer) the code to benchmark
--- @param loops? integer the number of times to run the code. Higher number = more accurate averate
function Bench(fn, loops)
	loops = loops or 100000

	local now = vim.loop.hrtime --- @type fun(): integer
	local total = 0

	for i = 1, loops do
		local start = now()
		fn(i)
		total = total + (now() - start)
	end

	print(total / loops)
end

--- @return string fold_text a neat template for the summary of what is on a fold
function NeatFoldText()
	local end_ = vim.v.foldend --- @type number
	local start = vim.v.foldstart --- @type number

	local lines = { start, end_ }
	for i, line_nr in ipairs(lines) do
		local line = vim.api.nvim_buf_get_lines(0, line_nr - 1, line_nr, true)[1]
		lines[i] = line
	end

	--- @cast lines string[]

	do
		local columns = vim.api.nvim_win_get_width(0)
		local first_line = lines[1]
		local first_line_len = #first_line

		-- NOTE: 10 is the magic number for the base width of the template line.
		--       5 is a heuristic because linenr/sign column width is indeterminable
		--       3 is the magic number for joining the lines
		local needed_width = #lines[2] + 10 + 5 + 3

		if first_line_len + needed_width > columns then
			local overflow = math.abs(first_line_len - columns)

			-- NOTE: 5 is the magic number for the replacement len.
			local remove = math.ceil(bit.rshift(overflow, 1) + needed_width + 5)
			local middle = bit.rshift(first_line_len, 1)

			lines[1] = first_line:sub(1, middle - remove) .. ' […] ' .. first_line:sub(middle + remove)
		end
	end

	return ('   %-6d%s'):format(end_ - start + 1, table.concat(lines, ' … '))
end
