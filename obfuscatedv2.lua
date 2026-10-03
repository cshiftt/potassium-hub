if not shared then
	return warn("No shared, no script.")
end
getfenv().LPH_NO_VIRTUALIZE = function(...) return ... end
getfenv().PP_SCRAMBLE_NUM = function(...) return ... end
getfenv().PP_SCRAMBLE_STR = function(...) return ... end
getfenv().PP_SCRAMBLE_RE_NUM = function(...) return ... end

local PotassiumHub = {
	active = false,
	uiVisible = false,
	iconVisible = false,
	mainGui = nil,
	iconGui = nil,
	sectionStates = { FARMING = true, COMBAT = true, MOVEMENT = true, UTILITY = true },
}
PotassiumHub.__index = PotassiumHub

local playersService = game:GetService("Players")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local coreGui = game:GetService("CoreGui")
local tweenService = game:GetService("TweenService")
local contentProvider = game:GetService("ContentProvider")

local localPlayer = playersService.LocalPlayer
local mouse = localPlayer:GetMouse()
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()

local COLORS = {
	BG_DARK = Color3.fromRGB(8, 8, 10),
	BG_CARD = Color3.fromRGB(18, 18, 22),
	BG_LIGHT = Color3.fromRGB(28, 28, 34),
	GLASS = Color3.fromRGB(255, 255, 255),
	GLASS_DARK = Color3.fromRGB(22, 22, 28),
	PRIMARY = Color3.fromRGB(245, 245, 250),
	SECONDARY = Color3.fromRGB(180, 180, 190),
	ACCENT = Color3.fromRGB(255, 255, 255),
	TEXT_PRIMARY = Color3.fromRGB(240, 240, 245),
	TEXT_SECONDARY = Color3.fromRGB(140, 140, 150),
	BORDER = Color3.fromRGB(55, 55, 65),
}

local LOGO_ID = 91234368312745
local LOGO_ASSET = "rbxthumb://type=Asset&id=" .. LOGO_ID .. "&w=420&h=420"
local LOGO_FALLBACK = "rbxassetid://" .. LOGO_ID

local ICONS = {
	Minus = "rbxassetid://79191240000290",
	X = "rbxassetid://134784309661522",
	ChevronDown = "rbxassetid://71457658246709",
	ChevronRight = "rbxassetid://101007429951147",
	Coins = "rbxassetid://117341212186115",
	Crosshair = "rbxassetid://83752373575368",
	Target = "rbxassetid://121091323240554",
	Zap = "rbxassetid://120081085677067",
	Move = "rbxassetid://77028714324861",
	Shield = "rbxassetid://106509993556171",
	Eye = "rbxassetid://127234874352422",
	Settings = "rbxassetid://106205298246017",
	User = "rbxassetid://80586093636888",
}

local FEATURE_DEFAULTS = {
	coinCollect = false, coinRadius = 100, coinMode = "Tween", coinSpeed = 10,
	autoAim = false, aimFOV = 50, shootSpeed = 0.1,
	killAura = false, auraRange = 30,
	flyEnabled = false, flySpeed = 50,
	speedEnabled = false, speedMultiplier = 2,
	noclipEnabled = false, infiniteJump = false,
	godMode = false, invisible = false, antiAfk = false,
}
local features = {}
for k, v in pairs(FEATURE_DEFAULTS) do features[k] = v end

local connections = {}
local lastShot = 0
local afkTimer = 0
local flyDirection = Vector3.new(0, 0, 0)
local collectingCoin = false

local function applyLogo(imageLabel)
	imageLabel.Image = LOGO_ASSET
	imageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
	imageLabel.ScaleType = Enum.ScaleType.Fit
	imageLabel.BackgroundTransparency = 1
	task.spawn(function()
		pcall(function() contentProvider:PreloadAsync({imageLabel}) end)
		task.wait(1.2)
		if not imageLabel.IsLoaded or imageLabel.Image == "" then
			imageLabel.Image = LOGO_FALLBACK
		end
	end)
end

local function applyGlass(frame, intensity)
	intensity = intensity or 0.45
	frame.BackgroundColor3 = COLORS.GLASS_DARK
	frame.BackgroundTransparency = intensity
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Parent = frame
	end
	stroke.Color = COLORS.GLASS
	stroke.Thickness = 1
	stroke.Transparency = 0.72
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local corner = frame:FindFirstChildOfClass("UICorner")
	if not corner then
		corner = Instance.new("UICorner")
		corner.Parent = frame
	end
	corner.CornerRadius = UDim.new(0, 12)
end

local function createIconImage(parent, asset, size, position)
	local img = Instance.new("ImageLabel")
	img.Size = size or UDim2.new(0, 18, 0, 18)
	img.Position = position or UDim2.new(0.5, -9, 0.5, -9)
	img.BackgroundTransparency = 1
	img.Image = asset
	img.ImageColor3 = COLORS.PRIMARY
	img.ScaleType = Enum.ScaleType.Fit
	img.ZIndex = 5
	img.Parent = parent
	return img
end

local function findCoinsInRadius(hrp, radius)
	local coins = {}
	if not hrp then return coins end
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			local name = obj.Name:lower()
			if name:find("coin") or name:find("drop") or name:find("money") or name:find("cash") or name:find("loot") then
				local distance = (obj.Position - hrp.Position).Magnitude
				if distance < radius and obj.Parent then
					table.insert(coins, {obj = obj, distance = distance})
				end
			end
		end
	end
	table.sort(coins, function(a, b) return a.distance < b.distance end)
	return coins
end

function PotassiumHub:manageCoinCollection()
	if connections.coins then connections.coins:Disconnect() connections.coins = nil end
	if not features.coinCollect then return end
	connections.coins = runService.Heartbeat:Connect(function()
		if not features.coinCollect or collectingCoin then return end
		pcall(function()
			local char = localPlayer.Character
			if not char then return end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			local coins = findCoinsInRadius(hrp, features.coinRadius)
			if #coins == 0 then return end
			local targetCoin = coins[1]
			if not targetCoin or not targetCoin.obj or not targetCoin.obj.Parent then return end
			collectingCoin = true
			local coinPos = targetCoin.obj.Position
			local distance = (coinPos - hrp.Position).Magnitude
			local startPos = hrp.Position
			if features.coinMode == "Tween" then
				local speedFactor = features.coinSpeed / 10
				local duration = math.max(distance / (12 * speedFactor), 0.5)
				local startTime = tick()
				local moveConnection
				moveConnection = runService.Heartbeat:Connect(function()
					if not features.coinCollect or not hrp.Parent or not targetCoin.obj or not targetCoin.obj.Parent then
						moveConnection:Disconnect()
						collectingCoin = false
						return
					end
					local progress = math.min((tick() - startTime) / duration, 1)
					if progress < 1 then
						hrp.CFrame = CFrame.new(startPos:Lerp(coinPos, progress)) * (hrp.CFrame - hrp.CFrame.Position)
					else
						hrp.CFrame = CFrame.new(coinPos) * (hrp.CFrame - hrp.CFrame.Position)
						if targetCoin.obj and targetCoin.obj.Parent then targetCoin.obj:Destroy() end
						moveConnection:Disconnect()
						collectingCoin = false
					end
				end)
			else
				hrp.CFrame = CFrame.new(coinPos) * (hrp.CFrame - hrp.CFrame.Position)
				if targetCoin.obj and targetCoin.obj.Parent then targetCoin.obj:Destroy() end
				collectingCoin = false
			end
		end)
	end)
end

function PotassiumHub:manageAutoAim()
	if connections.aim then connections.aim:Disconnect() connections.aim = nil end
	if not features.autoAim then return end
	connections.aim = runService.RenderStepped:Connect(function()
		if not features.autoAim then return end
		pcall(function()
			local char = localPlayer.Character
			if not char then return end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local weapon = char:FindFirstChildOfClass("Tool")
			if not hrp or not weapon then return end
			local bestTarget, bestDistance = nil, features.aimFOV
			for _, p in pairs(playersService:GetPlayers()) do
				if p ~= localPlayer and p.Character then
					local targetHrp = p.Character:FindFirstChild("HumanoidRootPart")
					local humanoid = p.Character:FindFirstChild("Humanoid")
					if targetHrp and humanoid and humanoid.Health > 0 then
						local dist = (targetHrp.Position - hrp.Position).Magnitude
						if dist < bestDistance then
							bestTarget = targetHrp
							bestDistance = dist
						end
					end
				end
			end
			if bestTarget then
				hrp.CFrame = CFrame.lookAt(hrp.Position, bestTarget.Position)
				if tick() - lastShot >= features.shootSpeed then
					if weapon:FindFirstChild("Fire") then weapon.Fire:FireServer() end
					lastShot = tick()
				end
			end
		end)
	end)
end

function PotassiumHub:manageKillAura()
	if connections.aura then connections.aura:Disconnect() connections.aura = nil end
	if not features.killAura then return end
	connections.aura = runService.Heartbeat:Connect(function()
		if not features.killAura then return end
		pcall(function()
			local char = localPlayer.Character
			if not char then return end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			for _, p in pairs(playersService:GetPlayers()) do
				if p ~= localPlayer and p.Character then
					local targetHrp = p.Character:FindFirstChild("HumanoidRootPart")
					local humanoid = p.Character:FindFirstChild("Humanoid")
					if targetHrp and humanoid and humanoid.Health > 0 then
						if (targetHrp.Position - hrp.Position).Magnitude < features.auraRange then
							humanoid:TakeDamage(5)
						end
					end
				end
			end
		end)
	end)
end

function PotassiumHub:manageFly()
	if connections.fly then connections.fly:Disconnect() connections.fly = nil end
	if not features.flyEnabled then return end
	connections.fly = runService.Heartbeat:Connect(function()
		if not features.flyEnabled then return end
		pcall(function()
			local char = localPlayer.Character
			if not char then return end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			flyDirection = Vector3.new(0, 0, 0)
			if userInputService:IsKeyDown(Enum.KeyCode.W) then flyDirection = flyDirection + (mouse.Hit.LookVector * Vector3.new(1, 0, 1)).Unit end
			if userInputService:IsKeyDown(Enum.KeyCode.S) then flyDirection = flyDirection - (mouse.Hit.LookVector * Vector3.new(1, 0, 1)).Unit end
			if userInputService:IsKeyDown(Enum.KeyCode.A) then flyDirection = flyDirection - hrp.CFrame.RightVector end
			if userInputService:IsKeyDown(Enum.KeyCode.D) then flyDirection = flyDirection + hrp.CFrame.RightVector end
			if userInputService:IsKeyDown(Enum.KeyCode.Space) then flyDirection = flyDirection + Vector3.new(0, 1, 0) end
			if userInputService:IsKeyDown(Enum.KeyCode.LeftControl) then flyDirection = flyDirection - Vector3.new(0, 1, 0) end
			if flyDirection.Magnitude > 0 then
				hrp.CFrame = hrp.CFrame + (flyDirection.Unit * 2 * (features.flySpeed / 50))
			end
		end)
	end)
end

function PotassiumHub:manageSpeed()
	if connections.speed then connections.speed:Disconnect() connections.speed = nil end
	if not features.speedEnabled then return end
	connections.speed = runService.Heartbeat:Connect(function()
		if not features.speedEnabled then return end
		pcall(function()
			local char = localPlayer.Character
			if not char then return end
			local humanoid = char:FindFirstChild("Humanoid")
			if humanoid then humanoid.WalkSpeed = 16 * features.speedMultiplier end
		end)
	end)
end

function PotassiumHub:manageNoClip()
	if connections.noclip then connections.noclip:Disconnect() connections.noclip = nil end
	if not features.noclipEnabled then return end
	connections.noclip = runService.Heartbeat:Connect(function()
		if not features.noclipEnabled then return end
		pcall(function()
			local char = localPlayer.Character
			if not char then return end
			for _, part in pairs(char:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end)
	end)
end

function PotassiumHub:manageInfiniteJump()
	if connections.ijump then connections.ijump:Disconnect() connections.ijump = nil end
	if not features.infiniteJump then return end
	connections.ijump = userInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.Space and features.infiniteJump then
			local char = localPlayer.Character
			if char then
				local humanoid = char:FindFirstChild("Humanoid")
				if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
			end
		end
	end)
end

function PotassiumHub:manageGodMode()
	if connections.god then connections.god:Disconnect() connections.god = nil end
	if not features.godMode then return end
	connections.god = runService.Heartbeat:Connect(function()
		if not features.godMode then return end
		pcall(function()
			local char = localPlayer.Character
			if not char then return end
			local humanoid = char:FindFirstChild("Humanoid")
			if humanoid then humanoid.Health = humanoid.MaxHealth end
		end)
	end)
end

function PotassiumHub:manageInvisibility()
	local char = localPlayer.Character
	if not char then return end
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = features.invisible and 1 or 0
		end
	end
end

function PotassiumHub:manageAntiAfk()
	if connections.afk then connections.afk:Disconnect() connections.afk = nil end
	if not features.antiAfk then return end
	connections.afk = runService.Heartbeat:Connect(function()
		if not features.antiAfk then return end
		afkTimer = afkTimer + runService.Heartbeat:Wait()
		if afkTimer > 120 then
			local char = localPlayer.Character
			if char then
				local humanoid = char:FindFirstChild("Humanoid")
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if humanoid and hrp then
					humanoid:MoveTo(hrp.Position + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5)))
				end
			end
			afkTimer = 0
		end
	end)
end

function PotassiumHub:createIcon()
	if PotassiumHub.iconGui and PotassiumHub.iconGui.Parent then
		PotassiumHub.iconGui:Destroy()
	end

	local iconGui = Instance.new("ScreenGui")
	iconGui.Name = "PotassiumIcon"
	iconGui.ResetOnSpawn = false
	iconGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	iconGui.Parent = coreGui

	local iconContainer = Instance.new("Frame")
	iconContainer.Name = "IconContainer"
	iconContainer.Size = UDim2.new(0, 80, 0, 80)
	iconContainer.Position = UDim2.new(0.5, -40, 0, 20)
	iconContainer.BackgroundColor3 = COLORS.BG_DARK
	iconContainer.BorderSizePixel = 0
	iconContainer.ZIndex = 10
	iconContainer.Active = true
	iconContainer.Parent = iconGui
	applyGlass(iconContainer, 0.35)

	local logoImage = Instance.new("ImageLabel")
	logoImage.Name = "Logo"
	logoImage.Size = UDim2.new(0.88, 0, 0.88, 0)
	logoImage.Position = UDim2.new(0.06, 0, 0.06, 0)
	logoImage.BackgroundTransparency = 1
	logoImage.BorderSizePixel = 0
	logoImage.ZIndex = 11
	logoImage.Parent = iconContainer
	applyLogo(logoImage)

	local fallbackText = Instance.new("TextLabel")
	fallbackText.Name = "Fallback"
	fallbackText.Size = UDim2.new(1, 0, 1, 0)
	fallbackText.BackgroundTransparency = 1
	fallbackText.Text = "K"
	fallbackText.TextColor3 = COLORS.PRIMARY
	fallbackText.TextSize = 36
	fallbackText.Font = Enum.Font.GothamBold
	fallbackText.ZIndex = 12
	fallbackText.Visible = false
	fallbackText.Parent = iconContainer

	task.spawn(function()
		task.wait(2)
		if not logoImage.IsLoaded then
			logoImage.Visible = false
			fallbackText.Visible = true
		end
	end)

	local dragging = false
	local dragStart = nil
	local startPos = nil

	iconContainer.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = iconContainer.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	userInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			if dragStart and startPos then
				local delta = input.Position - dragStart
				iconContainer.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			end
		end
	end)

	local clickStartPos = nil
	local clickStartTime = 0
	iconContainer.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			clickStartPos = input.Position
			clickStartTime = tick()
		end
	end)
	iconContainer.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if clickStartPos and (input.Position - clickStartPos).Magnitude < 8 and (tick() - clickStartTime) < 0.35 then
				if PotassiumHub.iconGui and PotassiumHub.iconGui.Parent then
					tweenService:Create(iconContainer, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
					task.wait(0.2)
					PotassiumHub.iconGui:Destroy()
					PotassiumHub.iconGui = nil
					PotassiumHub.iconVisible = false
				end
				PotassiumHub:createUI()
			end
		end
	end)

	local stroke = iconContainer:FindFirstChildOfClass("UIStroke")
	iconContainer.MouseEnter:Connect(function()
		if stroke then tweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0.45}):Play() end
	end)
	iconContainer.MouseLeave:Connect(function()
		if stroke then tweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0.72}):Play() end
	end)

	PotassiumHub.iconGui = iconGui
	PotassiumHub.iconVisible = true
end

function PotassiumHub:showLoading()
	local loadingGui = Instance.new("ScreenGui")
	loadingGui.Name = "PotassiumLoading"
	loadingGui.ResetOnSpawn = false
	loadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	loadingGui.Parent = coreGui

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = COLORS.BG_DARK
	bg.BorderSizePixel = 0
	bg.Parent = loadingGui

	local loadingLogo = Instance.new("ImageLabel")
	loadingLogo.Size = UDim2.new(0, 140, 0, 140)
	loadingLogo.Position = UDim2.new(0.5, -70, 0.28, -70)
	loadingLogo.BackgroundTransparency = 1
	loadingLogo.BorderSizePixel = 0
	loadingLogo.ZIndex = 5
	loadingLogo.Parent = bg
	applyLogo(loadingLogo)

	local fallbackLoad = Instance.new("TextLabel")
	fallbackLoad.Size = UDim2.new(0, 140, 0, 140)
	fallbackLoad.Position = UDim2.new(0.5, -70, 0.28, -70)
	fallbackLoad.BackgroundTransparency = 1
	fallbackLoad.Text = "K"
	fallbackLoad.TextColor3 = COLORS.PRIMARY
	fallbackLoad.TextSize = 80
	fallbackLoad.Font = Enum.Font.GothamBold
	fallbackLoad.Visible = false
	fallbackLoad.Parent = bg
	task.spawn(function()
		task.wait(1.5)
		if not loadingLogo.IsLoaded then
			loadingLogo.Visible = false
			fallbackLoad.Visible = true
		end
	end)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0, 420, 0, 70)
	title.Position = UDim2.new(0.5, -210, 0.48, -35)
	title.BackgroundTransparency = 1
	title.TextColor3 = COLORS.PRIMARY
	title.TextSize = 42
	title.Font = Enum.Font.GothamBold
	title.Text = "POTASSIUM"
	title.Parent = bg

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(0, 400, 0, 30)
	subtitle.Position = UDim2.new(0.5, -200, 0.56, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.TextColor3 = COLORS.TEXT_SECONDARY
	subtitle.TextSize = 14
	subtitle.Font = Enum.Font.Gotham
	subtitle.Text = "Murder Mystery 2"
	subtitle.Parent = bg

	task.wait(1.8)
	tweenService:Create(bg, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
	task.wait(0.3)
	loadingGui:Destroy()
end

function PotassiumHub:createUI()
	if coreGui:FindFirstChild("PotassiumUIMain") then
		coreGui.PotassiumUIMain:Destroy()
	end

	local mainGui = Instance.new("ScreenGui")
	mainGui.Name = "PotassiumUIMain"
	mainGui.ResetOnSpawn = false
	mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	mainGui.Parent = coreGui
	PotassiumHub.mainGui = mainGui

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 100, 0, 150)
	mainFrame.Position = UDim2.new(0.5, -230, 0.5, -310)
	mainFrame.BackgroundColor3 = COLORS.BG_DARK
	mainFrame.BorderSizePixel = 0
	mainFrame.BackgroundTransparency = 1
	mainFrame.Parent = mainGui
	tweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 460, 0, 620), BackgroundTransparency = 0.08
	}):Play()

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 20)
	mainCorner.Parent = mainFrame
	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = COLORS.GLASS
	mainStroke.Thickness = 1
	mainStroke.Transparency = 0.78
	mainStroke.Parent = mainFrame

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 68)
	header.BackgroundColor3 = COLORS.GLASS_DARK
	header.BackgroundTransparency = 0.35
	header.BorderSizePixel = 0
	header.Parent = mainFrame
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 20)
	headerCorner.Parent = header
	local headerStroke = Instance.new("UIStroke")
	headerStroke.Color = COLORS.GLASS
	headerStroke.Thickness = 1
	headerStroke.Transparency = 0.7
	headerStroke.Parent = header

	local headerLogo = Instance.new("ImageLabel")
	headerLogo.Size = UDim2.new(0, 40, 0, 40)
	headerLogo.Position = UDim2.new(0, 20, 0.5, -20)
	headerLogo.BackgroundTransparency = 1
	headerLogo.BorderSizePixel = 0
	headerLogo.ZIndex = 5
	headerLogo.Parent = header
	applyLogo(headerLogo)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0, 200, 0, 50)
	title.Position = UDim2.new(0, 68, 0.5, -25)
	title.BackgroundTransparency = 1
	title.TextColor3 = COLORS.PRIMARY
	title.TextSize = 22
	title.Font = Enum.Font.GothamBold
	title.Text = "POTASSIUM"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local dragging = false
	local dragStart = nil
	local startPos = nil
	local dragArea = Instance.new("TextButton")
	dragArea.Size = UDim2.new(0.65, 0, 1, 0)
	dragArea.BackgroundTransparency = 1
	dragArea.Text = ""
	dragArea.Parent = header

	dragArea.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	userInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			if dragStart and startPos then
				local delta = input.Position - dragStart
				mainFrame.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			end
		end
	end)

	local minBtn = Instance.new("TextButton")
	minBtn.Size = UDim2.new(0, 40, 0, 40)
	minBtn.Position = UDim2.new(1, -92, 0, 14)
	minBtn.BackgroundColor3 = COLORS.GLASS_DARK
	minBtn.BackgroundTransparency = 0.4
	minBtn.Text = ""
	minBtn.BorderSizePixel = 0
	minBtn.Parent = header
	applyGlass(minBtn, 0.4)
	createIconImage(minBtn, ICONS.Minus, UDim2.new(0, 18, 0, 18), UDim2.new(0.5, -9, 0.5, -9))

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -46, 0, 14)
	closeBtn.BackgroundColor3 = COLORS.GLASS_DARK
	closeBtn.BackgroundTransparency = 0.4
	closeBtn.Text = ""
	closeBtn.BorderSizePixel = 0
	closeBtn.Parent = header
	applyGlass(closeBtn, 0.4)
	createIconImage(closeBtn, ICONS.X, UDim2.new(0, 16, 0, 16), UDim2.new(0.5, -8, 0.5, -8))

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, -68)
	scroll.Position = UDim2.new(0, 0, 0, 68)
	scroll.BackgroundColor3 = COLORS.BG_DARK
	scroll.BackgroundTransparency = 0.15
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = COLORS.PRIMARY
	scroll.CanvasSize = UDim2.new(0, 0, 0, 1000)
	scroll.Parent = mainFrame
	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 18)
	scrollCorner.Parent = scroll

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 18)
	list.FillDirection = Enum.FillDirection.Vertical
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = scroll
	local scrollPad = Instance.new("UIPadding")
	scrollPad.PaddingLeft = UDim.new(0, 16)
	scrollPad.PaddingRight = UDim.new(0, 16)
	scrollPad.PaddingTop = UDim.new(0, 18)
	scrollPad.PaddingBottom = UDim.new(0, 20)
	scrollPad.Parent = scroll
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 40)
	end)

	local isMinimized = false
	minBtn.MouseButton1Click:Connect(function()
		isMinimized = not isMinimized
		if isMinimized then
			tweenService:Create(mainFrame, TweenInfo.new(0.25), {Size = UDim2.new(0, 460, 0, 68)}):Play()
			scroll.Visible = false
		else
			tweenService:Create(mainFrame, TweenInfo.new(0.25), {Size = UDim2.new(0, 460, 0, 620)}):Play()
			scroll.Visible = true
		end
	end)
	closeBtn.MouseButton1Click:Connect(function()
		tweenService:Create(mainFrame, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
		task.wait(0.2)
		mainGui:Destroy()
		PotassiumHub.mainGui = nil
		PotassiumHub.uiVisible = false
		PotassiumHub:createIcon()
	end)

	local function createToggle(text, key, parent)
		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 0, 50)
		container.BackgroundColor3 = COLORS.BG_CARD
		container.BackgroundTransparency = 0.25
		container.BorderSizePixel = 0
		container.Parent = parent
		applyGlass(container, 0.38)

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.65, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = COLORS.TEXT_PRIMARY
		label.TextSize = 13
		label.Font = Enum.Font.Gotham
		label.Text = text
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = container
		local lp = Instance.new("UIPadding")
		lp.PaddingLeft = UDim.new(0, 14)
		lp.Parent = label

		local toggle = Instance.new("Frame")
		toggle.Size = UDim2.new(0, 44, 0, 22)
		toggle.Position = UDim2.new(0.78, -22, 0.5, -11)
		toggle.BackgroundColor3 = COLORS.BG_LIGHT
		toggle.BackgroundTransparency = 0.3
		toggle.BorderSizePixel = 0
		toggle.Parent = container
		local tc = Instance.new("UICorner")
		tc.CornerRadius = UDim.new(0, 11)
		tc.Parent = toggle

		local ball = Instance.new("Frame")
		ball.Size = UDim2.new(0, 18, 0, 18)
		ball.Position = UDim2.new(0, 2, 0.5, -9)
		ball.BackgroundColor3 = COLORS.TEXT_SECONDARY
		ball.BorderSizePixel = 0
		ball.Parent = toggle
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(1, 0)
		bc.Parent = ball

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.Parent = container
		btn.MouseButton1Click:Connect(function()
			features[key] = not features[key]
			if features[key] then
				tweenService:Create(ball, TweenInfo.new(0.2), {Position = UDim2.new(0, 24, 0.5, -9), BackgroundColor3 = COLORS.ACCENT}):Play()
				tweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(55, 55, 68)}):Play()
			else
				tweenService:Create(ball, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -9), BackgroundColor3 = COLORS.TEXT_SECONDARY}):Play()
				tweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BG_LIGHT}):Play()
			end
			if key == "coinCollect" then PotassiumHub:manageCoinCollection() end
			if key == "autoAim" then PotassiumHub:manageAutoAim() end
			if key == "killAura" then PotassiumHub:manageKillAura() end
			if key == "flyEnabled" then PotassiumHub:manageFly() end
			if key == "speedEnabled" then PotassiumHub:manageSpeed() end
			if key == "noclipEnabled" then PotassiumHub:manageNoClip() end
			if key == "infiniteJump" then PotassiumHub:manageInfiniteJump() end
			if key == "godMode" then PotassiumHub:manageGodMode() end
			if key == "invisible" then PotassiumHub:manageInvisibility() end
			if key == "antiAfk" then PotassiumHub:manageAntiAfk() end
		end)
		if features[key] then
			ball.Position = UDim2.new(0, 24, 0.5, -9)
			ball.BackgroundColor3 = COLORS.ACCENT
			toggle.BackgroundColor3 = Color3.fromRGB(55, 55, 68)
		end
	end

	local function createNumberInput(text, key, minVal, maxVal, parent)
		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 0, 64)
		container.BackgroundColor3 = COLORS.BG_CARD
		container.BackgroundTransparency = 0.25
		container.BorderSizePixel = 0
		container.Parent = parent
		applyGlass(container, 0.38)

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -28, 0, 16)
		label.Position = UDim2.new(0, 14, 0, 8)
		label.BackgroundTransparency = 1
		label.TextColor3 = COLORS.TEXT_PRIMARY
		label.TextSize = 12
		label.Font = Enum.Font.GothamBold
		label.Text = text .. " (" .. features[key] .. ")"
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = container

		local inputBox = Instance.new("TextBox")
		inputBox.Size = UDim2.new(1, -28, 0, 28)
		inputBox.Position = UDim2.new(0, 14, 0, 28)
		inputBox.BackgroundColor3 = COLORS.BG_LIGHT
		inputBox.BackgroundTransparency = 0.25
		inputBox.TextColor3 = COLORS.TEXT_PRIMARY
		inputBox.PlaceholderColor3 = COLORS.TEXT_SECONDARY
		inputBox.TextSize = 12
		inputBox.Font = Enum.Font.Gotham
		inputBox.Text = tostring(features[key])
		inputBox.PlaceholderText = minVal .. " - " .. maxVal
		inputBox.BorderSizePixel = 0
		inputBox.ClearTextOnFocus = false
		inputBox.Parent = container
		local ic = Instance.new("UICorner")
		ic.CornerRadius = UDim.new(0, 8)
		ic.Parent = inputBox
		local ip = Instance.new("UIPadding")
		ip.PaddingLeft = UDim.new(0, 10)
		ip.Parent = inputBox

		inputBox.FocusLost:Connect(function()
			local val = tonumber(inputBox.Text)
			if val then
				val = math.clamp(math.floor(val), minVal, maxVal)
				features[key] = val
				inputBox.Text = tostring(val)
				label.Text = text .. " (" .. val .. ")"
				if key == "coinRadius" or key == "coinSpeed" then PotassiumHub:manageCoinCollection() end
				if key == "aimFOV" or key == "shootSpeed" then PotassiumHub:manageAutoAim() end
				if key == "auraRange" then PotassiumHub:manageKillAura() end
				if key == "flySpeed" then PotassiumHub:manageFly() end
				if key == "speedMultiplier" then PotassiumHub:manageSpeed() end
			else
				inputBox.Text = tostring(features[key])
			end
		end)
	end

	local function createSubcategory(text, parent)
		local sub = Instance.new("Frame")
		sub.Size = UDim2.new(1, 0, 0, 34)
		sub.BackgroundColor3 = COLORS.GLASS_DARK
		sub.BackgroundTransparency = 0.55
		sub.BorderSizePixel = 0
		sub.Parent = parent
		applyGlass(sub, 0.55)

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -20, 1, 0)
		label.Position = UDim2.new(0, 12, 0, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = COLORS.SECONDARY
		label.TextSize = 12
		label.Font = Enum.Font.GothamBold
		label.Text = text
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = sub
		return sub
	end

	local function createSection(title, sectionKey, iconAsset)
		local section = Instance.new("Frame")
		section.Size = UDim2.new(1, 0, 0, 42)
		section.BackgroundTransparency = 1
		section.Parent = scroll

		local sectionHeader = Instance.new("Frame")
		sectionHeader.Size = UDim2.new(1, 0, 0, 42)
		sectionHeader.BackgroundColor3 = COLORS.GLASS_DARK
		sectionHeader.BackgroundTransparency = 0.32
		sectionHeader.BorderSizePixel = 0
		sectionHeader.Parent = section
		applyGlass(sectionHeader, 0.32)

		if iconAsset then
			createIconImage(sectionHeader, iconAsset, UDim2.new(0, 18, 0, 18), UDim2.new(0, 14, 0.5, -9))
		end

		local headerLabel = Instance.new("TextLabel")
		headerLabel.Size = UDim2.new(0.7, 0, 1, 0)
		headerLabel.Position = UDim2.new(0, iconAsset and 40 or 16, 0, 0)
		headerLabel.BackgroundTransparency = 1
		headerLabel.TextColor3 = COLORS.PRIMARY
		headerLabel.TextSize = 13
		headerLabel.Font = Enum.Font.GothamBold
		headerLabel.Text = title
		headerLabel.TextXAlignment = Enum.TextXAlignment.Left
		headerLabel.Parent = sectionHeader

		local expandIcon = Instance.new("ImageLabel")
		expandIcon.Size = UDim2.new(0, 16, 0, 16)
		expandIcon.Position = UDim2.new(1, -28, 0.5, -8)
		expandIcon.BackgroundTransparency = 1
		expandIcon.Image = PotassiumHub.sectionStates[sectionKey] and ICONS.ChevronDown or ICONS.ChevronRight
		expandIcon.ImageColor3 = COLORS.PRIMARY
		expandIcon.ScaleType = Enum.ScaleType.Fit
		expandIcon.Parent = sectionHeader

		local contentHolder = Instance.new("Frame")
		contentHolder.Size = UDim2.new(1, 0, 0, 0)
		contentHolder.BackgroundTransparency = 1
		contentHolder.Parent = section
		local contentList = Instance.new("UIListLayout")
		contentList.Padding = UDim.new(0, 10)
		contentList.FillDirection = Enum.FillDirection.Vertical
		contentList.SortOrder = Enum.SortOrder.LayoutOrder
		contentList.Parent = contentHolder
		local contentPad = Instance.new("UIPadding")
		contentPad.PaddingLeft = UDim.new(0, 8)
		contentPad.PaddingRight = UDim.new(0, 8)
		contentPad.PaddingTop = UDim.new(0, 12)
		contentPad.PaddingBottom = UDim.new(0, 8)
		contentPad.Parent = contentHolder

		local isExpanded = PotassiumHub.sectionStates[sectionKey] ~= false
		if not isExpanded then contentHolder.Visible = false end

		local headerBtn = Instance.new("TextButton")
		headerBtn.Size = UDim2.new(1, 0, 1, 0)
		headerBtn.BackgroundTransparency = 1
		headerBtn.Text = ""
		headerBtn.Parent = sectionHeader
		headerBtn.MouseButton1Click:Connect(function()
			isExpanded = not isExpanded
			PotassiumHub.sectionStates[sectionKey] = isExpanded
			expandIcon.Image = isExpanded and ICONS.ChevronDown or ICONS.ChevronRight
			if isExpanded then
				contentHolder.Visible = true
				local h = contentList.AbsoluteContentSize.Y + 20
				tweenService:Create(section, TweenInfo.new(0.25), {Size = UDim2.new(1, 0, 0, 42 + h)}):Play()
				tweenService:Create(contentHolder, TweenInfo.new(0.25), {Size = UDim2.new(1, 0, 0, h)}):Play()
			else
				tweenService:Create(section, TweenInfo.new(0.25), {Size = UDim2.new(1, 0, 0, 42)}):Play()
				tweenService:Create(contentHolder, TweenInfo.new(0.25), {Size = UDim2.new(1, 0, 0, 0)}):Play()
				task.wait(0.25)
				contentHolder.Visible = false
			end
		end)
		contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			if isExpanded then
				local h = contentList.AbsoluteContentSize.Y + 20
				section.Size = UDim2.new(1, 0, 0, 42 + h)
				contentHolder.Size = UDim2.new(1, 0, 0, h)
			end
		end)
		if isExpanded then contentHolder.Visible = true end
		return contentHolder
	end

	local farmingSection = createSection("FARMING", "FARMING", ICONS.Coins)
	createSubcategory("Coin Collection", farmingSection)
	createToggle("Enable", "coinCollect", farmingSection)
	createNumberInput("Radius", "coinRadius", 50, 300, farmingSection)
	createNumberInput("Speed", "coinSpeed", 5, 50, farmingSection)
	createSubcategory("Settings", farmingSection)
	local modeBtn = Instance.new("Frame")
	modeBtn.Size = UDim2.new(1, 0, 0, 44)
	modeBtn.BackgroundColor3 = COLORS.BG_LIGHT
	modeBtn.BackgroundTransparency = 0.3
	modeBtn.BorderSizePixel = 0
	modeBtn.Parent = farmingSection
	applyGlass(modeBtn, 0.4)
	local modeLabel = Instance.new("TextLabel")
	modeLabel.Size = UDim2.new(1, 0, 1, 0)
	modeLabel.BackgroundTransparency = 1
	modeLabel.TextColor3 = COLORS.TEXT_PRIMARY
	modeLabel.TextSize = 12
	modeLabel.Font = Enum.Font.Gotham
	modeLabel.Text = "Mode: " .. features.coinMode
	modeLabel.Parent = modeBtn
	local mp = Instance.new("UIPadding")
	mp.PaddingLeft = UDim.new(0, 14)
	mp.Parent = modeLabel
	local modeClick = Instance.new("TextButton")
	modeClick.Size = UDim2.new(1, 0, 1, 0)
	modeClick.BackgroundTransparency = 1
	modeClick.Text = ""
	modeClick.Parent = modeBtn
	modeClick.MouseButton1Click:Connect(function()
		features.coinMode = features.coinMode == "Tween" and "Teleport" or "Tween"
		modeLabel.Text = "Mode: " .. features.coinMode
	end)

	local combatSection = createSection("COMBAT", "COMBAT", ICONS.Crosshair)
	createSubcategory("Auto Aim", combatSection)
	createToggle("Enable", "autoAim", combatSection)
	createNumberInput("FOV", "aimFOV", 10, 180, combatSection)
	createNumberInput("Rate", "shootSpeed", 0.05, 1, combatSection)
	createSubcategory("Kill Aura", combatSection)
	createToggle("Enable", "killAura", combatSection)
	createNumberInput("Range", "auraRange", 20, 100, combatSection)

	local movementSection = createSection("MOVEMENT", "MOVEMENT", ICONS.Move)
	createSubcategory("Flight", movementSection)
	createToggle("Enable", "flyEnabled", movementSection)
	createNumberInput("Speed", "flySpeed", 10, 200, movementSection)
	createSubcategory("Sprint", movementSection)
	createToggle("Enable", "speedEnabled", movementSection)
	createNumberInput("Multiplier", "speedMultiplier", 1, 5, movementSection)
	createSubcategory("Physics", movementSection)
	createToggle("No Clip", "noclipEnabled", movementSection)
	createToggle("Infinite Jump", "infiniteJump", movementSection)

	local utilitySection = createSection("UTILITY", "UTILITY", ICONS.Shield)
	createSubcategory("Character", utilitySection)
	createToggle("God Mode", "godMode", utilitySection)
	createToggle("Invisible", "invisible", utilitySection)
	createSubcategory("General", utilitySection)
	createToggle("Anti AFK", "antiAfk", utilitySection)

	PotassiumHub.uiVisible = true
end

userInputService.InputBegan:Connect(function(input, gp)
	if input.KeyCode == Enum.KeyCode.RightControl then
		if coreGui:FindFirstChild("PotassiumUIMain") then
			local uiGui = coreGui.PotassiumUIMain
			local mainFrame = uiGui:FindFirstChild("MainFrame")
			if mainFrame then
				tweenService:Create(mainFrame, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
				task.wait(0.2)
			end
			uiGui:Destroy()
			PotassiumHub.mainGui = nil
			PotassiumHub.uiVisible = false
			PotassiumHub:createIcon()
		elseif coreGui:FindFirstChild("PotassiumIcon") then
			if PotassiumHub.iconGui and PotassiumHub.iconGui.Parent then
				PotassiumHub.iconGui:Destroy()
				PotassiumHub.iconGui = nil
			end
			PotassiumHub:createUI()
		end
	end
end)

localPlayer.CharacterAdded:Connect(function(newChar)
	character = newChar
	afkTimer = 0
	flyDirection = Vector3.new(0, 0, 0)
	collectingCoin = false
end)

local function initializeScript()
	PotassiumHub.active = true
	PotassiumHub:showLoading()
	task.wait(2)
	PotassiumHub:createUI()
end

xpcall(initializeScript, function(err)
	warn("POTASSIUM HUB init fail: " .. tostring(err))
end)

if shared.PotassiumHub then
	shared.PotassiumHub.active = false
end
shared.PotassiumHub = PotassiumHub
