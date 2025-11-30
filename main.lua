-- Sirux Client WITH CUSTOM KEYBINDS & KILLAURA
local Sirux = {
    version = "1.2",
    author = "nezox1488"
}

--=== КОНФИГУРАЦИЯ ===--
local Config = {
    theme = {
        name = "Default",
        colors = {
            accent = {0, 200, 255, 255},
            windowBg = {20, 25, 35, 240},
            textPrimary = {255, 255, 255, 255},
            textSecondary = {160, 170, 180, 255},
            buttonBg = {35, 45, 60, 255},
            sliderBg = {30, 40, 55, 255},
            checkboxBg = {40, 50, 65, 255}
        },
        transparency = 0.94
    },
    
    keybinds = {
        aimbot = "X",
        antiAim = "V", 
        esp = "N",
        killaura = "B"
    },
    
    esp = {
        enabled = true,
        showTeam = false,
        box = true,
        healthbar = true,
        name = true,
        distance = true
    },
    
    aimbot = {
        enabled = false,
        ignoreTeam = true,
        fov = 30,
        showFov = true,
        smoothness = 15,
        targetPart = "Head"
    },
    
    antiAim = {
        enabled = false,
        spin = false,
        spinSpeed = 10,
        dodgeBullets = true
    },
    
    killaura = {
        enabled = false,
        range = 20,
        ignoreTeam = true,
        autoShoot = true
    }
}

--=== МОДУЛИ ===--
local Modules = {
    list = {
        {
            name = "ESP",
            category = "Visuals", 
            enabled = true,
            keybind = "N",
            description = "Отображение игроков через стены"
        },
        {
            name = "Aimbot", 
            category = "Player",
            enabled = false,
            keybind = "X",
            description = "Автоматическое прицеливание"
        },
        {
            name = "AntiAim",
            category = "Player",
            enabled = false,
            keybind = "V", 
            description = "Уворот от пуль и спин"
        },
        {
            name = "Killaura",
            category = "Player",
            enabled = false,
            keybind = "B",
            description = "Авто-атака вокруг игрока"
        }
    }
}

--=== ESP ФУНКЦИОНАЛ ===--
local ESP = {
    players = {},
    connections = {}
}

function ESP:init()
    self:updatePlayers()
    
    table.insert(self.connections, game:GetService("Players").PlayerAdded:Connect(function()
        self:updatePlayers()
    end))
    
    table.insert(self.connections, game:GetService("Players").PlayerRemoving:Connect(function()
        self:updatePlayers()
    end))
end

function ESP:updatePlayers()
    self.players = {}
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player ~= game:GetService("Players").LocalPlayer then
            table.insert(self.players, player)
        end
    end
end

function ESP:draw()
    if not Config.esp.enabled then return end
    
    for _, player in pairs(self.players) do
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart") then
            -- Проверка на смерть игрока
            if character.Humanoid.Health <= 0 then
                continue
            end
            
            if not Config.esp.showTeam and player.Team == game:GetService("Players").LocalPlayer.Team then
                continue
            end
            
            local head = character:FindFirstChild("Head")
            local root = character:FindFirstChild("HumanoidRootPart")
            if head and root then
                local headPos, headOnScreen = game:GetService("Workspace").CurrentCamera:WorldToViewportPoint(head.Position)
                local rootPos, rootOnScreen = game:GetService("Workspace").CurrentCamera:WorldToViewportPoint(root.Position)
                
                if headOnScreen then
                    local height = (headPos.Y - rootPos.Y) * 2
                    local width = height / 2
                    
                    if Config.esp.box then
                        self:drawBox(headPos.X, rootPos.Y, width, height, player)
                    end
                    
                    if Config.esp.healthbar then
                        self:drawHealthbar(headPos.X - width/2 - 10, rootPos.Y, height, character.Humanoid.Health, character.Humanoid.MaxHealth)
                    end
                    
                    if Config.esp.name then
                        self:drawText(headPos.X, rootPos.Y - height/2 - 20, player.Name, {255, 255, 255, 255})
                    end
                    
                    if Config.esp.distance then
                        local distance = (game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
                        self:drawText(headPos.X, rootPos.Y + height/2 + 10, math.floor(distance) .. "m", {255, 255, 255, 255})
                    end
                end
            end
        end
    end
end

function ESP:drawBox(x, y, width, height, player)
    local color = player.Team == game:GetService("Players").LocalPlayer.Team and {0, 255, 0, 255} or {255, 0, 0, 255}
    
    drawRect(x - width/2, y, width, height, {0, 0, 0, 150})
    drawRect(x - width/2, y, width, 2, color)
    drawRect(x - width/2, y + height, width, 2, color)
    drawRect(x - width/2, y, 2, height, color)
    drawRect(x + width/2, y, 2, height, color)
end

function ESP:drawHealthbar(x, y, height, health, maxHealth)
    local healthPercent = health / maxHealth
    local barHeight = height * healthPercent
    
    drawRect(x, y, 6, height, {50, 50, 50, 150})
    
    local color
    if healthPercent > 0.6 then
        color = {0, 255, 0, 255}
    elseif healthPercent > 0.3 then
        color = {255, 255, 0, 255}
    else
        color = {255, 0, 0, 255}
    end
    
    drawRect(x, y + (height - barHeight), 6, barHeight, color)
end

function ESP:drawText(x, y, text, color)
    drawText(x, y, text, color, 1)
end

--=== AIMBOT ФУНКЦИОНАЛ ===--
local Aimbot = {
    target = nil,
    fovCircle = nil
}

function Aimbot:findTarget()
    if not Config.aimbot.enabled then return nil end
    
    local closestTarget = nil
    local closestDistance = Config.aimbot.fov
    local localPlayer = game:GetService("Players").LocalPlayer
    local camera = game:GetService("Workspace").CurrentCamera

    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player ~= localPlayer then
            if Config.aimbot.ignoreTeam and player.Team == localPlayer.Team then
                continue
            end
            
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
                -- ПРОВЕРКА НА СМЕРТЬ ИГРОКА
                if character.Humanoid.Health <= 0 then
                    continue
                end
                
                local targetPart = character:FindFirstChild(Config.aimbot.targetPart)
                if targetPart then
                    local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                    
                    if onScreen then
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)).Magnitude
                        
                        if distance < closestDistance then
                            closestDistance = distance
                            closestTarget = player
                        end
                    end
                end
            end
        end
    end
    
    return closestTarget
end

function Aimbot:aimAtTarget()
    if not Config.aimbot.enabled then return end
    
    self.target = self:findTarget()
    
    if self.target and self.target.Character then
        local targetPart = self.target.Character:FindFirstChild(Config.aimbot.targetPart)
        if targetPart then
            local camera = game:GetService("Workspace").CurrentCamera
            local mouse = game:GetService("Players").LocalPlayer:GetMouse()
            
            local screenPos = camera:WorldToViewportPoint(targetPart.Position)
            local targetPos = Vector2.new(screenPos.X, screenPos.Y)
            local currentPos = Vector2.new(mouse.X, mouse.Y)
            
            local smoothFactor = Config.aimbot.smoothness / 100
            local newPos = currentPos:Lerp(targetPos, smoothFactor)
            
            mousemoverel((newPos.X - currentPos.X) * 0.5, (newPos.Y - currentPos.Y) * 0.5)
        end
    end
end

function Aimbot:drawFovCircle()
    if not Config.aimbot.showFov or not Config.aimbot.enabled then return end
    
    local centerX = game:GetService("Workspace").CurrentCamera.ViewportSize.X / 2
    local centerY = game:GetService("Workspace").CurrentCamera.ViewportSize.Y / 2
    local radius = Config.aimbot.fov
    
    drawCircle(centerX, centerY, radius, {255, 255, 255, 100})
end

--=== ANTI AIM ФУНКЦИОНАЛ ===--
local AntiAim = {
    spinAngle = 0,
    lastShotTime = 0
}

function AntiAim:init()
    table.insert(ESP.connections, game:GetService("RunService").RenderStepped:Connect(function()
        self:update()
    end))
end

function AntiAim:update()
    if not Config.antiAim.enabled then return end
    
    local character = game:GetService("Players").LocalPlayer.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    if Config.antiAim.spin then
        self.spinAngle = self.spinAngle + Config.antiAim.spinSpeed
        if self.spinAngle >= 360 then self.spinAngle = 0 end
        
        humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position) * CFrame.Angles(0, math.rad(self.spinAngle), 0)
    end
    
    if Config.antiAim.dodgeBullets then
        self:detectBullets()
    end
end

function AntiAim:detectBullets()
    local currentTime = tick()
    if currentTime - self.lastShotTime < 0.5 then
        self:dodge()
    end
end

function AntiAim:dodge()
    local character = game:GetService("Players").LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local jump = math.random() > 0.5
        local moveX = math.random(-10, 10)
        local moveZ = math.random(-10, 10)
        
        if jump then
            character.Humanoid.Jump = true
        end
        
        character.Humanoid:Move(Vector3.new(moveX, 0, moveZ))
    end
end

--=== KILLAURA ФУНКЦИОНАЛ ===--
local Killaura = {
    lastAttack = 0,
    attackDelay = 0.2
}

function Killaura:findTargetsInRange()
    local targets = {}
    local localPlayer = game:GetService("Players").LocalPlayer
    local localCharacter = localPlayer.Character
    local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    
    if not localRoot then return targets end
    
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player ~= localPlayer then
            if Config.killaura.ignoreTeam and player.Team == localPlayer.Team then
                continue
            end
            
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
                -- ПРОВЕРКА НА СМЕРТЬ
                if character.Humanoid.Health <= 0 then
                    continue
                end
                
                local distance = (localRoot.Position - character.HumanoidRootPart.Position).Magnitude
                if distance <= Config.killaura.range then
                    table.insert(targets, player)
                end
            end
        end
    end
    
    return targets
end

function Killaura:attackTargets()
    if not Config.killaura.enabled then return end
    if tick() - self.lastAttack < self.attackDelay then return end
    
    local targets = self:findTargetsInRange()
    
    if #targets > 0 then
        -- АТАКУЕМ ВСЕХ ИГРОКОВ В РАДИУСЕ
        for _, target in pairs(targets) do
            if Config.killaura.autoShoot then
                -- АВТО-СТРЕЛЬБА (без поворота головы)
                self:simulateAttack(target)
            end
        end
        
        self.lastAttack = tick()
    end
end

function Killaura:simulateAttack(target)
    -- Эмуляция атаки (зависит от игры)
    local localPlayer = game:GetService("Players").LocalPlayer
    local mouse = localPlayer:GetMouse()
    
    -- Можно добавить вызов функции атаки игры здесь
    -- Например: game:GetService("ReplicatedStorage").AttackEvent:FireServer(target)
    
    print("🎯 Killaura атакует: " .. target.Name)
end

function Killaura:update()
    if Config.killaura.enabled then
        self:attackTargets()
    end
end

--=== GUI СИСТЕМА ===--
local GUI = {
    visible = false,
    currentTab = "Visuals", 
    bindingMode = false,
    bindingModule = nil
}

function GUI.draw()
    GUI.drawHUD()
    
    if not GUI.visible then return end
    
    local colors = Config.theme.colors
    
    drawRect(100, 100, 800, 600, colors.windowBg)
    drawText(120, 110, "SIRUX CLIENT", colors.accent, 2)
    drawText(120, 140, "KEYBINDS: X=AIM, V=AA, N=ESP, B=KILLAURA", colors.textSecondary, 0.8)
    
    GUI.drawSidebar()
    GUI.drawContent()
    Aimbot:drawFovCircle()
end

function GUI.drawSidebar()
    local tabs = {"Visuals", "Player", "Movement", "Theme"}
    local startY = 180
    
    for i, tab in ipairs(tabs) do
        local color = (GUI.currentTab == tab) and Config.getColor("accent") or Config.getColor("buttonBg")
        drawRect(120, startY + (i-1)*45, 150, 40, color)
        drawText(140, startY + (i-1)*45 + 12, tab, Config.getColor("textPrimary"), 1)
    end
end

function GUI.drawContent()
    local startX, startY = 290, 180
    
    if GUI.currentTab == "Visuals" then
        GUI.drawVisualsTab(startX, startY)
    elseif GUI.currentTab == "Player" then
        GUI.drawPlayerTab(startX, startY)
    elseif GUI.currentTab == "Theme" then
        GUI.drawThemeTab(startX, startY)
    end
end

function GUI.drawVisualsTab(x, y)
    drawText(x, y, "ESP SETTINGS", Config.getColor("accent"), 1.3)
    
    GUI.drawCheckbox(x, y + 40, "esp_enabled", "Enable ESP [N]", Config.esp.enabled)
    GUI.drawCheckbox(x, y + 70, "esp_team", "Show Team", Config.esp.showTeam)
    GUI.drawCheckbox(x, y + 100, "esp_box", "2D Box", Config.esp.box)
    GUI.drawCheckbox(x, y + 130, "esp_health", "Health Bar", Config.esp.healthbar)
    GUI.drawCheckbox(x, y + 160, "esp_name", "Player Name", Config.esp.name)
    GUI.drawCheckbox(x, y + 190, "esp_distance", "Distance", Config.esp.distance)
end

function GUI.drawPlayerTab(x, y)
    drawText(x, y, "AIMBOT SETTINGS", Config.getColor("accent"), 1.3)
    
    GUI.drawCheckbox(x, y + 40, "aim_enabled", "Enable Aimbot [X]", Config.aimbot.enabled)
    GUI.drawCheckbox(x, y + 70, "aim_team", "Ignore Team", Config.aimbot.ignoreTeam)
    GUI.drawCheckbox(x, y + 100, "aim_fov", "Show FOV Circle", Config.aimbot.showFov)
    
    drawText(x, y + 140, "FOV: " .. Config.aimbot.fov, Config.getColor("textPrimary"), 1)
    drawRect(x, y + 160, 200, 10, Config.getColor("sliderBg"))
    drawRect(x, y + 160, (Config.aimbot.fov / 100) * 200, 10, Config.getColor("accent"))
    
    drawText(x, y + 180, "Smooth: " .. Config.aimbot.smoothness, Config.getColor("textPrimary"), 1)
    drawRect(x, y + 200, 200, 10, Config.getColor("sliderBg"))
    drawRect(x, y + 200, Config.aimbot.smoothness * 2, 10, Config.getColor("accent"))
    
    -- AntiAim настройки
    drawText(x + 300, y, "ANTI AIM SETTINGS", Config.getColor("accent"), 1.3)
    GUI.drawCheckbox(x + 300, y + 40, "aa_enabled", "Enable AntiAim [V]", Config.antiAim.enabled)
    GUI.drawCheckbox(x + 300, y + 70, "aa_spin", "Enable Spin", Config.antiAim.spin)
    GUI.drawCheckbox(x + 300, y + 100, "aa_dodge", "Dodge Bullets", Config.antiAim.dodgeBullets)
    
    drawText(x + 300, y + 140, "Spin Speed: " .. Config.antiAim.spinSpeed, Config.getColor("textPrimary"), 1)
    drawRect(x + 300, y + 160, 200, 10, Config.getColor("sliderBg"))
    drawRect(x + 300, y + 160, Config.antiAim.spinSpeed * 10, 10, Config.getColor("accent"))
    
    -- Killaura настройки
    drawText(x, y + 250, "KILLAURA SETTINGS", Config.getColor("accent"), 1.3)
    GUI.drawCheckbox(x, y + 290, "ka_enabled", "Enable Killaura [B]", Config.killaura.enabled)
    GUI.drawCheckbox(x, y + 320, "ka_team", "Ignore Team", Config.killaura.ignoreTeam)
    GUI.drawCheckbox(x, y + 350, "ka_shoot", "Auto Shoot", Config.killaura.autoShoot)
    
    drawText(x, y + 380, "Range: " .. Config.killaura.range, Config.getColor("textPrimary"), 1)
    drawRect(x, y + 400, 200, 10, Config.getColor("sliderBg"))
    drawRect(x, y + 400, Config.killaura.range * 5, 10, Config.getColor("accent"))
end

function GUI.drawThemeTab(x, y)
    drawText(x, y, "THEME SETTINGS", Config.getColor("accent"), 1.3)
    
    local themes = {"Default", "Dark", "Purple", "Green"}
    for i, theme in ipairs(themes) do
        local btnX = x + (i-1) * 120
        local color = (Config.theme.name == theme) and Config.getColor("accent") or Config.getColor("buttonBg")
        drawRect(btnX, y + 40, 110, 35, color)
        drawText(btnX + 10, y + 48, theme, Config.getColor("textPrimary"), 0.9)
    end
end

function GUI.drawCheckbox(x, y, id, text, state)
    drawRect(x, y, 20, 20, state and Config.getColor("accent") or Config.getColor("checkboxBg"))
    if state then
        drawText(x + 5, y + 2, "✓", Config.getColor("textPrimary"), 1)
    end
    drawText(x + 30, y + 2, text, Config.getColor("textPrimary"), 0.9)
end

function GUI.drawHUD()
    if Config.hud.watermark.enabled then
        drawRect(10, 10, 300, 25, {0, 0, 0, 180})
        local statusText = "Sirux | ESP:" .. (Config.esp.enabled and "ON" or "OFF") .. 
                          " | AIM:" .. (Config.aimbot.enabled and "ON" or "OFF") ..
                          " | AA:" .. (Config.antiAim.enabled and "ON" or "OFF") ..
                          " | KA:" .. (Config.killaura.enabled and "ON" or "OFF")
        drawText(15, 15, statusText, {255, 255, 255, 255}, 0.8)
    end
end

--=== ОБРАБОТКА КЛАВИШ ===--
function GUI.handleKeyPress(key)
    -- Бинды включаются/выключаются по нажатию клавиш
    if key == Config.keybinds.aimbot then
        Config.aimbot.enabled = not Config.aimbot.enabled
        print("🎯 Aimbot: " .. (Config.aimbot.enabled and "ON" or "OFF"))
        
    elseif key == Config.keybinds.antiAim then
        Config.antiAim.enabled = not Config.antiAim.enabled
        print("🛡️ AntiAim: " .. (Config.antiAim.enabled and "ON" or "OFF"))
        
    elseif key == Config.keybinds.esp then
        Config.esp.enabled = not Config.esp.enabled
        print("👁️ ESP: " .. (Config.esp.enabled and "ON" or "OFF"))
        
    elseif key == Config.keybinds.killaura then
        Config.killaura.enabled = not Config.killaura.enabled
        print("⚔️ Killaura: " .. (Config.killaura.enabled and "ON" or "OFF"))
        
    elseif key == "Insert" then
        GUI.visible = not GUI.visible
        print("🎮 GUI: " .. (GUI.visible and "OPEN" or "CLOSED"))
    end
end

function GUI.handleClick(x, y)
    if not GUI.visible then return end
    
    local tabs = {"Visuals", "Player", "Movement", "Theme"}
    local startY = 180
    
    for i, tab in ipairs(tabs) do
        if x >= 120 and x <= 270 and y >= startY + (i-1)*45 and y <= startY + (i-1)*45 + 40 then
            GUI.currentTab = tab
            return
        end
    end
    
    if GUI.currentTab == "Visuals" then
        GUI.handleVisualsClick(x, y)
    elseif GUI.currentTab == "Player" then
        GUI.handlePlayerClick(x, y)
    elseif GUI.currentTab == "Theme" then
        GUI.handleThemeClick(x, y)
    end
end

function GUI.handleVisualsClick(x, y)
    local startX, startY = 290, 180
    
    if x >= startX and x <= startX + 20 and y >= startY + 40 and y <= startY + 60 then
        Config.esp.enabled = not Config.esp.enabled
    elseif x >= startX and x <= startX + 20 and y >= startY + 70 and y <= startY + 90 then
        Config.esp.showTeam = not Config.esp.showTeam
    end
end

function GUI.handlePlayerClick(x, y)
    local startX, startY = 290, 180
    
    -- Aimbot
    if x >= startX and x <= startX + 20 and y >= startY + 40 and y <= startY + 60 then
        Config.aimbot.enabled = not Config.aimbot.enabled
    elseif x >= startX and x <= startX + 20 and y >= startY + 70 and y <= startY + 90 then
        Config.aimbot.ignoreTeam = not Config.aimbot.ignoreTeam
        
    -- AntiAim  
    elseif x >= startX + 300 and x <= startX + 320 and y >= startY + 40 and y <= startY + 60 then
        Config.antiAim.enabled = not Config.antiAim.enabled
        
    -- Killaura
    elseif x >= startX and x <= startX + 20 and y >= startY + 290 and y <= startY + 310 then
        Config.killaura.enabled = not Config.killaura.enabled
    elseif x >= startX and x <= startX + 20 and y >= startY + 320 and y <= startY + 340 then
        Config.killaura.ignoreTeam = not Config.killaura.ignoreTeam
    end
    
    -- Слайдеры
    if x >= startX and x <= startX + 200 and y >= startY + 160 and y <= startY + 170 then
        Config.aimbot.fov = math.floor(((x - startX) / 200) * 100)
    elseif x >= startX and x <= startX + 200 and y >= startY + 200 and y <= startY + 210 then
        Config.aimbot.smoothness = math.floor(((x - startX) / 200) * 50)
    elseif x >= startX + 300 and x <= startX + 500 and y >= startY + 160 and y <= startY + 170 then
        Config.antiAim.spinSpeed = math.floor(((x - startX - 300) / 200) * 20)
    elseif x >= startX and x <= startX + 200 and y >= startY + 400 and y <= startY + 410 then
        Config.killaura.range = math.floor(((x - startX) / 200) * 40)
    end
end

function GUI.handleThemeClick(x, y)
    local startX, startY = 290, 180
    local themes = {"Default", "Dark", "Purple", "Green"}
    
    for i, theme in ipairs(themes) do
        local btnX = startX + (i-1) * 120
        if x >= btnX and x <= btnX + 110 and y >= startY + 40 and y <= startY + 75 then
            Config.theme.name = theme
            return
        end
    end
end

--=== ОСНОВНОЙ ЦИКЛ ===--
function Sirux:init()
    print("🚀 Sirux Client Loading...")
    print("🎯 Features: ESP, Aimbot, AntiAim, Killaura")
    print("⌨️ Keybinds: X=Aim, V=AntiAim, N=ESP, B=Killaura, INSERT=GUI")
    
    ESP:init()
    AntiAim:init()
    
    -- Обработка клавиш
    game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Insert then
            GUI.visible = not GUI.visible
        else
            local key = input.KeyCode.Name
            GUI.handleKeyPress(key)
        end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            GUI.handleClick(input.Position.X, input.Position.Y)
        end
    end)
    
    -- Главный цикл
    game:GetService("RunService").RenderStepped:Connect(function()
        GUI.draw()
        ESP:draw()
        
        if Config.aimbot.enabled then
            Aimbot:aimAtTarget()
        end
        
        Killaura:update()
    end)
    
    print("✅ Sirux Client Ready!")
end

-- ЗАПУСК
Sirux:init()
