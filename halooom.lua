--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

--// VARIABLES
local fovEnabled = false
local fovRadius = 150
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Color = Color3.fromRGB(0, 255, 0)
fovCircle.Thickness = 1
fovCircle.NumSides = 64
fovCircle.Filled = false

--// UI SETUP
local screenGui = Instance.new("ScreenGui", game.CoreGui)
screenGui.Name = "FOV_UI"

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 200, 0, 220)
frame.Position = UDim2.new(0, 20, 0, 370)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0

-- Styling
local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(70, 70, 70)
stroke.Thickness = 1.2
stroke.Transparency = 0.3

local function styleButton(btn)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.BorderSizePixel = 0

    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 6)
end

local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.new(0, 180, 0, 30)
toggleBtn.Position = UDim2.new(0, 10, 0, 10)
toggleBtn.Text = "FOV: OFF"
styleButton(toggleBtn)
toggleBtn.TextSize = 14

local sizeLabel = Instance.new("TextLabel", frame)
sizeLabel.Size = UDim2.new(0, 80, 0, 20)
sizeLabel.Position = UDim2.new(0, 10, 0, 50)
sizeLabel.Text = "Radius: " .. fovRadius
sizeLabel.BackgroundTransparency = 1
sizeLabel.TextColor3 = Color3.new(1, 1, 1)
sizeLabel.Font = Enum.Font.SourceSans
sizeLabel.TextSize = 14

local plusBtn = Instance.new("TextButton", frame)
plusBtn.Size = UDim2.new(0, 20, 0, 20)
plusBtn.Position = UDim2.new(0, 100, 0, 50)
plusBtn.Text = "+"
styleButton(plusBtn)
plusBtn.TextSize = 14

local minusBtn = Instance.new("TextButton", frame)
minusBtn.Size = UDim2.new(0, 20, 0, 20)
minusBtn.Position = UDim2.new(0, 125, 0, 50)
minusBtn.Text = "-"
styleButton(minusBtn)
minusBtn.TextSize = 14

--// BUTTON FUNCTIONS
toggleBtn.MouseButton1Click:Connect(function()
    fovEnabled = not fovEnabled
    toggleBtn.Text = fovEnabled and "FOV: ON" or "FOV: OFF"
    fovCircle.Visible = fovEnabled
end)

plusBtn.MouseButton1Click:Connect(function()
    fovRadius = math.clamp(fovRadius + 10, 50, 400)
    sizeLabel.Text = "Radius: " .. fovRadius
    fovCircle.Radius = fovRadius
end)

minusBtn.MouseButton1Click:Connect(function()
    fovRadius = math.clamp(fovRadius - 10, 50, 400)
    sizeLabel.Text = "Radius: " .. fovRadius
    fovCircle.Radius = fovRadius
end)

--// TARGET FUNCTION - GET CLOSEST ENEMY (UPDATED)
local function getClosestEnemy()
    local closestPlayer = nil
    local shortestDistance = fovRadius
    local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            for _, part in ipairs(player.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end

    if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("Head") then
        return closestPlayer.Character.Head
    end
    return nil
end

local function getClosestEnemyHead()
    local closest = nil
    local shortest = math.huge
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                if distance < fovRadius and distance < shortest then  -- ตรวจสอบว่าอยู่ภายในวง FOV
                    shortest = distance
                    closest = head
                end
            end
        end
    end

    return closest
end

--// OVERRIDE GUN SYSTEM
local GunModule = require(game:GetService("ReplicatedStorage").Modules.Game.ItemTypes.Gun)
local OriginalCalculateBullet = GunModule.calculate_bullet_direction

GunModule.calculate_bullet_direction = function(self, lookVector)
    if fovEnabled then
        local target = getClosestEnemyHead()
        if target then
            local origin = camera.CFrame.Position
            local targetPos = target.Position
            local targetVel = target.Velocity
            local bulletSpeed = 9999 -- หรือดึงจาก tool:GetAttribute("BulletSpeed")

            local distance = (targetPos - origin).Magnitude
            local timeToTarget = distance / bulletSpeed
            local predictedPosition = targetPos + targetVel * timeToTarget

            return (predictedPosition - origin).Unit
        end
    end
    return OriginalCalculateBullet(self, lookVector)
end


-- OVERRIDE calculate_bullet_direction
local OriginalCalculateBullet = GunModule.calculate_bullet_direction
GunModule.calculate_bullet_direction = function(self, lookVector)
    if fovEnabled then
        local target = getClosestEnemyHead()
        if target then
            return (target.Position - camera.CFrame.Position).Unit
        end
    end
    return OriginalCalculateBullet(self, lookVector)
end

-- OVERRIDE gunshot FOR INSTANT HIT
local OriginalGunshot = GunModule.gunshot
GunModule.gunshot = function(tool, hitPos, normal, part)
    if fovEnabled then
        local target = getClosestEnemyHead()
        if target then
            local hitPosition = target.Position
            local normalVec = Vector3.new(0, 1, 0)
            local dummyPart = target
            print("[INSTANT HIT] Trigger gunshot on:", target.Parent.Name)

            OriginalGunshot(tool, hitPosition, normalVec, dummyPart)
            return
        end
    end
    OriginalGunshot(tool, hitPos, normal, part)
end

--// MAIN LOOP
RunService.RenderStepped:Connect(function()
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    fovCircle.Position = center
    fovCircle.Radius = fovRadius
end)

-- Instant Bullet System Loop
task.spawn(function()
    while true do
        if fovEnabled then
            GunModule.calculate_bullet_direction = function(self, lookVector)
                local target = getClosestEnemyHead()
                if target then
                    local origin = camera.CFrame.Position
                    print("[INSTANT BULLET] Locking onto:", target.Parent.Name)
                    return (target.Position - origin).Unit
                end
                return lookVector
            end
        else
            GunModule.calculate_bullet_direction = OriginalCalculateBullet
        end
        task.wait(0.2)
    end
end)

--// DELETE TO CLOSE SCRIPT

-- Create the Toggle Row for Gun Settings
local function createGunToggleRow(labelText, defaultState, callback)
    local rowFrame = Instance.new("Frame")
    rowFrame.Size = UDim2.new(0, 180, 0, 30)
    rowFrame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", rowFrame)
    label.Size = UDim2.new(0, 120, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Text = labelText
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggleButton = Instance.new("TextButton", rowFrame)
    toggleButton.Size = UDim2.new(0, 25, 0, 25)
    toggleButton.Position = UDim2.new(1, -35, 0.5, -12)
    styleButton(toggleButton)
    toggleButton.TextSize = 20
    toggleButton.Text = ""  -- Start with empty text

    local state = defaultState
    toggleButton.MouseButton1Click:Connect(function()
        state = not state
        toggleButton.Text = state and "" or "●"  -- Toggle between empty and filled circle
        callback(state)
        LocalPlayer:SetAttribute(labelText .. "Enabled", state)
    end)

    LocalPlayer:SetAttribute(labelText .. "Enabled", defaultState)

    return rowFrame
end

-- Gun Toggles
local recoilState = LocalPlayer:GetAttribute("RecoilEnabled") or true
local reloadState = LocalPlayer:GetAttribute("ReloadEnabled") or true

local function setGunAttribute(attrName, value)
    task.spawn(function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local tool
        for i = 1, 30 do
            tool = char:FindFirstChildOfClass("Tool")
            if tool then break end
            task.wait(0.1)
        end
        if tool and tool:GetAttribute(attrName) ~= nil then
            tool:SetAttribute(attrName, value)
        end
    end)
end

local recoilRow = createGunToggleRow("Recoil", recoilState, function(state)
    setGunAttribute("Recoil", state and 1 or 0)
end)
recoilRow.Position = UDim2.new(0, 10, 0, 90)
recoilRow.Parent = frame

local reloadRow = createGunToggleRow("Reload", reloadState, function(state)
    setGunAttribute("ReloadTime", state and 2 or 0)
end)
reloadRow.Position = UDim2.new(0, 10, 0, 130)
reloadRow.Parent = frame

-- ESP Toggle Row
local espBoxes = {}
local nameTags = {}
local espState = LocalPlayer:GetAttribute("ESPEnabled") or false  -- Make sure it starts as false by default

local function CreateESP(player)
    if player == LocalPlayer or espBoxes[player] or not player.Character then return end

    -- Create highlight for ESP
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Adornee = player.Character
    highlight.Parent = player.Character
    espBoxes[player] = highlight

    -- Create name tag above player
    local head = player.Character:FindFirstChild("Head")
    if head then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_NameTag"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = player.Name
        label.TextColor3 = Color3.fromRGB(255, 255, 0)
        label.TextSize = 12
        label.Font = Enum.Font.GothamSemibold
        label.TextStrokeTransparency = 0.6
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.Parent = billboard

        nameTags[player] = billboard
    end
end

local function RemoveESP(player)
    if espBoxes[player] then
        espBoxes[player]:Destroy()
        espBoxes[player] = nil
    end
    if nameTags[player] then
        nameTags[player]:Destroy()
        nameTags[player] = nil
    end
end

local espLoopActive = false
local espLoopThread = nil

local function setESPEnabled(state)
    LocalPlayer:SetAttribute("ESPEnabled", state)

    if state then
        espLoopActive = true
        print("[ESP] เปิดใช้งาน ESP")
        if not espLoopThread then
            espLoopThread = task.spawn(function()
                print("[ESP] เริ่มลูป ESP แล้ว")

                while espLoopActive do
                    print("[ESP] ลูปล่าสุด: ตรวจสอบผู้เล่น...")
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then
                            local char = player.Character
                            if char then
                                if not espBoxes[player] then
                                    print("[ESP] สร้าง ESP ให้กับ:", player.Name)
                                    CreateESP(player)
                                elseif espBoxes[player].Adornee ~= char then
                                    print("[ESP] รีเซ็ต ESP ให้กับ:", player.Name)
                                    RemoveESP(player)
                                    CreateESP(player)
                                end
                            end
                        end
                    end
                    task.wait(1)
                end

                print("[ESP] หยุดลูป ESP แล้ว")
                espLoopThread = nil
            end)
        end
    else
        espLoopActive = false
        print("[ESP] ปิดใช้งาน ESP - ลบ ESP ทั้งหมด")
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                RemoveESP(player)
            end
        end
    end
end


-- Create the ESP toggle row
local espRow = createGunToggleRow("ESP", espState, setESPEnabled)
espRow.Position = UDim2.new(0, 10, 0, 170)
espRow.Parent = frame

-- Update when a new player joins
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if LocalPlayer:GetAttribute("ESPEnabled") then
            task.wait(1)
            CreateESP(player)
        end
    end)
end)

-- Remove ESP when a player leaves
Players.PlayerRemoving:Connect(RemoveESP)

--// Toggle ESP UI with N key
espRow.Position = UDim2.new(0, 10, 0, 170)
espRow.Parent = frame

task.spawn(function()
	while true do
		local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local tool = char:FindFirstChildOfClass("Tool")

		if tool then
			pcall(function()
				-- ✅ Force BulletSpeed (ทำให้กระสุนเร็วสุด)
				if tool:GetAttribute("BulletSpeed") == nil or tool:GetAttribute("BulletSpeed") < 9999 then
					tool:SetAttribute("BulletSpeed", 9999)
					print("[FORCE] BulletSpeed set to 9999 for", tool.Name)
				end

				-- ✅ Force ReloadTime (ยิงได้ต่อเนื่อง)
				if tool:GetAttribute("ReloadTime") ~= 0 then
					tool:SetAttribute("ReloadTime", 0)
					print("[FORCE] ReloadTime set to 0 for", tool.Name)
				end

				-- ✅ Force Recoil (ไม่มีเด้ง)
				if tool:GetAttribute("Recoil") ~= 0 then
					tool:SetAttribute("Recoil", 0)
					print("[FORCE] Recoil set to 0 for", tool.Name)
				end

				-- ✅ Force Range และ MaxDistance (ยิงได้ไกลมาก)
				if tool:GetAttribute("Range") ~= 9999 then
					tool:SetAttribute("Range", 9999)
					print("[FORCE] Range set to 9999 for", tool.Name)
				end
				if tool:GetAttribute("MaxDistance") ~= 9999 then
					tool:SetAttribute("MaxDistance", 9999)
					print("[FORCE] MaxDistance set to 9999 for", tool.Name)
				end
			end)
		end

		task.wait(0.5) -- ตรวจสอบทุกครึ่งวินาที
	end
end)



local function toggleGunRowState(attrName)
    local currentState = LocalPlayer:GetAttribute(attrName .. "Enabled")
    local newState = not currentState
    LocalPlayer:SetAttribute(attrName .. "Enabled", newState)

    -- เรียก callback ของ toggle จริง
    if attrName == "ESP" then
        setESPEnabled(newState)
    elseif attrName == "Recoil" then
        setGunAttribute("Recoil", newState and 1 or 0)
    elseif attrName == "Reload" then
        setGunAttribute("ReloadTime", newState and 2 or 0)
    end

    -- อัปเดตปุ่ม UI
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("Frame") and child:FindFirstChildWhichIsA("TextButton") then
            local label = child:FindFirstChildWhichIsA("TextLabel")
            local btn = child:FindFirstChildWhichIsA("TextButton")
            if label and label.Text == attrName then
                btn.Text = newState and "●" or ""  -- Update button text for ESP, Recoil, Reload
            end
        end
    end
end


UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    local key = input.KeyCode

    if key == Enum.KeyCode.Delete then
        screenGui:Destroy()
        fovCircle:Remove()

    elseif key == Enum.KeyCode.N then
        toggleGunRowState("ESP")  -- เรียกใช้งาน toggleGunRowState ที่นี่

    elseif key == Enum.KeyCode.M then
        screenGui.Enabled = not screenGui.Enabled

    elseif key == Enum.KeyCode.B then
        fovEnabled = not fovEnabled
        toggleBtn.Text = fovEnabled and "FOV: ON" or "FOV: OFF"
        fovCircle.Visible = fovEnabled
    end
end) 
