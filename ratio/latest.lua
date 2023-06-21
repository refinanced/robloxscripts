getgenv().configuration = {autoload = "", no_gui = false}

local services = setmetatable({}, { __index = function(self, key) return game:GetService(key) end })
local corsa = {}
local lib = {handler = {}, flags = {}, copied_color = {}}

lib.copied_color["color"] = Color3.fromRGB(255,255,255)
lib.copied_color["transparency"] = 0

-- umm.. go crazy skidding!! ig

function lib:get_killsays()
	if isfile("corsa/killsays.txt") then
		local files;
		local m, err = pcall(function()
			files = services.HttpService:JSONDecode(readfile("corsa/killsays.txt"))
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

if not isfolder("corsa") then
	makefolder("corsa")
end

if not isfolder("corsa/configs") then
	makefolder("corsa/configs")
end

if not isfile("corsa/killsays.txt") then
	writefile("corsa/killsays.txt", "[\"sponsored by corsa\", \"we love you tecca!\"]")
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
		local new_values = game.HttpService:JSONDecode(dec(readfile("corsa/configs/"..cfgName..".cfg")))

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
			writefile("corsa/configs/"..cfgName..".cfg",enc(game.HttpService:JSONEncode(values_copy)))
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
		Text = "corsa";
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

	if getgenv().configuration.no_gui then
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
    local cfgs = listfiles("corsa/configs/")
    local returnTable = {}
    for _, file in pairs(cfgs) do
        local str = tostring(file)
        if string.sub(str, #str-3, #str) == ".cfg" then
            local tb = services.HttpService:JSONDecode(dec(readfile(file)))
            if (tb["game_id"] and game.GameId == tonumber(tb["game_id"])) or not tb["game_id"] then
                table.insert(returnTable, string.sub(str, 15, #str-4))
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

local enemy = {}
enemy.__index = enemy

function enemy.new(instance, name)
	local surge = {}

	setmetatable(surge, enemy)

	surge.instance = instance
	surge.cooldown = false
	surge.in_game = false

	local player = instance

	corsa.locations[player.Name] = {}

	surge.backtrack = game:GetObjects("rbxassetid://11868212008")[1]
	surge.backtrack.Name = ""

	local identicator = Instance.new("StringValue")
	identicator.Value = player.Name
	identicator.Name = "StringValue"
	identicator.Parent = surge.backtrack

	for _, part in pairs(surge.backtrack:GetChildren()) do
		if part:IsA("Part") then
			local decal = part:FindFirstChildOfClass("Decal")
			if decal then decal:Destroy() end
			if part.Name == "Head" then part:GetChildren()[1]:Destroy() end
			part.CanCollide = false
			part.Material = Enum.Material.Neon
			part.Transparency = 0.6
			part.Anchored = part.Name ~= "HumanoidRootPart"
		end
	end

	if not player:FindFirstChild("Backpack") then
		repeat task.wait() until player:FindFirstChild("Backpack")
	end

	connection.new(player.Backpack.ChildAdded, function(tool)
		if tool:IsA("Tool") then
			corsa.players[player.Name].in_game = true
		end
	end)

	connection.new(player.Backpack.ChildRemoved, function(tool)
		if tool:IsA("Tool") then
			task.wait()
			if corsa.players[player.Name]:is_loaded() and not corsa.players[player.Name]:has_knife() then
				corsa.players[player.Name]:start_knife_cooldown()
			end
		end
	end)

	connection.new(player.CharacterAdded, function(character)
		corsa.players[player.Name].in_game = false
		connection.new(character.ChildAdded, function(tool)
			if tool:IsA("Tool") then
				corsa.players[player.Name].in_game = true
			end
		end)

		corsa.locations[player.Name] = {}

		connection.new(character.ChildRemoved, function(tool)
			if tool:IsA("Tool") then
				task.wait()
				if corsa.players[player.Name]:is_loaded() and not corsa.players[player.Name]:has_knife() then
					corsa.players[player.Name]:start_knife_cooldown()
				end
			end
		end)
	end)

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

function enemy:has_knife()
	local is_loaded = self:is_loaded()

	if is_loaded then
		local knife = self.instance.Character:FindFirstChild("Knife") or self.instance.Backpack:FindFirstChild("Knife")
		if knife then
			return true
		end
	end
end

function enemy:start_knife_cooldown()
	local number = 5.00
	self.cooldown = number
	for i = 1, 500 do
		number = number - 0.01
		self.cooldown = number
		task.wait(0.01)
	end
	self.cooldown = false
end

function enemy:is_throwing_knife()
	local has_knife = self:has_knife()

	if has_knife then
		local character = self.instance.Character
		local timepos = nil
		local anims = character.Humanoid:GetPlayingAnimationTracks()
		for i = 1, #anims do
			local anim = anims[i]
			if anim.Animation.AnimationId == "http://www.roblox.com/Asset?ID=89147993" then
				timepos = anim.TimePosition
				break
			end
		end

		return timepos
	end
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
	function client:has_knife()
		local is_loaded = client:is_character_loaded()
	
		if is_loaded then
			local knife = client:get_character():FindFirstChild("Knife") or client.plr.Backpack:FindFirstChild("Knife")
			if knife then
				return true
			end
		end
	end
	client.highlight = Instance.new("Highlight")
	client.highlight.Parent = game.CoreGui
	client.highlight.Enabled = false
	client.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	client.highlight.Name = "\255"

-- ! esp class

local esp = {}

function esp:create_drawings()
	local esp_table = {}

	esp_table.box = draw.new("Square", {
		ZIndex = 2,
		Thickness = 1,
		Filled = false
	})
	esp_table.fill = draw.new("Square", {
		ZIndex = 1,
		Thickness = 1,
		Filled = true
	})
	esp_table.outline = draw.new("Square", {
		ZIndex = 1,
		Thickness = 3,
		Filled = false
	})
	esp_table.name = draw.new("Text", {
		ZIndex = 4,
		Center = true,
		Outline = true
	})
	esp_table.throwbox = draw.new("Line", {
		ZIndex = 2,
		Thickness = 1,
	})
	esp_table.throwoutline = draw.new("Line", {
		ZIndex = 1,
		Thickness = 3,
	})
	esp_table.knifebox = draw.new("Line", {
		ZIndex = 2,
		Thickness = 1,
	})
	esp_table.knifeoutline = draw.new("Line", {
		ZIndex = 1,
		Thickness = 3,
	})
	esp_table.triangleoutline = draw.new("Triangle", {
		Thickness = 3,
		ZIndex = 3,
		Filled = true,
	})
	esp_table.triangle = draw.new("Triangle", {
		Thickness = 1,
		ZIndex = 4,
		Filled = true,
	})

	esp_table.highlight = Instance.new("Highlight")
	esp_table.highlight.Parent = game.CoreGui
	esp_table.highlight.Enabled = false
	esp_table.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	esp_table.highlight.Name = "\255"

	return esp_table
end

-- ! hitmarker class

local hitmarker = {}

function hitmarker.new(size, offset)
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

-- ! external libraries

local draw3 = loadstring(game:HttpGet("https://raw.githubusercontent.com/Blissful4992/ESPs/main/3D%20Drawing%20Api.lua"))()

-- ! bypass

setreadonly(getrenv().task, false)

ts = getrenv().task.spawn
getrenv().task.spawn = newcclosure(function(...)
	if not checkcaller() then
		return wait(9e9)
	end
	return ts(...)
end)

setreadonly(getrenv().task, true)

local old_index = nil
old_index = hookmetamethod(game, "__index", LPH_NO_VIRTUALIZE(function(self, index)
	if checkcaller() and index == "Character" then
		return workspace:FindFirstChild(tostring(self))
	elseif not checkcaller() and index == "Size" and tostring(self) == "HumanoidRootPart" then
		return Vector3.new(2,2,1)
	end
	return old_index(self, index)
end))

-- ! gather functions

corsa = {
	old = {outdoorambient = game.Lighting.OutdoorAmbient, ambient = game.Lighting.Ambient, clocktime = game.Lighting.ClockTime, fogend = game.Lighting.FogEnd, fogstart = game.Lighting.FogStart, fogcolor = game.Lighting.FogColor}, 
	info = {stop_ghost = false, serverhop_cooldown = false, update_cooldown = false, aim_location = Vector3.new(), chat_cooldown = false, no_lag = false, lagging = false, lag_cooldown = false, throw_args = {}, target = nil, kills = 0, time_played = 0, stab_cooldown = false, kill_cooldown = false, auto_peek_location = Vector3.new(-9e9,0,0), auto_peeking = false, retreating = true}, 
	assets = {ragdoll_holder = Instance.new("Folder", game.CoreGui), fake = game:GetObjects("rbxassetid://11868212008")[1], pet_holder = Instance.new("Folder", game.CoreGui), auto_peek = draw3:New3DCircle(), stab_range = draw3:New3DCircle()}, 
	players = {}, 
	esp = {}, 
	assassin = {}, 
	connections = {}, 
	states = {"running", "jumping", "falling"},
	locations = {},
	signals = {hit_player = lib.signal.new("hit_player"), knife_thrown = lib.signal.new("knife_thrown")},
	throwsounds = {bow = "rbxassetid://3442683707"},
	collidesounds = {bow = "rbxassetid://177380034"},
	parts = {"Head", "Torso", "Left Leg", "Right Leg", "Left Arm", "Right Arm"},
	aim_circle = draw.new("Circle", {
		ZIndex = 5,
		Thickness = 1,
		Filled = false
	}),
	aim_tracer = draw.new("Line", {
		ZIndex = 15,
		Thickness = 2,
	}),
	cases = {},
	hitsounds = {minecraft = "rbxassetid://5869422451", cod = "rbxassetid://160432334", bameware = "rbxassetid://6565367558", neverlose = "rbxassetid://6565370984", skeet = "rbxassetid://4817809188", rust = "rbxassetid://6565371338"}
}

local sm = require(services.ReplicatedStorage.Modules.ShopDisplay)
local t = sm.getKnifeShop()
for _, v in pairs(t) do
	local case = tostring(v[1])
	if string.find(case, "Case") then
		corsa.cases[case] = {}
		corsa.cases[case]["cost"] = v[2]
		table.insert(corsa.cases, case)
	end
end

function corsa:serverhop()
    LPH_JIT_MAX(function()
        if not corsa.info.teleporting then
            local servers = services.HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..tostring(game.PlaceId).."/servers/Public?sortOrder=Desc&limit=100"))
            for i,v in pairs(servers.data) do
                if v.playing ~= v.maxPlayers and v.playing > 4 then
                    corsa.info.serverhop_cooldown = true
					services.RunService:Stop()
					task.wait(1)
                    services.TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id)
                    coroutine.wrap(function()
                        task.wait(4.9)
                        corsa.info.serverhop_cooldown = false
                    end)()
					break
                end
            end
            return r
        end
    end)()
end

function corsa:is_in_game()
	return client.plr.PlayerGui.ScreenGui.UI.Target.Visible
end

function corsa:is_visible(start, result, part)
	local surge = corsa.players[part.Name]
	if surge then
		local bt = surge.backtrack
		if bt then
			return #workspace.CurrentCamera:GetPartsObscuringTarget({start, result}, {client:get_character(), part, workspace.KnifeHost, workspace.Pets, bt}) == 0
		end
	end
end

function corsa:get_state_from_velocity(velocity)
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

function corsa:predict_player(hrp)
	if lib.flags["custom_prediction"]["toggle"] then
		local vel = hrp.Velocity
		local state = corsa:get_state_from_velocity(vel)

		local x_vel = vel.X * lib.flags["running_prediction"]["value"]/200
		local y_vel = vel.Y > 0 and vel.Y * lib.flags["jumping_prediction"]["value"]/330 or vel.Y * lib.flags["falling_prediction"]["value"]/330
		local z_vel = vel.Z * lib.flags["running_prediction"]["value"]/200

		local distance = (client:get_character().HumanoidRootPart.Position-hrp.Position).magnitude/51
		local equation = distance*lib.flags["distance_multiplier"]["value"]/100

		return hrp.Position + Vector3.new(x_vel*equation,y_vel + distance,z_vel*equation)
	else
		local vel = hrp.Velocity
		local prediction = Vector3.new()
		local state = corsa:get_state_from_velocity(vel)

		local distance = (client:get_character().HumanoidRootPart.Position-hrp.Position).magnitude/51
		prediction = prediction + Vector3.new(0,distance,0)
		local distance = (client:get_character().HumanoidRootPart.Position-hrp.Position).magnitude/48

		prediction = prediction + Vector3.new((vel.X/8.7)*distance,0,0)
		prediction = prediction + Vector3.new(0,0,(vel.Z/8.7)*distance)

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

function corsa:get_closest_to_cursor()
	local closest = 9e9
	local target = nil

	if client:is_character_loaded() then
		for _, plr in next, services.Players:GetPlayers() do
			if plr ~= client.plr then
				local character = corsa.players[plr.Name].instance.Character

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

for _, part in pairs(corsa.assets.fake:GetChildren()) do
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

LPH_NO_VIRTUALIZE(function()
	for i,v in pairs(getgc()) do
		if typeof(v) == "function" and string.find(debug.getinfo(v, "s").source, "localchat") and debug.getinfo(v, "n").name == "doChat" then
			corsa.assassin.chat = v
		elseif typeof(v) == "function" and string.find(debug.getinfo(v, "s").source, "Network") then
			if quik.find(getconstants(v), "FireServer") then
				corsa.assassin.hit_player = v
			end
		end
	end
end)()

task.wait()

-- ! init menu

local sessionBack = Instance.new("Frame")
local sessionBack2 = Instance.new("Frame")
local sessionLabel = Instance.new("TextLabel")
local sessionLine = Instance.new("Frame")
local sessionTimeLabel = Instance.new("TextLabel")
local sessionTimeValue = Instance.new("TextLabel")
local sessionKillsLabel = Instance.new("TextLabel")
local sessionKillsValue = Instance.new("TextLabel")

local ui1 = Instance.new("ScreenGui", game.CoreGui); 
if gethui then ui1.Parent = gethui() end
if syn and syn.protect_gui then syn.protect_gui(ui1) end
ui1.ResetOnSpawn = false; ui1.Enabled = false

sessionBack.Name = "sessionBack"
sessionBack.Parent = ui1
sessionBack.BackgroundColor3 = Color3.fromRGB(27, 22, 20)
sessionBack.BorderSizePixel = 0
sessionBack.Size = UDim2.new(0, 140, 0, 83)

lib:set_draggable(sessionBack)

do
	local uiCorner = Instance.new("UICorner",sessionBack); uiCorner.CornerRadius = UDim.new(0,6)
	sessionBack2.Name = "sessionBack2"
	sessionBack2.Parent = sessionBack
	sessionBack2.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
	sessionBack2.BorderSizePixel = 0
	sessionBack2.Position = UDim2.new(0, 1, 0, 1)
	sessionBack2.Size = UDim2.new(1, -2, 1, -2)

	sessionLabel.Name = "sessionLabel"
	sessionLabel.Parent = sessionBack2
	sessionLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sessionLabel.BackgroundTransparency = 1.000
	sessionLabel.Position = UDim2.new(0, 0, 0, 3)
	sessionLabel.Size = UDim2.new(1, 0, 0, 20)
	sessionLabel.Font = Enum.Font.Arial
	sessionLabel.Text = "session information"
	sessionLabel.TextColor3 = Color3.fromRGB(218, 218, 218)
	sessionLabel.TextSize = 14.000
	sessionLabel.TextStrokeColor3 = Color3.fromRGB(14, 14, 14)
	sessionLabel.TextStrokeTransparency = 0.220

	sessionLine.Name = "sessionLine"
	sessionLine.Parent = sessionLabel
	sessionLine.BackgroundColor3 = Color3.fromRGB(218, 154, 169)
	sessionLine.BorderSizePixel = 0
	sessionLine.Position = UDim2.new(0, 0, 1, 2)
	sessionLine.Size = UDim2.new(1, 0, 0, 2)

	sessionTimeLabel.Name = "sessionTimeLabel"
	sessionTimeLabel.Parent = sessionBack2
	sessionTimeLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sessionTimeLabel.BackgroundTransparency = 1.000
	sessionTimeLabel.BorderSizePixel = 0
	sessionTimeLabel.Position = UDim2.new(0, 8, 0, 31)
	sessionTimeLabel.Size = UDim2.new(0, 73, 0, 25)
	sessionTimeLabel.Font = Enum.Font.Arial
	sessionTimeLabel.Text = "time played:"
	sessionTimeLabel.TextColor3 = Color3.fromRGB(218, 218, 218)
	sessionTimeLabel.TextSize = 13.000
	sessionTimeLabel.TextStrokeColor3 = Color3.fromRGB(14, 14, 14)
	sessionTimeLabel.TextStrokeTransparency = 0.200
	sessionTimeLabel.TextXAlignment = Enum.TextXAlignment.Left

	sessionTimeValue.Name = "sessionTimeValue"
	sessionTimeValue.Parent = sessionTimeLabel
	sessionTimeValue.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sessionTimeValue.BackgroundTransparency = 1.000
	sessionTimeValue.BorderSizePixel = 0
	sessionTimeValue.Position = UDim2.new(1, 0, 0, 0)
	sessionTimeValue.Size = UDim2.new(0, 73, 0, 25)
	sessionTimeValue.Font = Enum.Font.Arial
	sessionTimeValue.Text = "00:00:00"
	sessionTimeValue.TextColor3 = Color3.fromRGB(218, 154, 169)
	sessionTimeValue.TextSize = 13.000
	sessionTimeValue.TextStrokeColor3 = Color3.fromRGB(14, 14, 14)
	sessionTimeValue.TextStrokeTransparency = 0.200
	sessionTimeValue.TextXAlignment = Enum.TextXAlignment.Left

	sessionKillsLabel.Name = "sessionKillsLabel"
	sessionKillsLabel.Parent = sessionBack2
	sessionKillsLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sessionKillsLabel.BackgroundTransparency = 1.000
	sessionKillsLabel.BorderSizePixel = 0
	sessionKillsLabel.Position = UDim2.new(0, 8, 0, 51)
	sessionKillsLabel.Size = UDim2.new(0, 28, 0, 25)
	sessionKillsLabel.Font = Enum.Font.Arial
	sessionKillsLabel.Text = "kills:"
	sessionKillsLabel.TextColor3 = Color3.fromRGB(218, 218, 218)
	sessionKillsLabel.TextSize = 13.000
	sessionKillsLabel.TextStrokeColor3 = Color3.fromRGB(14, 14, 14)
	sessionKillsLabel.TextStrokeTransparency = 0.200
	sessionKillsLabel.TextXAlignment = Enum.TextXAlignment.Left

	sessionKillsValue.Name = "sessionKillsValue"
	sessionKillsValue.Parent = sessionKillsLabel
	sessionKillsValue.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sessionKillsValue.BackgroundTransparency = 1.000
	sessionKillsValue.BorderSizePixel = 0
	sessionKillsValue.Position = UDim2.new(1, 0, 0, 0)
	sessionKillsValue.Size = UDim2.new(0, 73, 0, 25)
	sessionKillsValue.Font = Enum.Font.Arial
	sessionKillsValue.Text = "0"
	sessionKillsValue.TextColor3 = Color3.fromRGB(218, 154, 169)
	sessionKillsValue.TextSize = 13.000
	sessionKillsValue.TextStrokeColor3 = Color3.fromRGB(14, 14, 14)
	sessionKillsValue.TextStrokeTransparency = 0.200
	sessionKillsValue.TextXAlignment = Enum.TextXAlignment.Left
end

local services = setmetatable({}, { __index = function(self, key) return game:GetService(key) end })
local screen_gui = Instance.new("ScreenGui", game.CoreGui)
if syn and syn.protect_gui then syn.protect_gui(screen_gui) elseif gethui then screen_gui.Parent = gethui() end 

uiCorner = Instance.new("UICorner",sessionBack2); uiCorner.CornerRadius = UDim.new(0,6)

local win = lib:create_window()

local combat = win:create_tab({name = "combat", icon = "http://www.roblox.com/asset/?id=12407137599"})
	local combat_main = combat:create_subtab({name = "main"})
		local general_aimhelper = combat_main:create_section({name = "aim helper"})
			local aim_helper = general_aimhelper:create_element({name = "enabled", flag = "aim_helper", c_default = Color3.fromRGB(255,255,255), t_default = false, types = {"toggle", "keybind"}, callback = function()
			end})
			local silent_aim = general_aimhelper:create_element({name = "silent aim", flag = "silent_aim", t_default = false, types = {"toggle"}, callback = function()
			end})
			local silent_tracer = general_aimhelper:create_element({name = "silent tracer", flag = "silent_tracer", t_default = false, types = {"toggle", "colorpicker"}, c_default = Color3.fromRGB(255,255,255), callback = function()
			end})
			local custom_prediction = general_aimhelper:create_element({name = "use custom prediction", flag = "custom_prediction", t_default = false, types = {"toggle"}, callback = function()
			end})
			local fov_radius = general_aimhelper:create_element({name = "helper fov", flag = "fov_radius", types = {"slider"}, min = 5, max = 500, s_default = 50, callback = function()
				cheat.aim_circle.Radius = lib.flags["fov_radius"]["value"]*1.5
			end})
		local general_aimcircles = combat_main:create_section({name = "aim circles"})
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
		local general_aimbotsettings = combat_main:create_section({name = "aimbot settings"})
			local shake = general_aimbotsettings:create_element({name = "shake", flag = "shake", t_default = false, types = {"toggle", "slider"}, min = 1, max = 100, suffix = "%", callback = function()
			end})
			local random_smoothness = general_aimbotsettings:create_element({name = "randomness", flag = "randomness", t_default = false, types = {"toggle", "slider"}, min = 1, max = 100, suffix = "%", callback = function()
			end})
			local vertical_smoothness = general_aimbotsettings:create_element({name = "vertical smoothing", flag = "vertical_smoothness", types = {"slider"}, min = 1, max = 20, s_default = 1, callback = function()
			end})
			local horizontal_smoothness = general_aimbotsettings:create_element({name = "horizontal smoothing", flag = "horizontal_smoothness", types = {"slider"}, min = 1, max = 20, s_default = 1, callback = function()
			end})
		local general_customprediction = combat_main:create_section({name = "custom prediction"})
			for i = 1, #corsa.states do
				local state = corsa.states[i]
				local state_prediction = general_customprediction:create_element({name = state.." prediction", flag = state.."_".."prediction", types = {"slider"}, min = -100, max = 100, s_default = 0, callback = function()
				end})
			end
			local distance_multiplier = general_customprediction:create_element({name = "distance multiplier", flag = "distance_multiplier", types = {"slider"}, min = 1, max = 100, s_default = 25, suffix = "%", callback = function()
			end})
		local hitboxes = combat_main:create_section({name = "hitboxes"})
			local backtrack = hitboxes:create_element({name = "backtrack", flag = "backtrack", types = {"toggle", "slider"}, min = 5, max = 50, suffix = "%", callback = function()
			end})
			local jitter = hitboxes:create_element({name = "jitter", flag = "jitter", tip = "adds randomness to the backtrack value", types = {"toggle"}, callback = function()
			end})
			local model = hitboxes:create_element({name = "model", d_default = "forcefield", flag = "model", types = {"colorpicker", "dropdown"}, options = {"forcefield", "neon"}, no_none = true, c_default = Color3.fromRGB(43,195,175), callback = function()
			end})
			local expander = hitboxes:create_element({name = "expander", flag = "expander", types = {"toggle", "dropdown", "colorpicker"}, c_default = Color3.fromRGB(255,255,255), options = {"forcefield", "neon"}, d_default = "forcefield", no_none = true, callback = function()
			end})
			local expanderx = hitboxes:create_element({name = "size x", flag = "sizex", types = {"slider"}, min = 2, max = 100, s_default = 2, callback = function()
			end})
			local expanderx = hitboxes:create_element({name = "size y", flag = "sizey", types = {"slider"}, min = 2, max = 100, s_default = 2, callback = function()
			end})
			local expanderx = hitboxes:create_element({name = "size z", flag = "sizez", types = {"slider"}, min = 1, max = 100, s_default = 1, callback = function()
			end})
			local expandervisible = hitboxes:create_element({name = "visible check", flag = "expandervisible", types = {"toggle"}, callback = function()
			end})
		local combat_misc = combat_main:create_section({name = "misc"})
			local delay_throw = combat_misc:create_element({name = "delay throw", flag = "delay_throw", types = {"toggle", "slider"}, min = 30, max = 250, s_default = 30, suffix = "ms", callback = function()
			end})
			local autoequip = combat_misc:create_element({name = "auto equip", flag = "autoequip", types = {"toggle", "slider"}, min = 30, max = 200, s_default = 30, suffix = "ms", callback = function()
			end})
			local fastthrow = combat_misc:create_element({name = "fast throw", suffix = "%", flag = "fastthrow", types = {"toggle", "slider"}, min = 1, max = 100, s_default = 1, callback = function()
			end})
			local stabaura = combat_misc:create_element({name = "stab aura", flag = "stabaura", types = {"toggle"}, callback = function()
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
		local collect = general:create_section({name = "automation"})
			local autoghost = collect:create_element({name = "collect ghost coins", flag = "autoghost", types = {"toggle"}, callback = function()
			end}) 
			local autoclaim = collect:create_element({name = "auto season pass", flag = "autoclaim", types = {"toggle"}, callback = function()
			end})
			local autotrade = collect:create_element({name = "auto trade", flag = "autotrade", types = {"toggle"}, callback = function()
			end})
			local autocase = collect:create_element({name = "auto case", flag = "autocase", types = {"toggle", "dropdown"}, options = corsa.cases, callback = function()
			end})
		local webhooks = general:create_section({name = "webhooks"})
			local webhookurl = webhooks:create_element({name = "webhook url", flag = "url", types = {"textbox"}, callback = function()
			end})
			local alerts = webhooks:create_element({name = "send stats every", flag = "alerts", types = {"toggle", "slider"}, suffix = " mins", min = 3, max = 45, s_default = 3, callback = function()
			end})
		local serverhop = general:create_section({name = "serverhop"})
			local serverhop_on = serverhop:create_element({name = "serverhop on", multi = true, flag = "serverhop", types = {"toggle", "dropdown"}, options = {"all afk", "less than 5 players"}, callback = function()
			end})
local character_menu = win:create_tab({name = "character", icon = "rbxassetid://8680441960"})
	local movement = character_menu:create_subtab({name = "movement"})
		local move_motion = movement:create_section({name = "motion"})
			local speed = move_motion:create_element({name = "cframe speed", flag = "speed", types = {"toggle", "slider", "keybind"}, min = 1, max = 100, s_default = 1, suffix = "%", callback = function()
			end})
			local quickstop = move_motion:create_element({name = "quick stop", flag = "quickstop", types = {"toggle"}, callback = function()
			end})
			local autojump = move_motion:create_element({name = "auto jump", flag = "autojump", types = {"toggle"}, callback = function()
			end})
			local spinbot = move_motion:create_element({name = "spinbot", flag = "spinbot", t_default = false, types = {"toggle", "slider"}, min = 1, max = 30, s_default = 1, suffix = "°", callback = function()
			end})
		local fakelag2 = movement:create_section({name = "fake lag"})
			local fakelag = fakelag2:create_element({name = "character lag", flag = "fakelag", types = {"toggle", "slider", "keybind"}, min = 1, max = 100, s_default = 1, suffix = "%", callback = function()
			end})
			local breakpattern = fakelag2:create_element({name = "break pattern", flag = "breakpattern", tip = "adds randomness to the character lag", types = {"toggle"}, callback = function()
			end})
			local breakthrow = fakelag2:create_element({name = "break throw", flag = "breakthrow", tip = "stops fake lag briefly when you throw a knife", types = {"toggle"}, callback = function()
			end})
			local fakelagmodel = fakelag2:create_element({name = "lag model", d_default = "forcefield", flag = "fakelagmodel", types = {"colorpicker", "dropdown"}, options = {"forcefield", "neon"}, no_none = true, c_default = Color3.fromRGB(43,195,175), callback = function()
			end})
		local move_misc = movement:create_section({name = "misc"})
			local autorotate = move_misc:create_element({name = "auto rotate", flag = "autorotate", t_default = true, types = {"toggle"}, callback = function()
			end})
			local autopeek = move_misc:create_element({name = "auto peek", flag = "autopeek", c_default = Color3.fromRGB(255,255,255), k_default = {method = "hold", key = "none"}, types = {"toggle", "keybind", "colorpicker", "dropdown"}, options = {"move", "teleport"}, no_none = true, d_default = "move", callback = function()
			end})
			local peekdelay = move_misc:create_element({name = "delay", tip = "adds delay before moving or teleporting after throwing", flag = "delay", types = {"slider"}, min = 0, max = 100, suffix = "%", s_default = 10, callback = function()
			end})
			local noclip = move_misc:create_element({name = "noclip", flag = "noclip", k_default = {method = "toggle", key = "none"}, types = {"toggle", "keybind"}, callback = function()
			end})
local visuals = win:create_tab({name = "visuals", icon = "http://www.roblox.com/asset/?id=12406796266"})
	local visuals_players = visuals:create_subtab({name = "players"})
		local players_esp = visuals_players:create_section({name = "player esp"})
			local esp_enabled = players_esp:create_element({name = "enabled", flag = "pesp", types = {"toggle"}, callback = function()
			end})
			local esp_outline1 = players_esp:create_element({name = "outlines", t_default = false, flag = "outlines", types = {"toggle"}, callback = function()
			end})
			local esp_box = players_esp:create_element({name = "box", flag = "box", c_default = Color3.fromRGB(201,201,201), types = {"toggle", "colorpicker"}, callback = function()
			end})
			local esp_fill = players_esp:create_element({name = "fill", flag = "fill", c_default = Color3.fromRGB(201,201,201), types = {"toggle", "colorpicker"}, callback = function()
			end})
			local esp_name = players_esp:create_element({name = "name", flag = "name", suffix = "px", c_default = Color3.fromRGB(201,201,201), types = {"toggle", "colorpicker"}, callback = function()
			end})
			local esp_chams = players_esp:create_element({name = "chams", flag = "chams", c_default = Color3.fromRGB(0,0,0), types = {"toggle", "colorpicker"}, callback = function()
			end})
			local esp_outline = players_esp:create_element({name = "chams outline", flag = "outline", c_default = Color3.fromRGB(0,201,0), types = {"colorpicker"}, callback = function()
			end})
			local hit_chams = players_esp:create_element({name = "hit chams", flag = "hit_chams", c_default = Color3.fromRGB(255,0,175), types = {"toggle", "dropdown", "colorpicker"}, no_none = true, d_default = "forcefield", options = {"forcefield", "neon"}, callback = function()
			end})
			local esp_timerbar = players_esp:create_element({name = "timer bar", flag = "timerbar", c_default = Color3.fromRGB(0,255,0), types = {"toggle", "colorpicker"}, callback = function()
			end})
			local esp_throwbar = players_esp:create_element({name = "throw bar", flag = "throwbar", c_default = Color3.fromRGB(0,255,0), types = {"toggle", "colorpicker"}, callback = function()
			end})
			local esp_offscreen = players_esp:create_element({name = "oof arrows", flag = "offscreen", min = 30, max = 250, s_default = 150, suffix = "", c_default = Color3.fromRGB(201,201,201), types = {"toggle", "colorpicker", "slider"}, callback = function()
			end})
			local esp_offscreen_distance = players_esp:create_element({name = "arrow distance", flag = "offscreen_distance", min = 50, max = 900, s_default = 400, suffix = "", types = {"slider"}, callback = function()
			end})
			local esp_font = players_esp:create_element({name = "font", flag = "font", d_default = "Plex", no_none = true, types = {"dropdown"}, options = {"Plex", "System", "Monospace"}, callback = function()
			end})
			local esp_fontsizez = players_esp:create_element({name = "text size", flag = "fontsize", types = {"slider"}, min = 12, max = 20, s_default = 14, callback = function()
			end})
			local esp_max_distance = players_esp:create_element({name = "max distance", flag = "max_distance", min = 50, max = 500, s_default = 400, suffix = "", types = {"slider"}, callback = function()
			end})
		local target_esp = visuals_players:create_section({name = "target esp"})
			local esp_box = target_esp:create_element({name = "box", flag = "t_box", c_default = Color3.fromRGB(201,201,201), types = {"colorpicker"}, callback = function()
			end})
			local esp_fill = target_esp:create_element({name = "fill", flag = "t_fill", c_default = Color3.fromRGB(201,201,201), types = {"colorpicker"}, callback = function()
			end})
			local esp_name = target_esp:create_element({name = "name", flag = "t_name", suffix = "px", c_default = Color3.fromRGB(201,201,201), types = {"colorpicker"}, callback = function()
			end})
			local esp_chams = target_esp:create_element({name = "chams", flag = "t_chams", c_default = Color3.fromRGB(0,0,0), types = {"colorpicker"}, callback = function()
			end})
			local esp_outline = target_esp:create_element({name = "chams outline", flag = "t_outline", c_default = Color3.fromRGB(201,0,0), types = {"colorpicker"}, callback = function()
			end})
			local esp_timerbar = target_esp:create_element({name = "timer bar", flag = "t_timerbar", c_default = Color3.fromRGB(255,0,0), types = {"colorpicker"}, callback = function()
			end})
			local esp_throwbar = target_esp:create_element({name = "throw bar", flag = "t_throwbar", c_default = Color3.fromRGB(255,0,0), types = {"colorpicker"}, callback = function()
			end})
			local esp_offscreen = target_esp:create_element({name = "oof arrows", flag = "t_offscreen", c_default = Color3.fromRGB(255,0,0), types = {"colorpicker"}, callback = function()
			end})
		local self_esp = visuals_players:create_section({name = "self esp"})
			local show_stab_range = self_esp:create_element({name = "show stab range", flag = "stab_range", c_default = Color3.fromRGB(201,201,201), types = {"toggle", "colorpicker"}, callback = function()
			end})
			local knifecolor = self_esp:create_element({name = "forcefield knife", flag = "knifecolor", c_default = Color3.fromRGB(255,0,0), types = {"toggle", "colorpicker"}, callback = function()
			end})
			local highlight = self_esp:create_element({name = "highlight", flag = "shighlight", c_default = Color3.fromRGB(0,0,0), types = {"toggle", "colorpicker"}, callback = function()
			end})
			local outline = self_esp:create_element({name = "outline", flag = "soutline", c_default = Color3.fromRGB(255,255,255), types = {"colorpicker"}, callback = function()
			end})
	local visuals_game = visuals:create_subtab({name = "game"})
		local visuals_world = visuals_game:create_section({name = "world"})
			local hue = visuals_world:create_element({name = "hue", flag = "hue", c_default = game.Lighting.Ambient, types = {"toggle", "colorpicker"}, callback = function()
				if lib.flags["hue"]["toggle"] then
					game.Lighting.Ambient = lib.flags["hue"]["color"]
				else
					game.Lighting.Ambient = corsa.old.ambient
				end
			end})
			local hue = visuals_world:create_element({name = "shadow hue", flag = "shadowhue", c_default = game.Lighting.OutdoorAmbient, types = {"toggle", "colorpicker"}, callback = function()
				if lib.flags["shadowhue"]["toggle"] then
					game.Lighting.OutdoorAmbient = lib.flags["shadowhue"]["color"]
				else
					game.Lighting.OutdoorAmbient = corsa.old.outdoorambient
				end
			end})
			local fov = visuals_world:create_element({name = "fov", flag = "fov", types = {"toggle", "slider"}, min = 70, max = 120, s_default = 70, callback = function()
			end})
			local worldtime = visuals_world:create_element({name = "time", min = 0, max = 24, flag = "clocktime", s_default = corsa.old.ClockTime, types = {"slider", "toggle"}, callback = function()
				if lib.flags["clocktime"]["toggle"] then
					game.Lighting.ClockTime = lib.flags["clocktime"]["value"]
				else
					game.Lighting.ClockTime = corsa.old.clocktime
				end
			end})
			local fog = visuals_world:create_element({name = "fog", flag = "fog", c_default = corsa.old.fogcolor, types = {"colorpicker", "toggle"}, callback = function()
				if lib.flags["fog"]["toggle"] then
					game.Lighting.FogColor = lib.flags["fog"]["color"]
				else
					game.Lighting.FogColor = corsa.old.fogcolor
				end
			end})
			local fogstart = visuals_world:create_element({name = "fog start", flag = "fogstart", s_default = corsa.old.fogstart, types = {"slider"}, sdefault = 500, min = 1, max = 5000, callback = function()
				if lib.flags["fog"]["toggle"] then
					game.Lighting.FogStart = lib.flags["fogstart"]["value"]
				else
					game.Lighting.FogStart = corsa.old.fogstart
					game.Lighting.FogColor = corsa.old.fogcolor
					game.Lighting.FogEnd = corsa.old.fogend
				end
			end})
			local fogend = visuals_world:create_element({name = "fog end", flag = "fogend", s_default = corsa.old.FogEnd, types = {"slider"}, sdefault = 500, min = 1, max = 5000, callback = function()
				if lib.flags["fog"]["toggle"] then
					game.Lighting.FogEnd = lib.flags["fogend"]["value"]
				end
			end})
			local removals = visuals_world:create_element({name = "removals", multi = true, flag = "removals", types = {"dropdown"}, options = {"ragdolls", "shadows", "pets"}, callback = function()
			end})
		local visuals_hud = visuals_game:create_section({name = "hud"})
			local stats_menu = visuals_hud:create_element({name = "session stats", flag = "stats", c_default = Color3.fromRGB(255,0,175), types = {"toggle", "colorpicker"}, t_default = false, callback = function()
				ui1.Enabled = lib.flags["stats"]["toggle"]
			end})
			local throwsound = visuals_hud:create_element({name = "knife sound", no_none = true, d_default = "bow", options = {"bow"}, flag = "throwsound", types = {"toggle", "dropdown"}, callback = function()
			end})
			local hitsound = visuals_hud:create_element({name = "hitsound", no_none = true, d_default = "skeet", options = {"minecraft", "skeet", "cod", "rust", "neverlose", "bameware"}, flag = "hitsound", types = {"toggle", "dropdown"}, callback = function()
			end})
			local volume = visuals_hud:create_element({name = "volume", flag = "volume", types = {"slider"}, min = 1, max = 100, s_default = 1, suffix = "%", callback = function()
			end})
		local visuals_chat = visuals_game:create_section({name = "chat"})
			local chat_color = visuals_chat:create_element({name = "chat color", flag = "chat_color", types = {"toggle", "colorpicker", "dropdown"}, options = {"random"}, c_default = Color3.fromRGB(255,255,255), callback = function()
			end})
			local chat_spam = visuals_chat:create_element({name = "chat spam", flag = "chat_spam", types = {"toggle", "textbox"}, callback = function()
			end})
			local spam_delay = visuals_chat:create_element({name = "delay", flag = "spam_delay", min = 2, max = 5, suffix = "s", types = {"slider"}, callback = function()
			end})
			local vip_tag = visuals_chat:create_element({name = "vip tag", flag = "vip_tag", types = {"toggle"}, callback = function()
			end})
			local killsay = visuals_chat:create_element({name = "killsay", tip = "says a custom message when you kill somebody. configurable @ workspace/corsa/killsays.txt", flag = "killsay", types = {"toggle"}, callback = function()
			end})
local misc = win:create_tab({name = "misc", icon = "http://www.roblox.com/asset/?id=12447089653"})
	local misc_main = misc:create_subtab({name = "main"})
		local main_config = misc_main:create_section({name = "config"})
			local config_list = main_config:create_element({name = "list", flag = "selected_config", options = lib.getConfigList(), types = {"dropdown"}, callback = function()
			end})
			local config_name = main_config:create_element({name = "name", flag = "text_config", types = {"textbox"}, callback = function()
			end})
			local config_create = main_config:create_element({name = "create config", flag = "2", types = {"button"}, callback = function()
				if not isfile("corsa/configs/"..lib.flags["text_config"]["text"]..".cfg") then
					lib.flags["stats_location"] = {sessionBack.Position.X.Scale, sessionBack.Position.X.Offset, sessionBack.Position.Y.Scale, sessionBack.Position.Y.Offset}
					lib.saveConfig(lib.flags["text_config"]["text"])
					config_list:set_p_options(lib.getConfigList())
				end
			end})
			local reload_list = main_config:create_element({name = "reload list", types = {"button"}, callback = function()
				config_list:set_p_options(lib.getConfigList())
			end})
			local config_load = main_config:create_element({name = "load config", confirmation = true, flag = "3", types = {"button"}, callback = function()
				if isfile("corsa/configs/"..lib.flags["selected_config"]["selected"][1]..".cfg") then
					lib.loadConfig(lib.flags["selected_config"]["selected"][1])
				end
				sessionBack.Position = UDim2.new(unpack(lib.flags["stats_location"]))
			end})
			local config_save = main_config:create_element({name = "override config", confirmation = true, flag = "4", types = {"button"}, callback = function()
				if isfile("corsa/configs/"..lib.flags["selected_config"]["selected"][1]..".cfg") then
					lib.flags["stats_location"] = {sessionBack.Position.X.Scale, sessionBack.Position.X.Offset, sessionBack.Position.Y.Scale, sessionBack.Position.Y.Offset}
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
		if game.PlaceId ~= 5006801542 then
			local menu_joincfreeplay = main_teleports:create_element({name = "join freeplay", confirmation = true, flag = "1", types = {"button"}, callback = function()
				services.TeleportService:Teleport(5006801542, client.plr)
			end})
		end
		if game.PlaceId ~= 379614936 then
			local menu_joinclassic = main_teleports:create_element({name = "join classic", confirmation = true, flag = "1111", types = {"button"}, callback = function()
				services.TeleportService:Teleport(379614936, client.plr)
			end})
		end
		if game.PlaceId ~= 860428890 then
			local menu_joinpro = main_teleports:create_element({name = "join pro", confirmation = true, flag = "11111", types = {"button"}, callback = function()
				services.TeleportService:Teleport(860428890, client.plr)
			end})
		end

-- ! namecall

local old_nc = nil
old_nc = hookmetamethod(game, "__namecall", LPH_NO_VIRTUALIZE(function(self, ...)
	local args = {...}
	local method = getnamecallmethod()
	if method == "FireServer" and tostring(self) == "ThrowKnife" then
		coroutine.wrap(function()
			if lib.flags["delay"]["value"] > 0 then
				task.wait(1*(lib.flags["delay"]["value"]/100))
			end
			corsa.info.retreating = true
		end)()
		if not checkcaller() then
			coroutine.wrap(function()
				corsa.signals.knife_thrown:Fire(args)
			end)()
			if lib.flags["delay_throw"]["toggle"] then
				return
			end
		end
		if lib.flags["breakthrow"]["toggle"] then
			coroutine.wrap(function()
				corsa.info.no_lag = true
				task.wait(0.11)
				corsa.info.no_lag = false
			end)()
		end
	elseif lib.flags["throwsound"]["toggle"] and method == "Play" and self.ClassName == "Sound" then -- if u know a better solution lmk gangie
		local id = self.SoundId
		if tostring(self) == "Swoosh" then
			self.SoundId = corsa.throwsounds[lib.flags["throwsound"]["selected"][1]]
			coroutine.wrap(function()
				task.wait(0.5)
				self.SoundId = id
			end)()
		end
		if tostring(self) == "Chop" then
			self.SoundId = corsa.collidesounds[lib.flags["throwsound"]["selected"][1]]
			coroutine.wrap(function()
				task.wait(0.5)
				self.SoundId = id
			end)()
		end
	elseif method == "FireServer" and tostring(self) == "nugget" and lib.flags["chat_color"]["toggle"] then
		if lib.flags["chat_color"]["toggle"] then
			local replacement_color = #lib.flags["chat_color"]["selected"] == 1 and Color3.fromRGB(math.random(255), math.random(255), math.random(255)) or lib.flags["chat_color"]["color"]
			args[3] = replacement_color
		end
		if args[4] == "" and lib.flags["vip_tag"]["toggle"] then
			args[4] = "[VIP]"
		end
		return old_nc(self, unpack(args))
	elseif tostring(getcallingscript()) == "knifeScript" and method == "FindPartOnRayWithIgnoreList" then
		if corsa.info.aim_location then
			local camera = workspace.CurrentCamera.CFrame.p
			args[1] = Ray.new(camera, ((corsa.info.aim_location + Vector3.new(0,(camera-corsa.info.aim_location).Magnitude/150,0) - camera).unit * (150 * 10)))
		end
		return old_nc(self, unpack(args))
	elseif not checkcaller() and method == "GetPlayerFromCharacter" then
		character = args[1]

		if character:FindFirstChild("StringValue") then
			return services.Players:FindFirstChild(character:FindFirstChild("StringValue").Value)
		end
	elseif not checkcaller() and method == "FireServer" and string.find(self.Name, ".") then
		coroutine.wrap(function()
			corsa.signals.hit_player:Fire(tostring(args[1]))
		end)()
	end
	return old_nc(self, ...)
end))

-- ! connections

local on_knife_thrown = connection.new(corsa.signals.knife_thrown, function(args)
	if lib.flags["delay_throw"]["toggle"] and args then
		coroutine.wrap(function()
			task.wait(lib.flags["delay_throw"]["value"]/1000)
			services.ReplicatedStorage.Remotes.ThrowKnife:FireServer(unpack(args))
		end)()
	end
end)

local player_added = connection.new(services.Players.PlayerAdded, function(player)
	if player == services.Players.LocalPlayer then return end
	corsa.players[player.Name] = enemy.new(player)
	corsa.esp[player.Name] = esp:create_drawings()
	if lib.flags["serverhop"]["toggle"] then
		if quik.find(lib.flags["serverhop"]["selected"], "less than 5 players") then
			if #services.Players:GetPlayers() < 5 then
				task.spawn(function()
					while task.wait(5) do
						corsa:serverhop()
					end
				end)
			end
		end 
	end
end)

local player_removing = connection.new(services.Players.PlayerRemoving, function(player)
	if player == services.Players.LocalPlayer then return end
	corsa.locations[player.Name] = nil
	corsa.players[player.Name].backtrack:Destroy()
	for i,v in pairs(corsa.esp[player.Name]) do
		if i == highlight then
			v:Destroy()
		else
			v:Remove()
		end
	end
	corsa.players[player.Name] = nil
	if lib.flags["serverhop"]["toggle"] then
		if quik.find(lib.flags["serverhop"]["selected"], "less than 5 players") then
			if #services.Players:GetPlayers() < 5 then
				task.spawn(function()
					while task.wait(5) do
						corsa:serverhop()
					end
				end)
			end
		end 
	end
end)

local chat_added = connection.new(client.plr.PlayerGui.ScreenGui.UI.Chat.GlobalChat.ChildAdded, function(c)
    c:WaitForChild("msg")
    repeat task.wait() until c.msg.Text ~= "" and c.msg.Text ~= nil
	if lib.flags["chat_color"]["toggle"] and string.find(c.plr.Text, client.plr.Name) then
        c.plr.TextColor3 = lib.flags["chat_color"]["color"]
		local replacement_color = #lib.flags["chat_color"]["selected"] == 1 and Color3.fromRGB(math.random(255), math.random(255), math.random(255)) or lib.flags["chat_color"]["color"]
		c.plr.TextColor3 = replacement_color
    end
end)

local player_killed = connection.new(services.ReplicatedStorage.Remotes.TargetMessage.OnClientEvent, LPH_JIT_MAX(function(...)
	local args = {...}
    if (string.find(string.lower(args[1]), "elim") or string.find(string.lower(args[1]), "claim")) then
		corsa.info.recent = true
		corsa.info.kills = corsa.info.kills + 1
		sessionKillsValue.Text = tostring(corsa.info.kills)
		coroutine.wrap(function()
			corsa.info.kill_cooldown = true
			task.wait(0.73)
			corsa.info.kill_cooldown = false
		end)()

		if lib.flags["killsay"]["toggle"] then
			local killsays = lib:get_killsays()
            if killsays then
                local v = killsays[math.random(1,#killsays)]
                services.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(v,"All")
                corsa.assassin.chat(v)
            end
		end

		if lib.flags["hitsound"]["toggle"] then
			local hitsound = Instance.new("Sound", client.plr.PlayerGui)
			hitsound.Name = "\255"
			hitsound.SoundId = corsa.hitsounds[lib.flags["hitsound"]["selected"][1]]
			hitsound.Volume = lib.flags["volume"]["value"]/100
			hitsound.PlayOnRemove = true
			hitsound:Destroy()
		end
    end
end))

for _, player in next, services.Players:GetPlayers() do
	if player == services.Players.LocalPlayer then continue end
	corsa.players[player.Name] = enemy.new(player)
	corsa.esp[player.Name] = esp:create_drawings()
end

local ragdoll_added = connection.new(workspace.Ragdolls.ChildAdded, LPH_JIT_MAX(function(ragdoll)
	repeat task.wait() until ragdoll:FindFirstChild("Torso") and ragdoll:FindFirstChild("Torso"):FindFirstChild("Dead")
    local torso = ragdoll:FindFirstChild("Torso")
    local sound = torso:FindFirstChild("Dead")
    if lib.flags["hitsound"]["toggle"] and corsa.info.recent then
        sound.Volume = 0
    end
	corsa.info.recent = false
end))

local on_render = connection.new(services.RunService.RenderStepped, LPH_JIT_MAX(function()
	corsa.aim_circle.Position = Vector2.new(client.mouse.X, client.mouse.Y + lib.flags["fov_offset"]["value"])
	corsa.aim_circle.Visible = aim_helper:get_active() and lib.flags["aim_helper"]["toggle"] and lib.flags["show_fov"]["toggle"]
	corsa.aim_circle.Color = lib.flags["show_fov"]["color"]
	corsa.aim_circle.Transparency = -lib.flags["show_fov"]["transparency"]+1
	corsa.aim_circle.Filled = lib.flags["fov_filled"]["toggle"]
	corsa.aim_circle.NumSides = lib.flags["fov_sides"]["value"]
	corsa.aim_circle.Radius = lib.flags["fov_radius"]["value"]*1.5
	local auto_peek = corsa.assets.auto_peek
	local stab_range = corsa.assets.stab_range
	local character = client:get_character()
	local isloaded = character and client:is_character_loaded() or false
	workspace.CurrentCamera.FieldOfView = lib.flags["fov"]["toggle"] and lib.flags["fov"]["value"] or 70
	auto_peek.Visible = false
	corsa.aim_tracer.Visible = false
	if lib.flags["silent_tracer"]["toggle"] and corsa.info.aim_location then
		corsa.aim_tracer.Visible = true
		corsa.aim_tracer.Color = lib.flags["silent_tracer"]["color"] 
		corsa.aim_tracer.Transparency = -lib.flags["silent_tracer"]["transparency"]+1
		local aim_screen_pos, visible = workspace.CurrentCamera:WorldToScreenPoint(corsa.info.aim_location)
		if visible then
			local mouse_pos = workspace.CurrentCamera:WorldToScreenPoint(client.mouse.Hit.p)
			corsa.aim_tracer.From = Vector2.new(mouse_pos.X, mouse_pos.Y)
			corsa.aim_tracer.To = Vector2.new(aim_screen_pos.X, aim_screen_pos.Y)
		else
			corsa.aim_tracer.Visible = false
		end
	end
	if lib.flags["autopeek"]["toggle"] and autopeek:get_active() then
		if corsa.info.auto_peeking then
			auto_peek.Visible = true
			auto_peek.Thickness = 1
			auto_peek.Color = lib.flags["autopeek"]["color"]
			auto_peek.Transparency = -lib.flags["autopeek"]["transparency"]+1
			auto_peek.ZIndex = 10
			auto_peek.Radius = 1.4
		end
	end
	stab_range.Visible = false
	if lib.flags["stab_range"]["toggle"] and isloaded and character:FindFirstChildOfClass("Tool") then
		stab_range.Visible = true
		stab_range.Thickness = 1
		stab_range.Color = lib.flags["stab_range"]["color"]
		stab_range.Transparency = -lib.flags["stab_range"]["transparency"]+1
		stab_range.ZIndex = 11
		stab_range.Radius = 6
		stab_range.Position = character.HumanoidRootPart.Position
	end
	if isloaded then
		local tool = character:FindFirstChildOfClass("Tool")
		local baseKnife = character:FindFirstChild("KnifeHandle") 
        if baseKnife then
            local knifeDeco = baseKnife:FindFirstChild("KnifeDecorationHandle") 
            if knifeDeco then
                knifeDeco.Material = lib.flags["knifecolor"]["toggle"] and Enum.Material.ForceField or Enum.Material.Plastic
                knifeDeco.Color = lib.flags["knifecolor"]["color"]
            end
        end
        if tool then
            local handle = tool:FindFirstChild("Handle")
            if handle then
                local knifeDeco = handle:FindFirstChild("KnifeDecorationHandle") 
                if knifeDeco then
                    knifeDeco.Material = lib.flags["knifecolor"]["toggle"] and Enum.Material.ForceField or Enum.Material.Plastic
                    knifeDeco.Color = lib.flags["knifecolor"]["color"]
                end
            end
        end
	end
	local pets = quik.find(lib.flags["removals"]["selected"], "pets")
	game.Lighting.GlobalShadows = not quik.find(lib.flags["removals"]["selected"], "shadows")
	if pets then
		local pets = workspace.Pets:GetChildren()
		for i = 1, #pets do
			local pet = pets[i]
			if pet then
				pet.Parent = corsa.assets.pet_holder
			end
		end
	else
		local pets = corsa.assets.pet_holder:GetChildren()
		for i = 1, #pets do
			local pet = pets[i]
			if pet then
				pet.Parent = workspace.Pets
			end
		end
	end
	local ragdolls = quik.find(lib.flags["removals"]["selected"], "ragdolls")
	if ragdolls then
		local ragdolls = workspace.Ragdolls:GetChildren()
		for i = 1, #ragdolls do
			local ragdoll = ragdolls[i]
			if ragdoll then
				ragdoll.Parent = corsa.assets.ragdoll_holder
			end
		end
	else
		local ragdolls = corsa.assets.ragdoll_holder:GetChildren()
		for i = 1, #ragdolls do
			local ragdoll = ragdolls[i]
			if ragdoll then
				ragdoll.Parent = workspace.Ragdolls
			end
		end
	end
	for i, player in next, services.Players:GetPlayers() do
		local esp_table = corsa.esp[player.Name]

		if not esp_table then
			continue
		end

		for i,v in pairs(esp_table) do
			if i ~= "highlight" then
				v.Visible = false
			end
		end

		esp_table.highlight.Enabled = false

		if not lib.flags["pesp"]["toggle"] then
			return
		end

		local surge = corsa.players[player.Name]

		local character = surge.instance.Character

		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			local hum = character:FindFirstChildOfClass("Humanoid")
			if hrp and hum then
				local pos, visible = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
				local target = player == corsa.info.target

				if visible then
					local dist = (workspace.CurrentCamera.CFrame.Position-hrp.Position).magnitude
					if dist > lib.flags["max_distance"]["value"] then
						continue
					end

					local timepos = surge:is_throwing_knife()
					local real = surge.cooldown

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
						local box = esp_table.box
						local outline = esp_table.outline
						
						box.Size = box_size
						box.Position = box_pos
						box.Color = not target and lib.flags["box"]["color"] or lib.flags["t_box"]["color"]
						box.Transparency = not target and -lib.flags["box"]["transparency"]+1 or -lib.flags["t_box"]["transparency"]+1
						outline.Transparency = not target and -lib.flags["box"]["transparency"]+1 or-lib.flags["t_box"]["transparency"]+1
						outline.Size = box_size
						outline.Position = box_pos
						outline.Visible = lib.flags["outlines"]["toggle"]
						outline.Color = Color3.fromRGB(0,0,0)
						box.Visible = true
					end

					if lib.flags["fill"]["toggle"] then
						local fill = esp_table.fill
						
						fill.Size = box_size
						fill.Position = box_pos
						fill.Color = lib.flags["fill"]["color"]
						fill.Transparency = -lib.flags["fill"]["transparency"]+1
						fill.Visible = true
					end

					if lib.flags["name"]["toggle"] then
						local name = esp_table.name

						name.Text = player.Name 
						name.Position = Vector2.new(box_size.X / 2 + box_pos.X, box_pos.Y - name.TextBounds.Y - 1)
						name.Color = not target and lib.flags["name"]["color"] or lib.flags["t_name"]["color"] 
						name.Transparency = not target and -lib.flags["name"]["transparency"]+1 or -lib.flags["t_name"]["transparency"]+1
						name.Font = Drawing.Fonts[font]
						name.Size = lib.flags["fontsize"]["value"]
						name.Visible = true
						name.Outline = lib.flags["outlines"]["toggle"]
					end

					local offset = 0

					if lib.flags["throwbar"]["toggle"] then
						local throwpercent = timepos and ((timepos+0.05)*10)/5.5 or 0

						local throwbox = esp_table.throwbox
						local throwoutline = esp_table.throwoutline

						throwbox.From = Vector2.new(box_pos.X, (box_size.Y + box_pos.Y) + 4)
						throwbox.To = Vector2.new(throwbox.From.X + (throwpercent) * box_size.X, (box_size.Y + box_pos.Y) + 4)
						throwbox.Color = not target and lib.flags["throwbar"]["color"] or lib.flags["t_throwbar"]["color"] 
						throwbox.Transparency = not target and -lib.flags["throwbar"]["transparency"]+1 or -lib.flags["t_throwbar"]["transparency"]+1
						throwbox.Visible = timepos and true or false
		
						throwoutline.From = Vector2.new(throwbox.From.X, throwbox.From.Y)
						throwoutline.To = Vector2.new(throwbox.From.X + box_size.X, (box_size.Y + box_pos.Y) + 4)
						throwoutline.Color = Color3.fromRGB(0,0,0)
						throwoutline.Visible = lib.flags["outlines"]["toggle"]

						offset = 4
					end

					if lib.flags["timerbar"]["toggle"] then
						local knifepercent = real and ((real))/5 or 0
						local timerbox = esp_table.knifebox
						local timeroutline = esp_table.knifeoutline
		
						timeroutline.From = Vector2.new(box_pos.X - 5, box_pos.Y)
						timeroutline.To = Vector2.new(timeroutline.From.X, timeroutline.From.Y + box_size.Y)
						timeroutline.Color = Color3.fromRGB(0,0,0)
						timeroutline.Visible = lib.flags["outlines"]["toggle"]
						
						timerbox.From = timeroutline.To
						timerbox.To = Vector2.new(timerbox.From.X, timerbox.From.Y - knifepercent * box_size.Y)
						timerbox.Color = not target and lib.flags["timerbar"]["color"] or lib.flags["t_timerbar"]["color"] 
						timerbox.Transparency = not target and -lib.flags["timerbar"]["transparency"]+1 or -lib.flags["t_timerbar"]["transparency"]+1
						timerbox.Visible = true
					end
				elseif not visible then

				end
			end
		end
	end
end))

local keybind_on_handler = connection.new(services.UserInputService.InputBegan, function(input, gpe)
	if gpe then return end
	if string.lower(input.KeyCode.Name) == lib.flags["autopeek"]["key"] then
		if lib.flags["autopeek"]["toggle"] and client:is_character_loaded() then
			corsa.info.auto_peeking = true
			corsa.info.auto_peek_location = client:get_character().HumanoidRootPart.Position - Vector3.new(0,2.99,0)
			corsa.assets.auto_peek.Position = corsa.info.auto_peek_location
		end
	end
end)

local keybind_on_handler = connection.new(services.UserInputService.InputEnded, function(input, gpe)
	if gpe then return end
	if string.lower(input.KeyCode.Name) == lib.flags["autopeek"]["key"] then
		corsa.info.auto_peeking = false
	end
end)

local on_hue_change = connection.new(game.Lighting:GetPropertyChangedSignal("Ambient"), function()
	local new = game.Lighting.Ambient
	if new ~= lib.flags["hue"]["color"] then
		corsa.old.ambient = new
	end
	if lib.flags["hue"]["toggle"] then
		game.Lighting.Ambient = lib.flags["hue"]["color"]
	end
end)

local on_shadowhue_change = connection.new(game.Lighting:GetPropertyChangedSignal("OutdoorAmbient"), function()
	local new = game.Lighting.OutdoorAmbient
	if new ~= lib.flags["shadowhue"]["color"] then
		corsa.old.outdoorambient = new
	end
	if lib.flags["shadowhue"]["toggle"] then
		game.Lighting.OutdoorAmbient = lib.flags["shadowhue"]["color"]
	end
end)

local on_time_change = connection.new(game.Lighting:GetPropertyChangedSignal("ClockTime"), function()
	if game.Lighting.ClockTime ~= lib.flags["clocktime"]["value"] then
		corsa.old.clocktime= game.Lighting.ClockTime
	end
	if lib.flags["clocktime"]["toggle"] then
		game.Lighting.ClockTime = lib.flags["clocktime"]["value"]
	end
end)

local on_fogcolor_change = connection.new(game.Lighting:GetPropertyChangedSignal("FogColor"), function()
	if game.Lighting.FogColor ~= lib.flags["fog"]["color"] then
		corsa.old.fogcolor = game.Lighting.FogColor
	end
	if lib.flags["fog"]["toggle"] then
		game.Lighting.FogColor = lib.flags["fog"]["color"]
	end
end)

local on_fogstart_change = connection.new(game.Lighting:GetPropertyChangedSignal("FogStart"), function()
	if game.Lighting.FogStart ~= lib.flags["fogstart"]["value"] then
		corsa.old.fogstart = game.Lighting.FogStart
	end
	if lib.flags["fog"]["toggle"] then
		game.Lighting.FogStart = lib.flags["fogstart"]["value"]
	end
end)

local on_hit_player = connection.new(corsa.signals.hit_player, function(name)
	local surge = corsa.players[name]
	if surge then
		local character = surge.instance.Character
		if lib.flags["hit_chams"]["toggle"] and character and surge:is_loaded() then
			character.Archivable = true
			local char_clone = character:Clone()
			local char_parts = char_clone:GetChildren()
			local real_parts = {}
			for i = 1, #char_parts do
				local part = char_parts[i]
				if part.ClassName == "Part" and quik.find(corsa.parts, part.Name) then
					if quik.find(corsa.parts, part.Name) then
						part.Material = lib.flags["hit_chams"]["selected"][1] == "forcefield" and Enum.Material.ForceField or Enum.Material.Neon
						part.Transparency = 1
						part.Anchored = true
						part.CanCollide = false
						part.Color = lib.flags["hit_chams"]["color"]
						local decal = part:FindFirstChildOfClass("Decal")
						if decal then decal:Destroy() end
						table.insert(real_parts, part)
					end
				else
					part:Destroy()
				end
			end
			char_clone.Name = "\255"
			char_clone.Parent = workspace.KnifeHost
			for i = 1, #real_parts do
				local part = real_parts[i]
				coroutine.wrap(function()
					lib:tween(part, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = lib.flags["hit_chams"]["transparency"]})
					task.wait(1.15)
					lib:tween(part, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1})
					task.wait(0.7)
					if char_clone and char_clone.Parent then
						char_clone:Destroy()
					end
				end)()
			end
		end
	end
end)

local on_fogend_change = connection.new(game.Lighting:GetPropertyChangedSignal("FogEnd"), function()
	if game.Lighting.FogEnd ~= lib.flags["fogend"]["value"] then
		corsa.old.fogend = game.Lighting.FogEnd
	end
	if lib.flags["fog"]["toggle"] then
		game.Lighting.FogEnd = lib.flags["fogend"]["value"]
	end
end)

local on_client_added = connection.new(client.plr.CharacterAdded, function(character)
	if lib.flags["autoclaim"]["toggle"] then
		for i = 1, 10 do
			services.ReplicatedStorage.Remotes.CompRemotes.RequestTier:FireServer(i)
		end
    end
	if lib.flags["autoghost"]["toggle"] and not corsa.info.stop_ghost then
		corsa.info.stop_ghost = true
		services.ReplicatedStorage.Remotes.RequestGhostSpawn:InvokeServer()
		coroutine.wrap(function()
            task.wait(5)
            if not workspace:FindFirstChild("GameMap") and client:is_character_loaded() then
                client:get_character():BreakJoints()
            end
        end)()
	end
end)

services.ReplicatedStorage.Remotes.ShowMR.OnClientEvent:connect(function(p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29)
	local level = p25
	local prestige = p26

	corsa.info.level = p25
	corsa.info.prestige = p26
end);

local on_afk = connection.new(client.plr.PlayerGui.ScreenGui.UI.textD:GetPropertyChangedSignal("Text"), function()
    if string.lower(client.plr.PlayerGui.ScreenGui.UI.textD.Text) == "player needed" or string.lower(client.plr.PlayerGui.ScreenGui.UI.textD.Text) == "players needed" then
        if lib.flags["serverhop"]["toggle"] and quik.find(lib.flags["serverhop"]["selected"], "all afk") then
            task.spawn(function()
                while task.wait(5) do
                    corsa:serverhop()
                end
            end)
        end
    end
end)

LPH_JIT_MAX(function()
	task.spawn(function()
	    while true do
			task.wait(1)
			corsa.info.time_played = corsa.info.time_played + 1
			sessionTimeValue.Text = string.format("%02i:%02i:%02i", corsa.info.time_played/60^2, corsa.info.time_played/60%60, corsa.info.time_played%60)
			coroutine.wrap(function()
				local tokens = services.ReplicatedStorage.Remotes.GetTokenAmount:InvokeServer()
				if lib.flags["autocase"]["toggle"] and #lib.flags["autocase"]["selected"] == 1 then
					if tokens > tonumber(corsa.cases[lib.flags["autocase"]["selected"][1]]["cost"]) then
						services.ReplicatedStorage.Remotes.RequestItemPurchase:InvokeServer("Knife", "Case", lib.flags["autocase"]["selected"][1])
					end
				end
			end)()
			if lib.flags["alerts"]["toggle"] and not corsa.info.update_cooldown and corsa.info.level and corsa.info.prestige then
				coroutine.wrap(function()
					local data = {
						["content"]= "",
						["embeds"]= {{
							["title"]= "corsa.lua | stats update",
							["type"] = "rich",
							["color"] = 1127128,
							["fields"] = {
							  {
								["name"]= "coins",
								["value"] = tostring(services.ReplicatedStorage.Remotes.GetTokenAmount:InvokeServer()),
								["inline"] = true
							  },
							  {
								["name"]= "level",
								["value"]= tostring(corsa.info.level),
								["inline"] = true
							  },
							  {
								["name"] = "prestige",
								["value"]= tostring(corsa.info.prestige),
								["inline"] = true
							  }
							}
						}}
					}
					  
					local response = syn.request({
						Url = lib.flags["url"]["text"],
						Method = "POST",
						Headers = {
							["Content-Type"] = "application/json"
						},
						Body = game:GetService("HttpService"):JSONEncode(data)
					})
					corsa.info.update_cooldown = true
					task.wait(lib.flags["alerts"]["value"]*60)
					corsa.info.update_cooldown = false
				end)()
			end
		end
	end)
end)()

LPH_JIT_MAX(function()
	task.spawn(function()
	    while true do
			task.wait(0.01)
			for _, player in next, services.Players:GetPlayers() do
				local surge = corsa.players[player.Name]
				if surge then
					local character = surge.instance.Character
					if character and surge:is_loaded() then
						local hrp = character.HumanoidRootPart
						local valid_bt = false
						corsa.locations[player.Name][#corsa.locations[player.Name]+1] = character.HumanoidRootPart.CFrame
						valid_bt = true
						local expander = lib.flags["expander"]["toggle"]
						if expander and lib.flags["expandervisible"]["toggle"] and client:is_character_loaded() then
							expander = corsa:is_visible(client:get_character().Head.Position, character.Head.Position, character)
						end
						hrp.Size = expander and Vector3.new(lib.flags["sizex"]["value"], lib.flags["sizey"]["value"], lib.flags["sizez"]["value"]) or Vector3.new(2,2,1)
						hrp.CanCollide = false
						hrp.Color = lib.flags["expander"]["color"]
						hrp.Material = expander and (lib.flags["expander"]["selected"][1] == "forcefield" and Enum.Material.ForceField or Enum.Material.Neon) or Enum.Material.Plastic
						hrp.Transparency = expander and lib.flags["expander"]["transparency"] or 1
						local bt_tick = lib.flags["jitter"]["toggle"] and lib.flags["backtrack"]["value"] or lib.flags["backtrack"]["value"] + math.random(4,9)
						if lib.flags["backtrack"]["toggle"] and valid_bt and #corsa.locations[player.Name] > bt_tick then
							surge.backtrack.Parent = workspace
							surge.backtrack:SetPrimaryPartCFrame(corsa.locations[player.Name][#corsa.locations[player.Name] - bt_tick])
							local parts = surge.backtrack:GetChildren()
							for i = 1, #parts do
								local part = parts[i]
								if part.ClassName == "Part" then
									part.Material = lib.flags["model"]["selected"][1] == "forcefield" and Enum.Material.ForceField or Enum.Material.Neon
									part.Color = lib.flags["model"]["color"]
									part.Transparency = lib.flags["model"]["transparency"]
								end
							end
						else
							surge.backtrack.Parent = game.CoreGui
						end
					else
						surge.backtrack.Parent = game.CoreGui
					end
				end
			end
		end
	end)
end)()

-- ! special cases

local old = getrenv().tick
local fake_tick = false

local on_faketick = connection.new(services.UserInputService.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        fake_tick = true
    end
end)

getrenv().tick = newcclosure(function(...)
    local s = getcallingscript()
    if not checkcaller() and s and tostring(s) == "knifeScript" and lib.flags["fastthrow"]["toggle"] then
        if not fake_tick then
            return old() + (35*(lib.flags["fastthrow"]["value"])/100)/100
        else
            fake_tick = false
        end
    end
    return old(...)
end)

local trade = client.plr.PlayerGui.ScreenGui.UI.TradeScreen
local trade_review = trade.Frame.TradeReview
local trade_requests = client.plr.PlayerGui.ScreenGui.UI.TradeRequests

local new_trade = connection.new(trade_requests.ChildAdded, function(c)
	if lib.flags["autotrade"]["toggle"] then
		local plr = services.Players:FindFirstChild(tostring(c))
		services.ReplicatedStorage.Remotes.StartTrade:FireServer(plr)

		task.spawn(function()
			repeat task.wait() until trade.Visible

			while trade.Visible do 
				task.wait(1)
				if trade_review.Visible then
					services.ReplicatedStorage.Remotes.UpdTradeReview:FireServer(true)
				else
					services.ReplicatedStorage.Remotes.UpdTradeStatus:FireServer(true)
				end
			end
		end)
	end
end)

-- ! final loops

local on_heartbeat = connection.new(services.RunService.Heartbeat, LPH_JIT_MAX(function()
	local aim_location = nil
	corsa.info.target = services.Players:FindFirstChild(client.plr.PlayerGui.ScreenGui.UI.Target.TargetText.Text)
	local character = client:get_character()
	client.highlight.Enabled = lib.flags["shighlight"]["toggle"]
	if lib.flags["shighlight"]["toggle"] then
		client.highlight.FillColor = lib.flags["shighlight"]["color"]
		client.highlight.FillTransparency = lib.flags["shighlight"]["transparency"]
		client.highlight.OutlineColor = lib.flags["soutline"]["color"]
		client.highlight.OutlineTransparency = lib.flags["soutline"]["transparency"]
		client.highlight.Adornee = character
	end
	if lib.flags["stats"]["toggle"] then
		sessionLine.BackgroundColor3 = lib.flags["stats"]["color"]
		sessionKillsValue.TextColor3 = lib.flags["stats"]["color"]
		sessionTimeValue.TextColor3 = lib.flags["stats"]["color"]
	end
	win.hotkey = lib.flags["togglekey"]["key"]
	if lib.flags["chat_spam"]["toggle"] and not corsa.info.chat_cooldown then
		coroutine.wrap(function()
			corsa.info.chat_cooldown = true
			services.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(lib.flags["chat_spam"]["text"],"All")
			corsa.assassin.chat(lib.flags["chat_spam"]["text"])
			task.wait(lib.flags["spam_delay"]["value"])
			corsa.info.chat_cooldown = false
		end)()
	end
	if character and client:is_character_loaded() then
		local bp_tool = client.plr.Backpack:FindFirstChildOfClass("Tool")
		local c_tool = character:FindFirstChildOfClass("Tool")
		local in_game = corsa:is_in_game()
		character.Humanoid.AutoRotate = lib.flags["autorotate"]["toggle"]
		if not bp_tool and not c_tool then
			client.no_knife = true
		end
		if lib.flags["autoghost"]["toggle"] then
            for _, coin in pairs(workspace.GhostCoins:GetDescendants()) do
				if coin.ClassName == "TouchTransmitter" then
					firetouchinterest(character.HumanoidRootPart, coin.Parent, 0)
				end
            end
        end
		if lib.flags["autoequip"]["toggle"] and client.no_knife and client.plr.Backpack:FindFirstChildOfClass("Tool") then
			client.no_knife = false
			coroutine.wrap(function()
				task.wait(lib.flags["autoequip"]["value"]/1000)
				if bp_tool.Parent == client.plr.Backpack then
					character.Humanoid:EquipTool(bp_tool)
				end
			end)()
		end
		if lib.flags["spinbot"]["toggle"] then
			character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(lib.flags["spinbot"]["value"]), 0)
		end
		if lib.flags["quickstop"]["toggle"] and character.Humanoid.MoveDirection == Vector3.new(0,0,0) then
			character.HumanoidRootPart.Velocity = Vector3.new(0,character.HumanoidRootPart.Velocity.Y,0)
		end
		if lib.flags["autojump"]["toggle"] and character.Humanoid.MoveDirection ~= Vector3.new(0,0,0) and character.Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and character.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
			character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
		if lib.flags["speed"]["toggle"] and speed.get_active() and character.Humanoid.MoveDirection ~= Vector3.new() then
			character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame + (character.Humanoid.MoveDirection / 50) * lib.flags["speed"]["value"]/25
		end
		if lib.flags["autokill"]["toggle"] then
			local checklist = ((bp_tool or c_tool) or in_game)
			if lib.flags["removehitboxes"]["toggle"] and checklist then
				for _, part in pairs(client:get_character():GetChildren()) do
					if quik.find(lib.flags["removehitboxes"]["selected"], "limbs") then
						if string.find(part.Name, "Leg") or string.find(part.Name, "Arm") then
							part:Destroy()
						end
					end
				end
			end
			if workspace:FindFirstChild("GameMap") and in_game then
				local killers = workspace.GameMap:FindFirstChild("Killers")
				local bac_ = workspace.GameMap:FindFirstChild("BAC_")
				if killers then
					killers:Destroy()
				end
				if bac_ then
					bac_:Destroy()
				end
			end
			if checklist then
				for i,v in pairs(client:get_character():GetChildren()) do
					if string.find(v.ClassName, "Part") then
						v.Velocity = Vector3.new(0,2.1,0)
					end
				end
				local target = corsa.info.target
				local surge = corsa.players[tostring(target)]
				if surge then
					local character = surge.instance.Character
					if character and surge:is_loaded() then
						lib:tween(client:get_character().HumanoidRootPart, TweenInfo.new(0+((1-lib.flags["autokill"]["value"])/50), Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {CFrame = (character.HumanoidRootPart.CFrame - Vector3.new(0, lib.flags["under"]["value"]/1.5, 0)) - (character.HumanoidRootPart.CFrame.lookVector * lib.flags["behind"]["value"]/1.5)})
					end
				end
			end
		end
		if (lib.flags["stabaura"]["toggle"] and c_tool) or (lib.flags["autokill"]["toggle"] and in_game) then
			if not corsa.info.stab_cooldown and not corsa.info.kill_cooldown then
				for i, player in next, services.Players:GetPlayers() do
					local surge = corsa.players[player.Name]
					if not surge then continue end
					if surge:is_loaded() then
						local hrp = player.Character.HumanoidRootPart
						if (character.HumanoidRootPart.Position-hrp.Position).magnitude < 6.1 then
							corsa.assassin.hit_player("kill", player, newproxy(), nil, "stab")
							coroutine.wrap(function()
								corsa.info.stab_cooldown = true
								task.wait(0.74)
								corsa.info.stab_cooldown = false
							end)()
						end
					end
				end
			end
		end
		if corsa.info.retreating and lib.flags["autopeek"]["toggle"] and autopeek:get_active() then
			local location = corsa.info.auto_peek_location
			if lib.flags["autopeek"]["selected"][1] == "move" then
				character.Humanoid:MoveTo(location)
			else
				character.HumanoidRootPart.CFrame = CFrame.new(location + Vector3.new(0,2.99,0))
			end
			if (character.HumanoidRootPart.Position-location).magnitude < 3.1 then
				corsa.info.retreating = false
			end
		else
			corsa.info.retreating = false
		end
		if aim_helper:get_active() and lib.flags["aim_helper"]["toggle"] then
			local closest = corsa:get_closest_to_cursor()
			if closest then
				local surge = corsa.players[closest.Name]
				if surge then
					local character = surge.instance.Character
					if character and surge:is_loaded() then
						local hrp = character.HumanoidRootPart
						local visible = corsa:is_visible(client:get_character().Head.Position, character.Head.Position, character)

						if visible then
							local predicted_position = corsa:predict_player(hrp)
							visible = corsa:is_visible(client:get_character().Head.Position, predicted_position, character)
							
							if visible then
								if lib.flags["silent_aim"]["toggle"] then 
									aim_location = predicted_position
								else
									local pos, visible = workspace.CurrentCamera:WorldToScreenPoint(predicted_position)
									local pos2 = workspace.CurrentCamera:WorldToScreenPoint(client.mouse.Hit.p)
									if visible then
										local new_posx = pos.X - pos2.X
										local new_posy = pos.Y - pos2.Y
										local dividend = lib.flags["horizontal_smoothness"]["value"]
										local dividend2 = lib.flags["vertical_smoothness"]["value"]
										if lib.flags["randomness"]["toggle"] then
											dividend = dividend + math.random(1,lib.flags["randomness"]["value"]/10)
											dividend2 = dividend2 + math.random(1,lib.flags["randomness"]["value"]/10+1)
										end
										if lib.flags["shake"]["toggle"] then
											new_posx = new_posx + math.random(1, 1 + lib.flags["shake"]["value"]/2)
											new_posy = new_posy + math.random(1, 1 + lib.flags["shake"]["value"]/2)
										end
										mousemoverel(new_posx / dividend, new_posy / dividend2)
									end
								end
							end
						end
					end
				end
			end
		else
			aim_location = nil
		end
		corsa.info.aim_location = aim_location
		if fakelag.get_active() and lib.flags["fakelag"]["toggle"] then
			corsa.assets.fake.Parent = workspace.KnifeHost
			for _, part in pairs(corsa.assets.fake:GetChildren()) do
				part.Transparency = lib.flags["fakelagmodel"]["transparency"]
				part.Color = lib.flags["fakelagmodel"]["color"]
			end
			if not corsa.info.lag_cooldown then
				for _, part in pairs(corsa.assets.fake:GetChildren()) do
					local found_part = character:FindFirstChild(part.Name)
					if found_part then
						part.CFrame = found_part.CFrame
						part.Material = lib.flags["fakelagmodel"]["selected"][1] == "forcefield" and Enum.Material.ForceField or Enum.Material.Neon
					end
				end
			end
			if not corsa.info.lag_cooldown then
				corsa.info.lagging = true
				corsa.info.lag_cooldown = true
				local cooldown = (lib.flags["fakelag"]["value"]/200) 
				local cooldown2 = (lib.flags["fakelag"]["value"]/400) * (math.random(100,115)/100)
				if lib.flags["breakpattern"]["toggle"] then
					cooldown = cooldown * (math.random(95,115)/100)
					cooldown = cooldown2 * (math.random(95,115)/100)
				end
				
				coroutine.wrap(function()
					task.wait(cooldown)
					corsa.info.lagging = false
					task.wait(cooldown2)
					corsa.info.lag_cooldown = false
				end)()
			end
		else
			corsa.assets.fake.Parent = game.CoreGui
			corsa.info.lagging = false
		end
		if corsa.info.lagging then
			if not corsa.info.no_lag then
				sethiddenproperty(character.HumanoidRootPart, "NetworkIsSleeping", true)
			end
		end
	end
end))

local on_stepped = connection.new(services.RunService.Stepped, LPH_JIT_MAX(function()
	if lib.flags["noclip"]["toggle"] and noclip.get_active() and client:is_character_loaded() then
		local all_parts = client:get_character():GetChildren()
		for i = 1, #all_parts do
			local part = all_parts[i]
			if part.ClassName == "Part" or part.ClassName == "MeshPart" then
				part.CanCollide = false
			end
		end
	end
	if lib.flags["backtrack"]["toggle"] then
		for _, player in next, services.Players:GetPlayers() do
			local surge = corsa.players[player.Name]
			if surge then
				local bt = surge.backtrack
				if bt then
					local parts = bt:GetChildren()
					for i = 1, #parts do
						local part = parts[i]
						if part.ClassName == "Part" then
							part.CanCollide = false
						end
					end
				end
			end
		end
	end
end))

-- ! autoload

LPH_NO_VIRTUALIZE(function()
	for i,v in pairs(getconnections(client.plr.Idled)) do
		v:Disable()
	end
end)()

if isfile("corsa/configs/"..getgenv().configuration.autoload..".cfg") then
	lib.loadConfig(getgenv().configuration.autoload)
	sessionBack.Position = UDim2.new(unpack(lib.flags["stats_location"]))
end
