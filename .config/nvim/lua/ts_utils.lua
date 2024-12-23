--- @class config.TSUtils
local TSUtils = {}

--- @param type string the type of ancestor to get
--- @param node? TSNode the node to get the parent of
--- @return nil|TSNode
--- @see TSNode.type
function TSUtils.get_next_ancestor(type, node)
	local section

	do
		local current_node = node or vim.treesitter.get_node()
		while current_node ~= nil and section == nil do
			if current_node:type() == type then
				section = current_node
				break
			end

			current_node = current_node:parent()
		end
	end

	return section
end

--- @alias config.TSUtils.get_sibling.direction 'next'|'previous'

--- @param node TSNode the node to get the sibling of
--- @param direction config.TSUtils.get_sibling.direction the
--- @return nil|TSNode
function TSUtils.get_sibling(node, direction)
	local parent = node:parent()
	if parent == nil then
		return vim.notify('Cannot get sibling because node has no parent', vim.log.levels.ERROR)
	end

	local found_current_section = false
	local next, previous --- @type nil|TSNode, nil|TSNode
	local node_id = node:id()
	local node_type = node:type()

	for child in parent:iter_children() do
		if child:type() == node_type then
			if found_current_section then
				next = child
				break
			end

			if child:id() == node_id then
				found_current_section = true
			else
				previous = child
			end
		end
	end

	if next ~= nil and direction == 'next' then
		return next
	elseif previous ~= nil and direction == 'previous' then
		return previous
	end
end

--- Place the cursor on a sibling
--- @param type string
--- @param direction config.TSUtils.get_sibling.direction
--- @param start_node? TSNode
--- @see config.TSUtils.get_sibling
--- @see config.TSUtils.get_next_ancestor
function TSUtils.goto_sibling(type, direction, start_node)
	local ancestor = TSUtils.get_next_ancestor(type, start_node)
	if ancestor == nil then
		return vim.notify('Cursor is not currently within a ' .. type, vim.log.levels.INFO)
	end

	local sibling =  TSUtils.get_sibling(ancestor, direction)
	if sibling == nil then
		return vim.notify('No ' .. direction .. ' sibling ' .. type, vim.log.levels.INFO)
	end

	TSUtils.set_cursor_on_node(sibling)
end

--- @param node TSNode the node whose contents should be shown in a floating window
--- @param file_ext string the file extension
--- @return integer buf, integer win
function TSUtils.in_floating_window(node, file_ext)
	local lines
	do
		local text = vim.treesitter.get_node_text(node, 0)
		lines = vim.split(text, '\n', {plain = false, trimempty = true})
	end

	-- stash original context
	local orig_buf = vim.api.nvim_get_current_buf()
	local orig_win = vim.api.nvim_get_current_win()

	-- create buffer and set options
	local buf = vim.api.nvim_create_buf(false, false)
	local opts = { buf = buf }

	vim.api.nvim_buf_set_name(buf, math.random() .. '.' .. file_ext)
	vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)

	local ft = vim.filetype.match(opts)
	vim.api.nvim_set_option_value('bufhidden', 'hide', opts)
	vim.api.nvim_set_option_value('buftype', 'nowrite', opts)
	vim.api.nvim_set_option_value('filetype', ft, opts)
	vim.api.nvim_set_option_value('swapfile', false, opts)

	vim.api.nvim_create_autocmd('WinClosed', {
		buffer = buf,
		callback = function() vim.api.nvim_buf_delete(buf, {force = false, unload = false}) end,
		once = true,
	})

	-- open window
	local start_row, start_col, end_row, end_col = node:range(false)
	local line_nr, col_nr = unpack(vim.api.nvim_win_get_cursor(orig_win))
	local win do

		local start_col_nr = math.min(start_col, end_col)
		local orig_wininfo = vim.fn.getwininfo(orig_win)[1]

		win = vim.api.nvim_open_win(buf, true, {
			border = 'none',

			relative = 'win',
			win = orig_win,
			zindex = 1,

			col = start_col_nr,
			row = start_row - orig_wininfo.topline + 1,

			height = end_row - start_row,
			width = vim.api.nvim_win_get_width(orig_win) - start_col_nr,
		})
	end

	do -- allow flushing to original buffer

		vim.api.nvim_buf_create_user_command(buf, 'W',
			function()
				local replacement = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
				do -- HACK: workaround for bad captures
					local original_text = vim.api.nvim_buf_get_text(orig_buf, start_row, start_col, end_row, end_col, {})
					while original_text[#original_text]:find('^%s*$') do -- bad capture detected
						table.remove(original_text)

						local last_real_line = original_text[#original_text]
						end_row = end_row - 1
						end_col = vim.api.nvim_strwidth(last_real_line)
					end
				end

				vim.api.nvim_buf_set_text(orig_buf, start_row, start_col, end_row, end_col, replacement)
				vim.api.nvim_win_close(win, true)
				vim.schedule(vim.cmd.update)
			end,
			{ desc = "Write this float's text to the buffer and close" }
		)
	end

	-- make buffer viewable
	vim.api.nvim_win_set_cursor(win, { line_nr - start_row, col_nr })
	vim.api.nvim_win_set_buf(win, buf)

	return buf, win
end

--- @param node TSNode
function TSUtils.set_cursor_on_node(node)
	local row, column = node:range()
	vim.api.nvim_win_set_cursor(0, {row + 1, column})
end

return TSUtils
