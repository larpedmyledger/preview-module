-- ESP Preview Module for UI Library
-- Load this from GitHub and integrate with your main library

local ESPPreview = {}

function ESPPreview.Create(Library)
    local Create = Library.Create or function(class, properties)
        local instance = Instance.new(class)
        for k, v in pairs(properties) do
            if k ~= "Parent" then
                instance[k] = v
            end
        end
        if properties.Parent then
            instance.Parent = properties.Parent
        end
        return instance
    end
    
    local cfg = {}
    
    -- Get main window position for positioning
    local main_window = Library.Holder or Library.MainFrame
    if not main_window then
        warn("[ESP Preview] Could not find main window reference")
        return nil
    end
    
    -- ESP Preview Frame
    local esp_preview = Create("Frame", {
        Parent = Library.Gui,
        Name = "ESPPreview",
        Visible = false, 
        Active = true,
        Position = UDim2.new(0, main_window.AbsolutePosition.X + main_window.AbsoluteSize.X + 8, 0, main_window.AbsolutePosition.Y), 
        BorderColor3 = Color3.fromRGB(60, 60, 60),
        Size = UDim2.new(0, 328, 0, 376),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(56, 56, 56),
        ZIndex = 60
    })
    Library.ThemeObjects[esp_preview] = "Outline"
    
    -- Make draggable
    if Library.MakeDraggable then
        Library.MakeDraggable(esp_preview)
    end
    
    -- Title bar
    local title_bar = Create("Frame", {
        Parent = esp_preview,
        Name = "",
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        Size = UDim2.new(1, 0, 0, 20),
        BorderSizePixel = 0,
        BackgroundColor3 = Library.Theme.Accent,
        ZIndex = 60
    })
    Library.ThemeObjects[title_bar] = "Accent"
    
    local title_text = Create("TextLabel", {
        Parent = title_bar,
        Name = "",
        Font = Enum.Font.Code,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        Text = "ESP Preview",
        TextStrokeTransparency = 0.5,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 61,
        TextSize = 12,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    })
    Library.ThemeObjects[title_text] = "Text"
    
    local separator = Create("Frame", {
        Parent = esp_preview,
        Name = "",
        Position = UDim2.new(0, 0, 0, 20),
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        ZIndex = 60
    })
    
    -- Main container
    local inline = Create("Frame", {
        Parent = esp_preview,
        Name = "",
        Position = UDim2.new(0, 1, 0, 21),
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        Size = UDim2.new(1, -2, 1, -22),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        ZIndex = 60
    })
    Library.ThemeObjects[inline] = "Border"
    
    local main = Create("Frame", {
        Parent = inline,
        Name = "",
        Position = UDim2.new(0, 1, 0, 1),
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(38, 38, 38),
        ZIndex = 60
    })
    Library.ThemeObjects[main] = "Background"
    
    -- Preview area with ViewportFrame
    local preview_area = Create("ViewportFrame", {
        Parent = main,
        Name = "",
        Position = UDim2.new(0, 8, 0, 8),
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        Size = UDim2.new(1, -16, 1, -16),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(22, 22, 22),
        ZIndex = 60,
        CurrentCamera = nil,
        LightColor = Color3.fromRGB(255, 255, 255),
        Ambient = Color3.fromRGB(150, 150, 150)
    })
    
    -- Create camera for viewport
    local viewport_cam = Instance.new("Camera")
    viewport_cam.Parent = preview_area
    preview_area.CurrentCamera = viewport_cam
    
    -- Container for ESP overlays
    local hitpart = Create("Frame", {
        Parent = main,
        Name = "",
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, -50, 0.5, -140),
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        Size = UDim2.new(0, 100, 0, 280),
        BorderSizePixel = 0,
        ZIndex = 65
    })
    
    -- Get player character
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    
    -- Clone character into viewport
    local char_clone
    local function update_character()
        if char_clone then char_clone:Destroy() end
        
        local current_char = player.Character
        if not current_char then return end
        
        char_clone = current_char:Clone()
        
        -- Remove scripts and unnecessary parts
        for _, obj in pairs(char_clone:GetDescendants()) do
            if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                obj:Destroy()
            elseif obj:IsA("Humanoid") then
                obj.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            elseif obj:IsA("Tool") then
                obj:Destroy()
            end
        end
        
        char_clone.Parent = preview_area
        
        -- Position camera
        if char_clone.PrimaryPart then
            local cf = char_clone.PrimaryPart.CFrame
            viewport_cam.CFrame = CFrame.new(cf.Position + Vector3.new(0, 1, 5), cf.Position + Vector3.new(0, 1, 0))
        elseif char_clone:FindFirstChild("HumanoidRootPart") then
            local hrp = char_clone.HumanoidRootPart
            viewport_cam.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 1, 5), hrp.Position + Vector3.new(0, 1, 0))
        end
        
        -- Apply chams if enabled
        if cfg._chams_enabled then
            cfg.preview_chams(true)
        end
    end
    
    update_character()
    
    -- Update on character respawn
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        update_character()
    end)
    
    -- Chams/Glow system for character
    local glow_patterns = {}
    cfg._chams_enabled = false
    
    function cfg._update_chams()
        glow_patterns = {}
        if not char_clone then return end
        
        for _, part in pairs(char_clone:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                -- Clear existing highlights
                for _, child in pairs(part:GetChildren()) do
                    if child:IsA("Highlight") then
                        child:Destroy()
                    end
                end
                
                if cfg._chams_enabled then
                    local highlight = Instance.new("Highlight")
                    highlight.Parent = part
                    highlight.FillColor = Library.Theme.Accent
                    highlight.OutlineColor = Library.Theme.Accent
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    table.insert(glow_patterns, highlight)
                end
            end
        end
    end
    
    -- Bounding box container
    local box_container = Create("Frame", {
        Parent = hitpart,
        Name = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 63,
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    })
    
    local box_outline = Create("Frame", {
        Parent = box_container,
        Name = "",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, -1, 0, -1),
        ZIndex = 63,
        Size = UDim2.new(1, 2, 1, 2),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    })
    
    local box_outline_stroke = Create("UIStroke", {
        Parent = box_outline,
        Name = "",
        Color = Color3.fromRGB(0, 0, 0),
        Thickness = 1
    })
    
    local box_color = Create("UIStroke", {
        Parent = box_container,
        Name = "",
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = 1
    })
    Library.ThemeObjects[box_color] = "Accent"
    
    -- Corner box system
    local corner_box = Create("Frame", {
        Parent = box_container,
        Name = "",
        Visible = false,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 63,
        BorderSizePixel = 0
    })
    
    -- Create corner lines
    local corners = {
        {name = "TopLeft", pos = UDim2.new(0, 0, 0, 0), anchor = Vector2.new(0, 0)},
        {name = "TopRight", pos = UDim2.new(1, 0, 0, 0), anchor = Vector2.new(1, 0)},
        {name = "BottomLeft", pos = UDim2.new(0, 0, 1, 0), anchor = Vector2.new(0, 1)},
        {name = "BottomRight", pos = UDim2.new(1, 0, 1, 0), anchor = Vector2.new(1, 1)}
    }
    
    for _, corner_data in ipairs(corners) do
        -- Horizontal line
        local h_line = Create("Frame", {
            Parent = corner_box,
            Name = corner_data.name .. "H",
            AnchorPoint = corner_data.anchor,
            Position = corner_data.pos,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 63,
            Size = UDim2.new(0.3, 0, 0, 1),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        })
        Library.ThemeObjects[h_line] = "Accent"
        
        -- Vertical line
        local v_line = Create("Frame", {
            Parent = corner_box,
            Name = corner_data.name .. "V",
            AnchorPoint = corner_data.anchor,
            Position = corner_data.pos,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 63,
            Size = UDim2.new(0, 1, 0.3, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        })
        Library.ThemeObjects[v_line] = "Accent"
    end
    
    -- Name label above box
    local name_label = Create("TextLabel", {
        Parent = box_container,
        Name = "",
        Font = Enum.Font.Code,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = "Player",
        TextStrokeTransparency = 0,
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, -4),
        ZIndex = 64,
        TextSize = 12,
        Size = UDim2.new(1, 0, 0, 12)
    })
    Library.ThemeObjects[name_label] = "Text"
    
    -- Health bar
    local health_bar = Create("Frame", {
        Parent = box_container,
        Name = "",
        Position = UDim2.new(0, -8, 0, -2),
        Size = UDim2.new(0, 4, 1, 4),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        ZIndex = 63
    })
    
    local health_fill = Create("Frame", {
        Parent = health_bar,
        Name = "",
        Position = UDim2.new(0, 1, 0, 1),
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        Size = UDim2.new(1, -2, 0.75, -2),
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 1, 1, -1),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(0, 255, 42),
        ZIndex = 63
    })
    
    -- Weapon label
    local weapon_label = Create("TextLabel", {
        Parent = box_container,
        Name = "",
        Font = Enum.Font.Code,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = "AK-47",
        TextStrokeTransparency = 0,
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 1, 4),
        ZIndex = 64,
        TextSize = 12,
        Size = UDim2.new(1, 0, 0, 12)
    })
    Library.ThemeObjects[weapon_label] = "Text"
    
    -- Distance label
    local distance_label = Create("TextLabel", {
        Parent = box_container,
        Name = "",
        Font = Enum.Font.Code,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = "125m",
        TextStrokeTransparency = 0,
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 1, 18),
        ZIndex = 64,
        TextSize = 12,
        Size = UDim2.new(1, 0, 0, 12)
    })
    Library.ThemeObjects[distance_label] = "Text"
    
    -- Configuration functions
    function cfg.preview_chams(bool)
        cfg._chams_enabled = bool
        cfg._update_chams()
    end
    
    function cfg.preview_box(box_type)
        if box_type == "Corner" then
            corner_box.Visible = true
            box_outline_stroke.Enabled = false
            box_outline.Visible = false
            box_color.Enabled = false
        elseif box_type == "2D" then
            corner_box.Visible = false
            box_outline_stroke.Enabled = true
            box_outline.Visible = true
            box_color.Enabled = true
        else
            corner_box.Visible = false
            box_outline_stroke.Enabled = false
            box_outline.Visible = false
            box_color.Enabled = false
        end
    end
    
    function cfg.preview_name(bool)
        name_label.Visible = bool
    end
    
    function cfg.preview_health(bool)
        health_bar.Visible = bool
    end
    
    function cfg.preview_weapon(bool)
        weapon_label.Visible = bool
    end
    
    function cfg.preview_distance(bool)
        distance_label.Visible = bool
    end
    
    -- Register with library
    Library:SetESPPreview(esp_preview)
    
    return {
        Frame = esp_preview,
        Config = cfg,
        Toggle = function(visible)
            esp_preview.Visible = visible
            Library:ToggleESPPreview(visible)
        end
    }
end

return ESPPreview
