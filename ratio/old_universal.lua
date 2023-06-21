if lgTagsTbl then
    if not table.find(lgTagsTbl, 'Tester') then
        while true do end
    end
end
local services = setmetatable({}, { __index = function(self, key) return game:GetService(key) end })

local lib = {handler = {}, flags = {}, copied_color = {}}

lib.copied_color["color"] = Color3.fromRGB(255,255,255)
lib.copied_color["transparency"] = 0

LPH_JIT = function(...) return ... end 
LPH_JIT_MAX = function(...) return ... end
LPH_NO_VIRTUALIZE = function(...) return ... end
LPH_HOOK_FIX = function(...) return ... end
LPH_NO_UPVALUES= function(...) return ... end

lib.handler.custom_properties = {
	["TextOutline"] = function(textlabel)
		local clone = textlabel:Clone()
		clone.TextColor3 = textlabel.TextColor3
		clone.Position = UDim2.new(0, -1, 0, -1)
		textlabel.Position = UDim2.new(textlabel.Position.X.Scale, textlabel.Position.X.Offset + 1, textlabel.Position.Y.Scale, textlabel.Position.Y.Offset + 1)
		clone.Parent = textlabel
		textlabel.TextColor3 = Color3.fromRGB(0,0,0)
	end,
	["Randomize"] = function(element)
		element.Name = game:GetService("HttpService"):GenerateGUID(false)
	end,
}

local function is_in_frame(frame)
    local y = frame.AbsolutePosition.Y <= game.Players.LocalPlayer:GetMouse().Y and game.Players.LocalPlayer:GetMouse().Y <= frame.AbsolutePosition.Y + frame.AbsoluteSize.Y
    local x = frame.AbsolutePosition.X <= game.Players.LocalPlayer:GetMouse().X and game.Players.LocalPlayer:GetMouse().X <= frame.AbsolutePosition.X + frame.AbsoluteSize.X

	return (y and x)
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

function lib:rgbToHex(r,g,b)
	local rgb = (r * 0x10000) + (g * 0x100) + b
	return string.format("%x", rgb)
end

function lib:hex2rgb(hex)
	hex = hex:gsub("#","")
	return Color3.fromRGB(tonumber("0x"..hex:sub(1,2))*255, tonumber("0x"..hex:sub(3,4))*255, tonumber("0x"..hex:sub(5,6))*255)
end

lib.signal = loadstring(game:HttpGet("https://raw.githubusercontent.com/Quenty/NevermoreEngine/version2/Modules/Shared/Events/Signal.lua"))()
lib.onConfigLoaded = lib.signal.new("onConfigLoaded")
lib.onConfigSaved = lib.signal.new("onConfigSaved")
lib.onClick = lib.signal.new("onClick")

services.UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		lib.onClick:Fire()
	end
end)

_G.threw_knife_signal = lib.signal.new("threw_knife")

lib.handle_custom_properties = function(element, custom_properties)
	for i = 1, #custom_properties do
		local prop = custom_properties[i]
		local func = lib.handler.custom_properties[prop]
		func(element)
	end
end

lib.before_creation = {
	["ScreenGui"] = function(element, custom_properties)
		if syn and syn.protect_gui then syn.protect_gui(element) end
		element.Parent = gethui and gethui() or game:GetService("CoreGui")
	end
}

function lib:create_element(class, properties, custom_properties)
	local element = Instance.new(class)

	if lib.before_creation[class] then lib.before_creation[class](element, custom_properties) end

	for property, value in pairs(properties) do
		element[property] = value
	end

	lib.handle_custom_properties(element, custom_properties)

	return element
end

function lib:tween(...)
	game:GetService("TweenService"):Create(...):Play()
end

function lib:get_table_length(t)
	local count = 0
	for _, v in pairs(t) do
		count = count + 1
	end
	return count
end

function lib:set_draggable(frame)
	local dragging
	local dragInput
	local dragStart
	local startPos

	local function update(input)
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	frame.InputBegan:Connect(function(input)
		if not lib.busy and input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	frame.InputChanged:Connect(function(input)
		if not lib.busy and input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	game:GetService("UserInputService").InputChanged:Connect(function(input)
		if not lib.busy and input == dragInput and dragging then
			update(input)
		end
	end)
end

if not isfolder("eunoia") then
	makefolder("eunoia")
end

if not isfolder("eunoia/configs") then
	makefolder("eunoia/configs")
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

lib.loadConfig = function(cfgName, old2)
	LPH_JIT_MAX(function()
		local new_values = game.HttpService:JSONDecode(dec(readfile("eunoia/configs/"..cfgName..".cfg")))

		for i,element in pairs(new_values) do
			if typeof(element) == "table" and element["color"] then
				element["color"] = Color3.new(element["color"].R, element["color"].G, element["color"].B)
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
			if typeof(element) == "table" and element["color"] then
				element["color"] = {R = element["color"].R, G = element["color"].G, B = element["color"].B}
			end
		end

		if not old then
			task.spawn(function()
				task.wait()
				lib.onConfigSaved:Fire()
			end)
			writefile("eunoia/configs/"..cfgName..".cfg",enc(game.HttpService:JSONEncode(values_copy)))
		else
			return game.HttpService:JSONEncode(values_copy)
		end
	end)()
end

function lib:create_window()
	local main = lib:create_element("ScreenGui", {
		Name = "Main";
		ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Global;
	}, {"Randomize"})

	local border = lib:create_element("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0);
		BorderSizePixel = 0;
		Position = UDim2.new(0, 0, 0, 0);
		Size = UDim2.new(0, 680, 0, 520);
		Parent = main;
	}, {"Randomize"})
	
	lib:set_draggable(border)

	local corner = lib:create_element("UICorner", {
		Parent = border;
		CornerRadius = UDim.new(0, 8)
	}, {"Randomize"})

	local bg = lib:create_element("Frame", {
		BackgroundColor3 = Color3.fromRGB(21.000000648200512, 21.000000648200512, 21.000000648200512);
		BorderSizePixel = 0;
		Position = UDim2.new(0, 1, 0, 1);
		Size = UDim2.new(1, -2, 1, -2);
		Parent = border;
	}, {"Randomize"})
	
	local corner = lib:create_element("UICorner", {
		Parent = bg;
		CornerRadius = UDim.new(0, 8)
	}, {"Randomize"})
	
	local topbar = lib:create_element("Frame", {
		BackgroundColor3 = Color3.fromRGB(41.00000135600567, 41.00000135600567, 41.00000135600567);
		BorderSizePixel = 0;
		Size = UDim2.new(1, 0, 0, 21);
		Parent = bg;
	}, {"Randomize"})

	local corner3 = lib:create_element("UICorner", {
		Parent = topbar;
	}, {"Randomize"})

	local topfitter = lib:create_element("Frame", {
		BackgroundColor3 = Color3.fromRGB(41.00000135600567, 41.00000135600567, 41.00000135600567);
		BorderSizePixel = 0;
		Position = UDim2.new(0, 0, 0, 6);
		Size = UDim2.new(1, 0, 0, 15);
		Parent = topbar;
	}, {"Randomize"})

	local topdivider = lib:create_element("Frame", {
		BackgroundColor3 = Color3.fromRGB(194.00000363588333, 155.00000596046448, 165.00000536441803);
		BorderSizePixel = 0;
		Position = UDim2.new(0, 0, 1, 0);
		Size = UDim2.new(1, 0, 0, 1);
		Parent = topfitter
	}, {"Randomize"})

	local toplabel = lib:create_element("TextLabel", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255);
		BackgroundTransparency = 1;
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = 3;
		Font = Enum.Font.Arial;
		FontFace = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
		Text = "eunoia";
		TextColor3 = Color3.fromRGB(201.00000321865082, 201.00000321865082, 201.00000321865082);
		TextSize = 14;
		Parent = topbar;
	}, {"Randomize", "TextOutline"})

	local leftbar = lib:create_element("Frame", {
		BackgroundColor3 = Color3.fromRGB(31, 31, 31);
		BorderSizePixel = 0;
		Size = UDim2.new(0, 120, 1, -77);
		Position = UDim2.new(0, 0, 0, 22);
		Parent = bg;
	}, {"Randomize"})

	local icon = lib:create_element("ImageLabel", {
		BackgroundTransparency = 1.000;
		BorderSizePixel = 0;
		Size = UDim2.new(0, 100, 0, 100);
		Position = UDim2.new(0, 10, 0, 2);
		Image = "http://www.roblox.com/asset/?id=12406678217";
		Parent = leftbar;
	}, {"Randomize"})

	local bottombar = lib:create_element("Frame", {
		BackgroundColor3 = Color3.fromRGB(41, 41, 41);
		BorderSizePixel = 0;
		Position = UDim2.new(0, 0, 1, -54);
		Size = UDim2.new(1, 0, 0, 54);
		Parent = bg
	}, {"Randomize"})
	
	local corner = lib:create_element("UICorner", {
		Parent = bottombar;
		CornerRadius = UDim.new(0, 8)
	}, {"Randomize"})

	local bottomdivider = lib:create_element("Frame", {
		BackgroundColor3 = Color3.fromRGB(194, 155, 165);
		BorderSizePixel = 0;
		Position = UDim2.new(0, 0, 0, -1);
		Size = UDim2.new(1, 0, 0, 1);
		Parent = bottombar
	}, {"Randomize"})

	local barholder = lib:create_element("Frame", {
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 0, 1, -54);
		Size = UDim2.new(1, 0, 0, 54);
		Parent = bottombar
	}, {"Randomize"})
	
	local corner = lib:create_element("UICorner", {
		Parent = barholder;
		CornerRadius = UDim.new(0, 8)
	}, {"Randomize"})
	
	local Frame123 = Instance.new("Frame", bottombar)
	Frame123.BackgroundColor3 = Color3.fromRGB(41.00000135600567, 41.00000135600567, 41.00000135600567);
	Frame123.BorderSizePixel = 0;
	Frame123.Position = UDim2.new(1, -15, 0, 0);
	Frame123.Size = UDim2.new(0, 15, 0, 15);
	
	local Frame123 = Instance.new("Frame", bottombar)
	Frame123.BackgroundColor3 = Color3.fromRGB(41.00000135600567, 41.00000135600567, 41.00000135600567);
	Frame123.BorderSizePixel = 0;
	Frame123.Position = UDim2.new(0, 0, 0, 0);
	Frame123.Size = UDim2.new(0, 15, 0, 15);

	local uilistlayout = lib:create_element("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal;
		HorizontalAlignment = Enum.HorizontalAlignment.Center;
		SortOrder = Enum.SortOrder.LayoutOrder;
		VerticalAlignment = Enum.VerticalAlignment.Center;
		Padding = UDim.new(0, 3);
		Parent = barholder
	}, {"Randomize"})
	
	local window = {
		tabs = {},
		active_tab = "",
		hotkey = "leftalt"
	}
	
	game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
		if gpe then return end
		
		if string.lower(input.KeyCode.Name) == window.hotkey then
			main.Enabled = not main.Enabled
		end
	end)
	
	function window:create_tab(args)
		local name = args["name"]
		local icon = args["icon"]
		
		local tab = {
			subtabs = {},
			active_subtab = ""
		}
		
		window.tabs[name] = tab
		
		local tab_button = lib:create_element("Frame", {
			BackgroundColor3 = Color3.fromRGB(31, 31, 31);
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new(0, 54, 0, 54);
			Parent = barholder,
			ClipsDescendants = true;
		}, {"Randomize"})
		local tab_wash = lib:create_element("Frame", {
			BackgroundColor3 = Color3.fromRGB(31, 31, 31);
			BorderSizePixel = 0;
			Size = UDim2.new(1, 0, 0, 54);
			Position = UDim2.new(0, 0, 0, 54);
			Parent = tab_button
		}, {"Randomize"})
		local button_line = lib:create_element("Frame", {
			BackgroundColor3 = Color3.fromRGB(194, 155, 165);
			BorderSizePixel = 0;
			Position = UDim2.new(0, 0, 1, -3);
			Size = UDim2.new(1, 0, 0, 3);
			Parent = tab_button
		}, {"Randomize"})
		local button_name = lib:create_element("TextLabel", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255);
			BackgroundTransparency = 1.000;
			Position = UDim2.new(0, 0, 0, -12);
			Size = UDim2.new(1, 0, 1, 0);
			Font = Enum.Font.Arial;
			Text = name;
			TextColor3 = Color3.fromRGB(201, 201, 201);
			TextSize = 14.000;
			Parent = button_line
		}, {"Randomize", "TextOutline"}); button_name = button_name:FindFirstChildOfClass("TextLabel")
		local button_image = lib:create_element("ImageLabel", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255);
			BackgroundTransparency = 1.000;
			Position = UDim2.new(0.5, -11, 0, -30);
			Size = UDim2.new(0, 22, 0, 22);
			Image = icon;
			ImageColor3 = Color3.fromRGB(201, 201, 201);
			Parent = button_name
		}, {"Randomize"})
		local tabbar = lib:create_element("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255);
			BackgroundTransparency = 1.000;
			Position = UDim2.new(0, 0, 0, 105);
			Size = UDim2.new(1, 0, 1, -150);
			Parent = leftbar;
			Visible = false
		}, {"Randomize"})
		local UIListLayout = lib:create_element("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder;
			Padding = UDim.new(0, 5);
			Parent = tabbar;
		}, {"Randomize"})
		local tabframe = lib:create_element("Frame", {
			BackgroundTransparency = 1.000;
			Position = UDim2.new(0, 136, 0, 38);
			Size = UDim2.new(1, -152, 1, -108);
			Parent = bg;
		}, {"Randomize"})

		
		function tab:set_active(bool)
			lib:tween(button_line, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = bool and 0 or 1})
			lib:tween(button_name, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = bool and Color3.fromRGB(201, 201, 201) or Color3.fromRGB(141,141,141)})
			lib:tween(button_image, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageColor3 = bool and Color3.fromRGB(201, 201, 201) or Color3.fromRGB(141,141,141)})
			lib:tween(tab_wash, TweenInfo.new(0.31, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = bool and UDim2.new(0, 0, 0, 0) or UDim2.new(0, 0, 0, 54)})
			tabbar.Visible = bool
			tabframe.Visible = bool
			if bool then
				window.active_tab = name
			end
		end
		
		function tab:on_highlight(bool)
			if not bool then
				lib:tween(button_line, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5})
				lib:tween(button_name, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(180, 180, 180)})
				lib:tween(button_image, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(180, 180, 180)})
			end
		end
		
		function tab:on_leave(bool)
			if not bool then
				lib:tween(button_line, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
				lib:tween(button_name, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(141,141,141)})
				lib:tween(button_image, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(141,141,141)})
			end
		end
		
		tab_button.MouseEnter:Connect(function()
			tab:on_highlight(window.active_tab == name)
		end)
		
		tab_button.MouseLeave:Connect(function()
			tab:on_leave(window.active_tab == name)
		end)
		
		tab_button.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and window.active_tab ~= name and not lib.busy then
				window.tabs[window.active_tab]:set_active(false)
				tab:set_active(true)
			end
		end)
		
		tab:set_active(lib:get_table_length(window.tabs) == 1)
		
		function tab:create_subtab(args)
			local name = args["name"]
			local icon = args["icon"]
		
			local subtab = lib:create_element("Frame", {
				BackgroundColor3 = Color3.fromRGB(26, 26, 26);
				BackgroundTransparency = 1;
				BorderSizePixel = 0;
				Position = UDim2.new(0, 0, 0, 105);
				Size = UDim2.new(1, 0, 0, 34);
				Parent = tabbar;
			}, {"Randomize"})
			local fillbar = lib:create_element("Frame", {
				BackgroundColor3 = Color3.fromRGB(26, 26, 26);
				BorderSizePixel = 0;
				Size = UDim2.new(0, 0, 1, 0);
				Parent = subtab;
			}, {"Randomize"})
			local barleft = lib:create_element("Frame", {
				BackgroundColor3 = Color3.fromRGB(194, 155, 165);
				BorderSizePixel = 0;
				Size = UDim2.new(0, 2, 1, 0);
				Parent = subtab;
			}, {"Randomize"})
			local sublabel = lib:create_element("TextLabel", {
				BackgroundTransparency = 1.000;
				Position = UDim2.new(0, 10, 0, 0);
				Size = UDim2.new(0, 80, 1, 0);
				Font = Enum.Font.Arial;
				Text = name;
				TextColor3 = Color3.fromRGB(201, 201, 201);
				TextSize = 14.000;
				TextXAlignment = Enum.TextXAlignment.Left;
				Parent = subtab
			}, {"Randomize", "TextOutline"}); sublabel = sublabel:FindFirstChildOfClass("TextLabel")
			local subtabframe = lib:create_element("ScrollingFrame", {
				Active = true;
				BackgroundColor3 = Color3.fromRGB(255, 255, 255);
				BackgroundTransparency = 1.000;
				BorderSizePixel = 0;
				Size = UDim2.new(1, 0, 1, 0);
				BottomImage = "http://www.roblox.com/asset/?id=1195495135";
				CanvasSize = UDim2.new(0, 0, 1, 0);
				MidImage = "http://www.roblox.com/asset/?id=1195495135";
				ScrollBarThickness = 2;
				ScrollingEnabled = false;
				TopImage = "http://www.roblox.com/asset/?id=1195495135";
				Parent = tabframe
			}, {"Randomize"})
			local left = lib:create_element("Frame", {
				BackgroundTransparency = 1.000;
				Size = UDim2.new(0.5, -8, 1, 0);
				Parent = subtabframe
			}, {"Randomize"})
			local right = lib:create_element("Frame", {
				BackgroundTransparency = 1.000;
				Size = UDim2.new(0.5, -8, 1, 0);
				Position = UDim2.new(1, -255, 0, 0);
				Parent = subtabframe
			}, {"Randomize"})
			local UIListLayout = lib:create_element("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder;
				Padding = UDim.new(0, 16);
				Parent = left
			}, {"Randomize"})
			local UIListLayout2 = lib:create_element("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder;
				Padding = UDim.new(0, 16);
				Parent = right
			}, {"Randomize"})
			
			local sub_tab = {active_subtab = "", sections = {}, left_size = 0, right_size = 0}
			
			tab.subtabs[name] = sub_tab
			
			function sub_tab:set_active(bool)
				lib:tween(barleft, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = bool and 0 or 1})
				lib:tween(sublabel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = bool and Color3.fromRGB(201, 201, 201) or Color3.fromRGB(141,141,141)})
				lib:tween(fillbar, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = bool and UDim2.new(1, 0, 1, 0) or UDim2.new(0, 0, 1, 0)})
				subtabframe.Visible = bool
				if bool then
					tab.active_subtab = name
				end
			end

			function sub_tab:on_highlight(bool)
				if not bool then
					lib:tween(barleft, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5})
					lib:tween(sublabel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(180,180,180)})
				end
			end

			function sub_tab:on_leave(bool)
				if not bool then
					lib:tween(barleft, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
					lib:tween(sublabel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(141,141,141)})
				end
			end

			subtab.MouseEnter:Connect(function()
				sub_tab:on_highlight(tab.active_subtab == name)
			end)

			subtab.MouseLeave:Connect(function()
				sub_tab:on_leave(tab.active_subtab == name)
			end)

			subtab.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 and tab.active_subtab ~= name and not lib.busy then
					tab.subtabs[tab.active_subtab]:set_active(false)
					sub_tab:set_active(true)
				end
			end)
			
			sub_tab:set_active(lib:get_table_length(tab.subtabs) == 1)
			
			function sub_tab:create_section(args)
				local name = args["name"]

				local sectionframe = lib:create_element("Frame", {
					BackgroundColor3 = Color3.fromRGB(0, 0, 0);
					BorderSizePixel = 0;
					Position = UDim2.new(0, 1, 0, 1);
					Size = UDim2.new(1, 0, 0, 40)
				}, {"Randomize"})
				local inside_section = lib:create_element("Frame", {
					BackgroundColor3 = Color3.fromRGB(31, 31, 31);
					Size = UDim2.new(1, -1, 1, -1);
					Parent = sectionframe
				}, {"Randomize"})
				local sectionlabel = lib:create_element("TextLabel", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255);
					BackgroundTransparency = 1.000;
					Position = UDim2.new(0, 8, 0, 9);
					Size = UDim2.new(1, -14, 0, 14);
					Font = Enum.Font.Arial;
					Text = name;
					TextColor3 = Color3.fromRGB(201, 201, 201);
					TextSize = 14.000;
					TextXAlignment = Enum.TextXAlignment.Left;
					Parent = inside_section
				}, {"Randomize", "TextOutline"})
				local section_holder = lib:create_element("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255);
					BackgroundTransparency = 1.000;
					Position = UDim2.new(0, 18, 0, 32);
					Size = UDim2.new(1, -36, 1, -39);
					ClipsDescendants = true;
					Parent = inside_section
				}, {"Randomize"})
				local UIListLayout = lib:create_element("UIListLayout", {
					Padding = UDim.new(0, 4);
					SortOrder = Enum.SortOrder.LayoutOrder;
					Parent = section_holder
				}, {"Randomize"})
				local corner3 = lib:create_element("UICorner", {
					Parent = sectionframe;
				}, {"Randomize"})
				local corner4 = lib:create_element("UICorner", {
					Parent = inside_section;
				}, {"Randomize"})
				local droplabel = lib:create_element("TextLabel", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255);
					BackgroundTransparency = 1.000;
					Position = UDim2.new(1, -23, 0, 9);
					Size = UDim2.new(0, 14, 0, 14);
					Font = Enum.Font.Arial;
					Text = "-";
					TextColor3 = Color3.fromRGB(201,201,201);
					TextSize = 14.000;
					Parent = inside_section
				}, {"Randomize", "TextOutline"})
				
				local section = {elements = {}, total_size = 40}
				
				sub_tab.sections[name] = section

				if lib:get_table_length(sub_tab.sections) % 2 == 0 then
					sectionframe.Parent = right
				else
					sectionframe.Parent = left
				end
				
				function section:close_section()
					droplabel.Text = "+"
					droplabel:FindFirstChildOfClass("TextLabel").Text = "+"
					lib:tween(sectionframe, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 40)})
				end
				
				function section:open_section()
					droplabel.Text = "-"
					droplabel:FindFirstChildOfClass("TextLabel").Text = "-"
					lib:tween(sectionframe, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, section.total_size)})
				end
				
				function section:update_size(size)
					section.total_size = section.total_size + size
					if sectionframe.Parent == left then
						sub_tab.left_size = sub_tab.left_size + size
					else
						sub_tab.right_size = sub_tab.right_size + size
					end
					local left_bigger = false
					local right_bigger = false
					local add_size = 0
					if sub_tab.left_size > 450 then
						subtabframe.ScrollingEnabled = true
						left_bigger = true
					end
					if sub_tab.right_size > 450 then
						subtabframe.ScrollingEnabled = true
						right_bigger = true
					end
					if left_bigger and not right_bigger then
						add_size = sub_tab.left_size - 450
					end
					if right_bigger and not left_bigger then
						add_size = sub_tab.right_size - 450
					end
					if right_bigger and left_bigger then
						if right_bigger > left_bigger then
							add_size = sub_tab.right_size - 450
						else
							add_size = sub_tab.left_size - 450
						end
					end
					subtabframe.CanvasSize = UDim2.new(0, 0, 1, add_size)
					sectionframe.Size = UDim2.new(1, 0, 0, section.total_size)
				end
				
				droplabel.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if droplabel.Text == "-" then section:close_section() else section:open_section() end
					end
				end)
				
				function section:create_element(args)
					local name = args["name"]
					local types = args["types"]
					local flag = args["flag"]
					local tip = args["tip"]
					local callback = args["callback"]

					local element = {}
					
					if flag then
						lib.flags[flag] = {}
					end
					
					local main_element = lib:create_element("Frame", {
						BackgroundTransparency = 1;
						Size = UDim2.new(1, 0, 0, 14);
						Visible = true;
						Parent = section_holder
					}, {"Randomize"})
					local elementlabel = lib:create_element("TextLabel", {
						BackgroundTransparency = 1.000;
						Size = UDim2.new(1, 0, 0, 14);
						Font = Enum.Font.Arial;
						Text = name;
						TextColor3 = Color3.fromRGB(201, 201, 201);
						TextSize = 14.000;
						TextXAlignment = Enum.TextXAlignment.Left;
						Parent = main_element
					}, {"Randomize", "TextOutline"})
					local addon_holder = lib:create_element("Frame", {
						BackgroundColor3 = Color3.fromRGB(255, 255, 255);
						BackgroundTransparency = 1.000;
						Position = UDim2.new(1, -100, 0, 0);
						Size = UDim2.new(0, 100, 0, 14);
						Parent = main_element
					}, {"Randomize"})
					local UIListLayout = lib:create_element("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal;
						HorizontalAlignment = Enum.HorizontalAlignment.Right;
						SortOrder = Enum.SortOrder.LayoutOrder;
						VerticalAlignment = Enum.VerticalAlignment.Center;
						Padding = UDim.new(0, 5);
						Parent = addon_holder
					}, {"Randomize"})
					
					if tip then
						local tipimage = lib:create_element("ImageLabel", {
							BackgroundColor3 = Color3.fromRGB(255, 255, 255);
							BackgroundTransparency = 1.000;
							Position = UDim2.new(1, 0, 0, 0);
							Size = UDim2.new(0, 14, 0, 14);
							Image = "http://www.roblox.com/asset/?id=12412698913";
							Parent = elementlabel
						}, {"Randomize"})
						local tipborder = lib:create_element("Frame", {
							BackgroundColor3 = Color3.fromRGB(39, 39, 39);
							BorderSizePixel = 0;
							Position = UDim2.new(0.5, -50, 0, -22);
							Size = UDim2.new(0, 100, 0, 20);
							Visible = false;
							Parent = main
						}, {"Randomize"})
						local tipinside = lib:create_element("Frame", {
							BackgroundColor3 = Color3.fromRGB(21, 21, 21);
							BorderSizePixel = 0;
							Position = UDim2.new(0, 1, 0, 1);
							Size = UDim2.new(1, -2, 1, -2);
							Parent = tipborder
						}, {"Randomize"})
						local tiplabel = lib:create_element("TextLabel", {
							BackgroundColor3 = Color3.fromRGB(255, 255, 255);
							BackgroundTransparency = 1.000;
							BorderColor3 = Color3.fromRGB(27, 42, 53);
							Size = UDim2.new(1, 0, 1, 0);
							Font = Enum.Font.Arial;
							Text = tip;
							TextColor3 = Color3.fromRGB(201, 201, 201);
							TextSize = 14.000;
							Parent = tipinside
						}, {"Randomize", "TextOutline"})
						local corner5 = lib:create_element("UICorner", {
							Parent = tipborder;
							CornerRadius = UDim.new(0, 6)
						}, {"Randomize"})
						local corner6 = lib:create_element("UICorner", {
							Parent = tipinside;
							CornerRadius = UDim.new(0, 6)
						}, {"Randomize"})
						
						function element:open_tip()
							lib.busy = true
							tipborder.Visible = true
							tipborder.Position = UDim2.new(0, elementlabel.AbsolutePosition.X, 0, elementlabel.AbsolutePosition.Y - 22)
							lib:tween(tipborder, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
							lib:tween(tipinside, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
							lib:tween(tiplabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
							lib:tween(tiplabel:FindFirstChildOfClass("TextLabel"), TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
						end
						
						function element:close_tip()
							lib:tween(tipborder, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
							lib:tween(tipinside, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
							lib:tween(tiplabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})
							lib:tween(tiplabel:FindFirstChildOfClass("TextLabel"), TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})
							coroutine.wrap(function()
								task.wait(0.305)
								if tipborder.BackgroundTransparency == 1 then
									tipborder.Visible = false
									lib.busy = false
								end
							end)()
						end
						
						tipimage.InputBegan:connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 and not lib.busy then
								element:open_tip()
							end
						end)
						
						tipimage.MouseLeave:connect(function()
							if tipborder.Visible == true then
								element:close_tip() 
							end
						end)
						
						local label_size = game:GetService("TextService"):GetTextSize(tip, 14.000, Enum.Font.Arial, Vector2.new(999,999))
						tipborder.Size = UDim2.new(0, label_size.X + 10, 0, 20)
						
						element:close_tip()
					end
					
					local label_size = game:GetService("TextService"):GetTextSize(name, 14.000, Enum.Font.Arial, Vector2.new(999,999))
					elementlabel.Size = UDim2.new(0, label_size.X + 2, 0, 14);
					section:update_size(18)
					
					if table.find(types, "colorpicker") then
						lib.flags[flag]["color"] = Color3.fromRGB(0,0,0)
						lib.flags[flag]["transparency"] = 1
						
						local colorpickerbox2 = Instance.new("Frame")
						local colorpickerinside = Instance.new("Frame")

						colorpickerbox2.Name = "colorpickerbox"
						colorpickerbox2.Parent = addon_holder
						colorpickerbox2.BackgroundColor3 = Color3.fromRGB(41, 41, 41)
						colorpickerbox2.BorderSizePixel = 0
						colorpickerbox2.Position = UDim2.new(0, 0, 0.5, -7)
						colorpickerbox2.Size = UDim2.new(0, 25, 0, 12)

						colorpickerinside.Name = "colorpickerinside"
						colorpickerinside.Parent = colorpickerbox2
						colorpickerinside.BackgroundColor3 = Color3.fromRGB(21, 21, 21)
						colorpickerinside.BorderSizePixel = 0
						colorpickerinside.Position = UDim2.new(0, 1, 0, 1)
						colorpickerinside.Size = UDim2.new(1, -2, 1, -2)

						local irn = false
						
						local corner5 = lib:create_element("UICorner", {
							Parent = colorpickerbox2;
							CornerRadius = UDim.new(0, 3)
						}, {"Randomize"})
						local corner6 = lib:create_element("UICorner", {
							Parent = colorpickerinside;
							CornerRadius = UDim.new(0, 3)
						}, {"Randomize"})

						colorpickerbox2.MouseEnter:Connect(function()
							irn = true 
						end)
						
						colorpickerbox2.MouseLeave:Connect(function()
							irn = false 
						end)
						
						local colorpickerbox = Instance.new("Frame")
						local colorpickerinside2 = Instance.new("Frame")
						local bigcolor = Instance.new("ImageLabel")
						local maincolorpicker = Instance.new("ImageLabel")
						local hueslider = Instance.new("Frame")
						local UIGradient = Instance.new("UIGradient")
						local huepicker = Instance.new("ImageLabel")
						local transparencyslider = Instance.new("Frame")
						local transparencypicker = Instance.new("ImageLabel")
						local UIGradient_2 = Instance.new("UIGradient")
						local applybutton = Instance.new("Frame")
						local applylabel = Instance.new("TextLabel")
						local copybutton = Instance.new("Frame")
						local copylabel = Instance.new("TextLabel")

						colorpickerbox.Name = "colorpickerbox"
						colorpickerbox.Parent = main
						colorpickerbox.BackgroundColor3 = Color3.fromRGB(41, 41, 41)
						colorpickerbox.BorderSizePixel = 0
						colorpickerbox.Position = UDim2.new(0, 15, 0.5, -7)
						colorpickerbox.Size = UDim2.new(0, 180, 0, 240)
						colorpickerbox.Visible = false

						colorpickerbox.MouseEnter:Connect(function()
							irn = true 
						end)
						
						colorpickerbox.MouseLeave:Connect(function()
							irn = false 
						end)
						
						colorpickerinside2.Name = "colorpickerinside2"
						colorpickerinside2.Parent = colorpickerbox
						colorpickerinside2.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
						colorpickerinside2.BorderSizePixel = 0
						colorpickerinside2.Position = UDim2.new(0, 1, 0, 1)
						colorpickerinside2.Size = UDim2.new(1, -2, 1, -2)

						bigcolor.Name = "bigcolor"
						bigcolor.Parent = colorpickerinside2
						bigcolor.BackgroundColor3 = Color3.fromRGB(255,255,255)
						bigcolor.BorderColor3 = Color3.fromRGB(41, 41, 41)
						bigcolor.Position = UDim2.new(0, 5, 0, 5)
						bigcolor.Size = UDim2.new(1, -10, 0, 168)
						bigcolor.Image = "rbxassetid://4155801252"

						maincolorpicker.Name = "maincolorpicker"
						maincolorpicker.Parent = bigcolor
						maincolorpicker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						maincolorpicker.BackgroundTransparency = 1.000
						maincolorpicker.Size = UDim2.new(0, 8, 0, 8)
						maincolorpicker.Image = "http://www.roblox.com/asset/?id=29684337"

						hueslider.Name = "hueslider"
						hueslider.Parent = colorpickerinside2
						hueslider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						hueslider.BorderColor3 = Color3.fromRGB(41, 41, 41)
						hueslider.Position = UDim2.new(0, 5, 0, 178)
						hueslider.Size = UDim2.new(1, -10, 0, 12)

						UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 0, 255)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 255, 0)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(170, 0, 0))}
						UIGradient.Parent = hueslider

						huepicker.Name = "huepicker"
						huepicker.Parent = hueslider
						huepicker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						huepicker.BackgroundTransparency = 1.000
						huepicker.Position = UDim2.new(0, 15, 0, 0)
						huepicker.Size = UDim2.new(0, 5, 1, 0)
						huepicker.Image = "http://www.roblox.com/asset/?id=29684337"

						transparencyslider.Name = "transparencyslider"
						transparencyslider.Parent = colorpickerinside2
						transparencyslider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						transparencyslider.BorderColor3 = Color3.fromRGB(41, 41, 41)
						transparencyslider.Position = UDim2.new(0, 5, 0, 195)
						transparencyslider.Size = UDim2.new(1, -10, 0, 12)

						transparencypicker.Name = "transparencypicker"
						transparencypicker.Parent = transparencyslider
						transparencypicker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						transparencypicker.BackgroundTransparency = 1.000
						transparencypicker.Position = UDim2.new(0, 15, 0, 0)
						transparencypicker.Size = UDim2.new(0, 5, 1, 0)
						transparencypicker.Image = "http://www.roblox.com/asset/?id=29684337"

						UIGradient_2.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(41, 41, 41)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 255, 255))}
						UIGradient_2.Parent = transparencyslider
						UIGradient_2.Rotation = 180

						applybutton.Name = "applybutton"
						applybutton.Parent = colorpickerinside2
						applybutton.BackgroundColor3 = Color3.fromRGB(21, 21, 21)
						applybutton.BorderColor3 = Color3.fromRGB(41, 41, 41)
						applybutton.Position = UDim2.new(1, -55, 1, -23)
						applybutton.Size = UDim2.new(0, 50, 0, 18)

						applylabel.Name = "applylabel"
						applylabel.Parent = applybutton
						applylabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						applylabel.BackgroundTransparency = 1.000
						applylabel.Size = UDim2.new(1, 0, 1, 0)
						applylabel.Font = Enum.Font.Arial
						applylabel.Text = "apply"
						applylabel.TextColor3 = Color3.fromRGB(201, 201, 201)
						applylabel.TextSize = 14.000

						copybutton.Name = "copybutton"
						copybutton.Parent = colorpickerinside2
						copybutton.BackgroundColor3 = Color3.fromRGB(21, 21, 21)
						copybutton.BorderColor3 = Color3.fromRGB(41, 41, 41)
						copybutton.Position = UDim2.new(1, -110, 1, -23)
						copybutton.Size = UDim2.new(0, 50, 0, 18)

						copylabel.Name = "copylabel"
						copylabel.Parent = copybutton
						copylabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						copylabel.BackgroundTransparency = 1.000
						copylabel.Size = UDim2.new(1, 0, 1, 0)
						copylabel.Font = Enum.Font.Arial
						copylabel.Text = "copy"
						copylabel.TextColor3 = Color3.fromRGB(201, 201, 201)
						copylabel.TextSize = 14.000
						
						colorpickerbox2.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 and not lib.busy then
								lib.busy = true
								colorpickerbox.Position = UDim2.new(0, colorpickerbox2.AbsolutePosition.X + 30, 0, colorpickerbox2.AbsolutePosition.Y)
								colorpickerbox.Visible = true
							elseif input.UserInputType == Enum.UserInputType.MouseButton1 and lib.busy and colorpickerbox.Visible then
								lib.busy = false
								colorpickerbox.Visible = false
							end
						end)

						lib.onClick:Connect(function()
							if lib.busy and colorpickerbox.Visible and not irn then
								lib.busy = false
								colorpickerbox.Visible = false
							end
						end)
						
						local in_color = false
						local in_color2 = false

						function element.update_transp()
							local x = math.clamp(game.Players.LocalPlayer:GetMouse().X - transparencyslider.AbsolutePosition.X, 0, 168)
							transparencypicker.Position = UDim2.new(0, x, 0, 0)
							local transparency = x/168
							lib.flags[flag]["transparency"] = transparency

							pcall(callback, lib.flags[flag]["transparency"])
						end
						transparencyslider.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								element.update_transp()
								local moveconnection = game.Players.LocalPlayer:GetMouse().Move:Connect(function()
									element.update_transp()
								end)
								releaseconnection = game.UserInputService.InputEnded:Connect(function(Mouse)
									if Mouse.UserInputType == Enum.UserInputType.MouseButton1 then
										element.update_transp()
										moveconnection:Disconnect()
										releaseconnection:Disconnect()
									end
								end)
							end
						end)

						element.h = (math.clamp(hueslider.AbsolutePosition.Y-maincolorpicker.AbsolutePosition.Y, 0, maincolorpicker.AbsoluteSize.Y)/maincolorpicker.AbsoluteSize.Y)
						element.s = 1-(math.clamp(huepicker.AbsolutePosition.X-huepicker.AbsolutePosition.X, 0, maincolorpicker.AbsoluteSize.X)/maincolorpicker.AbsoluteSize.X)
						element.v = 1-(math.clamp(huepicker.AbsolutePosition.Y-huepicker.AbsolutePosition.Y, 0, maincolorpicker.AbsoluteSize.Y)/maincolorpicker.AbsoluteSize.Y)

						lib.flags[flag]["color"] = Color3.fromHSV(element.h, element.s, element.v)

						function element.update_color()
							local ColorX = (math.clamp(game.Players.LocalPlayer:GetMouse().X - bigcolor.AbsolutePosition.X, 0, bigcolor.AbsoluteSize.X)/bigcolor.AbsoluteSize.X)
							local ColorY = (math.clamp(game.Players.LocalPlayer:GetMouse().Y - bigcolor.AbsolutePosition.Y, 0, bigcolor.AbsoluteSize.Y)/bigcolor.AbsoluteSize.Y)
							maincolorpicker.Position = UDim2.new(ColorX, 0, ColorY, 0)

							element.s = 1 - ColorX
							element.v = 1 - ColorY

							colorpickerinside.BackgroundColor3 = Color3.fromHSV(element.h, element.s, element.v)
							lib.flags[flag]["color"] = Color3.fromHSV(element.h, element.s, element.v)
							pcall(callback, lib.flags[flag])
						end
						bigcolor.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								element.update_color()
								local moveconnection = game.Players.LocalPlayer:GetMouse().Move:Connect(function()
									element.update_color()
								end)
								releaseconnection = game.UserInputService.InputEnded:Connect(function(Mouse)
									if Mouse.UserInputType == Enum.UserInputType.MouseButton1 then
										element.update_color()
										moveconnection:Disconnect()
										releaseconnection:Disconnect()
									end
								end)
							end
						end)

						function element.update_hue()
							local y = math.clamp(game.Players.LocalPlayer:GetMouse().X - hueslider.AbsolutePosition.X, 0, 168)
							huepicker.Position = UDim2.new(0, y, 0, 0)
							local hue = y/168
							element.h = 1-hue
							bigcolor.ImageColor3 = Color3.fromHSV(element.h, 1, 1)
							colorpickerinside.BackgroundColor3 = Color3.fromHSV(element.h, element.s, element.v)
							lib.flags[flag]["color"] = Color3.fromHSV(element.h, element.s, element.v)
							pcall(callback, lib.flags[flag])
						end
						hueslider.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								element.update_hue()
								local moveconnection = game.Players.LocalPlayer:GetMouse().Move:Connect(function()
									element.update_hue()
								end)
								releaseconnection = game.UserInputService.InputEnded:Connect(function(Mouse)
									if Mouse.UserInputType == Enum.UserInputType.MouseButton1 then
										element.update_hue()
										moveconnection:Disconnect()
										releaseconnection:Disconnect()
									end
								end)
							end
						end)

						function element:set_color(new_value)
							if typeof(new_value) == "Color3" then
								lib.flags[flag]["color"] = new_value
								lib.flags[flag]["transparency"] = 0
							else
								lib.flags[flag]["color"] = new_value["color"]
								lib.flags[flag]["transparency"] = new_value["transparency"]
							end

							local duplicate = Color3.new(lib.flags[flag]["color"].R, lib.flags[flag]["color"].G, lib.flags[flag]["color"].B)
							element.h, element.s, element.v = duplicate:ToHSV()
							element.h = math.clamp(element.h, 0, 1)
							element.s = math.clamp(element.s, 0, 1)
							element.v = math.clamp(element.v, 0, 1)

							maincolorpicker.Position = UDim2.new(1 - element.s, 0, 1 - element.v, 0)
							element.ImageColor3 = Color3.fromHSV(element.h, 1, 1)
							element.BackgroundColor3 = Color3.fromHSV(element.h, element.s, element.v)
							colorpickerinside.BackgroundColor3 = Color3.fromHSV(element.h, element.s, element.v)
							huepicker.Position = UDim2.new(0, 1 - element.h, 0, 0)
							bigcolor.ImageColor3 = Color3.fromHSV(element.h, 1, 1)

							transparencypicker.Position = UDim2.new(lib.flags[flag]["transparency"], -1, 0, 0)
							

							pcall(callback, lib.flags[flag])
						end
						
						applybutton.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								applylabel.Text = "applied!"
								element:set_color(lib.copied_color)
								coroutine.wrap(function()
									task.wait(1)
									if applylabel.Text == "applied!" then
										applylabel.Text = "apply"
									end
								end)()
							end
						end)

						copybutton.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								copylabel.Text = "copied!"
								lib.copied_color = lib.flags[flag]
								coroutine.wrap(function()
									task.wait(1)
									if copylabel.Text == "copied!" then
										copylabel.Text = "copy"
									end
								end)()
							end
						end)

						element:set_color(args["c_default"])
						
						lib.onConfigLoaded:Connect(function()
							element:set_color(lib.flags[flag])
						end)
					end
					
					if table.find(types, "keybind") then
						
						local def = args["k_default"]

						local keybindbox = Instance.new("Frame", addon_holder)
						keybindbox.BackgroundColor3 = Color3.fromRGB(41.00000135600567, 41.00000135600567, 41.00000135600567);
						keybindbox.BorderSizePixel = 0;
						keybindbox.Name = "keybindbox";
						keybindbox.Position = UDim2.new(0, 0, 1, 0);
						keybindbox.Size = UDim2.new(0, 65, 0, 14);

						local boxinside = Instance.new("Frame", keybindbox);
						boxinside.BackgroundColor3 = Color3.fromRGB(21.000000648200512, 21.000000648200512, 21.000000648200512);
						boxinside.BorderSizePixel = 0;
						boxinside.Name = "boxinside";
						boxinside.Position = UDim2.new(0, 1, 0, 1);
						boxinside.Size = UDim2.new(1, -2, 1, -2);

						local keybindlabel = Instance.new("TextLabel", boxinside);
						keybindlabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
						keybindlabel.BackgroundTransparency = 1;
						keybindlabel.Name = "keybindlabel";
						keybindlabel.Size = UDim2.new(1, 0, 1, 0);
						keybindlabel.Font = Enum.Font.Arial;
						keybindlabel.FontFace = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
						keybindlabel.Text = "always off";
						keybindlabel.TextColor3 = Color3.fromRGB(201.00000321865082, 201.00000321865082, 201.00000321865082);
						keybindlabel.TextSize = 12;
						keybindlabel.TextWrapped = true;

						local UICorner = Instance.new("UICorner", boxinside);
						UICorner.CornerRadius = UDim.new(0, 2);

						local binddivider = Instance.new("Frame", boxinside);
						binddivider.BackgroundColor3 = Color3.fromRGB(41.00000135600567, 41.00000135600567, 41.00000135600567);
						binddivider.BorderSizePixel = 0;
						binddivider.Name = "binddivider";
						binddivider.Position = UDim2.new(0, 0, 1, -1);
						binddivider.Size = UDim2.new(0, 0, 0, 1);
						binddivider.Visible = true;

						local openkeybind = Instance.new("Frame", main);
						openkeybind.BackgroundColor3 = Color3.fromRGB(41.00000135600567, 41.00000135600567, 41.00000135600567);
						openkeybind.BorderSizePixel = 0;
						openkeybind.Name = "openkeybind";
						openkeybind.Position = UDim2.new(0, 0, 0, 14);
						openkeybind.Size = UDim2.new(0, 65, 0, 0);
						openkeybind.Visible = false;
						openkeybind.ClipsDescendants = true
						openkeybind.ZIndex = 5
						local UICorner_0 = Instance.new("UICorner", openkeybind);
						UICorner_0.CornerRadius = UDim.new(0, 2);

						local openinside = Instance.new("Frame", openkeybind);
						openinside.BackgroundColor3 = Color3.fromRGB(21.000000648200512, 21.000000648200512, 21.000000648200512);
						openinside.BorderSizePixel = 0;
						openinside.Name = "openinside";
						openinside.Position = UDim2.new(0, 1, 0, -1);
						openinside.Size = UDim2.new(1, -2, 1, 0);
						openinside.ZIndex = 5
						
						local UICorner_1 = Instance.new("UICorner", openinside);
						UICorner_1.CornerRadius = UDim.new(0, 2);

						local UIListLayout = Instance.new("UIListLayout", openinside);
						UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder;

						local UICorner_2 = Instance.new("UICorner", keybindbox);
						UICorner_2.CornerRadius = UDim.new(0, 2);
						
						binddivider:GetPropertyChangedSignal("Size"):Connect(function()
							if binddivider.Size.X.Offset > 0 and not openkeybind.Visible then
								binddivider.Size = UDim2.new(0, 0, 0, 1)
							end
							binddivider.Position = UDim2.new(0.5, -binddivider.Size.X.Offset/2, 1, -1)
						end)
						
						function element:on_keybind_hover(bool)
							lib:tween(keybindbox, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(52, 52, 52)})
						end

						function element:on_keybind_leave(bool)
							lib:tween(keybindbox, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(41, 41, 41)})
						end
						
						function element:update_keybind_text()
							local text = lib.flags[flag]["method"]..": "..lib.flags[flag]["key"]
							if lib.flags[flag]["method"] == "on" then
								text = "always on"
							end
							if lib.flags[flag]["method"] == "off" then
								text = "always off"
							end
							local label_size = game:GetService("TextService"):GetTextSize(text, 12.000, Enum.Font.Arial, Vector2.new(999,999))
							keybindbox.Size = UDim2.new(0, label_size.X + 10, 0, 14)
							keybindlabel.Text = text
							openkeybind.Size = UDim2.new(0, label_size.X + 10, 0, openkeybind.Size.Y.Offset)
							binddivider.Size = UDim2.new(0, label_size.X + 10, 0, binddivider.Size.Y.Offset)
						end
						
						function element:set_method(method)
							lib.flags[flag]["method"] = method
							for i,v in pairs(openinside:GetChildren()) do
								if v.ClassName == "TextLabel" and v.Name ~= method then
									lib:tween(v, TweenInfo.new(0.03, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(141, 141, 141)})
								elseif v.Name == method then
									lib:tween(v, TweenInfo.new(0.03, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(194, 155, 165)})
								end
							end
							element:update_keybind_text()
						end
						
						function element:set_key(key)
							lib.flags[flag]["key"] = key
							element:update_keybind_text()
						end
						
						local methods = {
							"on",
							"off",
							"toggle",
							"hold"
						}
						
						lib.flags[flag]["key"] = "none"
						
						for i, method in pairs(methods) do							
							local keybindlabel2 = Instance.new("TextLabel", openinside);
							keybindlabel2.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
							keybindlabel2.BackgroundTransparency = 1;
							keybindlabel2.Name = "keybindlabel";
							keybindlabel2.Size = UDim2.new(1, 0, 0, 14);
							keybindlabel2.Font = Enum.Font.Arial;
							keybindlabel2.FontFace = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
							keybindlabel2.Text = method;
							keybindlabel2.TextColor3 = Color3.fromRGB(141.00000321865082, 141.00000321865082, 141.00000321865082);
							keybindlabel2.TextSize = 12;
							keybindlabel2.TextWrapped = true;
							keybindlabel2.ZIndex = 6;
							keybindlabel2.Name = method
							
							keybindlabel2.MouseEnter:Connect(function()
								if method == lib.flags[flag]["method"] then return end
								lib:tween(keybindlabel2, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(201.00000321865082, 201.00000321865082, 201.00000321865082);})
							end)
							
							keybindlabel2.MouseLeave:Connect(function()
								if method == lib.flags[flag]["method"] then return end
								lib:tween(keybindlabel2, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(141.00000321865082, 141.00000321865082, 141.00000321865082);})
							end)
							
							keybindlabel2.InputBegan:Connect(function(input)
								if input.UserInputType == Enum.UserInputType.MouseButton1 then
									if method == lib.flags[flag]["method"] then return end
									element:set_method(method)
									element:close_keybind()
								end
							end)
						end
						
						function element:open_keybind()
							openkeybind.Visible = true
							openkeybind.Position = UDim2.new(0, keybindbox.AbsolutePosition.X, 0, keybindbox.AbsolutePosition.Y + 13)
							lib:tween(openkeybind, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, keybindbox.Size.X.Offset, 0, 56)})
							lib:tween(binddivider, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, keybindbox.Size.X.Offset, 0, 1)})
						end
						
						function element:close_keybind()
							openkeybind.Position = UDim2.new(0, keybindbox.AbsolutePosition.X, 0, keybindbox.AbsolutePosition.Y + 13)
							lib:tween(openkeybind, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, keybindbox.Size.X.Offset, 0, 0)})
							lib:tween(binddivider, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 0, 0, 1)})
							coroutine.wrap(function()
								task.wait(0.305)
								if openkeybind.Size.Y.Offset == 0 then
									openkeybind.Visible = false
									lib.busy = false
								end
							end)()
						end

						lib.onClick:Connect(function()
							if lib.busy and openkeybind.Visible and not is_in_frame(openkeybind) and not is_in_frame(keybindbox) then
								element:close_keybind()
							end
						end)

						keybindbox.MouseEnter:connect(function()
							element:on_keybind_hover()
						end)

						keybindbox.MouseLeave:connect(function()
							element:on_keybind_leave()
						end)
						
						local binding = false
						local active = false
						
						game:GetService("UserInputService").InputBegan:Connect(function(input)
							if binding then
								local key = nil
								if input.UserInputType == Enum.UserInputType.MouseButton2 then
									key = "mouse2"
								elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
									key = "mouse3"
								elseif input.KeyCode.Name == "Unknown" then
									key = "none"
								elseif input.KeyCode.Name == "Escape" then
									key = "none"
								end
								if key then element:set_key(key) end
								if not key then
									element:set_key(string.lower(input.KeyCode.Name))
								end
								binding = false
								lib.busy = false
							else
								local key = nil
								if input.UserInputType == Enum.UserInputType.MouseButton2 then
									key = "mouse2"
								elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
									key = "mouse3"
								elseif input.KeyCode.Name == "Unknown" then
									key = "none"
								elseif input.KeyCode.Name == "Escape" then
									key = "none"
								end
								if key == lib.flags[flag]["key"] then
									if lib.flags[flag]["method"] == "toggle" then
										active = not active
									elseif lib.flags[flag]["method"] == "hold" then
										active = true
									end
								else
									key = string.lower(input.KeyCode.Name)
									if key == lib.flags[flag]["key"] then
										if lib.flags[flag]["method"] == "toggle" then
											active = not active
										elseif lib.flags[flag]["method"] == "hold" then
											active = true
										end
									end
								end
							end
						end)
						
						game:GetService("UserInputService").InputEnded:Connect(function(input)
							local key = nil
							if input.UserInputType == Enum.UserInputType.MouseButton2 then
								key = "mouse2"
							elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
								key = "mouse3"
							elseif input.KeyCode.Name == "Unknown" then
								key = "none"
							elseif input.KeyCode.Name == "Escape" then
								key = "none"
							end
							if key == lib.flags[flag]["key"] then
								if lib.flags[flag]["method"] == "hold" then
									active = false
								end
							else
								key = string.lower(input.KeyCode.Name)
								if key == lib.flags[flag]["key"] then
									if lib.flags[flag]["method"] == "hold" then
										active = false
									end
								end
							end
						end)
						
						function element:get_active()
							if lib.flags[flag]["method"] == "off" or lib.flags[flag]["method"] == "on" then
								return lib.flags[flag]["method"] == "on" and true or false
							end
							return active
						end
						
						keybindbox.InputBegan:connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton2 and not lib.busy then
								lib.busy = true
								element:open_keybind()
							elseif input.UserInputType == Enum.UserInputType.MouseButton2 and lib.busy and openkeybind.Visible then
								element:close_keybind()
								element:open_keybind()
							elseif input.UserInputType == Enum.UserInputType.MouseButton1 and not lib.busy then
								if lib.flags[flag]["method"] ~= "off" and lib.flags[flag]["method"] ~= "on" then
									local label_size = game:GetService("TextService"):GetTextSize(lib.flags[flag]["method"]..": ".."...", 12.000, Enum.Font.Arial, Vector2.new(999,999))
									keybindbox.Size = UDim2.new(0, label_size.X + 10, 0, 14)
									keybindlabel.Text = lib.flags[flag]["method"]..": ".."..."
									lib.busy = true
									task.wait(0.1)
									binding = true
								end
							end
						end)
						
						local label_size = game:GetService("TextService"):GetTextSize("always off", 12.000, Enum.Font.Arial, Vector2.new(999,999))
						keybindbox.Size = UDim2.new(0, label_size.X + 10, 0, 14)
						
						element:set_method("off")
						element:set_key("none")

						if def then
							element:set_method(def.method)
							element:set_key(def.key)
						end

						lib.onConfigLoaded:Connect(function()
							element:set_method(lib.flags[flag]["method"])
							element:set_key(lib.flags[flag]["key"])
						end)
					end
					
					if table.find(types, "toggle") then
						elementlabel.Position = UDim2.new(0, 20, 0, 0)
						local togglebox = lib:create_element("Frame", {
							BackgroundColor3 = Color3.fromRGB(41, 41, 41);
							BorderSizePixel = 0;
							Position = UDim2.new(0, 0, 0, 1);
							Size = UDim2.new(0, 12, 0, 12);
							Parent = main_element
						}, {"Randomize"})
						local toggleinside = lib:create_element("Frame", {
							BackgroundColor3 = Color3.fromRGB(21, 21, 21);
							BorderSizePixel = 0;
							Position = UDim2.new(0, 1, 0, 1);
							Size = UDim2.new(1, -2, 1, -2);
							Parent = togglebox
						}, {"Randomize"})
						local corner5 = lib:create_element("UICorner", {
							Parent = toggleinside;
							CornerRadius = UDim.new(0, 3)
						}, {"Randomize"})
						local corner6 = lib:create_element("UICorner", {
							Parent = togglebox;
							CornerRadius = UDim.new(0, 3)
						}, {"Randomize"})
						
						function element:set_toggle(val)
							lib.flags[flag]["toggle"] = val
							lib:tween(toggleinside, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = val and Color3.fromRGB(194, 155, 165) or Color3.fromRGB(21, 21, 21)})
							pcall(callback, val)
						end
						
						function element:on_toggle_highlight(bool)
							lib:tween(togglebox, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(52, 52, 52)})
						end

						function element:on_toggle_leave(bool)
							lib:tween(togglebox, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(41, 41, 41)})
						end
						
						elementlabel.MouseEnter:connect(function()
							element:on_toggle_highlight()
						end)
						
						elementlabel.MouseLeave:connect(function()
							element:on_toggle_leave()
						end)
						
						togglebox.MouseEnter:connect(function()
							element:on_toggle_highlight()
						end)

						togglebox.MouseLeave:connect(function()
							element:on_toggle_leave()
						end)
						
						togglebox.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								if not lib.busy then element:set_toggle(not lib.flags[flag]["toggle"]) end
							end
						end)
						
						elementlabel.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								if not lib.busy then element:set_toggle(not lib.flags[flag]["toggle"]) end
							end
						end)
						
						element:set_toggle(args["t_default"])
						
						lib.onConfigLoaded:Connect(function()
							element:set_toggle(lib.flags[flag]["toggle"])
						end)
					end
					
					if table.find(types, "slider") then
						main_element.Size = UDim2.new(1, 0, 0, 31)
						section:update_size(17)

						local sliderbox = Instance.new("Frame", main_element)
						sliderbox.BackgroundColor3 = Color3.fromRGB(41.00000135600567, 41.00000135600567, 41.00000135600567);
						sliderbox.Name = "sliderbox";
						sliderbox.Position = UDim2.new(0, 0, 0, 18);
						sliderbox.Size = UDim2.new(1, 0, 0, 12);

						local UICorner = Instance.new("UICorner", sliderbox);
						UICorner.CornerRadius = UDim.new(0, 3);

						local sliderinside = Instance.new("Frame", sliderbox);
						sliderinside.BackgroundColor3 = Color3.fromRGB(21.000000648200512, 21.000000648200512, 21.000000648200512);
						sliderinside.Name = "sliderinside";
						sliderinside.Position = UDim2.new(0, 1, 0, 1);
						sliderinside.Size = UDim2.new(1, -2, 1, -2);

						local UICorner_0 = Instance.new("UICorner", sliderinside);
						UICorner_0.CornerRadius = UDim.new(0, 3);

						local sliderfill = Instance.new("Frame", sliderinside);
						sliderfill.BackgroundColor3 = Color3.fromRGB(194.00000363588333, 155.00000596046448, 165.00000536441803);
						sliderfill.BorderColor3 = Color3.fromRGB(255, 255, 255);
						sliderfill.BorderSizePixel = 0;
						sliderfill.Name = "sliderfill";
						sliderfill.Size = UDim2.new(0, 0, 1, 0);

						local UICorner_1 = Instance.new("UICorner", sliderfill);
						UICorner_1.CornerRadius = UDim.new(0, 3);
						
						local elementtextbox = lib:create_element("TextBox", {
							BackgroundTransparency = 1.000;
							Size = UDim2.new(0, 50, 0, 14);
							Font = Enum.Font.Arial;
							Text = "";
							TextColor3 = Color3.fromRGB(201, 201, 201);
							TextSize = 14.000;
							TextXAlignment = Enum.TextXAlignment.Left;
							Position = UDim2.new(1, 1, 0, -1);
							Parent = elementlabel
						}, {"Randomize"})
						
						function element:on_slider_highlight(bool)
							lib:tween(sliderbox, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(52, 52, 52)})
						end

						function element:on_slider_leave(bool)
							lib:tween(sliderbox, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(41, 41, 41)})
						end
						
						local suffix = args["suffix"] or ""
						local prefix = args["prefix"] or ""
						local max = args["max"] 
						local min = args["min"]
						local def = args["s_default"] or min
						local sliding, sliding2, inContact;

						local function round(num, bracket)
							bracket = bracket or 1
							local a = math.floor(num/bracket + (math.sign(num) * 0.5)) * bracket
							if a < 0 then
								a = a + bracket
							end
							return a
						end

						function element:set_value(value3, call)
							call = true
							value3 = round(value3, 1)
							value3 = math.clamp(value3, min, max)
							local value4 = math.clamp(value3, min, max)
							if min >= 0 then
								lib:tween(sliderfill, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new((value4 - min) / (max - min), 0, 1, 0)})
							else
								lib:tween(sliderfill, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new((value4 - min) / (max - min), 0, 1, 0)})
							end
							lib.flags[flag]["value"] = value3
							elementtextbox.Text = "("..prefix..tostring(value3)..suffix..")"
							if call then
								pcall(callback, lib.flags[flag]["value"])
							end
						end
						
						elementtextbox.FocusLost:Connect(function()
							local number = tonumber(elementtextbox.Text)
							if not number then number = min end
							element:set_value(number)
						end)

						sliderinside.InputBegan:connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 and not lib.busy then
								sliding = true
								sliding2 = true
								lib.busy = true
								element:set_value(min + ((input.Position.X - sliderinside.AbsolutePosition.X) / sliderinside.AbsoluteSize.X) * (max - min), true)
							end
							if input.UserInputType == Enum.UserInputType.MouseMovement and not lib.busy then
								inContact = true
							end
						end)

						game.UserInputService.InputChanged:connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseMovement and (sliding2 and lib.busy) then
								element:set_value(min + ((input.Position.X - sliderinside.AbsolutePosition.X) / sliderinside.AbsoluteSize.X) * (max - min), true)
							end
						end)

						sliderinside.InputEnded:connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 and sliding2 then
								sliding = false
								sliding2 = false
								lib.busy = false
							end
							if input.UserInputType == Enum.UserInputType.MouseMovement then
								inContact = false
							end
						end)
						
						sliderbox.MouseEnter:Connect(function()
							element:on_slider_highlight()
						end)
						
						sliderbox.MouseLeave:Connect(function()
							element:on_slider_leave()
						end)

						element:set_value(def)
						
						lib.onConfigLoaded:Connect(function()
							element:set_value(lib.flags[flag]["value"])
						end)
					end
					
					if table.find(types, "dropdown") then
						main_element.Size = UDim2.new(1, 0, 0, 36)
						section:update_size(22)
						local dropdownbox = Instance.new("Frame", main_element);
						dropdownbox.BackgroundColor3 = Color3.fromRGB(41.00000135600567, 41.00000135600567, 41.00000135600567);
						dropdownbox.Name = "dropdownbox";
						dropdownbox.Position = UDim2.new(0, 0, 0, 16);
						dropdownbox.Size = UDim2.new(1, 0, 0, 18);
						
						local corner5 = lib:create_element("UICorner", {
							Parent = colorpickerbox2;
							CornerRadius = UDim.new(0, 3)
						}, {"Randomize"})
						local corner6 = lib:create_element("UICorner", {
							Parent = colorpickerinside;
							CornerRadius = UDim.new(0, 3)
						}, {"Randomize"})

						local UICorner = Instance.new("UICorner", dropdownbox);
						UICorner.CornerRadius = UDim.new(0, 3);

						local dropdowninside = Instance.new("Frame", dropdownbox);
						dropdowninside.BackgroundColor3 = Color3.fromRGB(21.000000648200512, 21.000000648200512, 21.000000648200512);
						dropdowninside.Name = "dropdowninside";
						dropdowninside.Position = UDim2.new(0, 1, 0, 1);
						dropdowninside.Size = UDim2.new(1, -2, 1, -2);
						
						local binddivider = Instance.new("Frame", dropdowninside);
						binddivider.BackgroundColor3 = Color3.fromRGB(41.00000135600567, 41.00000135600567, 41.00000135600567);
						binddivider.BorderSizePixel = 0;
						binddivider.Name = "binddivider";
						binddivider.Position = UDim2.new(0, 0, 1, -1);
						binddivider.Size = UDim2.new(0, 0, 0, 1);
						binddivider.Visible = true;

						local UICorner_0 = Instance.new("UICorner", dropdowninside);
						UICorner_0.CornerRadius = UDim.new(0, 3);

						local dropdownlabel = Instance.new("TextLabel", dropdowninside);
						dropdownlabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
						dropdownlabel.BackgroundTransparency = 1;
						dropdownlabel.Name = "dropdownlabel";
						dropdownlabel.Position = UDim2.new(0, 6, 0, 0);
						dropdownlabel.Size = UDim2.new(1, -6, 1, 0);
						dropdownlabel.Font = Enum.Font.Arial;
						dropdownlabel.FontFace = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
						dropdownlabel.Text = "none";
						dropdownlabel.TextColor3 = Color3.fromRGB(201.00000321865082, 201.00000321865082, 201.00000321865082);
						dropdownlabel.TextSize = 14;
						dropdownlabel.TextXAlignment = Enum.TextXAlignment.Left;
						dropdownlabel.TextWrapped = true
						
						function element:on_dropdown_hover(bool)
							lib:tween(dropdownbox, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(52, 52, 52)})
						end

						function element:on_dropdown_leave(bool)
							lib:tween(dropdownbox, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(41, 41, 41)})
						end
						
						dropdownbox.MouseEnter:Connect(function()
							element:on_dropdown_hover()
						end)

						dropdownbox.MouseLeave:Connect(function()
							element:on_dropdown_leave()
						end)
						
						local opendropdown = Instance.new("Frame", main);
						opendropdown.BackgroundColor3 = Color3.fromRGB(41.00000135600567, 41.00000135600567, 41.00000135600567);
						opendropdown.BorderSizePixel = 0;
						opendropdown.Name = "opendropdown";
						opendropdown.Position = UDim2.new(0, 0, 0, 34);
						opendropdown.Size = UDim2.new(0, 218, 0, 0);
						opendropdown.Visible = false;
						opendropdown.ZIndex = 5;

						local UICorner_1 = Instance.new("UICorner", opendropdown);
						UICorner_1.CornerRadius = UDim.new(0, 2);

						local openinside = Instance.new("Frame", opendropdown);
						openinside.BackgroundColor3 = Color3.fromRGB(21.000000648200512, 21.000000648200512, 21.000000648200512);
						openinside.BorderSizePixel = 0;
						openinside.Name = "openinside";
						openinside.Position = UDim2.new(0, 1, 0, -1);
						openinside.Size = UDim2.new(1, -2, 1, 0);
						openinside.ZIndex = 5;
						openinside.ClipsDescendants = true;


						lib.onClick:Connect(function()
							if lib.busy and opendropdown.Visible and not is_in_frame(opendropdown) and not is_in_frame(dropdowninside) then
								element:close_dropdown()
							end
						end)

						local UICorner_2 = Instance.new("UICorner", openinside);
						UICorner_2.CornerRadius = UDim.new(0, 2);

						local UIListLayout = Instance.new("UIListLayout", openinside);
						UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right;
						UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder;
						
						local dropdownimage = Instance.new("ImageLabel", dropdowninside);
						dropdownimage.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
						dropdownimage.BackgroundTransparency = 1;
						dropdownimage.Name = "dropdownimage";
						dropdownimage.Position = UDim2.new(1, -15, 0.5, -5);
						dropdownimage.Size = UDim2.new(0, 10, 0, 10);
						dropdownimage.Image = "http://www.roblox.com/asset/?id=12446904427";
						dropdownimage.ImageColor3 = Color3.fromRGB(125.00000774860382, 125.00000774860382, 125.00000774860382);
						dropdownimage.Rotation = 180;
						
						local options = args["options"]
						local default = args["d_default"]
						local no_none = args["no_none"]
						local multi = args["multi"]
						
						local p_options = options

						function element:open_dropdown()
							opendropdown.Visible = true
							dropdownimage.Rotation = 0;
							opendropdown.Position = UDim2.new(0, dropdownbox.AbsolutePosition.X, 0, dropdownbox.AbsolutePosition.Y + 18)
							lib:tween(opendropdown, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 218, 0, #p_options*14)})
							lib:tween(binddivider, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 218, 0, 1)})
						end

						function element:close_dropdown()
							dropdownimage.Rotation = 180;
							opendropdown.Position = UDim2.new(0, dropdownbox.AbsolutePosition.X, 0, dropdownbox.AbsolutePosition.Y + 18)
							lib:tween(opendropdown, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 218, 0, 0)})
							lib:tween(binddivider, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 0, 0, 1)})
							coroutine.wrap(function()
								task.wait(0.305)
								if opendropdown.Size.Y.Offset == 0 then
									opendropdown.Visible = false
									lib.busy = false
								end
							end)()
						end

						dropdownbox.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 and not lib.busy then
								lib.busy = true
								element:open_dropdown()
							elseif input.UserInputType == Enum.UserInputType.MouseButton1 and lib.busy and opendropdown.Visible then
								element:close_dropdown()
							end
						end)

						binddivider:GetPropertyChangedSignal("Size"):Connect(function()
							if binddivider.Size.X.Offset > 0 and not opendropdown.Visible then
								binddivider.Size = UDim2.new(0, 0, 0, 1)
							end
							binddivider.Position = UDim2.new(0.5, -binddivider.Size.X.Offset/2, 1, -1)
						end)
						
						function element:set_options(p)
							if #p == 0 and no_none then
								return
							end
							
							if not multi then
								p = {p[#p]}
							end
							
							local text = #p > 0 and p[1] or "none"
							
							for _, o in pairs(openinside:GetChildren()) do
								if o.ClassName == "TextLabel" then
									o.TextColor3 = Color3.fromRGB(201, 201, 201)
								end
							end
							
							lib.flags[flag]["selected"] = p
							for i = 1, #p do
								local o = p[i]
								if i > 1 then
									text = text..", "..o
								end
								local f = table.find(lib.flags[flag]["selected"], o)
								lib:tween(openinside[o], TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = f and Color3.fromRGB(194, 155, 165) or Color3.fromRGB(201, 201, 201)})
							end
							
							dropdownlabel.Text = text
						end
						
						function element:set_p_options(opts)
							options = opts
							
							local clone = lib.flags[flag]["selected"]
							
							for i,v in pairs(lib.flags[flag]["selected"]) do
								if table.find(options, v) then
									
								else
									table.remove(clone, table.find(clone, v))
								end
							end
														
							p_options = options
							
							for i,v in pairs(openinside:GetChildren()) do
								if v.ClassName == "TextLabel" then
									v:Destroy()
								end
							end
							
							for i = 1, #options do
								local option = options[i]

								local dropdownlabel_0 = Instance.new("TextLabel", openinside);
								dropdownlabel_0.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
								dropdownlabel_0.BackgroundTransparency = 1;
								dropdownlabel_0.Name = "dropdownlabel";
								dropdownlabel_0.Size = UDim2.new(1, -6, 0, 14);
								dropdownlabel_0.ZIndex = 5;
								dropdownlabel_0.Font = Enum.Font.Arial;
								dropdownlabel_0.FontFace = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
								dropdownlabel_0.Text = option;
								dropdownlabel_0.TextColor3 = Color3.fromRGB(201.00000321865082, 201.00000321865082, 201.00000321865082);
								dropdownlabel_0.TextSize = 12;
								dropdownlabel_0.TextWrapped = true;
								dropdownlabel_0.TextXAlignment = Enum.TextXAlignment.Left;
								dropdownlabel_0.Name = option

								dropdownlabel_0.MouseEnter:Connect(function()
									if table.find(lib.flags[flag]["selected"], option) then return end
									lib:tween(dropdownlabel_0, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(255, 255, 255)})
								end)

								dropdownlabel_0.MouseLeave:Connect(function()
									if table.find(lib.flags[flag]["selected"], option) then return end
									lib:tween(dropdownlabel_0, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(201, 201, 201)})
								end)

								dropdownlabel_0.InputBegan:Connect(function(input)
									if input.UserInputType == Enum.UserInputType.MouseButton1 then
										if not multi then
											element:close_dropdown()
										end
										if not table.find(lib.flags[flag]["selected"], option) then
											local clone = lib.flags[flag]["selected"]
											table.insert(clone, option)
											element:set_options(clone)
										elseif table.find(lib.flags[flag]["selected"], option) and not no_none then
											local clone = lib.flags[flag]["selected"]
											table.remove(clone, table.find(clone, option))
											element:set_options(clone)
										end
									end
								end)
							end
							
							element:set_options(clone)
						end
						for i = 1, #options do
							local option = options[i]

							local dropdownlabel_0 = Instance.new("TextLabel", openinside);
							dropdownlabel_0.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
							dropdownlabel_0.BackgroundTransparency = 1;
							dropdownlabel_0.Name = "dropdownlabel";
							dropdownlabel_0.Size = UDim2.new(1, -6, 0, 14);
							dropdownlabel_0.ZIndex = 5;
							dropdownlabel_0.Font = Enum.Font.Arial;
							dropdownlabel_0.FontFace = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
							dropdownlabel_0.Text = option;
							dropdownlabel_0.TextColor3 = Color3.fromRGB(201.00000321865082, 201.00000321865082, 201.00000321865082);
							dropdownlabel_0.TextSize = 12;
							dropdownlabel_0.TextWrapped = true;
							dropdownlabel_0.TextXAlignment = Enum.TextXAlignment.Left;
							dropdownlabel_0.Name = option

							dropdownlabel_0.MouseEnter:Connect(function()
								if table.find(lib.flags[flag]["selected"], option) then return end
								lib:tween(dropdownlabel_0, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(255, 255, 255)})
							end)

							dropdownlabel_0.MouseLeave:Connect(function()
								if table.find(lib.flags[flag]["selected"], option) then return end
								lib:tween(dropdownlabel_0, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(201, 201, 201)})
							end)

							dropdownlabel_0.InputBegan:Connect(function(input)
								if input.UserInputType == Enum.UserInputType.MouseButton1 then
									if not multi then
										element:close_dropdown()
									end
									if not table.find(lib.flags[flag]["selected"], option) then
										local clone = lib.flags[flag]["selected"]
										table.insert(clone, option)
										element:set_options(clone)
									elseif table.find(lib.flags[flag]["selected"], option) and not no_none then
										local clone = lib.flags[flag]["selected"]
										table.remove(clone, table.find(clone, option))
										element:set_options(clone)
									end
								end
							end)
						end
						
						lib.onConfigLoaded:Connect(function()
							element:set_options(lib.flags[flag]["selected"])
						end)
					
						
						element:set_options({default})
					end
					
					if table.find(types, "textbox") then
						main_element.Size = UDim2.new(1, 0, 0, 36)
						section:update_size(22)
						local textboxbox = Instance.new("Frame", main_element);
						textboxbox.BackgroundColor3 = Color3.fromRGB(41.00000135600567, 41.00000135600567, 41.00000135600567);
						textboxbox.Name = "textboxbox";
						textboxbox.Position = UDim2.new(0, 0, 0, 16);
						textboxbox.Size = UDim2.new(1, 0, 0, 18);

						local UICorner = Instance.new("UICorner", textboxbox);
						UICorner.CornerRadius = UDim.new(0, 3);

						local textboxinside = Instance.new("Frame", textboxbox);
						textboxinside.BackgroundColor3 = Color3.fromRGB(21.000000648200512, 21.000000648200512, 21.000000648200512);
						textboxinside.Name = "textboxinside";
						textboxinside.Position = UDim2.new(0, 1, 0, 1);
						textboxinside.Size = UDim2.new(1, -2, 1, -2);

						local UICorner_0 = Instance.new("UICorner", textboxinside);
						UICorner_0.CornerRadius = UDim.new(0, 3);

						local realtextbox = Instance.new("TextBox", textboxinside);
						realtextbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
						realtextbox.BackgroundTransparency = 1;
						realtextbox.Name = "realtextbox";
						realtextbox.Position = UDim2.new(0, 6, 0, 0);
						realtextbox.Size = UDim2.new(1, -6, 1, 0);
						realtextbox.Font = Enum.Font.Arial;
						realtextbox.FontFace = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
						realtextbox.PlaceholderColor3 = Color3.fromRGB(100.00000163912773, 100.00000163912773, 100.00000163912773);
						realtextbox.PlaceholderText = "enter text";
						realtextbox.Text = "";
						realtextbox.TextColor3 = Color3.fromRGB(201.00000321865082, 201.00000321865082, 201.00000321865082);
						realtextbox.TextSize = 14;
						realtextbox.TextXAlignment = Enum.TextXAlignment.Left;
						realtextbox.ClearTextOnFocus = false;
						
						function element:set_text(text)
							realtextbox.Text = text
							lib.flags[flag]["text"] = text
							pcall(callback, text)
						end
						
						realtextbox.FocusLost:Connect(function()
							element:set_text(realtextbox.Text)
						end)
						
						element:set_text("")
						
						lib.onConfigLoaded:Connect(function()
							element:set_text(lib.flags[flag]["text"])
						end)
					end
					
					if table.find(types, "button") then
						main_element.Size = UDim2.new(1, 0, 0, 20)
						section:update_size(6)
						elementlabel.Visible = false
						local name = args["name"]
						local buttonbox = Instance.new("Frame", main_element);
						buttonbox.BackgroundColor3 = Color3.fromRGB(41.00000135600567, 41.00000135600567, 41.00000135600567);
						buttonbox.Name = "buttonbox";
						buttonbox.Size = UDim2.new(1, 0, 0, 18);

						local UICorner = Instance.new("UICorner", buttonbox);
						UICorner.CornerRadius = UDim.new(0, 3);

						local buttoninside = Instance.new("Frame", buttonbox);
						buttoninside.BackgroundColor3 = Color3.fromRGB(21.000000648200512, 21.000000648200512, 21.000000648200512);
						buttoninside.Name = "buttoninside";
						buttoninside.Position = UDim2.new(0, 1, 0, 1);
						buttoninside.Size = UDim2.new(1, -2, 1, -2);

						local UICorner_0 = Instance.new("UICorner", buttoninside);
						UICorner_0.CornerRadius = UDim.new(0, 3);

						local buttonlabel = Instance.new("TextLabel", buttoninside);
						buttonlabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
						buttonlabel.BackgroundTransparency = 1;
						buttonlabel.Name = "buttonlabel";
						buttonlabel.Size = UDim2.new(1, 0, 1, -2);
						buttonlabel.Font = Enum.Font.Arial;
						buttonlabel.FontFace = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
						buttonlabel.Text = name;
						buttonlabel.TextColor3 = Color3.fromRGB(201.00000321865082, 201.00000321865082, 201.00000321865082);
						buttonlabel.TextSize = 14;

						local confirmationlabel = Instance.new("TextLabel", main_element);
						confirmationlabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
						confirmationlabel.BackgroundTransparency = 1;
						confirmationlabel.Name = "confirmationlabel";
						confirmationlabel.Size = UDim2.new(0, 85, 1, -2);
						confirmationlabel.Visible = false;
						confirmationlabel.Font = Enum.Font.Arial;
						confirmationlabel.FontFace = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
						confirmationlabel.Text = "are you sure?";
						confirmationlabel.TextColor3 = Color3.fromRGB(201.00000321865082, 201.00000321865082, 201.00000321865082);
						confirmationlabel.TextSize = 14;
						confirmationlabel.TextXAlignment = Enum.TextXAlignment.Left;

						local confirmationbox = Instance.new("Frame", confirmationlabel);
						confirmationbox.BackgroundColor3 = Color3.fromRGB(41.00000135600567, 41.00000135600567, 41.00000135600567);
						confirmationbox.BorderColor3 = Color3.fromRGB(27.000000290572643, 42.000001296401024, 53.00000064074993);
						confirmationbox.Name = "confirmationbox";
						confirmationbox.Position = UDim2.new(1, 0, 0, 0);
						confirmationbox.Size = UDim2.new(0, 128, 1, 0);

						local UICorner_1 = Instance.new("UICorner", confirmationbox);
						UICorner_1.CornerRadius = UDim.new(0, 3);

						local confirmationinside = Instance.new("Frame", confirmationbox);
						confirmationinside.BackgroundColor3 = Color3.fromRGB(21.000000648200512, 21.000000648200512, 21.000000648200512);
						confirmationinside.BorderColor3 = Color3.fromRGB(27.000000290572643, 42.000001296401024, 53.00000064074993);
						confirmationinside.Name = "confirmationinside";
						confirmationinside.Position = UDim2.new(0, 1, 0, 1);
						confirmationinside.Size = UDim2.new(1, -2, 1, -2);

						local UICorner_2 = Instance.new("UICorner", confirmationinside);
						UICorner_2.CornerRadius = UDim.new(0, 3);

						local divider = Instance.new("Frame", confirmationinside);
						divider.BackgroundColor3 = Color3.fromRGB(41.00000135600567, 41.00000135600567, 41.00000135600567);
						divider.BorderSizePixel = 0;
						divider.Name = "divider";
						divider.Position = UDim2.new(0.5, 0, 0, 0);
						divider.Size = UDim2.new(0, 1, 1, 0);

						local yeslabel = Instance.new("TextLabel", confirmationinside);
						yeslabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
						yeslabel.BackgroundTransparency = 1;
						yeslabel.Name = "yeslabel";
						yeslabel.Size = UDim2.new(0.49000000953674316, 0, 1, 0);
						yeslabel.Font = Enum.Font.Arial;
						yeslabel.FontFace = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
						yeslabel.Text = "yes";
						yeslabel.TextColor3 = Color3.fromRGB(201.00000321865082, 201.00000321865082, 201.00000321865082);
						yeslabel.TextSize = 14;

						local nolabel = Instance.new("TextLabel", confirmationinside);
						nolabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
						nolabel.BackgroundTransparency = 1;
						nolabel.Name = "nolabel";
						nolabel.Position = UDim2.new(0.5, 0, 0, 0);
						nolabel.Size = UDim2.new(0.49000000953674316, 0, 1, 0);
						nolabel.Font = Enum.Font.Arial;
						nolabel.FontFace = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
						nolabel.Text = "no";
						nolabel.TextColor3 = Color3.fromRGB(201.00000321865082, 201.00000321865082, 201.00000321865082);
						nolabel.TextSize = 14;
						
						function element:on_button_hover(bool)
							lib:tween(buttonbox, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(52, 52, 52)})
						end

						function element:on_button_leave(bool)
							lib:tween(buttonbox, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(41, 41, 41)})
						end
						
						buttonbox.MouseEnter:Connect(function()
							element:on_button_hover()
						end)

						buttonbox.MouseLeave:Connect(function()
							element:on_button_leave()
						end)

	
						local confirmation = args["confirmation"]
						
						local on_confirmation = false
						
						if confirmation then
							buttonbox.InputBegan:Connect(function(input)
								if not lib.busy and input.UserInputType == Enum.UserInputType.MouseButton1 then									
									buttonbox.Visible = false
									confirmationlabel.Visible = true
								end
							end)
							
							yeslabel.MouseEnter:Connect(function()
								yeslabel.TextColor3 = Color3.fromRGB(194, 155, 165)
							end)
							
							yeslabel.MouseLeave:Connect(function()
								yeslabel.TextColor3 = Color3.fromRGB(201, 201, 201)
							end)
							
							yeslabel.InputBegan:Connect(function(input)
								if input.UserInputType == Enum.UserInputType.MouseButton1 then	
									buttonbox.Visible = true
									confirmationlabel.Visible = false
									pcall(callback)
								end
							end)
							
							nolabel.InputBegan:Connect(function(input)
								if input.UserInputType == Enum.UserInputType.MouseButton1 then	
									buttonbox.Visible = true
									confirmationlabel.Visible = false
								end
							end)
							
							nolabel.MouseEnter:Connect(function()
								nolabel.TextColor3 = Color3.fromRGB(194, 155, 165)
							end)
							
							nolabel.MouseLeave:Connect(function()
								nolabel.TextColor3 = Color3.fromRGB(201, 201, 201)
							end)
						else
							buttonbox.InputBegan:Connect(function(input)
								if not lib.busy and input.UserInputType == Enum.UserInputType.MouseButton1 then									
									buttonlabel.TextColor3 = Color3.fromRGB(194, 155, 165)
									pcall(callback)
								end
							end)
							
							buttonbox.InputEnded:Connect(function(input)
								if input.UserInputType == Enum.UserInputType.MouseButton1 then									
									buttonlabel.TextColor3 = Color3.fromRGB(201,201,201)
								end
							end)
						end
						
					end

					return element
				end
				
				return section
			end
			
			return sub_tab
		end
				
		return tab
	end
	
	return window
end

lib.getConfigList = function()
    local cfgs = listfiles("eunoia/configs/")
    local returnTable = {}
    for _, file in pairs(cfgs) do
        local str = tostring(file)
        if string.sub(str, #str-3, #str) == ".cfg" then
            table.insert(returnTable, string.sub(str, 16, #str-4))
        end
    end
    return returnTable
end

-- ! end lib

-- * Bypasses

task.wait(1.5)

LPH_JIT_MAX(function()
	local old = getrenv().wait
	getrenv().wait = newcclosure(function(arg)
		if not checkcaller() and arg == 3 then
			return old(9e9)
		end
		return old(arg)
	end)
end)()

loadstring([[
	for i,v in pairs(getgc()) do
		if typeof(v) == "function" and debug.getinfo(v, "n").name == "Ts" then
			hookfunction(v, function(...)
				return wait(9e9)
			end)
		elseif typeof(v) == "function" and string.find(debug.getinfo(v, "s").source, "Network") then
			if table.find(getconstants(v), "FireServer") then
				_G.hit_func = v
			end
		end
	end
]])()

local old = getrenv().tick
local fake_tick = false

services.UserInputService.InputBegan:connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        fake_tick = true
    end
end)

getrenv().tick = newcclosure(function(...)
    local s = getcallingscript()
    if not checkcaller() and s and tostring(s) == "knifeScript" and lib.flags["fast_throw"]["toggle"] then
        if not fake_tick then
            return old() + lib.flags["fast_throw"]["value"]/100
        else
            fake_tick = false
        end
    end
    return old(...)
end)

task.wait(.5)

-- * Base variables

local client = {plr = services.Players.LocalPlayer}; client.mouse = client.plr:GetMouse(); client.recent = false
	function client:get_character()
		return client.plr.Character or client.plr.CharacterAdded:Wait()
	end
	function client:is_character_loaded()
		local parts = {"Head","HumanoidRootPart","Humanoid"}
		for i,v in pairs(parts) do
			if not client.get_character():FindFirstChild(v) then
				return false
			end
		end
		return true
	end

-- * Core lib

local core = {}

core.drawing_tween = loadstring(game:HttpGet("https://raw.githubusercontent.com/vozoid/utility/main/Tween.lua"))()

function core:is_key_down(key)
    return services.UserInputService:IsKeyDown(key)
end

function core:find_in_table(t, l)
	for i = 1, #t do
		local o = t[i]
		if l == o then
			return i
		end
	end
	return
end

function core:lerp(a,b,t)
	 return a * (1-t) + b * t
 end

function core:new_2drawing(type, properties)
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

-- * Start cheat initilization

local cheat = {
	states = {"still", "running", "jumping", "falling"},
	playstyles = {"afk", "strafe", "jumpy strafe", "other", "jumpy"},
	connections = {},
	drawings = {players = {}},
	esp = {},
	knife_ready = true,
	player_information = {},
	aim_circle = core:new_2drawing("Circle", {
		ZIndex = 5,
		Thickness = 1,
		Filled = false
	}),
	knives = {},
	target = nil,
	stop_ghost = false,
	equip_ready = true,
	old_values = {
		ClockTime = game.Lighting.ClockTime,
		Ambient = game.Lighting.Ambient,
		FieldOfView = workspace.CurrentCamera.FieldOfView,
		FogColor = game.Lighting.FogColor,
		FogStart = game.Lighting.FogStart,
		FogEnd = game.Lighting.FogEnd
	},
	fake = game:GetObjects("rbxassetid://11868212008")[1],
	lagging = false,
	lag_cooldown = false,
	no_lag = false,
	hit_player = function() end,
	hitlogs = {},
	og_position = Vector3.new(),
	teleporting = false,
	hitsounds = {cod = "rbxassetid://160432334", bameware = "rbxassetid://6565367558", neverlose = "rbxassetid://6565370984", skeet = "rbxassetid://4817809188", rust = "rbxassetid://6565371338"}
}

local on_player_hit = lib.signal.new("on_player_hit")
_G.on_player_hit = on_player_hit

cheat.hit_player = _G.hit_func

loadstring([[
	local old;
	old = hookfunction(_G.hit_func, function(...)
		local args = {...}
		_G.on_player_hit:Fire(args)
		return old(unpack(args))
	end)]]
)()

cheat.fake.Parent = game.CoreGui

for _, part in pairs(cheat.fake:GetChildren()) do
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

function cheat:is_in_game()
	return client.plr.PlayerGui.ScreenGui.UI.Target.Visible
end

function cheat:create_hitmarker(size, offset)
	local sides = {
		{-1,-1,-2,-2},
		{1,1,2,2},
		{-1,1,-2,2},
		{1, -1, 2, -2},
	}

	local hitmarker = {size = 40, start_point = Vector2.new(), offset = 20, lines = {}, outlines = {}}

	function hitmarker:set_color(color)
		for i = 1, #hitmarker.lines do
			local line = hitmarker.lines[i]
			line.Color = color
		end
	end

	function hitmarker:set_visible(bool)
		for i = 1, #hitmarker.lines do
			local line = hitmarker.lines[i]
			line.Visible = bool
		end
		for i = 1, #hitmarker.outlines do
			local line = hitmarker.outlines[i]
			line.Visible = bool
		end
	end

	function hitmarker:set_transparency(transparency)
		for i = 1, #hitmarker.lines do
			local line = hitmarker.lines[i]
			line.Transparency = -transparency+1
		end
		for i = 1, #hitmarker.outlines do
			local line = hitmarker.outlines[i]
			line.Transparency = -transparency+1
		end
	end

	function hitmarker:remove()
		for i = 1, #hitmarker.lines do
			local line = hitmarker.lines[i]
			line:Remove()
		end
		for i = 1, #hitmarker.outlines do
			local line = hitmarker.outlines[i]
			line:Remove()
		end
		sides = nil; hitmarker = nil
	end

	function hitmarker:set_position(start_point, size, offset)
		for i = 1, #hitmarker.lines do
			local line = hitmarker.lines[i]
			local side = sides[i]
			line.From = start_point + Vector2.new(side[1]*offset, side[2]*offset)
			line.To = start_point + Vector2.new(side[3]*size, side[4]*size)
		end
		for i = 1, #hitmarker.outlines do
			local line = hitmarker.outlines[i]
			local line2 = hitmarker.lines[i]
			line.From = line2.From
			line.To = line2.To
		end
	end

	for i = 1, #sides do
		local side = sides[i]
		local line = Drawing.new("Line")
		line.Thickness = 1
		line.Transparency = 1
		line.ZIndex = 2
		line.Color = Color3.fromRGB(255,255,255)
		table.insert(hitmarker.lines, line)
		local outline = Drawing.new("Line")
		outline.Thickness = 3
		outline.Transparency = 1
		outline.ZIndex = 1
		outline.Color = Color3.fromRGB(0,0,0)
		table.insert(hitmarker.outlines, outline)
	end

	return hitmarker
end

function cheat.esp:create_table(player)
	local esp_table = {}

	esp_table.tracer = core:new_2drawing("Line", {
		ZIndex = 1,
		Thickness = 1
	})
	esp_table.box = core:new_2drawing("Square", {
		ZIndex = 2,
		Thickness = 1,
		Filled = false
	})
	esp_table.fill = core:new_2drawing("Square", {
		ZIndex = 1,
		Thickness = 1,
		Filled = true
	})
	esp_table.outline = core:new_2drawing("Square", {
		ZIndex = 1,
		Thickness = 3,
		Filled = false
	})
	esp_table.name = core:new_2drawing("Text", {
		ZIndex = 4,
		Center = true,
		Outline = true
	})
	esp_table.distance = core:new_2drawing("Text", {
		ZIndex = 4,
		Center = true,
		Outline = true
	})
	esp_table.has_knife = core:new_2drawing("Text", {
		ZIndex = 4,
		Center = true,
		Outline = true
	})
	esp_table.throwbox = core:new_2drawing("Line", {
		ZIndex = 2,
		Thickness = 1,
	})
	esp_table.throwoutline = core:new_2drawing("Line", {
		ZIndex = 1,
		Thickness = 3,
	})
	esp_table.triangle = core:new_2drawing("Triangle", {
		Thickness = 1,
		ZIndex = 3,
	})
	return esp_table
end

function cheat:render_hitlog(n, d, p)
	local hitlog = {}
	local total = 0

	local hit = core:new_2drawing("Text", {
		ZIndex = 6,
		Center = true,
		Outline = true,
		Color = Color3.fromRGB(201,201,201),
		Size = 21,
		Text = "hit",
		Transparency = 1
	}); table.insert(hitlog, hit)

	local inn = core:new_2drawing("Text", {
		ZIndex = 6,
		Center = true,
		Outline = true,
		Color = Color3.fromRGB(201,201,201),
		Size = 21,
		Text = "in",
		Transparency = 1
	}); table.insert(hitlog, inn)

	local from = core:new_2drawing("Text", {
		ZIndex = 6,
		Center = true,
		Outline = true,
		Color = Color3.fromRGB(201,201,201),
		Size = 21,
		Text = "from",
		Transparency = 1
	}); table.insert(hitlog, from)

	local name = core:new_2drawing("Text", {
		ZIndex = 6,
		Center = true,
		Outline = true,
		Color = Color3.fromRGB(201,201,201),
		Size = 21,
		Text = n,
		Transparency = 1
	}); table.insert(hitlog, name)

	local distance = core:new_2drawing("Text", {
		ZIndex = 6,
		Center = true,
		Outline = true,
		Color = Color3.fromRGB(201,201,201),
		Size = 21,
		Text = d.." studs",
		Transparency = 1
	}); table.insert(hitlog, distance)

	local part = core:new_2drawing("Text", {
		ZIndex = 6,
		Center = true,
		Outline = true,
		Color = Color3.fromRGB(201,201,201),
		Size = 21,
		Text = p,
		Transparency = 1
	}); table.insert(hitlog, part)

	hitlog["og"] = -.4

	table.insert(cheat.hitlogs, hitlog)
end

function cheat:get_closest_to_cursor()
	local closest = 9e9
	local target = nil

	if client:is_character_loaded() then
		for _, plr in next, services.Players:GetPlayers() do
			if plr ~= client.plr then
				local character = cheat.player_information[plr.Name]:get_character()

				if character then
					local playerHumanoid = character:FindFirstChild("Humanoid")
					local hrp = character:FindFirstChild("HumanoidRootPart")
					if hrp and playerHumanoid then
						local hitVector, onScreen = workspace.CurrentCamera:WorldToScreenPoint(hrp.Position)
						if onScreen then
							local htm = (Vector2.new(client.mouse.X, client.mouse.Y) - Vector2.new(hitVector.X, hitVector.Y)).magnitude
							local threshold = lib.flags["fov_radius"]["value"]*1.5
							if htm < closest and htm <= threshold and (client:get_character().HumanoidRootPart.Position-hrp.Position).magnitude < 350 then
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

cheat.esp.connection = services.RunService:BindToRenderStep("esp", Enum.RenderPriority.Camera.Value + 1, LPH_JIT_MAX(function()
	for i, player in next, services.Players:GetPlayers() do
		local esp_table = cheat.drawings.players[player.Name]
		local player_information = cheat.player_information[player.Name]

		if not esp_table then
			continue
		end

		if not player_information then
			continue
		end

		for i,v in pairs(esp_table.drawings) do
			v.Visible = false
		end

		esp_table.highlight.Enabled = false

		if not lib.flags["pesp"]["toggle"] then
			continue
		end

		local character = player_information:get_character()

		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			local hum = character:FindFirstChildOfClass("Humanoid")
			if hrp and hum then
				local pos, visible = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
				local target = player == cheat.target

				if visible then
					local dist = (workspace.CurrentCamera.CFrame.Position-hrp.Position).magnitude
					if dist > lib.flags["max_distance"]["value"] then
						continue
					end

					local throwing = false
					local timepos = 1
					local anims = hum:GetPlayingAnimationTracks()
					for i = 1, #anims do
						local anim = anims[i]
						if anim.Animation.AnimationId == "http://www.roblox.com/Asset?ID=89147993" then
							timepos = anim.TimePosition
							throwing = true
							break
						end
					end
					
					local size = (workspace.CurrentCamera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.3, 0)).Y - workspace.CurrentCamera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.9, 0)).Y) / 2
					local box_size = Vector2.new(math.floor(size * 1.3), math.floor(size * 1.9))
					local box_pos = Vector2.new(math.floor(pos.X - size * 1.3 / 2), math.floor(pos.Y - size * 1.6 / 2))
					local font = lib.flags["font"]["selected"][1]
					
					if lib.flags["chams"]["toggle"] then
						local highlight = esp_table.highlight

						highlight.FillColor = not target and lib.flags["chams"]["color"] or lib.flags["t_chams"]["color"]
						highlight.FillTransparency = not target and lib.flags["chams"]["transparency"] or lib.flags["t_chams"]["transparency"]
						highlight.OutlineColor = not target and lib.flags["outline"]["color"] or lib.flags["t_outline"]["color"]
						highlight.OutlineTransparency = not target and lib.flags["outline"]["transparency"] or lib.flags["t_outline"]["transparency"]
						highlight.Adornee = character
						highlight.Enabled = true
					end

					if lib.flags["box"]["toggle"] then
						local box = esp_table.drawings.box
						local outline = esp_table.drawings.outline
						
						box.Size = box_size
						box.Position = box_pos
						box.Color = not target and lib.flags["box"]["color"] or lib.flags["t_box"]["color"]
						box.Transparency = not target and -lib.flags["box"]["transparency"]+1 or -lib.flags["t_box"]["transparency"]+1
						outline.Transparency = not target and -lib.flags["box"]["transparency"]+1 or-lib.flags["t_box"]["transparency"]+1
						outline.Size = box_size
						outline.Position = box_pos
						outline.Visible = true
						box.Visible = true
					end

					if lib.flags["fill"]["toggle"] then
						local fill = esp_table.drawings.fill
						
						fill.Size = box_size
						fill.Position = box_pos
						fill.Color = lib.flags["fill"]["color"]
						fill.Transparency = -lib.flags["fill"]["transparency"]+1
						fill.Visible = true
					end

					if lib.flags["name"]["toggle"] then
						local name = esp_table.drawings.name

						name.Text = player.Name 
						name.Position = Vector2.new(box_size.X / 2 + box_pos.X, box_pos.Y - name.TextBounds.Y - 1)
						name.Color = not target and lib.flags["name"]["color"] or lib.flags["t_name"]["color"] 
						name.Transparency = not target and -lib.flags["name"]["transparency"]+1 or -lib.flags["t_name"]["transparency"]+1
						name.Font = Drawing.Fonts[font]
						name.Size = not target and lib.flags["name"]["value"] or lib.flags["t_name"]["value"]
						name.Visible = true
					end

					local flag_offset = 0

					if lib.flags["throwbar"]["toggle"] then
						local throwpercent = (timepos*10)/5

						local throwbox = esp_table.drawings.throwbox
						local throwoutline = esp_table.drawings.throwoutline

						throwbox.From = Vector2.new(box_pos.X, (box_size.Y + box_pos.Y) + 4)
						throwbox.To = Vector2.new(throwbox.From.X + (throwpercent) * box_size.X, (box_size.Y + box_pos.Y) + 4)
						throwbox.Color = not target and lib.flags["throwbar"]["color"] or lib.flags["t_throwbar"]["color"] 
						throwbox.Transparency = not target and -lib.flags["throwbar"]["transparency"]+1 or -lib.flags["t_throwbar"]["transparency"]+1
						throwbox.Visible = throwing
		
						throwoutline.From = Vector2.new(throwbox.From.X, (box_size.Y + box_pos.Y) + 4)
						throwoutline.To = Vector2.new(throwbox.From.X + box_size.X, (box_size.Y + box_pos.Y) + 4)
						throwoutline.Visible = true
					end

					if lib.flags["has_knife"]["toggle"] and (player_information:has_knife() or player_information.on_knife_cooldown ) then
						local has_knife = esp_table.drawings.has_knife
						local text = ""
						if player_information:has_knife() then
							text = "K"
						else
							if player_information.on_knife_cooldown then
								text = player_information.on_knife_cooldown.."s"
							end
						end

						has_knife.Text = text
						has_knife.Color = not target and lib.flags["has_knife"]["color"] or lib.flags["t_has_knife"]["color"]
						has_knife.Size = not target and lib.flags["has_knife"]["value"] or lib.flags["t_has_knife"]["value"]
						has_knife.Font = Drawing.Fonts[font]
						has_knife.Position = Vector2.new((box_pos.X + box_size.X) + has_knife.TextBounds.X/2 + 2, box_pos.Y + flag_offset)
						has_knife.Visible = true

						flag_offset = flag_offset + has_knife.TextBounds.Y
					end

					if lib.flags["distance"]["toggle"] then
						local dist = tostring(math.round(dist)).."m"
						local distance = esp_table.drawings.distance

						distance.Text = dist
						distance.Color = not target and lib.flags["distance"]["color"] or lib.flags["t_distance"]["color"]
						distance.Size = not target and lib.flags["distance"]["value"] or lib.flags["t_distance"]["value"]
						distance.Font = Drawing.Fonts[font]
						distance.Position = Vector2.new((box_pos.X + box_size.X) + distance.TextBounds.X/2 + 2, box_pos.Y + flag_offset)
						distance.Visible = true

						flag_offset = flag_offset + distance.TextBounds.Y
					end
				elseif not visible then
					if lib.flags["offscreen"]["toggle"] then
						local triangle = esp_table.drawings.triangle
						local font = lib.flags["font"]["selected"][1]

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
							name.Color = not target and lib.flags["name"]["color"] or lib.flags["t_name"]["color"]
							name.Transparency = not target and -lib.flags["name"]["transparency"]+1 or -lib.flags["t_name"]["transparency"]+1
							name.Font = Drawing.Fonts[font]
							name.Size = not target and lib.flags["name"]["value"] or lib.flags["t_name"]["value"]
							name.Position = middle + Vector2.new(0, name.TextBounds.Y)
							name.Visible = true
						end
						
						triangle.Color = not target and lib.flags["offscreen"]["color"] or lib.flags["t_offscreen"]["color"]
						triangle.Transparency = not target and -lib.flags["offscreen"]["transparency"]+1 or -lib.flags["t_offscreen"]["transparency"]+1
					end
				end
			end
		end
	end
end))

function cheat.esp:remove_esp(player)
	local esp_table = cheat.drawings.players[player.Name]
	for i,v in pairs(esp_table.drawings) do
		v:Remove()
	end
	esp_table.highlight:Destroy()
end

function cheat.esp:add_esp(player)
	local esp_table = {drawings = cheat.esp:create_table(player), highlight = nil}

	esp_table.highlight = Instance.new("Highlight")
	esp_table.highlight.Parent = game.CoreGui
	esp_table.highlight.Enabled = false
	esp_table.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	esp_table.highlight.Name = player.Name

	cheat.drawings.players[player.Name] = esp_table
end

function cheat:stop_packet(hrp)
	if not cheat.no_lag then
		sethiddenproperty(hrp, "NetworkIsSleeping", true)
	end
end

function cheat:do_lag()
	if not cheat.lag_cooldown then
		cheat.lagging = true
		cheat.lag_cooldown = true
		local cooldown = (lib.flags["fakelag"]["value"]/200) * (math.random(100,115)/100)
		local cooldown2 = (lib.flags["fakelag"]["value"]/400) * (math.random(100,115)/100)
		coroutine.wrap(function()
			task.wait(cooldown)
			cheat.lagging = false
			task.wait(cooldown2)
			cheat.lag_cooldown = false
		end)()
	end
end

function cheat:get_state_from_velocity(velocity)
	if velocity.Y > 11 then
		return "jumping"
	elseif velocity.Y < -11 then
		return "falling"
	end
	if math.abs(velocity.X) > 4 or math.abs(velocity.Z) > 4 then
		return "running"
	end
	return "still"
end

function cheat:init_player(player)
	local name = player.Name
	local info_table = {
		recorded_positions = {},
		state_counters = {
			still = {
				count = 0
			},
			jumping = {
				count = 0
			},
			strafe = {
				count = 0
			}
		},
		playstyle = "other",
		on_record_cooldown = false,
		on_knife_cooldown = false,
		in_game = false,
	}

	function info_table:get_character()
		return workspace:FindFirstChild(player.Name)
	end

	function info_table:start_knife_cooldown()
		local number = 5.0
		cheat.player_information[player.Name].on_knife_cooldown = number
		for i = 1, 50 do
			number = number - 0.1
			cheat.player_information[player.Name].on_knife_cooldown = string.sub(tostring((number)), 1, 3)
			task.wait(0.1)
		end
		cheat.player_information[player.Name].on_knife_cooldown = false
	end

	function info_table:has_knife()
		local knife = info_table:get_character():FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife")
		if knife then return true else return false end
	end

	function info_table:is_character_loaded()
		local character = info_table:get_character()
		if character then
			local parts = {"Head","HumanoidRootPart","Humanoid"}
			for i,v in pairs(parts) do
				if not character:FindFirstChild(v) then
					return false
				end
			end
			return true
		end
		return false
	end

	cheat.player_information[player.Name] = info_table
end

function cheat:predict_player(player, hrp)
	if lib.flags["custom_prediction"]["toggle"] then
		local vel = hrp.Velocity
		local state = cheat:get_state_from_velocity(vel)

		local x_vel = vel.X * lib.flags["running_prediction"]["value"]/200
		local y_vel = vel.Y > 0 and vel.Y * lib.flags["jumping_prediction"]["value"]/330 or vel.Y * lib.flags["falling_prediction"]["value"]/330
		local z_vel = vel.X * lib.flags["running_prediction"]["value"]/200

		local distance = (client:get_character().HumanoidRootPart.Position-hrp.Position).magnitude/51
		local equation = distance*lib.flags["distance_multiplier"]["value"]/100

		return hrp.Position + Vector3.new(x_vel*equation,y_vel + distance,z_vel*equation)
	else
		local vel = hrp.Velocity
		local prediction = Vector3.new()
		local state = cheat:get_state_from_velocity(vel)
		local player_information = cheat.player_information[player.Name]

		local distance = (client:get_character().HumanoidRootPart.Position-hrp.Position).magnitude/51
		prediction = prediction + Vector3.new(0,distance,0)
		local distance = (client:get_character().HumanoidRootPart.Position-hrp.Position).magnitude/48

		if state == "jumping" then
			prediction = prediction - Vector3.new(0, 1.20, 0)
			prediction = prediction + Vector3.new(0, math.clamp((math.abs(vel.Y)/26*distance)*distance/2, 0, 1.75), 0)
		elseif state == "falling" then
			prediction = prediction - Vector3.new(0, .4, 0)
			prediction = prediction - Vector3.new(0, math.clamp((math.abs(vel.Y)/26*distance)*distance/2, 0, 1.1), 0)
		end

		return hrp.Position + prediction
	end
end

function cheat:add_connection(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(cheat.connections, connection)
	return connection
end

local win = lib:create_window()
local aimbot = win:create_tab({name = "aimbot", icon = "http://www.roblox.com/asset/?id=12407137599"})
	local aimbot_general = aimbot:create_subtab({name = "general"})
		local general_aimhelper = aimbot_general:create_section({name = "aim helper"})
			local aim_helper = general_aimhelper:create_element({name = "enabled", flag = "aim_helper", c_default = Color3.fromRGB(255,255,255), t_default = false, types = {"toggle", "keybind"}, callback = function()
			end})
			local silent_aim = general_aimhelper:create_element({name = "silent aim", flag = "silent_aim", t_default = false, types = {"toggle"}, callback = function()
			end})
			local visible_check = general_aimhelper:create_element({name = "visible check", flag = "visible_check", t_default = false, types = {"toggle"}, callback = function()
			end})
			local correct_jitter = general_aimhelper:create_element({name = "correct jitter", tip = "if player is strafing often, it will try to predict it", flag = "correct_jitter", t_default = false, types = {"toggle"}, callback = function()
			end})
			local custom_prediction = general_aimhelper:create_element({name = "use custom prediction", flag = "custom_prediction", t_default = false, types = {"toggle"}, callback = function()
			end})
			local fov_radius = general_aimhelper:create_element({name = "helper fov", flag = "fov_radius", types = {"slider"}, min = 30, max = 500, s_default = 50, callback = function()
				cheat.aim_circle.Radius = lib.flags["fov_radius"]["value"]*1.5
			end})
		local general_aimcircles = aimbot_general:create_section({name = "aim circles"})
			local show_fov = general_aimcircles:create_element({name = "show fov", flag = "show_fov", t_default = false, c_default = Color3.fromRGB(255,255,255), types = {"toggle", "colorpicker"}, callback = function()
				cheat.aim_circle.Color = lib.flags["show_fov"]["color"]
				cheat.aim_circle.Transparency = -lib.flags["show_fov"]["transparency"]+1
			end})
			local filled = general_aimcircles:create_element({name = "filled", flag = "fov_filled", t_default = false, types = {"toggle"}, callback = function()
				cheat.aim_circle.Filled = lib.flags["fov_filled"]["toggle"]
			end})
			local fov_sides = general_aimcircles:create_element({name = "sides", flag = "fov_sides", types = {"slider"}, min = 3, max = 30, s_default = 18, callback = function()
				cheat.aim_circle.NumSides = lib.flags["fov_sides"]["value"]
			end})
			local fov_offset = general_aimcircles:create_element({name = "offset", flag = "fov_offset", types = {"slider"}, min = 0, max = 50, s_default = 38, callback = function()
				cheat.aim_circle.Position = Vector2.new(client.mouse.X, client.mouse.Y + lib.flags["fov_offset"]["value"])
			end})
		local general_aimbotsettings = aimbot_general:create_section({name = "aimbot settings"})
			local random_smoothness = general_aimbotsettings:create_element({name = "randomness", flag = "randomness", t_default = false, types = {"toggle"}, callback = function()
			end})
			local vertical_smoothness = general_aimbotsettings:create_element({name = "vertical smoothing", flag = "vertical_smoothness", types = {"slider"}, min = 1, max = 20, s_default = 1, callback = function()
			end})
			local horizontal_smoothness = general_aimbotsettings:create_element({name = "horizontal smoothing", flag = "horizontal_smoothness", types = {"slider"}, min = 1, max = 20, s_default = 1, callback = function()
			end})
		local general_customprediction = aimbot_general:create_section({name = "custom prediction"})
			for i = 1, #cheat.states do
				local state = cheat.states[i]
				local state_prediction = general_customprediction:create_element({name = state.." prediction", flag = state.."_".."prediction", types = {"slider"}, min = -100, max = 100, s_default = 0, callback = function()
				end})
			end
			local distance_multiplier = general_customprediction:create_element({name = "distance multiplier", flag = "distance_multiplier", types = {"slider"}, min = 1, max = 100, s_default = 25, callback = function()
			end})
	local aimbot_other = aimbot:create_subtab({name = "other"})
		local other_hitboxes = aimbot_other:create_section({name = "hitboxes"})
			local hbe = other_hitboxes:create_element({name = "expand hitbox", flag = "hbe", c_default = Color3.fromRGB(255,255,255), types = {"toggle", "colorpicker", "dropdown"}, no_none = true, d_default = "forcefield", options = {"forcefield", "neon", "glass"}, callback = function()
			end})
			local adaptive_size = other_hitboxes:create_element({name = "adaptive size", flag = "adaptive_size", tip = "adjusts hitbox size based on velocity", types = {"toggle"}, callback = function()
			end})
			local visible_check2 = other_hitboxes:create_element({name = "visible check", flag = "visible_check2", types = {"toggle"}, no_none = true, d_default = "forcefield", callback = function()
			end})
			local hbex = other_hitboxes:create_element({name = "hitbox size x", flag = "hbe_x", s_default = 2, min = 2, max = 100, types = {"slider"}, callback = function()
			end})
			local hbey = other_hitboxes:create_element({name = "hitbox size y", flag = "hbe_y", s_default = 2, min = 2, max = 100, types = {"slider"}, callback = function()
			end})
			local hbez = other_hitboxes:create_element({name = "hitbox size z", flag = "hbe_z", s_default = 1, min = 1, max = 100, types = {"slider"}, callback = function()
			end})
		local other_knife = aimbot_other:create_section({name = "knife"})
			local menu_autoequip = other_knife:create_element({name = "auto equip", types = {"toggle", "slider"}, min = 30, max = 250, s_default = 50, suffix = "ms", flag = "auto_equip", callback = function(f)
			end})
			local delay_throw = other_knife:create_element({name = "delay throw", flag = "delay_throw", types = {"toggle", "slider"}, min = 30, max = 250, s_default = 30, suffix = "ms", callback = function()
			end})
			local fast_throw = other_knife:create_element({name = "fast throw", flag = "fast_throw", types = {"toggle", "slider"}, min = 1, max = 35, s_default = 1, suffix = "ms", callback = function()
			end})
local autofarm = win:create_tab({name = "autofarm", icon = "rbxassetid://12492180720"})
	local general = autofarm:create_subtab({name = "general"})
		local auto_kill = general:create_section({name = "auto kill"})
			local autokill = auto_kill:create_element({name = "enabled", flag = "autokill", types = {"toggle", "slider"}, s_default = 2, min = 1, max = 3, callback = function()
			end})
			local under = auto_kill:create_element({name = "under", flag = "under", types = {"toggle", "slider"}, s_default = 4, min = 0, max = 8, callback = function()
			end})
			local behind = auto_kill:create_element({name = "behind", flag = "behind", types = {"toggle", "slider"}, s_default = 2, min = 0, max = 5, callback = function()
			end})
			local remove_hitboxes = auto_kill:create_element({name = "remove hitboxes", multi = true, flag = "removehitboxes", types = {"toggle", "dropdown"}, options = {"limbs"}, callback = function()
			end})
		local collect = general:create_section({name = "auto collect"})
			local autoghost = collect:create_element({name = "collect ghost coins", flag = "autoghost", types = {"toggle"}, callback = function()
			end})
local motion = win:create_tab({name = "motion", icon = "rbxassetid://8680441960"})
	local general = motion:create_subtab({name = "general"})
		local movement = general:create_section({name = "movement"})
			local speed = movement:create_element({name = "speed", flag = "speed", min = 1, max = 60, types = {"toggle", "slider", "keybind"}, callback = function()
			end})
		local fake_lag = general:create_section({name = "fake lag"})
			local fakelag = fake_lag:create_element({name = "enabled", flag = "fakelag", min = 1, max = 100, types = {"toggle", "slider", "keybind"}, suffix = "%", callback = function()
			end})
			local fakelagvisual = fake_lag:create_element({name = "visualization", flag = "fakelagvisual", c_default = Color3.fromRGB(0,155,75), types = {"toggle", "colorpicker"}, callback = function()
			end})
			local disableonthrow = fake_lag:create_element({name = "compensate throw", tip = "attempts to compensate for the lag when throwing", flag = "disableonthrow", types = {"toggle"}, callback = function()
			end})
		local exploits = general:create_section({name = "exploits"})
			local semi_godmode = exploits:create_element({name = "semi godmode", flag = "1", types = {"button"}, callback = function()
				client:get_character().HumanoidRootPart:Destroy()
			end})
local visuals = win:create_tab({name = "visuals", icon = "http://www.roblox.com/asset/?id=12406796266"})
	local visuals_players = visuals:create_subtab({name = "players"})
		local players_esp = visuals_players:create_section({name = "enemy esp"})
			local esp_enabled = players_esp:create_element({name = "enabled", flag = "pesp", types = {"toggle"}, callback = function()
			end})
			local esp_box = players_esp:create_element({name = "box", flag = "box", c_default = Color3.fromRGB(255,255,255), types = {"toggle", "colorpicker"}, callback = function()
			end})
			local esp_fill = players_esp:create_element({name = "fill", flag = "fill", c_default = Color3.fromRGB(255,255,255), types = {"toggle", "colorpicker"}, callback = function()
			end})
			local esp_name = players_esp:create_element({name = "name", flag = "name", min = 10, max = 20, s_default = 14, suffix = "px", c_default = Color3.fromRGB(255,255,255), types = {"toggle", "slider", "colorpicker"}, callback = function()
			end})
			local esp_chams = players_esp:create_element({name = "chams", flag = "chams", c_default = Color3.fromRGB(255,255,255), types = {"toggle", "colorpicker"}, callback = function()
			end})
			local esp_outline = players_esp:create_element({name = "outline", flag = "outline", c_default = Color3.fromRGB(255,255,255), types = {"colorpicker"}, callback = function()
			end})
			local esp_distance = players_esp:create_element({name = "distance", flag = "distance", min = 10, max = 20, s_default = 14, suffix = "px", c_default = Color3.fromRGB(255,0,175), types = {"toggle", "slider", "colorpicker"}, callback = function()
			end})
			local esp_has_knife = players_esp:create_element({name = "has knife", flag = "has_knife", min = 10, max = 20, s_default = 14, suffix = "px", c_default = Color3.fromRGB(255,0,0), types = {"toggle", "slider", "colorpicker"}, callback = function()
			end})
			local esp_throwbar = players_esp:create_element({name = "throw bar", flag = "throwbar", c_default = Color3.fromRGB(255,0,0), types = {"toggle", "colorpicker"}, callback = function()
			end})
			local esp_offscreen = players_esp:create_element({name = "oof arrows", flag = "offscreen", min = 30, max = 250, s_default = 150, suffix = "", c_default = Color3.fromRGB(255,255,255), types = {"toggle", "colorpicker", "slider"}, callback = function()
			end})
			local esp_show_name = players_esp:create_element({name = "show name", flag = "show_name", types = {"toggle"}, callback = function()
			end})
			local esp_offscreen_distance = players_esp:create_element({name = "arrow distance", flag = "offscreen_distance", min = 50, max = 900, s_default = 400, suffix = "", types = {"slider"}, callback = function()
			end})
			local esp_max_distance = players_esp:create_element({name = "max distance", flag = "max_distance", min = 50, max = 500, s_default = 400, suffix = "", types = {"slider"}, callback = function()
			end})
			local esp_font = players_esp:create_element({name = "font", flag = "font", d_default = "Plex", no_none = true, types = {"dropdown"}, options = {"Plex", "System", "Monospace"}, callback = function()
			end})
		local target_esp = visuals_players:create_section({name = "target esp"})
			local esp_box = target_esp:create_element({name = "box", flag = "t_box", c_default = Color3.fromRGB(255,0,0), types = {"colorpicker"}, callback = function()
			end})
			local esp_fill = target_esp:create_element({name = "fill", flag = "t_fill", c_default = Color3.fromRGB(255,255,255), types = {"colorpicker"}, callback = function()
			end})
			local esp_name = target_esp:create_element({name = "name", flag = "t_name", min = 10, max = 20, s_default = 14, suffix = "px", c_default = Color3.fromRGB(255,255,255), types = {"slider", "colorpicker"}, callback = function()
			end})
			local esp_chams = target_esp:create_element({name = "chams", flag = "t_chams", c_default = Color3.fromRGB(0,0,0), types = {"colorpicker"}, callback = function()
			end})
			local esp_outline = target_esp:create_element({name = "outline", flag = "t_outline", c_default = Color3.fromRGB(255,255,255), types = {"colorpicker"}, callback = function()
			end})
			local esp_distance = target_esp:create_element({name = "distance", flag = "t_distance", min = 10, max = 20, s_default = 14, suffix = "px", c_default = Color3.fromRGB(255,0,175), types = {"slider", "colorpicker"}, callback = function()
			end})
			local esp_has_knife = target_esp:create_element({name = "has knife", flag = "t_has_knife", min = 10, max = 20, s_default = 14, suffix = "px", c_default = Color3.fromRGB(255,0,0), types = {"slider", "colorpicker"}, callback = function()
			end})
			local esp_throwbar = target_esp:create_element({name = "throw bar", flag = "t_throwbar", c_default = Color3.fromRGB(255,0,0), types = {"toggle", "colorpicker"}, callback = function()
			end})
			local esp_offscreen = target_esp:create_element({name = "oof arrows", flag = "t_offscreen", min = 30, max = 250, s_default = 150, suffix = "", c_default = Color3.fromRGB(255,255,255), types = {"colorpicker", "slider"}, callback = function()
			end})
	local visuals_world = visuals:create_subtab({name = "world"})
		local world_appearance = visuals_world:create_section({name = "game appearance"})
			local ambient = world_appearance:create_element({name = "world hue", flag = "ambient", c_default = cheat.old_values.Ambient, types = {"colorpicker", "toggle"}, callback = function()
				if lib.flags["ambient"]["toggle"] then
					game.Lighting.Ambient = lib.flags["ambient"]["color"]
				else
					game.Lighting.Ambient = cheat.old_values.Ambient 
				end
			end})
			local worldtime = world_appearance:create_element({name = "world time", min = 0, max = 24, flag = "clocktime", s_default = cheat.old_values.ClockTime, types = {"slider", "toggle"}, callback = function()
				if lib.flags["clocktime"]["toggle"] then
					game.Lighting.ClockTime = lib.flags["clocktime"]["value"]
				else
					game.Lighting.ClockTime = cheat.old_values.ClockTime 
				end
			end})
			local fog = world_appearance:create_element({name = "fog", flag = "fog", c_default = cheat.old_values.FogColor, types = {"colorpicker", "toggle"}, callback = function()
				if lib.flags["fog"]["toggle"] then
					game.Lighting.FogColor = lib.flags["fog"]["color"]
				else
					game.Lighting.FogColor = cheat.old_values.FogColor
				end
			end})
			local fogstart = world_appearance:create_element({name = "fog start", flag = "fogstart", s_default = cheat.old_values.FogStart, types = {"slider"}, sdefault = 500, min = 1, max = 5000, callback = function()
				if lib.flags["fog"]["toggle"] then
					game.Lighting.FogStart = lib.flags["fogstart"]["value"]
				else
					game.Lighting.FogStart = cheat.old_values.FogStart
					game.Lighting.FogColor = cheat.old_values.FogColor
					game.Lighting.FogEnd = cheat.old_values.FogEnd
				end
			end})
			local fogend = world_appearance:create_element({name = "fog end", flag = "fogend", s_default = cheat.old_values.FogEnd, types = {"slider"}, sdefault = 500, min = 1, max = 5000, callback = function()
				if lib.flags["fog"]["toggle"] then
					game.Lighting.FogEnd = lib.flags["fogend"]["value"]
				end
			end})
		local world_knife = visuals_world:create_section({name = "knife"})
			local forcefield_knife = world_knife:create_element({name = "forcefield knife", flag = "forcefield_knife", c_default = Color3.fromRGB(255,0,175), types = {"toggle", "colorpicker"},callback = function()
			end})
		local world_camera = visuals_world:create_section({name = "camera"})
			local field_of_view = world_camera:create_element({name = "field of view", min = 70, max = 120, flag = "fov", s_default = 70, types = {"slider", "toggle"}, callback = function()
				if lib.flags["fov"]["toggle"] then
					workspace.CurrentCamera.FieldOfView = lib.flags["fov"]["value"]
				else
					workspace.CurrentCamera.FieldOfView = 70
				end
			end})
			local cursor_hitmarker = world_camera:create_element({name = "hitmarker", min = 8, max = 16, flag = "cursor_hitmarker", s_default = 10, c_default = Color3.fromRGB(201,201,201), types = {"slider", "toggle", "colorpicker"}, suffix = "px", callback = function()
			end})
		local world_other = visuals_world:create_section({name = "other"})
			local hit_chams = world_other:create_element({name = "hit chams", no_none = true, d_default = "forcefield", options = {"forcefield", "neon", "glass",}, flag = "hit_chams", types = {"toggle", "dropdown", "colorpicker"}, c_default = Color3.fromRGB(255,255,255), callback = function()
			end})
			local hitsound = world_other:create_element({name = "hitsound", no_none = true, d_default = "skeet", options = {"skeet", "cod", "rust", "neverlose", "bameware"}, flag = "hitsound", types = {"toggle", "dropdown"}, callback = function()
			end})
			local hit_logs = world_other:create_element({name = "hit logs", options = {"on screen", "console"}, flag = "hitlogs", multi = true, types = {"toggle", "dropdown", "colorpicker"}, c_default = Color3.fromRGB(194, 155, 165), callback = function()
			end})
local misc = win:create_tab({name = "misc", icon = "http://www.roblox.com/asset/?id=12447089653"})
	local misc_main = misc:create_subtab({name = "main"})
		local main_config = misc_main:create_section({name = "config"})
			local config_list = main_config:create_element({name = "list", flag = "selected_config", options = lib.getConfigList(), types = {"dropdown"}, callback = function()
			end})
			local config_name = main_config:create_element({name = "name", flag = "text_config", types = {"textbox"}, callback = function()
			end})
			local config_create = main_config:create_element({name = "create config", flag = "2", types = {"button"}, callback = function()
				if not isfile("eunoia/configs/"..lib.flags["text_config"]["text"]..".cfg") then
					lib.saveConfig(lib.flags["text_config"]["text"])
					config_list:set_p_options(lib.getConfigList())
				end
			end})
			local reload_list = main_config:create_element({name = "reload list", types = {"button"}, callback = function()
				config_list:set_p_options(lib.getConfigList())
			end})
			local config_load = main_config:create_element({name = "load config", confirmation = true, flag = "3", types = {"button"}, callback = function()
				if isfile("eunoia/configs/"..lib.flags["selected_config"]["selected"][1]..".cfg") then
					lib.loadConfig(lib.flags["selected_config"]["selected"][1])
				end
			end})
			local config_save = main_config:create_element({name = "override config", confirmation = true, flag = "4", types = {"button"}, callback = function()
				if isfile("eunoia/configs/"..lib.flags["selected_config"]["selected"][1]..".cfg") then
					lib.saveConfig(lib.flags["selected_config"]["selected"][1])
				end
			end})
	local main_menu = misc_main:create_section({name = "menu"})
		local menu_togglekey = main_menu:create_element({name = "toggle key", flag = "toggle_key", types = {"keybind"}, k_default = {method = "toggle", key = "leftalt"}, callback = function()
		end})
	local main_other = misc_main:create_section({name = "other"})
		local menu_antiafk = main_other:create_element({name = "anti afk", flag = "anti_afk", types = {"toggle"}, callback = function()
			for i,v in pairs(getconnections(client.plr.Idled)) do
				if lib.flags["anti_afk"]["toggle"] then v:Disable() else v:Enable() end
			end
		end})

-- * Hookmetamethods

local old_index = nil
old_index = hookmetamethod(game, "__index", LPH_JIT_MAX(function(self, index)
	if not checkcaller() and index == "Size" and tostring(self) == "HumanoidRootPart" and self:IsDescendantOf(workspace) then
        return Vector3.new(2,2,1)
    end
    return old_index(self, index)
end))

LPH_NO_VIRTUALIZE(function()
	local old_namecall = nil
	old_namecall = hookmetamethod(game, "__namecall", function(self, ...)
		local args = {...}
		local method = getnamecallmethod()
		local script2; 
		if not fluxus then
			script2 = getcallingscript()
		elseif fluxus then
			script2 = not checkcaller() and "knifeScript" or "D"
		end
		if tostring(script2) == "knifeScript" and self == workspace and method == "FindPartOnRayWithIgnoreList" then
			if _G.z then
				local camera = workspace.CurrentCamera.CFrame.p
				local pos = _G.z2
				if pos then
					args[1] = Ray.new(camera, ((pos + Vector3.new(0,(camera-pos).Magnitude/150,0) - camera).unit * (150 * 10)))
				end
			end
			return old_namecall(self, unpack(args))
		elseif not checkcaller() and method == "FireServer" and tostring(self) == "ThrowKnife" then
			coroutine.wrap(function()
			_G.threw_knife_signal:Fire()
			end)()
			if _G.l == true then
				_G.l2 = args
				return
			end
		end
		return old_namecall(self, ...)
	end)
end)()

-- * Connections

local on_mouse_move = cheat:add_connection(client.mouse.Move, function()
	cheat.aim_circle.Position = Vector2.new(client.mouse.X, client.mouse.Y + lib.flags["fov_offset"]["value"])
end)

cheat.knives = {}

local on_render = cheat:add_connection(services.RunService.RenderStepped, LPH_JIT_MAX(function()
	cheat.aim_circle.Position = Vector2.new(client.mouse.X, client.mouse.Y + lib.flags["fov_offset"]["value"])
	cheat.aim_circle.Visible = aim_helper:get_active() and lib.flags["aim_helper"]["toggle"] and lib.flags["show_fov"]["toggle"]

	if client:get_character() and client:is_character_loaded() then
		if lib.flags["speed"]["toggle"] and speed.get_active() and client:get_character().Humanoid.MoveDirection ~= Vector3.new() then
			client:get_character().HumanoidRootPart.CFrame = client:get_character().HumanoidRootPart.CFrame + (client:get_character().Humanoid.MoveDirection / 50) * lib.flags["speed"]["value"]/10
		end
		if aim_helper:get_active() and lib.flags["aim_helper"]["toggle"] then
			_G.z = lib.flags["silent_aim"]["toggle"]
			local closest = cheat:get_closest_to_cursor()
			cheat.closest = closest
			if not closest then _G.z2 = nil end
			if closest then
				local info = cheat.player_information[closest.Name]
				local character = info:get_character()
				if not character then _G.z2 = nil end
				if character and info:is_character_loaded() then
					local hrp = character.HumanoidRootPart
					local visible = true
					if lib.flags["visible_check"]["toggle"] then
						visible = #workspace.CurrentCamera:GetPartsObscuringTarget({client:get_character().Head.Position, character.Head.Position}, {client:get_character(), character, workspace.KnifeHost, workspace.Pets}) == 0
					end
					if not visible then _G.z2 = nil end
					if visible then
						local prediction = cheat:predict_player(closest, hrp)
						local visible = true
						visible = #workspace.CurrentCamera:GetPartsObscuringTarget({client:get_character().Head.Position, prediction}, {client:get_character(), character, workspace.KnifeHost, workspace.Pets}) == 0
						if visible then
							if lib.flags["silent_aim"]["toggle"] then 
								_G.z2 = prediction
							else
								local pos, visible = workspace.CurrentCamera:WorldToScreenPoint(prediction)
								local pos2 = workspace.CurrentCamera:WorldToScreenPoint(client.mouse.Hit.p)
								if visible then
									local new_posx = pos.X - pos2.X
									local new_posy = pos.Y - pos2.Y
									local dividend = lib.flags["horizontal_smoothness"]["value"]
									local dividend2 = lib.flags["vertical_smoothness"]["value"]
									if lib.flags["randomness"]["toggle"] then
										dividend = dividend + math.random(1,2)
										dividend2 = dividend2 + math.random(1,3)
									end
									mousemoverel(new_posx / dividend, new_posy / dividend2)
								end
							end
						end
					end
				end
			end
		else
			_G.z2 = nil
			_G.z = false
		end
	end
	if lib.flags["fov"]["toggle"] then
		workspace.CurrentCamera.FieldOfView = lib.flags["fov"]["value"]
	end
	for i = 1, #cheat.hitlogs do
		local done = false
		local hitlog = cheat.hitlogs[i]
		if hitlog then
			local y_offset = 120 + i*21
			local vpsize = workspace.CurrentCamera.ViewportSize
			local tb1, tb2, tb3, tb4, tb5, tb6 = hitlog[1].TextBounds.X, hitlog[2].TextBounds.X, hitlog[3].TextBounds.X, hitlog[4].TextBounds.X, hitlog[5].TextBounds.X, hitlog[6].TextBounds.X
			local hit, inn, from, name, distance, part = hitlog[1], hitlog[2], hitlog[3], hitlog[4], hitlog[5], hitlog[6]
			local collective = 20
			collective = tb1 + tb2 + tb3 + tb4 + tb5 + tb6

			local tikk = hitlog["og"]
			hitlog["og"] = hitlog["og"] + 0.001
			local transparency = core:lerp(0, 1, hitlog["og"])

			local y_pos = vpsize.Y/2 + y_offset
			local x_pos = vpsize.X/2
			hit.Position = Vector2.new(x_pos - collective/2 - 2, y_pos)
			name.Position = hit.Position + Vector2.new(4 + tb1/2 + tb4/2, 0)
			inn.Position = name.Position + Vector2.new(4 + tb4/2 + tb2/2, 0)
			part.Position = inn.Position + Vector2.new(4 + tb2/2 + tb6/2, 0)
			from.Position = part.Position + Vector2.new(4 + tb6/2 + tb3/2, 0)
			distance.Position = from.Position + Vector2.new(4 + tb3/2 + tb5/2, 0)
			hit.Visible = true; inn.Visible = true; from.Visible = true; name.Visible = true; distance.Visible = true; part.Visible = true;
			name.Color = lib.flags["hitlogs"]["color"]; distance.Color = lib.flags["hitlogs"]["color"]; part.Color = lib.flags["hitlogs"]["color"]
			local ran = math.random(3)
			for i = 1, #hitlog do
				local drew = hitlog[i]
				drew.Transparency = drew.Transparency - transparency
				if drew.Transparency <= 0 then
					drew:Remove()
					done = true
				end
			end
			if done then
				cheat.hitlogs[i] = nil
				hitlog = nil
			end
		end
	end
end))

local on_player_added = cheat:add_connection(services.Players.PlayerAdded, function(player)
	if player == client.plr then return end
	cheat:init_player(player)
	cheat.esp:add_esp(player)

	player.CharacterAdded:Connect(function()
		cheat.player_information[player.Name].recorded_positions = {}
		cheat.player_information[player.Name].state_counters = {
			still = {
				count = 0
			},
			jumping = {
				count = 0
			},
			strafe = {
				count = 0
			}
		}
		cheat.player_information[player.Name].playstyle = "other"
		cheat.player_information[player.Name].in_game = false

		local player_information = cheat.player_information[player.Name]

		local character = player_information:get_character()
		local humanoid = character:WaitForChild("Humanoid")

		humanoid.Died:Connect(function()
			cheat.player_information[player.Name].in_game = false
		end)
	end)
end)

local on_player_removing = cheat:add_connection(services.Players.PlayerRemoving, function(player)
	if player == client.plr then return end
	cheat.esp:remove_esp(player)
end)

for _, player in pairs(services.Players:GetPlayers()) do
	if player == client.plr then continue end
	cheat:init_player(player)
	cheat.esp:add_esp(player)
	player.CharacterAdded:Connect(function()
		cheat.player_information[player.Name].recorded_positions = {}
		cheat.player_information[player.Name].state_counters = {
			still = {
				count = 0
			},
			jumping = {
				count = 0
			},
			strafe = {
				count = 0
			}
		}
		cheat.player_information[player.Name].playstyle = "other"
		cheat.player_information[player.Name].in_game = false
	
		local player_information = cheat.player_information[player.Name]
	
		local character = player_information:get_character()
		local humanoid = character:WaitForChild("Humanoid")
	
		humanoid.Died:Connect(function()
			cheat.player_information[player.Name].in_game = false
		end)
	end)
end

local ambient_change = cheat:add_connection(game.Lighting:GetPropertyChangedSignal("Ambient"), function()
	if game.Lighting.Ambient ~= lib.flags["ambient"]["color"] then
		cheat.old_values.Ambient = game.Lighting.Ambient
	end
	if lib.flags["ambient"]["toggle"] then
		game.Lighting.Ambient = lib.flags["ambient"]["color"]
	end
end)

cheat:add_connection(services.ReplicatedStorage.Remotes.TargetMessage.OnClientEvent, LPH_JIT_MAX(function(...)
	local args = {...}
    if lib.flags["hitsound"]["toggle"] and (string.find(string.lower(args[1]), "elim") or string.find(string.lower(args[1]), "claim")) then
        client.recent = true
        local newSound = Instance.new("Sound", client.plr.PlayerGui)
        newSound.Name = "\\\\"
        newSound.SoundId = cheat.hitsounds[lib.flags["hitsound"]["selected"][1]]
        newSound.Volume = 1
        newSound.PlayOnRemove = true
        newSound:Destroy()
    end
	if string.find(string.lower(args[1]), "wrong") then
		coroutine.wrap(function()
			task.wait(5.1)
			cheat.equip_ready = true
		end)()
    end
end))

local ragdoll_added = cheat:add_connection(workspace.Ragdolls.ChildAdded, LPH_JIT_MAX(function(ragdoll)
	repeat task.wait() until ragdoll:FindFirstChild("Torso") and ragdoll:FindFirstChild("Torso"):FindFirstChild("Dead")
    local torso = ragdoll:FindFirstChild("Torso")
    local sound = torso:FindFirstChild("Dead")
    if lib.flags["hitsound"]["toggle"] and client.recent then
        sound.Volume = 0
    end
    client.recent = false
end))

local character_added = cheat:add_connection(client.plr.CharacterAdded, LPH_JIT_MAX(function()
	if lib.flags["autoghost"]["toggle"] and not cheat.stop_ghost then
		cheat.stop_ghost = true
		services.ReplicatedStorage.Remotes.RequestGhostSpawn:InvokeServer()
		coroutine.wrap(function()
            task.wait(5)
            if not workspace:FindFirstChild("GameMap") and client:is_character_loaded() then
                client:get_character():BreakJoints()
            end
        end)()
	end
end))

local clocktime_change = cheat:add_connection(game.Lighting:GetPropertyChangedSignal("ClockTime"), function()
	if game.Lighting.ClockTime ~= lib.flags["clocktime"]["value"] then
		cheat.old_values.ClockTime = game.Lighting.ClockTime
	end
	if lib.flags["clocktime"]["toggle"] then
		game.Lighting.ClockTime = lib.flags["clocktime"]["value"]
	end
end)

local fogcolor_change = cheat:add_connection(game.Lighting:GetPropertyChangedSignal("FogColor"), function()
	if game.Lighting.FogColor ~= lib.flags["fog"]["color"] then
		cheat.old_values.FogColor = game.Lighting.FogColor
	end
	if lib.flags["fog"]["toggle"] then
		game.Lighting.FogColor = lib.flags["fog"]["color"]
	end
end)

local fogstart_change = cheat:add_connection(game.Lighting:GetPropertyChangedSignal("FogStart"), function()
	if game.Lighting.FogStart ~= lib.flags["fogstart"]["value"] then
		cheat.old_values.FogStart = game.Lighting.FogStart
	end
	if lib.flags["fog"]["toggle"] then
		game.Lighting.FogStart = lib.flags["fogstart"]["value"]
	end
end)

local fogend_change = cheat:add_connection(game.Lighting:GetPropertyChangedSignal("FogEnd"), function()
	if game.Lighting.FogEnd ~= lib.flags["fogend"]["value"] then
		cheat.old_values.FogEnd = game.Lighting.FogEnd
	end
	if lib.flags["fog"]["toggle"] then
		game.Lighting.FogEnd = lib.flags["fogend"]["value"]
	end
end)

local function convert_material(material)
	if material == "forcefield" then
		return Enum.Material.ForceField
	elseif material == "neon" then
		return Enum.Material.Neon
	elseif material == "glass" then
		return Enum.Material.Glass 
	end
end

local cursor_hitmarker = cheat:create_hitmarker()

on_player_hit:Connect(LPH_JIT_MAX(function(args)
	local tt = args[1]
	local method = args[5]
	if tt == "kill" and method == "throw" then
		local name = tostring(args[2])
		local distance = args[6]
		local part = args[7]
		if lib.flags["hitlogs"]["toggle"] then
			local hitlog = string.format("hit %s in %s from %s studs", name, part, distance)
			if core:find_in_table(lib.flags["hitlogs"]["selected"], "console") then
				printconsole(hitlog)
			end
			if core:find_in_table(lib.flags["hitlogs"]["selected"], "on screen") then
				cheat:render_hitlog(name, distance, part)
			end
		end
		if lib.flags["cursor_hitmarker"]["toggle"] then
			local player = services.Players:FindFirstChild(name)
			if name then
				local info = cheat.player_information[name]
				if info then
					local character = info:get_character()
					if character and info:is_character_loaded() then
						local connection;
						local int = 0

						cursor_hitmarker:set_visible(true)

						connection = cheat:add_connection(services.RunService.RenderStepped, function()
							int = int + .5
							
							cursor_hitmarker:set_position(Vector2.new(client.mouse.X, client.mouse.Y + 38), lib.flags["cursor_hitmarker"]["value"], 10)
							cursor_hitmarker:set_color(lib.flags["cursor_hitmarker"]["color"])

							if int < 21 then
								cursor_hitmarker:set_transparency(1-(int/20))
							elseif int < 41 then
							elseif int < 61 then
								cursor_hitmarker:set_transparency(0+((int-40)/20))
							else
								connection:Disconnect()
								cursor_hitmarker:set_visible(false)
							end
						end)
					end
				end
			end
		end
		if lib.flags["hit_chams"]["toggle"] then
			local player = services.Players:FindFirstChild(name)
			if name then
				local info = cheat.player_information[name]
				if info then
					local character = info:get_character()
					if character and info:is_character_loaded() then
						character.Archivable = true
						local clone = character:Clone()
						for i,v in pairs(clone:GetDescendants()) do
							if string.find(v.ClassName, "Part") and v.ClassName ~= "ParticleEmitter" then
								v.Anchored = true
								v.CanCollide = false
								v.Material = convert_material(lib.flags["hit_chams"]["selected"][1])
								v.Color = lib.flags["hit_chams"]["color"]
								v.Transparency = 1
								coroutine.wrap(function()
									lib:tween(v, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = lib.flags["hit_chams"]["transparency"]})
									task.wait(0.6)
									lib:tween(v, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1})
								end)()
							end
							if v.Name == "HumanoidRootPart" or v.Name == "baseHitbox" or v.Name == "Humanoid" or v.Name == "Shirt" or v.Name == "Pants" or v.ClassName == "Decal" then
								v:Destroy()
							end
						end
						clone.Parent = workspace.KnifeHost
						coroutine.wrap(function()
							task.wait(1.1)
							clone:Destroy()
						end)()
					end
				end
			end
		end
	end
end))

_G.threw_knife_signal:Connect(LPH_JIT_MAX(function(name)
	task.wait(0.03)
	if lib.flags["delay_throw"]["toggle"] and _G.l2 then
		coroutine.wrap(function()
			task.wait(lib.flags["delay_throw"]["value"]/1000)
			services.ReplicatedStorage.Remotes.ThrowKnife:FireServer(unpack(_G.l2))
		end)()
	end
	if lib.flags["disableonthrow"]["toggle"] and lib.flags["fakelag"]["toggle"] and fakelag.get_active() then 
		coroutine.wrap(function()
			cheat.no_lag = true
			task.wait(0.15)
			cheat.no_lag = false
		end)()
	end
end))

-- * Main Loops

local main_loop = cheat:add_connection(services.RunService.Heartbeat, LPH_JIT_MAX(function()
	local players = services.Players:GetPlayers()
	win.hotkey = lib.flags["toggle_key"]["key"]
	cheat.target = services.Players:FindFirstChild(client.plr.PlayerGui.ScreenGui.UI.Target.TargetText.Text)
	_G.l = lib.flags["delay_throw"]["toggle"]
	local tool2 = client.plr.Backpack:FindFirstChildOfClass("Tool")
	if cheat.stop_ghost == true and cheat:is_in_game() then cheat.stop_ghost = false end
	if lib.flags["auto_equip"]["toggle"] and cheat.equip_ready then
        if client:is_character_loaded() then
			if tool2 then
				coroutine.wrap(function()
					cheat.equip_ready = false
					task.wait(lib.flags["auto_equip"]["value"]/1000)
					if tool2.Parent == client.plr.Backpack then
						client:get_character().Humanoid:EquipTool(tool2)
					end
				end)()
			end
        end
    end
	for i = 1, #players do
		local plr = players[i]
		if plr == client.plr then continue end
		local info = cheat.player_information[plr.Name]
		if info then
			local character = info:get_character()
			if character and info:is_character_loaded() then
				local hrp = character.HumanoidRootPart
				local check = lib.flags["hbe"]["toggle"]
				if lib.flags["visible_check2"]["toggle"] and client:is_character_loaded() then
					check = #workspace.CurrentCamera:GetPartsObscuringTarget({client:get_character().Head.Position, character.Head.Position}, {client:get_character(), character, workspace.KnifeHost, workspace.Pets}) == 0
				end
				hrp.Transparency = check and lib.flags["hbe"]["transparency"] or 1
				hrp.Color = check and lib.flags["hbe"]["color"] or Color3.fromRGB(255,255,255)
				hrp.Material = check and convert_material(lib.flags["hbe"]["selected"][1]) or Enum.Material.Plastic
				hrp.CanCollide = false
				local size = Vector3.new(lib.flags["hbe_x"]["value"], lib.flags["hbe_y"]["value"], lib.flags["hbe_z"]["value"])
				if check then
					if lib.flags["adaptive_size"]["toggle"] then
						local state = cheat:get_state_from_velocity(hrp.Velocity)
						if state == "running" then
							size = size * Vector3.new(0.85,0.85,0.85)
						elseif state == "jumping" then
							size = size * Vector3.new(0.55,0.55,0.55)
						elseif state == "falling" then
							size = size * Vector3.new(0.55,0.55,0.55)
						end
						if size.Y < 2 then
							size = Vector3.new(size.X, 2, size.Z)
						end
						if size.X < 2 then
							size = Vector3.new(2, size.Y, size.Z)
						end
						if size.Z < 1 then
							size = Vector3.new(size.X, size.Y, 1)
						end
					end
				end
				hrp.Size = check and size or Vector3.new(2,2,1)
			end
		end
	end
	if client:is_character_loaded() then
		local character = client:get_character()
		local tool = character:FindFirstChildOfClass("Tool")
		local baseKnife = character:FindFirstChild("KnifeHandle") 
        if baseKnife then
            local knifeDeco = baseKnife:FindFirstChild("KnifeDecorationHandle") 
            if knifeDeco then
                knifeDeco.Material = lib.flags["forcefield_knife"]["toggle"] and Enum.Material.ForceField or Enum.Material.Plastic
                knifeDeco.Color = lib.flags["forcefield_knife"]["color"]
            end
        end
        if tool then
            local handle = tool:FindFirstChild("Handle")
            if handle then
                local knifeDeco = handle:FindFirstChild("KnifeDecorationHandle") 
                if knifeDeco then
                    knifeDeco.Material = lib.flags["forcefield_knife"]["toggle"] and Enum.Material.ForceField or Enum.Material.Plastic
                    knifeDeco.Color = lib.flags["forcefield_knife"]["color"]
                end
            end
        end
		if lib.flags["autoghost"]["toggle"] then
            for _, coin in pairs(workspace.GhostCoins:GetDescendants()) do
				if coin.ClassName == "TouchTransmitter" then
					firetouchinterest(client:get_character().HumanoidRootPart, coin.Parent, 0)
				end
            end
        end
		if lib.flags["autokill"]["toggle"] and ((tool or tool2) or cheat:is_in_game()) then
			for i,v in pairs(client:get_character():GetChildren()) do
				if string.find(v.ClassName, "Part") then
					v.Velocity = Vector3.new(0,2,0)
				end
			end
		end
		if cheat:is_in_game() then
			if lib.flags["autokill"]["toggle"] then
				if workspace:FindFirstChild("GameMap") then
					workspace.GameMap:Destroy()
				end
				if lib.flags["removehitboxes"]["toggle"] then
					for _, part in pairs(client:get_character():GetChildren()) do
						if core:find_in_table(lib.flags["removehitboxes"]["selected"], "limbs") then
							if string.find(part.Name, "Leg") or string.find(part.Name, "Arm") then
								part:Destroy()
							end
						end
					end
				end
				local yes = false
				if cheat.target then
					local info = cheat.player_information[cheat.target.Name]
					local char = info:get_character()
					if char and info:is_character_loaded() then
						yes = true
						lib:tween(client:get_character().HumanoidRootPart, TweenInfo.new(0+((1-lib.flags["autokill"]["value"])/50), Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {CFrame = (char.HumanoidRootPart.CFrame - Vector3.new(0, lib.flags["under"]["value"]/1.5, 0)) - (char.HumanoidRootPart.CFrame.lookVector * lib.flags["behind"]["value"]/1.5)})
						if (client:get_character().HumanoidRootPart.Position-char.HumanoidRootPart.Position).magnitude < 10 then
							if cheat.knife_ready then
								coroutine.wrap(function()
									cheat.knife_ready = false
									cheat.hit_player("kill", cheat.target, newproxy(), nil, "stab")
									task.wait(0.74)
									cheat.knife_ready = true
								end)()
							end
						end
					end
				end
				if not yes then lib:tween(client:get_character().HumanoidRootPart, TweenInfo.new(9e9, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {CFrame = client:get_character().HumanoidRootPart.CFrame}) end
			end
		end
		if fakelag.get_active() and lib.flags["fakelag"]["toggle"] and lib.flags["fakelag"]["toggle"] then
			cheat.fake.Parent = workspace.KnifeHost
			for _, part in pairs(cheat.fake:GetChildren()) do
				part.Transparency = lib.flags["fakelagvisual"]["toggle"] and lib.flags["fakelagvisual"]["transparency"] or 1
				part.Color = lib.flags["fakelagvisual"]["color"]
			end
			if not cheat.lag_cooldown then
				for _, part in pairs(cheat.fake:GetChildren()) do
					local found_part = client:get_character():FindFirstChild(part.Name)
					if found_part then
						part.CFrame = found_part.CFrame
					end
				end
			end
			cheat:do_lag()
		else
			cheat.fake.Parent = game.CoreGui
			cheat.lagging = false
		end
		if cheat.lagging then
			cheat:stop_packet(client:get_character().HumanoidRootPart)
		end
	end
end))
