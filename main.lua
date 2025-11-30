-- Sirux Client MINIMAL - С кругом FOV
local Sirux = {
    version = "1.2", 
    author = "nezox1488"
}

--=== КОНФИГУРАЦИЯ ===--
local Config = {
    keybinds = {
        aimbot = "X",
        antiAim = "V", 
        esp = "N",
        killaura = "B"
    },
    
    esp = {
        enabled = true,
        showTeam = false
    },
    
    aimbot = {
        enabled = false,
        ignoreTeam = true,
        fov = 50,
        showFov = true  -- Добавил включение/выключение круга
    },
    
    antiAim = {
        enabled = false,
        spin = false,
        spinSpeed = 10
    },
    
    killaura = {
        enabled = false,
        range = 20,
        ignoreTeam = true
    }
}

--=== ESP ФУНКЦИОНАЛ ===--
local ESP = {
    players = {},
    connections = {}
}

function ESP:init()
    self:updatePlayers()
    
    self.connections.playerAdded = game:GetService("Players").PlayerAdded:Connect(function()
        self:updatePlayers()
    end)
    
    self.connections.playerRemoving = game:GetService("Players").PlayerRemoving:Connect(function()
        self:updatePlayers()
    end)
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
            if character.Humanoid.Health <= 0 then continue end
            if not Config.esp.showTeam and player.Team == game:GetService("Players").LocalPlayer.Team then continue end
            
            -- Здесь будет отрисовка ESP
        end
    end
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
            if Config.aimbot.ignoreTeam and player.Team == localPlayer.Team then continue end
            
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
                if character.Humanoid.Health <= 0 then continue end
                
                local targetPart = character:FindFirstChild("Head")
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
        local targetPart = self.target.Character:FindFirstChild("Head")
        if targetPart then
            local camera = game:GetService("Workspace").CurrentCamera
            local mouse = game:GetService("Players").LocalPlayer:GetMouse()
            
            local screenPos = camera:WorldToViewportPoint(targetPart.Position)
            local targetPos = Vector2.new(screenPos.X, screenPos.Y)
            local currentPos = Vector2.new(mouse.X, mouse.Y)
            
            mousemoverel((targetPos.X - currentPos.X) * 0.5, (targetPos.Y - currentPos.Y) * 0.5)
        end
    end
end

-- ФУНКЦИЯ ОТРИСОВКИ КРУГА FOV
function Aimbot:drawFovCircle()
    if not Config.aimbot.showFov or not Config.aimbot.enabled then return end
    
    local camera = game:GetService("Workspace").CurrentCamera
    local centerX = camera.ViewportSize.X / 2
    local centerY = camera.ViewportSize.Y / 2
    local radius = Config.aimbot.fov
    
    -- Отрисовка круга FOV
    if drawing then
        -- Для эксплойтов с drawing library
        if not self.fovCircle then
            self.fovCircle = drawing.new("Circle")
            self.fovCircle.Visible = true
            self.fovCircle.Thickness = 1
            self.fovCircle.Filled = false
        end
        
        self.fovCircle.Position = Vector2.new(centerX, centerY)
        self.fovCircle.Radius = radius
        self.fovCircle.Color = Color3.fromRGB(255, 255, 255)
        self.fovCircle.Transparency = 0.5
        
    else
        -- Альтернативный метод отрисовки
        for i = 1, 360, 5 do
            local angle = math.rad(i)
            local x = centerX + math.cos(angle) * radius
            local y = centerY + math.sin(angle) * radius
            local nextAngle = math.rad(i + 5)
            local nextX = centerX + math.cos(nextAngle) * radius
            local nextY = centerY + math.sin(nextAngle) * radius
            
            -- Здесь можно использовать любую доступную функцию отрисовки линии
            -- drawLine(x, y, nextX, nextY, {255, 255, 255, 128})
        end
    end
end

-- ФУНКЦИЯ СКРЫТИЯ КРУГА FOV
function Aimbot:hideFovCircle()
    if self.fovCircle then
        self.fovCircle.Visible = false
        self.fovCircle:Remove()
        self.fovCircle = nil
    end
end

--=== ANTI AIM ФУНКЦИОНАЛ ===--
local AntiAim = {
    spinAngle = 0
}

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
            if Config.killaura.ignoreTeam and player.Team == localPlayer.Team then continue end
            
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
                if character.Humanoid.Health <= 0 then continue end
                
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
        for _, target in pairs(targets) do
            self:simulateAttack(target)
        end
        
        self.lastAttack = tick()
    end
end

function Killaura:simulateAttack(target)
    print("⚔️ Killaura атакует: " .. target.Name)
    -- game:GetService("ReplicatedStorage").DamageEvent:FireServer(target, damage)
end

function Killaura:update()
    if Config.killaura.enabled then
        self:attackTargets()
    end
end

--=== ОБРАБОТКА БИНДОВ ===--
local function handleKeyPress(key)
    -- Aimbot бинд
    if key == Config.keybinds.aimbot then
        Config.aimbot.enabled = not Config.aimbot.enabled
        
        if Config.aimbot.enabled then
            print("🎯 Aimbot: ВКЛ (FOV: " .. Config.aimbot.fov .. ")")
        else
            print("🎯 Aimbot: ВЫКЛ")
            Aimbot:hideFovCircle() -- Скрываем круг при выключении
        end
        
    -- AntiAim бинд
    elseif key == Config.keybinds.antiAim then
        Config.antiAim.enabled = not Config.antiAim.enabled
        print("🛡️ AntiAim: " .. (Config.antiAim.enabled and "ВКЛ" or "ВЫКЛ"))
        
    -- ESP бинд
    elseif key == Config.keybinds.esp then
        Config.esp.enabled = not Config.esp.enabled
        print("👁️ ESP: " .. (Config.esp.enabled and "ВКЛ" or "ВЫКЛ"))
        
    -- Killaura бинд
    elseif key == Config.keybinds.killaura then
        Config.killaura.enabled = not Config.killaura.enabled
        print("⚔️ Killaura: " .. (Config.killaura.enabled and "ВКЛ" or "ВЫКЛ"))
        
    -- Дополнительные бинды для FOV
    elseif key == "RightBracket" then  -- Клавиша ]
        Config.aimbot.fov = Config.aimbot.fov + 5
        print("🎯 FOV увеличен: " .. Config.aimbot.fov)
        
    elseif key == "LeftBracket" then   -- Клавиша [
        Config.aimbot.fov = math.max(10, Config.aimbot.fov - 5)
        print("🎯 FOV уменьшен: " .. Config.aimbot.fov)
        
    elseif key == "P" then  -- Вкл/выкл отображение круга
        Config.aimbot.showFov = not Config.aimbot.showFov
        if not Config.aimbot.showFov then
            Aimbot:hideFovCircle()
        end
        print("⭕ FOV круг: " .. (Config.aimbot.showFov and "ВКЛ" or "ВЫКЛ"))
    end
end

--=== ИНИЦИАЛИЗАЦИЯ ===--
function Sirux:init()
    print("🚀 Sirux Client Загружен!")
    print("🎯 Функции: ESP, Aimbot, AntiAim, Killaura")
    print("⌨️ Основные бинды:")
    print("   X = Aimbot вкл/выкл")
    print("   V = AntiAim вкл/выкл") 
    print("   N = ESP вкл/выкл")
    print("   B = Killaura вкл/выкл")
    print("⌨️ Дополнительные бинды:")
    print("   [ = Уменьшить FOV")
    print("   ] = Увеличить FOV")
    print("   P = Показать/скрыть круг FOV")
    
    -- Инициализация систем
    ESP:init()
    
    -- Обработка клавиш
    game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.KeyCode then
            local key = input.KeyCode.Name
            handleKeyPress(key)
        end
    end)
    
    -- Главный цикл
    game:GetService("RunService").RenderStepped:Connect(function()
        -- ESP отрисовка
        ESP:draw()
        
        -- Aimbot логика
        if Config.aimbot.enabled then
            Aimbot:aimAtTarget()
        end
        
        -- Отрисовка круга FOV
        Aimbot:drawFovCircle()
        
        -- AntiAim логика
        AntiAim:update()
        
        -- Killaura логика
        Killaura:update()
    end)
    
    print("✅ Sirux Client Готов к работе!")
end

-- АВТОМАТИЧЕСКИЙ ЗАПУСК
Sirux:init()

return Sirux
