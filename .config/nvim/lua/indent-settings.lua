--- Set the fold options given the `expandtab` and `tabstop` params
--- @param expandtab? boolean
--- @param tabstop? integer
return function(expandtab, tabstop)
	vim.api.nvim_set_option_value('expandtab', expandtab or false, {scope = 'local'})
	vim.api.nvim_set_option_value('shiftwidth', 0, {scope = 'local'})  -- Use tabstop
	vim.api.nvim_set_option_value('softtabstop', -1, {scope = 'local'}) -- Use shiftwidth
	vim.api.nvim_set_option_value('tabstop', tabstop or 3, {scope = 'local'}) -- How many spaces a tab is worth
end
