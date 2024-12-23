--[[/* IMPORTS */]]

local libmodal = require 'libmodal'

--[[/* MODULE */]]

--- the beginning of every command involving writing XML.
local ENTER = string.char(require('libmodal.collections.ParseTable').CR)
local OPEN_EQUALS = '="'
local XML_PREFIX  = 'norm saiwi<'

--- a basic inline xml template.
local XML_TEMPLATE_INLINE = {XML_PREFIX, OPEN_EQUALS .. ENTER .. '"/>' .. ENTER}

--- create an expanded xml template.
local function xml_expanded_template(tag_name, assignment)
	return XML_PREFIX ..
		tag_name ..
		' ' ..
		(assignment and assignment .. OPEN_EQUALS or '') ..
		ENTER ..
		'"></' ..
		tag_name ..
		'>' ..
		ENTER
end

local XML_TEMPLATE_SURROUND = {'norm saiwt', ENTER}

--- enter the mode
return function()
	libmodal.mode.enter('CODE DOC',
	{
		a = xml_expanded_template('seealso',    'cref'),
		e = xml_expanded_template('exception',  'cref'),
		m = table.concat(XML_TEMPLATE_SURROUND, 'summary'),
		p = xml_expanded_template('param',      'name'),
		r = table.concat(XML_TEMPLATE_SURROUND, 'returns'),
		s = table.concat(XML_TEMPLATE_INLINE,   'see cref'),
		u = 'norm u',
	})
end
