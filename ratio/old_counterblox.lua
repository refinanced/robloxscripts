local lib = {}
local services = setmetatable({}, { __index = function(self, key) return game:GetService(key) end })
lib.util = {}
lib.items = {}
lib.connections = {}
lib.tweens = {}

local find = function(t, l)
	for i = 1, #t do
		local o = t[i]
		if l == o then
			return i
		end
	end
	return
end

LPH_JIT = function(...) return ... end 
LPH_JIT_MAX = function(...) return ... end
LPH_NO_VIRTUALIZE = function(...) return ... end
LPH_HOOK_FIX = function(...) return ... end

lib.util.new = function(t, p, o)
	local t = Instance.new(t)
	for i,v in pairs(p) do
		if tostring(i) == "Parent" and t.ClassName == "ScreenGui" then
			if not gethui then syn.protect_gui(t); t.Parent = game.CoreGui else t.Parent = gethui() end
		else
			t[i] = v
		end
	end
	lib.items[p.Name] = t
	return t
end

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
function enc(data)
	return ((data:gsub('.', function(x) 
		local r,b='',x:byte()
		for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
		return r;
	end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
		if (#x < 6) then return '' end
		local c=0
		for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
		return b:sub(c+1,c+1)
	end)..({ '', '==', '=' })[#data%3+1])
end
function dec(data)
	data = string.gsub(data, '[^'..b..'=]', '')
	return (data:gsub('.', function(x)
		if (x == '=') then return '' end
		local r,f='',(b:find(x)-1)
		for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
		return r;
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
		if (#x ~= 8) then return '' end
		local c=0
		for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
		return string.char(c)
	end))
end

function lib:setDraggable(gui, gui2)
	local dragging
	local dragInput
	local dragStart
	local startPos

	local function update(input)
		local delta = input.Position - dragStart
		gui2.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	gui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch and not lib.stats.busy then
			dragging = true
			dragStart = input.Position
			startPos = gui.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	gui.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch and not lib.stats.busy then
			dragInput = input
		end
	end)

	services.UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging and not lib.stats.busy then
			update(input)
		end
	end)
end

testfunc = function()
	
end

local keyNames = {
	['One'] = "1",
	['Two'] = "2",
	['Three'] = "3",
	['Four'] = "4",
	['Five'] = "5",
	['Six'] = "6",
	['Seven'] = "7",
	['Eight'] = "8",
	['Nine'] = "9",
	['Zero'] = "0",
	['LeftBracket'] = "[",
	['RightBracket'] = "]",
	['Semicolon'] = ";",
	['BackSlash'] = "\\",
	['Slash'] = "/",
	['Minus'] = "-",
	['Equals'] = "=",
	['Return'] = "Enter",
	['Backquote'] = "`",
	['CapsLock'] = "Caps",
	['LeftShift'] = "LShift",
	['RightShift'] = "RShift",
	['LeftControl'] = "LCtrl",
	['RightControl'] = "RCtrl",
	['LeftAlt'] = "LAlt",
	['RightAlt'] = "RAlt",
	['Backspace'] = "Back",
	['Plus'] = "+",
	['Multiplaye'] = "x",
	['PageUp'] = "PgUp",
	['PageDown'] = "PgDown",
	['Delete'] = "Del",
	['Insert'] = "Ins",
	['NumLock'] = "NumL",
	['Comma'] = ",",
	['Period'] = ".",
}

if not isfolder("Ratio") then
	makefolder("Ratio")
end

if not isfolder("Ratio/Configs") then
	makefolder("Ratio/Configs")
end

if not isfolder("Ratio/Scripts") then
	makefolder("Ratio/Scripts")
end

if not isfolder("Ratio/Skins") then
	makefolder("Ratio/Skins")
end

if not isfile("Ratio/Configs/Killsays.txt") then
	writefile("Ratio/Configs/Killsays.txt", "[\"I should change this in Killsays.txt!\", \"I really need to change this Killsays file!\"]")
end

if not isfile("Ratio/Configs/Chatspam.txt") then
	writefile("Ratio/Configs/Chatspam.txt", "[\"I should change this in Chatspam.txt!\", \"I really need to change this Chatspam file!\"]")
end

function lib.copy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = lib.copy(v)
		end
		copy[k] = v
	end
	return copy
end

lib.signal = loadstring(game:HttpGet("https://raw.githubusercontent.com/Quenty/NevermoreEngine/version2/Modules/Shared/Events/Signal.lua"))()
lib.onConfigLoaded = lib.signal.new("onConfigLoaded")
lib.onConfigSaved = lib.signal.new("onConfigSaved")

lib.loadConfig = function(cfgName, old2)
    LPH_JIT_MAX(function()
        local new_values = services.HttpService:JSONDecode(dec(readfile("Ratio/Configs/"..cfgName..".cfg")))

        for i,element in pairs(new_values) do
            if typeof(element) == "table" and element.Color then
                element.Color = Color3.new(element.Color.R, element.Color.G, element.Color.B)
            end
            lib.flags[i] = element
        end

        task.spawn(function()
            task.wait()
            lib.onConfigLoaded:Fire()
        end)
        lib.busy = false
    end)()
end

lib.saveConfig = function(cfgName, old)
    LPH_JIT_MAX(function()
        local values_copy = lib.copy(lib.flags)
        for i,element in pairs(values_copy) do
            if typeof(element) == "table" and element.Color then
                element.Color = {R = element.Color.R, G = element.Color.G, B = element.Color.B}
            end
        end

        if not old then
            task.spawn(function()
                task.wait()
                lib.onConfigSaved:Fire()
            end)
            writefile("Ratio/Configs/"..cfgName..".cfg",enc(services.HttpService:JSONEncode(values_copy)))
        else
            return services.HttpService:JSONEncode(values_copy)
        end
    end)()
end

local indicators = Instance.new("ScreenGui")

if gethui then
	indicators.Parent = gethui()
elseif syn and syn.protect_gui then
	syn.protect_gui(indicators)
	indicators.Parent = game.CoreGui
end

indicators.Name = "indicators";
indicators.ResetOnSpawn = false;
indicators.Enabled = false;

local indicators_holder = Instance.new("Frame", indicators);
indicators_holder.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
indicators_holder.BackgroundTransparency = 1;
indicators_holder.Name = "indicators_holder";
indicators_holder.Position = UDim2.new(0, 10, 0.288, 0);
indicators_holder.Size = UDim2.new(0, 150, 0.7	, 0);

local UIListLayout = Instance.new("UIListLayout", indicators_holder);
UIListLayout.Padding = UDim.new(0, 5);
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder;
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center;

lib.indicators = {}
lib.indicators.states = {
	["default"] = Color3.fromRGB(228,228,228), 
	["off"] = Color3.fromRGB(177, 0, 18), 
	["on"] = Color3.fromRGB(143, 190, 55)
}

function lib.indicators:set_visible(bool)
	indicators.Enabled = bool
end

function lib.indicators:set_alignment(alignment)
	if alignment == "Bottom" then
		UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	else
		UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	end
end

function lib.indicators:add_indicator(text)
	local size = services.TextService:GetTextSize(text, 30, Enum.Font.RobotoMono, Vector2.new(999,999))

	local i1 = Instance.new("Frame", indicators_holder);
	i1.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
	i1.BorderSizePixel = 0;
	i1.Name = "i1";
	i1.Size = UDim2.new(0, 26 + size.X, 0, 30);
	i1.Visible = false

	local UIGradient = Instance.new("UIGradient", i1);
	UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.5062344074249268, 0.7250000238418579, 0), NumberSequenceKeypoint.new(1, 1, 0)};

	local indicator_main = Instance.new("TextLabel", i1);
	indicator_main.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	indicator_main.BackgroundTransparency = 1;
	indicator_main.Name = "indicator_main";
	indicator_main.Size = UDim2.new(1, 0, 1, 0);
	indicator_main.Font = Enum.Font.Unknown;
	indicator_main.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal);
	indicator_main.Text = text;
	indicator_main.TextColor3 = Color3.fromRGB(177.0000046491623, 0, 18.000000827014446);
	indicator_main.TextSize = 30;
	indicator_main.TextWrapped = false;

	local indicator_shadow = Instance.new("TextLabel", indicator_main);
	indicator_shadow.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	indicator_shadow.BackgroundTransparency = 1;
	indicator_shadow.Name = "indicator_shadow";
	indicator_shadow.Position = UDim2.new(0, 1, 0, 1);
	indicator_shadow.Size = UDim2.new(1, 0, 1, 0);
	indicator_shadow.ZIndex = 0;
	indicator_shadow.Font = Enum.Font.Unknown;
	indicator_shadow.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal);
	indicator_shadow.Text = text;
	indicator_shadow.TextColor3 = Color3.fromRGB(0, 0, 0);
	indicator_shadow.TextScaled = true;
	indicator_shadow.TextSize = 30;
	indicator_shadow.TextTransparency = 0.5;
	indicator_shadow.TextWrapped = false;

	local indicator = {}

	function indicator:set_text(text)
		local size = services.TextService:GetTextSize(text, 30, Enum.Font.RobotoMono, Vector2.new(999,999))
		i1.Size = UDim2.new(0, 26 + size.X, 0, 30);
	end

	function indicator:set_state(state)
		indicator_main.TextColor3 = lib.indicators.states[state]
	end

	function indicator:set_visible(bool)
		i1.Visible = bool
	end

	function indicator:set_color(color)
		indicator.main.TextColor3 = color
	end

	return indicator
end

lib.init = function()
	local holder = lib.util.new("ScreenGui", {
		Enabled = true,
		Name = services.HttpService:GenerateGUID(false),
		Parent = game.CoreGui,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Global
	}, {})
	
	local outline = Instance.new("Frame", holder);
	outline.BackgroundColor3 = Color3.fromRGB(57.00000040233135, 57.00000040233135, 57.00000040233135);
	outline.BorderColor3 = Color3.fromRGB(41.00000135600567, 41.00000135600567, 41.00000135600567);
	outline.Name = "outline";
	outline.Position = UDim2.new(0.31009024381637573, 0, 0.0938461571931839, 0);
	outline.Size = UDim2.new(0, 610, 0, 520);
	lib:setDraggable(outline, outline)

	local outline2 = Instance.new("Frame", outline);
	outline2.BackgroundColor3 = Color3.fromRGB(57.00000040233135, 57.00000040233135, 57.00000040233135);
	outline2.BorderColor3 = Color3.fromRGB(40.00000141561031, 40.00000141561031, 40.00000141561031);
	outline2.Name = "outline2";
	outline2.Position = UDim2.new(0, 2, 0, 2);
	outline2.Size = UDim2.new(1, -4, 1, -4);

	local outline3 = Instance.new("Frame", outline2);
	outline3.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	outline3.BorderColor3 = Color3.fromRGB(40.00000141561031, 40.00000141561031, 40.00000141561031);
	outline3.Name = "outline3";
	outline3.Position = UDim2.new(0, 2, 0, 2);
	outline3.Size = UDim2.new(1, -4, 1, -4);

	local outline4 = Instance.new("Frame", outline3);
	outline4.BackgroundColor3 = Color3.fromRGB(42.000001296401024, 42.000001296401024, 42.000001296401024);
	outline4.BorderColor3 = Color3.fromRGB(40.00000141561031, 40.00000141561031, 40.00000141561031);
	outline4.Name = "outline4";
	outline4.Position = UDim2.new(0, 1, 0, 1);
	outline4.Size = UDim2.new(1, -2, 1, -2);

	local inside = Instance.new("Frame", outline4);
	inside.BackgroundColor3 = Color3.fromRGB(18.000000827014446, 18.000000827014446, 18.000000827014446);
	inside.BorderColor3 = Color3.fromRGB(40.00000141561031, 40.00000141561031, 40.00000141561031);
	inside.Name = "inside";
	inside.Position = UDim2.new(0, 1, 0, 1);
	inside.Size = UDim2.new(1, -2, 1, -2);
	inside.ClipsDescendants = true;
	
	local tab_holder = Instance.new("Frame", inside);
	tab_holder.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	tab_holder.BackgroundTransparency = 1;
	tab_holder.Name = "tab_holder";
	tab_holder.Size = UDim2.new(0.11749999970197678, 0, 1, 0);
	tab_holder.ZIndex = 2;

	local UIListLayout = Instance.new("UIListLayout", tab_holder);
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder;

	local size_handle = Instance.new("Frame", tab_holder);
	size_handle.BackgroundColor3 = Color3.fromRGB(12.000001184642315, 12.000001184642315, 12.000001184642315);
	size_handle.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	size_handle.BorderSizePixel = 0;
	size_handle.Name = "size_handle";
	size_handle.Size = UDim2.new(1, 1, 0.019999999552965164, 0);
	size_handle.ZIndex = 2;

	local top_line = Instance.new("Frame", size_handle);
	top_line.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	top_line.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	top_line.BorderSizePixel = 0;
	top_line.Name = "top_line";
	top_line.Size = UDim2.new(1, 0, 0, 1);
	top_line.Visible = false;
	top_line.ZIndex = 3;

	local bottom_line = Instance.new("Frame", size_handle);
	bottom_line.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	bottom_line.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	bottom_line.BorderSizePixel = 0;
	bottom_line.Name = "bottom_line";
	bottom_line.Position = UDim2.new(0, 0, 1, 0);
	bottom_line.Size = UDim2.new(1, 0, 0, 1);
	bottom_line.Visible = false;
	bottom_line.ZIndex = 3;

	local side_line = Instance.new("Frame", size_handle);
	side_line.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	side_line.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	side_line.BorderSizePixel = 0;
	side_line.Name = "side_line";
	side_line.Position = UDim2.new(1, -1, 0, 0);
	side_line.Size = UDim2.new(0, 1, 1, 0);
	side_line.ZIndex = 3;

	local rage_tab = Instance.new("Frame", tab_holder);
	rage_tab.BackgroundColor3 = Color3.fromRGB(12.000001184642315, 12.000001184642315, 12.000001184642315);
	rage_tab.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	rage_tab.BorderSizePixel = 0;
	rage_tab.Name = "rage_tab";
	rage_tab.Size = UDim2.new(1, 1, 0.1379999965429306, 0);
	rage_tab.ZIndex = 2;

	local tab_image = Instance.new("ImageLabel", rage_tab);
	tab_image.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	tab_image.BackgroundTransparency = 1;
	tab_image.Name = "tab_image";
	tab_image.Size = UDim2.new(1, 0, 1, 0);
	tab_image.ZIndex = 4;
	tab_image.Image = "rbxassetid://8816520340";
	tab_image.ImageColor3 = Color3.fromRGB(67.00000360608101, 67.00000360608101, 67.00000360608101);
	
	local top_line_1 = Instance.new("Frame", rage_tab);
	top_line_1.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	top_line_1.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	top_line_1.BorderSizePixel = 0;
	top_line_1.Name = "top_line";
	top_line_1.Size = UDim2.new(1, 0, 0, 1);
	top_line_1.Visible = false;
	top_line_1.ZIndex = 3;

	local bottom_line_1 = Instance.new("Frame", rage_tab);
	bottom_line_1.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	bottom_line_1.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	bottom_line_1.BorderSizePixel = 0;
	bottom_line_1.Name = "bottom_line";
	bottom_line_1.Position = UDim2.new(0, 0, 1, 0);
	bottom_line_1.Size = UDim2.new(1, 0, 0, 1);
	bottom_line_1.Visible = false;
	bottom_line_1.ZIndex = 3;
	
	local side_line_1 = Instance.new("Frame", rage_tab);
	side_line_1.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	side_line_1.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	side_line_1.BorderSizePixel = 0;
	side_line_1.Name = "side_line";
	side_line_1.Position = UDim2.new(1, -1, 0, 0);
	side_line_1.Size = UDim2.new(0, 1, 1, 0);
	side_line_1.ZIndex = 3;

	local aa_tab = Instance.new("Frame", tab_holder);
	aa_tab.BackgroundColor3 = Color3.fromRGB(12.000001184642315, 12.000001184642315, 12.000001184642315);
	aa_tab.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	aa_tab.BorderSizePixel = 0;
	aa_tab.Name = "aa_tab";
	aa_tab.Size = UDim2.new(1, 1, 0.1379999965429306, 0);
	aa_tab.ZIndex = 2;

	local top_line_1 = Instance.new("Frame", aa_tab);
	top_line_1.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	top_line_1.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	top_line_1.BorderSizePixel = 0;
	top_line_1.Name = "top_line";
	top_line_1.Size = UDim2.new(1, 0, 0, 1);
	top_line_1.Visible = false;
	top_line_1.ZIndex = 3;

	local bottom_line_1 = Instance.new("Frame", aa_tab);
	bottom_line_1.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	bottom_line_1.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	bottom_line_1.BorderSizePixel = 0;
	bottom_line_1.Name = "bottom_line";
	bottom_line_1.Position = UDim2.new(0, 0, 1, 0);
	bottom_line_1.Size = UDim2.new(1, 0, 0, 1);
	bottom_line_1.Visible = false;
	bottom_line_1.ZIndex = 3;

	local side_line_1 = Instance.new("Frame", aa_tab);
	side_line_1.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	side_line_1.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	side_line_1.BorderSizePixel = 0;
	side_line_1.Name = "side_line";
	side_line_1.Position = UDim2.new(1, -1, 0, 0);
	side_line_1.Size = UDim2.new(0, 1, 1, 0);
	side_line_1.ZIndex = 3;

	local tab_image_0 = Instance.new("ImageLabel", aa_tab);
	tab_image_0.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	tab_image_0.BackgroundTransparency = 1;
	tab_image_0.Name = "tab_image";
	tab_image_0.Size = UDim2.new(1, 0, 1, 0);
	tab_image_0.ZIndex = 4;
	tab_image_0.Image = "rbxassetid://8816521065";
	tab_image_0.ImageColor3 = Color3.fromRGB(67.00000360608101, 67.00000360608101, 67.00000360608101);

	local visuals_tab = Instance.new("Frame", tab_holder);
	visuals_tab.BackgroundColor3 = Color3.fromRGB(12.000001184642315, 12.000001184642315, 12.000001184642315);
	visuals_tab.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	visuals_tab.BorderSizePixel = 0;
	visuals_tab.Name = "visuals_tab";
	visuals_tab.Size = UDim2.new(1, 1, 0.1379999965429306, 0);
	visuals_tab.ZIndex = 2;

	local top_line_2 = Instance.new("Frame", visuals_tab);
	top_line_2.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	top_line_2.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	top_line_2.BorderSizePixel = 0;
	top_line_2.Name = "top_line";
	top_line_2.Size = UDim2.new(1, 0, 0, 1);
	top_line_2.Visible = false;
	top_line_2.ZIndex = 3;

	local bottom_line_2 = Instance.new("Frame", visuals_tab);
	bottom_line_2.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	bottom_line_2.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	bottom_line_2.BorderSizePixel = 0;
	bottom_line_2.Name = "bottom_line";
	bottom_line_2.Position = UDim2.new(0, 0, 1, 0);
	bottom_line_2.Size = UDim2.new(1, 0, 0, 1);
	bottom_line_2.Visible = false;
	bottom_line_2.ZIndex = 3;

	local side_line_2 = Instance.new("Frame", visuals_tab);
	side_line_2.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	side_line_2.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	side_line_2.BorderSizePixel = 0;
	side_line_2.Name = "side_line";
	side_line_2.Position = UDim2.new(1, -1, 0, 0);
	side_line_2.Size = UDim2.new(0, 1, 1, 0);
	side_line_2.ZIndex = 3;

	local tab_image_1 = Instance.new("ImageLabel", visuals_tab);
	tab_image_1.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	tab_image_1.BackgroundTransparency = 1;
	tab_image_1.Name = "tab_image";
	tab_image_1.Size = UDim2.new(1, 0, 1, 0);
	tab_image_1.ZIndex = 4;
	tab_image_1.Image = "rbxassetid://8816523039";
	tab_image_1.ImageColor3 = Color3.fromRGB(67.00000360608101, 67.00000360608101, 67.00000360608101);

	local settings_tab = Instance.new("Frame", tab_holder);
	settings_tab.BackgroundColor3 = Color3.fromRGB(12.000001184642315, 12.000001184642315, 12.000001184642315);
	settings_tab.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	settings_tab.BorderSizePixel = 0;
	settings_tab.Name = "settings_tab";
	settings_tab.Size = UDim2.new(1, 1, 0.1379999965429306, 0);
	settings_tab.ZIndex = 2;

	local top_line_3 = Instance.new("Frame", settings_tab);
	top_line_3.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	top_line_3.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	top_line_3.BorderSizePixel = 0;
	top_line_3.Name = "top_line";
	top_line_3.Size = UDim2.new(1, 0, 0, 1);
	top_line_3.Visible = false;
	top_line_3.ZIndex = 3;

	local bottom_line_3 = Instance.new("Frame", settings_tab);
	bottom_line_3.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	bottom_line_3.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	bottom_line_3.BorderSizePixel = 0;
	bottom_line_3.Name = "bottom_line";
	bottom_line_3.Position = UDim2.new(0, 0, 1, 0);
	bottom_line_3.Size = UDim2.new(1, 0, 0, 1);
	bottom_line_3.Visible = false;
	bottom_line_3.ZIndex = 3;

	local side_line_3 = Instance.new("Frame", settings_tab);
	side_line_3.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	side_line_3.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	side_line_3.BorderSizePixel = 0;
	side_line_3.Name = "side_line";
	side_line_3.Position = UDim2.new(1, -1, 0, 0);
	side_line_3.Size = UDim2.new(0, 1, 1, 0);
	side_line_3.ZIndex = 3;

	local tab_image_2 = Instance.new("ImageLabel", settings_tab);
	tab_image_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	tab_image_2.BackgroundTransparency = 1;
	tab_image_2.Name = "tab_image";
	tab_image_2.Size = UDim2.new(1, 0, 1, 0);
	tab_image_2.ZIndex = 4;
	tab_image_2.Image = "rbxassetid://8816524736";
	tab_image_2.ImageColor3 = Color3.fromRGB(67.00000360608101, 67.00000360608101, 67.00000360608101);

	local skins_tab = Instance.new("Frame", tab_holder);
	skins_tab.BackgroundColor3 = Color3.fromRGB(12.000001184642315, 12.000001184642315, 12.000001184642315);
	skins_tab.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	skins_tab.BorderSizePixel = 0;
	skins_tab.Name = "skins_tab";
	skins_tab.Size = UDim2.new(1, 1, 0.1379999965429306, 0);
	skins_tab.ZIndex = 2;

	local top_line_4 = Instance.new("Frame", skins_tab);
	top_line_4.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	top_line_4.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	top_line_4.BorderSizePixel = 0;
	top_line_4.Name = "top_line";
	top_line_4.Size = UDim2.new(1, 0, 0, 1);
	top_line_4.Visible = false;
	top_line_4.ZIndex = 3;

	local bottom_line_4 = Instance.new("Frame", skins_tab);
	bottom_line_4.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	bottom_line_4.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	bottom_line_4.BorderSizePixel = 0;
	bottom_line_4.Name = "bottom_line";
	bottom_line_4.Position = UDim2.new(0, 0, 1, 0);
	bottom_line_4.Size = UDim2.new(1, 0, 0, 1);
	bottom_line_4.Visible = false;
	bottom_line_4.ZIndex = 3;

	local side_line_4 = Instance.new("Frame", skins_tab);
	side_line_4.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	side_line_4.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	side_line_4.BorderSizePixel = 0;
	side_line_4.Name = "side_line";
	side_line_4.Position = UDim2.new(1, -1, 0, 0);
	side_line_4.Size = UDim2.new(0, 1, 1, 0);
	side_line_4.ZIndex = 3;

	local tab_image_3 = Instance.new("ImageLabel", skins_tab);
	tab_image_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	tab_image_3.BackgroundTransparency = 1;
	tab_image_3.Name = "tab_image";
	tab_image_3.Size = UDim2.new(1, 0, 1, 0);
	tab_image_3.ZIndex = 4;
	tab_image_3.Image = "rbxassetid://8816523751";
	tab_image_3.ImageColor3 = Color3.fromRGB(67.00000360608101, 67.00000360608101, 67.00000360608101);

	local players_tab = Instance.new("Frame", tab_holder);
	players_tab.BackgroundColor3 = Color3.fromRGB(12.000001184642315, 12.000001184642315, 12.000001184642315);
	players_tab.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	players_tab.BorderSizePixel = 0;
	players_tab.Name = "players_tab";
	players_tab.Size = UDim2.new(1, 1, 0.1379999965429306, 0);
	players_tab.ZIndex = 2;

	local top_line_5 = Instance.new("Frame", players_tab);
	top_line_5.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	top_line_5.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	top_line_5.BorderSizePixel = 0;
	top_line_5.Name = "top_line";
	top_line_5.Size = UDim2.new(1, 0, 0, 1);
	top_line_5.Visible = false;
	top_line_5.ZIndex = 3;

	local bottom_line_5 = Instance.new("Frame", players_tab);
	bottom_line_5.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	bottom_line_5.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	bottom_line_5.BorderSizePixel = 0;
	bottom_line_5.Name = "bottom_line";
	bottom_line_5.Position = UDim2.new(0, 0, 1, 0);
	bottom_line_5.Size = UDim2.new(1, 0, 0, 1);
	bottom_line_5.Visible = false;
	bottom_line_5.ZIndex = 3;

	local side_line_5 = Instance.new("Frame", players_tab);
	side_line_5.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	side_line_5.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	side_line_5.BorderSizePixel = 0;
	side_line_5.Name = "side_line";
	side_line_5.Position = UDim2.new(1, -1, 0, 0);
	side_line_5.Size = UDim2.new(0, 1, 1, 0);
	side_line_5.ZIndex = 3;

	local tab_image_4 = Instance.new("ImageLabel", players_tab);
	tab_image_4.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	tab_image_4.BackgroundTransparency = 1;
	tab_image_4.Name = "tab_image";
	tab_image_4.Size = UDim2.new(1, 0, 1, 0);
	tab_image_4.ZIndex = 4;
	tab_image_4.Image = "rbxassetid://8816551170";
	tab_image_4.ImageColor3 = Color3.fromRGB(67.00000360608101, 67.00000360608101, 67.00000360608101);

	local lua_tab = Instance.new("Frame", tab_holder);
	lua_tab.BackgroundColor3 = Color3.fromRGB(12.000001184642315, 12.000001184642315, 12.000001184642315);
	lua_tab.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	lua_tab.BorderSizePixel = 0;
	lua_tab.Name = "lua_tab";
	lua_tab.Size = UDim2.new(1, 1, 0.1379999965429306, 0);
	lua_tab.ZIndex = 2;

	local top_line_6 = Instance.new("Frame", lua_tab);
	top_line_6.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	top_line_6.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	top_line_6.BorderSizePixel = 0;
	top_line_6.Name = "top_line";
	top_line_6.Size = UDim2.new(1, 0, 0, 1);
	top_line_6.Visible = false;
	top_line_6.ZIndex = 3;

	local bottom_line_6 = Instance.new("Frame", lua_tab);
	bottom_line_6.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	bottom_line_6.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	bottom_line_6.BorderSizePixel = 0;
	bottom_line_6.Name = "bottom_line";
	bottom_line_6.Position = UDim2.new(0, 0, 1, 0);
	bottom_line_6.Size = UDim2.new(1, 0, 0, 1);
	bottom_line_6.Visible = false;
	bottom_line_6.ZIndex = 3;

	local side_line_6 = Instance.new("Frame", lua_tab);
	side_line_6.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	side_line_6.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	side_line_6.BorderSizePixel = 0;
	side_line_6.Name = "side_line";
	side_line_6.Position = UDim2.new(1, -1, 0, 0);
	side_line_6.Size = UDim2.new(0, 1, 1, 0);
	side_line_6.ZIndex = 3;

	local tab_image_5 = Instance.new("ImageLabel", lua_tab);
	tab_image_5.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	tab_image_5.BackgroundTransparency = 1;
	tab_image_5.Name = "tab_image";
	tab_image_5.Size = UDim2.new(1, 0, 1, 0);
	tab_image_5.ZIndex = 4;
	tab_image_5.Image = "http://www.roblox.com/asset/?id=11763091015";
	tab_image_5.ImageColor3 = Color3.fromRGB(67.00000360608101, 67.00000360608101, 67.00000360608101);

	local size_handle_0 = Instance.new("Frame", tab_holder);
	size_handle_0.BackgroundColor3 = Color3.fromRGB(12.000001184642315, 12.000001184642315, 12.000001184642315);
	size_handle_0.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	size_handle_0.BorderSizePixel = 0;
	size_handle_0.Name = "size_handle";
	size_handle_0.Size = UDim2.new(1, 1, 0.019999999552965164, 0);
	size_handle_0.ZIndex = 2;

	local top_line_7 = Instance.new("Frame", size_handle_0);
	top_line_7.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	top_line_7.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	top_line_7.BorderSizePixel = 0;
	top_line_7.Name = "top_line";
	top_line_7.Size = UDim2.new(1, 0, 0, 1);
	top_line_7.Visible = false;
	top_line_7.ZIndex = 3;

	local bottom_line_7 = Instance.new("Frame", size_handle_0);
	bottom_line_7.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	bottom_line_7.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	bottom_line_7.BorderSizePixel = 0;
	bottom_line_7.Name = "bottom_line";
	bottom_line_7.Position = UDim2.new(0, 0, 1, 0);
	bottom_line_7.Size = UDim2.new(1, 0, 0, 1);
	bottom_line_7.Visible = false;
	bottom_line_7.ZIndex = 3;

	local side_line_7 = Instance.new("Frame", size_handle_0);
	side_line_7.BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	side_line_7.BorderColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
	side_line_7.BorderSizePixel = 0;
	side_line_7.Name = "side_line";
	side_line_7.Position = UDim2.new(1, -1, 0, 0);
	side_line_7.Size = UDim2.new(0, 1, 1, 0);
	side_line_7.ZIndex = 3;

	local rage_tab_0 = Instance.new("Frame", inside);
	rage_tab_0.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	rage_tab_0.BackgroundTransparency = 1;
	rage_tab_0.BorderSizePixel = 0;
	rage_tab_0.Name = "rage_tab";
	rage_tab_0.Position = UDim2.new(0.14000000059604645, 0, 0.020999999716877937, 0);
	rage_tab_0.Size = UDim2.new(0.675000011920929, 100, 0.9599999785423279, 0);
	rage_tab_0.ZIndex = 2;

	local left = Instance.new("Frame", rage_tab_0);
	left.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	left.BackgroundTransparency = 1;
	left.Name = "left";
	left.Size = UDim2.new(0.49000000953674316, 0, 1, 0);
	left.ZIndex = 3;

	local UIListLayout_0 = Instance.new("UIListLayout", left);
	UIListLayout_0.SortOrder = Enum.SortOrder.LayoutOrder;
	UIListLayout_0.Padding = UDim.new(0, 15);

	local right = Instance.new("Frame", rage_tab_0);
	right.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	right.BackgroundTransparency = 1;
	right.Name = "right";
	right.Position = UDim2.new(1, -241, 0, 0);
	right.Size = UDim2.new(0.49000000953674316, 0, 1, 0);
	right.ZIndex = 3;

	local UIListLayout_1 = Instance.new("UIListLayout", right);
	UIListLayout_1.SortOrder = Enum.SortOrder.LayoutOrder;
	UIListLayout_1.Padding = UDim.new(0, 15);

	local UIListLayout_2 = Instance.new("UIListLayout", rage_tab_0);
	UIListLayout_2.Padding = UDim.new(0.019999999552965164, 0);
	UIListLayout_2.FillDirection = Enum.FillDirection.Horizontal;
	UIListLayout_2.SortOrder = Enum.SortOrder.LayoutOrder;

	local aa_tab_0 = Instance.new("Frame", inside);
	aa_tab_0.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	aa_tab_0.BackgroundTransparency = 1;
	aa_tab_0.BorderSizePixel = 0;
	aa_tab_0.Name = "aa_tab";
	aa_tab_0.Position = UDim2.new(0.14000000059604645, 0, 0.020999999716877937, 0);
	aa_tab_0.Size = UDim2.new(0.675000011920929, 100, 0.9599999785423279, 0);
	aa_tab_0.Visible = false;
	aa_tab_0.ZIndex = 2;

	local left_0 = Instance.new("Frame", aa_tab_0);
	left_0.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	left_0.BackgroundTransparency = 1;
	left_0.Name = "left";
	left_0.Size = UDim2.new(0.49000000953674316, 0, 1, 0);
	left_0.ZIndex = 3;

	local UIListLayout_3 = Instance.new("UIListLayout", left_0);
	UIListLayout_3.Padding = UDim.new(0, 15);
	UIListLayout_3.SortOrder = Enum.SortOrder.LayoutOrder;

	local right_0 = Instance.new("Frame", aa_tab_0);
	right_0.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	right_0.BackgroundTransparency = 1;
	right_0.Name = "right";
	right_0.Position = UDim2.new(1, -241, 0, 0);
	right_0.Size = UDim2.new(0.49000000953674316, 0, 1, 0);
	right_0.ZIndex = 3;
	

	local UIListLayout_4 = Instance.new("UIListLayout", right_0);
	UIListLayout_4.SortOrder = Enum.SortOrder.LayoutOrder;
	UIListLayout_4.Padding = UDim.new(0, 15);

	local UIListLayout_5 = Instance.new("UIListLayout", aa_tab_0);
	UIListLayout_5.Padding = UDim.new(0.019999999552965164, 0);
	UIListLayout_5.FillDirection = Enum.FillDirection.Horizontal;
	UIListLayout_5.SortOrder = Enum.SortOrder.LayoutOrder;

	local visuals_tab_0 = Instance.new("Frame", inside);
	visuals_tab_0.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	visuals_tab_0.BackgroundTransparency = 1;
	visuals_tab_0.BorderSizePixel = 0;
	visuals_tab_0.Name = "visuals_tab";
	visuals_tab_0.Position = UDim2.new(0.14000000059604645, 0, 0.020999999716877937, 0);
	visuals_tab_0.Size = UDim2.new(0.675000011920929, 100, 0.9599999785423279, 0);
	visuals_tab_0.Visible = false;
	visuals_tab_0.ZIndex = 2;

	local left_1 = Instance.new("Frame", visuals_tab_0);
	left_1.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	left_1.BackgroundTransparency = 1;
	left_1.Name = "left";
	left_1.Size = UDim2.new(0.49000000953674316, 0, 1, 0);
	left_1.ZIndex = 3;

	local UIListLayout_6 = Instance.new("UIListLayout", left_1);
	UIListLayout_6.SortOrder = Enum.SortOrder.LayoutOrder;
	UIListLayout_6.Padding = UDim.new(0, 15);

	local right_1 = Instance.new("Frame", visuals_tab_0);
	right_1.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	right_1.BackgroundTransparency = 1;
	right_1.Name = "right";
	right_1.Position = UDim2.new(1, -241, 0, 0);
	right_1.Size = UDim2.new(0.49000000953674316, 0, 1, 0);
	right_1.ZIndex = 3;

	local UIListLayout_7 = Instance.new("UIListLayout", right_1);
	UIListLayout_7.SortOrder = Enum.SortOrder.LayoutOrder;
	UIListLayout_7.Padding = UDim.new(0, 15);

	local UIListLayout_8 = Instance.new("UIListLayout", visuals_tab_0);
	UIListLayout_8.Padding = UDim.new(0.019999999552965164, 0);
	UIListLayout_8.FillDirection = Enum.FillDirection.Horizontal;
	UIListLayout_8.SortOrder = Enum.SortOrder.LayoutOrder;

	local settings_tab_0 = Instance.new("Frame", inside);
	settings_tab_0.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	settings_tab_0.BackgroundTransparency = 1;
	settings_tab_0.BorderSizePixel = 0;
	settings_tab_0.Name = "settings_tab";
	settings_tab_0.Position = UDim2.new(0.14000000059604645, 0, 0.020999999716877937, 0);
	settings_tab_0.Size = UDim2.new(0.675000011920929, 100, 0.9599999785423279, 0);
	settings_tab_0.Visible = false;
	settings_tab_0.ZIndex = 2;

	local left_2 = Instance.new("Frame", settings_tab_0);
	left_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	left_2.BackgroundTransparency = 1;
	left_2.Name = "left";
	left_2.Size = UDim2.new(0.49000000953674316, 0, 1, 0);
	left_2.ZIndex = 3;

	local UIListLayout_9 = Instance.new("UIListLayout", left_2);
	UIListLayout_9.Padding = UDim.new(0, 15);
	UIListLayout_9.SortOrder = Enum.SortOrder.LayoutOrder;

	local right_2 = Instance.new("Frame", settings_tab_0);
	right_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	right_2.BackgroundTransparency = 1;
	right_2.Name = "right";
	right_2.Position = UDim2.new(1, -241, 0, 0);
	right_2.Size = UDim2.new(0.49000000953674316, 0, 1, 0);
	right_2.ZIndex = 3;

	local UIListLayout_10 = Instance.new("UIListLayout", right_2);
	UIListLayout_10.Padding = UDim.new(0, 15);
	UIListLayout_10.SortOrder = Enum.SortOrder.LayoutOrder;

	local UIListLayout_11 = Instance.new("UIListLayout", settings_tab_0);
	UIListLayout_11.Padding = UDim.new(0.019999999552965164, 0);
	UIListLayout_11.FillDirection = Enum.FillDirection.Horizontal;
	UIListLayout_11.SortOrder = Enum.SortOrder.LayoutOrder;

	local players_tab_0 = Instance.new("Frame", inside);
	players_tab_0.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	players_tab_0.BackgroundTransparency = 1;
	players_tab_0.BorderSizePixel = 0;
	players_tab_0.Name = "players_tab";
	players_tab_0.Position = UDim2.new(0.14000000059604645, 0, 0.020999999716877937, 0);
	players_tab_0.Size = UDim2.new(0.675000011920929, 100, 0.9599999785423279, 0);
	players_tab_0.Visible = false;
	players_tab_0.ZIndex = 2;

	local left_3 = Instance.new("Frame", players_tab_0);
	left_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	left_3.BackgroundTransparency = 1;
	left_3.Name = "left";
	left_3.Size = UDim2.new(0.49000000953674316, 0, 1, 0);
	left_3.ZIndex = 3;

	local UIListLayout_12 = Instance.new("UIListLayout", left_3);
	UIListLayout_12.Padding = UDim.new(0.029999999329447746, 0);
	UIListLayout_12.SortOrder = Enum.SortOrder.LayoutOrder;

	local right_3 = Instance.new("Frame", players_tab_0);
	right_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	right_3.BackgroundTransparency = 1;
	right_3.Name = "right";
	right_3.Position = UDim2.new(1, -241, 0, 0);
	right_3.Size = UDim2.new(0.49000000953674316, 0, 1, 0);
	right_3.ZIndex = 3;

	local UIListLayout_13 = Instance.new("UIListLayout", right_3);
	UIListLayout_13.Padding = UDim.new(0, 15);
	UIListLayout_13.SortOrder = Enum.SortOrder.LayoutOrder;

	local UIListLayout_14 = Instance.new("UIListLayout", players_tab_0);
	UIListLayout_14.Padding = UDim.new(0.019999999552965164, 0);
	UIListLayout_14.FillDirection = Enum.FillDirection.Horizontal;
	UIListLayout_14.SortOrder = Enum.SortOrder.LayoutOrder;

	local skins_tab_0 = Instance.new("Frame", inside);
	skins_tab_0.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	skins_tab_0.BackgroundTransparency = 1;
	skins_tab_0.BorderSizePixel = 0;
	skins_tab_0.Name = "skins_tab";
	skins_tab_0.Position = UDim2.new(0.14000000059604645, 0, 0.020999999716877937, 0);
	skins_tab_0.Size = UDim2.new(0.675000011920929, 100, 0.9599999785423279, 0);
	skins_tab_0.Visible = false;
	skins_tab_0.ZIndex = 2;

	local left_4 = Instance.new("Frame", skins_tab_0);
	left_4.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	left_4.BackgroundTransparency = 1;
	left_4.Name = "left";
	left_4.Size = UDim2.new(0.49000000953674316, 0, 1, 0);
	left_4.ZIndex = 3;

	local UIListLayout_15 = Instance.new("UIListLayout", left_4);
	UIListLayout_15.Padding = UDim.new(0, 15);
	UIListLayout_15.SortOrder = Enum.SortOrder.LayoutOrder;

	local right_4 = Instance.new("Frame", skins_tab_0);
	right_4.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	right_4.BackgroundTransparency = 1;
	right_4.Name = "right";
	right_4.Position = UDim2.new(1, -241, 0, 0);
	right_4.Size = UDim2.new(0.49000000953674316, 0, 1, 0);
	right_4.ZIndex = 3;

	local UIListLayout_16 = Instance.new("UIListLayout", right_4);
	UIListLayout_16.SortOrder = Enum.SortOrder.LayoutOrder;

	local UIListLayout_17 = Instance.new("UIListLayout", skins_tab_0);
	UIListLayout_17.Padding = UDim.new(0.019999999552965164, 0);
	UIListLayout_17.FillDirection = Enum.FillDirection.Horizontal;
	UIListLayout_17.SortOrder = Enum.SortOrder.LayoutOrder;

	local lua_tab_0 = Instance.new("Frame", inside);
	lua_tab_0.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	lua_tab_0.BackgroundTransparency = 1;
	lua_tab_0.BorderSizePixel = 0;
	lua_tab_0.Name = "lua_tab";
	lua_tab_0.Position = UDim2.new(0.14000000059604645, 0, 0.020999999716877937, 0);
	lua_tab_0.Size = UDim2.new(0.675000011920929, 100, 0.9599999785423279, 0);
	lua_tab_0.Visible = false;
	lua_tab_0.ZIndex = 2;

	local left_5 = Instance.new("Frame", lua_tab_0);
	left_5.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	left_5.BackgroundTransparency = 1;
	left_5.Name = "left";
	left_5.Size = UDim2.new(0.49000000953674316, 0, 1, 0);
	left_5.ZIndex = 3;

	local UIListLayout_18 = Instance.new("UIListLayout", left_5);
	UIListLayout_18.Padding = UDim.new(0.029999999329447746, 0);
	UIListLayout_18.SortOrder = Enum.SortOrder.LayoutOrder;

	local right_5 = Instance.new("Frame", lua_tab_0);
	right_5.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	right_5.BackgroundTransparency = 1;
	right_5.Name = "right";
	right_5.Position = UDim2.new(1, -241, 0, 0);
	right_5.Size = UDim2.new(0.49000000953674316, 0, 1, 0);
	right_5.ZIndex = 3;

	local UIListLayout_19 = Instance.new("UIListLayout", right_5);
	UIListLayout_19.Padding = UDim.new(0, 15);
	UIListLayout_19.SortOrder = Enum.SortOrder.LayoutOrder;

	local UIListLayout_20 = Instance.new("UIListLayout", lua_tab_0);
	UIListLayout_20.Padding = UDim.new(0.019999999552965164, 0);
	UIListLayout_20.FillDirection = Enum.FillDirection.Horizontal;
	UIListLayout_20.SortOrder = Enum.SortOrder.LayoutOrder;
	
	local b = lib.util.new("ImageLabel", {
		Parent = inside;
		BackgroundColor3 = Color3.fromRGB(255, 255, 255);
		BorderSizePixel = 0;
		Name = "bg";
		Size = UDim2.new(1, 0, 1, 0);
		Image = "rbxassetid://8816631771";
		ZIndex = 1;
	}, {})
	
	local rainbowline = lib.util.new("ImageLabel", {
		Parent = inside;
		BackgroundColor3 = Color3.fromRGB(255, 255, 255);
		BorderSizePixel = 0;
		Name = "rainbowline";
		Size = UDim2.new(1, 0, 0, 2);
		Image = "http://www.roblox.com/asset/?id=7023958524";
		ZIndex = 4;
	}, {})
	
	lib.stats = {
		tab = "rage",
		key = Enum.KeyCode.LeftAlt,
		clr = Color3.fromRGB(143, 190, 55),
		busy = false
	}
	
	lib.flags = {}
	
	local tn = {"rage","aa","visuals","players","skins","settings","lua"}
	
	lib.titems = {}
	
	for i,v in pairs(tn) do
		lib.stats[v] = {}
		lib.stats[v]["count"] = 0
	end
	
	lib.util.changeTab = function(name, button)
		if not lib.stats.busy then
			for i,v in pairs(lib.titems) do
				if v.Name:match("([^_]+)_([^_]+)") == name then
					v.BackgroundTransparency = 1
					v.bottom_line.Visible = true
					v.top_line.Visible = true
					v.side_line.Visible = false
					v.tab_image.ImageColor3 = Color3.fromRGB(199, 199, 199)
					inside:FindFirstChild(v.Name).Visible = true
				else
					v.BackgroundTransparency = 0
					v.bottom_line.Visible = false
					v.top_line.Visible = false
					v.side_line.Visible = true
					v.tab_image.ImageColor3 = Color3.fromRGB(67, 67, 67)
					inside:FindFirstChild(v.Name).Visible = false
				end
			end
		end
	end
	
	for i,v in pairs(tab_holder:GetChildren()) do
		if v:IsA("Frame") and v.Name ~= "size_handle" then
			local t = v.Name:match("([^_]+)_([^_]+)")
			table.insert(lib.titems, v)
			v.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 and lib.stats.tab ~= t and not lib.stats.busy then
					lib.stats.tab = t
					lib.util.changeTab(t, v)
				end
			end)
			
			v.MouseEnter:Connect(function()
				v.tab_image.ImageColor3 = Color3.fromRGB(199, 199, 199)
			end)

			v.MouseLeave:Connect(function()
				v.tab_image.ImageColor3 = lib.stats.tab == t and Color3.fromRGB(199, 199, 199) or Color3.fromRGB(67, 67, 67)
			end)
		end
	end
	
	local l = {}
	
	l.create_section = function(tab, name)
		lib.stats[tab]["count"] = lib.stats[tab]["count"] + 1
		local section = Instance.new("Frame", lib.stats[tab]["count"] % 2 == 0 and inside[tab.."_tab"].right or inside[tab.."_tab"].left);
		section.BackgroundColor3 = Color3.fromRGB(19.0000007674098, 19.0000007674098, 19.0000007674098);
		section.BorderColor3 = Color3.fromRGB(42.000001296401024, 42.000001296401024, 42.000001296401024);
		section.Name = "section";
		section.Size = UDim2.new(1, 0, 0, 21);
		section.ZIndex = 2;
		
		local t = {}

		local section_label = Instance.new("TextLabel", section);
		section_label.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
		section_label.BackgroundTransparency = 1;
		section_label.Name = "section_label";
		section_label.Position = UDim2.new(0.029999999329447746, 0, 0, -10);
		section_label.Size = UDim2.new(0.949999988079071, 0, 0, 20);
		section_label.ZIndex = 4;
		section_label.Font = Enum.Font.SourceSansBold;
		section_label.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal);
		section_label.Text = name
		section_label.TextColor3 = Color3.fromRGB(221.00001722574234, 221.00001722574234, 221.00001722574234);
		section_label.TextSize = 14;
		section_label.TextStrokeTransparency = 0.6000000238418579;
		section_label.TextXAlignment = Enum.TextXAlignment.Left;

		local section_holder = Instance.new("Frame", section);
		section_holder.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
		section_holder.BackgroundTransparency = 1;
		section_holder.Name = "section_holder";
		section_holder.Position = UDim2.new(0.07000000029802322, 0, 0, 14);
		section_holder.Size = UDim2.new(1, -34, 1, -19);

		local UIListLayout = Instance.new("UIListLayout", section_holder);
		UIListLayout.Padding = UDim.new(0, 2);
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder;

		function t:destroy()
			section:Destroy()
			lib.stats[tab]["count"] = lib.stats[tab]["count"] - 1
		end
		
		t.create_element = function(args)
			local n = args["name"]
			local f = args["flag"]
			local h = args["highlight"]
			local c = args["callback"]
			local t2 = {}
			for i,v in pairs(args["types"]) do
				table.insert(t2, v)
			end
			
			local t = {}
			
			lib.flags[f] = {}
			
			local element = Instance.new("Frame", section_holder);
			element.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
			element.Name = "element";
			element.Size = UDim2.new(1, 0, 0, 14);

			local elabel = Instance.new("TextLabel", element);
			elabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
			elabel.BackgroundTransparency = 1;
			elabel.Name = "elabel";
			elabel.Position = UDim2.new(0.10000000149011612, 0, 0, 0);
			elabel.Size = UDim2.new(0.6000000238418579, 0, 0, 13);
			elabel.ZIndex = 3;
			elabel.Font = Enum.Font.SourceSans;
			elabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
			elabel.Text = n;
			elabel.TextColor3 = h and Color3.fromRGB(149, 149, 84) or Color3.fromRGB(189.00000393390656, 189.00000393390656, 189.00000393390656);
			elabel.TextSize = 14;
			elabel.TextStrokeTransparency = 0.5199999809265137;
			elabel.TextWrapped = true;
			elabel.TextXAlignment = Enum.TextXAlignment.Left;

			local addon_holder = Instance.new("Frame", element);
			addon_holder.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
			addon_holder.Name = "addon_holder";
			addon_holder.Position = UDim2.new(0.5, 0, 0, 0);
			addon_holder.Size = UDim2.new(0.5, 0, 0, 14);

			local UIListLayout = Instance.new("UIListLayout", addon_holder);
			UIListLayout.FillDirection = Enum.FillDirection.Horizontal;
			UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right;
			UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder;
			UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom;

			function t:set_visible(visible)
				element.Visible = visible
				if visible then
					section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset + 16)
					if find(t2, "slider") then
						section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset + 16)
					end
					if find(t2, "dropdown") then
						section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset + 26)
					end
					if find(t2, "textbox") then
						section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset + 26)
					end
					if find(t2, "button") then
						section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset + 16)
					end
				else
					if find(t2, "slider") then
						section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset - 16)
					end
					if find(t2, "dropdown") then
						section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset - 26)
					end
					if find(t2, "textbox") then
						section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset - 26)
					end
					if find(t2, "button") then
						section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset - 16)
					end
					section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset - 16)
				end
			end

			function t:destroy()
				lib.flags[f] = nil
				element:Destroy()
				if find(v2, "slider") then
					section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset - 16)
				end
				if find(v2, "dropdown") then
					section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset - 26)
				end
				if find(v2, "textbox") then
					section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset - 26)
				end
				if find(v2, "button") then
					section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset - 16)
				end
				section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset - 14)
			end
			
			section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset + 16);
			
			for i,v in pairs(t2) do
				if v == "toggle" then
					local def = args["tdefault"]
					local cb = args["noload"] or true
					local box = Instance.new("Frame", elabel);
					box.BackgroundColor3 = Color3.fromRGB(57.00000040233135, 57.00000040233135, 57.00000040233135);
					box.BorderColor3 = Color3.fromRGB(12.000000234693289, 12.000000234693289, 12.000000234693289);
					box.Name = "box";
					box.Position = UDim2.new(0, -21, 0.5, -3);
					box.Size = UDim2.new(0, 8, 0, 8);
					box.ZIndex = 3;

					local UIGradient = Instance.new("UIGradient", box);
					UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(249, 249, 249)), ColorSequenceKeypoint.new(1, Color3.fromRGB(202.00000286102295, 202.00000286102295, 202.00000286102295))};
					UIGradient.Rotation = 90;
					
					element.MouseEnter:Connect(function()
						box.BackgroundColor3 = lib.flags[f]["toggle"] and Color3.fromRGB(143, 190, 55) or Color3.fromRGB(72,72,72)
					end)
					
					element.MouseLeave:Connect(function()
						box.BackgroundColor3 = lib.flags[f]["toggle"] and Color3.fromRGB(143, 190, 55) or Color3.fromRGB(57,57,57)
					end)
					
					box.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 and not lib.stats.busy then
							t.set_toggle(not lib.flags[f]["toggle"], true)
						end
					end)
					
					elabel.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 and not lib.stats.busy then
							t.set_toggle(not lib.flags[f]["toggle"], true)
						end
					end)
					
					t.set_toggle = function(val, cb)
						lib.flags[f]["toggle"] = val
						box.BackgroundColor3 = lib.flags[f]["toggle"] and Color3.fromRGB(143, 190, 55) or Color3.fromRGB(57,57,57)
						if cb then
							pcall(c, lib.flags[f])
						end
					end
					
					t.set_toggle(def, true)
					
					lib.onConfigLoaded:Connect(function()
						t.set_toggle(lib.flags[f]["toggle"], true)
					end)
				elseif v == "keybind" then
					local def = args["kdefault"]
					local binding = false
					local methods = {"always","toggle","hold"}

					local keybind_label = Instance.new("TextLabel", addon_holder);
					keybind_label.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
					keybind_label.BackgroundTransparency = 1;
					keybind_label.Name = "keybind_label";
					keybind_label.Position = UDim2.new(-0.667937695980072, 0, -0.0357142873108387, 1);
					keybind_label.Size = UDim2.new(0, 25, 0, 13);
					keybind_label.ZIndex = 3;
					keybind_label.Font = Enum.Font.Unknown;
					keybind_label.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal);
					keybind_label.Text = "[-]";
					keybind_label.TextColor3 = Color3.fromRGB(65.0000037252903, 65.0000037252903, 65.0000037252903);
					keybind_label.TextSize = 14;
					keybind_label.TextStrokeTransparency = 0.6000000238418579;
					keybind_label.TextWrapped = true;
					keybind_label.TextScaled = true;
					keybind_label.ZIndex = 3;
					keybind_label.TextXAlignment = Enum.TextXAlignment.Right
					
					local keybind_frame = Instance.new("Frame", holder);
					keybind_frame.BackgroundColor3 = Color3.fromRGB(20.000000707805157, 20.000000707805157, 20.000000707805157);
					keybind_frame.BorderColor3 = Color3.fromRGB(57.00000040233135, 57.00000040233135, 57.00000040233135);
					keybind_frame.Name = "keybind_frame";
					keybind_frame.Position = UDim2.new(0, 25, 0, 2);
					keybind_frame.Size = UDim2.new(0, 80, 0, 60);
					keybind_frame.ZIndex = 4;
					keybind_frame.Visible = false
					
					for i = 1, #methods do
						local m = methods[i]
						
						local TextLabel = Instance.new("TextLabel", keybind_frame);
						TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
						TextLabel.BackgroundTransparency = 1;
						TextLabel.Size = UDim2.new(1, 0, 0, 20);
						TextLabel.Position = UDim2.new(0, 0, 0, i > 1 and 20 * (i-1) or 0);
						TextLabel.ZIndex = 5;
						TextLabel.Font = Enum.Font.SourceSans;
						TextLabel.Name = m;
						TextLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
						TextLabel.Text = m;
						TextLabel.TextColor3 = Color3.fromRGB(162.00000554323196, 162.00000554323196, 162.00000554323196);
						TextLabel.TextSize = 14;
						
						TextLabel.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								lib.flags[f]["bind"]["method"] = m
								t.set_keybind(lib.flags[f]["bind"])
								keybind_frame.Visible = false
								lib.stats.busy = false
							end
						end)
					end
					
					t.set_keybind = function(val)
						lib.flags[f]["bind"] = val
						if lib.flags[f]["bind"]["key"] == nil then
							keybind_label.Text = "[-]"
						else
							local key = lib.flags[f]["bind"]["key"]
							keybind_label.Text = keyNames[key] and "["..keyNames[key].."]" or "["..key.."]"
						end
						for i = 1, #methods do
							local m = methods[i]
							keybind_frame[m].Font = Enum.Font.SourceSans
							keybind_frame[m].TextColor3 = Color3.fromRGB(162.00000554323196, 162.00000554323196, 162.00000554323196);
						end
						keybind_frame[lib.flags[f]["bind"]["method"]].Font = Enum.Font.SourceSansBold
						keybind_frame[lib.flags[f]["bind"]["method"]].TextColor3 = Color3.fromRGB(143, 190, 55)
						lib.flags[f]["bind"] = val
						pcall(c, lib.flags[f])
					end
					
					keybind_label.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 and not lib.stats.busy and not binding then
							keybind_label.TextColor3 = Color3.fromRGB(155,0,0)
							keybind_label.Text = "[...]"
							binding = true
							lib.stats.busy = true
							
							local connection;
							connection = services.UserInputService.InputBegan:Connect(function(input)
								local mouse = false
								if input.UserInputType == Enum.UserInputType.MouseButton2 then
									mouse = "M2"
								elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
									mouse = "M3"
								elseif input.KeyCode.Name == "Unknown" then
									return
 								end
								task.wait(0.1)
								lib.flags[f]["bind"]["key"] = mouse and mouse or input.KeyCode.Name
								keybind_label.TextColor3 = Color3.fromRGB(65.0000037252903, 65.0000037252903, 65.0000037252903);
								t.set_keybind(lib.flags[f]["bind"])
								lib.stats.busy = false
								binding = false
								connection:Disconnect()
							end)
						elseif input.UserInputType == Enum.UserInputType.MouseButton2 and not lib.stats.busy then
							keybind_frame.Visible = true
							lib.stats.busy = true
							keybind_frame.Position = UDim2.new(0, keybind_label.AbsolutePosition.X + 30, 0, keybind_label.AbsolutePosition.Y + 2)
						end
					end)
					
					t.get_active = function()
						if lib.flags[f]["bind"]["method"] == "always" then
							return true
						end
						return lib.flags[f]["bind"]["active"]
					end
					
					services.UserInputService.InputBegan:Connect(function(input, gpe)
						if gpe then return end
						local key = lib.flags[f]["bind"]["key"]
						if key == "M2" or key == "M3" then
							if input.UserInputType == Enum.UserInputType.MouseButton2 and key == "M2" then
								lib.flags[f]["bind"]["active"] = not lib.flags[f]["bind"]["active"]
							elseif input.UserInputType == Enum.UserInputType.MouseButton3 and key == "M3" then
								lib.flags[f]["bind"]["active"] = not lib.flags[f]["bind"]["active"]
							end
						else
							if input.KeyCode.Name == lib.flags[f]["bind"]["key"] and lib.flags[f]["bind"]["method"] == "hold" then
								lib.flags[f]["bind"]["active"] = true
							elseif input.KeyCode.Name == lib.flags[f]["bind"]["key"] and lib.flags[f]["bind"]["method"] == "toggle" then
								lib.flags[f]["bind"]["active"] = not lib.flags[f]["bind"]["active"]
							end
						end
					end)
					
					services.UserInputService.InputEnded:Connect(function(input, gpe)
						local key = lib.flags[f]["bind"]["key"]
						if key == "M2" or key == "M3" then
							if lib.flags[f]["bind"]["method"] == "hold" then
								if input.UserInputType == Enum.UserInputType.MouseButton2 and key == "M2" then
									lib.flags[f]["bind"]["active"] = false
								elseif input.UserInputType == Enum.UserInputType.MouseButton3 and key == "M3" then
									lib.flags[f]["bind"]["active"] = false
								end
							end
						else
							if gpe then return end
							if input.KeyCode.Name == lib.flags[f]["bind"]["key"] and lib.flags[f]["bind"]["method"] == "hold" then
								lib.flags[f]["bind"]["active"] = false
							end
						end
					end)
					
					t.set_keybind(def and def or {["key"] = nil, ["method"] = "toggle", ["active"] = false})
					
					lib.onConfigLoaded:Connect(function()
						t.set_keybind(lib.flags[f]["bind"], true)
					end)
				elseif v == "slider" then
					element.Size = UDim2.new(element.Size.X.Scale, element.Size.X.Offset, element.Size.Y.Scale, element.Size.Y.Offset + 14);
					section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset + 14);
					local def = args["sdefault"] or 0
					local suffix = args["suffix"] or ""
					local prefix = args["prefix"] or ""
					local min = args["min"]
					local max = args["max"]
					local sliding, sliding2, inContact;

					local slider_background = Instance.new("Frame", element);
					slider_background.BackgroundColor3 = Color3.fromRGB(51.00000040233135, 51.00000040233135, 51.00000040233135);
					slider_background.BorderColor3 = Color3.fromRGB(0, 0, 0);
					slider_background.Name = "slider_background";
					slider_background.Position = UDim2.new(0.10000000149011612, 0, 0, 18);
					slider_background.Size = UDim2.new(0.800000011920929, 0, 0, 6);
					slider_background.ZIndex = 3;

					local UIGradient = Instance.new("UIGradient", slider_background);
					UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(163.00000435113907, 163.00000435113907, 163.00000435113907))};
					UIGradient.Rotation = 270;

					local slider_fill = Instance.new("Frame", slider_background);
					slider_fill.BackgroundColor3 = Color3.fromRGB(143.00000667572021, 190.0000038743019, 55.00000052154064);
					slider_fill.BorderColor3 = Color3.fromRGB(0, 0, 0);
					slider_fill.BorderSizePixel = 0;
					slider_fill.Name = "slider_fill";
					slider_fill.Size = UDim2.new(0, 0, 1, 0);
					slider_fill.ZIndex = 3;

					local slider_label = Instance.new("TextLabel", slider_fill);
					slider_label.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
					slider_label.Name = "slider_label";
					slider_label.Position = UDim2.new(1, 1, 0.800000011920929, 0);
					slider_label.Size = UDim2.new(0, 1, 0, 1);
					slider_label.ZIndex = 4;
					slider_label.Font = Enum.Font.SourceSansBold;
					slider_label.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal);
					slider_label.Text = "";
					slider_label.TextColor3 = Color3.fromRGB(228.0000016093254, 228.0000016093254, 228.0000016093254);
					slider_label.TextSize = 14;
					slider_label.TextStrokeTransparency = 0;

					local UIGradient_0 = Instance.new("UIGradient", slider_fill);
					UIGradient_0.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(221.00000202655792, 221.00000202655792, 221.00000202655792)), ColorSequenceKeypoint.new(1, Color3.fromRGB(77.00000301003456, 77.00000301003456, 77.00000301003456))};
					UIGradient_0.Rotation = 90;
					
					local function round(num, bracket)
						bracket = bracket or 1
						local a = math.floor(num/bracket + (math.sign(num) * 0.5)) * bracket
						if a < 0 then
							a = a + bracket
						end
						return a
					end

					t.set_slider = function(value3, call)
						value3 = round(value3, 1)
						value3 = math.clamp(value3, min, max)
						local value4 = math.clamp(value3, min, max)
						if min >= 0 then
							slider_fill.Size = UDim2.new((value4 - min) / (max - min), 0, 1, 0) 
						else
							slider_fill.Size = UDim2.new((0 - min) / (max - min), 0, 0, 0) 
							slider_fill.Size = UDim2.new(value4 / (max - min), 0, 1, 0) 
						end
						lib.flags[f]["value"] = value3
						slider_label.Text = prefix..tostring(value3)..suffix
						if call then
							pcall(c, lib.flags[f])
						end
					end

					slider_background.InputBegan:connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 and not lib.stats.busy then
							sliding = true
							sliding2 = true
							lib.stats.busy = true
							t.set_slider(min + ((input.Position.X - slider_background.AbsolutePosition.X) / slider_background.AbsoluteSize.X) * (max - min), true)
						end
						if input.UserInputType == Enum.UserInputType.MouseMovement and not lib.stats.busy then
							inContact = true
						end
					end)

					services.UserInputService.InputChanged:connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement and (sliding2 and lib.stats.busy) then
							t.set_slider(min + ((input.Position.X - slider_background.AbsolutePosition.X) / slider_background.AbsoluteSize.X) * (max - min), true)
						end
					end)

					slider_background.InputEnded:connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 and sliding2 then
							sliding = false
							sliding2 = false
							lib.stats.busy = false
						end
						if input.UserInputType == Enum.UserInputType.MouseMovement then
							inContact = false
						end
					end)
					
					t.set_slider(def, true)
					lib.onConfigLoaded:Connect(function()
						t.set_slider(lib.flags[f]["value"], true)
					end)
				elseif v == "colorpicker" then
					local color_box = Instance.new("Frame", addon_holder);
					color_box.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
					color_box.BorderColor3 = Color3.fromRGB(11.000000294297934, 11.000000294297934, 11.000000294297934);
					color_box.Name = "color_box";
					color_box.Size = UDim2.new(0, 20, 0, 11);
					color_box.ZIndex = 3;
					
					local def = args["cdefault"]

					local UIGradient = Instance.new("UIGradient", color_box);
					UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(221.00000202655792, 221.00000202655792, 221.00000202655792)), ColorSequenceKeypoint.new(1, Color3.fromRGB(77.00000301003456, 77.00000301003456, 77.00000301003456))};
					UIGradient.Rotation = 90;
					
					local colorPicker = Instance.new("Frame")
					local colorPickerInside = Instance.new("Frame")
					local colorPickerTransparencyBackground = Instance.new("Frame")
					local UIGradient = Instance.new("UIGradient")
					local colorPickerTransparencySlider = Instance.new("Frame")
					local colorPickerWheelBackground = Instance.new("Frame")
					local UIGradient_2 = Instance.new("UIGradient")
					local colorPickerTransparencySlider_2 = Instance.new("Frame")
					local colorPickerLabel = Instance.new("ImageLabel")
					local colorPickerSlider = Instance.new("Frame")

					colorPicker.Name = "colorPicker"
					colorPicker.Parent = holder
					colorPicker.BackgroundColor3 = Color3.fromRGB(57, 57, 57)
					colorPicker.BorderColor3 = Color3.fromRGB(0, 0, 0)
					colorPicker.Position = UDim2.new(0.179000005, 0, 0.710000038, 0)
					colorPicker.Size = UDim2.new(0, 165, 0, 135)
					colorPicker.ZIndex = 9
					colorPicker.Visible = false

					colorPickerInside.Name = "colorPickerInside"
					colorPickerInside.Parent = colorPicker
					colorPickerInside.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					colorPickerInside.BorderColor3 = Color3.fromRGB(0, 0, 0)
					colorPickerInside.BorderSizePixel = 0
					colorPickerInside.Position = UDim2.new(0, 1, 0, 1)
					colorPickerInside.Size = UDim2.new(1, -2, 1, -2)
					colorPickerInside.ZIndex = 9

					colorPickerTransparencyBackground.Name = "colorPickerTransparencyBackground"
					colorPickerTransparencyBackground.Parent = colorPickerInside
					colorPickerTransparencyBackground.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					colorPickerTransparencyBackground.BorderColor3 = Color3.fromRGB(0, 0, 0)
					colorPickerTransparencyBackground.Position = UDim2.new(1, -15, 0, 5)
					colorPickerTransparencyBackground.Size = UDim2.new(0, 10, 1, -10)
					colorPickerTransparencyBackground.ZIndex = 10

					UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))}
					UIGradient.Rotation = 90
					UIGradient.Parent = colorPickerTransparencyBackground

					colorPickerTransparencySlider.Name = "colorPickerTransparencySlider"
					colorPickerTransparencySlider.Parent = colorPickerTransparencyBackground
					colorPickerTransparencySlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					colorPickerTransparencySlider.BorderColor3 = Color3.fromRGB(0, 0, 0)
					colorPickerTransparencySlider.Size = UDim2.new(1, 0, 0, 2)
					colorPickerTransparencySlider.ZIndex = 11

					colorPickerWheelBackground.Name = "colorPickerWheelBackground"
					colorPickerWheelBackground.Parent = colorPickerInside
					colorPickerWheelBackground.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					colorPickerWheelBackground.BorderColor3 = Color3.fromRGB(0, 0, 0)
					colorPickerWheelBackground.Position = UDim2.new(1, -30, 0, 5)
					colorPickerWheelBackground.Size = UDim2.new(0, 10, 1, -10)
					colorPickerWheelBackground.ZIndex = 10

					UIGradient_2.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 0, 255)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 255, 0)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(170, 0, 0))}
					UIGradient_2.Rotation = 90
					UIGradient_2.Parent = colorPickerWheelBackground

					colorPickerTransparencySlider_2.Name = "colorPickerTransparencySlider"
					colorPickerTransparencySlider_2.Parent = colorPickerWheelBackground
					colorPickerTransparencySlider_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					colorPickerTransparencySlider_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
					colorPickerTransparencySlider_2.Size = UDim2.new(1, 0, 0, 2)
					colorPickerTransparencySlider_2.ZIndex = 11

					colorPickerLabel.Name = "colorPickerLabel"
					colorPickerLabel.Parent = colorPickerInside
					colorPickerLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					colorPickerLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
					colorPickerLabel.Position = UDim2.new(0, 5, 0, 5)
					colorPickerLabel.Size = UDim2.new(0, 123, 1, -10)
					colorPickerLabel.ZIndex = 11
					colorPickerLabel.Image = "rbxassetid://4155801252"

					colorPickerSlider.Name = "colorPickerSlider"
					colorPickerSlider.Parent = colorPickerLabel
					colorPickerSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					colorPickerSlider.BackgroundTransparency = 1.000
					colorPickerSlider.Size = UDim2.new(0, 2, 0, 2)
					colorPickerSlider.ZIndex = 12

					color_box.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 and not lib.stats.busy then
							lib.stats.busy = true
							colorPicker.Position = UDim2.new(0, color_box.AbsolutePosition.X, 0, color_box.AbsolutePosition.Y + 15)
							colorPicker.Visible = true
						elseif input.UserInputType == Enum.UserInputType.MouseButton1 and lib.stats.busy and colorPicker.Visible then
							lib.stats.busy = false
							colorPicker.Visible = false
						end
					end)

					local in_color = false
					local in_color2 = false

					function t.update_transp()
						local x = math.clamp(services.Players.LocalPlayer:GetMouse().Y - colorPickerTransparencyBackground.AbsolutePosition.Y, 0, 123)
						colorPickerTransparencySlider.Position = UDim2.new(0, 0, 0, x)
						local transparency = x/123
						lib.flags[f].Transparency = transparency

						pcall(c, lib.flags[f])
					end
					colorPickerTransparencyBackground.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							t.update_transp()
							local moveconnection = services.Players.LocalPlayer:GetMouse().Move:Connect(function()
								t.update_transp()
							end)
							releaseconnection = services.UserInputService.InputEnded:Connect(function(Mouse)
								if Mouse.UserInputType == Enum.UserInputType.MouseButton1 then
									t.update_transp()
									moveconnection:Disconnect()
									releaseconnection:Disconnect()
								end
							end)
						end
					end)

					t.h = (math.clamp(colorPickerWheelBackground.AbsolutePosition.Y-colorPickerTransparencySlider_2.AbsolutePosition.Y, 0, colorPickerTransparencySlider_2.AbsoluteSize.Y)/colorPickerTransparencySlider_2.AbsoluteSize.Y)
					t.s = 1-(math.clamp(colorPickerSlider.AbsolutePosition.X-colorPickerSlider.AbsolutePosition.X, 0, colorPickerTransparencySlider_2.AbsoluteSize.X)/colorPickerTransparencySlider_2.AbsoluteSize.X)
					t.v = 1-(math.clamp(colorPickerSlider.AbsolutePosition.Y-colorPickerSlider.AbsolutePosition.Y, 0, colorPickerTransparencySlider_2.AbsoluteSize.Y)/colorPickerTransparencySlider_2.AbsoluteSize.Y)

					lib.flags[f].Color = Color3.fromHSV(t.h, t.s, t.v)

					function t.update_color()
						local ColorX = (math.clamp(services.Players.LocalPlayer:GetMouse().X - colorPickerLabel.AbsolutePosition.X, 0, colorPickerLabel.AbsoluteSize.X)/colorPickerLabel.AbsoluteSize.X)
						local ColorY = (math.clamp(services.Players.LocalPlayer:GetMouse().Y - colorPickerLabel.AbsolutePosition.Y, 0, colorPickerLabel.AbsoluteSize.Y)/colorPickerLabel.AbsoluteSize.Y)
						colorPickerSlider.Position = UDim2.new(ColorX, 0, ColorY, 0)

						t.s = 1 - ColorX
						t.v = 1 - ColorY

						color_box.BackgroundColor3 = Color3.fromHSV(t.h, t.s, t.v)
						lib.flags[f].Color = Color3.fromHSV(t.h, t.s, t.v)
						pcall(c, lib.flags[f])
					end
					colorPickerLabel.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							t.update_color()
							local moveconnection = services.Players.LocalPlayer:GetMouse().Move:Connect(function()
								t.update_color()
							end)
							releaseconnection = services.UserInputService.InputEnded:Connect(function(Mouse)
								if Mouse.UserInputType == Enum.UserInputType.MouseButton1 then
									t.update_color()
									moveconnection:Disconnect()
									releaseconnection:Disconnect()
								end
							end)
						end
					end)

					function t.update_hue()
						local y = math.clamp(services.Players.LocalPlayer:GetMouse().Y - colorPickerWheelBackground.AbsolutePosition.Y, 0, 123)
						colorPickerTransparencySlider_2.Position = UDim2.new(0, 0, 0, y)
						local hue = y/123
						t.h = 1-hue
						colorPickerLabel.ImageColor3 = Color3.fromHSV(t.h, 1, 1)
						color_box.BackgroundColor3 = Color3.fromHSV(t.h, t.s, t.v)
						colorPickerLabel.ImageColor3 = Color3.fromHSV(t.h, 1, 1)
						lib.flags[f].Color = Color3.fromHSV(t.h, t.s, t.v)
						pcall(c, lib.flags[f])
					end
					colorPickerWheelBackground.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							t.update_hue()
							local moveconnection = services.Players.LocalPlayer:GetMouse().Move:Connect(function()
								t.update_hue()
							end)
							releaseconnection = services.UserInputService.InputEnded:Connect(function(Mouse)
								if Mouse.UserInputType == Enum.UserInputType.MouseButton1 then
									t.update_hue()
									moveconnection:Disconnect()
									releaseconnection:Disconnect()
								end
							end)
						end
					end)

					t.set = function(new_value)
						if typeof(new_value) == "Color3" then
							lib.flags[f].Color = new_value
							lib.flags[f].Transparency = 0
						else
							lib.flags[f].Color = new_value.Color
							lib.flags[f].Transparency = new_value.Transparency
						end

						local duplicate = Color3.new(lib.flags[f].Color.R, lib.flags[f].Color.G, lib.flags[f].Color.B)
						t.h, t.s, t.v = duplicate:ToHSV()
						t.h = math.clamp(t.h, 0, 1)
						t.s = math.clamp(t.s, 0, 1)
						t.v = math.clamp(t.v, 0, 1)

						colorPickerSlider.Position = UDim2.new(1 - t.s, 0, 1 - t.v, 0)
						t.ImageColor3 = Color3.fromHSV(t.h, 1, 1)
						t.BackgroundColor3 = Color3.fromHSV(t.h, t.s, t.v)
						color_box.BackgroundColor3 = Color3.fromHSV(t.h, t.s, t.v)
						colorPickerTransparencySlider_2.Position = UDim2.new(0, 0, 1 - t.h, -1)
						colorPickerLabel.ImageColor3 = Color3.fromHSV(t.h, 1, 1)

						colorPickerLabel.ImageColor3 = Color3.fromHSV(t.h, 1, 1)

						colorPickerTransparencySlider.Position = UDim2.new(lib.flags[f].Transparency, -1, 0, 0)

						pcall(c, lib.flags[f])
					end
					t.set(def)
					
					lib.onConfigLoaded:Connect(function()
						t.set(lib.flags[f])
					end)
				elseif v == "dropdown" then
					element.Size = UDim2.new(element.Size.X.Scale, element.Size.X.Offset, element.Size.Y.Scale, element.Size.Y.Offset + 26);
					section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset + 26);
					local def = args["ddefault"]
					local options = args["options"]
					local multi = args["multi"]
					
					local dropdown_background = Instance.new("Frame", element);
					dropdown_background.BackgroundColor3 = Color3.fromRGB(49.000000700354576, 49.000000700354576, 49.000000700354576);
					dropdown_background.BorderColor3 = Color3.fromRGB(11.000000294297934, 11.000000294297934, 11.000000294297934);
					dropdown_background.Name = "dropdown_background";
					dropdown_background.Position = UDim2.new(0.10000000149011612, 0, 0, 18);
					dropdown_background.Size = UDim2.new(0.800000011920929, 0, 0, 17);
					dropdown_background.ZIndex = 3;

					local UIGradient = Instance.new("UIGradient", dropdown_background);
					UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(163.00000435113907, 163.00000435113907, 163.00000435113907))};
					UIGradient.Rotation = 270;

					local dropdown_label = Instance.new("TextLabel", dropdown_background);
					dropdown_label.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
					dropdown_label.BackgroundTransparency = 1;
					dropdown_label.Name = "dropdown_label";
					dropdown_label.Position = UDim2.new(0.029999999329447746, 0, 0, 0);
					dropdown_label.Size = UDim2.new(0.94, 9, 1, 0);
					dropdown_label.ZIndex = 4;
					dropdown_label.Font = Enum.Font.SourceSans;
					dropdown_label.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
					dropdown_label.Text = "Off";
					dropdown_label.TextColor3 = Color3.fromRGB(95.00000193715096, 95.00000193715096, 95.00000193715096);
					dropdown_label.TextSize = 14;
					dropdown_label.TextStrokeTransparency = 0.6000000238418579;
					dropdown_label.TextXAlignment = Enum.TextXAlignment.Left;
					dropdown_label.TextWrapped = true

					local dropdown_image = Instance.new("ImageLabel", dropdown_background);
					dropdown_image.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
					dropdown_image.BackgroundTransparency = 1;
					dropdown_image.BorderSizePixel = 0;
					dropdown_image.Name = "dropdown_image";
					dropdown_image.Position = UDim2.new(1, -15, 0.5, -6);
					dropdown_image.Rotation = 180;
					dropdown_image.Size = UDim2.new(0, 12, 0, 12);
					dropdown_image.ZIndex = 4;
					dropdown_image.Image = "rbxassetid://278543076";
					dropdown_image.ImageColor3 = Color3.fromRGB(78.00000295042992, 78.00000295042992, 78.00000295042992);

					local dropdown_inside = Instance.new("Frame", holder);
					dropdown_inside.BackgroundColor3 = Color3.fromRGB(52.000000700354576, 52.000000700354576, 52.000000700354576);
					dropdown_inside.BorderColor3 = Color3.fromRGB(11.000000294297934, 11.000000294297934, 11.000000294297934);
					dropdown_inside.Name = "dropdown_inside";
					dropdown_inside.Position = UDim2.new(0, 0, 0, 20);
					dropdown_inside.Size = UDim2.new(0, 170, 0, 0);
					dropdown_inside.Visible = false;
					dropdown_inside.ZIndex = 8;

					local UIGradient_0 = Instance.new("UIGradient", dropdown_inside);
					UIGradient_0.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(163, 163, 163))};
					UIGradient_0.Rotation = 270;

					local UIListLayout = Instance.new("UIListLayout", dropdown_inside);
					UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder;
					
					dropdown_background.MouseEnter:Connect(function()
						dropdown_background.BackgroundColor3 = Color3.fromRGB(67,67,67)
					end)
					
					dropdown_background.MouseLeave:Connect(function()
						dropdown_background.BackgroundColor3 = Color3.fromRGB(49,49,49)
					end)
					
					dropdown_background.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 and not lib.stats.busy then
							lib.stats.busy = true
							dropdown_inside.Visible = true
							dropdown_image.Rotation = 0
							dropdown_inside.Position = UDim2.new(0, dropdown_background.AbsolutePosition.X + 1, 0, dropdown_background.AbsolutePosition.Y + 18)
						elseif input.UserInputType == Enum.UserInputType.MouseButton1 and lib.stats.busy and dropdown_inside.Visible then
							dropdown_inside.Visible = false
							dropdown_image.Rotation = 180
							lib.stats.busy = false
						end
					end)
					
					t.set_option = function(val)
						local set = (#val > 0 and find(options, val[1])) and val or {}
						for i,v in pairs(dropdown_inside:GetChildren()) do
							if v:IsA("TextLabel") then
								if find(set, v.Name) then
									v.Font = Enum.Font.SourceSansBold
									v.TextColor3 = Color3.fromRGB(143, 190, 55)
								else
									v.Font = Enum.Font.SourceSans
									v.TextColor3 = Color3.fromRGB(176.00000470876694, 176.00000470876694, 176.00000470876694);
								end
							end
						end
						local text = ""
						for i,v in pairs(set) do
							if text ~= "" then
								text = text..", "..v
							else
								text = v
							end
						end
						if text == "" then
							text = "..."
						end
						dropdown_label.Text = text
						lib.flags[f]["option"] = set
						pcall(c, lib.flags[f])
					end
					
					t.set_options = function(val)
						options = val
						dropdown_inside.Size = UDim2.new(dropdown_inside.Size.X.Scale, dropdown_inside.Size.X.Offset, dropdown_inside.Size.Y.Scale, 0)
						for i,v in pairs(dropdown_inside:GetChildren()) do
							if v:IsA("TextLabel") then
								v:Destroy()
							end
						end
						local old_options = lib.flags[f]["option"]
						lib.flags[f]["option"] = {}
						for i = 1, #val do
							dropdown_inside.Size = UDim2.new(dropdown_inside.Size.X.Scale, dropdown_inside.Size.X.Offset, dropdown_inside.Size.Y.Scale, dropdown_inside.Size.Y.Offset + 16)
							local dropdown_label_0 = Instance.new("TextLabel", dropdown_inside);
							dropdown_label_0.BackgroundColor3 = Color3.fromRGB(12.000001184642315, 12.000001184642315, 12.000001184642315);
							dropdown_label_0.BackgroundTransparency = 1;
							dropdown_label_0.BorderSizePixel = 0;
							dropdown_label_0.Name = val[i];
							dropdown_label_0.Position = UDim2.new(0.029999999329447746, 0, 0, 0);
							dropdown_label_0.Size = UDim2.new(1, 0, 0, 16);
							dropdown_label_0.Visible = true;
							dropdown_label_0.ZIndex = 9;
							dropdown_label_0.Font = Enum.Font.SourceSans;
							dropdown_label_0.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
							dropdown_label_0.Text = "  "..val[i]
							dropdown_label_0.TextColor3 = Color3.fromRGB(176.00000470876694, 176.00000470876694, 176.00000470876694);
							dropdown_label_0.TextSize = 14;
							dropdown_label_0.TextStrokeTransparency = 0.6000000238418579;
							dropdown_label_0.TextXAlignment = Enum.TextXAlignment.Left;
							
							dropdown_label_0.MouseEnter:Connect(function()
								if not find(lib.flags[f]["option"], val[i]) then
									dropdown_label_0.Font = Enum.Font.SourceSansBold
									dropdown_label_0.BackgroundTransparency = 0.5
									dropdown_label_0.TextColor3 = Color3.fromRGB(199, 199, 199)
								else
									dropdown_label_0.BackgroundTransparency = 0.5
								end
							end)
							
							dropdown_label_0.MouseLeave:Connect(function()
								if not find(lib.flags[f]["option"], val[i]) then
									dropdown_label_0.Font = Enum.Font.SourceSans
									dropdown_label_0.BackgroundTransparency = 1
									dropdown_label_0.TextColor3 = Color3.fromRGB(176.00000470876694, 176.00000470876694, 176.00000470876694)
								else
									dropdown_label_0.BackgroundTransparency = 1
								end
							end)
							
							dropdown_label_0.InputBegan:Connect(function(input)
								if input.UserInputType == Enum.UserInputType.MouseButton1 then
									if multi then
										if not find(lib.flags[f]["option"], val[i]) then
											local clone = lib.flags[f]["option"]
											table.insert(clone, val[i])
											t.set_option(clone)
										else
											local clone = lib.flags[f]["option"]
											table.remove(clone, find(clone, val[i]))
											t.set_option(clone)
										end
									else
										if not find(lib.flags[f]["option"], val[i]) then
											t.set_option({val[i]})
										else
											t.set_option({})
										end
									end
								end
							end)
						end
						for i = 1, #old_options do
							local option = old_options[i]
							local of = find(options, option)
							if not of then
								old_options[i] = nil
							end
						end
						t.set_option(multi and old_options or {old_options[1]})
					end
					
					for i = 1, #options do
						dropdown_inside.Size = UDim2.new(dropdown_inside.Size.X.Scale, dropdown_inside.Size.X.Offset, dropdown_inside.Size.Y.Scale, dropdown_inside.Size.Y.Offset + 16)
						local dropdown_label_0 = Instance.new("TextLabel", dropdown_inside);
						dropdown_label_0.BackgroundColor3 = Color3.fromRGB(12.000001184642315, 12.000001184642315, 12.000001184642315);
						dropdown_label_0.BackgroundTransparency = 1;
						dropdown_label_0.BorderSizePixel = 0;
						dropdown_label_0.Name = options[i];
						dropdown_label_0.Position = UDim2.new(0.029999999329447746, 0, 0, 0);
						dropdown_label_0.Size = UDim2.new(1, 0, 0, 16);
						dropdown_label_0.Visible = true;
						dropdown_label_0.ZIndex = 9;
						dropdown_label_0.Font = Enum.Font.SourceSans;
						dropdown_label_0.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
						dropdown_label_0.Text = "  "..options[i]
						dropdown_label_0.TextColor3 = Color3.fromRGB(176.00000470876694, 176.00000470876694, 176.00000470876694);
						dropdown_label_0.TextSize = 14;
						dropdown_label_0.TextStrokeTransparency = 0.6000000238418579;
						dropdown_label_0.TextXAlignment = Enum.TextXAlignment.Left;
						
						dropdown_label_0.MouseEnter:Connect(function()
							if not find(lib.flags[f]["option"], options[i]) then
								dropdown_label_0.Font = Enum.Font.SourceSansBold
								dropdown_label_0.BackgroundTransparency = 0.5
								dropdown_label_0.TextColor3 = Color3.fromRGB(199, 199, 199)
							else
								dropdown_label_0.BackgroundTransparency = 0.5
							end
						end)

						dropdown_label_0.MouseLeave:Connect(function()
							if not find(lib.flags[f]["option"], options[i]) then
								dropdown_label_0.Font = Enum.Font.SourceSans
								dropdown_label_0.BackgroundTransparency = 1
								dropdown_label_0.TextColor3 = Color3.fromRGB(176.00000470876694, 176.00000470876694, 176.00000470876694)
							else
								dropdown_label_0.BackgroundTransparency = 1
							end
						end)
						
						dropdown_label_0.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								if multi then
									if not find(lib.flags[f]["option"], options[i]) then
										local clone = lib.flags[f]["option"]
										table.insert(clone, options[i])
										t.set_option(clone)
									else
										local clone = lib.flags[f]["option"]
										table.remove(clone, find(clone, options[i]))
										t.set_option(clone)
									end
								else
									if not find(lib.flags[f]["option"], options[i]) then
										t.set_option({options[i]})
									else
										t.set_option({})
									end
								end
							end
						end)
					end
					
					t.set_option({})

					if def then
						t.set_option({options[1]})
					end
					
					lib.onConfigLoaded:Connect(function()
						t.set_option(lib.flags[f]["option"])
					end)
				elseif v == "textbox" then
					element.Size = UDim2.new(element.Size.X.Scale, element.Size.X.Offset, element.Size.Y.Scale, element.Size.Y.Offset + 26);
					section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset + 26);
					local def = args["tdefault"] or ""
                    local cb = args["noload"]
					lib.flags[f]["text"] = ""
					
					local textbox_background = Instance.new("Frame", element);
					textbox_background.BackgroundColor3 = Color3.fromRGB(52.000000700354576, 52.000000700354576, 52.000000700354576);
					textbox_background.BorderColor3 = Color3.fromRGB(11.000000294297934, 11.000000294297934, 11.000000294297934);
					textbox_background.Name = "textbox_background";
					textbox_background.Position = UDim2.new(0.10000000149011612, 0, 0, 18);
					textbox_background.Size = UDim2.new(0.800000011920929, 0, 0, 17);
					textbox_background.ZIndex = 3;

					local UIGradient = Instance.new("UIGradient", textbox_background);
					UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(182.00000435113907, 182.00000435113907, 182.00000435113907))};
					UIGradient.Rotation = 90;

					local textbox = Instance.new("TextBox", textbox_background);
					textbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
					textbox.BackgroundTransparency = 1;
					textbox.Name = "textbox";
					textbox.Size = UDim2.new(1, 0, 1, 0);
					textbox.ZIndex = 5;
					textbox.Font = Enum.Font.SourceSansBold;
					textbox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal);
					textbox.Text = ""
					textbox.TextColor3 = Color3.fromRGB(115.00000074505806, 115.00000074505806, 115.00000074505806);
					textbox.TextSize = 14;
					textbox.TextStrokeTransparency = 0.6000000238418579;
					textbox.TextWrapped = true
					textbox.ClearTextOnFocus = false
					
					t.set_text = function(val)
						textbox.Text = val
						lib.flags[f]["text"] = val
                        if not cb then
						    pcall(c, lib.flags[f])
                        end
					end
					
					textbox.FocusLost:Connect(function()
						t.set_text(textbox.Text)
					end)
					
					t.set_text(def)
					
					lib.onConfigLoaded:Connect(function()
						t.set_text(lib.flags[f]["text"])
					end)
				elseif v == "button" then
					for i,v in pairs(element:GetChildren()) do
						v:Destroy()
					end
					element.Size = UDim2.new(element.Size.X.Scale, element.Size.X.Offset, element.Size.Y.Scale, element.Size.Y.Offset + 16);
					section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset + 16);
					local button = Instance.new("Frame", element);
					button.BackgroundColor3 = Color3.fromRGB(49.000001177191734, 49.000001177191734, 49.000001177191734);
					button.BorderColor3 = Color3.fromRGB(11.000000294297934, 11.000000294297934, 11.000000294297934);
					button.Name = "button";
					button.Position = UDim2.new(0.10000000149011612, 0, 0, 2);
					button.Size = UDim2.new(0.800000011920929, 0, 0, 26);
					button.ZIndex = 3;

					local button = Instance.new("Frame", button);
					button.BackgroundColor3 = Color3.fromRGB(33.000001177191734, 33.000001177191734, 33.000001177191734);
					button.BorderSizePixel = 0
					button.Name = "button";
					button.Position = UDim2.new(0, 1, 0, 1);
					button.Size = UDim2.new(1, -2, 1, -2);
					button.ZIndex = 3;

					local UIGradient = Instance.new("UIGradient", button);
					UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(161, 161, 161))};
					UIGradient.Rotation = 270;

					local buttonlabel = Instance.new("TextLabel", button);
					buttonlabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
					buttonlabel.BackgroundTransparency = 1;
					buttonlabel.Name = "buttonlabel";
					buttonlabel.Size = UDim2.new(1, 0, 1, 0);
					buttonlabel.ZIndex = 6;
					buttonlabel.Font = Enum.Font.SourceSans;
					buttonlabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
					buttonlabel.Text = n;
					buttonlabel.TextColor3 = Color3.fromRGB(159.0000057220459, 159.0000057220459, 159.0000057220459);
					buttonlabel.TextSize = 15;
					buttonlabel.TextStrokeTransparency = 0.6000000238418579;
					
					buttonlabel.MouseEnter:Connect(function()
						button.BackgroundColor3 = Color3.fromRGB(54,54,54)
					end)
					
					buttonlabel.MouseLeave:Connect(function()
						button.BackgroundColor3 = Color3.fromRGB(33,33,33)
					end)
					
					buttonlabel.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 and not lib.stats.busy then
							button.BackgroundColor3 = Color3.fromRGB(22,22,22)
							task.spawn(c)
						end
					end)
					
					buttonlabel.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							button.BackgroundColor3 = Color3.fromRGB(33,33,33)
						end
					end)
				end
			end
			
			return t
		end
		
		return t
	end
	
	lib.changeScale = function(scale)
		outline.Size = UDim2.new(0, 610 * scale, 0, 520 * scale)
	end
	
	lib.util.changeTab("rage", rage_tab)
	
	services.UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == lib.stats.key then
			holder.Enabled = not holder.Enabled
		end
	end)
	
	return l
end

-- * Client

local client = {}
client.plr = services.Players.LocalPlayer; client.mouse = client.plr:GetMouse()
client.character = function() return client.plr.Character or client.plr.CharacterAdded:Wait() end
client.loaded = function()
    local parts = {"Head","HumanoidRootPart","Humanoid"}
    for i,v in pairs(parts) do
        if client.character():FindFirstChild(v) then
        else
            return false
        end
    end
    return true
end

client.return_time = game.Lighting.ClockTime
client.return_ambient = game.Lighting.Ambient
client.return_fov = workspace.CurrentCamera.FieldOfView
client.return_fog = game.Lighting.FogColor
client.return_fogstart = game.Lighting.FogStart
client.return_fogend = game.Lighting.FogEnd
client.tp_location = CFrame.new()
client.teleporting = false

-- * Menu setup

local menu;

local function getConfigList()
    local cfgs = listfiles("Ratio/Configs/")
    local returnTable = {}
    for _, file in pairs(cfgs) do
        local str = tostring(file)
        if string.sub(str, #str-3, #str) == ".cfg" then
            table.insert(returnTable, string.sub(str, 15, #str-4))
        end
    end
    return returnTable
end

local api = {}

local scripts = {}

api.add_connection = function(src, connection, callback)
	table.insert(scripts[src].connections, connection:Connect(callback))
end

api.create_section = function(scr, tab, name)
	local section = menu.create_section(tab, name)
	table.insert(scripts[scr].sections, section)
	return section
end

api.indicators = lib.indicators

api.flags = function() return lib.flags end

local function createScriptEnv(scr)
	scripts[scr] = {}
	scripts[scr].elements = {}
	scripts[scr].sections = {}
	scripts[scr].connections = {}
	scripts[scr].c = nil
	return a
end

local function unloadScript(scr)
	if scripts[scr] and isfile("Ratio/Scripts/"..scr..".lua") then
		local env = scripts[scr]
		for i,v in pairs(env.elements) do
			v:destroy()
		end
		for i,v in pairs(env.sections) do
			v:destroy()
		end
		for i,v in pairs(env.connections) do
			v:Disconnect()
		end
		coroutine.close(scripts[scr].c)
		scripts[scr] = nil
	end
end

local function loadScript(scr)
	if not scripts[scr] and isfile("Ratio/Scripts/"..scr..".lua") then
		local script2 = readfile("Ratio/Scripts/"..scr..".lua")
		local env = createScriptEnv(scr)
		local exec = string.gsub(script2, "create_section%(", "create_section(".."\""..scr.."\""..", ")
		local exec = string.gsub(exec, "add_connection%(", "add_connection(".."\""..scr.."\""..", ")
		local s = coroutine.create(loadstring(exec))
		coroutine.resume(s)
		scripts[scr].c = s
	end
end

local function getScriptList()
    local scripts = listfiles("Ratio/Scripts/")
    local returnTable = {}
    for _, file in pairs(scripts) do
        local str = tostring(file)
        if string.sub(str, #str-3, #str) == ".lua" then
            table.insert(returnTable, string.sub(str, 15, #str-4))
        end
    end
    return returnTable
end

local function getPlayerList()
	local players = services.Players:GetPlayers()
	local player_names = {}
	for i = 1, #players do
		local player = players[i]
		if player ~= client.plr then
			table.insert(player_names, tostring(player))
		end
	end
	return player_names
end

-- * HUD options

local keybinds_list = {}

function lib:tween(...) 
    services.TweenService:Create(...):Play()
end

do
	local hud = Instance.new("ScreenGui");
	hud.Name = "hud";
	hud.ZIndexBehavior = Enum.ZIndexBehavior.Global;

	if gethui then 
		hud.Parent = gethui() 
	elseif syn and syn.protect_gui then 
		syn.protect_gui(hud)
		hud.Parent = game.CoreGui
	end

	hud.Enabled = false

	local keybind_list = Instance.new("Frame", hud);
	keybind_list.BackgroundColor3 = Color3.fromRGB(175,0,0);
	keybind_list.Name = "keybind_list";
	keybind_list.Position = UDim2.new(0, 500, 0, 500);
	keybind_list.Size = UDim2.new(0, 150, 0, 22);

	keybinds_list.main = keybind_list
	
	lib:setDraggable(keybind_list, keybind_list)

	local UIGradient = Instance.new("UIGradient", keybind_list);
	UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(245,245,245)), ColorSequenceKeypoint.new(0.25, Color3.fromRGB(125,125,125)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(125,125,125)), ColorSequenceKeypoint.new(0.75, Color3.fromRGB(125,125,125)), ColorSequenceKeypoint.new(1, Color3.fromRGB(245,245,245))};

	local keybind_image = Instance.new("ImageLabel", keybind_list);
	keybind_image.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	keybind_image.BackgroundTransparency = 1;
	keybind_image.Name = "keybind_image";
	keybind_image.Position = UDim2.new(0, 5, 0.5, -11);
	keybind_image.Size = UDim2.new(0, 22, 0, 22);
	keybind_image.ZIndex = 2;
	keybind_image.Image = "http://www.roblox.com/asset/?id=12331814109";
	keybind_image.ImageColor3 = Color3.fromRGB(170.0000050663948, 0, 0);

	local keybind_inside = Instance.new("Frame", keybind_list);
	keybind_inside.BackgroundColor3 = Color3.fromRGB(12.000000234693289, 12.000000234693289, 12.000000234693289);
	keybind_inside.BorderSizePixel = 0;
	keybind_inside.Name = "keybind_inside";
	keybind_inside.Position = UDim2.new(0, 1, 0, 1);
	keybind_inside.Size = UDim2.new(1, -2, 1, -2);

	local keybind_label = Instance.new("TextLabel", keybind_inside);
	keybind_label.BackgroundColor3 = Color3.fromRGB(12.000000234693289, 12.000000234693289, 12.000000234693289);
	keybind_label.BorderSizePixel = 0;
	keybind_label.Name = "keybind_label";
	keybind_label.Position = UDim2.new(0, 1, 0, 1);
	keybind_label.Size = UDim2.new(1, -32, 1, -2);
	keybind_label.Font = Enum.Font.SourceSansBold;
	keybind_label.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal);
	keybind_label.Text = "Keybinds";
	keybind_label.TextColor3 = Color3.fromRGB(170.0000050663948, 0, 0);
	keybind_label.TextSize = 16;
	keybind_label.TextStrokeTransparency = 0.5;

	local UICorner = Instance.new("UICorner", keybind_inside);
	UICorner.CornerRadius = UDim.new(0.18000000715255737, 0);

	local keybind_holder = Instance.new("Frame", keybind_list);
	keybind_holder.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	keybind_holder.BackgroundTransparency = 1;
	keybind_holder.Name = "keybind_holder";
	keybind_holder.Position = UDim2.new(0, 0, 1, 2);
	keybind_holder.Size = UDim2.new(1, 0, 0, 100);

	local UIListLayout = Instance.new("UIListLayout", keybind_holder);
	UIListLayout.Padding = UDim.new(0, 1);
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder;

	local UICorner_0 = Instance.new("UICorner", keybind_list);
	UICorner_0.CornerRadius = UDim.new(0.18000000715255737, 0);

	function keybinds_list:set_visible(bool)
		hud.Enabled = bool
	end

	function keybinds_list:set_color(color)
		keybind_label.TextColor3 = color
		keybind_image.ImageColor3 = color
		keybind_list.BackgroundColor3 = color
	end

	function keybinds_list:add_keybind(name)
		local keybind = {}

		local name_label = Instance.new("TextLabel", keybind_holder);
		name_label.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
		name_label.BackgroundTransparency = 1;
		name_label.Name = "name_label";
		name_label.Size = UDim2.new(1, 0, 0, 16);
		name_label.Font = Enum.Font.SourceSans;
		name_label.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
		name_label.Text = name;
		name_label.TextColor3 = Color3.fromRGB(255, 255, 255);
		name_label.TextSize = 15;
		name_label.TextXAlignment = Enum.TextXAlignment.Left;
		name_label.Visible = false
		name_label.TextTransparency = 1

		local method_label = Instance.new("TextLabel", name_label);
		method_label.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
		method_label.BackgroundTransparency = 1;
		method_label.Name = "method_label";
		method_label.Size = UDim2.new(1, 0, 0, 16);
		method_label.Font = Enum.Font.SourceSans;
		method_label.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
		method_label.Text = "";
		method_label.TextColor3 = Color3.fromRGB(255, 255, 255);
		method_label.TextSize = 15;
		method_label.TextXAlignment = Enum.TextXAlignment.Right;
		method_label.Visible = false
		method_label.TextTransparency = 1

		function keybind:set_visible(bool)
			if bool then
				name_label.Visible = true
				method_label.Visible = true
				lib:tween(name_label, TweenInfo.new(1/name_label.TextTransparency/25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {TextTransparency = 0})
				lib:tween(method_label, TweenInfo.new(1/method_label.TextTransparency/25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {TextTransparency = 0})
			elseif not bool and name_label.Visible then
				lib:tween(name_label, TweenInfo.new(1/name_label.TextTransparency/25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {TextTransparency = 1})
				lib:tween(method_label, TweenInfo.new(1/method_label.TextTransparency/25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {TextTransparency = 1})
			end
			if name_label.TextTransparency > 0.98 then
				name_label.Visible = false
				method_label.Visible = false
			end
		end

		function keybind:set_key(text)
			method_label.Text = "["..text.."]"
		end

		return keybind
	end
end

local function update_gun(t)
	local arms = workspace.CurrentCamera:FindFirstChild("Arms")
	if arms then
		local real_arms = arms:FindFirstChildOfClass("Model")
		local arms_children = arms:GetChildren()
		for i = 1, #arms_children do
			local part = arms_children[i]
			if (part.ClassName == "Part" or part.ClassName == "MeshPart") and part.Transparency == 0 then
				part.Material = t and Enum.Material.ForceField or Enum.Material.Plastic
				part.Color = t and lib.flags["forcefield_gun"].Color or Color3.fromRGB(163, 162, 165)
			end
		end
	end
end

-- * Menu

menu = lib.init()

local menu_autoload

lib.flags["autoloaders"] = {}

lib.flags["kb_pos"] = {0, 500, 0, 500}

local fc_keybind = keybinds_list:add_keybind("Freeze character")
local s_keybind = keybinds_list:add_keybind("CFrame speed")
local fw_keybind = keybinds_list:add_keybind("Freeze world")
local ps_keybind = keybinds_list:add_keybind("Ping spike")
local aa_keybind = keybinds_list:add_keybind("Aim assist")
local t_keybind = keybinds_list:add_keybind("Triggerbot")
local fl_keybind = keybinds_list:add_keybind("Fake lag")
local n_keybind = keybinds_list:add_keybind("Noclip")
local f_keybind = keybinds_list:add_keybind("Fly")

local menu_aimassist = menu.create_section("rage", "Aim assist")
	local aim_assist = menu_aimassist.create_element({name = "Enabled", types = {"toggle", "keybind"}, kdefault = {["key"] = "Z", ["active"] = false, ["method"] = "hold"}, flag = "aim_assist", callback = function()
	end});
	local aim_part = menu_aimassist.create_element({name = "Part", types = {"dropdown"}, options = {"Head", "HumanoidRootPart"}, flag = "aim_part", callback = function()
	end})
	local team_check2 = menu_aimassist.create_element({name = "Team check", types = {"toggle"}, flag = "team_check2", callback = function()
	end})
	local flash_check = menu_aimassist.create_element({name = "Flash check", types = {"toggle"}, flag = "flash_check", callback = function()
	end})
	local visible_check = menu_aimassist.create_element({name = "Visible check", types = {"toggle"}, flag = "visible_check", callback = function()
	end})
	local field_of_view = menu_aimassist.create_element({name = "Field of view", types = {"slider"}, min = 1, max = 500, sdefault = 50, flag = "field_of_view", callback = function()
	end})
	local horizontal_smoothing = menu_aimassist.create_element({name = "Horizontal smoothing", types = {"slider"}, min = 1, max = 30, sdefault = 15, suffix = "%", flag = "horizontal_smoothing", callback = function()
	end})
	local vertical_smoothing = menu_aimassist.create_element({name = "Vertical smoothing", types = {"slider"}, min = 1, max = 30, sdefault = 15, suffix = "%", flag = "vertical_smoothing", callback = function()
	end})
	local deadzone = menu_aimassist.create_element({name = "Deadzone", types = {"slider"}, min = 1, max = 100, sdefault = 15, suffix = "%", flag = "deadzone", callback = function()
	end})

local menu_assistcircle = menu.create_section("rage", "Assist circle")
	local fov_circle = menu_assistcircle.create_element({name = "FoV circle", types = {"colorpicker", "dropdown"}, options = {"Filled"}, ddefault = false, cdefault = Color3.fromRGB(24,24,24), flag = "fov_circle", callback = function()
	end})
	local deadzone_circle = menu_assistcircle.create_element({name = "Deadzone circle", types = {"colorpicker", "dropdown"}, options = {"Filled"}, ddefault = true, cdefault = Color3.fromRGB(155,155,155), flag = "deadzone_circle", callback = function()
	end})

local menu_triggerbot = menu.create_section("rage", "Triggerbot")
	local triggerbot = menu_triggerbot.create_element({name = "Enabled", types = {"toggle", "slider", "keybind"}, min = 1, max = 285, sdefault = 80, suffix = "ms", kdefault = {["key"] = "L", ["active"] = false, ["method"] = "hold"}, flag = "triggerbot", callback = function()
	end})
	local flash_check2 = menu_triggerbot.create_element({name = "Flash check", types = {"toggle"}, flag = "flash_check2", callback = function()
	end})
	local menu_hitboxes = menu_triggerbot.create_element({name = "Hitboxes", types = {"dropdown"}, options = {"Head", "Torso", "Legs", "Arms"}, multi = true, flag = "hitboxes", callback = function()
	end})

local menu_character = menu.create_section("aa", "Character")
	local quickstop = menu_character.create_element({name = "Quick stop", types = {"toggle"}, flag = "quickstop", callback = function()
	end})

local menu_client = menu.create_section("aa", "Client")
	local freeze_character = menu_client.create_element({name = "Freeze character", types = {"toggle", "colorpicker", "keybind"}, cdefault = Color3.fromRGB(255, 89, 89), kdefault = {["key"] = "F", ["active"] = false, ["method"] = "hold"}, flag = "freeze_character", callback = function()
	end})
	local no_fall = menu_client.create_element({name = "No fall damage", types = {"toggle"}, flag = "no_fall", callback = function()
	end})
	local freeze_world = menu_client.create_element({name = "Freeze world", types = {"toggle", "keybind"}, kdefault = {["key"] = "M", ["active"] = false, ["method"] = "hold"}, flag = "freeze_world", callback = function()
	end})
	local ping_spike = menu_client.create_element({name = "Ping spike", types = {"toggle", "keybind", "slider"}, flag = "ping_spike", min = 80, max = 99, sdefault = 85, kdefault = {["key"] = "X", ["active"] = false, ["method"] = "toggle"}, callback = function()
	end})
	local ping_spoof = menu_client.create_element({name = "Ping spoof", types = {"toggle", "slider"}, flag = "ping_spoof", min = 1, max = 1000, sdefault = 85, callback = function()
	end})

local menu_fakelag = menu.create_section("aa", "Fake lag")
	local fake_lag = menu_fakelag.create_element({name = "Enabled", types = {"toggle", "colorpicker", "keybind"}, cdefault = Color3.fromRGB(255, 89, 89), kdefault = {["key"] = "H", ["active"] = false, ["method"] = "hold"}, flag = "fake_lag", callback = function()
	end})
	local character_lag = menu_fakelag.create_element({name = "Character lag", types = {"toggle", "slider"}, min = 90, max = 1000, sdefault = 90, suffix = "ms", flag = "character_lag", callback = function()
	end})
	local cancel_anims = menu_fakelag.create_element({name = "Cancel animations", types = {"toggle", "slider"}, min = 1, max = 100, sdefault = 2, suffix = "%", flag = "cancel_anims", callback = function()
	end})

local menu_camera = menu.create_section("visuals", "Camera")
	local camera_fov = menu_camera.create_element({name = "Field of view", types = {"toggle", "slider"}, sdefault = client.current_fov, min = 70, max = 120, flag = "fov", callback = function()
		if not lib.flags["fov"]["toggle"] then
			task.wait()
			workspace.CurrentCamera.FieldOfView = client.return_fov
		end
	end})
	local forcefield_gun = menu_camera.create_element({name = "Forcefield gun", types = {"toggle", "colorpicker"}, cdefault = Color3.fromRGB(163, 162, 165), flag = "forcefield_gun", callback = function()
		if not lib.flags["forcefield_gun"]["toggle"] then
			task.wait()
			update_gun(false)
		end
	end})
	local custom_viewmodel = menu_camera.create_element({name = "Custom viewmodel", types = {"toggle"}, min = 1, max = 20, flag = "viewmodel", callback = function()
	end})
	local custom_viewmodelx = menu_camera.create_element({name = "Viewmodel (X)", types = {"slider"}, min = 1, max = 20, flag = "viewmodel_x", callback = function()
	end})
	local custom_viewmodely = menu_camera.create_element({name = "Viewmodel (Y)", types = {"slider"}, min = 1, max = 20, flag = "viewmodel_y", callback = function()
	end})
	local custom_viewmodelz = menu_camera.create_element({name = "Viewmodel (Z)", types = {"slider"}, min = 1, max = 20, flag = "viewmodel_z", callback = function()
	end})

local menu_world = menu.create_section("visuals", "World")
	local dropped_weapons = menu_world.create_element({name = "Dropped weapons", types = {"toggle", "colorpicker", "slider"}, sdefault = 14, min = 12, max = 20, suffix = "px", cdefault = Color3.fromRGB(255,255,255), flag = "dropped_weapons", callback = function()
	end})
	local dropped_bomb = menu_world.create_element({name = "Dropped bomb", types = {"toggle", "colorpicker", "slider"}, sdefault = 14, min = 12, max = 20, suffix = "px", cdefault = Color3.fromRGB(255,255,255), flag = "dropped_bomb", callback = function()
	end})
	local world_time = menu_world.create_element({name = "World time", types = {"toggle", "slider"}, sdefault = 0, min = 0, max = 24, flag = "world_time", callback = function()
		if not lib.flags["world_time"]["toggle"] then
			task.wait()
			game.Lighting.ClockTime = client.return_time
		end
	end})
	local removals = menu_world.create_element({name = "Removals", types = {"dropdown"}, options = {"Smokes", "Flash", "Shadows"}, multi = true, flag = "removals", callback = function()
	end})
	local ambient = menu_world.create_element({name = "Ambient", types = {"toggle", "colorpicker"}, cdefault = client.return_ambient, flag = "ambient", callback = function()
		if not lib.flags["ambient"]["toggle"] then
			task.wait()
			game.Lighting.Ambient = client.return_ambient
		end
	end})
	local fog = menu_world.create_element({name = "Fog", types = {"toggle", "colorpicker"}, cdefault = client.return_fog, flag = "fog", callback = function()
		if not lib.flags["fog"]["toggle"] then
			task.wait()
			game.Lighting.FogColor = client.return_fog
			game.Lighting.FogStart = client.return_fogstart
			game.Lighting.FogEnd = client.return_fogend
		end
	end})
	local fog_start = menu_world.create_element({name = "Fog start", types = {"slider"}, min = 1, max = 7500, sdefault = client.return_fogstart, flag = "fog_start", callback = function()
	end})
	local fog_end = menu_world.create_element({name = "Fog end", types = {"slider"}, min = 1, max = 7500, sdefault = client.return_fogend, flag = "fog_end", callback = function()
	end})
	
local menu_pesp = menu.create_section("players", "Player esp")
	local playeresp = menu_pesp.create_element({name = "Enabled", types = {"toggle"}, flag = "pesp", callback = function()
	end})
	local team_check = menu_pesp.create_element({name = "Team check", types = {"toggle"}, flag = "team_check", callback = function()
	end})
	local box = menu_pesp.create_element({name = "Box", types = {"toggle", "colorpicker"}, cdefault = Color3.fromRGB(255,255,255), flag = "box", callback = function()
	end})
	local fill = menu_pesp.create_element({name = "Fill", types = {"toggle", "colorpicker"}, cdefault = Color3.fromRGB(255,255,255), flag = "fill", callback = function()
	end})
	local name = menu_pesp.create_element({name = "Name", types = {"toggle", "colorpicker", "slider"}, sdefault = 14, min = 12, max = 20, suffix = "px", cdefault = Color3.fromRGB(255,255,255), flag = "name", callback = function()
	end})
	local weapon = menu_pesp.create_element({name = "Weapon", types = {"toggle", "colorpicker", "slider"}, sdefault = 13, min = 12, max = 20, suffix = "px", cdefault = Color3.fromRGB(255,0,0), flag = "weapon", callback = function()
	end})
	local zoom = menu_pesp.create_element({name = "Zoom", types = {"toggle", "colorpicker", "slider"}, sdefault = 12, min = 10, max = 20, suffix = "px", cdefault = Color3.fromRGB(255,255,255), flag = "zoom", callback = function()
	end})
	local bomb = menu_pesp.create_element({name = "Bomb", types = {"toggle", "colorpicker", "slider"}, sdefault = 12, min = 10, max = 20, suffix = "px", cdefault = Color3.fromRGB(255,0,0), flag = "bomb", callback = function()
	end})
	local distance = menu_pesp.create_element({name = "Distance", types = {"toggle", "colorpicker", "slider"}, sdefault = 12, min = 10, max = 20, suffix = "px", cdefault = Color3.fromRGB(255,0,0), flag = "distance", callback = function()
	end})
	local health = menu_pesp.create_element({name = "Health", types = {"toggle", "colorpicker", "dropdown"}, multi = true, options = {"Health based color", "Health number"}, cdefault = Color3.fromRGB(0,255,0), flag = "health", callback = function()
	end})
	local chams = menu_pesp.create_element({name = "Chams", types = {"toggle", "colorpicker"}, cdefault = Color3.fromRGB(255,255,255), flag = "chams", callback = function()
	end})
	local outline = menu_pesp.create_element({name = "Outline", types = {"colorpicker"}, cdefault = Color3.fromRGB(255,255,255), flag = "outline", callback = function()
	end})
	local tracers = menu_pesp.create_element({name = "Tracers", types = {"toggle", "colorpicker", "dropdown"}, options = {"Mouse", "Torso"}, ddefault = true, cdefault = Color3.fromRGB(255,0,0), flag = "tracers", callback = function()
	end})
	local max_distance = menu_pesp.create_element({name = "Max distance", types = {"slider"}, sdefault = 2500, min = 100, max = 7500, suffix = "m", flag = "max_distance", callback = function()
	end})
	local font = menu_pesp.create_element({name = "Font", types = {"dropdown"}, options = {"Plex", "System", "Monospace"}, ddefault = true, flag = "font", callback = function()
	end})

local menu_playersother = menu.create_section("lua", "Player options")
	local selected_player = menu_playersother.create_element({name = "Player", types = {"dropdown"}, options = getPlayerList(), flag = "selected_player", callback = function()
	end})

local menu_offscreenesp = menu.create_section("players", "Offscreen esp")
local offscreen = menu_offscreenesp.create_element({name = "Offscreen arrow", types = {"toggle", "colorpicker", "slider"}, sdefault = 100, min = 10, max = 250, suffix = "px", cdefault = Color3.fromRGB(255,255,255), flag = "offscreen", callback = function()
	end})
	local offscreen_distance = menu_offscreenesp.create_element({name = "Arrow distance", types = {"slider"}, sdefault = 400, min = 100, max = 900, cdefault = Color3.fromRGB(255,255,255), flag = "offscreen_distance", callback = function()
	end})
	local show_name = menu_offscreenesp.create_element({name = "Show name", types = {"toggle"}, flag = "show_name", callback = function()
	end})

local menu_configs = menu.create_section("settings", "Configs")
    local menu_cfg = menu_configs.create_element({name = "Config list", types = {"dropdown"}, flag = "cfg", ddefault = false, options = getConfigList(), callback = function(f)
    end})
    local menu_savecfg = menu_configs.create_element({name = "Save config", types = {"button"}, flag = "", callback = function(f)
        if lib.flags["cfg"]["option"][1] then
			lib.flags["kb_pos"] = {0, keybinds_list.main.Position.X.Offset, 0, keybinds_list.main.Position.Y.Offset}
            lib.saveConfig(lib.flags["cfg"]["option"][1])
        end
    end})
    local menu_loadcfg = menu_configs.create_element({name = "Load config", types = {"button"}, flag = "", callback = function(f)
        if lib.flags["cfg"]["option"][1] then
            lib.loadConfig(lib.flags["cfg"]["option"][1])
			keybinds_list.main.Position = UDim2.new(unpack(lib.flags["kb_pos"]))
			task.spawn(function()
				task.wait(0.05)
				for i,v in pairs(lib.flags["autoloaders"]) do
					loadScript(v)
				end
			end)
			if find(lib.flags["autoloaders"], lib.flags["script"]["option"][1]) then
				menu_autoload.set_toggle(false, false)
				table.remove(lib.flags["autoloaders"], find(lib.flags["autoloaders"], lib.flags["script"]["option"][1]))
			else
				menu_autoload.set_toggle(true, false)
				table.insert(lib.flags["autoloaders"], lib.flags["script"]["option"][1])
			end
        end
    end})
    local menu_loadcfg = menu_configs.create_element({name = "Refresh list", types = {"button"}, flag = "", callback = function(f)
        menu_cfg.set_options(getConfigList())
    end})
    local menu_cfgn = menu_configs.create_element({name = "Config name", types = {"textbox"}, flag = "cfgname", noload = true, ddefault = false, callback = function(f)
    end})
    local menu_savecfg = menu_configs.create_element({name = "Create config", types = {"button"}, flag = "", callback = function(f)
        lib.saveConfig(lib.flags["cfgname"]["text"])
        menu_cfg.set_options(getConfigList())
    end})

local menu_section = menu.create_section("settings", "Menu")
    local menu_key = menu_section.create_element({name = "Menu key", types = {"keybind"}, flag = "menukey", kdefault = {["key"] = "LeftAlt", ["method"] = "toggle", ["active"] = false}, callback = function(f)
        lib.stats.key = Enum.KeyCode[f["bind"]["key"]]
    end})

local menu_other = menu.create_section("settings", "Other")
	local menu_indicators = menu_other.create_element({name = "Indicators", types = {"toggle", "dropdown"}, options = {"Center", "Bottom"}, ddefault = true, flag = "indicators", callback = function(f)
		lib.indicators:set_visible(lib.flags["indicators"]["toggle"])
		lib.indicators:set_alignment(lib.flags["indicators"]["option"][1] and lib.flags["indicators"]["option"][1] or "Center")
	end})
	local menu_keybinds = menu_other.create_element({name = "Keybinds list", types = {"toggle", "colorpicker"}, cdefault = Color3.fromRGB(143, 190, 55), flag = "keybinds", callback = function(f)
		keybinds_list:set_visible(lib.flags["keybinds"]["toggle"])
		keybinds_list:set_color(lib.flags["keybinds"].Color)
	end})

local menu_scripting = menu.create_section("lua", "Scripting")
	local menu_script = menu_scripting.create_element({name = "Script list", types = {"dropdown"}, flag = "script", ddefault = false, options = getScriptList(), callback = function(f)
		if find(lib.flags["autoloaders"], lib.flags["script"]["option"][1]) then
			menu_autoload.set_toggle(true, false)
		else
			menu_autoload.set_toggle(false, false)
		end
	end})
	menu_autoload = menu_scripting.create_element({name = "Auto load", types = {"toggle"}, flag = "autoload", callback = function(f)
		if find(lib.flags["autoloaders"], lib.flags["script"]["option"][1]) then
			menu_autoload.set_toggle(false, false)
			table.remove(lib.flags["autoloaders"], find(lib.flags["autoloaders"], lib.flags["script"]["option"][1]))
		else
			menu_autoload.set_toggle(true, false)
			table.insert(lib.flags["autoloaders"], lib.flags["script"]["option"][1])
		end
    end})
	local menu_unloadscript = menu_scripting.create_element({name = "Unload script", types = {"button"}, flag = "", callback = function(f)
		if lib.flags["script"]["option"][1] then
			unloadScript(lib.flags["script"]["option"][1])
		end
	end})
	local menu_loadscript = menu_scripting.create_element({name = "Load script", types = {"button"}, flag = "", callback = function(f)
		if lib.flags["script"]["option"][1] then
			loadScript(lib.flags["script"]["option"][1])
		end
	end})
	local menu_refreshlist = menu_scripting.create_element({name = "Refresh list", types = {"button"}, flag = "", callback = function(f)
		menu_script.set_options(getScriptList())
	end})

-- * Metamethods

LPH_JIT_MAX(function()
	local old_namecall = nil
	old_namecall = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
		if checkcaller() and method == "GetService" and args[1] == "Ratio" then
			return api
		elseif not checkcaller() and method == "FireServer" and tostring(self) == "UpdatePing" then
			if lib.flags["ping_spoof"]["toggle"] then
				local num = lib.flags["ping_spoof"]["value"]/1000 + math.random(lib.flags["ping_spoof"]["value"]/8, lib.flags["ping_spoof"]["value"]/4.5)/1000
				args[1] = num
				return old_namecall(self, unpack(args))
			end
		elseif not checkcaller() and method == "FireServer" and tostring(self) == "FallDamage" then
			if lib.flags["no_fall"]["toggle"] then
				return
			end
		elseif method == "SetPrimaryPartCFrame" and tostring(self) == "Arms" and lib.flags["viewmodel"]["toggle"] then 
			args[1] = args[1] * CFrame.new((lib.flags["viewmodel_x"]["value"]-5)/5, (lib.flags["viewmodel_y"]["value"]-5)/5, (lib.flags["viewmodel_z"]["value"]-5)/5)
			return old_namecall(self, unpack(args))
		end
		return old_namecall(self, ...)
	end)
end)()

-- * Indicators

local fake = lib.indicators:add_indicator("FAKE")
local ps = lib.indicators:add_indicator("PING")
local fly2 = lib.indicators:add_indicator("FLY")
local fw = lib.indicators:add_indicator("FW")

-- * Core

local core = {connections = {}, last_fake_cf = CFrame.new(), lagging = false, lag_cooldown = false, trigger_delay = false}
local r6_parts = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
local r15_parts = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}

function core:add_connection(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(core.connections, connection)
	return connection
end

core.fake = game:GetObjects("rbxassetid://8318476657")[1]
core.fake.Parent = game.CoreGui

for _, part in pairs(core.fake:GetChildren()) do
	if not part:IsA("Humanoid") then
		local decal = part:FindFirstChildOfClass("Decal")
		if decal then decal:Destroy() end
		if part.Name == "Head" then part:GetChildren()[1]:Destroy() end
		part.CanCollide = false
		part.Material = Enum.Material.Neon
		part.Anchored = true
		if part.Name == "HumanoidRootPart" then part:Destroy() end
	else
		part:Destroy()
	end
end

-- * Drawing

local Drawing2D = {}

function Drawing2D:new(type, properties)
	local new_drawing = Drawing.new(type)

	for prop, val in pairs(properties) do
		if prop == "Outline" and type ~= "Text" then
			new_drawing.Color = Color3.fromRGB(0,0,0)
			continue
		end
		new_drawing[prop] = val
	end

	new_drawing.Visible = false

	return new_drawing
end

-- * ESP

local esp = {tables = {}}
function esp:create_table(player)
	local esp_table = {}

	esp_table.tracer = Drawing2D:new("Line", {
		ZIndex = 1,
		Thickness = 1
	})
	esp_table.box = Drawing2D:new("Square", {
		ZIndex = 2,
		Thickness = 1,
		Filled = false
	})
	esp_table.fill = Drawing2D:new("Square", {
		ZIndex = 1,
		Thickness = 1,
		Filled = true
	})
	esp_table.outline = Drawing2D:new("Square", {
		ZIndex = 1,
		Thickness = 3,
		Filled = false
	})
	esp_table.name = Drawing2D:new("Text", {
		ZIndex = 4,
		Center = true,
		Outline = true
	})
	esp_table.healthoutline = Drawing2D:new("Line", {
		ZIndex = 1,
		Thickness = 3,
		Outline = true
	})
	esp_table.healthbar = Drawing2D:new("Line", {
		ZIndex = 3,
		Thickness = 1,
	})
	esp_table.distance = Drawing2D:new("Text", {
		ZIndex = 4,
		Center = true,
		Outline = true
	})
	esp_table.weapon = Drawing2D:new("Text", {
		ZIndex = 4,
		Center = true,
		Outline = true
	})
	esp_table.zoom = Drawing2D:new("Text", {
		ZIndex = 4,
		Center = true,
		Outline = true
	})
	esp_table.bomb = Drawing2D:new("Text", {
		ZIndex = 4,
		Center = true,
		Outline = true
	})
	esp_table.health = Drawing2D:new("Text", {
		ZIndex = 5,
		Center = true,
		Outline = true,
		Font = Drawing.Fonts.Plex,
		Size = 10
	})
	esp_table.triangle = Drawing2D:new("Triangle", {
		Thickness = 1,
		ZIndex = 3,
		Filled = true
	})
	return esp_table
end

function esp:remove_esp(player)
	local esp_table = esp.tables[player.Name]
	for i,v in pairs(esp_table.drawings) do
		v:Remove()
	end
	esp_table.highlight:Destroy()
end

function esp:add_esp(player)
	local esp_table = {drawings = esp:create_table(player), highlight = nil}

	esp_table.highlight = Instance.new("Highlight")
	esp_table.highlight.Parent = game.CoreGui
	esp_table.highlight.Enabled = false
	esp_table.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	esp_table.highlight.Name = player.Name

	esp.tables[player.Name] = esp_table
end

local dropped_weapons = {}
local dw_drawings = {}

LPH_JIT_MAX(function()

local drawing_bomb = Drawing2D:new("Text", {
	ZIndex = 2,
	Center = true,
	Outline = true
})

esp.connection = services.RunService:BindToRenderStep("esp", Enum.RenderPriority.Camera.Value + 1, function()
	for i, v in pairs(dw_drawings) do
		local gun = v[1]
		local text = v[2]
		
		if gun and text and gun.Parent == workspace.Debris and lib.flags["dropped_weapons"]["toggle"] then
			text.Visible = false
			local pos, visible = workspace.CurrentCamera:WorldToViewportPoint(gun.Mag.Position)

			if visible then
				text.Text = tostring(gun)
				text.Size = lib.flags["dropped_weapons"]["value"]
				text.Color = lib.flags["dropped_weapons"].Color
				text.Transparency = -lib.flags["dropped_weapons"].Transparency+1
				text.Position = Vector2.new(pos.X, pos.Y)
				text.Visible = true
			end
		else
			if gun then table.remove(dropped_weapons, find(dropped_weapons, gun)) end
			table.remove(dw_drawings, find(dw_drawings, v))
			if text then text:Remove() end
		end
	end

	drawing_bomb.Visible = false

	if lib.flags["dropped_bomb"]["toggle"] and workspace.Debris:FindFirstChild("C4") then
		local c4 = workspace.Debris.C4
		local pos, visible = workspace.CurrentCamera:WorldToViewportPoint(c4.Position)
		if visible then
			drawing_bomb.Text = "BOMB"
			drawing_bomb.Size = lib.flags["dropped_bomb"]["value"]
			drawing_bomb.Color = lib.flags["dropped_bomb"].Color
			drawing_bomb.Transparency = -lib.flags["dropped_bomb"].Transparency+1
			drawing_bomb.Position = Vector2.new(pos.X, pos.Y)
			drawing_bomb.Visible = true
		end
	end

	for i, player in next, services.Players:GetPlayers() do
		local esp_table = esp.tables[player.Name]

		if not esp_table then
			continue
		end

		for i,v in pairs(esp_table.drawings) do
			v.Visible = false
		end

		esp_table.highlight.Enabled = false

		if not lib.flags["pesp"]["toggle"] then
			continue
		end

		local team_check = false
		if lib.flags["team_check"]["toggle"] then 
			team_check = player.Team ~= client.plr.Team 
		else 
			team_check = true
		end
		
		local health_number = false
		local health_color = false
		
		if find(lib.flags["health"]["option"], "Health based color") then
			health_color = true
		end

		if find(lib.flags["health"]["option"], "Health number") then
			health_number = true
		end

		if player.Character and team_check then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			local hum = player.Character:FindFirstChildOfClass("Humanoid")
			if hrp and hum then
				local pos, visible = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)

				if visible then
					local dist = (workspace.CurrentCamera.CFrame.Position-hrp.Position).magnitude
					if dist > lib.flags["max_distance"]["value"] then
						continue
					end

					local size = (workspace.CurrentCamera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.3, 0)).Y - workspace.CurrentCamera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.9, 0)).Y) / 2
					local box_size = Vector2.new(math.floor(size * 1.3), math.floor(size * 1.9))
					local box_pos = Vector2.new(math.floor(pos.X - size * 1.3 / 2), math.floor(pos.Y - size * 1.6 / 2))
					local font = #lib.flags["font"]["option"] == 1 and lib.flags["font"]["option"][1] or "Plex"
					
					if lib.flags["chams"]["toggle"] then
						local highlight = esp_table.highlight

						highlight.FillColor = lib.flags["chams"].Color
						highlight.FillTransparency = lib.flags["chams"].Transparency
						highlight.OutlineColor = lib.flags["outline"].Color
						highlight.OutlineTransparency = lib.flags["outline"].Transparency
						highlight.Adornee = player.Character
						highlight.Enabled = true
					end

					if lib.flags["box"]["toggle"] then
						local box = esp_table.drawings.box
						local outline = esp_table.drawings.outline
						
						box.Size = box_size
						box.Position = box_pos
						box.Color = lib.flags["box"].Color
						box.Transparency = -lib.flags["box"].Transparency+1
						outline.Transparency = -lib.flags["box"].Transparency+1
						outline.Size = box_size
						outline.Position = box_pos
						outline.Visible = true
						box.Visible = true
					end

					if lib.flags["fill"]["toggle"] then
						local fill = esp_table.drawings.fill
						
						fill.Size = box_size
						fill.Position = box_pos
						fill.Color = lib.flags["fill"].Color
						fill.Transparency = -lib.flags["fill"].Transparency+1
						fill.Visible = true
					end

					if lib.flags["health"]["toggle"] then
						local healthbar = esp_table.drawings.healthbar
						local health_outline = esp_table.drawings.healthoutline

						healthbar.From = Vector2.new((box_pos.X - 5), box_pos.Y + box_size.Y)
						healthbar.To = Vector2.new(healthbar.From.X, healthbar.From.Y - (hum.Health / hum.MaxHealth) * box_size.Y)
						healthbar.Color = lib.flags["health"].Color
						healthbar.Transparency = -lib.flags["health"].Transparency+1
						healthbar.Visible = true
		
						health_outline.From = Vector2.new(healthbar.From.X, box_pos.Y + box_size.Y + 1)
						health_outline.To = Vector2.new(healthbar.From.X, (healthbar.From.Y - 1 * box_size.Y) -1)
						health_outline.Visible = true

						if health_color then
							local hp = math.clamp(hum.Health/hum.MaxHealth,0,1)
							healthbar.Color = Color3.fromHSV(hp/3,1,1)
						end

						if hum.Health < hum.MaxHealth and health_number then
							local health = esp_table.drawings.health
							local h_text = tostring(math.round(hum.Health))

							health.Text = h_text
							health.Size = 12
							health.Visible = true
							health.Color = Color3.fromRGB(255,255,255)
							health.Position = healthbar.To - Vector2.new(health.TextBounds.X/2 + 2, 0)
						end
					end

					if lib.flags["name"]["toggle"] then
						local name = esp_table.drawings.name

						name.Text = player.Name 
						name.Position = Vector2.new(box_size.X / 2 + box_pos.X, box_pos.Y - name.TextBounds.Y - 1)
						name.Color = lib.flags["name"].Color
						name.Transparency = -lib.flags["name"].Transparency+1
						name.Font = Drawing.Fonts[font]
						name.Size = lib.flags["name"]["value"]
						name.Visible = true
					end

					if lib.flags["weapon"]["toggle"] then
						local weapon = esp_table.drawings.weapon
						local e_weapon = player.Character:FindFirstChild("EquippedTool")

						if e_weapon then
							weapon.Text = e_weapon.Value
							weapon.Color = lib.flags["weapon"].Color
							weapon.Transparency = -lib.flags["weapon"].Transparency+1
							weapon.Font = Drawing.Fonts[font]
							weapon.Size = lib.flags["weapon"]["value"]
							weapon.Position = Vector2.new(box_size.X / 2 + box_pos.X, (box_size.Y + box_pos.Y) + 1)
							weapon.Visible = true
						end
					end

					local flag_offset = 0

					if lib.flags["zoom"]["toggle"] then
						local zoom = esp_table.drawings.zoom
						local ads = player.Character:FindFirstChild("ADS")

						if ads and ads.Value then
							zoom.Text = "ZOOM"
							zoom.Color = lib.flags["zoom"].Color
							zoom.Transparency = -lib.flags["zoom"].Transparency+1
							zoom.Font = Drawing.Fonts[font]
							zoom.Size = lib.flags["zoom"]["value"]
							zoom.Position = Vector2.new((box_pos.X + box_size.X) + zoom.TextBounds.X/2 + 2, box_pos.Y + flag_offset)
							zoom.Visible = true

							flag_offset = flag_offset + zoom.TextBounds.Y
						end
					end

					if lib.flags["bomb"]["toggle"] then
						local bomb = esp_table.drawings.bomb
						local has_bomb = workspace.Status.HasBomb.Value

						if player.Name == has_bomb then
							bomb.Text = "BOMB"
							bomb.Color = lib.flags["bomb"].Color
							bomb.Transparency = -lib.flags["bomb"].Transparency+1
							bomb.Font = Drawing.Fonts[font]
							bomb.Size = lib.flags["bomb"]["value"]
							bomb.Position = Vector2.new((box_pos.X + box_size.X) + bomb.TextBounds.X/2 + 2, box_pos.Y + flag_offset)
							bomb.Visible = true

							flag_offset = bomb.TextBounds.Y
						end
					end

					if lib.flags["distance"]["toggle"] then
						local dist = tostring(math.round(dist)).."m"
						local distance = esp_table.drawings.distance

						distance.Text = dist
						distance.Color = lib.flags["distance"].Color
						distance.Size = lib.flags["distance"]["value"]
						distance.Font = Drawing.Fonts[font]
						distance.Position = Vector2.new((box_pos.X + box_size.X) + distance.TextBounds.X/2 + 2, box_pos.Y + flag_offset)
						distance.Visible = true

						flag_offset = flag_offset + distance.TextBounds.Y
					end

					if lib.flags["tracers"]["toggle"] then
						local tracer = esp_table.drawings.tracer
						local tracer_option = lib.flags["tracers"]["option"]
						local tracer_option = #tracer_option == 1 and lib.flags["tracers"]["option"][1] or "Torso"

						tracer.To = Vector2.new(pos.X, pos.Y)
						tracer.Color = lib.flags["tracers"].Color
						tracer.Transparency = -lib.flags["tracers"].Transparency+1
						tracer.Visible = true

						if tracer_option == "Mouse" then
							tracer.From = Vector2.new(client.mouse.X, client.mouse.Y + 38)
						elseif tracer_option == "Torso" and client.loaded() then
							local hrp = client.character().HumanoidRootPart
							local pos, visible = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
							if visible then
								tracer.From = Vector2.new(pos.X, pos.Y)
							else
								tracer.Visible = false
							end
						end
					end
				elseif not visible then
					if lib.flags["offscreen"]["toggle"] then
						local triangle = esp_table.drawings.triangle
						local font = #lib.flags["font"]["option"] == 1 and lib.flags["font"]["option"][1] or "Plex"

						local screen_size = workspace.CurrentCamera.ViewportSize
						triangle.Visible = true
						local camCf = workspace.CurrentCamera.CFrame
						camCf = CFrame.lookAt(camCf.p, camCf.p + camCf.LookVector * Vector3.new(1, 0, 1))
		
						local projected = camCf:PointToObjectSpace(hrp.Position)
						local angle = math.atan2(projected.z, projected.x)
		
						local cx, sy = math.cos(angle), math.sin(angle)
						local cx1, sy1 = math.cos(angle + math.pi/2), math.sin(angle + math.pi/2)
						local cx2, sy2 = math.cos(angle + math.pi/2*3), math.sin(angle + math.pi/2*3)
		
						local viewport = screen_size
		
						local big, small = math.max(viewport.x, viewport.y), math.min(viewport.x, viewport.y)
		
						local arrowOrigin = viewport/2 + Vector2.new(cx * big * 75/200, sy * small * 75/200) * lib.flags["offscreen_distance"]["value"]/1000
		
						triangle.PointA = arrowOrigin + Vector2.new(30 * cx, 30 * sy) * lib.flags["offscreen"]["value"]/100
						triangle.PointB = arrowOrigin + Vector2.new(15 * cx1, 15 * sy1) * lib.flags["offscreen"]["value"]/100
						triangle.PointC = arrowOrigin + Vector2.new(15 * cx2, 15 * sy2) * lib.flags["offscreen"]["value"]/100

						if lib.flags["show_name"]["toggle"] then
							local middle = Vector2.new(triangle.PointA.X, arrowOrigin.Y + (triangle.PointA.Y - arrowOrigin.Y)/2)

							local name = esp_table.drawings.name

							name.Text = player.Name 
							name.Color = lib.flags["name"].Color
							name.Transparency = -lib.flags["name"].Transparency+1
							name.Font = Drawing.Fonts[font]
							name.Size = lib.flags["name"]["value"]
							name.Position = middle + Vector2.new(0, name.TextBounds.Y)
							name.Visible = true
						end
						
						triangle.Color = lib.flags["offscreen"].Color
						triangle.Transparency = -lib.flags["offscreen"].Transparency+1
					end
				end
			end
		end
	end
end)
end)()

function core:is_key_down(key)
    return services.UserInputService:IsKeyDown(key)
end

function core:get_closest_to_cursor()
	local closest = 9e9
	local target = nil

	if client.loaded() then
		for _, plr in next, services.Players:GetPlayers() do
			if plr ~= client.plr then
				local team_check = true

				local character = plr.Character or workspace:FindFirstChild(plr.Name)

				if lib.flags["team_check2"]["toggle"] then 
					team_check = plr.Team ~= client.plr.Team 
				else 
					team_check = true
				end

				if character and team_check then
					local playerHumanoid = character:FindFirstChild("Humanoid")
					local hrp = character:FindFirstChild("HumanoidRootPart")
					if hrp and playerHumanoid then
						local hitVector, onScreen = workspace.CurrentCamera:WorldToScreenPoint(hrp.Position)
						if onScreen then
							local htm = (Vector2.new(client.mouse.X, client.mouse.Y) - Vector2.new(hitVector.X, hitVector.Y)).magnitude
							local threshold = lib.flags["field_of_view"]["value"]*2
							if htm < closest and htm <= threshold and (client.character().HumanoidRootPart.Position-hrp.Position).magnitude < 600 then
								target = plr
								closest = htm
							end
						end
					end
				end
			end
		end
	end
	return target
end

-- * Main functions

local function update_indicators()
	local ps_state = ((ping_spike.get_active() and lib.flags["ping_spike"]["toggle"]) and "on" or "off")
	ps:set_visible(lib.flags["ping_spike"]["toggle"]); ps:set_state(ps_state)
	local fake_state = ((fake_lag.get_active() and lib.flags["fake_lag"]["toggle"]) and "on" or "off")
	fake:set_visible(lib.flags["fake_lag"]["toggle"]); fake:set_state(fake_state)
	local fw_state = ((freeze_world.get_active() and lib.flags["freeze_world"]["toggle"]) and "on" or "off")
	fw:set_visible(lib.flags["freeze_world"]["toggle"]); fw:set_state(fw_state)
end

local function update_keybinds()
	local state = ((triggerbot.get_active() and lib.flags["triggerbot"]["toggle"]) and true or false)
	t_keybind:set_visible(state); t_keybind:set_key(lib.flags["triggerbot"]["bind"]["key"])
	
	local state = ((ping_spike.get_active() and lib.flags["ping_spike"]["toggle"]) and true or false)
	ps_keybind:set_visible(state); ps_keybind:set_key(lib.flags["ping_spike"]["bind"]["key"])

	local state = ((fake_lag.get_active() and lib.flags["fake_lag"]["toggle"]) and true or false)
	fl_keybind:set_visible(state); fl_keybind:set_key(lib.flags["fake_lag"]["bind"]["key"])

	local state = ((aim_assist.get_active() and lib.flags["aim_assist"]["toggle"]) and true or false)
	aa_keybind:set_visible(state); aa_keybind:set_key(lib.flags["aim_assist"]["bind"]["key"])

	local state = ((freeze_world.get_active() and lib.flags["freeze_world"]["toggle"]) and true or false)
	fw_keybind:set_visible(state); fw_keybind:set_key(lib.flags["freeze_world"]["bind"]["key"])

	local state = ((freeze_character.get_active() and lib.flags["freeze_character"]["toggle"]) and true or false)
	fc_keybind:set_visible(state); fc_keybind:set_key(lib.flags["freeze_character"]["bind"]["key"])
end

local function set_ping(amount)
	services.NetworkClient:SetOutgoingKBPSLimit(amount)
end

local function stop_packet(hrp)
	sethiddenproperty(hrp, "NetworkIsSleeping", true)
end

local function hitbox_check(name)
	local arm_checks = {"Arm", "Hand"}
	for i = 1, #arm_checks do
		if string.find(name, arm_checks[i]) then
			return "Arms"
		end
	end
	local leg_checks = {"Leg", "Foot"}
	for i = 1, #leg_checks do
		if string.find(name, leg_checks[i]) then
			return "Legs"
		end
	end
	local torso_checks = {"Torso", "RootPart"}
	for i = 1, #torso_checks do
		if string.find(name, torso_checks[i]) then
			return "Torso"
		end
	end
	local head_checks = {"Head"}
	for i = 1, #head_checks do
		if string.find(name, head_checks[i]) then
			return "Head"
		end
	end
end

local function client_added(char)
	client.highlight.Adornee = char
	local hum = char:WaitForChild("Humanoid")
	hum.AnimationPlayed:Connect(function(anim)
		if (lib.flags["fake_lag"]["toggle"] and fake_lag.get_active()) and lib.flags["cancel_anims"]["toggle"] then
			local chance = math.random(1, 100)
			if chance <= lib.flags["cancel_anims"]["value"] then
				anim:Stop()
			end
		end
	end)
end

local function do_lag()
	local hrp = client.character().HumanoidRootPart
	if not core.lag_cooldown then
		core.lagging = true
		core.lag_cooldown = true
		local cooldown = lib.flags["character_lag"]["value"]/math.random(1000,2222)
		local cooldown2 = lib.flags["character_lag"]["value"]/math.random(2500,3222)
		coroutine.wrap(function()
			task.wait(cooldown)
			core.lagging = false
			task.wait(cooldown2)
			core.lag_cooldown = false
		end)()
	end
end

for i,v in pairs(services.Players:GetPlayers()) do
	if v ~= client.plr then
		esp:add_esp(v)
	end
end

-- * Connections / Init pt. 2

core:add_connection(client.plr.CharacterAdded, client_added)

for i,v in pairs(services.Players:GetPlayers()) do
	if v ~= client.plr then
		esp:add_esp(v)
	end
end

core:add_connection(services.Players.PlayerAdded, function(player)
	if player == client.plr then
		return
	end

	esp:add_esp(player)
	selected_player.set_options(getPlayerList())
end)

core:add_connection(services.Players.PlayerRemoving, function(player)
	if player == client.plr then
		return
	end

	esp:remove_esp(player)
	selected_player.set_options(getPlayerList())
end)

-- * ESP 2

client.highlight = Instance.new("Highlight")
client.highlight.Parent = game.CoreGui
client.highlight.Enabled = false
client.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

if client.loaded() then client_added(client.character()) end

local f_c = Drawing.new("Circle")
f_c.Thickness = 1
f_c.Radius = 0
f_c.Filled = true
f_c.NumSides = 50
f_c.Visible = false
f_c.ZIndex = 5

local d_c = Drawing.new("Circle")
d_c.Thickness = 1
d_c.Radius = 0
d_c.Filled = true
d_c.NumSides = 50
d_c.Visible = false
d_c.ZIndex = 6

-- * Loops

LPH_JIT_MAX(function()
local heartbeat_loop = core:add_connection(services.RunService.Heartbeat, function()
    set_ping((ping_spike.get_active() and lib.flags["ping_spike"]["toggle"]) and 100-lib.flags["ping_spike"]["value"] or 9e9)
	if lib.flags["aim_assist"]["toggle"] then
		f_c.Filled = #lib.flags["fov_circle"]["option"] == 1
		f_c.Color = lib.flags["fov_circle"].Color
		f_c.Transparency = -lib.flags["fov_circle"].Transparency+1
		f_c.Position = Vector2.new(client.mouse.X, client.mouse.Y + 38)
		f_c.Radius = lib.flags["field_of_view"]["value"]*2
		f_c.Visible = true
		d_c.Filled = #lib.flags["deadzone_circle"]["option"] == 1
		d_c.Color = lib.flags["deadzone_circle"].Color
		d_c.Transparency = -lib.flags["deadzone_circle"].Transparency+1
		d_c.Position = Vector2.new(client.mouse.X, client.mouse.Y + 38)
		d_c.Radius = (lib.flags["field_of_view"]["value"]*2)/(100/lib.flags["deadzone"]["value"])
		d_c.Visible = true
	else
		f_c.Visible = false
		d_c.Visible = false
	end
	if lib.flags["dropped_weapons"]["toggle"] then
		local debris = workspace.Debris:GetChildren()

		for i = 1, #debris do
			local gun = debris[i]
			local mag = gun:FindFirstChild("Mag")
			if mag and not find(dropped_weapons, gun) then
				table.insert(dropped_weapons, gun)
	
				local drawing_name = Drawing2D:new("Text", {
					ZIndex = 2,
					Center = true,
					Outline = true
				})
	
				local t = {gun, drawing_name}
	
				table.insert(dw_drawings, t)
			end
		end
	end
	if client.loaded() then
		local hrp = client.character().HumanoidRootPart
		local hum = client.character().Humanoid
		settings().Network.IncomingReplicationLag = (lib.flags["freeze_world"]["toggle"] and freeze_world.get_active()) and 1000 or 0
		if lib.flags["triggerbot"]["toggle"] and triggerbot.get_active() and not core.trigger_delay then
			local mouse_target = client.mouse.Target
			if mouse_target then
				local hb_name = hitbox_check(mouse_target.Name)
				if hb_name then
					local blind_check = true
					if lib.flags["flash_check2"]["toggle"] then
						if client.plr.PlayerGui.Blnd.Blind.BackgroundTransparency > 0.45 then 
							blind_check = true 
						else
							blind_check = false
						end
					end

					local p_p = services.Players:FindFirstChild(mouse_target.Parent.Name) or services.Players:FindFirstChild(mouse_target.Parent.Parent.Name) or services.Players:FindFirstChild(mouse_target.Parent.Parent.Parent.Name)
					if p_p and blind_check and p_p.Team ~= client.plr.Team then
						if find(lib.flags["hitboxes"]["option"], hb_name) then
							core.trigger_delay = true 
							coroutine.wrap(function()
								task.wait(lib.flags["triggerbot"]["value"]/1000)
								mouse1press()
								task.wait(0.015)
								mouse1release()
								core.trigger_delay = false
							end)()
						end
					end
				end
			end
		end
		if lib.flags["aim_assist"]["toggle"] and aim_assist.get_active() then
			local closest = core:get_closest_to_cursor()
			if closest ~= nil then
				local character = closest.Character
				local team_check = false
				local blind_check = true
				if lib.flags["flash_check"]["toggle"] then
					if client.plr.PlayerGui.Blnd.Blind.BackgroundTransparency > 0.45 then 
						blind_check = true 
					else
						blind_check = false
					end
				end

				if lib.flags["team_check2"]["toggle"] then 
					team_check = closest.Team ~= client.plr.Team 
				else 
					team_check = true
				end

				if team_check and character and blind_check then
					local aim_part = #lib.flags["aim_part"]["option"] == 1 and lib.flags["aim_part"]["option"][1] and "Head"
					local hrp = character:FindFirstChild(aim_part)
					local visible = true
					
					if lib.flags["visible_check"]["toggle"] then
						visible = #workspace.CurrentCamera:GetPartsObscuringTarget({client.character().Head.Position, hrp.Position}, {client.character(), character, workspace.CurrentCamera}) == 0
					end
					
					if hrp and visible then
						local pos, visible = workspace.CurrentCamera:WorldToScreenPoint(hrp.Position)
						local pos2 = workspace.CurrentCamera:WorldToScreenPoint(client.mouse.Hit.p)
						if visible then
							local new_posx = pos.X - pos2.X
							local new_posy = pos.Y - pos2.Y
							local deadzone_distance = (lib.flags["field_of_view"]["value"]*2)/(100/lib.flags["deadzone"]["value"])
							if math.abs(new_posx) > deadzone_distance or math.abs(new_posy) > deadzone_distance then
								mousemoverel(new_posx / lib.flags["horizontal_smoothing"]["value"], new_posy / lib.flags["vertical_smoothing"]["value"])
							end
						end
					end
				end
			end	
		end
		if freeze_character.get_active() and lib.flags["freeze_character"]["toggle"] then
			core.fake.Parent = workspace
			for _, part in pairs(core.fake:GetChildren()) do
				part.Transparency = lib.flags["freeze_character"].Transparency
				part.Color = lib.flags["freeze_character"].Color
			end
			core.lagging = true
		elseif fake_lag.get_active() and lib.flags["fake_lag"]["toggle"] and lib.flags["character_lag"]["toggle"] then
			core.fake.Parent = workspace
			for _, part in pairs(core.fake:GetChildren()) do
				part.Transparency = lib.flags["fake_lag"].Transparency
				part.Color = lib.flags["fake_lag"].Color
			end
			if not core.lag_cooldown then
				core.last_fake_cf = {}
				for _, part in pairs(core.fake:GetChildren()) do
					local found_part = client.character():FindFirstChild(part.Name)
					if found_part then
						part.CFrame = found_part.CFrame
					end
				end
			end
			do_lag()
		else
			core.fake.Parent = game.CoreGui
		   	core.last_fake_cf = {}
			for _, part in pairs(core.fake:GetChildren()) do
				local found_part = client.character():FindFirstChild(part.Name)
				if found_part then
					part.CFrame = found_part.CFrame
				end
			end
			core.lagging = false
		end
		if core.lagging then
			stop_packet(hrp)
		end
	end
	update_indicators()
	update_keybinds()
end)

local renderstepped_loop = core:add_connection(services.RunService.RenderStepped, function()
	if lib.flags["fov"]["toggle"] then
		workspace.CurrentCamera.FieldOfView = lib.flags["fov"]["value"]
	end
	if find(lib.flags["removals"]["option"], "Flash") then client.plr.PlayerGui.Blnd.Enabled = false else client.plr.PlayerGui.Blnd.Enabled = true end
	if find(lib.flags["removals"]["option"], "Shadows") then game.Lighting.GlobalShadows = false else game.Lighting.GlobalShadows = true end
	for _, smoke in pairs(workspace.Ray_Ignore.Smokes:GetChildren()) do
		local emitter = smoke:FindFirstChild("ParticleEmitter")
		if emitter then
			emitter.ZOffset = find(lib.flags["removals"]["option"], "Smokes") and -1000 or 1
		end
	end
	if lib.flags["forcefield_gun"]["toggle"] then
		update_gun(true)
	end
	if lib.flags["world_time"]["toggle"] then
		game.Lighting.ClockTime = lib.flags["world_time"]["value"]
	end
	if lib.flags["ambient"]["toggle"] then
		game.Lighting.Ambient = lib.flags["ambient"].Color
	end
	if lib.flags["fog"]["toggle"] then
		game.Lighting.FogColor = lib.flags["fog"].Color
		game.Lighting.FogStart = lib.flags["fog_start"]["value"]
		game.Lighting.FogEnd = lib.flags["fog_end"]["value"]
	end
	if client.loaded() then
		local hrp = client.character().HumanoidRootPart
		local hum = client.character().Humanoid
		if lib.flags["quickstop"]["toggle"] and (not core:is_key_down(Enum.KeyCode.W) and not core:is_key_down(Enum.KeyCode.A) and not core:is_key_down(Enum.KeyCode.S) and not core:is_key_down(Enum.KeyCode.D)) then
			hrp.Velocity = Vector3.new(0,hrp.Velocity.Y,0)
		end
	end
end)
end)()
