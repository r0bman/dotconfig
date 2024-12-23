local next_section = { callback = function() require('ts_utils').goto_sibling('section', 'next') end }
local previous_section = { callback = function() require('ts_utils').goto_sibling('section', 'previous') end }
for _, mode in ipairs {'n', 'x'} do
	vim.api.nvim_buf_set_keymap(0, mode, '][', '', next_section)
	vim.api.nvim_buf_set_keymap(0, mode, '[]', '', previous_section)
end
