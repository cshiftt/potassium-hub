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
	sectionStates = {
		COMBAT = true,
		VISUALS = true,
		MOVEMENT = true,
		UTILITY = true,
		CONFIG = true,
	},
}
PotassiumHub.__index = PotassiumHub

local playersService = game:GetService("Players")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local coreGui = game:GetService("CoreGui")
local tweenService = game:GetService("TweenService")
local contentProvider = game:GetService("ContentProvider")
local lighting = game:GetService("Lighting")
local teleportService = game:GetService("TeleportService")
local httpService = game:GetService("HttpService")
local virtualUser = game:GetService("VirtualUser")

local localPlayer = playersService.LocalPlayer
local mouse = localPlayer:GetMouse()
local camera = workspace.CurrentCamera
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
	ESP_ENEMY = Color3.fromRGB(255, 70, 70),
	ESP_VISIBLE = Color3.fromRGB(70, 255, 120),
	FOV_COLOR = Color3.fromRGB(255, 255, 255),
}

local LOGO_ID = 91234368312745
local LOGO_ASSET = "rbxthumb://type=Asset&id=" .. LOGO_ID .. "&w=420&h=420"
local LOGO_FALLBACK = "rbxassetid://" .. LOGO_ID

local ICONS = {
	Minus = "rbxassetid://79191240000290",
	X = "rbxassetid://134784309661522",
	ChevronDown = "rbxassetid://71457658246709",
	ChevronRight = "rbxassetid://101007429951147",
	Crosshair = "rbxassetid://83752373575368",
	Eye = "rbxassetid://117341212186115",
	Move = "rbxassetid://77028714324861",
	Shield = "rbxassetid://106509993556171",
	Settings = "rbxassetid://106509993556171",
}

local FEATURE_DEFAULTS = {
	aimbot = false,
	aimAssist = false,
	silentAim = false,
	triggerbot = false,
	aimFOV = 120,
	aimSmooth = 0.18,
	aimPart = "Head",
	aimPrediction = 0.12,
	teamCheck = true,
	visibleCheck = true,
	showFOV = true,
	hitChance = 100,

	espEnabled = false,
	espBoxes = true,
	espNames = true,
	espDistance = true,
	espHealth = true,
	espTracers = false,
	espChams = true,
	espSkeleton = false,
	espMaxDist = 800,

	speedEnabled = false,
	speedMultiplier = 1.8,
	flyEnabled = false,
	flySpeed = 60,
	noclipEnabled = false,
	infiniteJump = false,
	bunnyHop = false,
	jumpPower = 50,

	godMode = false,
	antiAfk = true,
	noClipCam = false,
	fullbright = false,
	noFog = false,
	customCrosshair = false,
	crosshairSize = 8,
	antiFlash = false,
	serverHop = false,
	rejoin = false,
	spinBot = false,
	spinSpeed = 12,
}

local features = {}
for k, v in pairs(FEATURE_DEFAULTS) do features[k] = v end

local connections = {}
local espObjects = {}
local fovCircle = nil
local crosshairGui = nil
local afkTimer = 0
local flyDirection = Vector3.zero
local currentFont = Enum.Font.Gotham

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
	intensity = intensity or 0.42
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

local function getRoot(char)
	return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end

local function getHumanoid(char)
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function isAlive(plr)
	local char = plr.Character
	if not char then return false end
	local hum = getHumanoid(char)
	return hum and hum.Health > 0
end

local function isEnemy(plr)
	if plr == localPlayer then return false end
	if not features.teamCheck then return true end
	if localPlayer.Team and plr.Team and localPlayer.Team == plr.Team then
		return false
	end
	return true
end

local function isVisible(targetPart)
	if not features.visibleCheck then return true end
	local origin = camera.CFrame.Position
	local dir = (targetPart.Position - origin)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {localPlayer.Character, camera}
	local result = workspace:Raycast(origin, dir, params)
	if not result then return true end
	return result.Instance:IsDescendantOf(targetPart.Parent)
end

local function getClosestTarget(maxFOV)
	local best, bestDist = nil, maxFOV or features.aimFOV
	local viewport = camera.ViewportSize
	local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
	for _, plr in ipairs(playersService:GetPlayers()) do
		if isEnemy(plr) and isAlive(plr) then
			local char = plr.Character
			local part = char:FindFirstChild(features.aimPart) or getRoot(char)
			if part then
				local screen, onScreen = camera:WorldToViewportPoint(part.Position)
				if onScreen and screen.Z > 0 then
					local dist = (Vector2.new(screen.X, screen.Y) - center).Magnitude
					if dist < bestDist and isVisible(part) then
						bestDist = dist
						best = part
					end
				end
			end
		end
	end
	return best
end

local function predictPosition(part)
	local vel = part.AssemblyLinearVelocity or Vector3.zero
	return part.Position + vel * features.aimPrediction
end

function PotassiumHub:manageAimbot()
	if connections.aimbot then connections.aimbot:Disconnect() connections.aimbot = nil end
	if not (features.aimbot or features.aimAssist) then return end
	connections.aimbot = runService.RenderStepped:Connect(function()
		if not (features.aimbot or features.aimAssist) then return end
		pcall(function()
			local target = getClosestTarget(features.aimFOV)
			if not target then return end
			local goal = predictPosition(target)
			if features.aimbot then
				local cf = CFrame.new(camera.CFrame.Position, goal)
				camera.CFrame = camera.CFrame:Lerp(cf, math.clamp(1 - features.aimSmooth, 0.05, 1))
			elseif features.aimAssist then
				local cf = CFrame.new(camera.CFrame.Position, goal)
				camera.CFrame = camera.CFrame:Lerp(cf, math.clamp(0.35 - features.aimSmooth * 0.2, 0.02, 0.25))
			end
		end)
	end)
end

function PotassiumHub:manageSilentAim()
	if connections.silent then connections.silent:Disconnect() connections.silent = nil end
	if not features.silentAim then return end
	connections.silent = runService.Heartbeat:Connect(function()
		if not features.silentAim then return end
		pcall(function()
			local target = getClosestTarget(features.aimFOV)
			if not target then return end
			if math.random(1, 100) > features.hitChance then return end
			local goal = predictPosition(target)
			local char = localPlayer.Character
			local hrp = getRoot(char)
			if hrp then
				hrp.CFrame = CFrame.lookAt(hrp.Position, goal)
			end
		end)
	end)
end

function PotassiumHub:manageTriggerbot()
	if connections.trigger then connections.trigger:Disconnect() connections.trigger = nil end
	if not features.triggerbot then return end
	connections.trigger = runService.RenderStepped:Connect(function()
		if not features.triggerbot then return end
		pcall(function()
			local target = getClosestTarget(math.min(features.aimFOV, 80))
			if not target then return end
			local tool = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Tool")
			if tool then
				pcall(function() tool:Activate() end)
			end
			pcall(function()
				virtualUser:Button1Down(Vector2.new(0, 0), camera.CFrame)
				task.wait(0.02)
				virtualUser:Button1Up(Vector2.new(0, 0), camera.CFrame)
			end)
		end)
	end)
end

function PotassiumHub:manageFOV()
	if fovCircle and fovCircle.Parent then
		fovCircle:Destroy()
		fovCircle = nil
	end
	if not features.showFOV then return end
	local gui = Instance.new("ScreenGui")
	gui.Name = "PotassiumFOV"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = coreGui
	local ring = Instance.new("Frame")
	ring.Name = "FOVRing"
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.BackgroundTransparency = 1
	ring.BorderSizePixel = 0
	ring.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.FOV_COLOR
	stroke.Thickness = 1.5
	stroke.Transparency = 0.35
	stroke.Parent = ring
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ring
	fovCircle = gui
	connections.fovUpdate = runService.RenderStepped:Connect(function()
		if not features.showFOV or not ring.Parent then return end
		local size = features.aimFOV * 2
		ring.Size = UDim2.fromOffset(size, size)
	end)
end

local function clearESP()
	for _, obj in pairs(espObjects) do
		pcall(function() obj:Destroy() end)
	end
	table.clear(espObjects)
end

local function createESPForPlayer(plr)
	if espObjects[plr] then return end
	local char = plr.Character
	if not char then return end
	local hrp = getRoot(char)
	if not hrp then return end

	local folder = Instance.new("Folder")
	folder.Name = "PH_ESP_" .. plr.Name

	if features.espChams then
		local hl = Instance.new("Highlight")
		hl.Name = "Chams"
		hl.Adornee = char
		hl.FillColor = COLORS.ESP_ENEMY
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.FillTransparency = 0.55
		hl.OutlineTransparency = 0.2
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = folder
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Info"
	billboard.Adornee = hrp
	billboard.Size = UDim2.new(0, 160, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3.2, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = features.espMaxDist
	billboard.Parent = folder

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, 0, 0, 18)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = features.espNames and plr.DisplayName or ""
	nameLabel.TextColor3 = COLORS.PRIMARY
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.TextSize = 13
	nameLabel.Font = currentFont
	nameLabel.Parent = billboard

	local distLabel = Instance.new("TextLabel")
	distLabel.Name = "Dist"
	distLabel.Size = UDim2.new(1, 0, 0, 16)
	distLabel.Position = UDim2.new(0, 0, 0, 18)
	distLabel.BackgroundTransparency = 1
	distLabel.TextColor3 = COLORS.SECONDARY
	distLabel.TextStrokeTransparency = 0.5
	distLabel.TextSize = 11
	distLabel.Font = currentFont
	distLabel.Parent = billboard

	local healthBarBg = Instance.new("Frame")
	healthBarBg.Name = "HealthBg"
	healthBarBg.Size = UDim2.new(0.7, 0, 0, 4)
	healthBarBg.Position = UDim2.new(0.15, 0, 0, 36)
	healthBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	healthBarBg.BorderSizePixel = 0
	healthBarBg.Visible = features.espHealth
	healthBarBg.Parent = billboard
	local hc = Instance.new("UICorner")
	hc.CornerRadius = UDim.new(1, 0)
	hc.Parent = healthBarBg
	local healthBar = Instance.new("Frame")
	healthBar.Name = "Health"
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.BackgroundColor3 = Color3.fromRGB(80, 255, 120)
	healthBar.BorderSizePixel = 0
	healthBar.Parent = healthBarBg
	local hc2 = Instance.new("UICorner")
	hc2.CornerRadius = UDim.new(1, 0)
	hc2.Parent = healthBar

	if features.espTracers then
		local tracer = Instance.new("Beam")
		local a0 = Instance.new("Attachment")
		a0.Name = "PH_A0"
		a0.Parent = camera
		local a1 = Instance.new("Attachment")
		a1.Name = "PH_A1"
		a1.Parent = hrp
		tracer.Attachment0 = a0
		tracer.Attachment1 = a1
		tracer.Width0 = 0.05
		tracer.Width1 = 0.02
		tracer.Color = ColorSequence.new(COLORS.ESP_ENEMY)
		tracer.FaceCamera = true
		tracer.Parent = folder
	end

	folder.Parent = coreGui
	espObjects[plr] = folder
end

function PotassiumHub:manageESP()
	if connections.esp then connections.esp:Disconnect() connections.esp = nil end
	clearESP()
	if not features.espEnabled then return end
	local function refresh()
		for _, plr in ipairs(playersService:GetPlayers()) do
			if isEnemy(plr) and isAlive(plr) then
				createESPForPlayer(plr)
			elseif espObjects[plr] then
				pcall(function() espObjects[plr]:Destroy() end)
				espObjects[plr] = nil
			end
		end
	end
	refresh()
	connections.esp = runService.Heartbeat:Connect(function()
		if not features.espEnabled then return end
		pcall(function()
			local myRoot = getRoot(localPlayer.Character)
			for plr, folder in pairs(espObjects) do
				if not isAlive(plr) or not isEnemy(plr) then
					pcall(function() folder:Destroy() end)
					espObjects[plr] = nil
				else
					local char = plr.Character
					local hrp = getRoot(char)
					local hum = getHumanoid(char)
					if hrp and hum and folder:FindFirstChild("Info") then
						local info = folder.Info
						if features.espDistance and myRoot then
							local d = (hrp.Position - myRoot.Position).Magnitude
							info.Dist.Text = math.floor(d) .. "m"
						else
							info.Dist.Text = ""
						end
						if features.espHealth then
							local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
							info.HealthBg.Health.Size = UDim2.new(pct, 0, 1, 0)
							info.HealthBg.Health.BackgroundColor3 = Color3.fromRGB(255 * (1 - pct), 255 * pct, 60)
							info.HealthBg.Visible = true
						else
							info.HealthBg.Visible = false
						end
						info.Name.Text = features.espNames and plr.DisplayName or ""
						local hl = folder:FindFirstChild("Chams")
						if hl then
							local vis = isVisible(hrp)
							hl.FillColor = vis and COLORS.ESP_VISIBLE or COLORS.ESP_ENEMY
						end
					end
				end
			end
			for _, plr in ipairs(playersService:GetPlayers()) do
				if isEnemy(plr) and isAlive(plr) and not espObjects[plr] then
					createESPForPlayer(plr)
				end
			end
		end)
	end)
	playersService.PlayerRemoving:Connect(function(plr)
		if espObjects[plr] then
			pcall(function() espObjects[plr]:Destroy() end)
			espObjects[plr] = nil
		end
	end)
end

function PotassiumHub:manageSpeed()
	if connections.speed then connections.speed:Disconnect() connections.speed = nil end
	if not features.speedEnabled then
		pcall(function()
			local hum = getHumanoid(localPlayer.Character)
			if hum then hum.WalkSpeed = 16 end
		end)
		return
	end
	connections.speed = runService.Heartbeat:Connect(function()
		if not features.speedEnabled then return end
		pcall(function()
			local hum = getHumanoid(localPlayer.Character)
			if hum then hum.WalkSpeed = 16 * features.speedMultiplier end
		end)
	end)
end

function PotassiumHub:manageFly()
	if connections.fly then connections.fly:Disconnect() connections.fly = nil end
	if not features.flyEnabled then return end
	connections.fly = runService.Heartbeat:Connect(function()
		if not features.flyEnabled then return end
		pcall(function()
			local hrp = getRoot(localPlayer.Character)
			if not hrp then return end
			flyDirection = Vector3.zero
			local look = camera.CFrame.LookVector
			local right = camera.CFrame.RightVector
			if userInputService:IsKeyDown(Enum.KeyCode.W) then flyDirection += look end
			if userInputService:IsKeyDown(Enum.KeyCode.S) then flyDirection -= look end
			if userInputService:IsKeyDown(Enum.KeyCode.A) then flyDirection -= right end
			if userInputService:IsKeyDown(Enum.KeyCode.D) then flyDirection += right end
			if userInputService:IsKeyDown(Enum.KeyCode.Space) then flyDirection += Vector3.new(0, 1, 0) end
			if userInputService:IsKeyDown(Enum.KeyCode.LeftControl) then flyDirection -= Vector3.new(0, 1, 0) end
			if flyDirection.Magnitude > 0 then
				hrp.AssemblyLinearVelocity = flyDirection.Unit * features.flySpeed
			else
				hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			end
		end)
	end)
end

function PotassiumHub:manageNoClip()
	if connections.noclip then connections.noclip:Disconnect() connections.noclip = nil end
	if not features.noclipEnabled then return end
	connections.noclip = runService.Stepped:Connect(function()
		if not features.noclipEnabled then return end
		pcall(function()
			local char = localPlayer.Character
			if not char then return end
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end)
	end)
end

function PotassiumHub:manageInfiniteJump()
	if connections.ijump then connections.ijump:Disconnect() connections.ijump = nil end
	if not features.infiniteJump then return end
	connections.ijump = userInputService.JumpRequest:Connect(function()
		if not features.infiniteJump then return end
		local hum = getHumanoid(localPlayer.Character)
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)
end

function PotassiumHub:manageBunnyHop()
	if connections.bhop then connections.bhop:Disconnect() connections.bhop = nil end
	if not features.bunnyHop then return end
	connections.bhop = runService.Heartbeat:Connect(function()
		if not features.bunnyHop then return end
		pcall(function()
			local hum = getHumanoid(localPlayer.Character)
			if hum and hum.FloorMaterial ~= Enum.Material.Air then
				hum.Jump = true
			end
		end)
	end)
end

function PotassiumHub:manageGodMode()
	if connections.god then connections.god:Disconnect() connections.god = nil end
	if not features.godMode then return end
	connections.god = runService.Heartbeat:Connect(function()
		if not features.godMode then return end
		pcall(function()
			local hum = getHumanoid(localPlayer.Character)
			if hum then
				hum.Health = hum.MaxHealth
			end
		end)
	end)
end

function PotassiumHub:manageAntiAfk()
	if connections.afk then connections.afk:Disconnect() connections.afk = nil end
	if not features.antiAfk then return end
	connections.afk = localPlayer.Idled:Connect(function()
		pcall(function()
			virtualUser:CaptureController()
			virtualUser:ClickButton2(Vector2.new())
		end)
	end)
end

function PotassiumHub:manageFullbright()
	if features.fullbright then
		lighting.Brightness = 2
		lighting.ClockTime = 14
		lighting.FogEnd = 100000
		lighting.GlobalShadows = false
		lighting.Ambient = Color3.fromRGB(180, 180, 180)
	else
		lighting.Brightness = 1
		lighting.GlobalShadows = true
	end
end

function PotassiumHub:manageNoFog()
	if features.noFog then
		lighting.FogEnd = 100000
		lighting.FogStart = 100000
	end
end

function PotassiumHub:manageSpinBot()
	if connections.spin then connections.spin:Disconnect() connections.spin = nil end
	if not features.spinBot then return end
	connections.spin = runService.RenderStepped:Connect(function(dt)
		if not features.spinBot then return end
		pcall(function()
			local hrp = getRoot(localPlayer.Character)
			if hrp then
				hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(features.spinSpeed * 60 * dt), 0)
			end
		end)
	end)
end

function PotassiumHub:manageCrosshair()
	if crosshairGui then
		crosshairGui:Destroy()
		crosshairGui = nil
	end
	if not features.customCrosshair then return end
	local gui = Instance.new("ScreenGui")
	gui.Name = "PotassiumCrosshair"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = coreGui
	local size = features.crosshairSize
	local function makeLine(w, h, x, y)
		local f = Instance.new("Frame")
		f.Size = UDim2.fromOffset(w, h)
		f.Position = UDim2.new(0.5, x, 0.5, y)
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.BackgroundColor3 = COLORS.PRIMARY
		f.BorderSizePixel = 0
		f.Parent = gui
		return f
	end
	makeLine(size * 2, 2, 0, -(size + 4))
	makeLine(size * 2, 2, 0, size + 4)
	makeLine(2, size * 2, -(size + 4), 0)
	makeLine(2, size * 2, size + 4, 0)
	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromOffset(3, 3)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.BackgroundColor3 = COLORS.ACCENT
	dot.BorderSizePixel = 0
	dot.Parent = gui
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(1, 0)
	dc.Parent = dot
	crosshairGui = gui
end

function PotassiumHub:doServerHop()
	pcall(function()
		local placeId = game.PlaceId
		local servers = httpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=50"))
		for _, s in ipairs(servers.data or {}) do
			if s.id ~= game.JobId and s.playing < s.maxPlayers then
				teleportService:TeleportToPlaceInstance(placeId, s.id, localPlayer)
				return
			end
		end
		teleportService:Teleport(placeId, localPlayer)
	end)
end

function PotassiumHub:doRejoin()
	pcall(function()
		teleportService:Teleport(game.PlaceId, localPlayer)
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
	logoImage.ZIndex = 11
	logoImage.Parent = iconContainer
	applyLogo(logoImage)

	local dragging, dragStart, startPos = false, nil, nil
	iconContainer.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = iconContainer.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	userInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			if dragStart and startPos then
				local delta = input.Position - dragStart
				iconContainer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end
	end)

	local clickStartPos, clickStartTime
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
	loadingLogo.Parent = bg
	applyLogo(loadingLogo)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0, 400, 0, 40)
	title.Position = UDim2.new(0.5, -200, 0.52, 0)
	title.BackgroundTransparency = 1
	title.Text = "POTASSIUM  ·  RIVALS"
	title.TextColor3 = COLORS.PRIMARY
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.Parent = bg

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(0, 400, 0, 24)
	sub.Position = UDim2.new(0.5, -200, 0.58, 0)
	sub.BackgroundTransparency = 1
	sub.Text = "Loading modules..."
	sub.TextColor3 = COLORS.TEXT_SECONDARY
	sub.TextSize = 14
	sub.Font = Enum.Font.Gotham
	sub.Parent = bg

	task.delay(2, function()
		pcall(function() loadingGui:Destroy() end)
	end)
end

function PotassiumHub:createUI()
	if PotassiumHub.mainGui and PotassiumHub.mainGui.Parent then
		PotassiumHub.mainGui:Destroy()
	end

	local mainGui = Instance.new("ScreenGui")
	mainGui.Name = "PotassiumUIMain"
	mainGui.ResetOnSpawn = false
	mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	mainGui.Parent = coreGui
	PotassiumHub.mainGui = mainGui

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 480, 0, 640)
	mainFrame.Position = UDim2.new(0.5, -240, 0.5, -320)
	mainFrame.BackgroundColor3 = COLORS.BG_DARK
	mainFrame.BackgroundTransparency = 0.18
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = mainGui
	applyGlass(mainFrame, 0.28)
	local mainCorner = mainFrame:FindFirstChildOfClass("UICorner")
	if mainCorner then mainCorner.CornerRadius = UDim.new(0, 20) end

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 68)
	header.BackgroundColor3 = COLORS.GLASS_DARK
	header.BackgroundTransparency = 0.35
	header.BorderSizePixel = 0
	header.Parent = mainFrame
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 20)
	headerCorner.Parent = header
	applyGlass(header, 0.35)

	local headerLogo = Instance.new("ImageLabel")
	headerLogo.Size = UDim2.new(0, 40, 0, 40)
	headerLogo.Position = UDim2.new(0, 20, 0.5, -20)
	headerLogo.BackgroundTransparency = 1
	headerLogo.Parent = header
	applyLogo(headerLogo)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0, 220, 0, 50)
	title.Position = UDim2.new(0, 68, 0.5, -25)
	title.BackgroundTransparency = 1
	title.TextColor3 = COLORS.PRIMARY
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.Text = "POTASSIUM  ·  RIVALS"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local dragging, dragStart, startPos = false, nil, nil
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
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	userInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			if dragStart and startPos then
				local delta = input.Position - dragStart
				mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end
	end)

	local minBtn = Instance.new("TextButton")
	minBtn.Size = UDim2.new(0, 40, 0, 40)
	minBtn.Position = UDim2.new(1, -92, 0, 14)
	minBtn.BackgroundTransparency = 0.4
	minBtn.Text = ""
	minBtn.Parent = header
	applyGlass(minBtn, 0.4)
	createIconImage(minBtn, ICONS.Minus)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -46, 0, 14)
	closeBtn.BackgroundTransparency = 0.4
	closeBtn.Text = ""
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
	scroll.CanvasSize = UDim2.new(0, 0, 0, 1200)
	scroll.Parent = mainFrame
	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 18)
	scrollCorner.Parent = scroll

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 12)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = scroll
	local scrollPad = Instance.new("UIPadding")
	scrollPad.PaddingLeft = UDim.new(0, 14)
	scrollPad.PaddingRight = UDim.new(0, 14)
	scrollPad.PaddingTop = UDim.new(0, 14)
	scrollPad.PaddingBottom = UDim.new(0, 20)
	scrollPad.Parent = scroll
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 40)
	end)

	local isMinimized = false
	minBtn.MouseButton1Click:Connect(function()
		isMinimized = not isMinimized
		if isMinimized then
			tweenService:Create(mainFrame, TweenInfo.new(0.25), {Size = UDim2.new(0, 480, 0, 68)}):Play()
			scroll.Visible = false
		else
			tweenService:Create(mainFrame, TweenInfo.new(0.25), {Size = UDim2.new(0, 480, 0, 640)}):Play()
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

	local function createToggle(text, key, parent, callback)
		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 0, 44)
		container.BackgroundTransparency = 0.25
		container.Parent = parent
		applyGlass(container, 0.38)

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.65, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = COLORS.TEXT_PRIMARY
		label.TextSize = 13
		label.Font = currentFont
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
		toggle.Parent = container
		local tc = Instance.new("UICorner")
		tc.CornerRadius = UDim.new(0, 11)
		tc.Parent = toggle

		local ball = Instance.new("Frame")
		ball.Size = UDim2.new(0, 18, 0, 18)
		ball.Position = UDim2.new(0, 2, 0.5, -9)
		ball.BackgroundColor3 = COLORS.TEXT_SECONDARY
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
			if callback then callback() end
		end)
		if features[key] then
			ball.Position = UDim2.new(0, 24, 0.5, -9)
			ball.BackgroundColor3 = COLORS.ACCENT
			toggle.BackgroundColor3 = Color3.fromRGB(55, 55, 68)
		end
	end

	local function createNumberInput(text, key, minVal, maxVal, parent, callback)
		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 0, 58)
		container.BackgroundTransparency = 0.25
		container.Parent = parent
		applyGlass(container, 0.38)

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -28, 0, 16)
		label.Position = UDim2.new(0, 14, 0, 6)
		label.BackgroundTransparency = 1
		label.TextColor3 = COLORS.TEXT_PRIMARY
		label.TextSize = 12
		label.Font = Enum.Font.GothamBold
		label.Text = text .. " (" .. tostring(features[key]) .. ")"
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = container

		local inputBox = Instance.new("TextBox")
		inputBox.Size = UDim2.new(1, -28, 0, 26)
		inputBox.Position = UDim2.new(0, 14, 0, 26)
		inputBox.BackgroundColor3 = COLORS.BG_LIGHT
		inputBox.BackgroundTransparency = 0.25
		inputBox.TextColor3 = COLORS.TEXT_PRIMARY
		inputBox.PlaceholderColor3 = COLORS.TEXT_SECONDARY
		inputBox.TextSize = 12
		inputBox.Font = currentFont
		inputBox.Text = tostring(features[key])
		inputBox.PlaceholderText = minVal .. " - " .. maxVal
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
				val = math.clamp(val, minVal, maxVal)
				if key == "aimSmooth" or key == "aimPrediction" or key == "shootSpeed" then
					val = math.floor(val * 100) / 100
				else
					val = math.floor(val)
				end
				features[key] = val
				inputBox.Text = tostring(val)
				label.Text = text .. " (" .. tostring(val) .. ")"
				if callback then callback() end
			else
				inputBox.Text = tostring(features[key])
			end
		end)
	end

	local function createDropdown(text, key, options, parent, callback)
		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 0, 44)
		container.BackgroundTransparency = 0.25
		container.Parent = parent
		applyGlass(container, 0.38)

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = COLORS.TEXT_PRIMARY
		label.TextSize = 13
		label.Font = currentFont
		label.Text = text .. ": " .. tostring(features[key])
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = container
		local lp = Instance.new("UIPadding")
		lp.PaddingLeft = UDim.new(0, 14)
		lp.Parent = label

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.Parent = container
		local idx = 1
		for i, opt in ipairs(options) do
			if opt == features[key] then idx = i break end
		end
		btn.MouseButton1Click:Connect(function()
			idx = idx % #options + 1
			features[key] = options[idx]
			label.Text = text .. ": " .. tostring(features[key])
			if callback then callback() end
		end)
	end

	local function createSubcategory(text, parent)
		local sub = Instance.new("Frame")
		sub.Size = UDim2.new(1, 0, 0, 30)
		sub.BackgroundTransparency = 0.55
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

	local function createButton(text, parent, callback)
		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 0, 42)
		container.BackgroundTransparency = 0.3
		container.Parent = parent
		applyGlass(container, 0.4)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = COLORS.PRIMARY
		label.TextSize = 13
		label.Font = Enum.Font.GothamBold
		label.Text = text
		label.Parent = container
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.Parent = container
		btn.MouseButton1Click:Connect(function()
			if callback then callback() end
		end)
	end

	local function createSection(titleText, sectionKey, iconAsset)
		local section = Instance.new("Frame")
		section.Size = UDim2.new(1, 0, 0, 42)
		section.BackgroundTransparency = 1
		section.ClipsDescendants = true
		section.Parent = scroll

		local sectionHeader = Instance.new("Frame")
		sectionHeader.Size = UDim2.new(1, 0, 0, 42)
		sectionHeader.Position = UDim2.new(0, 0, 0, 0)
		sectionHeader.BackgroundTransparency = 0.32
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
		headerLabel.Text = titleText
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
		contentHolder.Position = UDim2.new(0, 0, 0, 42)
		contentHolder.BackgroundTransparency = 1
		contentHolder.Parent = section

		local contentList = Instance.new("UIListLayout")
		contentList.Padding = UDim.new(0, 8)
		contentList.SortOrder = Enum.SortOrder.LayoutOrder
		contentList.Parent = contentHolder

		local contentPad = Instance.new("UIPadding")
		contentPad.PaddingLeft = UDim.new(0, 6)
		contentPad.PaddingRight = UDim.new(0, 6)
		contentPad.PaddingTop = UDim.new(0, 8)
		contentPad.PaddingBottom = UDim.new(0, 6)
		contentPad.Parent = contentHolder

		local isExpanded = PotassiumHub.sectionStates[sectionKey] ~= false
		local animating = false

		local function updateSize()
			if isExpanded then
				local h = contentList.AbsoluteContentSize.Y + 16
				section.Size = UDim2.new(1, 0, 0, 42 + h)
				contentHolder.Size = UDim2.new(1, 0, 0, h)
			else
				section.Size = UDim2.new(1, 0, 0, 42)
				contentHolder.Size = UDim2.new(1, 0, 0, 0)
			end
		end

		local headerBtn = Instance.new("TextButton")
		headerBtn.Size = UDim2.new(1, 0, 1, 0)
		headerBtn.BackgroundTransparency = 1
		headerBtn.Text = ""
		headerBtn.Parent = sectionHeader
		headerBtn.MouseButton1Click:Connect(function()
			if animating then return end
			animating = true
			isExpanded = not isExpanded
			PotassiumHub.sectionStates[sectionKey] = isExpanded
			expandIcon.Image = isExpanded and ICONS.ChevronDown or ICONS.ChevronRight
			local tweenInfo = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			if isExpanded then
				contentHolder.Visible = true
				local h = contentList.AbsoluteContentSize.Y + 16
				tweenService:Create(section, tweenInfo, {Size = UDim2.new(1, 0, 0, 42 + h)}):Play()
				tweenService:Create(contentHolder, tweenInfo, {Size = UDim2.new(1, 0, 0, h)}):Play()
				task.delay(0.32, function() animating = false end)
			else
				tweenService:Create(section, tweenInfo, {Size = UDim2.new(1, 0, 0, 42)}):Play()
				tweenService:Create(contentHolder, tweenInfo, {Size = UDim2.new(1, 0, 0, 0)}):Play()
				task.delay(0.32, function()
					if not isExpanded then contentHolder.Visible = false end
					animating = false
				end)
			end
		end)

		contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			if isExpanded and not animating then updateSize() end
		end)

		if isExpanded then
			contentHolder.Visible = true
			task.defer(updateSize)
		else
			contentHolder.Visible = false
		end

		return contentHolder
	end

	local combat = createSection("COMBAT", "COMBAT", ICONS.Crosshair)
	createSubcategory("Aiming", combat)
	createToggle("Aimbot", "aimbot", combat, function() PotassiumHub:manageAimbot() end)
	createToggle("Aim Assist", "aimAssist", combat, function() PotassiumHub:manageAimbot() end)
	createToggle("Silent Aim", "silentAim", combat, function() PotassiumHub:manageSilentAim() end)
	createToggle("Triggerbot", "triggerbot", combat, function() PotassiumHub:manageTriggerbot() end)
	createToggle("Show FOV Circle", "showFOV", combat, function() PotassiumHub:manageFOV() end)
	createNumberInput("FOV Size", "aimFOV", 20, 400, combat, function() PotassiumHub:manageFOV() end)
	createNumberInput("Smoothness", "aimSmooth", 0.01, 0.95, combat)
	createNumberInput("Prediction", "aimPrediction", 0, 0.5, combat)
	createNumberInput("Hit Chance %", "hitChance", 1, 100, combat)
	createDropdown("Target Part", "aimPart", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, combat)
	createSubcategory("Checks", combat)
	createToggle("Team Check", "teamCheck", combat)
	createToggle("Visible Check", "visibleCheck", combat)

	local visuals = createSection("VISUALS", "VISUALS", ICONS.Eye)
	createSubcategory("ESP", visuals)
	createToggle("Enable ESP", "espEnabled", visuals, function() PotassiumHub:manageESP() end)
	createToggle("Boxes / Chams", "espChams", visuals, function() if features.espEnabled then PotassiumHub:manageESP() end end)
	createToggle("Names", "espNames", visuals)
	createToggle("Distance", "espDistance", visuals)
	createToggle("Health Bar", "espHealth", visuals)
	createToggle("Tracers", "espTracers", visuals, function() if features.espEnabled then PotassiumHub:manageESP() end end)
	createNumberInput("Max Distance", "espMaxDist", 50, 2000, visuals)
	createSubcategory("Screen", visuals)
	createToggle("Custom Crosshair", "customCrosshair", visuals, function() PotassiumHub:manageCrosshair() end)
	createNumberInput("Crosshair Size", "crosshairSize", 4, 24, visuals, function() PotassiumHub:manageCrosshair() end)
	createToggle("Fullbright", "fullbright", visuals, function() PotassiumHub:manageFullbright() end)
	createToggle("No Fog", "noFog", visuals, function() PotassiumHub:manageNoFog() end)

	local movement = createSection("MOVEMENT", "MOVEMENT", ICONS.Move)
	createSubcategory("Flight & Speed", movement)
	createToggle("Fly", "flyEnabled", movement, function() PotassiumHub:manageFly() end)
	createNumberInput("Fly Speed", "flySpeed", 10, 200, movement)
	createToggle("Speed Boost", "speedEnabled", movement, function() PotassiumHub:manageSpeed() end)
	createNumberInput("Speed Multiplier", "speedMultiplier", 1, 5, movement)
	createSubcategory("Physics", movement)
	createToggle("No Clip", "noclipEnabled", movement, function() PotassiumHub:manageNoClip() end)
	createToggle("Infinite Jump", "infiniteJump", movement, function() PotassiumHub:manageInfiniteJump() end)
	createToggle("Bunny Hop", "bunnyHop", movement, function() PotassiumHub:manageBunnyHop() end)
	createToggle("Spin Bot", "spinBot", movement, function() PotassiumHub:manageSpinBot() end)
	createNumberInput("Spin Speed", "spinSpeed", 1, 40, movement)

	local utility = createSection("UTILITY", "UTILITY", ICONS.Shield)
	createSubcategory("Character", utility)
	createToggle("God Mode", "godMode", utility, function() PotassiumHub:manageGodMode() end)
	createToggle("Anti AFK", "antiAfk", utility, function() PotassiumHub:manageAntiAfk() end)
	createSubcategory("Server", utility)
	createButton("Server Hop", utility, function() PotassiumHub:doServerHop() end)
	createButton("Rejoin", utility, function() PotassiumHub:doRejoin() end)

	local config = createSection("CONFIG", "CONFIG", ICONS.Settings)
	createSubcategory("Theme", config)
	createDropdown("Font", "fontChoice", {"Gotham", "GothamBold", "SourceSans", "SourceSansBold", "Ubuntu", "Arial"}, config, function()
		local map = {
			Gotham = Enum.Font.Gotham,
			GothamBold = Enum.Font.GothamBold,
			SourceSans = Enum.Font.SourceSans,
			SourceSansBold = Enum.Font.SourceSansBold,
			Ubuntu = Enum.Font.Ubuntu,
			Arial = Enum.Font.Arial,
		}
		currentFont = map[features.fontChoice] or Enum.Font.Gotham
	end)
	features.fontChoice = features.fontChoice or "Gotham"
	createButton("Reset All Features", config, function()
		for k, v in pairs(FEATURE_DEFAULTS) do features[k] = v end
		PotassiumHub:manageAimbot()
		PotassiumHub:manageSilentAim()
		PotassiumHub:manageTriggerbot()
		PotassiumHub:manageFOV()
		PotassiumHub:manageESP()
		PotassiumHub:manageSpeed()
		PotassiumHub:manageFly()
		PotassiumHub:manageNoClip()
		PotassiumHub:manageInfiniteJump()
		PotassiumHub:manageBunnyHop()
		PotassiumHub:manageGodMode()
		PotassiumHub:manageSpinBot()
		PotassiumHub:manageCrosshair()
		PotassiumHub:manageFullbright()
	end)

	PotassiumHub.uiVisible = true
	PotassiumHub:manageFOV()
	if features.antiAfk then PotassiumHub:manageAntiAfk() end
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
		else
			PotassiumHub:createUI()
		end
	end
end)

localPlayer.CharacterAdded:Connect(function(newChar)
	character = newChar
	afkTimer = 0
	flyDirection = Vector3.zero
	task.wait(0.5)
	if features.espEnabled then PotassiumHub:manageESP() end
	if features.speedEnabled then PotassiumHub:manageSpeed() end
	if features.flyEnabled then PotassiumHub:manageFly() end
	if features.noclipEnabled then PotassiumHub:manageNoClip() end
	if features.godMode then PotassiumHub:manageGodMode() end
end)

local function initializeScript()
	PotassiumHub.active = true
	PotassiumHub:showLoading()
	task.wait(2)
	PotassiumHub:createUI()
	print("POTASSIUM HUB · RIVALS | Toggle: RIGHT CTRL | 30+ features")
end

xpcall(initializeScript, function(err)
	warn("POTASSIUM HUB RIVALS init fail: " .. tostring(err))
end)

if shared.PotassiumHub then
	shared.PotassiumHub.active = false
end
shared.PotassiumHub = PotassiumHub
