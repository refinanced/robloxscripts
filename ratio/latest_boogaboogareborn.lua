local services = setmetatable({}, { __index = function(self, key) return game:GetService(key) end })
local etheria = {}
local lib = {handler = {}, flags = {}, copied_color = {}}

lib.copied_color["color"] = Color3.fromRGB(255,255,255)
lib.copied_color["transparency"] = 0

function lib:get_killsays()
	if isfile("etheria/killsays.txt") then
		local files;
		local m, err = pcall(function()
			files = services.HttpService:JSONDecode(readfile("etheria/killsays.txt"))
		end)
		if not err and files then
			return files
		else
			printconsole(err)
		end
	end
end

LPH_JIT = function(...) return ... end 
LPH_JIT_MAX = function(...) return ... end
LPH_NO_VIRTUALIZE = function(...) return ... end
LPH_HOOK_FIX = function(...) return ... end
LPH_NO_UPVALUES = function(...) return ... end

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

local draw3 = loadstring(game:HttpGet("https://raw.githubusercontent.com/Blissful4992/ESPs/main/3D%20Drawing%20Api.lua"))()

services.UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		lib.onClick:Fire()
	end
end)

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

if not isfolder("etheria") then
	makefolder("etheria")
end

if not isfolder("etheria/configs") then
	makefolder("etheria/configs")
end

if not isfile("etheria/killsays.txt") then
	writefile("etheria/killsays.txt", "[\"sponsored by etheria\", \"we love you tecca!\"]")
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
		local new_values = game.HttpService:JSONDecode(dec(readfile("etheria/configs/"..cfgName..".cfg")))

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
			writefile("etheria/configs/"..cfgName..".cfg",enc(game.HttpService:JSONEncode(values_copy)))
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
		Text = "etheria";
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

	window.main = main

	if getgenv().configuration and getgenv().configuration.no_gui then
		main.Enabled = false
	end
	
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
			
			local sub_tab = {active_subtab = "", sections = {}, left_size = 26, right_size = 26}
			
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

				if sectionframe.Parent == left then
					sub_tab.left_size = sub_tab.left_size + 56
				else
					sub_tab.right_size = sub_tab.right_size + 56
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
						if sub_tab.right_size > sub_tab.left_size then
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
								elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
									key = "mouse1"
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
								elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
									key = "mouse1"
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
							elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
								key = "mouse1"
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
						local togglecopy = lib:create_element("Frame", {
							BackgroundColor3 = Color3.fromRGB(21, 21, 21);
							BorderSizePixel = 0;
							Position = UDim2.new(0, 1, 0, 1);
							Size = UDim2.new(1, -2, 1, -2);
							Parent = togglebox
						}, {"Randomize"})
						local toggleinside = lib:create_element("Frame", {
							BackgroundColor3 = Color3.fromRGB(21, 21, 21);
							BorderSizePixel = 0;
							Position = UDim2.new(0, 1, 0, 1);
							Size = UDim2.new(1, -2, 1, -2);
							Parent = togglecopy
						}, {"Randomize"})
						local corner5 = lib:create_element("UICorner", {
							Parent = toggleinside;
							CornerRadius = UDim.new(0, 3)
						}, {"Randomize"})
						local corner6 = lib:create_element("UICorner", {
							Parent = togglebox;
							CornerRadius = UDim.new(0, 3)
						}, {"Randomize"})
						local corner6 = lib:create_element("UICorner", {
							Parent = togglecopy;
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

						local slidercopy = Instance.new("Frame", sliderinside);
						slidercopy.BackgroundTransparency = 1
						slidercopy.Name = "slidercopy";
						slidercopy.Position = UDim2.new(0, 1, 0, 1);
						slidercopy.Size = UDim2.new(1, -2, 1, -2);

						local sliderfill = Instance.new("Frame", slidercopy);
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
    local cfgs = listfiles("etheria/configs/")
    local returnTable = {}
    for _, file in pairs(cfgs) do
        local str = tostring(file)
        if string.sub(str, #str-3, #str) == ".cfg" then
            local tb = services.HttpService:JSONDecode(dec(readfile(file)))
            if (tb["game_id"] and game.GameId == tonumber(tb["game_id"])) or not tb["game_id"] then
                table.insert(returnTable, string.sub(str, 17, #str-4))
            end
        end
    end
    return returnTable
end

-- ! end lib

local quik = {}

function quik.find(keeper, obj)
	local length = #keeper
	for i = 1, length do
		local found = keeper[i]
		if obj == found then
			return i
		end
	end
	return false
end

local connection = {}
connection.__index = connection

function connection.new(signal, callback, keeper)
	local handle = signal:Connect(callback)
	local surge = {}

	setmetatable(surge, connection)

	surge.connection = handle

	if keeper then table.insert(handle, keeper) end

	return handle
end

function connection:stop()
	local connection = self.connection
	if self.keeper then table.remove(self.keeper, quik.find(self.keeper, connection)) end
	connection:Disconnect()
	self = nil
	return true
end

local draw = {}
draw.__index = draw

function draw.new(class, properties, other)
	local surge = Drawing.new(class); surge.Visible = false
	for property, value in pairs(properties) do
		surge[property] = value
	end

	return surge
end

local renderer = {
	esp = {}
}

function renderer:lerp(a,b,t)
	return a * (1-t) + b * t
end

-- ! player class

local function on_enemy_load(char)
	char.ChildAdded:Connect(function(tool)
		local name = tool.Name
		if tool.ClassName == "Model" and not name:find("Pet") and not name:find("Friend") and not name:find("Buddy") then
			if etheria.esp[char.Name] then
				etheria.esp[char.Name].tool.Text = name
			end
		end
	end)

	char.ChildRemoved:Connect(function(tool)
		local name = tool.Name
		if tool.ClassName == "Model" and not name:find("Pet") and not name:find("Friend") and not name:find("Buddy") then
			if etheria.esp[char.Name] then
				etheria.esp[char.Name].tool.Text = ""
			end
		end
	end)
end

local enemy = {}
enemy.__index = enemy

function enemy.new(instance, name)
	local surge = {}

	setmetatable(surge, enemy)

	surge.instance = instance
	surge.cooldown = false
	surge.in_game = false

	local player = instance

	local character = player.Character

	if character then
		on_enemy_load(character)
		for _, part in next, character:GetChildren() do
			local name = part.Name
			if part.ClassName == "Model" and not part.Name:find("Pet") and not part.Name:find("Friend") and not name:find("Buddy") then
				if etheria.esp[character.Name] then
					etheria.esp[character.Name].tool.Text = name
				end
			end
		end 
	end

	player.CharacterAdded:Connect(on_enemy_load)

	return surge
end

function enemy:is_loaded()
	local character = self.instance.Character

	local check_list = {"Head", "HumanoidRootPart", "Humanoid"}

	if character then
		local collective = {}

		for i = 1, #check_list do
			local part = check_list[i]
			if not character:FindFirstChild(part) then
				return false
			end
		end

		return true
	end
end

-- ! esp class

local esp = {}

function esp:create_drawings(plr)
	local esp_table = {}

	esp_table.box = draw.new("Square", {
		ZIndex = 2,
		Thickness = 1,
		Filled = false
	})
	esp_table.outline = draw.new("Square", {
		ZIndex = 1,
		Thickness = 3,
		Filled = false
	})
	esp_table.name = draw.new("Text", {
		ZIndex = 4,
		Center = true,
		Outline = true,
		Text = plr.Name
	})
    esp_table.tool = draw.new("Text", {
		ZIndex = 4,
		Center = true,
		Outline = true
	})
    esp_table.healthtext = draw.new("Text", {
		ZIndex = 4,
		Center = true,
		Outline = true
	})
	esp_table.armortext = draw.new("Text", {
		ZIndex = 3,
		Center = true,
		Outline = true
	})
	esp_table.healthbar = draw.new("Line", {
		ZIndex = 2,
		Thickness = 1,
	})
	esp_table.healthoutline = draw.new("Line", {
		ZIndex = 1,
		Thickness = 3,
	})

	esp_table.highlight = Instance.new("Highlight")
	esp_table.highlight.Parent = game.CoreGui
	esp_table.highlight.Enabled = false
	esp_table.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	esp_table.highlight.Name = "\255"

	return esp_table
end

-- ! client

local client = {plr = services.Players.LocalPlayer}; client.mouse = client.plr:GetMouse()
	function client:get_character()
		return client.plr.Character or client.plr.CharacterAdded:Wait()
	end
	function client:is_character_loaded()
		local parts = {"Head","HumanoidRootPart","Humanoid"}
		for i,v in pairs(parts) do
			if not client:get_character():FindFirstChild(v) then
				return false
			end
		end
		return true
	end
	do
        client.highlight = Instance.new("Highlight")
        client.highlight.Parent = game.CoreGui
        client.highlight.Enabled = false
        client.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        client.highlight.Name = "\255"
    end

-- ! connections

local connections = {}
local connection = {}

connection.__index = connection

function connection.new(signal, callback)
    local con = signal:Connect(callback)

    local surge = {connection = con}

    setmetatable(surge, connection)

    table.insert(connections, connection)

    return con
end

function connection:stop()
    self.connection:Disconnect()
    table.remove(connections, table.find(connections, self.connection))
end

-- ! etheria

etheria = {eggs = {}, on_heal_cooldown = false, old = {outdoorambient = game.Lighting.OutdoorAmbient, ambient = game.Lighting.Ambient, clocktime = game.Lighting.ClockTime, fogend = game.Lighting.FogEnd, fogstart = game.Lighting.FogStart, fogcolor = game.Lighting.FogColor}, aim_location = nil, aim_circle = draw.new("Circle", {Visible = false, Thickness = 1}), nodes = {}, esp = {}, players = {}, aura_cooldown = false, swing_cooldown = false, pickup_cooldown = false, killaura = draw3:New3DCircle(), look_at = Vector3.new(), jumps = 0, tp_cooldown = false}

-- ! gather funcs

local booga = {food_converts = {["bloodfruit"] = "Bloodfruit", ["bluefruit"] = "Bluefruit", ["sun fruit"] = "Sun Fruit", ["berry"] = "Berry", ["orange"] = "Orange"}}

for i,v in pairs(getgc(true)) do
    if typeof(v) == "function" and debug.getinfo(v, "n").name == "SwingTool" then
        if debug.getinfo(v, "s").source:find("Local Handler") then
            booga.swing_tool = v
        end
	elseif typeof(v) == "table" and rawget(v, "CanBearLoad") then
		booga.can_bear_load = rawget(v, "CanBearLoad")
		booga.has_item = rawget(v, "HasItem")
		local old_mojo = rawget(v, "HasMojoRecipe")
		rawset(v, "HasMojoRecipe", function(...)
			args = {...}
			if args[1] == "Water Walker" and lib.flags["water_walker"]["toggle"] then
				return true
			end
			return old_mojo(...)
		end)
    end
end

-- ! services

local players = services.Players
local rs = services.RunService
local repstorage = services.ReplicatedStorage
local uis = services.UserInputService

-- ! hooks

local old_index = nil
old_index = hookmetamethod(game, "__index", LPH_NO_VIRTUALIZE(function(self, index)
	if not checkcaller() and index == "Size" and tostring(self) == "HumanoidRootPart" then
		return Vector3.new(2,2,1)
	elseif not checkcaller() and index == "MaxSlopeAngle" and tostring(self) == "Humanoid" then
		return 46
	elseif not checkcaller() and etheria.old[index] then
		return etheria.old[index]
	end
	return old_index(self, index)
end))

-- ! target hud

local targethudlib = {opened = false}

do
	local TargetHud = Instance.new("ScreenGui");

	TargetHud.Name = "TargetHud";
	TargetHud.ZIndexBehavior = Enum.ZIndexBehavior.Global;
	TargetHud.Enabled = false
	if syn and syn.protect_gui then
		syn.protect_gui(TargetHud)
		TargetHud.Parent = game.CoreGui
	elseif gethui then
		Targethud.Parent = gethui() 
	end

	local BG = Instance.new("Frame", TargetHud);
	BG.BackgroundColor3 = Color3.fromRGB(11.000000294297934, 11.000000294297934, 11.000000294297934);
	BG.BackgroundTransparency = 0.20000000298023224;
	BG.BorderSizePixel = 0;
	BG.Name = "BG";
	BG.Position = UDim2.new(0.5, 30, 0.5, -45);
	BG.Size = UDim2.new(0, 250, 0, 90);

	local dropshadow = Instance.new("Frame", BG);
	dropshadow.BackgroundTransparency = 1;
	dropshadow.BorderSizePixel = 0;
	dropshadow.Name = "dropshadow";
	dropshadow.Size = UDim2.new(1, 0, 1, 0);
	dropshadow.ZIndex = 0;

	local shadowimage = Instance.new("ImageLabel", dropshadow);
	shadowimage.AnchorPoint = Vector2.new(0.5, 0.5);
	shadowimage.BackgroundTransparency = 1;
	shadowimage.BorderSizePixel = 0;
	shadowimage.Name = "shadowimage";
	shadowimage.Position = UDim2.new(0.5, 0, 0.5, 0);
	shadowimage.Size = UDim2.new(1, 47, 1, 47);
	shadowimage.ZIndex = 0;
	shadowimage.Image = "rbxassetid://6014261993";
	shadowimage.ImageColor3 = Color3.fromRGB(0, 0, 0);
	shadowimage.ImageTransparency = 0.5;
	shadowimage.ScaleType = Enum.ScaleType.Slice;
	shadowimage.SliceCenter = Rect.new(49, 49, 450, 450)
	local UICorner = Instance.new("UICorner", BG);

	local player_icon = Instance.new("ImageLabel", BG);
	player_icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	player_icon.BackgroundTransparency = 1;
	player_icon.Name = "player_icon";
	player_icon.Position = UDim2.new(0, 5, 0, 5);
	player_icon.Size = UDim2.new(0.23999999463558197, 0, 0.6700000166893005, 0);
	player_icon.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=1&width=420&height=420&format=png";

	local playertext = Instance.new("TextLabel", player_icon);
	playertext.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	playertext.BackgroundTransparency = 1;
	playertext.Name = "playertext";
	playertext.Position = UDim2.new(1.02, 0, 0.5, -10);
	playertext.Size = UDim2.new(2.799999952316284, 0, 0, 20);
	playertext.Font = Enum.Font.Gotham;
	playertext.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	playertext.Text = "ROBLOX";
	playertext.TextColor3 = Color3.fromRGB(255, 255, 255);
	playertext.TextScaled = true;
	playertext.TextSize = 14;
	playertext.TextStrokeTransparency = 0;
	playertext.TextWrapped = true;
	playertext.TextXAlignment = Enum.TextXAlignment.Left;

	local healthtext = Instance.new("TextLabel", player_icon);
	healthtext.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	healthtext.BackgroundTransparency = 1;
	healthtext.Name = "healthtext";
	healthtext.Position = UDim2.new(1.02, 0, 0.5, 10);
	healthtext.Size = UDim2.new(2.799999952316284, 0, 0, 16);
	healthtext.Font = Enum.Font.Gotham;
	healthtext.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	healthtext.Text = "100/100 HP";
	healthtext.TextColor3 = Color3.fromRGB(85.0000025331974, 255, 0);
	healthtext.TextScaled = true;
	healthtext.TextSize = 14;
	healthtext.TextStrokeTransparency = 0;
	healthtext.TextWrapped = true;
	healthtext.TextXAlignment = Enum.TextXAlignment.Left;

	local health_bar = Instance.new("Frame", BG);
	health_bar.BackgroundColor3 = Color3.fromRGB(10.000000353902578, 10.000000353902578, 10.000000353902578);
	health_bar.BorderColor3 = Color3.fromRGB(0, 0, 0);
	health_bar.Name = "health_bar";
	health_bar.Position = UDim2.new(0, 6, 1, -13);
	health_bar.Size = UDim2.new(1, -12, 0, 6);

	local UICorner_0 = Instance.new("UICorner", health_bar);
	UICorner_0.CornerRadius = UDim.new(1, 0);

	local bar_filll = Instance.new("Frame", health_bar);
	bar_filll.BackgroundColor3 = Color3.fromRGB(85.0000025331974, 255, 0);
	bar_filll.BorderColor3 = Color3.fromRGB(0, 0, 0);
	bar_filll.Name = "bar_filll";
	bar_filll.Size = UDim2.new(1, 0, 1, 0);

	local UICorner_1 = Instance.new("UICorner", bar_filll);
	UICorner_1.CornerRadius = UDim.new(1, 0);

	function targethudlib:open()
		targethudlib.opened = true 
		TargetHud.Enabled = true
		lib:tween(BG, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0.2})
		for _, element in next, BG:GetDescendants() do
			if element.ClassName == "TextLabel" then
				lib:tween(element, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0, TextStrokeTransparency = 0})
			elseif element.ClassName == "ImageLabel" then 
				lib:tween(element, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageTransparency = element ~= player_icon and 0.5 or 0})
			elseif element.ClassName == "Frame" and element ~= dropshadow then
				lib:tween(element, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
			end
		end
	end

	function targethudlib:update_health(health)
		healthtext.Text = tostring(math.round(health)).."/100"
		lib:tween(bar_filll, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(health/100, 0, 1, 0)})
	end

	function targethudlib:update_name(player)
		playertext.Text = player.Name
		player_icon.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..player.UserId.."&width=420&height=420&format=png";
	end

	function targethudlib:update_color(color, hum)
		if lib.flags["dynamic_color"]["toggle"] then
			local color = Color3.fromHSV((math.clamp(hum.Health/hum.MaxHealth,0,1))/3,1,1)
			bar_filll.BackgroundColor3 = color
			healthtext.TextColor3 = color
		else
			bar_filll.BackgroundColor3 = color
			healthtext.TextColor3 = color
		end
	end

	function targethudlib:close()
		targethudlib.opened = false 
		lib:tween(BG, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
		for _, element in next, BG:GetDescendants() do
			if element.ClassName == "TextLabel" then
				lib:tween(element, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 1, TextStrokeTransparency = 1})
			elseif element.ClassName == "ImageLabel" then 
				lib:tween(element, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageTransparency = 1})
			elseif element.ClassName == "Frame" and element ~= dropshadow then
				lib:tween(element, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
			end
		end
		task.spawn(function()
			task.wait(0.261)
			if not targethudlib.opened then
				TargetHud.Enabled = false
			end
		end)
	end
end

-- ! menu

local win = lib:create_window()

local combat = win:create_tab({name = "combat", icon = "http://www.roblox.com/asset/?id=12407137599"})
	local combat_main = combat:create_subtab({name = "main"})
		local general_aimhelper = combat_main:create_section({name = "aim helper"})
			local silent_aim = general_aimhelper:create_element({name = "silent aim", flag = "silent_aim", t_default = false, types = {"toggle", "keybind"}, callback = function()
			end})
			local fov_radius = general_aimhelper:create_element({name = "helper fov", flag = "fov_radius", types = {"slider"}, min = 5, max = 500, s_default = 50, callback = function()
				etheria.aim_circle.Radius = lib.flags["fov_radius"]["value"]*1.5
			end})
		local general_aimcircles = combat_main:create_section({name = "aim circles"})
			local show_fov = general_aimcircles:create_element({name = "show fov", flag = "show_fov", t_default = false, c_default = Color3.fromRGB(255,255,255), types = {"toggle", "colorpicker"}, callback = function()
				etheria.aim_circle.Color = lib.flags["show_fov"]["color"]
				etheria.aim_circle.Transparency = -lib.flags["show_fov"]["transparency"]+1
			end})
			local filled = general_aimcircles:create_element({name = "filled", flag = "fov_filled", t_default = false, types = {"toggle"}, callback = function()
				etheria.aim_circle.Filled = lib.flags["fov_filled"]["toggle"]
			end})
			local fov_sides = general_aimcircles:create_element({name = "sides", flag = "fov_sides", types = {"slider"}, min = 3, max = 30, s_default = 18, callback = function()
				etheria.aim_circle.NumSides = lib.flags["fov_sides"]["value"]
			end})
			local fov_offset = general_aimcircles:create_element({name = "offset", flag = "fov_offset", types = {"slider"}, min = 0, max = 50, s_default = 38, callback = function()
				etheria.aim_circle.Position = Vector2.new(client.mouse.X, client.mouse.Y + lib.flags["fov_offset"]["value"])
			end})
		local combat_helpers = combat_main:create_section({name = "helpers"})
			local swing_spam = combat_helpers:create_element({name = "swing spam", flag = "swing_spam", min = 1, max = 100, s_default = 1, suffix = "ms", t_default = false, types = {"toggle", "keybind", "slider"}, callback = function()
			end})
			local reach = combat_helpers:create_element({name = "reach", flag = "reach", min = 1, max = 11, s_default = 1, t_default = false, types = {"toggle", "slider"}, callback = function()
			end})
		local hitboxes = combat_main:create_section({name = "hitboxes"})
			local expander = hitboxes:create_element({name = "expander", flag = "expander", types = {"toggle", "dropdown", "colorpicker"}, c_default = Color3.fromRGB(255,255,255), options = {"forcefield", "neon"}, d_default = "forcefield", no_none = true, callback = function()
			end})
			local expanderx = hitboxes:create_element({name = "size x", flag = "sizex", types = {"slider"}, min = 2, max = 8, s_default = 2, callback = function()
			end})
			local expanderx = hitboxes:create_element({name = "size y", flag = "sizey", types = {"slider"}, min = 2, max = 8, s_default = 2, callback = function()
			end})
			local expanderx = hitboxes:create_element({name = "size z", flag = "sizez", types = {"slider"}, min = 1, max = 8, s_default = 1, callback = function()
			end})
		local combat_blatant = combat_main:create_section({name = "blatant"})
			local kill_aura = combat_blatant:create_element({name = "kill aura", flag = "kill_aura", types = {"toggle", "slider", "colorpicker", "keybind"}, c_default = Color3.fromRGB(255,255,255), min = 3, max = 8, s_default = 3, suffix = "", callback = function()
			end})
			local look_at = combat_blatant:create_element({name = "look at", flag = "look_at", types = {"toggle"}, callback = function()
			end})
local character_menu = win:create_tab({name = "character", icon = "rbxassetid://8680441960"})
    local movement = character_menu:create_subtab({name = "movement"})
        local move_motion = movement:create_section({name = "motion"})
			local double_jump = move_motion:create_element({name = "double jump", flag = "double_jump", types = {"toggle"}, callback = function()
			end})
			local anti_slide = move_motion:create_element({name = "anti slide", flag = "anti_slide", types = {"toggle"}, callback = function()
			end})
            local speed = move_motion:create_element({name = "speed", flag = "speed", types = {"toggle", "slider", "keybind"}, min = 1, max = 1000, s_default = 1, suffix = "%", callback = function()
            end})
			local tp_up = move_motion:create_element({name = "tp up", flag = "tp_up", types = {"toggle", "keybind", "slider"}, min = 50, max = 1000, s_default = 50, k_default = {method = "hold", key = "none"}, callback = function()
			end})
		local move_other = movement:create_section({name = "other"})
			local no_water_slow = move_other:create_element({name = "no water slow", flag = "water_walker", types = {"toggle"}, callback = function()
			end})
			local spinbot = move_other:create_element({name = "spin bot", flag = "spinbot", types = {"toggle", "slider"}, min = 1, max = 100, s_default = 1, suffix = "%", callback = function()
			end})
local visuals = win:create_tab({name = "visuals", icon = "http://www.roblox.com/asset/?id=12406796266"})
    local visuals_players = visuals:create_subtab({name = "players"})
        local players_esp = visuals_players:create_section({name = "player esp"})
            local esp_enabled = players_esp:create_element({name = "enabled",  t_default = false, flag = "pesp", types = {"toggle"}, callback = function()
            end})
            local esp_outline1 = players_esp:create_element({name = "outlines", t_default = false, flag = "outlines", types = {"toggle"}, callback = function()
            end})
            local esp_box = players_esp:create_element({name = "box", flag = "box", t_default = false, c_default = Color3.fromRGB(201,201,201), types = {"toggle", "colorpicker"}, callback = function()
            end})
            local esp_name = players_esp:create_element({name = "name", flag = "name", suffix = "px", c_default = Color3.fromRGB(201,201,201), types = {"toggle", "colorpicker"}, callback = function()
            end})
            local esp_tool = players_esp:create_element({name = "tool", flag = "tool", c_default = Color3.fromRGB(201,201,201), types = {"toggle", "colorpicker"}, callback = function()
            end})
            local esp_chams = players_esp:create_element({name = "chams", flag = "chams", c_default = Color3.fromRGB(0,0,0), types = {"toggle", "colorpicker"}, callback = function()
            end})
            local esp_outline = players_esp:create_element({name = "chams outline", flag = "outline", c_default = Color3.fromRGB(0,201,0), types = {"colorpicker"}, callback = function()
            end})
            local esp_healthbar = players_esp:create_element({name = "health bar", flag = "health", c_default = Color3.fromRGB(0,255,0), types = {"toggle", "colorpicker"}, callback = function()
            end})
            local esp_healthtext = players_esp:create_element({name = "health text", flag = "healthtext", types = {"toggle"}, callback = function()
            end})
            local esp_healthoverride = players_esp:create_element({name = "dynamic color", flag = "healthoverride", types = {"toggle"}, callback = function()
            end})
            local esp_font = players_esp:create_element({name = "font", flag = "font", d_default = "Plex", no_none = true, types = {"dropdown"}, options = {"Plex", "System", "Monospace"}, callback = function()
            end})
            local esp_fontsize = players_esp:create_element({name = "text size", flag = "fontsize", types = {"slider"}, min = 12, max = 20, s_default = 14, callback = function()
            end})
		local visuals_other = visuals:create_subtab({name = "other"})
			local visuals_world = visuals_other:create_section({name = "world"})
				local hue = visuals_world:create_element({name = "hue", flag = "hue", c_default = game.Lighting.Ambient, types = {"toggle", "colorpicker"}, callback = function()
					if lib.flags["hue"]["toggle"] then
						game.Lighting.Ambient = lib.flags["hue"]["color"]
					else
						game.Lighting.Ambient = etheria.old.ambient
					end
				end})
				local hue = visuals_world:create_element({name = "shadow hue", flag = "shadowhue", c_default = game.Lighting.OutdoorAmbient, types = {"toggle", "colorpicker"}, callback = function()
					if lib.flags["shadowhue"]["toggle"] then
						game.Lighting.OutdoorAmbient = lib.flags["shadowhue"]["color"]
					else
						game.Lighting.OutdoorAmbient = etheria.old.outdoorambient
					end
				end})
				local fov = visuals_world:create_element({name = "fov", flag = "fov", types = {"toggle", "slider"}, min = 65, max = 120, s_default = 70, callback = function()
				end})
				local worldtime = visuals_world:create_element({name = "time", min = 0, max = 24, flag = "clocktime", s_default = etheria.old.clocktime, types = {"slider", "toggle"}, callback = function()
					if lib.flags["clocktime"]["toggle"] then
						game.Lighting.ClockTime = lib.flags["clocktime"]["value"]
					else
						game.Lighting.ClockTime = etheria.old.clocktime
					end
				end})
				local fog = visuals_world:create_element({name = "fog", flag = "fog", c_default = etheria.old.fogcolor, types = {"colorpicker", "toggle"}, callback = function()
					if lib.flags["fog"]["toggle"] then
						game.Lighting.FogColor = lib.flags["fog"]["color"]
					else
						game.Lighting.FogColor = etheria.old.fogcolor
					end
				end})
				local fogstart = visuals_world:create_element({name = "fog start", flag = "fogstart", s_default = etheria.old.fogstart, types = {"slider"}, sdefault = 500, min = 1, max = 5000, callback = function()
					if lib.flags["fog"]["toggle"] then
						game.Lighting.FogStart = lib.flags["fogstart"]["value"]
					else
						game.Lighting.FogStart = etheria.old.fogstart
						game.Lighting.FogColor = etheria.old.fogcolor
						game.Lighting.FogEnd = etheria.old.fogend
					end
				end})
				local fogend = visuals_world:create_element({name = "fog end", flag = "fogend", s_default = etheria.old.FogEnd, types = {"slider"}, sdefault = 500, min = 1, max = 5000, callback = function()
					if lib.flags["fog"]["toggle"] then
						game.Lighting.FogEnd = lib.flags["fogend"]["value"]
					end
				end})
		local node_esp = visuals_other:create_section({name = "node esp"})
			local nodeesp_enabled = node_esp:create_element({name = "enabled", no_none = true, d_default = "adurite", t_default = false, flag = "node_esp", types = {"toggle", "dropdown", "colorpicker"}, c_default = Color3.fromRGB(201,201,201), options = {"adurite", "gold", "stone", "iron"}, callback = function()
			end})
		local egg_esp = visuals_other:create_section({name = "egg esp"})
			local eggesp_enabled = egg_esp:create_element({name = "enabled", t_default = false, flag = "egg_esp", types = {"toggle", "colorpicker"}, c_default = Color3.fromRGB(201,201,201), callback = function()
			end})
		local visuals_hud = visuals_other:create_section({name = "hud"})
			local target_hud = visuals_hud:create_element({name = "target hud", no_none = true, d_default = "modern", t_default = false, flag = "target_hud", types = {"toggle", "colorpicker"}, c_default = Color3.fromRGB(0,255,0), callback = function()
			end})
			local dynamic_color = visuals_hud:create_element({name = "dynamic color", t_default = false, flag = "dynamic_color", types = {"toggle"}, callback = function()
			end})
local misc = win:create_tab({name = "misc", icon = "http://www.roblox.com/asset/?id=12447089653"})
	local misc_script = misc:create_subtab({name = "main"})
		local main_helper = misc_script:create_section({name = "helpers"})
			local auto_pickup = main_helper:create_element({name = "auto pickup", flag = "auto_pickup", t_default = false, types = {"toggle", "keybind"}, callback = function()
			end})
			local whitelist = main_helper:create_element({name = "whitelist", multi = true, flag = "whitelist", types = {"toggle", "dropdown"}, options = {"magnetite", "emerald", "adurite", "iron", "pink diamond", "crystal", "bloodfruit", "log", "gold", "essence"}, callback = function()
			end})
			local auto_heal = main_helper:create_element({name = "auto heal", flag = "auto_heal", t_default = false, types = {"toggle", "keybind", "dropdown"}, no_none = true, d_default = "bloodfruit",  options = {"bloodfruit", "bluefruit", "sun fruit", "berry", "orange"}, callback = function()
			end})
			local heal_below = main_helper:create_element({name = "below", flag = "heal_below", t_default = false, types = {"toggle", "slider"}, min = 1, max = 100, s_default = 1, suffix = "hp", callback = function()
			end})
			local heal_delay = main_helper:create_element({name = "delay", flag = "heal_delay", t_default = false, types = {"slider"}, min = 1, max = 100, s_default = 1, suffix = "ms", callback = function()
			end})

	local misc_main = misc:create_subtab({name = "script"})
		local main_config = misc_main:create_section({name = "config"})
			local config_list = main_config:create_element({name = "list", flag = "selected_config", options = lib.getConfigList(), types = {"dropdown"}, callback = function()
			end})
			local config_name = main_config:create_element({name = "name", flag = "text_config", types = {"textbox"}, callback = function()
			end})
			local config_create = main_config:create_element({name = "create config", flag = "2", types = {"button"}, callback = function()
				if not isfile("etheria/configs/"..lib.flags["text_config"]["text"]..".cfg") then
					lib.saveConfig(lib.flags["text_config"]["text"])
					config_list:set_p_options(lib.getConfigList())
				end
			end})
			local reload_list = main_config:create_element({name = "reload list", types = {"button"}, callback = function()
				config_list:set_p_options(lib.getConfigList())
			end})
			local config_load = main_config:create_element({name = "load config", confirmation = true, flag = "3", types = {"button"}, callback = function()
				if isfile("etheria/configs/"..lib.flags["selected_config"]["selected"][1]..".cfg") then
					lib.loadConfig(lib.flags["selected_config"]["selected"][1])
				end
			end})
			local config_save = main_config:create_element({name = "override config", confirmation = true, flag = "4", types = {"button"}, callback = function()
				if isfile("etheria/configs/"..lib.flags["selected_config"]["selected"][1]..".cfg") then
					lib.saveConfig(lib.flags["selected_config"]["selected"][1])
				end
			end})
	local main_menu = misc_main:create_section({name = "menu"})
		local menu_togglekey = main_menu:create_element({name = "toggle key", flag = "togglekey", types = {"keybind"}, k_default = {method = "toggle", key = "leftalt"}, callback = function()
		end})
		local menu_destroygui = main_menu:create_element({name = "destroy gui", confirmation = true, flag = "111", types = {"button"}, callback = function()
			win.main:Destroy()
		end})
	local main_teleports = misc_main:create_section({name = "teleports"})
		local menu_rejoinserver = main_teleports:create_element({name = "rejoin server", confirmation = true, flag = "11", types = {"button"}, callback = function()
			services.TeleportService:Teleport(game.PlaceId, client.plr)
		end})

-- ! hook namecall

local old_namecall = nil
old_namecall = hookmetamethod(game, "__namecall", LPH_NO_VIRTUALIZE(function(self, ...)
	local args = {...}
	local method = getnamecallmethod()
	if args[3] ~= "new" and method == "FireServer" and tostring(self) == "SwingTool" and etheria.look_at ~= Vector3.new() then
		return
	elseif args[3] == "new" and method == "FireServer" and tostring(self) == "SwingTool" then
		args[3] = nil
		return old_namecall(self, unpack(args))
	elseif method == "FireServer" and tostring(self) == "Event" and tostring(self.Parent) == "ProjectileHandler" and lib.flags["silent_aim"]["toggle"] and silent_aim.get_active() and etheria.aim_location then
		args[1] = etheria.aim_location
		return old_namecall(self, unpack(args))
	elseif method == "GetPartBoundsInBox" and self == workspace and lib.flags["reach"]["toggle"] then
		local size = lib.flags["reach"]["value"]
		args[2] = args[2] + Vector3.new(size,0,size)
        return old_namecall(self, unpack(args))
	end
	return old_namecall(self, ...)
end))

-- ! custom funcs

local function is_visible(start, result, part)
	local surge = etheria.players[part.Name]
	if surge then
		return #workspace.CurrentCamera:GetPartsObscuringTarget({start, result}, {client:get_character(), part, workspace.energybolts, workspace.Projectiles}) == 0
	end
end

local function get_state_from_velocity(velocity)
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

local function predict_player(hrp)
	local vel = hrp.Velocity
	local prediction = Vector3.new()
	local state = get_state_from_velocity(vel)

	local hrpdist = (client:get_character().HumanoidRootPart.Position-hrp.Position).magnitude

	local distance = hrpdist/11
	prediction = prediction + Vector3.new(0,distance,0)
	local distance = hrpdist/48

	prediction = prediction + Vector3.new((vel.X/7.9)*distance,0,0)
	prediction = prediction + Vector3.new(0,0,(vel.Z/7.9)*distance)

	if state == "jumping" then
		prediction = prediction - Vector3.new(0, 1.20, 0)
		prediction = prediction + Vector3.new(0, math.clamp((math.abs(vel.Y)/32*distance)*distance/2, 0, 1.75), 0)
	elseif state == "falling" then
		prediction = prediction - Vector3.new(0, .4, 0)
		prediction = prediction - Vector3.new(0, math.clamp((math.abs(vel.Y)/32*distance)*distance/2, 0, 1.1), 0)
	end

	return hrp.Position + prediction
end

local function get_closest_player()
	local character = client:get_character()
	local hrp = character.HumanoidRootPart
	local distance = math.huge
	local closest = nil
	for _, player in next, players:GetPlayers() do
		if player == client.plr then continue end
		if player.Team.Name == client.plr.Team.Name and player.Team.Name ~= "NoTribe" then continue end
		local surge = etheria.players[player.Name]
		if surge then
			local character = surge.instance.Character
			if character and surge:is_loaded() then
				local hrp2 = character.HumanoidRootPart
				local dist = (hrp.Position-hrp2.Position).magnitude 
				if dist < distance then
					distance = dist
					closest = player
				end
			end
		end
	end
	return closest, distance
end

local function get_closest_to_cursor()
	local closest = 9e9
	local target = nil

	if client:is_character_loaded() then
		for _, plr in next, services.Players:GetPlayers() do
			if plr ~= client.plr and (plr.Team.Name ~= client.plr.Team.Name or client.plr.Team.Name ~= "NoTribe") then
				local character = etheria.players[plr.Name].instance.Character

				if character then
					local playerHumanoid = character:FindFirstChild("Humanoid")
					local hrp = character:FindFirstChild("HumanoidRootPart")
					if hrp and playerHumanoid then
						local hitVector, onScreen = workspace.CurrentCamera:WorldToScreenPoint(hrp.Position)
						if onScreen then
							local htm = (Vector2.new(client.mouse.X, client.mouse.Y) - Vector2.new(hitVector.X, hitVector.Y)).magnitude
							local threshold = lib.flags["fov_radius"]["value"]*1.5
							if htm < closest and htm <= threshold and (client:get_character().HumanoidRootPart.Position-hrp.Position).magnitude < 325 then
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

-- ! big loops

local esp_loop = rs:BindToRenderStep("esp", Enum.RenderPriority.Camera.Value + 1, function()
	local is_loaded = client:is_character_loaded()
	local character = nil
	if is_loaded then
		character = client:get_character()
	end
	if is_loaded and lib.flags["look_at"]["toggle"] and etheria.look_at ~= Vector3.new() and is_loaded then
		local position = character.HumanoidRootPart.Position
		character.HumanoidRootPart.CFrame = CFrame.new(position, Vector3.new(etheria.look_at.X, position.Y, etheria.look_at.Z))
	end
	for i, node in next, etheria.nodes do
		local node_model = node[1]
		local text = node[2]

		text.Visible = false

		local node_esp = lib.flags["node_esp"]

		if node_esp["toggle"] and is_loaded then
			if node_model and node_model:FindFirstChild("Reference") then
				local selected = node_esp["selected"][1]
				if node_model.Name:lower():find(selected) then
					local pos,visible = workspace.CurrentCamera:WorldToViewportPoint(node_model.Reference.Position)

					if visible then
						text.Position = Vector2.new(pos.X, pos.Y)
						text.Visible = true
						text.Color = node_esp["color"]
						text.Transparency = -node_esp["transparency"]+1
					end
				end
			else
				text:Remove()
				table.remove(etheria.nodes, i)
			end
		end
	end
	for i, egg in next, etheria.eggs do
		local egg_model = egg[1]
		local text = egg[2]

		text.Visible = false

		local egg_esp = lib.flags["egg_esp"]

		if egg_esp["toggle"] and is_loaded then
			if egg_model and egg_model:FindFirstChild("Handle") then
				local pos,visible = workspace.CurrentCamera:WorldToViewportPoint(egg_model.Handle.Position)

				if visible then
					text.Position = Vector2.new(pos.X, pos.Y)
					text.Visible = true
					text.Color = egg_esp["color"]
					text.Transparency = -egg_esp["transparency"]+1
				end
			else
				text:Remove()
				table.remove(etheria.eggs, i)
			end
		end
	end
	local is_esp = lib.flags["pesp"]["toggle"]
	for i, player in next, services.Players:GetPlayers() do
		local esp_table = etheria.esp[player.Name]

		if not esp_table then
			continue
		end

		for i,v in pairs(esp_table) do
			if i ~= "highlight" then
				v.Visible = false
			end
		end

		esp_table.highlight.Enabled = false

		if not is_esp then
			continue
		end

		local surge = etheria.players[player.Name]

		local character = surge.instance.Character

		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			local hum = character:FindFirstChildOfClass("Humanoid")
			if hrp and hum then
				local pos, visible = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)

				if visible then
					local size = (workspace.CurrentCamera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.3, 0)).Y - workspace.CurrentCamera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.9, 0)).Y) / 2
					local box_size = Vector2.new(math.floor(size * 1.6), math.floor(size * 1.9))
					local box_pos = Vector2.new(math.floor(pos.X - size * 1.6 / 2), math.floor(pos.Y - size * 1.6 / 2))
					local font = lib.flags["font"]["selected"][1]
					
                    local font = Drawing.Fonts[font]

					local chams = lib.flags["chams"]
					local outline = lib.flags["outline"]
					local outlines2 = lib.flags["outlines"]
					local box2 = lib.flags["box"]
					local name2 = lib.flags["name"]
					local tool2 = lib.flags["tool"]
					local health2 = lib.flags["health"]
					local fontsize2 = lib.flags["fontsize"]

					if chams["toggle"] then
						local highlight = esp_table.highlight

						highlight.FillColor = not target and chams["color"] or lib.flags["t_chams"]["color"]
						highlight.FillTransparency = not target and chams["transparency"] or lib.flags["t_chams"]["transparency"]
						highlight.OutlineColor = not target and outline["color"] or lib.flags["t_outline"]["color"]
						highlight.OutlineTransparency = not target and outline["transparency"] or lib.flags["t_outline"]["transparency"]
						highlight.Adornee = character
						highlight.Enabled = true
					end

					if box2["toggle"] then
						local box = esp_table.box
						local outline = esp_table.outline
						
						box.Size = box_size
						box.Position = box_pos
						box.Color = not target and box2["color"] or lib.flags["t_box"]["color"]
						box.Transparency = not target and -box2["transparency"]+1 or -lib.flags["t_box"]["transparency"]+1
						outline.Transparency = not target and -box2["transparency"]+1 or-lib.flags["t_box"]["transparency"]+1
						outline.Size = box_size
						outline.Position = box_pos
						outline.Visible = lib.flags["outlines"]["toggle"]
						outline.Color = Color3.fromRGB(0,0,0)
						box.Visible = true
					end

					if name2["toggle"] then
						local name = esp_table.name

						name.Position = Vector2.new(box_size.X / 2 + box_pos.X, box_pos.Y - name.TextBounds.Y - 1)
						name.Color = not target and name2["color"] or lib.flags["t_name"]["color"] 
						name.Transparency = not target and -name2["transparency"]+1 or -lib.flags["t_name"]["transparency"]+1
						name.Font = font
						name.Size = fontsize2["value"]
						name.Visible = true
						name.Outline = outlines2["toggle"]
					end

					if tool2["toggle"] then
                        local tool = esp_table.tool

						if tool.Text ~= "" then
                            tool.Position = Vector2.new(box_size.X / 2 + box_pos.X, (box_pos.Y + box_size.Y))
                            tool.Color = not target and tool2["color"] or lib.flags["t_tool"]["color"] 
                            tool.Transparency = not target and -tool2["transparency"]+1 or -lib.flags["t_tool"]["transparency"]+1
                            tool.Font = font
                            tool.Size = fontsize2["value"] - 2
                            tool.Visible = true
                            tool.Outline = outlines2["toggle"]
                        end
					end

                    if health2["toggle"] then
						local healthbar = esp_table.healthbar
						local health_outline = esp_table.healthoutline
                        local health_number = lib.flags["healthtext"]["toggle"]
                        local health_color = lib.flags["healthoverride"]["toggle"]

						healthbar.From = Vector2.new((box_pos.X - 5), box_pos.Y + box_size.Y)
						healthbar.To = Vector2.new(healthbar.From.X, healthbar.From.Y - (hum.Health / hum.MaxHealth) * box_size.Y)
						healthbar.Color = health2["color"]
						healthbar.Transparency = -health2["transparency"]+1
						healthbar.Visible = true
		
						health_outline.From = Vector2.new(healthbar.From.X, box_pos.Y + box_size.Y + 1)
						health_outline.To = Vector2.new(healthbar.From.X, (healthbar.From.Y - 1 * box_size.Y) -1)
						health_outline.Visible = true

						if health_color then
							local hp = math.clamp(hum.Health/hum.MaxHealth,0,1)
							healthbar.Color = Color3.fromHSV(hp/3,1,1)
						end

						if hum.Health < hum.MaxHealth and health_number then
							local health = esp_table.healthtext
							local h_text = tostring(math.round(hum.Health))

							health.Text = h_text
							health.Size = 13
							health.Visible = true
							health.Color = Color3.fromRGB(255,255,255)
                            health.Font = font
							health.Position = healthbar.To - Vector2.new(health.TextBounds.X/2 + 2, health.TextBounds.Y/2)
						end
					end
				end
			end
		end
	end
end)

-- ! main connections

for _, player in next, players:GetPlayers() do
    if player == players.LocalPlayer then continue end
	etheria.esp[player.Name] = esp:create_drawings(player)
	etheria.players[player.Name] = enemy.new(player)
end

local player_added = connection.new(players.PlayerAdded, function(player)
	if player == players.LocalPlayer then return end
	etheria.esp[player.Name] = esp:create_drawings(player)
	etheria.players[player.Name] = enemy.new(player)
end)

local player_removing = connection.new(players.PlayerRemoving, function(player)
	if player == players.LocalPlayer then return end
	for i,v in pairs(etheria.esp[player.Name]) do
		if i == highlight then
			v:Destroy()
		else
			v:Remove()
		end
	end
	etheria.players[player.Name] = nil
end)

local character_added = connection.new(client.plr.CharacterAdded, function(char)
	local humanoid = char:WaitForChild("Humanoid")
	humanoid.StateChanged:Connect(function(old, new)
		if new == Enum.HumanoidStateType.Landed then
			etheria.jumps = 0
			etheria.tp_cooldown = false
		elseif new == Enum.HumanoidStateType.Freefall then
			etheria.jumps+=1
		end
	end)
end)

local jump_request = connection.new(uis.InputBegan, function(input, gpe)
	if gpe then return end
	if input.KeyCode.Name == "Space" and lib.flags["double_jump"]["toggle"] then
		if client:is_character_loaded() then
			if etheria.jumps == 1 then
				client:get_character().Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end
	elseif string.lower(input.KeyCode.Name) == lib.flags["tp_up"]["key"] and lib.flags["tp_up"]["toggle"] and client:is_character_loaded() and not etheria.tp_cooldown and client:get_character().Humanoid:GetState() == Enum.HumanoidStateType.Running then
		etheria.tp_cooldown = true
		local hrp = client:get_character().HumanoidRootPart
		hrp.CFrame = hrp.CFrame + Vector3.new(0,lib.flags["tp_up"]["value"],0)
	end
end)

local on_hue_change = connection.new(game.Lighting:GetPropertyChangedSignal("Ambient"), function()
	local new = game.Lighting.Ambient
	if new ~= lib.flags["hue"]["color"] then
		etheria.old.ambient = new
	end
	if lib.flags["hue"]["toggle"] then
		game.Lighting.Ambient = lib.flags["hue"]["color"]
	end
end)

local on_shadowhue_change = connection.new(game.Lighting:GetPropertyChangedSignal("OutdoorAmbient"), function()
	local new = game.Lighting.OutdoorAmbient
	if new ~= lib.flags["shadowhue"]["color"] then
		etheria.old.outdoorambient = new
	end
	if lib.flags["shadowhue"]["toggle"] then
		game.Lighting.OutdoorAmbient = lib.flags["shadowhue"]["color"]
	end
end)

local on_time_change = connection.new(game.Lighting:GetPropertyChangedSignal("ClockTime"), function()
	if game.Lighting.ClockTime ~= lib.flags["clocktime"]["value"] then
		etheria.old.clocktime = game.Lighting.ClockTime
	end
	if lib.flags["clocktime"]["toggle"] then
		game.Lighting.ClockTime = lib.flags["clocktime"]["value"]
	end
end)

local on_fogcolor_change = connection.new(game.Lighting:GetPropertyChangedSignal("FogColor"), function()
	if game.Lighting.FogColor ~= lib.flags["fog"]["color"] then
		etheria.old.fogcolor = game.Lighting.FogColor
	end
	if lib.flags["fog"]["toggle"] then
		game.Lighting.FogColor = lib.flags["fog"]["color"]
	end
end)

local on_fogstart_change = connection.new(game.Lighting:GetPropertyChangedSignal("FogStart"), function()
	if game.Lighting.FogStart ~= lib.flags["fogstart"]["value"] then
		etheria.old.fogstart = game.Lighting.FogStart
	end
	if lib.flags["fog"]["toggle"] then
		game.Lighting.FogStart = lib.flags["fogstart"]["value"]
	end
end)

local on_fogend_change = connection.new(game.Lighting:GetPropertyChangedSignal("FogEnd"), function()
	if game.Lighting.FogEnd ~= lib.flags["fogend"]["value"] then
		etheria.old.fogend = game.Lighting.FogEnd
	end
	if lib.flags["fog"]["toggle"] then
		game.Lighting.FogEnd = lib.flags["fogend"]["value"]
	end
end)

for _, node in next, workspace.Resources:GetChildren() do
	if node.Name:find("Node") or node.Name:find("Rich Rock") then
		local surge = {node, draw.new("Text", {ZIndex = 2, Center = true, Outline = true, Visible = false, Text = node.Name})}

		table.insert(etheria.nodes, surge)
	end
end

for _, egg in next, workspace.Eggs:GetChildren() do
	local surge = {egg, draw.new("Text", {ZIndex = 2, Center = true, Outline = true, Visible = false, Text = egg.Name})}

	table.insert(etheria.eggs, surge)
end

local on_new_node = connection.new(workspace.Resources.ChildAdded, function(resource)
	if resource.Name:find("Node") or resource.Name:find("Rich Rock") then
		resource:WaitForChild("Reference")
		local surge = {node, draw.new("Text", {ZIndex = 2, Center = true, Outline = true, Visible = false, Text = resource.Name})}

		table.insert(etheria.nodes, surge)
	end
end)

if client:is_character_loaded() then
	local humanoid = client:get_character().Humanoid
	humanoid.StateChanged:Connect(function(old, new)
		if new == Enum.HumanoidStateType.Landed then
			etheria.jumps = 0
			task.spawn(function()
				task.wait(0.2)
				etheria.tp_cooldown = false
			end)
		elseif new == Enum.HumanoidStateType.Freefall then
			etheria.jumps+=1
		end
	end)
end

-- ! Main Loop

local main_loop = connection.new(rs.Heartbeat, function(dt)
	etheria.killaura.Visible = false
	etheria.look_at = Vector3.new()
	local fov = lib.flags["fov"]
	local showfov = lib.flags["show_fov"]
	workspace.CurrentCamera.FieldOfView = fov["toggle"] and fov["value"] or 65
	etheria.aim_circle.Position = Vector2.new(client.mouse.X, client.mouse.Y + lib.flags["fov_offset"]["value"])
	etheria.aim_circle.Visible = silent_aim.get_active() and lib.flags["silent_aim"]["toggle"] and showfov["toggle"]
	etheria.aim_circle.Color = showfov["color"]
	etheria.aim_circle.Transparency = -showfov["transparency"]+1
	etheria.aim_circle.Filled = lib.flags["fov_filled"]["toggle"]
	etheria.aim_circle.NumSides = lib.flags["fov_sides"]["value"]
	etheria.aim_circle.Radius = lib.flags["fov_radius"]["value"]*1.5
	if client:is_character_loaded() then
		local character = client:get_character()
		local humanoid = character.Humanoid
		local hrp = character.HumanoidRootPart
		if lib.flags["swing_spam"]["toggle"] and swing_spam.get_active() then
			if not etheria.swing_cooldown then
				etheria.swing_cooldown = true
				task.spawn(function()
					booga.swing_tool()
					task.wait(lib.flags["swing_spam"]["value"]/1000)
					etheria.swing_cooldown = false
				end)
			end
		end
		local autoheal2 = lib.flags["auto_heal"]
		if not etheria.on_heal_cooldown and autoheal2["toggle"] and auto_heal.get_active() then
			if humanoid.Health <= 99 then
				local heal_below = lib.flags["heal_below"]
				local food_convert = booga.food_converts[autoheal2["selected"][1]]
				if heal_below["toggle"] then
					if humanoid.Health < heal_below["value"] and booga.has_item(food_convert) then
						repstorage.Events.UseBagItem:FireServer(food_convert)
						task.spawn(function()
							etheria.on_heal_cooldown = true
							task.wait(lib.flags["heal_delay"]["value"]/1000)
							etheria.on_heal_cooldown = false
						end)
					end
				else
					if booga.has_item(food_convert) then
						repstorage.Events.UseBagItem:FireServer(food_convert)
						task.spawn(function()
							etheria.on_heal_cooldown = true
							task.wait(autoheal2["value"]/1000)
							etheria.on_heal_cooldown = false
						end)
					end
				end
			end
		end
		if lib.flags["speed"]["toggle"] and speed.get_active() and humanoid.MoveDirection ~= Vector3.new() then
			hrp.CFrame = hrp.CFrame + (humanoid.MoveDirection / ((1000-lib.flags["speed"]["value"]) * 1-dt))
		end
		humanoid.MaxSlopeAngle = lib.flags["anti_slide"]["toggle"] and 90 or 46
		if lib.flags["kill_aura"]["toggle"] and kill_aura.get_active() then
			local circle = etheria.killaura
			circle.Visible = true
			circle.Thickness = 1
			circle.Color = lib.flags["kill_aura"]["color"]
			circle.Transparency = -lib.flags["kill_aura"]["transparency"]+1
			circle.ZIndex = 11
			circle.Radius = lib.flags["kill_aura"]["value"]
			circle.Position = hrp.Position

			local closest, dist = get_closest_player()
			if dist < 10.5 and closest then
				if lib.flags["target_hud"]["toggle"] then
					targethudlib:update_name(closest)
					targethudlib:update_color(lib.flags["target_hud"]["color"], closest.Character.Humanoid)
					targethudlib:update_health(closest.Character.Humanoid.Health)
					if not targethudlib.opened then
						targethudlib:open()
					end
				end
				etheria.look_at = closest.Character.HumanoidRootPart.Position
			end
			if closest and dist <= lib.flags["kill_aura"]["value"] then
				if not etheria.aura_cooldown then
					etheria.aura_cooldown = true
					booga.swing_tool()
					local args = {}
					for _, part in next, closest.Character:GetChildren() do
						if part.ClassName == "Part" or part.ClassName == "MeshPart" then
							args[_] = part
						end
					end
					repstorage.Events.SwingTool:FireServer(os.clock(), args, "new")
					task.spawn(function()
						task.wait(0.016)
						etheria.aura_cooldown = false
					end)
				end
			else
				if targethudlib.opened then
					targethudlib:close()
				end
			end
		end
		if silent_aim.get_active() and lib.flags["silent_aim"]["toggle"] then
			local closest = get_closest_to_cursor()
			local yuh = false
			if closest then
				local surge = etheria.players[closest.Name]
				if surge then
					local character = surge.instance.Character
					if character and surge:is_loaded() then
						local hrp = character.HumanoidRootPart
						local visible = is_visible(client:get_character().Head.Position, character.Head.Position, character)

						if visible then
							local predicted_position = predict_player(hrp)
							visible = is_visible(client:get_character().Head.Position, predicted_position, character)
							
							if visible then
								etheria.aim_location = predicted_position
								yuh = true
							end
						end
					end
				end
			end
			if not yuh then
				etheria.aim_location = nil
			end
		end
		for _, player in next, services.Players:GetPlayers() do
			local surge = etheria.players[player.Name]
			if surge then
				local character = surge.instance.Character
				if character and surge:is_loaded() then
					local hrp = character.HumanoidRootPart
					local expander = lib.flags["expander"]["toggle"]
					hrp.Size = expander and Vector3.new(lib.flags["sizex"]["value"], lib.flags["sizey"]["value"], lib.flags["sizez"]["value"]) or Vector3.new(2,2,1)
					hrp.CanCollide = false
					hrp.Color = lib.flags["expander"]["color"]
					hrp.Material = expander and (lib.flags["expander"]["selected"][1] == "forcefield" and Enum.Material.ForceField or Enum.Material.Neon) or Enum.Material.Plastic
					hrp.Transparency = expander and lib.flags["expander"]["transparency"] or 1
				end
			end
		end
		if lib.flags["auto_pickup"]["toggle"] and auto_pickup.get_active() and not etheria.pickup_cooldown then
			etheria.pickup_cooldown = true
			for _, item in next, workspace.Items:GetChildren() do
				local part = item:FindFirstChildOfClass("Part") or (item.ClassName ~= "Model" and item)
				local name = item.Name:lower()
				local check = not lib.flags["whitelist"]["toggle"]
				if lib.flags["whitelist"]["toggle"] then
					for _, option in next, lib.flags["whitelist"]["selected"] do
						if name:find(option) then
							check = true
						end
					end
				end
				if part and check and booga.can_bear_load(item.Name) then
					local distance = (character.Head.Position-part.Position).magnitude
					if distance < 27 then 
						game.ReplicatedStorage.Events.Pickup:FireServer(item)
					end
				end
			end
			task.spawn(function()
				task.wait(0.08)
				etheria.pickup_cooldown = false
			end)
		end
	end
end)
