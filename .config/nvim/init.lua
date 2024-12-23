--[[
 ___       _ _
|_ _|_ __ (_) |_
 | || '_ \| | __|
 | || | | | | |_
|___|_| |_|_|\__|
--]]

_G['nvim >= 0.10'] = vim.fn.has('nvim-0.10') == 1

vim.loader.enable()

-- Config
require 'init/config'
require 'init/mappings'

-- Plugins
require 'init/lazy'
