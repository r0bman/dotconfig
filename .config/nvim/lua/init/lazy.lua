--[[
 _                              _
| | __ _ _____   _   _ ____   _(_)_ __ ___
| |/ _` |_  / | | | | '_ \ \ / / | '_ ` _ \
| | (_| |/ /| |_| |_| | | \ V /| | | | | | |
|_|\__,_/___|\__, (_)_| |_|\_/ |_|_| |_| |_|
             |___/
--]]

--[[/* Vars */]]

local has_nvim_10 = _G['nvim >= 0.10'];
local not_man = vim.g.man ~= true

--- Return a wrapper function which loads the `plugin`'s configuration file
--- @param plugin string
--- @return fun()
local function req(plugin)
	return function() require('plugin.' .. plugin) end
end

--[[/* Install lazy.nvim */]]

local data_dir = vim.fn.stdpath 'data'
local install_dir = data_dir .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(install_dir) then
	vim.fn.system
	{
		'git', 'clone', '--filter=blob:none',
		'https://github.com/folke/lazy.nvim.git', '--branch=stable',
		install_dir
	}
end

--[[/* Load plugins */]]

local new_file_read_file = { 'BufNewFile', 'BufReadPre' }

vim.opt.rtp:prepend(install_dir)
require('lazy').setup(
	{
		{'folke/lazy.nvim', tag = 'stable'},

		--[[ Programming
			___                                     _
		  / _ \_______  ___ ________ ___ _  __ _  (_)__  ___ _
		 / ___/ __/ _ \/ _ `/ __/ _ `/  ' \/  ' \/ / _ \/ _ `/
		/_/  /_/  \___/\_, /_/  \_,_/_/_/_/_/_/_/_/_//_/\_, /
						  /___/                            /___/
		--]]

		--[[ Completion
		 _
		/  _ ._ _ ._ | __|_o _ ._
		\_(_)| | ||_)|(/_|_|(_)| |
					 |
		--]]

		{'hrsh7th/nvim-cmp',
			config = function(_, o)
				--- @return boolean # `true` if the cursor is on a word
				local function cursor_on_word()
					local col = vim.api.nvim_win_get_cursor(0)[2]
					return col ~= 0 and vim.api.nvim_get_current_line():sub(col, col):find '%s' == nil
				end

				local cmp = require 'cmp'
				local kind = require('cmp.types').lsp.CompletionItemKind --- @type lsp.CompletionItemKind
				local luasnip = require 'luasnip'

				cmp.setup(
				{
					formatting = o.formatting,
					snippet =  { expand = function(args) luasnip.lsp_expand(args.body) end },
					window = o.window,

					mapping =
					{
						['<C-b>'] = cmp.mapping.scroll_docs(-20),
						['<C-f>'] = cmp.mapping.scroll_docs(20),
						['<C-Space>'] = cmp.mapping.confirm { behavior = cmp.ConfirmBehavior.Insert, select = true },

						--- @param fallback fun()
						['<C-n>'] = cmp.mapping(function(fallback)
							if not cmp.select_next_item() then
								if cursor_on_word() then
									cmp.complete()
								else
									fallback()
								end
							end
						end),

						--- @param fallback fun()
						['<C-p>'] = cmp.mapping(function(fallback)
							if not cmp.select_prev_item() then
								if cursor_on_word() then
									cmp.complete()
								else
									fallback()
								end
							end
						end),

						--- @param fallback fun()
						['<Tab>'] = cmp.mapping(function(fallback)
							if not cmp.select_next_item() then
								if luasnip.expand_or_locally_jumpable() then
									luasnip.expand_or_jump()
								elseif cursor_on_word() then
									cmp.complete()
								else
									fallback()
								end
							end
						end, {'i', 's'}),

						--- @param fallback fun()
						['<S-Tab>'] = cmp.mapping(function(fallback)
							if not cmp.select_prev_item() then
								if luasnip.jumpable(-1) then
									luasnip.jump(-1)
								elseif cursor_on_word() then
									cmp.complete()
								else
									fallback()
								end
							end
						end, {'i', 's'}),
					},

					sources = cmp.config.sources(
						{
							{ name = 'luasnip' },
							{ name = 'nvim_lsp', entry_filter = function(entry) return kind[entry:get_kind()] ~= 'Text' end },
						},
						{ { name = 'nvim_lua' }, { name = 'vim-dadbod-completion' } },
						{ { name = 'path' } },
						{ { name = 'buffer' } },
						{ { name = 'latex_symbols', max_item_count = 10 } }
					),
				})
			end,
			dependencies =
			{
				'hrsh7th/cmp-path',
				'hrsh7th/cmp-buffer',
				'hrsh7th/cmp-nvim-lsp',
				'hrsh7th/cmp-nvim-lua',
				'kdheepak/cmp-latex-symbols',
				{'kristijanhusak/vim-dadbod-completion', dependencies = 'tpope/vim-dadbod'},
				{'saadparwaiz1/cmp_luasnip',
					dependencies = {
						'L3MON4D3/LuaSnip',
						dependencies = 'rafamadriz/friendly-snippets',
						config = function()
							local luasnip = require 'luasnip'
							luasnip.setup { store_selection_keys = '<Tab>' }
							luasnip.log.set_loglevel('error') -- only log errors

							-- lazy load snippets
							local from_vscode = require 'luasnip.loaders.from_vscode'
							from_vscode.lazy_load { paths = vim.fn.stdpath('config') .. '/snippets' }
							from_vscode.lazy_load()
						end,
					},
				},
			},
			event = 'InsertEnter',
			opts = function(_, o)
				local SOURCES =
				{
					buffer = '',
					latex_symbols = '󱔁',
					nvim_lsp = '',
					nvim_lua = '󰢱',
					path = '',
					luasnip = '',
					spell = '󰓆',
					['vim-dadbod-completion'] = '',
				}

				o.formatting =
				{
					format = function(entry, vim_item)
						vim_item.menu = SOURCES[entry.source.name]
						return vim_item
					end,
				}

				o.window =
				{
					completion = {border = 'rounded', winhighlight = 'CursorLine:PmenuSel,Search:None'},
					documentation = {border = 'rounded', winhighlight = ''},
				}
			end,
		},

		{'chrisgrieser/nvim-scissors',
			dependencies = 'nvim-telescope/telescope.nvim',
			keys = {
				{'<A-w>s', function() require('scissors').addNewSnippet() end, desc = 'Add snippet with scissors', mode = {'n', 'x'}},
				{'<A-w>S', function() require('scissors').editSnippet() end, desc = 'Edit snippet with scissors', mode = 'n'},
			},
			opts = function(_, o)
				o.editSnippetPopup = { keymaps = { deleteSnippet = '<Leader>d' } }
				o.jsonFormatter = 'jq'
			end,
		},

		--[[ Languages
		|  _.._  _     _. _  _  _
		|_(_|| |(_||_|(_|(_|(/__>
					_|       _|
		--]]

		{'neovim/nvim-lspconfig', cond = not_man, config = req 'lsp.lspconfig', dependencies = 'cmp-nvim-lsp'},
		{'ray-x/lsp_signature.nvim',
			cond = not_man and not has_nvim_10,
			init = function()
				vim.api.nvim_create_autocmd('LspAttach', {
					callback = function(event)
						require('lsp_signature').on_attach(
							{floating_window = false, hint_scheme = '@text.literal', hint_prefix = ''},
							event.buf
						)
					end,
					group = 'config',
				})
			end,
			lazy = true,
		},

		{'nvim-treesitter/nvim-treesitter',
			build = ':TSUpdate',
			cond = not_man,
			init = function()
				local ts_utils = require 'ts_utils' --- @type config.TSUtils
				vim.api.nvim_create_user_command('ShowAs',
					function(tbl)
						local file_ext, node_type = unpack(tbl.fargs)
						local node = ts_utils.get_next_ancestor(node_type)
						if node == nil then
							return vim.notify('No ' .. node_type .. ' at cursor', vim.log.levels.INFO)
						end

						ts_utils.in_floating_window(node, file_ext)
					end,
					{ complete = 'filetype', desc = 'Show $2 TS node in float with $1 file extension ', nargs = '+' }
				);
			end,
			main = 'nvim-treesitter.configs',
			opts = function(_, o)
				o.auto_install = true
				o.ensure_installed = {
					-- won't get auto installed
					'http',
					'markdown_inline',
					'printf',
					'regex',

					-- I maintain queries for these languages
					'bash',
					'c',
					'c_sharp',
					'css',
					'dockerfile',
					'fish',
					'git_config',
					'gitignore',
					'git_rebase',
					'go',
					'gomod',
					'html',
					'ini',
					'java',
					'javascript',
					'lua',
					'markdown',
					'markdown_inline',
					'nix',
					'python',
					'query',
					'regex',
					'rust',
					'sql',
					'toml',
					'typescript',
					'typst',
					'ungrammar',
					'vim',
					'vimdoc',
					'yaml',
				}
				o.highlight = { additional_vim_regex_highlighting = false, enable = true }
				o.indent = { enable = false }

				vim.treesitter.language.register('gitignore', 'dockerignore');
				vim.treesitter.language.register('bash', 'zsh');
			end,
			event = new_file_read_file,
		},

		{'brenoprata10/nvim-highlight-colors',
			cmd = 'HighlightColors',
			keys = {{ '<Leader>C', '<Cmd>HighlightColors Toggle<CR>', mode = 'n', desc = 'Toggle colorizer' }},
			opts = function(_, o)
				o.enable_named_colors = true
				o.enable_tailwind = true
				o.render = 'background'
			end,
		},

		-- NOTE: replace these syntax files with treesitter parsers when available
		{'aklt/plantuml-syntax',
			config = function() vim.api.nvim_set_var('plantuml_executable_script', '/usr/bin/plantuml') end,
			ft = 'plantuml',
		},
		{'mboughaba/i3config.vim', ft = 'i3config'},
		{'MTDL9/vim-log-highlighting', ft = 'log'},
		{'chaimleib/vim-renpy',
			config = function()
				vim.api.nvim_set_hl(0, 'pythonAttribute', {link = '@variable.member.python'});
				vim.api.nvim_set_hl(0, 'pythonBuiltin', {link = '@variable.builtin.python'});
				vim.api.nvim_set_hl(0, 'pythonFunction', {link = '@lsp.type.class.python'});
				vim.api.nvim_set_hl(0, 'pythonDecorator', {link = '@punctuation.special.python'});
				vim.api.nvim_set_hl(0, 'pythonDecoratorName', {link = '@attribute.python'});
				vim.api.nvim_set_hl(0, 'pythonStatement', {link = '@keyword.python'});
				vim.api.nvim_set_hl(0, 'renpyBuiltin', {link = '@keyword.renpy'});
				vim.api.nvim_set_hl(0, 'renpyEscape', {link = '@string.escape'});
				vim.api.nvim_set_hl(0, 'renpyFunction', {link = '@lsp.type.class.renpy'});
				vim.api.nvim_set_hl(0, 'renpyHeader', {link = '@punctuation.delimiter'});
				vim.api.nvim_set_hl(0, 'renpyHeaderArgs', {link = '@punctuation.delimiter'});
				vim.api.nvim_set_hl(0, 'renpyHeaderFById', {link = '@type.renpy'});
				vim.api.nvim_set_hl(0, 'renpyHeaderFByPriority', {link = '@keyword.renpy'});
				vim.api.nvim_set_hl(0, 'renpyHeaderIdentifier', {link = '@function.renpy'});
				vim.api.nvim_set_hl(0, 'renpyHeaderPython', {link = '@keyword.renpy'});
				vim.api.nvim_set_hl(0, 'renpyStatement', {link = '@keyword.renpy'});
			end,
			ft = 'renpy',
		},

		--[[ Outlining
		 _
		/ \  _|_|o._ o._  _
		\_/|_||_||| ||| |(_|
								_|
		--]]

		{'folke/todo-comments.nvim',
			cond = not_man,
			dependencies = 'nvim-lua/plenary.nvim',
			opts =
			{
				highlight = {comments_only = false, keyword = 'bg'},
				keywords =
				{
					FIX = {icon = ''},
					NOTE = {icon = '', alt = {'INFO', 'SEE'}},
					PERF = {icon = '󰓅'},
					TEST = {icon = ''},
					TODO = {icon = '󰦕'},
					WARN = {icon = ''},
				},
				merge_keywords = true,
			},
			event = new_file_read_file,
		},

		{'folke/trouble.nvim',
			dependencies = 'nvim-web-devicons',
			keys =
			{
				{'<A-w>d', '<Cmd>TroubleToggle workspace_diagnostics<CR>', desc = 'Toggle trouble.nvim workspace diagnostics', mode = 'n'},
				{']D',
					function() require('trouble').next {skip_groups = true, jump = true} end,
					desc = 'Jump to the next Trouble entry',
					mode = 'n',
				},
				{'[D',
					function() require('trouble').previous {skip_groups = true, jump = true} end,
					desc = 'Jump to the previous Trouble entry',
					mode = 'n',
				},
				{'<A-w>T', '<Cmd>TodoTrouble<CR>', desc = 'Toggle trouble.nvim todos using todo-comments.nvim', mode = 'n'},
			},
			opts = function(_, o)
				o.auto_preview = false
			end,
		},

		{'nvim-neotest/neotest',
			dependencies = {
				'antoinemadec/FixCursorHold.nvim',
				'nvim-lua/plenary.nvim',
				'nvim-neotest/nvim-nio',
				'nvim-treesitter/nvim-treesitter'
			},
			cmd = 'Neotest',
			keys = {{'<A-w>t', '<Cmd>Neotest summary<CR>', desc = 'Open test panel', mode = 'n'}},
			opts = function(_, o)
				o.adapters = { require 'neotest-dotnet' }
				o.loglevel = vim.log.levels.OFF
			end,
		},

		{'nvim-treesitter/nvim-treesitter-context',
			cmd = 'TSContextToggle',
			dependencies = 'nvim-treesitter',
			event = new_file_read_file,
			keys = {{'<A-w>c', '<Cmd>TSContextToggle<CR>', desc = 'Toggle TS context', mode = 'n'}},
			opts = function(_, o)
				o.max_lines = 3
			end,
		},

		{'stevearc/aerial.nvim',
			dependencies = {'nvim-treesitter', 'nvim-web-devicons'},
			keys = {{'gO', '<Cmd>AerialToggle<CR>', desc = 'Toggle aerial.nvim', mode = 'n'}},
			opts = function(_, o)
				o.backends = {'lsp', 'treesitter', 'man', 'markdown'}
				o.filter_kind = false
				o.icons =
				{
					Array         = '󱡠',
					Boolean       = '󰨙',
					Class         = '󰆧',
					Constant      = '󰏿',
					Constructor   = '',
					Enum          = '',
					EnumMember    = '',
					Event         = '',
					Field         = '',
					File          = '󰈙',
					Function      = '󰊕',
					Interface     = '',
					Key           = '󰌋',
					Method        = '󰊕',
					Module        = '',
					Namespace     = '󰦮',
					Null          = '󰟢',
					Number        = '󰎠',
					Object        = '',
					Operator      = '󰆕',
					Package       = '',
					Property      = '',
					String        = '',
					Struct        = '󰆼',
					TypeParameter = '󰗴',
					Variable      = '󰀫',
					ArrayCollapsed         = '󱡠 ',
					BooleanCollapsed       = '󰨙',
					ClassCollapsed         = '󰆧 ',
					ConstantCollapsed      = '󰏿',
					ConstructorCollapsed   = ' ',
					EnumCollapsed          = ' ',
					EnumMemberCollapsed    = ' ',
					EventCollapsed         = ' ',
					FieldCollapsed         = ' ',
					FileCollapsed          = '󰈙 ',
					FunctionCollapsed      = '󰊕 ',
					InterfaceCollapsed     = ' ',
					KeyCollapsed           = '󰌋 ',
					MethodCollapsed        = '󰊕 ',
					ModuleCollapsed        = ' ',
					NamespaceCollapsed     = '󰦮 ',
					NullCollapsed          = '󰟢',
					NumberCollapsed        = '󰎠',
					ObjectCollapsed        = ' ',
					OperatorCollapsed      = '󰆕 ',
					PackageCollapsed       = ' ',
					PropertyCollapsed      = ' ',
					StringCollapsed        = '',
					StructCollapsed        = '󰆼 ',
					TypeParameterCollapsed = '󰗴',
					VariableCollapsed      = '󰀫',
				}
				o.layout =
				{
					default_direction = 'right',
					max_width = {40, 0.25}
				}
				o.guides =
				{
					last_item = '└─ ',
					mid_item = '├─ ',
					nested_top = '│  ',
					whitespace = '   ',
				}
				o.keymaps =
				{
					['?'] = false,
					['[['] = 'actions.prev',
					['[]'] = 'actions.prev_up',
					[']['] = 'actions.next_up',
					[']]'] = 'actions.next',
				}
				o.show_guides = true
				o.update_events = 'CursorHold,CursorHoldI,InsertLeave'
			end,
		},

		--[[ Special Features
			____             _      __  ____         __
		  / __/__  ___ ____(_)__ _/ / / __/__ ___ _/ /___ _________ ___
		 _\ \/ _ \/ -_) __/ / _ `/ / / _// -_) _ `/ __/ // / __/ -_|_-<
		/___/ .__/\__/\__/_/\_,_/_/ /_/  \__/\_,_/\__/\_,_/_/  \__/___/
			/_/
		--]]
		{'echasnovski/mini.nvim', config = req 'mini'},
		{'LunarVim/bigfile.nvim', config = true, event = 'BufReadPre'},
		{'NMAC427/guess-indent.nvim',
			event = 'BufReadPre',
			opts = function(_, o)
				o.auto_cmd = true
				o.override_editorconfig = false
			end,
		},

		--[[ Input
		___
		 | ._ ._   _|_
		_|_| ||_)|_||_
				|
		--]]

		{'dstein64/vim-win',
			commit = '00a31b44f9388927102dcd96606e236f13681a33',
			keys = {{'<Leader>w', '<Plug>WinWin', desc = 'Enter winmode', mode = 'n'}},
		},
		{'Iron-E/nvim-libmodal', lazy = true},
		{'Iron-E/nvim-bufmode',
			dependencies = 'nvim-libmodal',
			keys = {{'<Leader>b', desc = 'Enter bufmode', mode = 'n'}},
			opts = function(_, o)
				o.barbar = true
			end,
		},
		{'Iron-E/nvim-tabmode', dependencies = 'nvim-libmodal', keys = {{
			'<Leader><Tab>', desc = 'Enter tabmode', mode = 'n',
		}}},
		{'swaits/thethethe.nvim', config = true, event = 'InsertEnter'},

		--[[ telescope.nvim

		_|_ _ | _  _ _ _ ._  _  ._   o._ _
		 |_(/_|(/__>(_(_)|_)(/_o| |\/|| | |
		                 |
		--]]

		{'nvim-telescope/telescope.nvim',
			cmd = 'Telescope',
			config = function(_, o)
				local telescope = require 'telescope'
				telescope.setup(o)
				telescope.load_extension 'fzf'
			end,
			dependencies = {
				'nvim-telescope/telescope-fzf-native.nvim',
				build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build',
			},
			init = function()
				vim.api.nvim_create_autocmd('LspAttach', {
					callback = function(event)
						local bufnr = event.buf
						vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<Cmd>Telescope lsp_definitions<CR>', {})
						vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gI', '<Cmd>Telescope lsp_implementations<CR>', {})
						vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<Cmd>Telescope lsp_references<CR>', {})
						vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gw', '<Cmd>Telescope lsp_document_symbols<CR>', {})
						vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gW', '<Cmd>Telescope lsp_workspace_symbols<CR>', {})
						vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gy', '<Cmd>Telescope lsp_type_definitions<CR>', {})
					end,
					group = 'config',
				})
			end,
			keys =
			{
				{'<A-b>', '<Cmd>Telescope buffers<CR>', desc = 'Fuzzy find buffer', mode = 'n'},
				{'<A-f>', '<Cmd>Telescope find_files<CR>', desc = 'Fuzzy find file', mode = 'n'},
				{'<A-g>', '<Cmd>Telescope live_grep<CR>', desc = 'Fuzzy find telescope live grep', mode = 'n'},
				{'<C-b>', '<C-w>s<A-b>', desc = 'Fuzzy find buffer in new split', mode = 'n', remap = true},
				{'<C-f>', '<C-w>s<A-f>', desc = 'Fuzzy find file in new split', mode = 'n', remap = true},
				{'<Leader>F', '<Cmd>Telescope resume<CR>', desc = 'Resume last telescope search', mode = 'n'},
				{'<Leader>f', '<Cmd>Telescope<CR>', desc = 'Fuzzy find telescope pickers', mode = 'n'},
				{'z=', '<Cmd>Telescope spell_suggest<CR>', desc = 'Fuzzy find spelling suggestion', mode = 'n'},
			},
			opts = function(_, o)
				local previewers = require 'telescope.previewers'
				local cursor_theme = require('telescope.themes').get_cursor {
					layout_config = {height = 0.5, width = 0.9},
				}

				local cursor_theme_no_jump = vim.deepcopy(cursor_theme)
				cursor_theme_no_jump.jump_type = 'never'

				o.defaults =
				{
					file_previewer = previewers.cat.new,
					grep_previewer = previewers.vimgrep.new,
					history = false,
					qflist_previewer = previewers.qflist.new,

					layout_config =
					{
						center = {prompt_position = 'bottom'},
						cursor = {height = 0.5, width = 0.9},
						horizontal = {height = 0.95, width = 0.9},
						vertical = {height = 0.95, width = 0.9},
					},
					layout_strategy = 'flex',
					multi_icon = '󰄵 ',
					prompt_prefix = ' ',
					selection_caret = ' ',
				}

				o.extensions =
				{
					fzf = {fuzzy = true, override_file_sorter = true, override_generic_sorter = true},
					["ui-select"] = {cursor_theme},
				}

				o.pickers =
				{
					lsp_definitions = cursor_theme,
					lsp_implementations = cursor_theme,
					lsp_references = cursor_theme_no_jump,
					lsp_document_symbols = cursor_theme_no_jump,
					lsp_workspace_symbols = cursor_theme_no_jump,
					spell_suggest = cursor_theme,
				}
			end,
		},

		{'debugloop/telescope-undo.nvim',
			config = function() require('telescope').load_extension 'undo' end,
			dependencies = 'telescope.nvim',
			keys = {{'<A-w>u', '<Cmd>Telescope undo<CR>', desc = 'Telescope undo', mode = 'n'}},
		},

		{'nvim-telescope/telescope-ui-select.nvim',
			dependencies = 'telescope.nvim',
			init = function()
				--- Lazy loads telescope on first run
				--- @diagnostic disable-next-line:duplicate-set-field
				function vim.ui.select(...)
					require('telescope').load_extension 'ui-select'
					vim.ui.select(...)
				end
			end,
			lazy = true,
		},

		{ 'wintermute-cell/gitignore.nvim', cmd = 'Gitignore', dependencies = 'nvim-telescope/telescope.nvim' },

		--[[ UI
			___
		| | |
		|_|_|_
		--]]

		{'kevinhwang91/nvim-bqf', ft = 'qf'},
		{'kristijanhusak/vim-dadbod-ui',
			config = function()
				vim.api.nvim_set_var('db_ui_execute_on_save', false)
				vim.api.nvim_set_var('db_ui_save_location', data_dir .. '/db_ui')
				vim.api.nvim_set_var('db_ui_show_database_icon', true)
				vim.api.nvim_set_var('db_ui_use_nerd_fonts', true)

				vim.api.nvim_create_autocmd('FileType', {
					callback = function(event)
						vim.api.nvim_buf_set_keymap(event.buf, 'n', '<Leader>q', '<Plug>(DBUI_ExecuteQuery)', {})
						vim.api.nvim_buf_set_keymap(event.buf, 'n', '<Leader>S', '<Plug>(DBUI_SaveQuery)', {})
						vim.api.nvim_buf_set_keymap(event.buf, 'x', '<Leader>q', '<Plug>(DBUI_ExecuteQuery)', {})
					end,
					group = 'config',
					pattern = {'mysql', 'plsql', 'sql'},
				})
			end,
			dependencies = 'tpope/vim-dadbod',
			keys = {{'<A-w>D', '<Cmd>DBUIToggle<CR>', desc = 'Toggle the DBUI', mode = 'n'}},
			ft = {'mysql', 'plsql', 'sql'},
		},
		{'lewis6991/gitsigns.nvim',
			cmd = 'Gitsigns',
			dependencies = 'nvim-lua/plenary.nvim',
			event = new_file_read_file,
			keys =
			{
				{'[c', '<Cmd>Gitsigns prev_hunk<CR>', desc = 'Previous hunk ', mode = 'n'},
				{']c', '<Cmd>Gitsigns next_hunk<CR>', desc = 'Next hunk', mode = 'n'},
				{'<Leader>hs', '<Cmd>Gitsigns stage_hunk<CR>', desc = 'Stage hunk', mode = 'n'},
				{'<Leader>hu', '<Cmd>Gitsigns undo_stage_hunk<CR>', desc = 'Unstage hunk', mode = 'n'},
			},
			opts = function(_, o)
				o.preview_config = {border = 'rounded'}
				o.trouble = false
			end,
		},
		{'lukas-reineke/indent-blankline.nvim',
			cond = not_man,
			main = 'ibl',
			opts = { indent = {char = '│'}, scope = {enabled = false} },
		},
		{'nvim-tree/nvim-web-devicons', lazy = true},
		{'rebelot/heirline.nvim',
			config = req 'heirline',
			dependencies = {'gitsigns.nvim', 'nvim-web-devicons'},
		},
		{'romgrk/barbar.nvim',
			cond = not_man,
			dependencies = {'gitsigns.nvim', 'nvim-web-devicons'},
			dev = true,
			init = function(barbar)
				vim.g.barbar_auto_setup = false -- disable auto-setup

				--- @param bufnr integer
				--- @return boolean
				local function filter(bufnr)
					return vim.api.nvim_get_option_value('buflisted', {buf = bufnr})
				end

				vim.api.nvim_create_autocmd({'BufNewFile', 'BufReadPost', 'SessionLoadPost', 'TabNewEntered'}, {
					callback = function()
						if #vim.tbl_filter(filter, vim.api.nvim_list_bufs()) > 1 then
							require('lazy.core.loader').load(barbar, {cmd = 'Lazy load'})
							return true -- delete autocmd
						end
					end,
					group = 'config',
				})
			end,
			keys =
			{
				{'[B', '<Cmd>BufferFirst<CR>', desc = 'Go to the first buffer', mode = 'n'},
				{'[b', ':BufferPrevious<CR>', desc = 'Go to the previous buffer', mode = 'n'},
				{']B', '<Cmd>BufferLast<CR>', desc = 'Go to the last buffer', mode = 'n'},
				{']b', ':BufferNext<CR>', desc = 'Go to the next buffer', mode = 'n'},
			},
			lazy = false,
			opts = function(_, o)
				o.animation = false
				o.auto_hide = true
				o.clickable = false
				o.focus_on_close = 'left'
				o.highlight_alternate = true
				o.icons =
				{
					button = false,
					current =
					{
						diagnostics = {{enabled = false}, {enabled = false}},
						gitsigns = {added = {enabled = false}, changed = {enabled = false}, deleted = {enabled = false}},
					},
					diagnostics = {{enabled = true, icon = ''}, {enabled = true, icon = ''}},
					gitsigns = {added = {enabled = true}, changed = {enabled = true}, deleted = {enabled = true}},
					modified = {button = false},
					pinned = {button = '', filename = true},
					preset = 'slanted',
				}
				o.maximum_padding = math.huge
			end,
		},
		{'tversteeg/registers.nvim',
			keys =
			{
				{'"', desc = 'View the registers', mode = {'n', 'x'}},
				{'<C-r>', desc = 'View the registers', mode = 'i'},
			},
			opts = function(_, o)
				o.window = {border = 'rounded'}
			end,
		},

		--[[ Themes
		 ________
		/_  __/ /  ___ __ _  ___ ___
		 / / / _ \/ -_)  ' \/ -_|_-<
		/_/ /_//_/\__/_/_/_/\__/___/
		--]]
		{'Iron-E/nvim-highlite',
			config = function(_, o)
				require('highlite').setup(o)
				vim.api.nvim_command 'colorscheme highlite-custom'
			end,
			priority = math.huge,
			opts = function(_, o)
				local allow_list = { __index = function() return false end }
				o.terminal_colors = false
				o.generate =
				{
					syntax = setmetatable({ dosini = true, editorconfig = true, i3config = true, man = true, plantuml = true }, allow_list),
					plugins =
					{
						vim = setmetatable({ dadbod_ui = true }, allow_list),
						nvim =
						{
							leap = false,
							lspsaga = false,
							nvim_tree = false,
							packer = false,
							sniprun = false,
							symbols_outline = false,
						},
					},
				}
			end,
		},
	},
	{
		dev = {fallback = true, path = '~/Programming', patterns = {'Iron-E'}},
		install = {colorscheme = {'highlite', 'habamax'}},
		performance = {rtp = {disabled_plugins =
		{
			'gzip',
			'netrwPlugin',
			'rplugin',
			'tarPlugin',
			'tohtml',
			'tutor',
			'zipPlugin',
		}}},
		ui = {border = 'rounded'},
	}
)
