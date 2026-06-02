-------------------------------------------
--[[

	Thanks for scriptblox.com
	
	Scripted by @vcd_
	
	Last Updated: 01/13/26
	
--]]
-------------------------------------------

-- [ Upvalue Caching / Performance Optimization ]
local cloneref = (cloneref or function<T>(reference: T): T return reference end)

local CoreGui         = cloneref(game:FindService('CoreGui'))
local tick            = tick
local ipairs          = ipairs
local math_sin        = math.sin
local math_floor      = math.floor
local string_sub      = string.sub
local table_insert    = table.insert
local table_concat    = table.concat
local string_format   = string.format

-- [ Types Definitions ]
export type ColorsType = { 
	Red: string, Cyan: string, Blue: string, Green: string, 
	Purple: string, Orange: string, Yellow: string, White: string, Brown: string 
}

export type LoggerModule = {
	Colors: ColorsType,
	ChangeColor: () -> (),
	print: (color: string, text: any, size: number?, print_function: ((...any) -> ())?) -> (),
	rainbowPrint: (text: string, size: number?, print_function: ((...any) -> ())?) -> ()
}

-- [ Module Definition ]
local Modules = {
	Colors = {
		['Red']    = '255, 0, 0',
		['Cyan']   = '33, 161, 163',
		['Blue']   = '0, 100, 255',
		['Green']  = '0,255,0',
		['White']  = '255, 255, 255',
		['Brown']  = '150, 75, 0',
		['Purple'] = '170, 0, 255',
		['Orange'] = '255, 150, 0',
		['Yellow'] = '255, 255, 0',
	} :: ColorsType
} 

-- [ Core Functions ]
Modules.ChangeColor = function() 
	local function EnableRichText(instance: Instance)
		if instance:IsA('TextLabel') then instance.RichText = true end
		for _, child: Instance in ipairs(instance:GetChildren()) do
			EnableRichText(child)
		end
	end

	local devConsole = CoreGui:FindFirstChild('DevConsoleMaster')
	if devConsole then EnableRichText(devConsole); end

	CoreGui.ChildAdded:Connect(function(child: Instance)
		if (child.Name == 'DevConsoleMaster') then
			EnableRichText(child)
			child.DescendantAdded:Connect(function(descendant: Instance)
				if descendant:IsA('TextLabel') then
					descendant.RichText = true
				end
			end)
		end
	end)

	if devConsole then
		devConsole.DescendantAdded:Connect(function(descendant: Instance)
			if descendant:IsA('TextLabel') then
				descendant.RichText = true
			end
		end)
	end
end

Modules.print = function(color: string, text: any, size: number?, print_function: ((...any) -> ())?)
	local output = print_function or print

	if not Modules.Colors[color :: any] then 
		return
	end 

	local Text = '<font color="rgb(' .. Modules.Colors[color :: any] .. ')"'
	if size then
		Text = Text .. ' size="' .. tostring(size) .. '"'
	end
	Text = Text .. '>' .. tostring(text) .. '</font>'
	output(Text)
end

Modules.rainbowPrint = function(text: string, size: number?, print_function: ((...any) -> ())?)
	local output = print_function or print
	local time = (tick() * 5)
	local buffer = {}

	for i = 1, #text do
		local character = string_sub(text, i, i)

		if character == " " then
			table_insert(buffer, " ")
		else
			local frequency = 0.5
			local r = math_floor(math_sin(frequency * i + time + 0) * 127 + 128)
			local g = math_floor(math_sin(frequency * i + time + 2) * 127 + 128)
			local b = math_floor(math_sin(frequency * i + time + 4) * 127 + 128)

			local colorStr = string_format("rgb(%d,%d,%d)", r, g, b) :: string

			if size then
				table_insert(buffer, string_format('<font color="%s" size="%d">%s</font>', colorStr, size, character))
			else
				table_insert(buffer, string_format('<font color="%s">%s</font>', colorStr, character))
			end
		end
	end

	output(table_concat(buffer))
end

-- [ Initialization ]
Modules.ChangeColor()

return Modules :: LoggerModule

-------------------------------------------
-- [ EOF ]
-------------------------------------------
