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
frame.Size = UDim2.new(0.14, 0, 0.28, 0)  -- ขนาด UI จะเป็นสัดส่วนของหน้าจอ
frame.Position = UDim2.new(0.02, 0, 0.35, 0)
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
toggleBtn.Size = UDim2.new(0.85, 0, 0.12, 0)  -- ปรับขนาดให้เป็นสัดส่วนของหน้าจอ
toggleBtn.Position = UDim2.new(0.075, 0, 0.06, 0)
toggleBtn.Text = "FOV: OFF"
styleButton(toggleBtn)
toggleBtn.TextSize = 14

local sizeLabel = Instance.new("TextLabel", frame)
sizeLabel.Size = UDim2.new(0.55, 0, 0.075, 0)
sizeLabel.Position = UDim2.new(0.075, 0, 0.19, 0)
sizeLabel.Text = "Radius: " .. fovRadius
sizeLabel.BackgroundTransparency = 1
sizeLabel.TextColor3 = Color3.new(1, 1, 1)
sizeLabel.Font = Enum.Font.SourceSans
sizeLabel.TextSize = 13

local plusBtn = Instance.new("TextButton", frame)
plusBtn.Size = UDim2.new(0.16, 0, 0.075, 0)
plusBtn.Position = UDim2.new(0.66, 0, 0.19, 0)
plusBtn.Text = "+"
styleButton(plusBtn)
plusBtn.TextSize = 16

local minusBtn = Instance.new("TextButton", frame)
minusBtn.Size = UDim2.new(0.16, 0, 0.075, 0)
minusBtn.Position = UDim2.new(0.83, 0, 0.19, 0)
minusBtn.Text = "-"
styleButton(minusBtn)
minusBtn.TextSize = 16

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
    rowFrame.Size = UDim2.new(0.85, 0, 0.12, 0)
    rowFrame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", rowFrame)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Text = labelText
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggleButton = Instance.new("TextButton", rowFrame)
    toggleButton.Size = UDim2.new(0, 20, 0, 20)
    toggleButton.Position = UDim2.new(1, -30, 0.5, -10)
    styleButton(toggleButton)
    toggleButton.TextSize = 16
    toggleButton.Text = ""

    local state = defaultState
    toggleButton.MouseButton1Click:Connect(function()
        state = not state
        toggleButton.Text = state and "" or "●"
        callback(state)
        LocalPlayer:SetAttribute(labelText .. "Enabled", state)
    end)

    LocalPlayer:SetAttribute(labelText .. "Enabled", defaultState)

    return rowFrame
end

local recoilRow = createGunToggleRow("Recoil", true, function(state)
	setGunAttribute("Recoil", state and 1 or 0)
end)
recoilRow.Position = UDim2.new(0.05, 0, 0.32, 0)
recoilRow.Parent = frame

local reloadRow = createGunToggleRow("Reload", true, function(state)
	setGunAttribute("ReloadTime", state and 2 or 0)
end)
reloadRow.Position = UDim2.new(0.05, 0, 0.48, 0)
reloadRow.Parent = frame

local espRow = createGunToggleRow("ESP", false, function(state)
	setESPEnabled(state)
end)
espRow.Position = UDim2.new(0.05, 0, 0.64, 0)
espRow.Parent = frame

-- Gun attribute function
function setGunAttribute(attrName, value)
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

-- ESP system
local espBoxes = {}
local nameTags = {}

function CreateESP(player)
	if player == LocalPlayer or espBoxes[player] or not player.Character then return end

	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(255, 0, 0)
	highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.Adornee = player.Character
	highlight.Parent = player.Character
	espBoxes[player] = highlight

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

function RemoveESP(player)
	if espBoxes[player] then
		espBoxes[player]:Destroy()
		espBoxes[player] = nil
	end
	if nameTags[player] then
		nameTags[player]:Destroy()
		nameTags[player] = nil
	end
end

function setESPEnabled(state)
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

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		if LocalPlayer:GetAttribute("ESPEnabled") then
			task.wait(1)
			CreateESP(player)
		end
	end)
end)

Players.PlayerRemoving:Connect(RemoveESP)

-- UI Toggle Icon
local toggleImage = Instance.new("ImageLabel", screenGui)
toggleImage.Size = UDim2.new(0, 50, 0, 50)
toggleImage.Position = UDim2.new(1, -60, 0.85, 0)
toggleImage.Image = "rbxassetid://2924923136"
toggleImage.BackgroundTransparency = 1

toggleImage.MouseButton1Click:Connect(function()
	uiVisible = not uiVisible
	screenGui.Enabled = uiVisible
end)
