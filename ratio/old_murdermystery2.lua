local lib = {}
local services = setmetatable({}, { __index = function(self, key) return game:GetService(key) end })
lib.util = {}
lib.items = {}
lib.connections = {}

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
	writefile("Ratio/Configs/Killsays.txt", "[\"I should change this in Killsays.txt!\", \"I really need to change this file!\"]")
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
	
	for i,v in pairs(tab_holder:GetChildren()) do
		if v:IsA("Frame") and v.Name ~= "size_handle" then
			local t = v.Name:match("([^_]+)_([^_]+)")
			table.insert(lib.titems, v)
			v.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 and lib.stats.tab ~= t then
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
					if table.find(t2, "slider") then
						section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset + 16)
					end
					if table.find(t2, "dropdown") then
						section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset + 26)
					end
					if table.find(t2, "textbox") then
						section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset + 26)
					end
					if table.find(t2, "button") then
						section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset + 16)
					end
				else
					if table.find(t2, "slider") then
						section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset - 16)
					end
					if table.find(t2, "dropdown") then
						section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset - 26)
					end
					if table.find(t2, "textbox") then
						section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset - 26)
					end
					if table.find(t2, "button") then
						section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset - 16)
					end
					section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset - 16)
				end
			end

			function t:destroy()
				lib.flags[f] = nil
				element:Destroy()
				if table.find(v2, "slider") then
					section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset - 16)
				end
				if table.find(v2, "dropdown") then
					section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset - 26)
				end
				if table.find(v2, "textbox") then
					section.Size = UDim2.new(section.Size.X.Scale, section.Size.X.Offset, section.Size.Y.Scale, section.Size.Y.Offset - 26)
				end
				if table.find(v2, "button") then
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
					keybind_label.Size = UDim2.new(0, 20, 0, 13);
					keybind_label.ZIndex = 3;
					keybind_label.Font = Enum.Font.Unknown;
					keybind_label.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal);
					keybind_label.Text = "[-]";
					keybind_label.TextColor3 = Color3.fromRGB(65.0000037252903, 65.0000037252903, 65.0000037252903);
					keybind_label.TextSize = 14;
					keybind_label.TextStrokeTransparency = 0.6000000238418579;
					keybind_label.TextWrapped = true;
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
								task.wait(0.1)
								if input.UserInputType == Enum.UserInputType.Keyboard then
									lib.flags[f]["bind"]["key"] = input.KeyCode.Name
									keybind_label.TextColor3 = Color3.fromRGB(65.0000037252903, 65.0000037252903, 65.0000037252903);
									t.set_keybind(lib.flags[f]["bind"])
									lib.stats.busy = false
									binding = false
									connection:Disconnect()
								end
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
					
					services.UserInputService.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.Keyboard then
							if input.KeyCode.Name == lib.flags[f]["bind"]["key"] and lib.flags[f]["bind"]["method"] == "hold" then
								lib.flags[f]["bind"]["active"] = true
							elseif input.KeyCode.Name == lib.flags[f]["bind"]["key"] and lib.flags[f]["bind"]["method"] == "toggle" then
								lib.flags[f]["bind"]["active"] = not lib.flags[f]["bind"]["active"]
							end
						end
					end)
					
					services.UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.Keyboard then
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
					slider_background.BackgroundColor3 = Color3.fromRGB(57.00000040233135, 57.00000040233135, 57.00000040233135);
					slider_background.BorderColor3 = Color3.fromRGB(0, 0, 0);
					slider_background.Name = "slider_background";
					slider_background.Position = UDim2.new(0.10000000149011612, 0, 0, 18);
					slider_background.Size = UDim2.new(0.800000011920929, 0, 0, 6);
					slider_background.ZIndex = 3;

					local UIGradient = Instance.new("UIGradient", slider_background);
					UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(182.00000435113907, 182.00000435113907, 182.00000435113907))};
					UIGradient.Rotation = 90;

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
					dropdown_background.BackgroundColor3 = Color3.fromRGB(52.000000700354576, 52.000000700354576, 52.000000700354576);
					dropdown_background.BorderColor3 = Color3.fromRGB(11.000000294297934, 11.000000294297934, 11.000000294297934);
					dropdown_background.Name = "dropdown_background";
					dropdown_background.Position = UDim2.new(0.10000000149011612, 0, 0, 18);
					dropdown_background.Size = UDim2.new(0.800000011920929, 0, 0, 17);
					dropdown_background.ZIndex = 3;

					local UIGradient = Instance.new("UIGradient", dropdown_background);
					UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(182.00000435113907, 182.00000435113907, 182.00000435113907))};
					UIGradient.Rotation = 90;

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
					UIGradient_0.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(182.00000435113907, 182.00000435113907, 182.00000435113907))};
					UIGradient_0.Rotation = 90;

					local UIListLayout = Instance.new("UIListLayout", dropdown_inside);
					UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder;
					
					dropdown_background.MouseEnter:Connect(function()
						dropdown_background.BackgroundColor3 = Color3.fromRGB(67,67,67)
					end)
					
					dropdown_background.MouseLeave:Connect(function()
						dropdown_background.BackgroundColor3 = Color3.fromRGB(52,52,52)
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
						local set = (#val > 0 and table.find(options, val[1])) and val or {}
						for i,v in pairs(dropdown_inside:GetChildren()) do
							if v:IsA("TextLabel") then
								if table.find(set, v.Name) then
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
								if not table.find(lib.flags[f]["option"], val[i]) then
									dropdown_label_0.Font = Enum.Font.SourceSansBold
									dropdown_label_0.BackgroundTransparency = 0.5
									dropdown_label_0.TextColor3 = Color3.fromRGB(199, 199, 199)
								else
									dropdown_label_0.BackgroundTransparency = 0.5
								end
							end)
							
							dropdown_label_0.MouseLeave:Connect(function()
								if not table.find(lib.flags[f]["option"], val[i]) then
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
										if not table.find(lib.flags[f]["option"], val[i]) then
											local clone = lib.flags[f]["option"]
											table.insert(clone, val[i])
											t.set_option(clone)
										else
											local clone = lib.flags[f]["option"]
											table.remove(clone, table.find(clone, val[i]))
											t.set_option(clone)
										end
									else
										if not table.find(lib.flags[f]["option"], val[i]) then
											t.set_option({val[i]})
										else
											t.set_option({})
										end
									end
								end
							end)
						end
						t.set_option({})
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
							if not table.find(lib.flags[f]["option"], options[i]) then
								dropdown_label_0.Font = Enum.Font.SourceSansBold
								dropdown_label_0.BackgroundTransparency = 0.5
								dropdown_label_0.TextColor3 = Color3.fromRGB(199, 199, 199)
							else
								dropdown_label_0.BackgroundTransparency = 0.5
							end
						end)

						dropdown_label_0.MouseLeave:Connect(function()
							if not table.find(lib.flags[f]["option"], options[i]) then
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
									if not table.find(lib.flags[f]["option"], options[i]) then
										local clone = lib.flags[f]["option"]
										table.insert(clone, options[i])
										t.set_option(clone)
									else
										local clone = lib.flags[f]["option"]
										table.remove(clone, table.find(clone, options[i]))
										t.set_option(clone)
									end
								else
									if not table.find(lib.flags[f]["option"], options[i]) then
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
					button.BackgroundColor3 = Color3.fromRGB(44.000001177191734, 44.000001177191734, 44.000001177191734);
					button.BorderColor3 = Color3.fromRGB(11.000000294297934, 11.000000294297934, 11.000000294297934);
					button.Name = "button";
					button.Position = UDim2.new(0.10000000149011612, 0, 0, 2);
					button.Size = UDim2.new(0.800000011920929, 0, 0, 26);
					button.ZIndex = 3;

					local UIGradient = Instance.new("UIGradient", button);
					UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(142.00000435113907, 142.00000435113907, 142.00000435113907))};
					UIGradient.Rotation = 90;

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
						button.BackgroundColor3 = Color3.fromRGB(44,44,44)
					end)
					
					buttonlabel.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 and not lib.stats.busy then
							button.BackgroundColor3 = Color3.fromRGB(22,22,22)
							task.spawn(c)
						end
					end)
					
					buttonlabel.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							button.BackgroundColor3 = Color3.fromRGB(44,44,44)
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

local load = false

if not isfile("Ratio/Configs/Autoload.cfg") then
do -- Loader

	local stat = {}
	stat["totalExecutions"] = "?"
	stat["WhitelistedDate"] = "?"
	local holder = lib.util.new("ScreenGui", {
		Enabled = true,
		Name = services.HttpService:GenerateGUID(false),
		Parent = game.CoreGui,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Global
	}, {})
	
	local o1 = lib.util.new("Frame", {
		Parent = holder;
		BackgroundColor3 = Color3.fromRGB(57.00000040233135, 57.00000040233135, 57.00000040233135);
		BorderColor3 = Color3.fromRGB(41.00000135600567, 41.00000135600567, 41.00000135600567);
		Name = "outline";
		Position = UDim2.new(0.5, -200, 0.5, -125);
		Size = UDim2.new(0, 400, 0, 250);
	}, {})
	
	local o2 = lib.util.new("Frame", {
		Parent = o1;
		BackgroundColor3 = Color3.fromRGB(57.00000040233135, 57.00000040233135, 57.00000040233135);
		BorderColor3 = Color3.fromRGB(40.00000141561031, 40.00000141561031, 40.00000141561031);
		Name = "outline2";
		Position = UDim2.new(0, 2, 0, 2);
		Size = UDim2.new(1, -4, 1, -4);
	}, {})
	
	local o3 = lib.util.new("Frame", {
		Parent = o2;
		BackgroundColor3 = Color3.fromRGB(46.000001057982445, 46.000001057982445, 46.000001057982445);
		BorderColor3 = Color3.fromRGB(40.00000141561031, 40.00000141561031, 40.00000141561031);
		Name = "outline3";
		Position = UDim2.new(0, 2, 0, 2);
		Size = UDim2.new(1, -4, 1, -4);
	}, {})
	
	local o4 = lib.util.new("Frame", {
		Parent = o3;
		BackgroundColor3 = Color3.fromRGB(42.000001296401024, 42.000001296401024, 42.000001296401024);
		BorderColor3 = Color3.fromRGB(40.00000141561031, 40.00000141561031, 40.00000141561031);
		Name = "outline4";
		Position = UDim2.new(0, 1, 0, 1);
		Size = UDim2.new(1, -2, 1, -2);
	}, {})
	
	local b = lib.util.new("ImageLabel", {
		Parent = o4;
		BackgroundColor3 = Color3.fromRGB(255, 255, 255);
		BorderSizePixel = 0;
		Name = "bg";
		Size = UDim2.new(1, 0, 1, 0);
		Image = "rbxassetid://8816631771";
	}, {})
	
	local rainbowline = lib.util.new("ImageLabel", {
		Parent = o4;
		BackgroundColor3 = Color3.fromRGB(255, 255, 255);
		BorderSizePixel = 0;
		Name = "rainbowline";
		Size = UDim2.new(1, 0, 0, 2);
		Image = "http://www.roblox.com/asset/?id=7023958524";
	}, {})
	
	local gamebox = lib.util.new("Frame", {
		Parent = o4;
		BackgroundColor3 = Color3.fromRGB(23.000000528991222, 23.000000528991222, 23.000000528991222);
		BorderColor3 = Color3.fromRGB(42.000001296401024, 42.000001296401024, 42.000001296401024);
		Name = "gamebox";
		Position = UDim2.new(0, 10, 0, 11);
		Size = UDim2.new(0, 250, 0, 100);
	}, {})
	
	local UIListLayout = lib.util.new("UIListLayout", {
		Parent = gamebox;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Name = "UIListLayout_2";
	}, {})
	
	local loadbox = lib.util.new("Frame", {
		Parent = o4;
		BackgroundColor3 = Color3.fromRGB(23.000000528991222, 23.000000528991222, 23.000000528991222);
		BorderColor3 = Color3.fromRGB(42.000001296401024, 42.000001296401024, 42.000001296401024);
		Name = "loadbox";
		Position = UDim2.new(1, -118, 0, 11);
		Size = UDim2.new(0, 108, 0, 100);
	}, {})

	local loadlabel = lib.util.new("TextLabel", {
		Parent = loadbox;
		BackgroundColor3 = Color3.fromRGB(255, 255, 255);
		BackgroundTransparency = 1;
		Name = "loadlabel";
		Position = UDim2.new(0, 5, 0, -9);
		Size = UDim2.new(1, 0, 0, 16);
		Font = Enum.Font.SourceSansBold;
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal);
		Text = "Options";
		TextColor3 = Color3.fromRGB(191.00000381469727, 191.00000381469727, 191.00000381469727);
		TextSize = 14;
		TextStrokeTransparency = 0.800000011920929;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Top;
	})

	local loadbutton = lib.util.new("TextLabel", {
		Parent = loadbox;
		BackgroundColor3 = Color3.fromRGB(31.000001952052116, 31.000001952052116, 31.000001952052116);
		BorderColor3 = Color3.fromRGB(12.000000234693289, 12.000000234693289, 12.000000234693289);
		Name = "loadbutton";
		Position = UDim2.new(0.5, -45, 0.5, -28);
		Size = UDim2.new(0, 90, 0, 24);
		Font = Enum.Font.SourceSansBold;
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal);
		Text = "Load";
		TextColor3 = Color3.fromRGB(206.000018119812, 206.000018119812, 206.000018119812);
		TextSize = 14;
		TextStrokeTransparency = 0.800000011920929;
	})

	local UIGradient = lib.util.new("UIGradient", {
		Parent = loadbutton;
		Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(185.00000417232513, 185.00000417232513, 185.00000417232513))};
		Rotation = 90;
		Name = "UIGradient_1"
	})
	
	local exitbutton = lib.util.new("TextLabel", {
		Parent = loadbox;
		BackgroundColor3 = Color3.fromRGB(31.000001952052116, 31.000001952052116, 31.000001952052116);
		BorderColor3 = Color3.fromRGB(12.000000234693289, 12.000000234693289, 12.000000234693289);
		Name = "exitbutton";
		Position = UDim2.new(0.5, -45, 0.5, 2);
		Size = UDim2.new(0, 90, 0, 24);
		Font = Enum.Font.SourceSansBold;
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal);
		Text = "Exit";
		TextColor3 = Color3.fromRGB(206.000018119812, 206.000018119812, 206.000018119812);
		TextSize = 14;
		TextStrokeTransparency = 0.800000011920929;
	})
	
	local UIGradient = lib.util.new("UIGradient", {
		Parent = exitbutton;
		Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(185.00000417232513, 185.00000417232513, 185.00000417232513))};
		Rotation = 90;
		Name = "UIGradient_2";
	})
	
	local statusbox = lib.util.new("Frame", {
		Parent = o4;
		BackgroundColor3 = Color3.fromRGB(23.000000528991222, 23.000000528991222, 23.000000528991222);
		BorderColor3 = Color3.fromRGB(42.000001296401024, 42.000001296401024, 42.000001296401024);
		Name = "statusbox";
		Position = UDim2.new(0, 10, 1, -120);
		Size = UDim2.new(1, -20, 0, 110);
	})

	local label = lib.util.new("TextLabel", {
		Parent = statusbox;
		BackgroundColor3 = Color3.fromRGB(255, 255, 255);
		BackgroundTransparency = 1;
		Name = "label";
		Position = UDim2.new(0, 5, 0, -9);
		Size = UDim2.new(1, 0, 0, 16);
		Font = Enum.Font.SourceSansBold;
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal);
		Text = "Stats";
		TextColor3 = Color3.fromRGB(191.00000381469727, 191.00000381469727, 191.00000381469727);
		TextSize = 14;
		TextStrokeTransparency = 0.800000011920929;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Top;
	})
	
	local statusholder = lib.util.new("Frame", {
		Parent = statusbox;
		BackgroundColor3 = Color3.fromRGB(27.000002190470695, 27.000002190470695, 27.000002190470695);
		BorderColor3 = Color3.fromRGB(12.000000234693289, 12.000000234693289, 12.000000234693289);
		Name = "statusholder";
		Position = UDim2.new(0, 10, 0, 10);
		Size = UDim2.new(1, -20, 1, -20);
	})
	
	local datelabel = lib.util.new("TextLabel", {
		Parent = statusholder;
		BackgroundColor3 = Color3.fromRGB(255, 255, 255);
		BackgroundTransparency = 1;
		Name = "datelabel";
		Position = UDim2.new(0, 5, 0, 2);
		Size = UDim2.new(1, -5, 0, 16);
		Font = Enum.Font.SourceSansItalic;
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Italic);
		Text = "Purchase date: "..stat["WhitelistedDate"];
		TextColor3 = Color3.fromRGB(213.0000177025795, 213.0000177025795, 213.0000177025795);
		TextSize = 14;
		TextStrokeTransparency = 0.6000000238418579;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Top;
	})

	local execlabel = lib.util.new("TextLabel", {
		Parent = statusholder;
		BackgroundColor3 = Color3.fromRGB(255, 255, 255);
		BackgroundTransparency = 1;
		Name = "execlabel";
		Position = UDim2.new(0, 5, 0, 17);
		Size = UDim2.new(1, -5, 0, 16);
		Font = Enum.Font.SourceSansItalic;
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Italic);
		Text = "Total executions: "..stat["totalExecutions"];
		TextColor3 = Color3.fromRGB(213.0000177025795, 213.0000177025795, 213.0000177025795);
		TextSize = 14;
		TextStrokeTransparency = 0.6000000238418579;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Top;
	})
	
	local function addGame(name, desc, img)
		local gamef = lib.util.new("Frame", {
			Parent = gamebox;
			BackgroundColor3 = Color3.fromRGB(16.000000946223736, 16.000000946223736, 16.000000946223736);
			BorderSizePixel = 0;
			Name = "game";
			Size = UDim2.new(1, 0, 0, 45);
		})

		local gameimage = lib.util.new("ImageLabel", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255);
			BackgroundTransparency = 1;
			BorderColor3 = Color3.fromRGB(12.000000234693289, 12.000000234693289, 12.000000234693289);
			Name = "gameimage";
			Position = UDim2.new(0, 5, 0.5, -18);
			Size = UDim2.new(0, 36, 0, 36);
			Image = img;
			Parent = gamef;
		})

		local gamename = lib.util.new("TextLabel", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255);
			BackgroundTransparency = 1;
			Name = "gamename";
			Position = UDim2.new(0, 48, 0, 5);
			Size = UDim2.new(0, 150, 0, 16);
			Font = Enum.Font.SourceSansBold;
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal);
			Text = name;
			TextColor3 = Color3.fromRGB(166.00000530481339, 255, 0);
			TextSize = 15;
			TextStrokeTransparency = 0.6000000238418579;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Top;
			Parent = gamef;
		})

		local gamedesc = lib.util.new("TextLabel", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255);
			BackgroundTransparency = 1;
			Name = "gamedesc";
			Position = UDim2.new(0, 48, 0, 21);
			Size = UDim2.new(0, 150, 0, 14);
			Font = Enum.Font.SourceSans;
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
			Text = desc;
			TextColor3 = Color3.fromRGB(83.00000265240669, 83.00000265240669, 83.00000265240669);
			TextSize = 13;
			TextStrokeTransparency = 0.6000000238418579;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Top;
			Parent = gamef;
		})
	end
	
	exitbutton.MouseEnter:Connect(function()
		exitbutton.BackgroundColor3 = Color3.fromRGB(27,27,27)
	end)
	
	exitbutton.MouseLeave:Connect(function()
		exitbutton.BackgroundColor3 = Color3.fromRGB(31,31,31)
	end)
	
	exitbutton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			exitbutton.BackgroundColor3 = Color3.fromRGB(22,22,22)
		end
	end)
	
	exitbutton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			exitbutton.BackgroundColor3 = Color3.fromRGB(31,31,31)
			holder:Destroy()
		end
	end)
	
	loadbutton.MouseEnter:Connect(function()
		loadbutton.BackgroundColor3 = Color3.fromRGB(27,27,27)
	end)

	loadbutton.MouseLeave:Connect(function()
		loadbutton.BackgroundColor3 = Color3.fromRGB(31,31,31)
	end)

	loadbutton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			loadbutton.BackgroundColor3 = Color3.fromRGB(22,22,22)
			do
				load = true
				holder:Destroy()
			end
		end
	end)

	loadbutton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			loadbutton.BackgroundColor3 = Color3.fromRGB(31,31,31)
		end
	end)
	
	local function setData(n)
		execlabel.Text = "Purchase date: "..tostring(n)
	end
	
	local function setExecutions(n)
		execlabel.Text = "Total executions: "..tostring(n)
	end
	
	if true then
		addGame("Murder Mystery 2", "Updated 1/12/2023", "rbxassetid://12126519184")
	end
end
end

-- * Client

local client = {}; local cheat = {}
client.plr = services.Players.LocalPlayer; client.mouse = client.plr:GetMouse()
client.character = function() return client.plr.Character or client.plr.CharacterAdded:Wait() end
client.loaded = function()
    local parts = {"Head","HumanoidRootPart","Humanoid","UpperTorso"}
    for i,v in pairs(parts) do
        if client.character():FindFirstChild(v) then
        else
            return false
        end
    end
    return true
end

-- * Menu setup

local menu;

if not isfile("Ratio/Configs/Autoload.cfg") then
	repeat task.wait() until load
end

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
	table.insert(scripts[scr].connections, connection:Connect(callback))
end

api.create_section = function(scr, tab, name)
	local section = menu.create_section(tab, name)
	table.insert(scripts[scr].sections, section)
	return section
end

api.flags = setmetatable({}, { __index = function() return lib.flags end })

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

-- * Menu

menu = lib.init()

local menu_autoload

lib.flags["autoloaders"] = {}

local menu_circle = menu.create_section("rage", "Aim circle")
    local menu_circle2 = menu_circle.create_element({name = "Enabled", types = {"toggle", "colorpicker"}, cdefault = Color3.fromRGB(255,0,0), flag = "circle", callback = function(f)
    end})
    local menu_filled = menu_circle.create_element({name = "Filled", types = {"toggle"}, flag = "circle_filled", callback = function(f)
    end})
    local menu_sides = menu_circle.create_element({name = "Sides", types = {"slider"}, min = 10, max = 100, sdefault = 30, flag = "circle_sides", callback = function(f)
    end})
    local menu_size = menu_circle.create_element({name = "Size", types = {"slider"}, min = 50, max = 800, sdefault = 100, flag = "circle_size", callback = function(f)
    end})

local menu_saim = menu.create_section("rage", "Silent aim")
    local menu_silentaim = menu_saim.create_element({name = "Enabled", types = {"toggle", "keybind"}, ddefault = true, flag = "silent_aim", kdefault = {["key"] = "F", ["active"] = false, ["method"] = "toggle"}, callback = function(f)
    end})

local menu_rage = menu.create_section("rage", "Other auto")
	local menu_coinaura = menu_rage.create_element({name = "Coin aura", types = {"toggle"}, flag = "coinaura", callback = function(f)
	end})

local menu_character = menu.create_section("aa", "Local character")
    local menu_walkspeed = menu_character.create_element({name = "Walk speed", types = {"toggle", "slider"}, flag = "walkspeed", min = 16, max = 100, sdefault = 16, callback = function(f)
    end})
    local menu_walkspeed = menu_character.create_element({name = "Jump power", types = {"toggle", "slider"}, flag = "jumppower", min = 50, max = 150, sdefault = 50, callback = function(f)
    end})
    local menu_spinbot = menu_character.create_element({name = "Spinbot", types = {"toggle", "slider"}, flag = "spinbot", suffix = "°", min = 1, max = 30, sdefault = 5, callback = function(f)
    end})

local menu_desync = menu.create_section("aa", "Client desync")
    local menu_denabled = menu_desync.create_element({name = "Enabled", types = {"toggle", "dropdown", "colorpicker"}, flag = "desync", ddefault = false, options = {"Randomize Angles"}, cdefault = Color3.fromRGB(255,0,0), callback = function(f)
        if cheat.desync then
            cheat.desync.Parent = lib.flags["desync"]["toggle"] and workspace or game.Lighting
            for i,v in pairs(cheat.desync:GetDescendants()) do
                if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("BasePart") then
                    v.Color = lib.flags["desync"].Color
                    v.Transparency = lib.flags["desync"].Transparency
                end
            end
        end
    end})
    local menu_danglex = menu_desync.create_element({name = "Angle X", types = {"slider"}, flag = "desync_anglex", suffix = "°", min = 1, max = 359, sdefault = 90, callback = function(f)
    end})
    local menu_dangley = menu_desync.create_element({name = "Angle Y", types = {"slider"}, flag = "desync_angley", suffix = "°", min = 1, max = 359, sdefault = 0, callback = function(f)
    end})
    local menu_danglez = menu_desync.create_element({name = "Angle Z", types = {"slider"}, flag = "desync_anglez", suffix = "°", min = 1, max = 359, sdefault = 0, callback = function(f)
    end})

local menu_eesp = menu.create_section("visuals", "Player esp")
    local menu_eenabled = menu_eesp.create_element({name = "Enabled", types = {"toggle"}, flag = "eesp", callback = function(f)
    end})
    local menu_ebox = menu_eesp.create_element({name = "Box", types = {"toggle", "colorpicker"}, flag = "ebox", cdefault = Color3.fromRGB(255,255,255), callback = function(f)
    end})
    local menu_ename = menu_eesp.create_element({name = "Name", types = {"toggle", "colorpicker"}, flag = "ename", cdefault = Color3.fromRGB(255,255,255), callback = function(f)
    end})
    local menu_echams = menu_eesp.create_element({name = "Chams", types = {"toggle", "colorpicker"}, flag = "echams", cdefault = Color3.fromRGB(255,0,0), callback = function(f)
    end})
    local menu_eoutline = menu_eesp.create_element({name = "Outline", types = {"colorpicker"}, flag = "eoutline", cdefault = Color3.fromRGB(0,0,0), callback = function(f)
    end})
    local menu_eoof = menu_eesp.create_element({name = "OOF arrow", types = {"toggle", "colorpicker", "slider"}, suffix = "px", cdefault = Color3.fromRGB(255,255,255), flag = "eoof", min = 1, max = 100, sdefault = 20, callback = function(f)
    end})
    local menu_eoof2 = menu_eesp.create_element({name = "OOF distance", types = {"slider"}, flag = "eoof2", suffix = "px", min = 1, max = 800, sdefault = 200, callback = function(f)
    end})
    local menu_efont = menu_eesp.create_element({name = "Font", types = {"dropdown"}, flag = "efont", ddefault = true, options = {"System","Plex","Monospace"}, callback = function(f)
    end})
    local menu_efont2 = menu_eesp.create_element({name = "Font size", types = {"slider"}, flag = "efont2", suffix = "px", min = 14, max = 20, sdefault = 14, callback = function(f)
    end})

local menu_sesp = menu.create_section("visuals", "Sherrif esp")
    local menu_sbox = menu_sesp.create_element({name = "Box", types = {"colorpicker"}, flag = "sbox", cdefault = Color3.fromRGB(255,0,0), callback = function(f)
    end})
    local menu_sname = menu_sesp.create_element({name = "Name", types = {"colorpicker"}, flag = "sname", cdefault = Color3.fromRGB(255,0,0), callback = function(f)
    end})
    local menu_schams = menu_sesp.create_element({name = "Chams", types = {"colorpicker"}, flag = "schams", cdefault = Color3.fromRGB(255,0,0), callback = function(f)
    end})
    local menu_soutline = menu_sesp.create_element({name = "Outline", types = {"colorpicker"}, flag = "soutline", cdefault = Color3.fromRGB(0,0,0), callback = function(f)
    end})
    local menu_soof = menu_sesp.create_element({name = "OOF arrow", types = {"colorpicker", "slider"}, suffix = "px", cdefault = Color3.fromRGB(255,0,0), flag = "soof", min = 1, max = 100, sdefault = 20, callback = function(f)
    end})
    local menu_soof2 = menu_sesp.create_element({name = "OOF distance", types = {"slider"}, flag = "soof2", suffix = "px", min = 1, max = 800, sdefault = 200, callback = function(f)
    end})
    local menu_sfont2 = menu_sesp.create_element({name = "Font size", types = {"slider"}, flag = "sfont2", suffix = "px", min = 14, max = 20, sdefault = 14, callback = function(f)
    end})

local menu_mesp = menu.create_section("visuals", "Sheriff esp")
    local menu_mbox = menu_mesp.create_element({name = "Box", types = {"colorpicker"}, flag = "mbox", cdefault = Color3.fromRGB(255,0,0), callback = function(f)
    end})
    local menu_mname = menu_mesp.create_element({name = "Name", types = {"colorpicker"}, flag = "mname", cdefault = Color3.fromRGB(255,0,0), callback = function(f)
    end})
    local menu_mchams = menu_mesp.create_element({name = "Chams", types = {"colorpicker"}, flag = "mchams", cdefault = Color3.fromRGB(255,0,0), callback = function(f)
    end})
    local menu_moutline = menu_mesp.create_element({name = "Outline", types = {"colorpicker"}, flag = "moutline", cdefault = Color3.fromRGB(0,0,0), callback = function(f)
    end})
    local menu_moof = menu_mesp.create_element({name = "OOF arrow", types = {"colorpicker", "slider"}, suffix = "px", cdefault = Color3.fromRGB(255,0,0), flag = "moof", min = 1, max = 100, sdefault = 20, callback = function(f)
    end})
    local menu_moof2 = menu_mesp.create_element({name = "OOF distance", types = {"slider"}, flag = "moof2", suffix = "px", min = 1, max = 800, sdefault = 200, callback = function(f)
    end})
    local menu_mfont2 = menu_mesp.create_element({name = "Font size", types = {"slider"}, flag = "mfont2", suffix = "px", min = 14, max = 20, sdefault = 14, callback = function(f)
    end})

local menu_hud = menu.create_section("visuals", "Game")
    local menu_fov = menu_hud.create_element({name = "Field of view", types = {"toggle", "slider"}, flag = "fieldofview", min = 70, max = 120, sdefault = 70, callback = function(f)
    end})
    local menu_toolcrosshair = menu_hud.create_element({name = "Tool crosshair", types = {"textbox"}, flag = "tool_crosshair", tdefault = "rbxasset://textures/GunCursor.png", callback = function(f)
    end})

local menu_configs = menu.create_section("settings", "Configs")
    local menu_cfg = menu_configs.create_element({name = "Config list", types = {"dropdown"}, flag = "cfg", ddefault = false, options = getConfigList(), callback = function(f)
    end})
    local menu_savecfg = menu_configs.create_element({name = "Save config", types = {"button"}, flag = "", callback = function(f)
        if lib.flags["cfg"]["option"][1] then
            lib.saveConfig(lib.flags["cfg"]["option"][1])
        end
    end})
    local menu_loadcfg = menu_configs.create_element({name = "Load config", types = {"button"}, flag = "", callback = function(f)
        if lib.flags["cfg"]["option"][1] then
            lib.loadConfig(lib.flags["cfg"]["option"][1])
			task.spawn(function()
				task.wait(0.05)
				for i,v in pairs(lib.flags["autoloaders"]) do
					loadScript(v)
				end
			end)
			if table.find(lib.flags["autoloaders"], lib.flags["script"]["option"][1]) then
				menu_autoload.set_toggle(false, false)
				table.remove(lib.flags["autoloaders"], table.find(lib.flags["autoloaders"], lib.flags["script"]["option"][1]))
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

local menu_scripting = menu.create_section("lua", "Scripting")
	local menu_script = menu_scripting.create_element({name = "Script list", types = {"dropdown"}, flag = "script", ddefault = false, options = getScriptList(), callback = function(f)
		if table.find(lib.flags["autoloaders"], lib.flags["script"]["option"][1]) then
			menu_autoload.set_toggle(true, false)
		else
			menu_autoload.set_toggle(false, false)
		end
	end})
	menu_autoload = menu_scripting.create_element({name = "Auto load", types = {"toggle"}, flag = "autoload", callback = function(f)
		if table.find(lib.flags["autoloaders"], lib.flags["script"]["option"][1]) then
			menu_autoload.set_toggle(false, false)
			table.remove(lib.flags["autoloaders"], table.find(lib.flags["autoloaders"], lib.flags["script"]["option"][1]))
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

-- * Menu final

if isfile("Ratio/Configs/Autoload.cfg") then
    local str = "Ratio/Configs/Autoload.cfg"
    local newStr = string.sub(str, 15, #str-4)

    local ScreenGui = Instance.new("ScreenGui")
    local Autoload = Instance.new("Frame")
    local LoadLabel = Instance.new("TextLabel")
    local cancel = false

    ScreenGui.Parent = gethui and gethui() or game.CoreGui
    if syn then
        syn.protect_gui(ScreenGui)
    end
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    Autoload.Name = "Autoload"
    Autoload.Parent = ScreenGui
    Autoload.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
    Autoload.BackgroundTransparency = 0.800
    Autoload.Position = UDim2.new(0.5, -130, 0.5, -13)
    Autoload.Size = UDim2.new(0, 260, 0, 26)
    Autoload.ZIndex = 15

    LoadLabel.Name = "LoadLabel"
    LoadLabel.Parent = Autoload
    LoadLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    LoadLabel.BackgroundTransparency = 1.000
    LoadLabel.Size = UDim2.new(1, 0, 1, 0)
    LoadLabel.Font = Enum.Font.SourceSans
    LoadLabel.Text = "CLICK TO CANCEL AUTOLOAD (3)"
    LoadLabel.TextColor3 = Color3.fromRGB(238, 238, 238)
    LoadLabel.TextSize = 16.000
    LoadLabel.TextStrokeTransparency = 0.500
    LoadLabel.TextWrapped = true
    LoadLabel.ZIndex = 16

    LoadLabel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            cancel = true
            ScreenGui:Destroy()
        end
    end)

    task.spawn(function()
        for i = 1, 5 do
            task.wait(1)
            LoadLabel.Text = "CLICK TO CANCEL AUTOLOAD ("..tostring(4-i)..")"
            if i == 5 then
                break
            end
        end

        if ScreenGui then
            ScreenGui:Destroy()
        end

        if not cancel then
            lib.loadConfig(newStr)
			task.wait(0.05)
			for i,v in pairs(lib.flags["autoloaders"]) do
				loadScript(v)
			end
        end
    end)
end

-- * Metamethods

LPH_JIT_MAX(function()
    local old_index = nil
    old_index = hookmetamethod(game, "__index", function(self, index)
        if not checkcaller() and index == "CFrame" and lib.flags["desync"]["toggle"] and tostring(self) == "HumanoidRootPart" and self:IsDescendantOf(client.character()) then
            return cheat.oldcf
        end
        return old_index(self, index)
    end)
end)()

LPH_JIT_MAX(function()
	local old_namecall = nil
	old_namecall = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
		local script = getcallingscript()
		if checkcaller() and method == "GetService" and args[1] == "Ratio" then
			return api
		elseif not checkcaller() and self == workspace and method == "FindPartOnRayWithIgnoreList" and script.Parent.ClassName == "Tool" then
			if cheat.desync then
				table.insert(args[2], cheat.desync)
			end
			if lib.flags["silent_aim"]["toggle"] and menu_silentaim:get_active() and cheat.target ~= nil then
                local camera = workspace.CurrentCamera.CFrame.p
                local pos = cheat.target.Position
				local vel = cheat.target.Velocity

				if script.Parent.Name == "Gun" then
                	args[1] = Ray.new(camera, ((pos + Vector3.new(0,(camera-pos).Magnitude/150,0) - camera).unit * (150 * 10)))
				else
					args[1] = Ray.new(camera, (((pos + vel/7) + Vector3.new(0,(camera-(pos + vel/7)).Magnitude/150,0) - camera).unit * (150 * 10)))
				end
			end
			return old_namecall(self, unpack(args))
		end
		return old_namecall(self, ...)
	end)
end)()

-- * Connections

cheat = {murderer = nil, sheriff = nil, connections = {}, coins = nil, desync = nil, oldcf = CFrame.new(), target = nil}

function cheat:create_body(char)
    char.Archivable = true
    local clone = char:Clone()
    for i,v in pairs(clone:GetChildren()) do
        if v:IsA("BasePart") then
            v.Anchored = true
            v.CanCollide = false
            v.Material = Enum.Material.ForceField
		else
			v:Destroy()
        end
    end
    clone.Name = "\\"
    clone.Parent = lib.flags["desync"]["toggle"] and workspace or game.Lighting
    clone.PrimaryPart = clone.HumanoidRootPart
    for i,v in pairs(clone:GetChildren()) do
        v.Color = lib.flags["desync"].Color
        v.Transparency = lib.flags["desync"].Transparency
    end
    return clone
end

function cheat:add_connection(connection, callback)
    local connection = connection:Connect(callback)
    table.insert(cheat.connections, connection)
    return connection
end

function cheat:setup_player(player)
	local character = player.Character or nil
	local backpack = player:WaitForChild("Backpack")
	backpack.ChildAdded:Connect(function(tool)
		if tool.Name == "Gun" then
			cheat.sheriff = player
		elseif tool.Name == "Knife" then
			cheat.murderer = player
		end
	end)
	player.CharacterAdded:Connect(function(char)
		character = char
		backpack = player:WaitForChild("Backpack")
		if cheat.sheriff == player then
			cheat.sheriff = nil
		elseif cheat.murderer == player then
			cheat.murderer = nil
		end
		backpack.ChildAdded:Connect(function(tool)
			if tool.Name == "Gun" then
				cheat.sheriff = player
			elseif tool.Name == "Knife" then
				cheat.murderer = player
			end
		end)
	end)
end

function cheat:get_in_circle(part)
	local i, v = workspace.CurrentCamera:WorldToScreenPoint(part.Position)
	if v and (client.character().HumanoidRootPart.Position-part.Position).magnitude < 220 then
		local m = (Vector2.new(client.mouse.X, client.mouse.Y) - Vector2.new(i.X, i.Y)).magnitude
		local max = lib.flags["circle"]["toggle"] and lib.flags["circle_size"]["value"] or 1800
		if m <= max then
			return true
		end
	end
end

function cheat:get_closest()
	local closest = 9e9
	local target = nil
	if client.character():FindFirstChild("HumanoidRootPart") then
		for _, player in next, services.Players:GetPlayers() do
			if player ~= client.plr and player.Character then
				local hum = player.Character:FindFirstChild("Humanoid")
				local hrp = player.Character:FindFirstChild("HumanoidRootPart")
				if hrp and hum then
					local i, v = workspace.CurrentCamera:WorldToScreenPoint(hrp.Position)
					if v and (client.character().HumanoidRootPart.Position-hrp.Position).magnitude < 220 then
						local max = (Vector2.new(client.mouse.X, client.mouse.Y) - Vector2.new(i.X, i.Y)).magnitude
						local threshold = lib.flags["circle_size"]["value"]
						local checks = #workspace.CurrentCamera:GetPartsObscuringTarget({client.character().HumanoidRootPart.Position, hrp.Position}, {workspace.CurrentCamera, client.character(), player.Character}) == 0
						if max < closest and max <= threshold and checks then
							target = player
							closest = max
						end
					end
				end
			end
		end
	end
	return target
end

function cheat:add_esp(player)
	LPH_JIT_MAX(function()
		local esp = {
			drawings = {},
			highlight = nil
		}

		esp.highlight = Instance.new("Highlight")
		esp.highlight.Parent = game.CoreGui
		esp.highlight.Enabled = false
		esp.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		esp.highlight.Name = player.Name
		
		do
			esp.drawings.box = Drawing.new("Square")
			esp.drawings.box.Filled = false
			esp.drawings.box.Thickness = 1
			esp.drawings.box.Visible = false
			esp.drawings.box.ZIndex = 2
			esp.drawings.outline = Drawing.new("Square")
			esp.drawings.outline.Filled = false
			esp.drawings.outline.Color = Color3.fromRGB(0,0,0)
			esp.drawings.outline.Thickness = 3
			esp.drawings.outline.Visible = false
			esp.drawings.outline.ZIndex = 1
			esp.drawings.name = Drawing.new("Text")
			esp.drawings.name.Size = 14
			esp.drawings.name.Center = true
			esp.drawings.name.Outline = true
			esp.drawings.name.Font = Drawing.Fonts.Plex
			esp.drawings.name.Visible = false
			esp.drawings.name.ZIndex = 3
			esp.drawings.triangle = Drawing.new("Triangle")
			esp.drawings.triangle.Thickness = 1
			esp.drawings.triangle.Visible = false
			esp.drawings.triangle.ZIndex = 2
			esp.drawings.triangle.Filled = true
		end

		function esp:destroy()
			esp.connection:Disconnect()
			for i,v in pairs(esp.drawings) do
				v:Remove()
			end
			esp.highlight.Adornee = nil
			esp.highlight:Destroy()
		end

		esp.connection = cheat:add_connection(services.RunService.RenderStepped, function()
			if player.Parent ~= nil then
				for i,v in pairs(esp.drawings) do
					v.Visible = false
				end
				esp.highlight.Enabled = false
				if lib.flags["eesp"]["toggle"] then
					local char = player.Character
					if char then
						local s = cheat.sheriff
						local m = cheat.murderer
						local torso = char:FindFirstChild("HumanoidRootPart")
                        if torso and client.loaded() and (torso.Position-client.character().HumanoidRootPart.Position).magnitude < 400 then
                            local pos, visible = workspace.CurrentCamera:WorldToViewportPoint(torso.Position)
                            if visible then
                                local size = (workspace.CurrentCamera:WorldToViewportPoint(torso.Position - Vector3.new(0, 3.3, 0)).Y - workspace.CurrentCamera:WorldToViewportPoint(torso.Position + Vector3.new(0, 2.9, 0)).Y) / 2
                                local box_size = Vector2.new(math.floor(size * 1.5), math.floor(size * 1.9))
                                local box_pos = Vector2.new(math.floor(pos.X - size * 1.5 / 2), math.floor(pos.Y - size * 1.6 / 2))
                                local font = #lib.flags["efont"]["option"] == 1 and lib.flags["efont"]["option"][1] or "UI"

                                if lib.flags["echams"]["toggle"] then
                                    esp.highlight.Enabled = true
                                    esp.highlight.Adornee = char
                                    esp.highlight.FillColor = ((m == player and lib.flags["mchams"].Color) or (s == player and lib.flags["schams"].Color) or lib.flags["echams"].Color)
                                    esp.highlight.OutlineColor = ((m == player and lib.flags["moutline"].Color) or (s == player and lib.flags["soutline"].Color) or lib.flags["eoutline"].Color)
                                    esp.highlight.FillTransparency = ((m == player and lib.flags["mchams"].Transparency) or (s == player and lib.flags["schams"].Transparency) or lib.flags["echams"].Transparency)
                                    esp.highlight.OutlineTransparency = ((m == player and lib.flags["moutline"].Transparency) or (s == player and lib.flags["soutline"].Transparency) or lib.flags["eoutline"].Transparency)
                                end

                                if lib.flags["ebox"]["toggle"] then
                                    esp.drawings.box.Visible = true
                                    esp.drawings.box.Size = box_size
                                    esp.drawings.box.Position = box_pos
                                    esp.drawings.box.Color = ((m == player and lib.flags["mbox"].Color) or (s == player and lib.flags["sbox"].Color) or lib.flags["ebox"].Color)
                                    esp.drawings.box.Transparency =	((m == player and -lib.flags["mbox"].Transparency+1) or (s == player and -lib.flags["sbox"].Transparency+1) or -lib.flags["ebox"].Transparency+1)
                                    esp.drawings.outline.Transparency = ((m == player and -lib.flags["mbox"].Transparency+1) or (s == player and -lib.flags["sbox"].Transparency+1) or -lib.flags["ebox"].Transparency+1)
                                    esp.drawings.outline.Size = box_size
                                    esp.drawings.outline.Position = box_pos
                                    esp.drawings.outline.Visible = true
                                end

                                if lib.flags["ename"]["toggle"] then
                                    esp.drawings.name.Text = player.Name 
                                    esp.drawings.name.Position = Vector2.new(box_size.X / 2 + box_pos.X, box_pos.Y - esp.drawings.name.TextBounds.Y - 1)
                                    esp.drawings.name.Color = ((m == player and lib.flags["mname"].Color) or (s == player and lib.flags["sname"].Color) or lib.flags["ename"].Color)
                                    esp.drawings.name.Transparency = ((m == player and -lib.flags["mname"].Transparency+1) or (s == player and -lib.flags["sname"].Transparency+1) or -lib.flags["ename"].Transparency+1)
                                    esp.drawings.name.Font = Drawing.Fonts[font]
                                    esp.drawings.name.Size = ((m == player and lib.flags["mfont2"]["value"]) or (s == player and lib.flags["sfont2"]["value"]) or lib.flags["efont2"]["value"])
                                    esp.drawings.name.Visible = true
                                end
                            else
                                if lib.flags["eoof"]["toggle"] then
                                    local screen_size = workspace.CurrentCamera.ViewportSize
                                    esp.drawings.triangle.Visible = true
                                    local camCf = workspace.CurrentCamera.CFrame
                                    camCf = CFrame.lookAt(camCf.p, camCf.p + camCf.LookVector * Vector3.new(1, 0, 1))
                    
                                    local projected = camCf:PointToObjectSpace(torso.Position)
                                    local angle = math.atan2(projected.z, projected.x)
                    
                                    local cx, sy = math.cos(angle), math.sin(angle)
                                    local cx1, sy1 = math.cos(angle + math.pi/2), math.sin(angle + math.pi/2)
                                    local cx2, sy2 = math.cos(angle + math.pi/2*3), math.sin(angle + math.pi/2*3)
                    
                                    local viewport = screen_size
                    
                                    local big, small = math.max(viewport.x, viewport.y), math.min(viewport.x, viewport.y)

									local value = ((m == player and lib.flags["moof"]["value"]/100) or (s == player and lib.flags["soof"]["value"]/100) or lib.flags["eoof"]["value"]/100)
                    
                                    local arrowOrigin = viewport/2 + Vector2.new(cx * big * 75/200, sy * small * 75/200) * ((m == player and lib.flags["moof2"]["value"]/1000) or (s == player and lib.flags["soof2"]["value"]/1000) or lib.flags["eoof2"]["value"]/1000)
                    
                                    esp.drawings.triangle.PointA = arrowOrigin + Vector2.new(30 * cx, 30 * sy) *  value
                                    esp.drawings.triangle.PointB = arrowOrigin + Vector2.new(15 * cx1, 15 * sy1) *  value
                                    esp.drawings.triangle.PointC = arrowOrigin + Vector2.new(15 * cx2, 15 * sy2) * value
                                    esp.drawings.triangle.Color = ((m == player and lib.flags["moof"].Color) or (s == player and lib.flags["soof"].Color) or lib.flags["eoof"].Color)
                                    esp.drawings.triangle.Transparency = ((m == player and -lib.flags["moof"].Transparency+1) or (s == player and -lib.flags["soof"].Transparency+1) or -lib.flags["eoof"].Transparency+1)
                                end
                            end
                        end
					else
						for i,v in pairs(esp.drawings) do
							v.Visible = true
							v.Transparency = v.Transparency - .0831314
						end
					end
				end
			else
				esp:destroy()
			end
		end)
	end)()
end

cheat:add_connection(client.plr.CharacterAdded, function(char)
    if cheat.desync then
        cheat.desync:Destroy()
    end
    repeat task.wait() until client.loaded()
    cheat.desync = cheat:create_body(char)
end)

for i,v in pairs(services.Players:GetPlayers()) do
    if v ~= client.plr then
	    cheat:add_esp(v)
        cheat:setup_player(v)
    end
end

cheat:add_connection(services.Players.PlayerAdded, function(player)
	cheat:add_esp(player)
    cheat:setup_player(player)
end)

cheat:add_connection(workspace.DescendantAdded, function(part)
	if part.Name == "CoinContainer" then
		cheat.coins = part
	end
end)

if client.loaded() then
    cheat.desync = cheat:create_body(client.character())
end

local circle = Drawing.new("Circle")
circle.NumSides = 24
circle.Visible = false
circle.Filled = false
circle.Thickness = 2

LPH_JIT_MAX(function()
	cheat:add_connection(services.RunService.Heartbeat, function()
		if client.loaded() then
			cheat.target = nil
			local tool = client.character():FindFirstChildOfClass("Tool")
			client.character().Humanoid.AutoRotate = not lib.flags["spinbot"]["toggle"]
			workspace.CurrentCamera.FieldOfView = lib.flags["fieldofview"]["toggle"] and lib.flags["fieldofview"]["value"] or 70
			if lib.flags["spinbot"]["toggle"] then
				client.character().HumanoidRootPart.CFrame = client.character().HumanoidRootPart.CFrame * CFrame.Angles(0,math.rad(lib.flags["spinbot"]["value"]),0)
			end
			if tool and client.mouse.Icon ~= lib.flags["tool_crosshair"]["text"] then
				client.mouse.Icon = lib.flags["tool_crosshair"]["text"]
			elseif not tool and client.mouse.Icon == lib.flags["tool_crosshair"]["text"] then
				client.mouse.Icon = ""
			end
			circle.NumSides = lib.flags["circle_sides"]["value"]
			circle.Filled = lib.flags["circle_filled"]["toggle"] and true or false
			circle.Color = lib.flags["circle"].Color
			circle.Transparency = -lib.flags["circle"].Transparency+1
			circle.Radius = lib.flags["circle_size"]["value"]
			circle.Position = Vector2.new(client.mouse.X, client.mouse.Y + 36)
			circle.Visible = (lib.flags["silent_aim"]["toggle"] and lib.flags["circle"]["toggle"]) and menu_silentaim.get_active() or false
			if tool and (tool.Name == "Gun" or tool.Name == "Knife") and circle.Visible then
				local m = cheat.murderer
				if tool.Name == "Gun" and m and m.Character and m.Character:FindFirstChild("HumanoidRootPart") then
					local visible = #workspace.CurrentCamera:GetPartsObscuringTarget({client.character().HumanoidRootPart.Position, m.Character:FindFirstChild("HumanoidRootPart").Position}, {workspace.CurrentCamera, client.character(), m.Character}) == 0
					if visible and cheat:get_in_circle(m.Character.HumanoidRootPart) then
						cheat.target = m.Character:FindFirstChild("HumanoidRootPart")
					end
				elseif tool.Name == "Knife" then
					local closest = cheat:get_closest()
					if closest then
						cheat.target = closest.Character.HumanoidRootPart
					end
				end
			end
			if lib.flags["coinaura"]["toggle"] and cheat.coins then
				for i,v in pairs(cheat.coins:GetChildren()) do
					if (v.Position-client.character().UpperTorso.Position).magnitude < 14 then
						firetouchinterest(client.character().UpperTorso, v, 0)
						firetouchinterest(client.character().UpperTorso, v, 1)
					end
				end
			end
		end
	end)

	cheat:add_connection(services.RunService.Heartbeat, function()
		if client.loaded() and lib.flags["desync"]["toggle"] and cheat.desync then
			local old = client.character().HumanoidRootPart.CFrame
			local ca = CFrame.Angles(math.rad(lib.flags["desync_anglex"]["value"]),math.rad(lib.flags["desync_angley"]["value"]),math.rad(lib.flags["desync_anglez"]["value"]))
			if #lib.flags["desync"]["option"] == 1 then
				ca = CFrame.Angles(math.rad(math.random(360)),math.rad(math.random(360)),math.rad(math.random(360)))
			end
			local new = old * ca
			client.character().HumanoidRootPart.CFrame = new
			cheat.desync:SetPrimaryPartCFrame(new)
			cheat.oldcf = old
			services.RunService.RenderStepped:Wait()
			client.character().HumanoidRootPart.CFrame = old
		end
	end)
end)()
