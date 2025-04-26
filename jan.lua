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

-- ปรับขนาดและตำแหน่งของ UI ให้ติดขอบซ้ายมากขึ้น
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 150, 0, 170)  -- ขนาดของ UI โดยใช้ offset
frame.Position = UDim2.new(0, 20, 0.25, 0)  -- ใช้ scale สำหรับตำแหน่งที่ติดขอบซ้าย (X = 0) และ Y ใช้ scale สำหรับตั้งระยะจากขอบบน
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
toggleBtn.Size = UDim2.new(0, 140, 0, 27)  -- ขนาดปุ่ม
toggleBtn.Position = UDim2.new(0.05, 0, 0.05, 0)  -- ใช้ scale สำหรับตำแหน่ง
toggleBtn.Text = "FOV: OFF"
styleButton(toggleBtn)
toggleBtn.TextSize = 12

local sizeLabel = Instance.new("TextLabel", frame)
sizeLabel.Size = UDim2.new(0, 50, 0, 10)
sizeLabel.Position = UDim2.new(0.05, 0, 0.25, 0)
sizeLabel.Text = "Radius: " .. fovRadius
sizeLabel.BackgroundTransparency = 1
sizeLabel.TextColor3 = Color3.new(1, 1, 1)
sizeLabel.Font = Enum.Font.SourceSans
sizeLabel.TextSize = 12

local plusBtn = Instance.new("TextButton", frame)
plusBtn.Size = UDim2.new(0, 16, 0, 16)
plusBtn.Position = UDim2.new(0.55, 0, 0.25, 0)  -- ตำแหน่ง relative กับ frame
plusBtn.Text = "+"
styleButton(plusBtn)
plusBtn.TextSize = 14

local minusBtn = Instance.new("TextButton", frame)
minusBtn.Size = UDim2.new(0, 18, 0, 18)
minusBtn.Position = UDim2.new(0.70, 0, 0.25, 0)
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

--// FUNCTION: Lock Target
local function getClosestVisiblePlayer()
	local closestPlayer = nil
	local closestDist = fovRadius
	local maxLockDistance = 150

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
			local head = player.Character.Head
			local headPos = head.Position
			local screenPoint, onScreen = camera:WorldToViewportPoint(headPos)
			local distanceToPlayer = (headPos - camera.CFrame.Position).Magnitude

			if onScreen and distanceToPlayer <= maxLockDistance then
				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Blacklist
				rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
				rayParams.IgnoreWater = true

				local rayResult = workspace:Raycast(camera.CFrame.Position, (headPos - camera.CFrame.Position).Unit * distanceToPlayer, rayParams)

				if not rayResult or rayResult.Instance:IsDescendantOf(player.Character) then
					local distOnScreen = (Vector2.new(screenPoint.X, screenPoint.Y) - Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)).Magnitude
					if distOnScreen < closestDist then
						closestDist = distOnScreen
						closestPlayer = player
					end
				end
			end
		end
	end

	return closestPlayer
end

--// MAIN LOOP
RunService.RenderStepped:Connect(function()
	local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	fovCircle.Position = center
	fovCircle.Radius = fovRadius

	if fovEnabled then
		local target = getClosestVisiblePlayer()
		if target and target.Character and target.Character:FindFirstChild("Head") then
			local targetPos = target.Character.Head.Position
			local camPos = camera.CFrame.Position
			local direction = (targetPos - camPos).Unit
			camera.CFrame = CFrame.new(camPos, camPos + direction)
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.B then
		fovEnabled = not fovEnabled
		toggleBtn.Text = fovEnabled and "FOV: ON" or "FOV: OFF"
		fovCircle.Visible = fovEnabled
	end
end)

--// UI Toggle
local uiVisible = true
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.M then
		uiVisible = not uiVisible
		screenGui.Enabled = uiVisible
	end
end)

--// ATTRIBUTE TOGGLE UI
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
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggleButton = Instance.new("TextButton", rowFrame)
    toggleButton.Size = UDim2.new(0, 25, 0, 25)
    toggleButton.Position = UDim2.new(1, -80, 0.5, -20)
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
recoilRow.Position = UDim2.new(0, 10, 0, 70)
recoilRow.Parent = frame

local reloadRow = createGunToggleRow("Reload", reloadState, function(state)
	setGunAttribute("ReloadTime", state and 2 or 0)
end)
reloadRow.Position = UDim2.new(0, 10, 0, 105)
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

local function setESPEnabled(state)
    LocalPlayer:SetAttribute("ESPEnabled", state)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if state then
                CreateESP(player)
            else
                RemoveESP(player)
            end
        end
    end
end

-- Create the ESP toggle row
local espRow = createGunToggleRow("ESP", espState, setESPEnabled)
espRow.Position = UDim2.new(0, 10, 0, 140)
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
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.N then
        espState = not espState
        setESPEnabled(espState)
        
        -- Update the ESP button to show "●" or empty text
        espRow:FindFirstChildOfClass("TextButton").Text = espState and "●" or ""
    end
end)

--// Close the script when the "Delete" key is pressed
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Delete then
        -- Disable the entire script
        screenGui:Destroy()
        fovCircle:Remove()
    end
end)

local toggleImageBtn = Instance.new("ImageButton", screenGui)
toggleImageBtn.Size = UDim2.new(0, 30, 0, 30)  -- ขนาดเหมือนเดิม
toggleImageBtn.Position = UDim2.new(0, 20, 0, 20)  -- ตำแหน่งเหมือนเดิม
toggleImageBtn.Image = "rbxassetid://118284077656202"  -- ใช้ Asset ID ที่คุณอัปโหลด
toggleImageBtn.BackgroundTransparency = 1  -- ลบพื้นหลังออก

-- เอาความโปร่งใสออกจากรูปภาพ
toggleImageBtn.ImageTransparency = 0  -- 0 คือไม่โปร่งใส

-- เพิ่มกรอบสีดำรอบรูปภาพ
toggleImageBtn.BorderSizePixel = 2  -- ขนาดของกรอบ
toggleImageBtn.BorderColor3 = Color3.fromRGB(0, 0, 0)  -- สีกรอบเป็นสีดำ

-- เพิ่มขอบโค้งให้กับปุ่ม
local corner = Instance.new("UICorner", toggleImageBtn)
corner.CornerRadius = UDim.new(0, 6)  -- ขอบโค้ง

-- ตัวแปรเพื่อเก็บสถานะการแสดงผลของ UI
local uiVisible = true

-- ฟังก์ชั่นที่ทำให้ UI ซ่อนและแสดง
local function toggleUI()
    uiVisible = not uiVisible
    frame.Visible = uiVisible  -- ซ่อนหรือแสดง UI หลัก
    newFrame.Visible = uiVisible  -- ซ่อนหรือแสดง UI ใหม่
end

-- เชื่อมโยงฟังก์ชั่นกับการกดปุ่มภาพ
toggleImageBtn.MouseButton1Click:Connect(toggleUI)
