--[[
           _       _              _
 _ __ ___ (_)_ __ (_)  _ ____   _(_)_ __ ___
| '_ ` _ \| | '_ \| | | '_ \ \ / / | '_ ` _ \
| | | | | | | | | | |_| | | \ V /| | | | | | |
|_| |_| |_|_|_| |_|_(_)_| |_|\_/ |_|_| |_| |_|
--]]

--[[/* One line */]]

require('mini.ai').setup { mappings = { goto_left = '[g', goto_right = ']g' }, n_lines = 1000 }
require('mini.align').setup { mappings = { start = '<Leader>a', start_with_preview = '<Leader>A' } }
require('mini.comment').setup { options = { ignore_blank_line = true } }
require('mini.jump2d').setup({ mappings = { start_jumping = '<Space>' } })
require('mini.misc').setup_restore_cursor()
require('mini.surround').setup { n_lines = 1000 }

--[[/* Multiline */]]

require('mini.move').setup
{
	mappings =
	{
		down = 'gj',      left = 'gh',      right = 'gl',      up = 'gk',
		line_down = 'gj', line_left = 'gh', line_right = 'gl', line_up = 'gk',
	},
}

require('mini.operators').setup
{
	evaluate = { prefix = 'g=' },
	exchange = { prefix = 'gs' },
	multiply = { prefix = 'gm' },
	replace = { prefix = 'gp' },
	sort = { prefix = 'go' },
}

--[[/* Advanced */]]

do --[[/* mini.files */]]
	--- @class mini.Entry
	--- @field fs_type 'file'|'directory'
	--- @field name string basename of the FS entry (including extension)
	--- @field path string the full path of an entry

	local files = require 'mini.files'
	files.setup
	{
		--- @type {[string]: fun(entry: mini.Entry): boolean}
		content = {filter = function(entry)
			return not (entry.fs_type == 'directory' and (
				entry.name == '.cache' or
				entry.name == '.git' or
				entry.name == 'node_modules'
			))
		end},

		mappings = {go_in = 'L', go_in_plus = 'l', synchronize = '<Enter>'},
		windows = {preview = true},
	}

	--- @param close? boolean
	--- @param vertical? boolean
	--- @return fun()
	local function open_file_in_split(close, vertical)
		local go_in_opts = {close_on_file = close}
		local split_opts = {mods = {split = 'belowright', vertical = vertical}}
		return function()
			local entry = files.get_fs_entry() --- @type mini.Entry|nil
			if entry and entry.fs_type == 'file' then
				vim.api.nvim_win_call(files.get_target_window(), function()
					vim.cmd.split(split_opts)
					files.set_target_window(vim.api.nvim_get_current_win())
				end)
			end

			files.go_in(go_in_opts)
		end
	end

	--- @param chdir fun(dir: string): boolean|nil # returns `true` if it changed the tab-local directory
	--- @return fun()
	local function set_dir_to_entry(chdir)
		return function()
			local entry = files.get_fs_entry() --- @type mini.Entry|nil
			if entry == nil then return vim.notify('No FS entry selected', vim.log.levels.INFO) end
			local dir = vim.fs.dirname(entry.path)
			vim.notify(':' .. (chdir(dir) and 't' or '') .. 'cd changed to ' .. vim.inspect(dir), vim.log.levels.INFO)
		end
	end

	vim.api.nvim_create_autocmd('User', {
		pattern = 'MiniFilesBufferCreate',
		callback = function(args)
			local buf = args.data.buf_id

			vim.api.nvim_buf_set_keymap(buf, 'n', '<C-s>', '', {
				callback = open_file_in_split(true, true),
				desc = 'Open file in vertical split and close file browser',
			})

			vim.api.nvim_buf_set_keymap(buf, 'n', '<C-w>s', '', {
				callback = open_file_in_split(false),
				desc = 'Open file in horizontal split',
			})

			vim.api.nvim_buf_set_keymap(buf, 'n', '<C-w>v', '', {
				callback = open_file_in_split(false, true),
				desc = 'Open file in vertical split',
			})

			vim.api.nvim_buf_set_keymap(buf, 'n', '<C-x>', '', {
				callback = open_file_in_split(true),
				desc = 'Open file in horizontal split and close file browser',
			})

			vim.api.nvim_buf_set_keymap(buf, 'n', 'gf', '', {
				callback = set_dir_to_entry(function(dir) vim.loop.chdir(dir) end),
				desc = 'Set current directory',
			})

			vim.api.nvim_buf_set_keymap(buf, 'n', 'gF', '', {
				callback = set_dir_to_entry(function(dir)
					vim.cmd.tcd {args = {dir}}
					return true
				end),
				desc = 'Set the tab-local directory',
			})
		end,
	})

	vim.api.nvim_create_autocmd('User', {
		pattern = 'MiniFilesWindowOpen',
		callback = function(args) vim.api.nvim_win_set_config(args.data.win_id, { border = 'rounded' }) end,
	})

	vim.api.nvim_set_keymap('n', '<A-w>e', '', {desc = 'Focus current file in file explorer', callback = function()
		if not files.close() then
			files.open(vim.api.nvim_buf_get_name(0))
			files.reveal_cwd()
		end
	end})

	vim.api.nvim_set_keymap('n', '<A-w>E', '', {desc = 'Resume previous file exploration.', callback = function()
		return files.close() or files.open(files.get_latest_path())
	end})
end

do --[[/* mini.jump */]]
	local jump = require 'mini.jump'
	jump.setup {mappings = {repeat_jump = ''}}

	vim.api.nvim_create_autocmd('CursorHold', {callback = jump.stop_jumping, group = 'config'})
	vim.api.nvim_set_keymap('n', ',', '', {callback = function() jump.jump(nil, true, nil, vim.v.count1) end})
	vim.api.nvim_set_keymap('n', ';', '', {callback = function() jump.jump(nil, false, nil, vim.v.count1) end})
end

do --[[/* mini.notify */]]
	local notify = require('mini.notify')
	notify.setup { window = { config = { border = 'rounded' } } }
	vim.notify = notify.make_notify {
		DEBUG = { hl_group = 'DiagnosticFloatingHint' },
		ERROR = { hl_group = 'DiagnosticFloatingError' },
		INFO  = { hl_group = 'DiagnosticFloatingInfo' },
		TRACE = { hl_group = 'DiagnosticFloatingOk' },
		WARN  = { hl_group = 'DiagnosticFloatingWarn' },
	}

	vim.api.nvim_create_user_command('Messages', 'lua MiniNotify.show_history()', { desc = 'Show MiniNotify log' })
end

do --[[/* mini.splitjoin */]]

	local split_join = require 'mini.splitjoin'
	local gen_hook = split_join.gen_hook

	local brace = '%b{}'
	local bracket = '%b[]'
	local paren = '%b()'

	local all = { brackets = { brace, bracket, paren } }
	local braces = { brackets = { brace } }
	local not_parens = { brackets = { brace, bracket } }

	split_join.setup
	{
		detect = { separator = ',' },
		join = { hooks_post = { gen_hook.del_trailing_separator(all), gen_hook.pad_brackets(braces) } },
		split = { hooks_post = { gen_hook.add_trailing_separator(not_parens) } },
	}

	local bvar = 'minisplitjoin_config'
	vim.api.nvim_create_autocmd('FileType', {
		callback = function(ev)
			vim.api.nvim_buf_set_var(ev.buf, bvar, { split = { hooks_post = { gen_hook.add_trailing_separator(all) } } })
		end,
		group = 'config',
		pattern = {'go', 'rust', 'typescript', 'typescriptreact', 'typst'},
	})

	vim.api.nvim_create_autocmd('FileType', {
		callback = function(ev) vim.api.nvim_buf_set_var(ev.buf, bvar, { split = { hooks_post = {} } }) end,
		group = 'config',
		pattern = {'json', 'nix', 'sql'},
	})
end

do --[[/* mini.trailspace */]]
	local trailspace = require 'mini.trailspace'
	vim.api.nvim_create_autocmd('BufWritePre', {
		group = 'config',
		callback = function(ev)
			local buf = ev.buf
			if not vim.api.nvim_get_option_value('binary', {buf = buf}) and
				vim.api.nvim_get_option_value('filetype', {buf = buf}) ~= 'diff'
			then
				trailspace.trim_last_lines()
			end
		end,
	})
end

do --[[/* mini.visits */]]
	local visits = require 'mini.visits'
	visits.setup()

	vim.api.nvim_set_keymap('n', '<Leader>va', '', {
		desc = 'MiniVisits label add',
		callback = visits.add_label,
		noremap = true,
	})

	vim.api.nvim_set_keymap('n', '<Leader>vl', '', {
		desc = 'MiniVisits label select',
		callback = visits.select_label,
		noremap = true,
	})

	vim.api.nvim_set_keymap('n', '<Leader>vp', '', {
		callback = visits.select_path,
		desc = 'MiniVisits path select',
		noremap = true,
	})

	vim.api.nvim_set_keymap('n', '<Leader>vr', '', {
		callback = visits.remove_label,
		desc = 'MiniVisits label remove',
		noremap = true,
	})
end
