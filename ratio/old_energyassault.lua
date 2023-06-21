local lib = {}
local services = setmetatable({}, { __index = function(self, key) return game:GetService(key) end })

-- * Luraph Functions

LPH_JIT = function(...) return ... end 
LPH_JIT_MAX = function(...) return ... end
LPH_JIT_ULTRA = function(...) return ... end
LPH_HOOK_FIX = function(...) return ... end

lib.options = {
	accent = Color3.fromRGB(151, 255, 168),
    toggle = Enum.KeyCode.LeftAlt,
    style = "Smooth",
    luraph = false,
}

if LPH_OBFUSCATED then
    lib.options.luraph = true
end

lib.current = {
    visible = true,
    playing = false,
    tab = nil
}

lib.flags = {
    
}

lib.busy = false

lib.elements = {
	accentDependent = {
		
	},
	textOverridable = {
		
	},
    ignoreTransparency = {

    },
    bringStroke = {

    },
    saveTransparency = {

    },
    main = nil
}

lib.util = {}
lib.util.securep = printconsole or function() end

lib.util.draggable = function(gui, gui2)
	local dragging
	local dragInput
	local dragStart
	local startPos

	local function update(input)
		local delta = input.Position - dragStart
		gui2.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	gui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch and not lib.busy then
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
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch and not lib.busy then
			dragInput = input
		end
	end)

	services.UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging and not lib.busy then
			update(input)
		end
	end)
end

lib.util.extra = function(instance, name)
    if name == "accent" then
        table.insert(lib.elements.accentDependent, instance)
    elseif name == "draggable" then
        lib.util.draggable(instance, instance)
    elseif name == "stroke" then
        lib.elements.bringStroke[instance.Name] = instance.TextStrokeTransparency
    elseif name == "transparency" then
        table.insert(lib.elements.ignoreTransparency, instance)
    elseif name == "main" then
        lib.elements.main = instance
    elseif name == "savetransparency" then
        lib.elements.saveTransparency[instance.Name] = instance.ClassName == "ImageLabel" and instance.ImageTransparency or instance.BackgroundTransparency
    end
end

lib.util.create = function(class, properties, extra)
    local instance = Instance.new(class)
    for i,p in pairs(properties) do
        local success, err = pcall(function()
            instance[i] = p
        end)
        if not success then
            lib.util.securep(tostring(err))
        end
    end
    if extra then
        for _, n in pairs(extra) do
            lib.util.extra(instance, n)
        end
    end
    if class == "ScreenGui" then
        instance.Parent = gethui and gethui() or game.CoreGui; if syn then syn.protect_gui(instance) end
    end
    return instance
end

lib.signal = loadstring(game:HttpGet("https://raw.githubusercontent.com/Quenty/NevermoreEngine/version2/Modules/Shared/Events/Signal.lua"))()
lib.onConfigLoaded = lib.signal.new("onConfigLoaded")
lib.onConfigSaved = lib.signal.new("onConfigSaved")
lib.closing = lib.signal.new("closing")
lib.opening = lib.signal.new("opening")

lib.util.tween = function(...) 
    services.TweenService:Create(...):Play()
end

lib.util.open = function()
    lib.elements.main.Parent.Enabled = true
    LPH_JIT_MAX(function()
        lib.util.tween(lib.elements.main, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
        for i,v in pairs(lib.elements.main:GetDescendants()) do
            if v:IsA("TextLabel") then
                lib.util.tween(v, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextStrokeTransparency = lib.elements.bringStroke[v.Name], TextTransparency = 0})
            elseif v:IsA("Frame") and not table.find(lib.elements.ignoreTransparency, v) then
                lib.util.tween(v, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
            elseif v:IsA("ImageLabel") then
                lib.util.tween(v, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageTransparency = lib.elements.saveTransparency[v.Name]})
            elseif v:IsA("TextBox") then
                lib.util.tween(v, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextStrokeTransparency = 0.5, TextTransparency = 0})
            end
        end
    end)()
    lib.current.playing, lib.current.visible = true, true
    task.wait(0.25)
    lib.current.playing = false
end

lib.util.close = function()
    lib.closing:Fire()
    LPH_JIT_MAX(function()
        lib.util.tween(lib.elements.main, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
        for i,v in pairs(lib.elements.main:GetDescendants()) do
            if v:IsA("TextLabel") then
                lib.util.tween(v, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextStrokeTransparency = 1, TextTransparency = 1})
            elseif v:IsA("Frame") and not table.find(lib.elements.ignoreTransparency, v) then
                lib.util.tween(v, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
            elseif v:IsA("ImageLabel") then
                lib.util.tween(v, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageTransparency = 1})
            elseif v:IsA("ScrollingFrame") and not table.find(lib.elements.ignoreTransparency, v) then
                lib.util.tween(v, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
            elseif v:IsA("TextBox") then
                lib.util.tween(v, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextStrokeTransparency = 1, TextTransparency = 1})
            end
        end
    end)()
    lib.current.playing, lib.current.visible = true, false
    task.wait(0.25)
    lib.current.playing = false
    lib.elements.main.Parent.Enabled = false
end

if not isfolder("Eunoia") then
    makefolder("Eunoia")
end

if not isfolder("Eunoia/Configs") then
    makefolder("Eunoia/Configs")
end

if not isfolder("Eunoia/Scripts") then
    makefolder("Eunoia/Scripts")
end

if not isfolder("Eunoia/Skins") then
    makefolder("Eunoia/Skins")
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
    local new_values = services.HttpService:JSONDecode(readfile("Eunoia/Configs/"..cfgName..".cfg"))
    if old2 then
        services.HttpService:JSONDecode(_G.autoload)
    end

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
end

lib.saveConfig = function(cfgName, old)
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
        writefile("Eunoia/Configs/"..cfgName..".cfg", services.HttpService:JSONEncode(values_copy))
    else
        return services.HttpService:JSONEncode(values_copy)
    end
end

lib.menu = function(name, build)
	local UI = lib.util.create("ScreenGui", {
        Name = services.HttpService:GenerateGUID(false),
        Parent = game.CoreGui
    })
    lib.main = UI
	local Border = lib.util.create("Frame", {
        Name = "Border",
        Parent = UI,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.3, 0),
        Size = UDim2.new(0, 560, 0, 360)
    }, {"draggable", "main"})
	local Border2 = lib.util.create("Frame", {
        Name = "Border2",
        Parent = Border,
        BackgroundColor3 = Color3.fromRGB(39, 39, 39),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2)
    })
	local Inside = lib.util.create("Frame", {
        Name = "Inside",
        Parent = Border2,
        BackgroundColor3 = Color3.fromRGB(13, 13, 13),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2)
    })
	local BottomLine = lib.util.create("Frame", {
        Name = "BottomLine",
        Parent = Inside,
        BackgroundColor3 = Color3.fromRGB(39, 39, 39),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -25),
        Size = UDim2.new(1, 0, 0, 1)
    })
	local BottomLine_Text = lib.util.create("TextLabel", {
        Name = "BottomLine_Text",
        Parent = BottomLine,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1.000,
        Position = UDim2.new(0, 6, 0, 1),
        Size = UDim2.new(0, 200, 0, 25),
        Font = Enum.Font.SourceSansLight,
        Text = build,
        TextColor3 = Color3.fromRGB(129, 129, 129),
        TextSize = 14.000,
        TextStrokeTransparency = 0.200,
        TextXAlignment = Enum.TextXAlignment.Left
    }, {"accent", "stroke"})
	local BottomLine_Text2 = lib.util.create("TextLabel", {
        Name = "BottomLine_Text2",
        Parent = BottomLine,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1.000,
        Position = UDim2.new(1, -206, 0, 1),
        Size = UDim2.new(0, 200, 0, 25),
        Font = Enum.Font.SourceSansLight,
        Text = name,
        TextColor3 = Color3.fromRGB(171, 255, 147),
        TextSize = 14.000,
        TextStrokeTransparency = 0.200,
        TextXAlignment = Enum.TextXAlignment.Right
    }, {"accent", "stroke"})
	local Main = lib.util.create("Frame", {
        Name = "Main",
        Parent = Inside,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1.000,
        Position = UDim2.new(0, 15, 0, 15),
        Size = UDim2.new(1, -30, 1, -55)
    }, {"transparency"})
	local MainTabs = lib.util.create("Frame", {
        Name = "MainTabs",
        Parent = Main,
        BackgroundColor3 = Color3.fromRGB(15, 15, 15),
        BorderColor3 = Color3.fromRGB(39, 39, 39),
        Size = UDim2.new(0, 80, 1, 0)
    })
	local MainTabsLayout = lib.util.create("UIListLayout", {
        Parent = MainTabs,
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    local UICorner1 = lib.util.create("UICorner", {
        Parent = Border,
        CornerRadius = UDim.new(0, 8)
    })
    local UICorner2 = lib.util.create("UICorner", {
        Parent = Border2,
        CornerRadius = UDim.new(0, 8)
    })
    local UICorner3 = lib.util.create("UICorner", {
        Parent = Inside,
        CornerRadius = UDim.new(0, 8)
    })

    services.UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == lib.options.toggle and not lib.current.playing then
            if not lib.current.visible then
                lib.util.open()
            elseif lib.current.visible then
                lib.util.close()
            end
        end
    end)

    local tabs = {}

    tabs.current = {
        amount = 0
    }

    tabs.changeAccent = function(color)
        local oldclr = lib.options.accent
        for i,v in pairs(lib.elements.accentDependent) do
            if v:IsA("ImageLabel") then
                v.ImageColor3 = color
            elseif v:IsA("Frame") and v.BackgroundColor3 == oldclr then
                v.BackgroundColor3 = color
            elseif v:IsA("TextLabel") and v.BackgroundTransparency == 1 and v.TextColor3 == oldclr then
                v.TextColor3 = color
            elseif v:IsA("TextLabel") and v.BackgroundTransparency ~= 1 and v.BackgroundColor3 == oldclr then
                v.BackgroundColor3 = color
            end
        end
        lib.options.accent = color
    end

    tabs.changeTab = function(name)
        for i,v in pairs(tabs) do
            if i ~= nil and tostring(i) ~= "current" and i ~= name and type(v) == "table" then
                lib.util.tween(v.overlay, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 1})
                lib.util.tween(v.label, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(95, 95, 95)})
                v.subtab.Visible = false
                lib.elements.saveTransparency[i.."Overlay"] = 1
            elseif i == name then
                lib.util.tween(v.overlay, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0.5})
                lib.util.tween(v.label, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(205, 205, 205)})
                v.subtab.Visible = true
                lib.elements.saveTransparency[name.."Overlay"] = 0.5
            end
        end
        lib.current.tab = tabs[name]
    end

    tabs.tab = function(name)
        local subtabs = {}

        tabs[name] = {}
        tabs[name].name = name

        tabs.current.amount = tabs.current.amount + 1;
        if tabs.current.amount == 1 then
            lib.current.tab = tabs[name]
        end

        local TabButton = lib.util.create("Frame", {
            Name = name.."Button",
            Parent = MainTabs,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1.000,
            Size = UDim2.new(1, 0, 0, 20)
        }, {"transparency"}); tabs[name].button = TabButton
        local TabLabel = lib.util.create("TextLabel", {
            Name = name.."Label",
            Parent = TabButton,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1.000,
            LayoutOrder = 1,
            Position = UDim2.new(0.5, -32, 0, 0),
            Size = UDim2.new(0.800000012, 0, 1, 0),
            Font = Enum.Font.SourceSans,
            TextColor3 = tabs.current.amount == 1 and Color3.fromRGB(205, 205, 205) or Color3.fromRGB(95, 95, 95),
            TextSize = 16.000,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextStrokeTransparency = 0,
            Text = name
        }, {"stroke"}); tabs[name].label = TabLabel
        local TabOverlay = lib.util.create("ImageLabel", {
            Name = name.."Overlay",
            Parent = TabButton,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1.000,
            BorderColor3 = Color3.fromRGB(27, 42, 53),
            BorderSizePixel = 0,
            Rotation = 180.000,
            Size = UDim2.new(1, 0, 1, 0),
            Image = "rbxassetid://7331239122",
            ImageColor3 = Color3.fromRGB(151, 255, 168),
            ImageTransparency = tabs.current.amount == 1 and 0.500 or 1
        }, {"savetransparency", "accent"}); tabs[name].overlay = TabOverlay

        TabButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and lib.current.tab.name ~= name and not lib.busy then
                tabs.changeTab(name)
            end
        end)

        TabButton.MouseEnter:Connect(function()
            if lib.current.tab.name ~= name and not lib.busy then
                lib.util.tween(TabOverlay, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0.8})
                lib.util.tween(TabLabel, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(145, 145, 145)})
            end
        end)

        TabButton.MouseLeave:Connect(function()
            if lib.current.tab.name ~= name and not lib.busy then
                lib.util.tween(TabOverlay, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 1})
                lib.util.tween(TabLabel, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(95, 95, 95)})
            end
        end)

        local SubTabs = lib.util.create("Frame", {
            Name = name.."SubTabs",
            Parent = Main,
            BackgroundColor3 = Color3.fromRGB(13, 13, 13),
            BorderColor3 = Color3.fromRGB(39, 39, 39),
            Position = UDim2.new(0, 95, 0, 0),
            Size = UDim2.new(0, 431, 1, 0),
            Visible = tabs.current.amount == 1 and true or false
        }); tabs[name].subtab = SubTabs
        local SubHolder = lib.util.create("Frame", {
            Name = name.."SubHolder",
            Parent = SubTabs,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1.000,
            Size = UDim2.new(1, 0, 0, 26)
        }, {"transparency"})
        local UIListLayout = lib.util.create("UIListLayout", {
            Parent = SubHolder,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 5)
        })
        local Divider = lib.util.create("Frame", {
            Name = name.."Divider",
            Parent = SubTabs,
            BackgroundColor3 = Color3.fromRGB(39, 39, 39),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 26),
            Size = UDim2.new(1, 0, 0, 1)
        })

        local name2 = name

        subtabs.current = {
            amount = 0,
            name = nil
        }

        subtabs.changeTab = function(name)
            for i,v in pairs(subtabs) do
                if i ~= nil and tostring(i) ~= "current" and i ~= name and type(v) == "table" then
                    v.gradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(99, 99, 99)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(33, 33, 33))}
                    v.label.TextColor3 = Color3.fromRGB(135,135,135)
                    v.main.Visible = false
                elseif i == name then
                    v.gradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(172, 172, 172)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(77, 77, 77))}
                    v.label.TextColor3 = Color3.fromRGB(235,235,235)
                    v.main.Visible = true
                end
            end
            subtabs.current.tab = subtabs[name]
        end

        subtabs.subtab = function(name)
            local sections = {}

            subtabs.current.amount = subtabs.current.amount + 1
            subtabs[name] = {}
            subtabs[name].name = name
            tabs[name2].active = subtabs[name]

            if subtabs.current.amount == 1 then
                subtabs.current.tab = subtabs[name]
            end

            local ExampleSubTab = lib.util.create("Frame", {
                Name = name.."SubTab",
                Parent = SubHolder,
                BackgroundColor3 = Color3.fromRGB(151, 255, 168),
                BorderSizePixel = 0,
                Size = UDim2.new(0, 80, 0, 20)
            }, {"accent"}); subtabs[name].button = ExampleSubTab
            local SubTabLabel = lib.util.create("TextLabel", {
                Name = name.."SubTabLabel",
                Parent = ExampleSubTab,
                BackgroundColor3 = Color3.fromRGB(151, 255, 168),
                BackgroundTransparency = 1.000,
                LayoutOrder = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.SourceSans,
                Text = name,
                TextColor3 = subtabs.current.amount == 1 and Color3.fromRGB(235, 235, 235) or Color3.fromRGB(135,135,135),
                TextSize = 16.000,
                TextStrokeTransparency = 0.400
            }, {"stroke"}); subtabs[name].label = SubTabLabel
            local SubTabGradient = lib.util.create("UIGradient", {
                Color = subtabs.current.amount == 1 and ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(172, 172, 172)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(77, 77, 77))} or ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(99, 99, 99)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(33, 33, 33))},
                Rotation = 90,
                Name = name.."SubTabGradient",
                Parent = ExampleSubTab
            }); subtabs[name].gradient = SubTabGradient
            local SubTabExample = lib.util.create("Frame", {
                Name = name.."SubTabExample",
                Parent = SubTabs,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1.000,
                Position = UDim2.new(0, 10, 0, 36),
                Size = UDim2.new(1, -20, 1, -51),
                Visible = subtabs.current.amount == 1 and true or false,
            }, {"transparency"}); subtabs[name].main = SubTabExample

            local UIListLayout = lib.util.create("UIListLayout", {
                Parent = SubTabExample,
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 13)
            })

            ExampleSubTab.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and subtabs.current.tab ~= subtabs[name] and not lib.busy then
                    subtabs.changeTab(name)
                end
            end)

            sections.current = {
                amount = 0
            }

            sections.section = function(name)
                sections.current.amount = sections.current.amount + 1

                local SectionExample = lib.util.create("Frame", {
                    Name = name.."SectionExample",
                    Parent = SubTabExample,
                    BackgroundColor3 = Color3.fromRGB(13, 13, 13),
                    BorderColor3 = Color3.fromRGB(25, 25, 25),
                    Size = UDim2.new(0, 191, 1, 0),
                });

                local SectionLabelHolder = lib.util.create("Frame", {
                    Name = name.."SectionLabelHolder",
                    Parent = SectionExample,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = 1.000,
                    Size = UDim2.new(1, 0, 0, 20)
                }, {"transparency"});
                
                local SectionDivider = lib.util.create("Frame", {
                    Name = name.."SectionDivider",
                    Parent = SectionLabelHolder,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 1, 0),
                    Size = UDim2.new(1, 0, 0, 2)
                });
                
                local UIGradient = lib.util.create("UIGradient", {
                    Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(23, 23, 23)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(13, 13, 13))},
                    Parent = SectionDivider
                });

                local SectionLabel = lib.util.create("TextLabel", {
                    Name = name.."SectionLabel",
                    Parent = SectionLabelHolder,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = 1.000,
                    Position = UDim2.new(0.03, 0, 0, 0),
                    Size = UDim2.new(0.97, 0, 1, 0),
                    Font = Enum.Font.SourceSans,
                    Text = name,
                    TextColor3 = Color3.fromRGB(153, 153, 153),
                    TextSize = 16.000,
                    TextStrokeTransparency = 0.500,
                    TextXAlignment = Enum.TextXAlignment.Left
                });

                local SectionHolder = lib.util.create("ScrollingFrame", {
                    Name = "SectionHolder",
                    Parent = SectionExample,
                    Active = true,
                    BackgroundColor3 = Color3.fromRGB(13, 13, 13),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 10, 0, 30),
                    Size = UDim2.new(1, -20, 1, -40),
                    BottomImage = "",
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    MidImage = "",
                    ScrollBarThickness = 0,
                    ScrollingEnabled = false,
                    TopImage = ""
                });

                local UIListLayout = lib.util.create("UIListLayout", {
                    Parent = SectionHolder,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    Padding = UDim.new(0, 5)
                });

                local elements = {}
                local totalSize = 0

                elements.element = function(args)
                    local name = args["name"]
                    local dependencies = args["dependencies"] or nil
                    local callback = args["callback"] or function() end
                    local etype = args["type"]
                    local flag = args["flag"]
                    local popup = args["popup"]
                    local element = {}

                    element.current = {}
                    element.main = nil

                    if etype == "toggle" then
                        local default = args["default"]

                        totalSize = totalSize + 19

                        local ExampleToggle = lib.util.create("Frame", {
                            Name = name.."ExampleToggle",
                            Parent = SectionHolder,
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            BackgroundTransparency = 1.000,
                            Size = UDim2.new(1, -2, 0, 14)
                        }, {"transparency"}); element.main = ExampleToggle
                        local ToggleVisualButton = lib.util.create("Frame", {
                            Name = name.."ToggleVisualButton",
                            Parent = ExampleToggle,
                            BackgroundColor3 = Color3.fromRGB(22, 22, 22),
                            BorderColor3 = Color3.fromRGB(35, 35, 35),
                            Position = UDim2.new(0, 0, 0, 1),
                            Size = UDim2.new(0, 12, 1, -2)
                        }, {"accent"});
                        local VisualButtonGradient = lib.util.create("UIGradient", {
                        Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(199, 199, 199)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(135, 135, 135))},
                            Rotation = 90,
                            Name = name.."VisualButtonGradient",
                            Parent = ToggleVisualButton
                        });
                        local ToggleLabel = lib.util.create("TextLabel", {
                            Name = name.."ToggleLabel",
                            Parent = ExampleToggle,
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            BackgroundTransparency = 1.000,
                            Position = UDim2.new(0, 17, 0, 0),
                            Size = UDim2.new(0, 85, 1, 0),
                            Font = Enum.Font.SourceSans,
                            Text = name,
                            TextColor3 = Color3.fromRGB(135, 135, 135),
                            TextSize = 15.000,
                            TextStrokeTransparency = 0.500,
                            TextXAlignment = Enum.TextXAlignment.Left
                        }, {"transparency", "stroke"});
                        local ToggleAddons = lib.util.create("Frame", {
                            Name = name.."ToggleAddons",
                            Parent = ExampleToggle,
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            BackgroundTransparency = 1.000,
                            Position = UDim2.new(1, -65, 0, 0),
                            Size = UDim2.new(0, 65, 1, 0)
                        }, {"transparency"});
                        local UIListLayout = lib.util.create("UIListLayout", {
                            Parent = ToggleAddons,
                            FillDirection = Enum.FillDirection.Horizontal,
                            HorizontalAlignment = Enum.HorizontalAlignment.Right,
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            VerticalAlignment = Enum.VerticalAlignment.Center,
                            Padding = UDim.new(0, 4)
                        });

                        element.set = function(value, c)
                            if value then
                                lib.util.tween(ToggleVisualButton, TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = lib.options.accent})
                            else
                                lib.util.tween(ToggleVisualButton, TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(25,25,25)})
                            end
                            lib.flags[flag] = value
                            if c then
                                local success, err = pcall(callback, lib.flags[flag])
                                if not success then
                                    lib.util.securep(tostring(err))
                                end
                            end
                        end

                        ToggleVisualButton.MouseEnter:Connect(function()
                            if not lib.busy then
                                lib.util.tween(ToggleLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(166, 166, 166)})
                            end
                        end)

                        ToggleVisualButton.MouseLeave:Connect(function()
                            lib.util.tween(ToggleLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(135, 135, 135)})
                        end)

                        ToggleLabel.MouseEnter:Connect(function()
                            if not lib.busy and ToggleVisualButton then
                                lib.util.tween(ToggleLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(166, 166, 166)})
                            end
                        end)

                        ToggleLabel.MouseLeave:Connect(function()
                            lib.util.tween(ToggleLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(135, 135, 135)})
                        end)

                        ToggleVisualButton.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 and not lib.busy and ToggleVisualButton then
                                element.set(not lib.flags[flag], true)
                            end
                        end)

                        ToggleLabel.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 and not lib.busy and ToggleVisualButton then
                                element.set(not lib.flags[flag], true)
                            end
                        end)

                        lib.onConfigLoaded:Connect(function()
                            element.set(lib.flags[flag], true)
                        end)

                        element.current.addonCount = 0

                        element.addon = function(args)
                            local aname = args["name"]
                            local adefault = args["default"]
                            local atype = args["type"]
                            local acallback = args["callback"]
                            local aremove = args["remove"]
                            local addon = {}
                            element.current.addonCount = element.current.addonCount + 1
                            local count = tostring(element.current.addonCount)

                            if aremove then
                                ToggleVisualButton:Destroy()
                            end

                            if atype == "colorpicker" then
                                local ColorPickerAddon = Instance.new("Frame")
                                local ColorPickerGradient = Instance.new("UIGradient")
                                lib.flags[count..flag] = {}
                                if not adefault then adefault = Color3.fromRGB(255,0,0) end

                                ColorPickerAddon.Name = aname.."ColorPickerAddon"
                                ColorPickerAddon.Parent = ToggleAddons
                                ColorPickerAddon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                ColorPickerAddon.BorderColor3 = Color3.fromRGB(25, 25, 25)
                                ColorPickerAddon.Size = UDim2.new(0, 20, 0, 10)

                                ColorPickerGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(141, 141, 141))}
                                ColorPickerGradient.Rotation = 90
                                ColorPickerGradient.Name = "ColorPickerGradient"
                                ColorPickerGradient.Parent = ColorPickerAddon

                                local Colorpicker = Instance.new("Frame")
                                local ColorpickerInside = Instance.new("Frame")
                                local ColorpickerLabel = Instance.new("TextLabel")
                                local colorPickerLabel = Instance.new("ImageLabel")
                                local colorPickerMover = Instance.new("Frame")
                                local huePickerSlider = Instance.new("Frame")
                                local UIGradient = Instance.new("UIGradient")
                                local huePickerMover = Instance.new("Frame")
                                local transparencyrSlider = Instance.new("Frame")
                                local transparencyMover = Instance.new("Frame")
                                local transparencyTexture = Instance.new("ImageLabel")
                                local UIGradient_2 = Instance.new("UIGradient")
                                local colorpickerlib = {}

                                Colorpicker.Name = "Colorpicker"
                                Colorpicker.Parent = UI
                                Colorpicker.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                                Colorpicker.BorderSizePixel = 0
                                Colorpicker.Position = UDim2.new(0.561270952, 0, 0.435947716, 0)
                                Colorpicker.Size = UDim2.new(0, 165, 0, 165)
                                Colorpicker.Visible = false
                                local UICorner = Instance.new("UICorner", Colorpicker); UICorner.CornerRadius = UDim.new(0, 8)

                                ColorpickerInside.Name = "ColorpickerInside"
                                ColorpickerInside.Parent = Colorpicker
                                ColorpickerInside.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
                                ColorpickerInside.BorderSizePixel = 0
                                ColorpickerInside.Position = UDim2.new(0, 1, 0, 1)
                                ColorpickerInside.Size = UDim2.new(1, -2, 1, -2)
                                local UICorner = Instance.new("UICorner", ColorpickerInside); UICorner.CornerRadius = UDim.new(0, 8)

                                ColorpickerLabel.Name = "ColorpickerLabel"
                                ColorpickerLabel.Parent = ColorpickerInside
                                ColorpickerLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                ColorpickerLabel.BackgroundTransparency = 1.000
                                ColorpickerLabel.Position = UDim2.new(0, 0, 0, 3)
                                ColorpickerLabel.Size = UDim2.new(1, 0, 0, 20)
                                ColorpickerLabel.Font = Enum.Font.SourceSansSemibold
                                ColorpickerLabel.Text = aname
                                ColorpickerLabel.TextColor3 = Color3.fromRGB(156, 156, 156)
                                ColorpickerLabel.TextSize = 16.000

                                colorPickerLabel.Name = "colorPickerLabel"
                                colorPickerLabel.Parent = ColorpickerInside
                                colorPickerLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                colorPickerLabel.BorderColor3 = Color3.fromRGB(35, 35, 35)
                                colorPickerLabel.Position = UDim2.new(0.5, -66, 0.5, -58)
                                colorPickerLabel.Size = UDim2.new(0, 116, 0, 116)
                                colorPickerLabel.Image = "rbxassetid://4155801252"

                                colorPickerMover.Name = "colorPickerMover"
                                colorPickerMover.Parent = colorPickerLabel
                                colorPickerMover.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                colorPickerMover.BorderSizePixel = 0

                                huePickerSlider.Name = "huePickerSlider"
                                huePickerSlider.Parent = ColorpickerInside
                                huePickerSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                huePickerSlider.BorderColor3 = Color3.fromRGB(35, 35, 35)
                                huePickerSlider.Position = UDim2.new(1, -26, 0, 23)
                                huePickerSlider.Size = UDim2.new(0, 11, 0, 116)

                                UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 0, 255)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 255, 0)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(170, 0, 0))}
                                UIGradient.Rotation = 90
                                UIGradient.Parent = huePickerSlider

                                huePickerMover.Name = "huePickerMover"
                                huePickerMover.Parent = huePickerSlider
                                huePickerMover.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                huePickerMover.BorderSizePixel = 0
                                huePickerMover.Size = UDim2.new(1, 0, 0, 0)

                                transparencyrSlider.Name = "transparencyrSlider"
                                transparencyrSlider.Parent = ColorpickerInside
                                transparencyrSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                transparencyrSlider.BackgroundTransparency = 1.000
                                transparencyrSlider.BorderColor3 = Color3.fromRGB(35, 35, 35)
                                transparencyrSlider.Position = UDim2.new(0, 15, 1, -19)
                                transparencyrSlider.Size = UDim2.new(0, 116, 0, 11)

                                transparencyMover.Name = "transparencyMover"
                                transparencyMover.Parent = transparencyrSlider
                                transparencyMover.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                transparencyMover.BorderSizePixel = 0
                                transparencyMover.Size = UDim2.new(0, 0, 1, 0)

                                transparencyTexture.Name = "transparencyTexture"
                                transparencyTexture.Parent = transparencyrSlider
                                transparencyTexture.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                transparencyTexture.BorderColor3 = Color3.fromRGB(35, 35, 35)
                                transparencyTexture.Size = UDim2.new(1, 0, 1, 0)
                                transparencyTexture.Image = "http://www.roblox.com/asset/?id=8657422630"

                                UIGradient_2.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))}
                                UIGradient_2.Parent = transparencyTexture

                                ColorPickerAddon.InputBegan:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseButton1 and not lib.busy then
                                        lib.busy = true
                                        Colorpicker.Position = UDim2.new(0, ColorPickerAddon.AbsolutePosition.X, 0, ColorPickerAddon.AbsolutePosition.Y + 10)
                                        LPH_JIT_MAX(function()
                                            lib.util.tween(Colorpicker, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
                                            for i,v in pairs(Colorpicker:GetDescendants()) do
                                                if v:IsA("Frame") then
                                                    lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
                                                elseif v:IsA("TextLabel") then
                                                    lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0})
                                                elseif v:IsA("ImageLabel") then
                                                    lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
                                                    lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageTransparency = 0})
                                                end
                                            end
                                        end)()
                                        Colorpicker.Visible = true
                                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 and lib.busy and Colorpicker.Visible then
                                        LPH_JIT_MAX(function()
                                            lib.util.tween(Colorpicker, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
                                            for i,v in pairs(Colorpicker:GetDescendants()) do
                                                if v:IsA("Frame") then
                                                    lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
                                                elseif v:IsA("TextLabel") then
                                                    lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 1})
                                                elseif v:IsA("ImageLabel") then
                                                    lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
                                                    lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageTransparency = 1})
                                                end
                                            end
                                        end)()
                                        task.wait(0.189)
                                        lib.busy = false
                                        Colorpicker.Visible = false
                                    end
                                end)

                                lib.closing:Connect(function()
                                    if Colorpicker.Visible and lib.busy then
                                        LPH_JIT_MAX(function()
                                            lib.util.tween(Colorpicker, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
                                            for i,v in pairs(Colorpicker:GetDescendants()) do
                                                if v:IsA("Frame") then
                                                    lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
                                                elseif v:IsA("TextLabel") then
                                                    lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 1})
                                                elseif v:IsA("ImageLabel") then
                                                    lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
                                                    lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageTransparency = 1})
                                                end
                                            end
                                        end)()
                                        task.wait(0.189)
                                        lib.busy = false
                                        Colorpicker.Visible = false
                                    end
                                end)
        
                                local in_color = false
                                local in_color2 = false
        
                                function colorpickerlib.update_transp()
                                    local x = math.clamp(services.Players.LocalPlayer:GetMouse().X - transparencyrSlider.AbsolutePosition.X, 0, 116)
                                    transparencyMover.Position = UDim2.new(0, x, 0, 0)
                                    local transparency = x/116
                                    lib.flags[count..flag].Transparency = transparency
        
                                    pcall(acallback, lib.flags[count..flag])
                                end
                                transparencyrSlider.InputBegan:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                        colorpickerlib.update_transp()
                                        local moveconnection = services.Players.LocalPlayer:GetMouse().Move:Connect(function()
                                            colorpickerlib.update_transp()
                                        end)
                                        releaseconnection = services.UserInputService.InputEnded:Connect(function(Mouse)
                                            if Mouse.UserInputType == Enum.UserInputType.MouseButton1 then
                                                colorpickerlib.update_transp()
                                                moveconnection:Disconnect()
                                                releaseconnection:Disconnect()
                                            end
                                        end)
                                    end
                                end)
        
                                colorpickerlib.h = (math.clamp(huePickerSlider.AbsolutePosition.Y-colorPickerMover.AbsolutePosition.Y, 0, colorPickerMover.AbsoluteSize.Y)/colorPickerMover.AbsoluteSize.Y)
                                colorpickerlib.s = 1-(math.clamp(huePickerMover.AbsolutePosition.X-huePickerMover.AbsolutePosition.X, 0, colorPickerMover.AbsoluteSize.X)/colorPickerMover.AbsoluteSize.X)
                                colorpickerlib.v = 1-(math.clamp(huePickerMover.AbsolutePosition.Y-huePickerMover.AbsolutePosition.Y, 0, colorPickerMover.AbsoluteSize.Y)/colorPickerMover.AbsoluteSize.Y)
        
                                lib.flags[count..flag].Color = Color3.fromHSV(colorpickerlib.h, colorpickerlib.s, colorpickerlib.v)
        
                                function colorpickerlib.update_color()
                                    local ColorX = (math.clamp(services.Players.LocalPlayer:GetMouse().X - colorPickerLabel.AbsolutePosition.X, 0, colorPickerLabel.AbsoluteSize.X)/colorPickerLabel.AbsoluteSize.X)
                                    local ColorY = (math.clamp(services.Players.LocalPlayer:GetMouse().Y - colorPickerLabel.AbsolutePosition.Y, 0, colorPickerLabel.AbsoluteSize.Y)/colorPickerLabel.AbsoluteSize.Y)
                                    huePickerMover.Position = UDim2.new(ColorX, 0, ColorY, 0)
        
                                    colorpickerlib.s = 1 - ColorX
                                    colorpickerlib.v = 1 - ColorY
        
                                    ColorPickerAddon.BackgroundColor3 = Color3.fromHSV(colorpickerlib.h, colorpickerlib.s, colorpickerlib.v)
                                    lib.flags[count..flag].Color = Color3.fromHSV(colorpickerlib.h, colorpickerlib.s, colorpickerlib.v)
                                    pcall(acallback, lib.flags[count..flag])
                                end
                                colorPickerLabel.InputBegan:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                        colorpickerlib.update_color()
                                        local moveconnection = services.Players.LocalPlayer:GetMouse().Move:Connect(function()
                                            colorpickerlib.update_color()
                                        end)
                                        releaseconnection = services.UserInputService.InputEnded:Connect(function(Mouse)
                                            if Mouse.UserInputType == Enum.UserInputType.MouseButton1 then
                                                colorpickerlib.update_color()
                                                moveconnection:Disconnect()
                                                releaseconnection:Disconnect()
                                            end
                                        end)
                                    end
                                end)
        
                                function colorpickerlib.update_hue()
                                    local y = math.clamp(services.Players.LocalPlayer:GetMouse().Y - huePickerSlider.AbsolutePosition.Y, 0, 123)
                                    colorPickerMover.Position = UDim2.new(0, 0, 0, y)
                                    local hue = y/123
                                    colorpickerlib.h = 1-hue
                                    colorPickerLabel.ImageColor3 = Color3.fromHSV(colorpickerlib.h, 1, 1)
                                    ColorPickerAddon.BackgroundColor3 = Color3.fromHSV(colorpickerlib.h, colorpickerlib.s, colorpickerlib.v)
                                    colorPickerLabel.ImageColor3 = Color3.fromHSV(colorpickerlib.h, 1, 1)
                                    lib.flags[count..flag].Color = Color3.fromHSV(colorpickerlib.h, colorpickerlib.s, colorpickerlib.v)
                                    pcall(acallback, lib.flags[count..flag])
                                end
                                huePickerSlider.InputBegan:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                        colorpickerlib.update_hue()
                                        local moveconnection = services.Players.LocalPlayer:GetMouse().Move:Connect(function()
                                            colorpickerlib.update_hue()
                                        end)
                                        releaseconnection = services.UserInputService.InputEnded:Connect(function(Mouse)
                                            if Mouse.UserInputType == Enum.UserInputType.MouseButton1 then
                                                colorpickerlib.update_hue()
                                                moveconnection:Disconnect()
                                                releaseconnection:Disconnect()
                                            end
                                        end)
                                    end
                                end)
        
                                addon.set = function(new_value)
                                    if typeof(new_value) == "Color3" then
                                        lib.flags[count..flag].Color = new_value
                                        lib.flags[count..flag].Transparency = 0
                                    else
                                        lib.flags[count..flag].Color = new_value.Color
                                        lib.flags[count..flag].Transparency = new_value.Transparency
                                    end
        
                                    local duplicate = Color3.new(lib.flags[count..flag].Color.R, lib.flags[count..flag].Color.G, lib.flags[count..flag].Color.B)
                                    colorpickerlib.h, colorpickerlib.s, colorpickerlib.v = duplicate:ToHSV()
                                    colorpickerlib.h = math.clamp(colorpickerlib.h, 0, 1)
                                    colorpickerlib.s = math.clamp(colorpickerlib.s, 0, 1)
                                    colorpickerlib.v = math.clamp(colorpickerlib.v, 0, 1)
        
                                    huePickerMover.Position = UDim2.new(1 - colorpickerlib.s, 0, 1 - colorpickerlib.v, 0)
                                    colorpickerlib.ImageColor3 = Color3.fromHSV(colorpickerlib.h, 1, 1)
                                    colorpickerlib.BackgroundColor3 = Color3.fromHSV(colorpickerlib.h, colorpickerlib.s, colorpickerlib.v)
                                    ColorPickerAddon.BackgroundColor3 = Color3.fromHSV(colorpickerlib.h, colorpickerlib.s, colorpickerlib.v)
                                    colorPickerMover.Position = UDim2.new(0, 0, 1 - colorpickerlib.h, -1)
                                    colorPickerLabel.ImageColor3 = Color3.fromHSV(colorpickerlib.h, 1, 1)
        
                                    colorPickerLabel.ImageColor3 = Color3.fromHSV(colorpickerlib.h, 1, 1)
        
                                    transparencyMover.Position = UDim2.new(lib.flags[count..flag].Transparency, -1, 0, 0)
        
                                    pcall(acallback, lib.flags[count..flag])
                                end

                                addon.set(adefault)

                                LPH_JIT_MAX(function()
                                    lib.util.tween(Colorpicker, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
                                    for i,v in pairs(Colorpicker:GetDescendants()) do
                                        if v:IsA("Frame") then
                                            lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
                                        elseif v:IsA("TextLabel") then
                                            lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 1})
                                        elseif v:IsA("ImageLabel") then
                                            lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
                                            lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageTransparency = 1})
                                        end
                                    end
                                end)()
        
                                lib.onConfigLoaded:Connect(function()
                                    addon.set(lib.flags[count..flag])
                                end)
                            elseif atype == "keybind" then
                                local adefault = adefault and adefault or ""
                                local akeycode = adefault
                                local binding = false
                                local choosing = false
                                lib.flags[count..flag] = {}
                                lib.flags[count..flag].key = nil
                                lib.flags[count..flag].method = "Hold"
                                lib.flags[count..flag].active = false
                                local KeybindLabel = lib.util.create("TextLabel", {
                                    Name = "KeybindLabel",
                                    Parent = ToggleAddons,
                                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                    BackgroundTransparency = 1.000,
                                    Position = UDim2.new(0, 17, 0, 0),
                                    Size = UDim2.new(0, 25, 0, 10),
                                    Font = Enum.Font.SourceSans,
                                    TextColor3 = Color3.fromRGB(85, 255, 127),
                                    TextSize = 14.000,
                                    TextStrokeTransparency = 0.500,
                                    TextYAlignment = Enum.TextYAlignment.Bottom,
                                }, {"transparency","stroke","accent"});

                                addon.set = function(keycode, num)
                                    if num == 1 then
                                        KeybindLabel.Text = "["..string.sub(keycode, 1, 3).."]"
                                        lib.flags[count..flag].key = keycode
                                        lib.util.tween(KeybindLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = lib.options.accent})
                                    elseif num == 2 then
                                        lib.flags[count..flag].method = keycode
                                        if keycode == "Always" then
                                            coroutine.wrap(function()
                                                task.wait(0.03)
                                                lib.flags[count..flag].active = true
                                            end)()
                                        end
                                    end
                                end

                                local KeybindMenu = Instance.new("Frame")
                                local KeybindMenuInside = Instance.new("Frame")
                                local KeybindAlwaysLabel = Instance.new("TextLabel")
                                local UIListLayout = Instance.new("UIListLayout")
                                local KeybindToggleLabel = Instance.new("TextLabel")
                                local KeybindHoldLabel = Instance.new("TextLabel")

                                KeybindMenu.Name = "KeybindMenu"
                                KeybindMenu.Parent = UI
                                KeybindMenu.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                                KeybindMenu.BorderSizePixel = 0
                                KeybindMenu.Position = UDim2.new(0, 471, 0, 485)
                                KeybindMenu.Size = UDim2.new(0, 70, 0, 46)
                                KeybindMenu.Visible = false
                                local UICorner = Instance.new("UICorner", KeybindMenu); UICorner.CornerRadius = UDim.new(0, 3)

                                KeybindMenuInside.Name = "KeybindMenuInside"
                                KeybindMenuInside.Parent = KeybindMenu
                                KeybindMenuInside.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
                                KeybindMenuInside.BorderSizePixel = 0
                                KeybindMenuInside.Position = UDim2.new(0, 1, 0, 1)
                                KeybindMenuInside.Size = UDim2.new(1, -2, 1, -2)
                                local UICorner = Instance.new("UICorner", KeybindMenuInside); UICorner.CornerRadius = UDim.new(0, 3)

                                KeybindAlwaysLabel.Name = "KeybindAlwaysLabel"
                                KeybindAlwaysLabel.Parent = KeybindMenuInside
                                KeybindAlwaysLabel.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
                                KeybindAlwaysLabel.BackgroundTransparency = 1.000
                                KeybindAlwaysLabel.Position = UDim2.new(0, 5, 0, 0)
                                KeybindAlwaysLabel.Size = UDim2.new(1, 0, 0, 14)
                                KeybindAlwaysLabel.Font = Enum.Font.SourceSans
                                KeybindAlwaysLabel.Text = "Always"
                                KeybindAlwaysLabel.TextColor3 = Color3.fromRGB(135, 135, 135)
                                KeybindAlwaysLabel.TextSize = 14.000
                                KeybindAlwaysLabel.TextStrokeTransparency = 0.500
                                KeybindAlwaysLabel.TextWrapped = true

                                UIListLayout.Parent = KeybindMenuInside
                                UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

                                KeybindToggleLabel.Name = "KeybindToggleLabel"
                                KeybindToggleLabel.Parent = KeybindMenuInside
                                KeybindToggleLabel.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
                                KeybindToggleLabel.BackgroundTransparency = 1.000
                                KeybindToggleLabel.Position = UDim2.new(0, 5, 0, 0)
                                KeybindToggleLabel.Size = UDim2.new(1, 0, 0, 14)
                                KeybindToggleLabel.Font = Enum.Font.SourceSans
                                KeybindToggleLabel.Text = "Toggle"
                                KeybindToggleLabel.TextColor3 = Color3.fromRGB(135, 135, 135)
                                KeybindToggleLabel.TextSize = 14.000
                                KeybindToggleLabel.TextStrokeTransparency = 0.500
                                KeybindToggleLabel.TextWrapped = true

                                KeybindHoldLabel.Name = "KeybindHoldLabel"
                                KeybindHoldLabel.Parent = KeybindMenuInside
                                KeybindHoldLabel.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
                                KeybindHoldLabel.BackgroundTransparency = 1.000
                                KeybindHoldLabel.Position = UDim2.new(0, 5, 0, 0)
                                KeybindHoldLabel.Size = UDim2.new(1, 0, 0, 14)
                                KeybindHoldLabel.Font = Enum.Font.SourceSans
                                KeybindHoldLabel.Text = "Hold"
                                KeybindHoldLabel.TextColor3 = Color3.fromRGB(135, 135, 135)
                                KeybindHoldLabel.TextSize = 14.000
                                KeybindHoldLabel.TextStrokeTransparency = 0.500
                                KeybindHoldLabel.TextWrapped = true
        
                                local UIGradient = Instance.new("UIGradient")
                                UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(173, 173, 173)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(88, 88, 88))}
                                UIGradient.Rotation = 90
                                UIGradient.Parent = KeybindLabel

                                KeybindAlwaysLabel.InputBegan:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                        KeybindMenu.Visible = not KeybindMenu.Visible
                                        lib.busy = false
                                        lib.flags[count..flag].method = "Always"
                                        coroutine.wrap(function()
                                            while lib.flags[count..flag].method == "Always" do
                                                lib.flags[count..flag].active = true
                                                task.wait()
                                            end
                                        end)()
                                    end
                                end)

                                KeybindToggleLabel.InputBegan:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                        KeybindMenu.Visible = not KeybindMenu.Visible
                                        lib.busy = false
                                        lib.flags[count..flag].method = "Toggle"
                                    end
                                end)

                                KeybindHoldLabel.InputBegan:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                        KeybindMenu.Visible = not KeybindMenu.Visible
                                        lib.busy = false
                                        lib.flags[count..flag].method = "Hold"
                                    end
                                end)

                                KeybindLabel.MouseEnter:Connect(function()
                                    if not lib.busy and not binding then
                                        lib.util.tween(KeybindLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(lib.options.accent.R * 185, lib.options.accent.G * 185, lib.options.accent.B * 185)})
                                    end
                                end)

                                KeybindLabel.MouseLeave:Connect(function()
                                    if not binding then
                                        lib.util.tween(KeybindLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = lib.options.accent})
                                    end
                                end)

                                KeybindLabel.InputBegan:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseButton1 and not binding and not lib.busy then
                                        binding = true; lib.busy = true
                                        KeybindLabel.Text = "[...]"
                                        lib.util.tween(KeybindLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(lib.options.accent.R * 55, lib.options.accent.G * 55, lib.options.accent.B * 55)})
                                    elseif input.UserInputType == Enum.UserInputType.MouseButton2 and not binding and not lib.busy then
                                        KeybindMenu.Visible = not KeybindMenu.Visible
                                        KeybindMenu.Position = UDim2.new(0, KeybindLabel.AbsolutePosition.X, 0, KeybindLabel.AbsolutePosition.Y + 15)
                                        lib.busy = KeybindMenu.Visible
                                    end
                                end)

                                services.UserInputService.InputBegan:Connect(function(input, gpe)
                                    if gpe then return end
                                    if binding then
                                        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= lib.options.toggle then
                                            addon.set(input.KeyCode.Name, 1)
                                            coroutine.wrap(function()
                                                task.wait(0.03)
                                                binding = false; lib.busy = false
                                            end)()
                                        elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == lib.options.toggle then
                                            addon.set(lib.flags[flag].key, 1)                                            
                                            coroutine.wrap(function()
                                                task.wait(0.03)
                                                binding = false; lib.busy = false
                                            end)()
                                        end
                                    elseif not binding then
                                        if input.UserInputType == Enum.UserInputType.Keyboard and lib.flags[count..flag].method == "Hold" and input.KeyCode.Name == lib.flags[count..flag].key then
                                            lib.flags[count..flag].active = true
                                        elseif input.UserInputType == Enum.UserInputType.Keyboard and lib.flags[count..flag].method == "Toggle" and input.KeyCode.Name == lib.flags[count..flag].key then
                                            lib.flags[count..flag].active = not lib.flags[count..flag].active
                                        end
                                    end
                                end)

                                services.UserInputService.InputEnded:Connect(function(input, gpe)
                                    if gpe then return end
                                    if not binding then
                                        if input.UserInputType == Enum.UserInputType.Keyboard and lib.flags[count..flag].method == "Hold" and input.KeyCode.Name == lib.flags[count..flag].key then
                                            lib.flags[count..flag].active = false
                                        end
                                    end
                                end)

                                lib.closing:Connect(function()
                                    if KeybindMenu.Visible then
                                        KeybindMenu.Visible = false
                                        lib.busy = false
                                    end
                                end)

                                addon.set(adefault, 1)

                                lib.onConfigLoaded:Connect(function()
                                    addon.set(lib.flags[count..flag].key, 1)
                                    addon.set(lib.flags[count..flag].method, 2)
                                end)
                            end

                            return addon
                        end

                        element.set(default, false)
                    elseif etype == "button" then
                        totalSize = totalSize + 24

                        local confirmation = args["confirmation"] and true or false

                        local ExampleButton = Instance.new("Frame")
                        local ExampleButtonInside = Instance.new("Frame")
                        local ButtonLabel = Instance.new("TextLabel")
                        local ButtonHighlight = lib.util.create("ImageLabel", {
                            Name = name.."ButtonHighlight",
                            Parent = ExampleButtonInside,
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            BackgroundTransparency = 1.000,
                            Size = UDim2.new(1, 0, 1, 0),
                            Image = "http://www.roblox.com/asset/?id=8753795586",
                            ImageColor3 = Color3.fromRGB(47, 47, 47)
                        }, {"savetransparency"});
                        
                        ExampleButton.Name = name.."ExampleButton"
                        ExampleButton.Parent = SectionHolder
                        ExampleButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                        ExampleButton.BorderColor3 = Color3.fromRGB(27, 42, 53)
                        ExampleButton.BorderSizePixel = 0
                        ExampleButton.Size = UDim2.new(1, -30, 0, 19)
                        local UICorner = Instance.new("UICorner", ExampleButton); UICorner.CornerRadius = UDim.new(0, 3)

                        ExampleButtonInside.Name = name.."ExampleButtonInside"
                        ExampleButtonInside.Parent = ExampleButton
                        ExampleButtonInside.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
                        ExampleButtonInside.BorderColor3 = Color3.fromRGB(27, 42, 53)
                        ExampleButtonInside.BorderSizePixel = 0
                        ExampleButtonInside.Position = UDim2.new(0, 1, 0, 1)
                        ExampleButtonInside.Size = UDim2.new(1, -2, 1, -2)
                        local UICorner = Instance.new("UICorner", ExampleButtonInside); UICorner.CornerRadius = UDim.new(0, 3)

                        element.main = ExampleButtonInside
                        ButtonLabel.Name = name.."ButtonLabel"
                        ButtonLabel.Parent = ExampleButtonInside
                        ButtonLabel.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
                        ButtonLabel.BackgroundTransparency = 1.000
                        ButtonLabel.BorderColor3 = Color3.fromRGB(27, 42, 53)
                        ButtonLabel.BorderSizePixel = 0
                        ButtonLabel.Position = UDim2.new(0, 1, 0, 1)
                        ButtonLabel.Size = UDim2.new(1, -2, 1, -2)
                        ButtonLabel.ZIndex = 2
                        ButtonLabel.Font = Enum.Font.SourceSans
                        ButtonLabel.Text = name
                        ButtonLabel.TextColor3 = Color3.fromRGB(135, 135, 135)
                        ButtonLabel.TextSize = 15.000
                        ButtonLabel.TextStrokeTransparency = 0.500
                        ButtonLabel.TextWrapped = true

                        local function click()
                            coroutine.wrap(function()
                                lib.util.tween(ButtonHighlight, TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(144, 144, 144)})
                                task.wait(0.14)
                                lib.util.tween(ButtonHighlight, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(47, 47, 47)})
                            end)()
                            pcall(callback)
                        end

                        ExampleButton.MouseEnter:Connect(function()
                            if not lib.busy then
                                lib.util.tween(ButtonHighlight, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(89, 89, 89)})
                            end
                        end)

                        ExampleButton.MouseLeave:Connect(function()
                            lib.util.tween(ButtonHighlight, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(47, 47, 47)})
                        end)

                        ExampleButton.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 and not lib.busy then
                                if confirmation and ButtonLabel.Text == name then
                                    ButtonLabel.Text = "Are you sure? (5)"
                                    coroutine.wrap(function()
                                        local num = 5
                                        for i = 1, 5 do
                                            task.wait(1)
                                            num = num-1
                                            if num == 0 or ButtonLabel.Text == name then
                                                ButtonLabel.Text = name
                                                break
                                            end
                                            ButtonLabel.Text = "Are you sure? ("..tostring(num)..")"
                                        end
                                    end)()
                                elseif confirmation then
                                    ButtonLabel.Text = name
                                    click()
                                else
                                    click()
                                end
                            end
                        end)
                    elseif etype == "textbox" then
                        totalSize = totalSize + 40
                        local default = args["default"] and args["default"] or ""
                        local noload = args["noload"] and true or false

                        local ExampleTextbox = lib.util.create("Frame", {
                            Name = name.."ExampleTextbox",
                            Parent = SectionHolder,
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            BackgroundTransparency = 1.000,
                            Size = UDim2.new(1, 0, 0, 35),
                        }, {"transparency"});
                        local UICorner = Instance.new("UICorner", ExampleTextbox); UICorner.CornerRadius = UDim.new(0, 8)

                        local TextboxLabel = Instance.new("TextLabel")
                        local TextboxInside = Instance.new("Frame")
                        local TextboxInside2 = Instance.new("Frame")
                        local TextBox = Instance.new("TextBox")
                        lib.flags[flag] = ""

                        TextboxLabel.Name = name.."TextboxLabel"
                        TextboxLabel.Parent = ExampleTextbox
                        TextboxLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        TextboxLabel.BackgroundTransparency = 1.000
                        TextboxLabel.Position = UDim2.new(0, 18, 0, 0)
                        TextboxLabel.Size = UDim2.new(0, 85, 0, 14)
                        TextboxLabel.Font = Enum.Font.SourceSans
                        TextboxLabel.Text = name
                        TextboxLabel.TextColor3 = Color3.fromRGB(135, 135, 135)
                        TextboxLabel.TextSize = 15.000
                        TextboxLabel.TextStrokeTransparency = 0.500
                        TextboxLabel.TextXAlignment = Enum.TextXAlignment.Left

                        TextboxInside.Name = name.."TextboxInside"
                        TextboxInside.Parent = ExampleTextbox
                        TextboxInside.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                        TextboxInside.BorderColor3 = Color3.fromRGB(27, 42, 53)
                        TextboxInside.BorderSizePixel = 0
                        TextboxInside.Position = UDim2.new(0.5, -71, 0, 18)
                        TextboxInside.Size = UDim2.new(1, -30, 0, 17)
                        local UICorner = Instance.new("UICorner", TextboxInside); UICorner.CornerRadius = UDim.new(0, 3)

                        TextboxInside2.Name = name.."TextboxInside2"
                        TextboxInside2.Parent = TextboxInside
                        TextboxInside2.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
                        TextboxInside2.BorderColor3 = Color3.fromRGB(27, 42, 53)
                        TextboxInside2.BorderSizePixel = 0
                        TextboxInside2.Position = UDim2.new(0, 1, 0, 1)
                        TextboxInside2.Size = UDim2.new(1, -2, 1, -2)
                        local UICorner = Instance.new("UICorner", TextboxInside2); UICorner.CornerRadius = UDim.new(0, 3)

                        TextBox.Parent = TextboxInside2
                        TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        TextBox.BackgroundTransparency = 1.000
                        TextBox.Position = UDim2.new(0, 1, 0, 1)
                        TextBox.Size = UDim2.new(1, -2, 1, -2)
                        TextBox.ZIndex = 2
                        TextBox.Font = Enum.Font.SourceSans
                        TextBox.PlaceholderColor3 = Color3.fromRGB(135, 135, 135)
                        TextBox.Text = ""
                        TextBox.TextColor3 = Color3.fromRGB(135, 135, 135)
                        TextBox.TextSize = 14.000
                        TextBox.TextStrokeTransparency = 0.500
                        TextBox.TextWrapped = true

                        element.set = function(text)
                            TextBox.Text = text
                            lib.flags[flag] = text
                            pcall(callback, text)
                        end

                        TextBox.FocusLost:Connect(function()
                            element.set(TextBox.Text)
                        end)

                        lib.onConfigLoaded:Connect(function()
                            if not noload then
                                element.set(lib.flags[flag])
                            end
                        end)

                        element.set(default)
                    elseif etype == "slider" then
                        totalSize = totalSize + 35
                        local min = args["min"]
                        local default = args["default"] and args["default"] or min
                        local max = args["max"]
                        local sliding; local sliding2; local inContact

                        lib.flags[flag] = default

                        local ExampleSlider = lib.util.create("Frame", {
                            Name = name.."ExampleSlider",
                            Parent = SectionHolder,
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            BackgroundTransparency = 1.000,
                            Size = UDim2.new(1, 0, 0, 30)
                        }, {"transparency"});
                        element.main = ExampleSlider
                        local SliderLabel = lib.util.create("TextLabel", {
                            Name = name.."SliderLabel",
                            Parent = ExampleSlider,
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            BackgroundTransparency = 1.000,
                            Position = UDim2.new(0, 17, 0, 0),
                            Size = UDim2.new(0, 85, 0, 14),
                            Font = Enum.Font.SourceSans,
                            Text = name,
                            TextColor3 = Color3.fromRGB(135, 135, 135),
                            TextSize = 15.000,
                            TextStrokeTransparency = 0.500,
                            TextXAlignment = Enum.TextXAlignment.Left
                        }, {"transparency"});
                        local SliderBorder = Instance.new("Frame")
                        local SliderBackground = Instance.new("Frame")
                        local SliderFill = lib.util.create("Frame", {
                            Name = name.."SliderFill",
                            Parent = SliderBackground,
                            BackgroundColor3 = lib.options.accent,
                            BorderColor3 = Color3.fromRGB(27, 42, 53),
                            BorderSizePixel = 0,
                            Size = UDim2.new(0, 0, 1, 0)
                        }, {"accent"});
                        local VisualButtonGradient = Instance.new("UIGradient")

                        SliderBorder.Name = name.."SliderBorder"
                        SliderBorder.Parent = ExampleSlider
                        SliderBorder.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                        SliderBorder.BorderColor3 = Color3.fromRGB(27, 42, 53)
                        SliderBorder.BorderSizePixel = 0
                        SliderBorder.Position = UDim2.new(0.5, -71, 0, 18)
                        SliderBorder.Size = UDim2.new(1, -30, 0, 13)
                        local UICorner = Instance.new("UICorner", SliderBorder); UICorner.CornerRadius = UDim.new(0, 3)

                        SliderBackground.Name = name.."SliderBackground"
                        SliderBackground.Parent = SliderBorder
                        SliderBackground.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
                        SliderBackground.BorderColor3 = Color3.fromRGB(27, 42, 53)
                        SliderBackground.BorderSizePixel = 0
                        SliderBackground.Position = UDim2.new(0, 1, 0, 1)
                        SliderBackground.Size = UDim2.new(1, -2, 1, -2)
                        local UICorner = Instance.new("UICorner", SliderBackground); UICorner.CornerRadius = UDim.new(0, 3)

                        local UICorner = Instance.new("UICorner", SliderFill); UICorner.CornerRadius = UDim.new(0, 3)

                        VisualButtonGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(229, 229, 229)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(91, 91, 91))}
                        VisualButtonGradient.Rotation = 90
                        VisualButtonGradient.Name = "VisualButtonGradient"
                        VisualButtonGradient.Parent = SliderFill

                        ExampleSlider.MouseEnter:Connect(function()
                            if not lib.busy then
                                lib.util.tween(SliderBorder, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(65, 65, 65)})
                            end
                        end)
    
                        ExampleSlider.MouseLeave:Connect(function()
                            lib.util.tween(SliderBorder, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(35, 35, 35)})
                        end)
    
                        local function round(num, bracket)
                            bracket = bracket or 1
                            local a = math.floor(num/bracket + (math.sign(num) * 0.5)) * bracket
                            if a < 0 then
                                a = a + bracket
                            end
                            return a
                        end
    
                        local function updateSlider(value3, call)
                            value3 = round(value3, 1)
                            value3 = math.clamp(value3, min, max)
                            local value4 = math.clamp(value3, min, max)
                            if min >= 0 then
                                lib.util.tween(SliderFill, TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new((value4 - min) / (max - min), 0, 1, 0)})
                            else
                                lib.util.tween(SliderFill, TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new((0 - min) / (max - min), 0, 0, 0)})
                                lib.util.tween(SliderFill, TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(value4 / (max - min), 0, 1, 0) })
                            end
                            lib.flags[flag] = value3
                            SliderLabel.Text = name.." ("..tostring(value3)..")"
                            if call then
                                pcall(callback, value3)
                            end
                        end
    
                        SliderBackground.InputBegan:connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 and not lib.busy then
                                sliding = true
                                sliding2 = true
                                lib.busy = true
                                updateSlider(min + ((input.Position.X - SliderBackground.AbsolutePosition.X) / SliderBackground.AbsoluteSize.X) * (max - min), true)
                            end
                            if input.UserInputType == Enum.UserInputType.MouseMovement and not lib.busy then
                                inContact = true
                            end
                        end)
    
                        services.UserInputService.InputChanged:connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseMovement and (sliding2 and lib.busy) then
                                updateSlider(min + ((input.Position.X - SliderBackground.AbsolutePosition.X) / SliderBackground.AbsoluteSize.X) * (max - min), true)
                            end
                        end)

                        SliderBackground.InputEnded:connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 and sliding2 then
                                sliding = false
                                sliding2 = false
                                lib.busy = false
                            end
                            if input.UserInputType == Enum.UserInputType.MouseMovement then
                                inContact = false
                            end
                        end)
    
                        element.set = function(value)
                            updateSlider(value, true)
                        end
    
                        element.set(default)
    
                        lib.onConfigLoaded:Connect(function()
                            updateSlider(lib.flags[flag], true)
                        end)
                    elseif etype == "dropdown" then
                        totalSize = totalSize + 42

                        local options = args["options"]
                        local multi = args["multi"]
                        local default = args["default"]
                        local eoptions = {}
                        local changed = lib.signal.new("changed"..tostring(math.random(100,13991)))
                        lib.flags[flag] = {}

                        local ExampleDropdown = lib.util.create("Frame", {
                            Name = name.."ExampleDropdown",
                            Parent = SectionHolder,
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            BackgroundTransparency = 1.000,
                            Size = UDim2.new(1, 0, 0, 38)
                        }, {"transparency"});
                        local DropdownLabel = lib.util.create("TextLabel", {
                            Name = name.."DropdownLabel",
                            Parent = ExampleDropdown,
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            BackgroundTransparency = 1.000,
                            Position = UDim2.new(0, 17, 0, 0),
                            Size = UDim2.new(0, 85, 0, 14),
                            Font = Enum.Font.SourceSans,
                            Text = name,
                            TextColor3 = Color3.fromRGB(135, 135, 135),
                            TextSize = 15.000,
                            TextStrokeTransparency = 0.500,
                            TextXAlignment = Enum.TextXAlignment.Left
                        }, {"transparency"});
                        local DropdownInside = Instance.new("Frame")
                        local UICorner = Instance.new("UICorner", DropdownInside); UICorner.CornerRadius = UDim.new(0, 3)
                        local DropdownInside2 = Instance.new("Frame")
                        local UICorner = Instance.new("UICorner", DropdownInside2); UICorner.CornerRadius = UDim.new(0, 3)
                        local DropdownArrow = lib.util.create("ImageLabel", {
                            Name = "DropdownArrow",
                            Parent = DropdownInside2,
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            BackgroundTransparency = 1.000,
                            Position = UDim2.new(1, -15, 0.5, -5),
                            Size = UDim2.new(0, 10, 0, 10),
                            Image = "http://www.roblox.com/asset/?id=8820494536",
                            ImageColor3 = Color3.fromRGB(173, 173, 173),
                            ZIndex = 2
                        }, {"transparency", "savetransparency"});
                        local DropdownLabel2 = lib.util.create("TextLabel", {
                            Name = "DropdownLabel2",
                            Parent = DropdownInside2,
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            BackgroundTransparency = 1.000,
                            Position = UDim2.new(0, 5, 0, 0),
                            Size = UDim2.new(0, 85, 0, 14),
                            Font = Enum.Font.SourceSans,
                            Text = "...",
                            TextColor3 = Color3.fromRGB(135, 135, 135),
                            TextSize = 14.000,
                            TextStrokeTransparency = 0.500,
                            TextWrapped = true,
                            TextXAlignment = Enum.TextXAlignment.Left
                        }, {"transparency"});

                        DropdownInside.Name = "DropdownInside"
                        DropdownInside.Parent = ExampleDropdown
                        DropdownInside.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                        DropdownInside.BorderColor3 = Color3.fromRGB(27, 42, 53)
                        DropdownInside.BorderSizePixel = 0
                        DropdownInside.Position = UDim2.new(0.5, -71, 0, 18)
                        DropdownInside.Size = UDim2.new(1, -30, 0, 17)

                        DropdownInside2.Name = "DropdownInside2"
                        DropdownInside2.Parent = DropdownInside
                        DropdownInside2.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
                        DropdownInside2.BorderColor3 = Color3.fromRGB(27, 42, 53)
                        DropdownInside2.BorderSizePixel = 0
                        DropdownInside2.Position = UDim2.new(0, 1, 0, 1)
                        DropdownInside2.Size = UDim2.new(1, -2, 1, -2)

                        local DropdownDrop = Instance.new("Frame")
                        local DropdownDropInside = Instance.new("Frame")
                        local UIListLayout = Instance.new("UIListLayout")

                        DropdownDrop.Name = "DropdownDrop"
                        DropdownDrop.Parent = UI
                        DropdownDrop.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                        DropdownDrop.BorderSizePixel = 0
                        DropdownDrop.Position = UDim2.new(0, 150, 0, 150)
                        DropdownDrop.Size = UDim2.new(0, 141, 0, 0)
                        DropdownDrop.Visible = false
                        DropdownDrop.ZIndex = 5

                        DropdownDropInside.Name = "DropdownDropInside"
                        DropdownDropInside.Parent = DropdownDrop
                        DropdownDropInside.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
                        DropdownDropInside.BorderSizePixel = 0
                        DropdownDropInside.Position = UDim2.new(0, 1, 0, 1)
                        DropdownDropInside.Size = UDim2.new(1, -2, 1, -2)
                        DropdownDropInside.ClipsDescendants = true
                        DropdownDropInside.ZIndex = 5

                        UIListLayout.Parent = DropdownDropInside
                        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

                        element.set = function(t, o, r)
                            local text = ""
                            if o then
                                lib.flags[flag] = t
                            else
                                if r then
                                    table.remove(lib.flags[flag], table.find(lib.flags[flag], t))
                                else
                                    table.insert(lib.flags[flag], t)
                                end
                            end
                            if not multi then
                                lib.flags[flag] = {lib.flags[flag][#lib.flags[flag]]}
                            end
                            for i,v in pairs(lib.flags[flag]) do
                                if text == "" then
                                    text = ""..v
                                else
                                    text = text..", "..v
                                end
                            end
                            if text == "" then text = "..." end
                            DropdownLabel2.Text = text
                            changed:Fire()
                            pcall(callback, lib.flags[flag])
                        end

                        element.createOption = function(name)
                            local DropdownLabel2 = lib.util.create("TextLabel", {
                                Name = "DropdownLabel2",
                                Parent = DropdownDropInside,
                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                BackgroundTransparency = 1.000,
                                Position = UDim2.new(0, 5, 0, 0),
                                Size = UDim2.new(1, -5, 0, 14),
                                Font = Enum.Font.SourceSans,
                                Text = name,
                                TextColor3 = Color3.fromRGB(135, 135, 135),
                                TextSize = 14.000,
                                TextStrokeTransparency = 0.500,
                                TextWrapped = true,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                ZIndex = 6
                            }, {"transparency", "accent"});

                            table.insert(eoptions, name)

                            DropdownLabel2.MouseEnter:Connect(function()
                                if table.find(lib.flags[flag], name) then
                                    lib.util.tween(DropdownLabel2, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(63, 63, 63)})
                                else
                                    lib.util.tween(DropdownLabel2, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(185, 185, 185)})
                                end                            
                            end)
        
                            DropdownLabel2.MouseLeave:Connect(function()
                                if table.find(lib.flags[flag], name) then
                                    lib.util.tween(DropdownLabel2, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = lib.options.accent})
                                else
                                    lib.util.tween(DropdownLabel2, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(135, 135, 135)})
                                end
                            end)

                            DropdownLabel2.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 and not table.find(lib.flags[flag], name) then
                                    lib.util.tween(DropdownLabel2, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = lib.options.accent})
                                    element.set(name)
                                elseif input.UserInputType == Enum.UserInputType.MouseButton1 and table.find(lib.flags[flag], name) then
                                    lib.util.tween(DropdownLabel2, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(135, 135, 135)})
                                    element.set(name, nil, true)
                                end
                            end)

                            changed:Connect(function()
                                if table.find(lib.flags[flag], name) then
                                    lib.util.tween(DropdownLabel2, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = lib.options.accent})
                                elseif not table.find(lib.flags[flag], name) then
                                    lib.util.tween(DropdownLabel2, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(135, 135, 135)})
                                end
                            end)
                        end

                        element.setOptions = function(args)
                            local overrideTable = {}
                            for i,v in pairs(DropdownDropInside:GetChildren()) do
                                if v:IsA("TextLabel") then
                                    v:Destroy()
                                end
                            end
                            for i,v in pairs(args) do
                                element.createOption(v)
                                if table.find(lib.flags[flag], v) then
                                    table.insert(overrideTable, v)
                                end
                            end
                            element.set(overrideTable, true)
                            eoptions = args
                        end

                        DropdownInside.MouseEnter:Connect(function()
                            if not lib.busy then
                                lib.util.tween(DropdownInside, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(65, 65, 65)})
                            end
                        end)
    
                        DropdownInside.MouseLeave:Connect(function()
                            lib.util.tween(DropdownInside, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(35, 35, 35)})
                        end)

                        for i,v in pairs(options) do
                            element.createOption(v)
                        end

                        DropdownInside.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 and not lib.busy then
                                lib.util.tween(DropdownArrow, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Rotation = 180})
                                lib.util.tween(DropdownDrop, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 141, 0, 3 + (#eoptions*14))})
                                DropdownDrop.Position = UDim2.new(0, DropdownInside.AbsolutePosition.X + 1, 0, DropdownInside.AbsolutePosition.Y + 16)
                                DropdownDrop.Visible = true
                                lib.busy = true
                                coroutine.wrap(function()
                                    task.wait(0.15)
                                    DropdownDrop.Visible = true
                                end)()
                            elseif input.UserInputType == Enum.UserInputType.MouseButton1 and lib.busy and DropdownDrop.Visible then
                                lib.util.tween(DropdownArrow, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Rotation = 0})
                                lib.util.tween(DropdownDrop, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 141, 0, 0)})
                                lib.busy = false
                                coroutine.wrap(function()
                                    task.wait(0.15)
                                    DropdownDrop.Visible = false
                                end)()
                            end
                        end)

                        lib.closing:Connect(function()
                            if lib.busy and DropdownDrop.Visible then
                                lib.util.tween(DropdownArrow, TweenInfo.new(0.04, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Rotation = 0})
                                lib.util.tween(DropdownDrop, TweenInfo.new(0.04, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 141, 0, 0)})
                                lib.busy = false
                                coroutine.wrap(function()
                                    task.wait(0.04)
                                    DropdownDrop.Visible = false
                                end)()
                            end
                        end)

                        lib.onConfigLoaded:Connect(function()
                            element.set(lib.flags[flag], true)
                        end)

                        if default then
                            element.set(eoptions[1], false)
                        end
                    end

                    if popup then
                        local pname = popup["name"]
                        local pbody = popup["body"]

                        local PopUp = Instance.new("Frame")
                        local PopUpInside = Instance.new("Frame")
                        local PopUpLabel = Instance.new("TextLabel")
                        local PopUpDivider = Instance.new("Frame")
                        local PopUpLabel2 = Instance.new("TextLabel")

                        PopUp.Name = "PopUp"
                        PopUp.Parent = element.main:FindFirstChildOfClass("TextLabel")
                        PopUp.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                        PopUp.BorderColor3 = Color3.fromRGB(25, 25, 25)
                        PopUp.Position = UDim2.new(0, 0, 1, 2)
                        PopUp.Size = UDim2.new(1.5, 0, 0, 85)
                        PopUp.ZIndex = 4
                        PopUp.Visible = false
                        local UICorner = Instance.new("UICorner", PopUp); UICorner.CornerRadius = UDim.new(0, 8)

                        PopUpInside.Name = "PopUpInside"
                        PopUpInside.Parent = PopUp
                        PopUpInside.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
                        PopUpInside.BorderColor3 = Color3.fromRGB(25, 25, 25)
                        PopUpInside.Position = UDim2.new(0, 1, 0, 1)
                        PopUpInside.Size = UDim2.new(1, -2, 1, -2)
                        PopUpInside.ZIndex = 4
                        local UICorner = Instance.new("UICorner", PopUpInside); UICorner.CornerRadius = UDim.new(0, 8)
                        
                        PopUpLabel.Name = "PopUpLabel"
                        PopUpLabel.Parent = PopUpInside
                        PopUpLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        PopUpLabel.BackgroundTransparency = 1.000
                        PopUpLabel.Position = UDim2.new(0, 0, 0, 2)
                        PopUpLabel.Size = UDim2.new(1, 0, 0, 15)
                        PopUpLabel.ZIndex = 4
                        PopUpLabel.Font = Enum.Font.SourceSansSemibold
                        PopUpLabel.Text = pname
                        PopUpLabel.TextColor3 = Color3.fromRGB(156, 156, 156)
                        PopUpLabel.TextSize = 16.000

                        PopUpDivider.Name = "PopUpDivider"
                        PopUpDivider.Parent = PopUpLabel
                        PopUpDivider.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                        PopUpDivider.BorderSizePixel = 0
                        PopUpDivider.Position = UDim2.new(0, 0, 1, 2)
                        PopUpDivider.Size = UDim2.new(1, 0, 0, 1)
                        PopUpDivider.ZIndex = 4

                        PopUpLabel2.Name = "PopUpLabel2"
                        PopUpLabel2.Parent = PopUpInside
                        PopUpLabel2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        PopUpLabel2.BackgroundTransparency = 1.000
                        PopUpLabel2.Position = UDim2.new(0, 0, 0.5, -18)
                        PopUpLabel2.Size = UDim2.new(1, 0, 0.7, -1)
                        PopUpLabel2.ZIndex = 4
                        PopUpLabel2.Font = Enum.Font.SourceSans
                        PopUpLabel2.Text = pbody
                        PopUpLabel2.TextColor3 = Color3.fromRGB(136, 136, 136)
                        PopUpLabel2.TextSize = 14.000
                        PopUpLabel2.TextWrapped = true
                        PopUpLabel2.TextYAlignment = Enum.TextYAlignment.Top

                        element.popup = PopUp

                        element.main:FindFirstChildOfClass("TextLabel").InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                                if not lib.busy then
                                    LPH_JIT_MAX(function()
                                        lib.util.tween(element.popup, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
                                        for i,v in pairs(element.popup:GetDescendants()) do
                                            if v:IsA("Frame") then
                                                lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
                                            elseif v:IsA("TextLabel") then
                                                lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0})
                                            end
                                        end
                                    end)()
                                    element.popup.Visible = true
                                    lib.busy = true
                                elseif lib.busy and element.popup.Visible then
                                    LPH_JIT_MAX(function()
                                        lib.util.tween(element.popup, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
                                        for i,v in pairs(element.popup:GetDescendants()) do
                                            if v:IsA("Frame") then
                                                lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
                                            elseif v:IsA("TextLabel") then
                                                lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 1})
                                            end
                                        end
                                    end)()
                                    task.wait(0.189)
                                    element.popup.Visible = false
                                    lib.busy = false
                                end
                            end
                        end)
    
                        for i,v in pairs(element.popup:GetDescendants()) do
                            if v:IsA("Frame") then
                                lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
                            elseif v:IsA("TextLabel") then
                                lib.util.tween(v, TweenInfo.new(0.189, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 1})
                            end
                        end
                    end

                    if totalSize > 210 then
                        SectionHolder.ScrollingEnabled = true
                        local size = totalSize - 210
                        SectionHolder.CanvasSize = UDim2.new(0, 0, 0, 210 + size)
                    end

                    return element
                end

                return elements
            end
            
            return sections
        end
        
        return subtabs
    end

    return tabs
end

-- * Cheat Indicators

local ScreenGui = lib.util.create("ScreenGui", {
    Parent = game.CoreGui,
    Name = services.HttpService:GenerateGUID(false)
})
local Indicators = Instance.new("Frame")
local UIListLayout = Instance.new("UIListLayout")

Indicators.Name = "Indicators"
Indicators.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Indicators.BackgroundTransparency = 1.000
Indicators.Position = UDim2.new(0, 10, 1, -510)
Indicators.Size = UDim2.new(0, 150, 0, 500)
Indicators.Parent = ScreenGui

UIListLayout.Parent = Indicators
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

-- * Cheat Utility

local client = {}
    client.plr = services.Players.LocalPlayer
    client.character = function() return client.plr.Character or client.plr.CharacterAdded:Wait() end; client.lagCooldown = false
    client.resolver = {}; client.esp = {}; client.mouse = client.plr:GetMouse()
    client.bodyCache = {}; client.animations = {}; client.target = nil; client.rc = false
    client.fake = true; client.recent = false; client.hitsounds = {Cod = "rbxassetid://160432334", Bameware = "rbxassetid://6565367558", Neverlose = "rbxassetid://6565370984", Gamesense = "rbxassetid://4817809188", Rust = "rbxassetid://6565371338"}
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

task.wait(1)

-- * Cheat Indicators (2)

local indicators = {}
    indicators.main = Indicators
    indicators.create = function(name)
        local IndicatorLabel = Instance.new("TextLabel")
        local UIGradient = Instance.new("UIGradient")
        
        IndicatorLabel.Name = name
        IndicatorLabel.Parent = indicators.main
        IndicatorLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        IndicatorLabel.BackgroundTransparency = 1.000
        IndicatorLabel.Size = UDim2.new(1, 0, 0, 35)
        IndicatorLabel.Font = Enum.Font.SourceSansSemibold
        IndicatorLabel.Text = name
        IndicatorLabel.TextColor3 = lib.options.accent
        IndicatorLabel.TextSize = 36.000
        IndicatorLabel.TextStrokeTransparency = 0.800
        IndicatorLabel.TextXAlignment = Enum.TextXAlignment.Left
        IndicatorLabel.Visible = false

        UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(0.90, Color3.fromRGB(0, 0, 0)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))}
        UIGradient.Parent = IndicatorLabel

        return IndicatorLabel
    end


-- * Cheat Functions

local silentInd = indicators.create("SILENT")
local invisInd = indicators.create("INVIS")
local speedInd = indicators.create("SPEED")

local function YROTATION(cframe) -- stolen, ty stormy
    local x, y, z = cframe:ToOrientation() 
    return CFrame.new(cframe.Position) * CFrame.Angles(0,y,0) 
end 

local function getPlayers()
    local t = {}
    for i,v in pairs(services.Players:GetPlayers()) do
        if v ~= client.plr then
            table.insert(t, v.Name)
        end
    end
    return t
end

local function espTable()
	local returnTable = {}
	returnTable.box = Drawing.new("Square")
	returnTable.box.Filled = false
	returnTable.box.Thickness = 1
	returnTable.box.Visible = false
	returnTable.box.ZIndex = 2
	returnTable.outline = Drawing.new("Square")
	returnTable.outline.Filled = false
	returnTable.outline.Color = Color3.fromRGB(0,0,0)
	returnTable.outline.Thickness = 3
	returnTable.outline.Visible = false
	returnTable.outline.ZIndex = 1
	returnTable.name = Drawing.new("Text")
	returnTable.name.Size = 14
	returnTable.name.Center = true
	returnTable.name.Outline = true
	returnTable.name.Font = Drawing.Fonts.Plex
	returnTable.name.Visible = false
	returnTable.name.ZIndex = 3
    returnTable.healthoutline = Drawing.new("Line")
	returnTable.healthoutline.Color = Color3.fromRGB(0,0,0)
	returnTable.healthoutline.Thickness = 3
	returnTable.healthoutline.Visible = false
	returnTable.healthoutline.ZIndex = 1
	returnTable.healthbar = Drawing.new("Line")
	returnTable.healthbar.Thickness = 1
	returnTable.healthbar.Visible = false
	returnTable.healthbar.ZIndex = 2

	return returnTable
end

-- * Cheat UI Menu

local menu = lib.menu("Eunoia", "debug")
    local combat = menu.tab("Combat")
        local legit = combat.subtab("Legit")
            local aim = legit.section("Aim")
                local silentaim = aim.element({name = "Mouse aim", type = "toggle", flag = "silentaim", callback = function()
                end}); silentaim.addon({type = "keybind", default = "X", callback = function(t)
                end})
                local silentcircle = aim.element({name = "FOV circle", type = "toggle", flag = "fovcircle", callback = function()
                end}); silentcircle.addon({name = "FOV Circle Colorpicker", type = "colorpicker", default = Color3.fromRGB(255,255,255), callback = function(t)
                end})
                local silentcirclesize = aim.element({name = "Circle size", type = "slider", min = 5, default = 50, max = 250, flag = "circlesize", callback = function()
                end})
                local visiblecheck = aim.element({name = "Visible check", type = "toggle", flag = "visiblecheck", callback = function()
                end})
                local rightclick = aim.element({name = "Right click", type = "toggle", flag = "rightclick", callback = function()
                end})
                local aimspeed = aim.element({name = "Aim speed", type = "slider", min = 1, default = 9, max = 15, flag = "aimspeed", callback = function()
                end})
                local aimpart = aim.element({name = "Aim at", type = "dropdown", default = false, multi = false, options = {"Head", "UpperTorso"}, flag = "aimpart", callback = function()
                end})
        local misc = combat.subtab("Misc")
            local other = misc.section("Other")
    local visuals = menu.tab("Visuals")
        local esp = visuals.subtab("ESP")
            local enemy = esp.section("Enemy")
                local enemyesp = enemy.element({name = "Enabled", flag = "enemyesp", type = "toggle", callback = function(o)
                end})
                local enemyespbox = enemy.element({name = "Box", flag = "enemyespbox", type = "toggle", callback = function(o)
                end}); enemyespbox.addon({name = "Box Colorpicker", type = "colorpicker", default = Color3.fromRGB(255,255,255), callback = function(t)
                end}) 
                local enemyespname = enemy.element({name = "Name", flag = "enemyespname", type = "toggle", callback = function(o)
                end}); enemyespname.addon({name = "Name Colorpicker", type = "colorpicker", default = Color3.fromRGB(255,255,255), callback = function(t)
                end}) 
                local enemyesphealth = enemy.element({name = "Health", flag = "enemyesphealth", type = "toggle", callback = function(o)
                end}); enemyesphealth.addon({name = "Health Colorpicker", type = "colorpicker", default = Color3.fromRGB(0,255,0), callback = function(t)
                end}) 
                local enemyespchams = enemy.element({name = "Chams", flag = "enemyespchams", type = "toggle", callback = function(o)
                end}); enemyespchams.addon({name = "Chams Colorpicker", type = "colorpicker", default = Color3.fromRGB(0,0,0), callback = function(t)
                end}); enemyespchams.addon({name = "Outline Colorpicker", type = "colorpicker", default = Color3.fromRGB(255,255,255), callback = function(t)
                end}) 
                local enemyespfont = enemy.element({name = "Font", flag = "enemyespfont", type = "dropdown", options = {"UI","Plex","System","Monospace"}, default = true, callback = function(o)
                end})
                local enemyespfontsize = enemy.element({name = "Font size", type = "slider", min = 14, default = 14, max = 20, flag = "enemyespsize", callback = function()
                end})
                local enemyespdistance = enemy.element({name = "Max distance", type = "slider", min = 100, default = 500, max = 1500, flag = "espdistance", callback = function()
                end})
            local target = esp.section("Aim Target")
                local targetespbox = target.element({name = "Box", flag = "targetespbox", type = "toggle", callback = function(o)
                end}); targetespbox.addon({name = "Box Colorpicker", remove = true, type = "colorpicker", default = Color3.fromRGB(255,255,255), callback = function(t)
                end}) 
                local targetespname = target.element({name = "Name", flag = "targetespname", type = "toggle", callback = function(o)
                end}); targetespname.addon({name = "Name Colorpicker", remove = true, type = "colorpicker", default = Color3.fromRGB(255,255,255), callback = function(t)
                end}) 
                local targetesphealth = target.element({name = "Health", flag = "targetesphealth", type = "toggle", callback = function(o)
                end}); targetesphealth.addon({name = "Health Colorpicker", remove = true, type = "colorpicker", default = Color3.fromRGB(0,255,0), callback = function(t)
                end})
                local targetespchams = target.element({name = "Chams", flag = "targetespchams", type = "toggle", callback = function(o)
                end}); targetespchams.addon({name = "Chams Colorpicker", type = "colorpicker", remove = true, default = Color3.fromRGB(0,0,0), callback = function(t)
                end}); targetespchams.addon({name = "Outline Colorpicker", type = "colorpicker", default = Color3.fromRGB(255,0,0), callback = function(t)
                end}) 
                local targetespfont = target.element({name = "Font", flag = "targetespfont", type = "dropdown", options = {"UI","Plex","System","Monospace"}, default = true, callback = function(o)
                end})
                local targetespfontsize = target.element({name = "Font size", type = "slider", min = 14, default = 14, max = 20, flag = "targetespsize", callback = function()
                end})
        local ccclient = visuals.subtab("Client")
            local hud = ccclient.section("HUD")
                local indicators = hud.element({name = "Indicators", flag = "indicators", type = "toggle", default = true, callback = function(o)
                end})
            local world = ccclient.section("World")
                local nadewarning = world.element({name = "Nade warning", flag = "nadewarning", type = "toggle", callback = function(o)
                end}); nadewarning.addon({name = "Nade Colorpicker", remove = false, type = "colorpicker", default = Color3.fromRGB(255,0,0), callback = function(t)
                end}) 
                local ambiance = world.element({name = "World ambient", flag = "ambient", type = "toggle", callback = function(o)
                end}); ambiance.addon({name = "Ambient Colorpicker", remove = true, type = "colorpicker", default = Color3.fromRGB(0,0,0), callback = function(t)
                end}) 
                local ambiance2 = world.element({name = "Outdoor ambient", flag = "ambient2", type = "toggle", callback = function(o)
                end}); ambiance2.addon({name = "Ambient Colorpicker", remove = true, type = "colorpicker", default = Color3.fromRGB(128,128,128), callback = function(t)
                end}) 
                local worldtime = world.element({name = "World time", type = "slider", min = 0, default = 0, max = 24, flag = "time", callback = function()
                end})
                local worldremovals = world.element({name = "Removals", type = "dropdown", default = false, multi = true, options = {"Shadows"}, flag = "removals", callback = function()
                    game.Lighting.GlobalShadows = not table.find(lib.flags["removals"], "Shadows")
                end})
    local playerss = menu.tab("Players")
        local ccccclient = playerss.subtab("Local")
            local character = ccccclient.section("Character")
                local invisible = character.element({name = "Invisible", type = "toggle", flag = "invisible", callback = function()
                end}); invisible.addon({type = "keybind", default = "X", callback = function(t)
                end})
            local movement = ccccclient.section("Movement")
                local speed = movement.element({name = "CFrame speed", type = "toggle", flag = "speed", callback = function()
                end}); speed.addon({type = "keybind", default = "G", callback = function(t)
                end})
                local speed3 = movement.element({name = "Speed multi", type = "slider", min = 1, default = 1, max = 100, flag = "speed3", callback = function()
                end})
    local settings = menu.tab("Settings")
        local general = settings.subtab("General")
            local configurations = general.section("Configurations")
                local configlist = configurations.element({name = "Config list", flag = "configlist", type = "dropdown", options = {"Legit", "Rage", "Stream", "Autofarm", "Other"}})
                local loadconfig = configurations.element({name = "Load config", type = "button", confirmation = true, callback = function()
                    lib.loadConfig(lib.flags["configlist"][1])
                end})
                local saveconfig = configurations.element({name = "Save config", type = "button", confirmation = true, callback = function()
                    lib.saveConfig(lib.flags["configlist"][1])
                end})
            local ui = general.section("UI")
                local togglekey = ui.element({name = "Toggle key", type = "toggle", flag = "togglekey", callback = function()
                    lib.options.toggle = Enum.KeyCode[lib.flags["1togglekey"].key]
                end}); togglekey.addon({type = "keybind", remove = true, default = "LeftAlt"})
                local accent = ui.element({name = "Accent color", type = "toggle", flag = "accent", callback = function()
                end}); accent.addon({name = "UI Accent Colorpicker", type = "colorpicker", remove = true, default = lib.options.accent, callback = function(t)
                    menu.changeAccent(t.Color)
                end})

-- * Cheat Functions

local function updatePlayers()
end

for i,v in pairs(services.Players:GetPlayers()) do
    if v ~= client.plr then
        client.resolver[v.Name] = {}
        client.resolver[v.Name].visible = false
        client.esp[v.Name] = espTable()
        
        local highlight = Instance.new("Highlight")
        highlight.Parent = game.CoreGui
        highlight.Enabled = false
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Name = v.Name

        if workspace:FindFirstChild(v.Name) then
            highlight.Adornee = workspace[v.Name]
        end

        v.CharacterAdded:Connect(function(character)
            highlight.Adornee = character
        end)
    end
end

local function getClosest()
	local closestTarg = math.huge
	local Target = nil
	if client.character():FindFirstChild("HumanoidRootPart") then
		for _, Player in next, services.Players:GetPlayers() do
			if Player ~= client.plr and Player.Character and (Player.Team ~= client.plr.Team or client.plr.Team == nil) then
				local playerHumanoid = Player.Character:FindFirstChild("Humanoid")
				local playerPart = Player.Character:FindFirstChild("HumanoidRootPart")
				if playerPart and playerHumanoid then
					local hitVector, onScreen = workspace.CurrentCamera:WorldToScreenPoint(playerPart.Position)
                    local checks = #workspace.CurrentCamera:GetPartsObscuringTarget({client.character().HumanoidRootPart.Position, playerPart.Position}, {workspace.CurrentCamera, client.character(), playerPart.Parent, workspace.map.bulletsgothrough}) < 1
					if not lib.flags["visiblecheck"] then checks = true end
                    if onScreen and (client.character().HumanoidRootPart.Position-playerPart.Position).magnitude < 220 and checks then
						local CCF = workspace.CurrentCamera.CFrame.p
						local hitTargMagnitude = (Vector2.new(client.mouse.X, client.mouse.Y) - Vector2.new(hitVector.X, hitVector.Y)).magnitude
						local threshold = lib.flags["circlesize"]*8
						if hitTargMagnitude < closestTarg and hitTargMagnitude <= threshold then
							Target = playerPart.Parent
							closestTarg = hitTargMagnitude
						end
					end
				end
			end
		end
	end
	return Target
end

local function resolve(part)
    local vel = part.Velocity
    local yvel = part.Velocity.Y
	local part2 = part.Parent.HumanoidRootPart
	yvel = part2.Velocity.Y*(lib.flags["prediction"]/3333)

    return part.CFrame + Vector3.new(vel.X*(lib.flags["prediction"]/1000), yvel, vel.Z*(lib.flags["prediction"]/1000))
end

local function getDirection(o, p)
    return (p - o).Unit * 1000
end

-- * Metatables

LPH_JIT_MAX(function()
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        local script = getcallingscript()
        if not checkcaller() and method == "FireServer" and tostring(self) == "Replicator" and args[1] == "Neck" and lib.flags["invisible"] and lib.flags["1invisible"].active then
            args[2]["C1"] = CFrame.new(math.random(1), math.random(1), math.random(1), math.random(1), math.random(1), math.random(1), math.random(1), math.random(1), math.random(1), math.random(1), math.random(1), math.random(1))  
            return old(self, unpack(args))
        end
        return old(self, ...)
    end)
end)()

-- * Connections

LPH_JIT_MAX(function()
    services.RunService.RenderStepped:Connect(function()
        services.RunService.RenderStepped:Wait()
        for _, player in pairs(services.Players:GetPlayers()) do
            if player ~= client.plr then
                if client.esp[player.Name] then
                    local playerTable = client.esp[player.Name]
                    for i,v in pairs(playerTable) do
                        v.Visible = false
                    end
                    
                    if services.CoreGui:FindFirstChild(player.Name) then
                        services.CoreGui[player.Name].Enabled = false
                    end

                    if lib.flags["enemyesp"] then
                        local character = workspace:FindFirstChild(player.Name)
                        local hrp, hum;

                        if character then
                            hrp = character:FindFirstChild("HumanoidRootPart")
                        end

                        if character then
                            hum = character:FindFirstChild("Humanoid")
                        end

                        local dist = 1

                        if client.loaded() and hrp then
                            dist = (client.character().HumanoidRootPart.Position-hrp.Position).magnitude
                        end

                        local Target = nil

                        services.CoreGui[player.Name].FillColor = client.target == player.Name and lib.flags["1targetespchams"].Color or lib.flags["1enemyespchams"].Color
                        services.CoreGui[player.Name].OutlineColor = client.target == player.Name and lib.flags["2targetespchams"].Color or lib.flags["2enemyespchams"].Color
                        services.CoreGui[player.Name].FillTransparency = client.target == player.Name and lib.flags["1targetespchams"].Transparency or lib.flags["1enemyespchams"].Transparency
                        services.CoreGui[player.Name].OutlineTransparency = client.target == player.Name and lib.flags["2targetespchams"].Transparency or lib.flags["2enemyespchams"].Transparency

                        local pos, visible
                        if hrp and dist < lib.flags["espdistance"] then
                            pos, visible = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
                        end

                        if visible and hrp and hum and (player.Team ~= client.plr.Team or client.plr.Team == nil) then
                            services.CoreGui[player.Name].Enabled = lib.flags["enemyespchams"]
                            _G.pos = pos
                            _G.hrp = hrp
                            _G.Size = nil
                            _G.BoxSize = nil
                            _G.BoxPos = nil
                            LPH_JIT_ULTRA(function()
                                _G.Size = (workspace.CurrentCamera:WorldToViewportPoint(_G.hrp.Position - Vector3.new(0, 3.3, 0)).Y - workspace.CurrentCamera:WorldToViewportPoint(_G.hrp.Position + Vector3.new(0, 2.9, 0)).Y) / 2
                                _G.BoxSize = Vector2.new(math.floor(_G.Size * 1.5), math.floor(_G.Size * 1.9))
                                _G.BoxPos = Vector2.new(math.floor(_G.pos.X - _G.Size * 1.5 / 2), math.floor(_G.pos.Y - _G.Size * 1.6 / 2))
                            end)() 
                            local BoxSize = _G.BoxSize
                            local BoxPos = _G.BoxPos
                
                            local font
                            if client.target == player.Name then
                                if #lib.flags["targetespfont"] ~= 1 then
                                    font = "UI"
                                else
                                    font = lib.flags["targetespfont"][1]
                                end
                            else
                                if #lib.flags["enemyespfont"] ~= 1 then
                                    font = "UI"
                                else
                                    font = lib.flags["enemyespfont"][1]
                                end
                            end

                            if lib.flags["enemyespbox"] then
                                playerTable.box.Visible = true
                                playerTable.box.Size = BoxSize
                                playerTable.box.Position = BoxPos
                                playerTable.box.Color = client.target == player.Name and lib.flags["1targetespbox"].Color or lib.flags["1enemyespbox"].Color
                                playerTable.box.Transparency = client.target == player.Name and -lib.flags["1targetespbox"].Transparency+1 or -lib.flags["1enemyespbox"].Transparency+1
                                playerTable.outline.Transparency = client.target == player.Name and -lib.flags["1targetespbox"].Transparency+1 or -lib.flags["1enemyespbox"].Transparency+1
                                playerTable.outline.Size = BoxSize
                                playerTable.outline.Position = BoxPos
                                playerTable.outline.Visible = true
                            end

                            if lib.flags["enemyespname"] then
                                playerTable.name.Text = player.Name 
                                playerTable.name.Position = Vector2.new(BoxSize.X / 2 + BoxPos.X, BoxPos.Y - 19)
                                playerTable.name.Color = client.target == player.Name and lib.flags["1targetespname"].Color or lib.flags["1enemyespname"].Color
                                playerTable.name.Transparency = client.target == player.Name and -lib.flags["1targetespname"].Transparency+1 or -lib.flags["1enemyespname"].Transparency+1
                                playerTable.name.Font = Drawing.Fonts[font]
                                playerTable.name.Size = client.target == player.Name and lib.flags["targetespsize"] or lib.flags["enemyespsize"]
                                playerTable.name.Visible = true
                            end

                            if lib.flags["enemyesphealth"] then
                                playerTable.healthbar.From = Vector2.new((BoxPos.X - 5), BoxPos.Y + BoxSize.Y)
                                playerTable.healthbar.To = Vector2.new(playerTable.healthbar.From.X, playerTable.healthbar.From.Y - (player.health.Value / character.Humanoid.MaxHealth) * BoxSize.Y)
                                playerTable.healthbar.Color = client.target == player.Name and lib.flags["1targetesphealth"].Color or lib.flags["1enemyesphealth"].Color
                                playerTable.healthbar.Transparency = client.target == player.Name and -lib.flags["1targetesphealth"].Transparency+1 or -lib.flags["1enemyesphealth"].Transparency+1
                                playerTable.healthbar.Visible = true
                
                                playerTable.healthoutline.From = Vector2.new(playerTable.healthbar.From.X, BoxPos.Y + BoxSize.Y + 1)
                                playerTable.healthoutline.To = Vector2.new(playerTable.healthbar.From.X, (playerTable.healthbar.From.Y - 1 * BoxSize.Y) -1)
                                playerTable.healthoutline.Visible = true
                            end
                        end
                    end
                end
            end
        end
    end)
end)()

services.UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        client.rc = true
    end
end)

services.UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        client.rc = false
    end
end)

client.plr.CharacterAdded:Connect(function(char)
    repeat task.wait() until client.loaded()

    if not lib.flags["forcefieldbody"] then
        for i,v in pairs(client.character():GetChildren()) do
            if v:IsA("MeshPart") then
                client.bodyCache[v.Name] = v.Color
            end
        end
    end
end)

if workspace:FindFirstChild("map") then
    workspace.map.bulletsgothrough.gamestuff.ChildAdded:Connect(function(nade)
        if nade:IsA("MeshPart") and lib.flags["nadewarning"] then
            local BillboardGui = Instance.new("BillboardGui")
            local ImageLabel = Instance.new("ImageLabel")

            BillboardGui.Parent = nade
            BillboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            BillboardGui.Active = true
            BillboardGui.AlwaysOnTop = true
            BillboardGui.LightInfluence = 1.000
            BillboardGui.Size = UDim2.new(4, 0, 4, 0)

            ImageLabel.Parent = BillboardGui
            ImageLabel.ImageColor3 = lib.flags["1nadewarning"].Color
            ImageLabel.BackgroundTransparency = 1.000
            ImageLabel.Size = UDim2.new(1, 0, 1, 0)
            ImageLabel.Image = "rbxassetid://9326086482"
        end
    end)
end

workspace.ChildAdded:Connect(function(d)
    if d.Name == "map" then
        task.wait(5)
        workspace.map.bulletsgothrough.gamestuff.ChildAdded:Connect(function(nade)
            if nade:IsA("MeshPart") and lib.flags["nadewarning"] then
                local BillboardGui = Instance.new("BillboardGui")
                local ImageLabel = Instance.new("ImageLabel")
    
                BillboardGui.Parent = nade
                BillboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                BillboardGui.Active = true
                BillboardGui.AlwaysOnTop = true
                BillboardGui.LightInfluence = 1.000
                BillboardGui.Size = UDim2.new(4, 0, 4, 0)
    
                ImageLabel.Parent = BillboardGui
                ImageLabel.ImageColor3 = lib.flags["1nadewarning"].Color
                ImageLabel.BackgroundTransparency = 1.000
                ImageLabel.Size = UDim2.new(1, 0, 1, 0)
                ImageLabel.Image = "rbxassetid://9326086482"
            end
        end)
    end
end)

services.Players.PlayerAdded:Connect(function(player)
    client.resolver[player.Name] = {}
    client.resolver[player.Name].visible = false
    client.esp[player.Name] = espTable()

    local highlight = Instance.new("Highlight")
    highlight.Parent = game.CoreGui
    highlight.Enabled = false
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Name = player.Name

    if workspace:FindFirstChild(player.Name) then
        game.CoreGui[player.Name].Adornee = workspace[player.Name]
    end

    player.CharacterAdded:Connect(function(character)
        game.CoreGui[player.Name].Adornee = character
    end)

    updatePlayers()
end)

services.Players.PlayerRemoving:Connect(function(player)
    if player ~= client.plr then
        client.resolver[player.Name] = nil
        for i,v in pairs(client.esp[player.Name]) do
            v:Remove()
        end
        client.esp[player.Name] = nil
    end
    services.CoreGui[player.Name]:Destroy()
    updatePlayers()
end)

services.UserInputService.JumpRequest:connect(function()
    if lib.flags["infjump"] and lib.flags["1infjump"].active then
        client.character().Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- * Loops

local circle = Drawing.new("Circle")
circle.NumSides = 24
circle.Visible = false
circle.Filled = false
circle.Thickness = 2

LPH_JIT_MAX(function()
    services.RunService.Heartbeat:Connect(function()
        game.Lighting.Ambient = lib.flags["1ambient"].Color
        game.Lighting.OutdoorAmbient = lib.flags["1ambient2"].Color
        if lib.flags["time"] ~= 0 then
            game.Lighting.ClockTime = lib.flags["time"]
        end
        if client.loaded() then
            if lib.flags["silentaim"] and lib.flags["1silentaim"].active then
                if lib.flags["fovcircle"] then
                    circle.Visible = true
                    circle.Color = lib.flags["1fovcircle"].Color
                    circle.Transparency = -lib.flags["1fovcircle"].Transparency+1
                    circle.Radius = lib.flags["circlesize"]*8
                    circle.Position = Vector2.new(client.mouse.X,client.mouse.Y+42)
                else
                    circle.Visible = false
                end
                client.target = tostring(getClosest())
                if not services.Players:FindFirstChild(client.target) or not workspace:FindFirstChild(client.target) or not workspace:FindFirstChild(client.target):FindFirstChild(lib.flags["aimpart"][1]) then
                    client.target = nil
                end
                if client.target ~= nil then
                    local check = false
                    if lib.flags["rightclick"] then
                        check = client.rc
                    else
                        check = true
                    end
                    if lib.flags["silentaim"] and lib.flags["1silentaim"].active and check then
                        local pos = services.Players[client.target].Character:FindFirstChild(lib.flags["aimpart"][1])
                        if pos then
                            pos = pos.Position
                            local pos2 = workspace.CurrentCamera:WorldToScreenPoint(pos)
                            local pos3 = workspace.CurrentCamera:WorldToScreenPoint(client.mouse.Hit.p)
                            local smooth = lib.flags["aimspeed"] > 1 and lib.flags["aimspeed"] + math.random(300,1200)/1000 or 1
                            local x, y = (pos2.X - pos3.X) / lib.flags["aimspeed"], (pos2.Y - pos3.Y) / smooth
                            mousemoverel(x, y)
                        end
                    end
                end
            else
                client.target = nil
                circle.Visible = false
            end
            silentInd.TextColor3 = lib.options.accent
            silentInd.Visible = lib.flags["silentaim"] and lib.flags["1silentaim"].active and lib.flags["indicators"]
            speedInd.TextColor3 = lib.options.accent
            speedInd.Visible = lib.flags["speed"] and lib.flags["1speed"].active and lib.flags["indicators"]
            invisInd.TextColor3 = lib.options.accent
            invisInd.Visible = lib.flags["invisible"] and lib.flags["1invisible"].active and lib.flags["indicators"]
            if lib.flags["speed"] and lib.flags["1speed"].active then
                if client.character().Humanoid.MoveDirection ~= Vector3.new() then
                    local add = 0
                    if services.UserInputService:IsKeyDown("A") then add = 90 end
                    if services.UserInputService:IsKeyDown("S") then add = 180 end
                    if services.UserInputService:IsKeyDown("D") then add = 270 end
                    if services.UserInputService:IsKeyDown("A") and services.UserInputService:IsKeyDown("W") then add = 45 end
                    if services.UserInputService:IsKeyDown("D") and services.UserInputService:IsKeyDown("W") then add = 315 end
                    if services.UserInputService:IsKeyDown("D") and services.UserInputService:IsKeyDown("S") then add = 225 end
                    if services.UserInputService:IsKeyDown("A") and services.UserInputService:IsKeyDown("S") then add = 145 end
                    local rot = YROTATION(workspace.CurrentCamera.CFrame) * CFrame.Angles(0,math.rad(add),0)
                    client.character().HumanoidRootPart.CFrame = client.character().HumanoidRootPart.CFrame + Vector3.new(rot.LookVector.X,0,rot.LookVector.Z) * lib.flags["speed3"]/110
                end
            end
        end
    end)
end)()
