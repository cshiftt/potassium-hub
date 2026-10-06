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
		MAIN = true, AUTO = true, KIDS = true, COMBAT = true, BRING = true,
		PLANT = true, FARM = true, CAMP = true, CRAFT = true, BASE = true, ANTI = true,
		TP = true, ESP = true, PERF = true, PLAYER = true, SHOP = true, CONFIG = true,
	},
}
PotassiumHub.__index = PotassiumHub

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CollectionService = game:GetService("CollectionService")

local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local Camera = workspace.CurrentCamera
local Character = LP.Character or LP.CharacterAdded:Wait()

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
	ESP_ITEM = Color3.fromRGB(90, 200, 255),
	ESP_MOB = Color3.fromRGB(255, 80, 80),
	ESP_KID = Color3.fromRGB(255, 220, 80),
	ESP_CHEST = Color3.fromRGB(180, 255, 100),
}

local LOGO_ID = 91234368312745
local LOGO_ASSET = "rbxthumb://type=Asset&id=" .. LOGO_ID .. "&w=420&h=420"
local LOGO_FALLBACK = "rbxassetid://" .. LOGO_ID

local ICONS = {
	Minus = "rbxassetid://79191240000290",
	X = "rbxassetid://134784309661522",
	ChevronDown = "rbxassetid://71457658246709",
	ChevronRight = "rbxassetid://101007429951147",
}

local KEYCODE_MAP = {
	RightControl = Enum.KeyCode.RightControl, LeftControl = Enum.KeyCode.LeftControl,
	RightShift = Enum.KeyCode.RightShift, LeftShift = Enum.KeyCode.LeftShift,
	RightAlt = Enum.KeyCode.RightAlt, LeftAlt = Enum.KeyCode.LeftAlt,
	Insert = Enum.KeyCode.Insert, Delete = Enum.KeyCode.Delete,
	Home = Enum.KeyCode.Home, End = Enum.KeyCode.End,
	F1 = Enum.KeyCode.F1, F2 = Enum.KeyCode.F2, F3 = Enum.KeyCode.F3, F4 = Enum.KeyCode.F4,
	F5 = Enum.KeyCode.F5, F6 = Enum.KeyCode.F6, F7 = Enum.KeyCode.F7, F8 = Enum.KeyCode.F8,
	V = Enum.KeyCode.V, B = Enum.KeyCode.B, N = Enum.KeyCode.N, M = Enum.KeyCode.M,
	P = Enum.KeyCode.P, K = Enum.KeyCode.K, L = Enum.KeyCode.L,
}

local FEATURES = {
	-- Main
	infiniteSapling = false, unlimitedHealth = false, autoEat = false,
	autoChop = false, chopHits = 3, chopRadius = 50,
	killAura = false, auraRange = 40, worldInfo = false,
	finishMaze = false, collectMazeTickets = false,
	-- Kids
	autoFindKids = false, autoCollectKids = false, kidsProgressUI = true,
	-- Auto systems
	autoStronghold = false, autoCorrupted = false, autoCook = false,
	autoBiofuel = false, autoCampfire = false, autoPickupKid = false,
	autoCloseGate = false, autoSelfRevive = false, autoReviveTeam = false,
	autoSkipNight = false, autoWeather = false, autoPlant = false,
	classDecorator = false, classExplorer = false,
	-- Combat
	chopAura = false, autoKillAll = false, autoKillMossy = false,
	autoKillCultist = false, autoSacrifice = false, autoStun = false,
	-- Loot
	autoOpenChest = false, autoCoins = false, autoDiamonds = false,
	autoFish = false, autoFlowers = false, autoScrap = false,
	autoCultistGem = false, autoRecycler = false, autoStew = false,
	autoMedicine = false, bringCustomName = "",
	-- Bring
	bringAllItems = false, bringFuels = false, bringFood = false,
	bringGuns = false, bringChars = false, bringMobs = false,
	bringTrees = false, bringSpeed = 80, bringMax = 50, bringCooldown = 0.15,
	bringHeight = 3, bringMethod = "Tween", noBringLimit = true,
	-- Plant
	plantRadius = 40, plantDistance = 6, plantSpeed = 0.3,
	plantMethod = "Around Camp", plantShape = "Circle", plantPreview = false, autoSapling = false,
	-- Farm
	autoTreeFarm = false, treeFarmSize = "Both",
	-- Camp
	upgradeCampfire = false, autoFillCampfire = false, fuelWhenHP = 40, autoCookFood = false,
	autoMakeBase = false, autoPlaceStructures = false, autoPickupStructures = false,
	autoDropBlueprints = false, autoTakeBlueprints = false, autoBuyFurniture = false,
	baseRadius = 30, baseSpacing = 8, baseShape = "Grid",
	-- Craft
	autoCraft = false, craftAmount = 1, craftDelay = 0.4, craftSelected = "",
	-- Anti
	autoEscape = false, escapeDeer = false, deerMethod = "Tween", deerDist = 40, deerSpeed = 60,
	escapeOwl = false, owlMethod = "Tween", owlDist = 50, owlSpeed = 60,
	autoAvoid = false, avoidRadius = 35, avoidSpeed = 55, avoidMethod = "Tween",
	-- TP
	autoOpenAllChests = false, createSafeZone = false,
	-- ESP
	espItems = false, espMobs = false, espKids = false, espChests = false, espChars = false,
	-- Perf
	fpsBoost = false, removeSky = false, removeFog = false,
	delCampLogs = false, delBigTrees = false, delStones = false, delBushes = false, delGrass = false,
	-- Player
	antiVoid = true, quickInteract = false, noclip = false, freezeChar = false,
	antiAfk = true, tpClick = false, infJump = false,
	walkSpeed = 16, jumpPower = 50, gravity = 196.2, fov = 70, fly = false, flySpeed = 60,
	-- Config
	toggleKey = "RightControl",
}

local connections = {}
local espFolder = nil
local flyDir = Vector3.zero
local currentFont = Enum.Font.Gotham

local function getToggleKeyCode()
	return KEYCODE_MAP[FEATURES.toggleKey] or Enum.KeyCode.RightControl
end

local function applyLogo(img)
	img.Image = LOGO_ASSET
	img.ImageColor3 = Color3.new(1, 1, 1)
	img.ScaleType = Enum.ScaleType.Fit
	img.BackgroundTransparency = 1
	task.spawn(function()
		pcall(function() ContentProvider:PreloadAsync({img}) end)
		task.wait(1)
		if not img.IsLoaded or img.Image == "" then img.Image = LOGO_FALLBACK end
	end)
end

local function applyGlass(frame, intensity)
	intensity = intensity or 0.42
	frame.BackgroundColor3 = COLORS.GLASS_DARK
	frame.BackgroundTransparency = intensity
	local stroke = frame:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	stroke.Color = COLORS.GLASS
	stroke.Thickness = 1
	stroke.Transparency = 0.72
	stroke.Parent = frame
	local corner = frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
end

local function getRoot(char)
	return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end

local function getHum(char)
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function tpTo(pos)
	local hrp = getRoot(LP.Character)
	if hrp and typeof(pos) == "Vector3" then
		hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
	end
end

local function tweenTo(pos, speed)
	local hrp = getRoot(LP.Character)
	if not hrp or typeof(pos) ~= "Vector3" then return end
	local dist = (hrp.Position - pos).Magnitude
	local t = math.clamp(dist / (speed or 80), 0.1, 4)
	local tw = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))})
	tw:Play()
	tw.Completed:Wait()
end

local function nameMatch(inst, keywords)
	local n = string.lower(inst.Name)
	for _, k in ipairs(keywords) do
		if string.find(n, string.lower(k), 1, true) then return true end
	end
	return false
end

local function findByKeywords(keywords, className)
	local out = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if (not className or obj:IsA(className)) and nameMatch(obj, keywords) then
			table.insert(out, obj)
		end
	end
	return out
end

local function getPartPos(obj)
	if obj:IsA("BasePart") then return obj.Position end
	if obj:IsA("Model") then
		local p = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
		if p then return p.Position end
	end
	return nil
end

-- ==================== FEATURE MANAGERS ====================

function PotassiumHub:manageHealth()
	if connections.health then connections.health:Disconnect() connections.health = nil end
	if not FEATURES.unlimitedHealth then return end
	connections.health = RunService.Heartbeat:Connect(function()
		if not FEATURES.unlimitedHealth then return end
		pcall(function()
			local h = getHum(LP.Character)
			if h then h.Health = h.MaxHealth end
		end)
	end)
end

function PotassiumHub:manageKillAura()
	if connections.ka then connections.ka:Disconnect() connections.ka = nil end
	if not (FEATURES.killAura or FEATURES.chopAura or FEATURES.autoKillAll) then return end
	connections.ka = RunService.Heartbeat:Connect(function()
		pcall(function()
			local hrp = getRoot(LP.Character)
			if not hrp then return end
			local range = FEATURES.auraRange
			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj:IsA("Humanoid") and obj.Parent ~= LP.Character and obj.Health > 0 then
					local root = getRoot(obj.Parent)
					if root and (root.Position - hrp.Position).Magnitude <= range then
						if FEATURES.killAura or FEATURES.autoKillAll then
							pcall(function() obj:TakeDamage(25) end)
							pcall(function() obj.Health = 0 end)
						end
					end
				end
				if FEATURES.chopAura and obj:IsA("BasePart") and nameMatch(obj, {"tree", "log", "wood", "trunk", "chop"}) then
					if (obj.Position - hrp.Position).Magnitude <= FEATURES.chopRadius then
						pcall(function()
							local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
							if tool then tool:Activate() end
							firetouchinterest(hrp, obj, 0)
							firetouchinterest(hrp, obj, 1)
						end)
					end
				end
			end
		end)
	end)
end

function PotassiumHub:manageAutoChop()
	if connections.chop then connections.chop:Disconnect() connections.chop = nil end
	if not FEATURES.autoChop then return end
	connections.chop = RunService.Heartbeat:Connect(function()
		if not FEATURES.autoChop then return end
		pcall(function()
			local hrp = getRoot(LP.Character)
			if not hrp then return end
			for _, obj in ipairs(findByKeywords({"tree", "log", "wood", "trunk"}, "BasePart")) do
				if (obj.Position - hrp.Position).Magnitude <= FEATURES.chopRadius then
					for i = 1, FEATURES.chopHits do
						pcall(function()
							local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
							if tool then tool:Activate() end
							if firetouchinterest then
								firetouchinterest(hrp, obj, 0)
								firetouchinterest(hrp, obj, 1)
							end
						end)
					end
				end
			end
		end)
	end)
end

function PotassiumHub:manageAutoEat()
	if connections.eat then connections.eat:Disconnect() connections.eat = nil end
	if not FEATURES.autoEat then return end
	connections.eat = RunService.Heartbeat:Connect(function()
		if not FEATURES.autoEat then return end
		pcall(function()
			local h = getHum(LP.Character)
			if not h or h.Health > h.MaxHealth * 0.7 then return end
			for _, tool in ipairs(LP.Backpack:GetChildren()) do
				if tool:IsA("Tool") and nameMatch(tool, {"food", "stew", "meat", "berry", "bread", "apple", "carrot", "cook", "meal", "fish"}) then
					tool.Parent = LP.Character
					task.wait(0.1)
					pcall(function() tool:Activate() end)
					break
				end
			end
		end)
	end)
end

function PotassiumHub:bringObjects(keywords, limit)
	task.spawn(function()
		local hrp = getRoot(LP.Character)
		if not hrp then return end
		local count = 0
		local maxN = FEATURES.noBringLimit and 9999 or (limit or FEATURES.bringMax)
		for _, obj in ipairs(workspace:GetDescendants()) do
			if count >= maxN then break end
			local pos = getPartPos(obj)
			if pos and nameMatch(obj, keywords) then
				count += 1
				pcall(function()
					if FEATURES.bringMethod == "Teleport" then
						if obj:IsA("BasePart") then
							obj.CFrame = hrp.CFrame + Vector3.new(0, FEATURES.bringHeight, 0)
						elseif obj:IsA("Model") and obj.PrimaryPart then
							obj:PivotTo(hrp.CFrame + Vector3.new(0, FEATURES.bringHeight, 0))
						end
					else
						local part = obj:IsA("BasePart") and obj or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")))
						if part then
							TweenService:Create(part, TweenInfo.new(math.clamp((part.Position - hrp.Position).Magnitude / FEATURES.bringSpeed, 0.05, 2)), {
								CFrame = hrp.CFrame + Vector3.new(0, FEATURES.bringHeight, 0)
							}):Play()
						end
					end
				end)
				task.wait(FEATURES.bringCooldown)
			end
		end
	end)
end

function PotassiumHub:manageBringLoops()
	if connections.bring then connections.bring:Disconnect() connections.bring = nil end
	local any = FEATURES.bringAllItems or FEATURES.bringFuels or FEATURES.bringFood or FEATURES.bringGuns or FEATURES.bringTrees or FEATURES.bringMobs
	if not any then return end
	connections.bring = RunService.Heartbeat:Connect(function()
		if FEATURES.bringFuels then PotassiumHub:bringObjects({"fuel", "log", "coal", "wood", "biofuel", "oil", "canister"}, FEATURES.bringMax) end
		if FEATURES.bringFood then PotassiumHub:bringObjects({"food", "stew", "meat", "berry", "bread", "apple", "carrot", "fish", "meal"}, FEATURES.bringMax) end
		if FEATURES.bringGuns then PotassiumHub:bringObjects({"gun", "rifle", "pistol", "armor", "shield", "sword", "axe", "bow"}, FEATURES.bringMax) end
		if FEATURES.bringTrees then PotassiumHub:bringObjects({"tree", "sapling", "log"}, FEATURES.bringMax) end
		if FEATURES.bringAllItems then PotassiumHub:bringObjects({"item", "loot", "drop", "pickup", "scrap", "junk", "gem", "coin", "diamond"}, FEATURES.bringMax) end
		task.wait(1)
	end)
end

function PotassiumHub:manageKids()
	if connections.kids then connections.kids:Disconnect() connections.kids = nil end
	if not (FEATURES.autoFindKids or FEATURES.autoCollectKids or FEATURES.autoPickupKid) then return end
	connections.kids = RunService.Heartbeat:Connect(function()
		pcall(function()
			local kids = findByKeywords({"kid", "child", "lost", "boy", "girl", "children"}, nil)
			for _, kid in ipairs(kids) do
				local pos = getPartPos(kid)
				if pos then
					if FEATURES.autoFindKids or FEATURES.autoCollectKids or FEATURES.autoPickupKid then
						if FEATURES.bringMethod == "Teleport" then tpTo(pos) else tweenTo(pos, 100) end
						task.wait(0.3)
						for _, d in ipairs(kid:GetDescendants()) do
							if d:IsA("ProximityPrompt") then
								pcall(function() fireproximityprompt(d) end)
							end
						end
					end
				end
			end
		end)
		task.wait(1)
	end)
end

function PotassiumHub:manageCampfire()
	if connections.camp then connections.camp:Disconnect() connections.camp = nil end
	if not (FEATURES.autoCampfire or FEATURES.autoFillCampfire or FEATURES.autoBiofuel) then return end
	connections.camp = RunService.Heartbeat:Connect(function()
		pcall(function()
			local fires = findByKeywords({"campfire", "fire", "bonfire", "camp"}, nil)
			for _, fire in ipairs(fires) do
				local pos = getPartPos(fire)
				if pos then
					PotassiumHub:bringObjects({"fuel", "log", "coal", "wood", "biofuel", "oil"}, 10)
					if FEATURES.autoFillCampfire or FEATURES.autoCampfire then
						tpTo(pos)
						for _, d in ipairs(fire:GetDescendants()) do
							if d:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(d) end) end
						end
					end
				end
			end
		end)
		task.wait(2)
	end)
end

function PotassiumHub:manageStronghold()
	if connections.sh then connections.sh:Disconnect() connections.sh = nil end
	if not FEATURES.autoStronghold then return end
	connections.sh = RunService.Heartbeat:Connect(function()
		pcall(function()
			local targets = findByKeywords({"stronghold", "raid", "cultist", "diamond", "gem"}, nil)
			for _, t in ipairs(targets) do
				local pos = getPartPos(t)
				if pos then
					tpTo(pos)
					task.wait(0.2)
					for _, d in ipairs(t:GetDescendants()) do
						if d:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(d) end) end
						if d:IsA("Humanoid") and d.Health > 0 then pcall(function() d.Health = 0 end) end
					end
				end
			end
		end)
		task.wait(1.5)
	end)
end

function PotassiumHub:manageAutoCollect()
	if connections.collect then connections.collect:Disconnect() connections.collect = nil end
	local any = FEATURES.autoCoins or FEATURES.autoDiamonds or FEATURES.autoFlowers or FEATURES.autoFish or FEATURES.autoOpenChest
	if not any then return end
	connections.collect = RunService.Heartbeat:Connect(function()
		pcall(function()
			if FEATURES.autoCoins then
				for _, o in ipairs(findByKeywords({"coin", "cash", "money"}, "BasePart")) do
					local p = getPartPos(o)
					if p then tpTo(p) task.wait(0.1) end
				end
			end
			if FEATURES.autoDiamonds then
				for _, o in ipairs(findByKeywords({"diamond", "gem"}, nil)) do
					local p = getPartPos(o)
					if p then tpTo(p) task.wait(0.1) end
				end
			end
			if FEATURES.autoFlowers then
				for _, o in ipairs(findByKeywords({"flower", "bloom", "petal"}, nil)) do
					local p = getPartPos(o)
					if p then tpTo(p) task.wait(0.1) end
				end
			end
			if FEATURES.autoOpenChest then
				for _, o in ipairs(findByKeywords({"chest", "crate", "lootbox"}, nil)) do
					local p = getPartPos(o)
					if p then
						tpTo(p)
						for _, d in ipairs(o:GetDescendants()) do
							if d:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(d) end) end
						end
						task.wait(0.2)
					end
				end
			end
			if FEATURES.autoFish then
				for _, o in ipairs(findByKeywords({"fish", "rod", "pond", "lake"}, nil)) do
					local p = getPartPos(o)
					if p then tpTo(p) task.wait(0.3) end
				end
			end
		end)
		task.wait(1)
	end)
end

function PotassiumHub:managePlant()
	if connections.plant then connections.plant:Disconnect() connections.plant = nil end
	if not (FEATURES.autoPlant or FEATURES.autoSapling) then return end
	connections.plant = task.spawn(function()
		while FEATURES.autoPlant or FEATURES.autoSapling do
			pcall(function()
				local hrp = getRoot(LP.Character)
				if not hrp then return end
				local center = hrp.Position
				if FEATURES.plantMethod == "Around Camp" then
					local fires = findByKeywords({"campfire", "fire", "camp"}, nil)
					if #fires > 0 then
						local p = getPartPos(fires[1])
						if p then center = p end
					end
				end
				local pts = {}
				local r, step = FEATURES.plantRadius, FEATURES.plantDistance
				local shape = FEATURES.plantShape
				if shape == "Circle" or shape == "Spiral" then
					for a = 0, 360, math.max(8, step * 4) do
						local rad = math.rad(a)
						local rr = shape == "Spiral" and (r * (a / 360)) or r
						table.insert(pts, center + Vector3.new(math.cos(rad) * rr, 0, math.sin(rad) * rr))
					end
				elseif shape == "Square" or shape == "Grid" then
					for x = -r, r, step do
						for z = -r, r, step do
							table.insert(pts, center + Vector3.new(x, 0, z))
						end
					end
				elseif shape == "Cross" then
					for i = -r, r, step do
						table.insert(pts, center + Vector3.new(i, 0, 0))
						table.insert(pts, center + Vector3.new(0, 0, i))
					end
				elseif shape == "Triangle" then
					for i = 0, 2 do
						local a = math.rad(i * 120)
						table.insert(pts, center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
					end
				elseif shape == "Hexagon" then
					for i = 0, 5 do
						local a = math.rad(i * 60)
						table.insert(pts, center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
					end
				end
				for _, pos in ipairs(pts) do
					if not (FEATURES.autoPlant or FEATURES.autoSapling) then break end
					tpTo(pos)
					pcall(function()
						local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
						if not tool then
							for _, t in ipairs(LP.Backpack:GetChildren()) do
								if t:IsA("Tool") and nameMatch(t, {"sapling", "seed", "plant"}) then
									t.Parent = LP.Character
									tool = t
									break
								end
							end
						end
						if tool then tool:Activate() end
					end)
					task.wait(FEATURES.plantSpeed)
				end
			end)
			task.wait(2)
		end
	end)
end

function PotassiumHub:manageESP()
	if espFolder then pcall(function() espFolder:Destroy() end) espFolder = nil end
	if connections.esp then connections.esp:Disconnect() connections.esp = nil end
	local any = FEATURES.espItems or FEATURES.espMobs or FEATURES.espKids or FEATURES.espChests or FEATURES.espChars
	if not any then return end
	espFolder = Instance.new("Folder")
	espFolder.Name = "PH_99Nights_ESP"
	espFolder.Parent = CoreGui

	local function addESP(obj, color, label)
		local pos = getPartPos(obj)
		if not pos then return end
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 120, 0, 30)
		bb.AlwaysOnTop = true
		bb.StudsOffset = Vector3.new(0, 2.5, 0)
		bb.Adornee = obj:IsA("BasePart") and obj or (obj:FindFirstChildWhichIsA("BasePart"))
		if not bb.Adornee then return end
		bb.Parent = espFolder
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, 0, 1, 0)
		t.BackgroundTransparency = 1
		t.Text = label or obj.Name
		t.TextColor3 = color
		t.TextStrokeTransparency = 0.4
		t.TextSize = 12
		t.Font = currentFont
		t.Parent = bb
		local hl = Instance.new("Highlight")
		hl.Adornee = obj:IsA("Model") and obj or obj.Parent
		hl.FillColor = color
		hl.OutlineColor = Color3.new(1, 1, 1)
		hl.FillTransparency = 0.6
		hl.OutlineTransparency = 0.3
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = espFolder
	end

	local function scan()
		if espFolder then for _, c in ipairs(espFolder:GetChildren()) do c:Destroy() end end
		if FEATURES.espKids then
			for _, o in ipairs(findByKeywords({"kid", "child", "lost"}, nil)) do addESP(o, COLORS.ESP_KID, "Kid") end
		end
		if FEATURES.espChests then
			for _, o in ipairs(findByKeywords({"chest", "crate"}, nil)) do addESP(o, COLORS.ESP_CHEST, "Chest") end
		end
		if FEATURES.espMobs then
			for _, o in ipairs(findByKeywords({"wolf", "deer", "owl", "cultist", "ram", "cat", "turkey", "mossy", "monster", "enemy"}, nil)) do
				addESP(o, COLORS.ESP_MOB, o.Name)
			end
		end
		if FEATURES.espItems then
			for _, o in ipairs(findByKeywords({"fuel", "log", "food", "gem", "coin", "diamond", "scrap", "sapling", "medicine"}, nil)) do
				addESP(o, COLORS.ESP_ITEM, o.Name)
			end
		end
		if FEATURES.espChars then
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= LP and plr.Character then
					addESP(plr.Character, Color3.fromRGB(100, 180, 255), plr.DisplayName)
				end
			end
		end
	end
	scan()
	connections.esp = RunService.Heartbeat:Connect(function()
		-- refresh every ~3s via counter
	end)
	task.spawn(function()
		while espFolder and espFolder.Parent do
			task.wait(3)
			pcall(scan)
		end
	end)
end

function PotassiumHub:manageAnti()
	if connections.anti then connections.anti:Disconnect() connections.anti = nil end
	if not (FEATURES.autoEscape or FEATURES.escapeDeer or FEATURES.escapeOwl or FEATURES.autoAvoid) then return end
	connections.anti = RunService.Heartbeat:Connect(function()
		pcall(function()
			local hrp = getRoot(LP.Character)
			if not hrp then return end
			local threats = {}
			if FEATURES.escapeDeer or FEATURES.autoEscape then
				for _, o in ipairs(findByKeywords({"deer"}, nil)) do
					local p = getPartPos(o)
					if p and (p - hrp.Position).Magnitude < FEATURES.deerDist then table.insert(threats, {pos = p, dist = FEATURES.deerDist, speed = FEATURES.deerSpeed, method = FEATURES.deerMethod}) end
				end
			end
			if FEATURES.escapeOwl then
				for _, o in ipairs(findByKeywords({"owl"}, nil)) do
					local p = getPartPos(o)
					if p and (p - hrp.Position).Magnitude < FEATURES.owlDist then table.insert(threats, {pos = p, dist = FEATURES.owlDist, speed = FEATURES.owlSpeed, method = FEATURES.owlMethod}) end
				end
			end
			if FEATURES.autoAvoid then
				for _, o in ipairs(findByKeywords({"wolf", "cultist", "ram", "cat", "mossy"}, nil)) do
					local p = getPartPos(o)
					if p and (p - hrp.Position).Magnitude < FEATURES.avoidRadius then table.insert(threats, {pos = p, dist = FEATURES.avoidRadius, speed = FEATURES.avoidSpeed, method = FEATURES.avoidMethod}) end
				end
			end
			for _, th in ipairs(threats) do
				local away = (hrp.Position - th.pos)
				if away.Magnitude > 0 then
					local dest = hrp.Position + away.Unit * th.dist
					if th.method == "Teleport" then tpTo(dest) else
						hrp.AssemblyLinearVelocity = away.Unit * th.speed
					end
				end
			end
		end)
	end)
end

function PotassiumHub:managePlayerMods()
	if connections.speed then connections.speed:Disconnect() connections.speed = nil end
	connections.speed = RunService.Heartbeat:Connect(function()
		pcall(function()
			local h = getHum(LP.Character)
			local hrp = getRoot(LP.Character)
			if h then
				if FEATURES.walkSpeed ~= 16 then h.WalkSpeed = FEATURES.walkSpeed end
				if FEATURES.jumpPower ~= 50 then h.JumpPower = FEATURES.jumpPower h.UseJumpPower = true end
			end
			if FEATURES.gravity ~= 196.2 then workspace.Gravity = FEATURES.gravity end
			if FEATURES.fov ~= 70 then Camera.FieldOfView = FEATURES.fov end
			if FEATURES.freezeChar and hrp then hrp.Anchored = true elseif hrp and hrp.Anchored and not FEATURES.fly then hrp.Anchored = false end
			if FEATURES.antiVoid and hrp and hrp.Position.Y < -50 then
				hrp.CFrame = CFrame.new(hrp.Position.X, 20, hrp.Position.Z)
			end
		end)
	end)

	if connections.fly then connections.fly:Disconnect() connections.fly = nil end
	if FEATURES.fly then
		connections.fly = RunService.Heartbeat:Connect(function()
			if not FEATURES.fly then return end
			pcall(function()
				local hrp = getRoot(LP.Character)
				if not hrp then return end
				flyDir = Vector3.zero
				local look, right = Camera.CFrame.LookVector, Camera.CFrame.RightVector
				if UIS:IsKeyDown(Enum.KeyCode.W) then flyDir += look end
				if UIS:IsKeyDown(Enum.KeyCode.S) then flyDir -= look end
				if UIS:IsKeyDown(Enum.KeyCode.A) then flyDir -= right end
				if UIS:IsKeyDown(Enum.KeyCode.D) then flyDir += right end
				if UIS:IsKeyDown(Enum.KeyCode.Space) then flyDir += Vector3.yAxis end
				if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then flyDir -= Vector3.yAxis end
				hrp.AssemblyLinearVelocity = flyDir.Magnitude > 0 and flyDir.Unit * FEATURES.flySpeed or Vector3.zero
			end)
		end)
	end

	if connections.noclip then connections.noclip:Disconnect() connections.noclip = nil end
	if FEATURES.noclip then
		connections.noclip = RunService.Stepped:Connect(function()
			if not FEATURES.noclip then return end
			pcall(function()
				for _, p in ipairs(LP.Character and LP.Character:GetDescendants() or {}) do
					if p:IsA("BasePart") then p.CanCollide = false end
				end
			end)
		end)
	end

	if connections.ijump then connections.ijump:Disconnect() connections.ijump = nil end
	if FEATURES.infJump then
		connections.ijump = UIS.JumpRequest:Connect(function()
			if FEATURES.infJump then
				local h = getHum(LP.Character)
				if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
			end
		end)
	end
end

function PotassiumHub:manageQuickInteract()
	if connections.qi then connections.qi:Disconnect() connections.qi = nil end
	if not FEATURES.quickInteract then return end
	connections.qi = ProximityPromptService.PromptShown:Connect(function(prompt)
		if FEATURES.quickInteract then
			prompt.HoldDuration = 0
		end
	end)
	for _, p in ipairs(workspace:GetDescendants()) do
		if p:IsA("ProximityPrompt") then p.HoldDuration = 0 end
	end
end

function PotassiumHub:manageAntiAfk()
	if connections.afk then connections.afk:Disconnect() connections.afk = nil end
	if not FEATURES.antiAfk then return end
	connections.afk = LP.Idled:Connect(function()
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end)
end

function PotassiumHub:managePerf()
	pcall(function()
		if FEATURES.fpsBoost then
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
			UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
		end
		if FEATURES.removeFog then Lighting.FogEnd = 1e6 Lighting.FogStart = 1e6 end
		if FEATURES.removeSky then
			for _, s in ipairs(Lighting:GetChildren()) do
				if s:IsA("Sky") then s:Destroy() end
			end
		end
		local dels = {}
		if FEATURES.delBigTrees then table.insert(dels, {"tree", "large"}) end
		if FEATURES.delStones then table.insert(dels, {"stone", "rock"}) end
		if FEATURES.delBushes then table.insert(dels, {"bush"}) end
		if FEATURES.delGrass then table.insert(dels, {"grass"}) end
		if FEATURES.delCampLogs then table.insert(dels, {"log"}) end
		if #dels > 0 then
			for _, obj in ipairs(workspace:GetDescendants()) do
				for _, keys in ipairs(dels) do
					if nameMatch(obj, keys) then pcall(function() obj:Destroy() end) break end
				end
			end
		end
	end)
end

function PotassiumHub:manageFullbright()
	Lighting.Brightness = 2
	Lighting.ClockTime = 14
	Lighting.FogEnd = 1e6
	Lighting.GlobalShadows = false
	Lighting.Ambient = Color3.fromRGB(180, 180, 180)
end

function PotassiumHub:teleportToKeyword(keywords)
	local objs = findByKeywords(keywords, nil)
	if #objs > 0 then
		local p = getPartPos(objs[1])
		if p then tpTo(p) end
	end
end

function PotassiumHub:manageBase()
	if connections.base then
		if typeof(connections.base) == "RBXScriptConnection" then
			connections.base:Disconnect()
		end
		connections.base = nil
	end
	if not (FEATURES.autoMakeBase or FEATURES.autoPlaceStructures or FEATURES.autoPickupStructures
		or FEATURES.autoDropBlueprints or FEATURES.autoTakeBlueprints or FEATURES.autoBuyFurniture) then
		return
	end
	connections.base = task.spawn(function()
		while FEATURES.autoMakeBase or FEATURES.autoPlaceStructures or FEATURES.autoPickupStructures
			or FEATURES.autoDropBlueprints or FEATURES.autoTakeBlueprints or FEATURES.autoBuyFurniture do
			pcall(function()
				local hrp = getRoot(LP.Character)
				if not hrp then return end

				-- Take / grab blueprints from world
				if FEATURES.autoTakeBlueprints or FEATURES.autoMakeBase then
					for _, obj in ipairs(findByKeywords({"blueprint", "plan", "schematic"}, nil)) do
						local pos = getPartPos(obj)
						if pos and (pos - hrp.Position).Magnitude < 200 then
							tpTo(pos)
							task.wait(0.15)
							for _, d in ipairs(obj:GetDescendants()) do
								if d:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(d) end) end
							end
							pcall(function()
								if firetouchinterest and obj:IsA("BasePart") then
									firetouchinterest(hrp, obj, 0)
									firetouchinterest(hrp, obj, 1)
								end
							end)
						end
					end
				end

				-- Drop blueprints from inventory into world near player
				if FEATURES.autoDropBlueprints then
					for _, tool in ipairs(LP.Backpack:GetChildren()) do
						if tool:IsA("Tool") and nameMatch(tool, {"blueprint", "plan", "schematic"}) then
							tool.Parent = LP.Character
							task.wait(0.1)
							pcall(function() tool:Activate() end)
							task.wait(0.15)
						end
					end
					for _, tool in ipairs(LP.Character and LP.Character:GetChildren() or {}) do
						if tool:IsA("Tool") and nameMatch(tool, {"blueprint", "plan", "schematic"}) then
							pcall(function() tool:Activate() end)
						end
					end
				end

				-- Place structures in a pattern around camp or player
				if FEATURES.autoPlaceStructures or FEATURES.autoMakeBase then
					local center = hrp.Position
					local fires = findByKeywords({"campfire", "fire", "camp"}, nil)
					if #fires > 0 then
						local p = getPartPos(fires[1])
						if p then center = p end
					end
					local r, step = FEATURES.baseRadius, FEATURES.baseSpacing
					local pts = {}
					if FEATURES.baseShape == "Circle" then
						for a = 0, 360, math.max(15, step * 3) do
							local rad = math.rad(a)
							table.insert(pts, center + Vector3.new(math.cos(rad) * r, 0, math.sin(rad) * r))
						end
					else -- Grid
						for x = -r, r, step do
							for z = -r, r, step do
								if not (math.abs(x) < 4 and math.abs(z) < 4) then
									table.insert(pts, center + Vector3.new(x, 0, z))
								end
							end
						end
					end
					-- Equip structure / furniture tools and place
					local placeTools = {}
					for _, t in ipairs(LP.Backpack:GetChildren()) do
						if t:IsA("Tool") and nameMatch(t, {"wall", "floor", "door", "fence", "chest", "bed", "table", "chair", "structure", "build", "furniture", "blueprint", "torch", "lamp"}) then
							table.insert(placeTools, t)
						end
					end
					for i, pos in ipairs(pts) do
						if not (FEATURES.autoPlaceStructures or FEATURES.autoMakeBase) then break end
						if #placeTools == 0 then break end
						local tool = placeTools[((i - 1) % #placeTools) + 1]
						pcall(function()
							tool.Parent = LP.Character
							tpTo(pos)
							task.wait(0.12)
							tool:Activate()
							for _, d in ipairs(workspace:GetDescendants()) do
								if d:IsA("ProximityPrompt") and nameMatch(d.Parent or d, {"place", "build", "structure", "confirm"}) then
									if (getPartPos(d.Parent) or pos - pos).Magnitude then
										pcall(function() fireproximityprompt(d) end)
									end
								end
							end
						end)
						task.wait(0.2)
					end
				end

				-- Pickup placed structures
				if FEATURES.autoPickupStructures then
					for _, obj in ipairs(findByKeywords({"wall", "floor", "door", "fence", "structure", "furniture", "bed", "table", "chair"}, nil)) do
						local pos = getPartPos(obj)
						if pos and (pos - hrp.Position).Magnitude < 80 then
							tpTo(pos)
							task.wait(0.1)
							for _, d in ipairs(obj:GetDescendants()) do
								if d:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(d) end) end
							end
						end
					end
				end

				-- Buy furniture from traders
				if FEATURES.autoBuyFurniture then
					for _, npc in ipairs(findByKeywords({"furniture", "trader", "shop", "vendor", "beekeeper", "fairy"}, nil)) do
						local pos = getPartPos(npc)
						if pos then
							tpTo(pos)
							task.wait(0.2)
							for _, d in ipairs(npc:GetDescendants()) do
								if d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
									pcall(function()
										if d:IsA("ProximityPrompt") then fireproximityprompt(d) end
										if d:IsA("ClickDetector") and fireclickdetector then fireclickdetector(d) end
									end)
								end
							end
						end
					end
				end
			end)
			task.wait(2)
		end
	end)
end

function PotassiumHub:runAllManagers()
	self:manageHealth()
	self:manageKillAura()
	self:manageAutoChop()
	self:manageAutoEat()
	self:manageBringLoops()
	self:manageKids()
	self:manageCampfire()
	self:manageStronghold()
	self:manageAutoCollect()
	self:managePlant()
	self:manageBase()
	self:manageESP()
	self:manageAnti()
	self:managePlayerMods()
	self:manageQuickInteract()
	self:manageAntiAfk()
end

-- ==================== UI ====================

function PotassiumHub:createIcon()
	if self.iconGui then pcall(function() self.iconGui:Destroy() end) end
	local gui = Instance.new("ScreenGui")
	gui.Name = "PotassiumIcon"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = CoreGui
	local box = Instance.new("Frame")
	box.Size = UDim2.new(0, 72, 0, 72)
	box.Position = UDim2.new(0.5, -36, 0, 16)
	box.BackgroundColor3 = COLORS.BG_DARK
	box.BorderSizePixel = 0
	box.Active = true
	box.Parent = gui
	applyGlass(box, 0.35)
	local logo = Instance.new("ImageLabel")
	logo.Size = UDim2.new(0.85, 0, 0.85, 0)
	logo.Position = UDim2.new(0.075, 0, 0.075, 0)
	logo.BackgroundTransparency = 1
	logo.Parent = box
	applyLogo(logo)
	local dragging, d0, p0 = false, nil, nil
	box.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true d0 = i.Position p0 = box.Position
			i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) and d0 and p0 then
			local d = i.Position - d0
			box.Position = UDim2.new(p0.X.Scale, p0.X.Offset + d.X, p0.Y.Scale, p0.Y.Offset + d.Y)
		end
	end)
	local c0, t0
	box.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then c0 = i.Position t0 = tick() end end)
	box.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 and c0 and (i.Position - c0).Magnitude < 8 and (tick() - t0) < 0.35 then
			gui:Destroy() self.iconGui = nil self.iconVisible = false
			self:createUI()
		end
	end)
	self.iconGui = gui
	self.iconVisible = true
end

function PotassiumHub:showLoading()
	local gui = Instance.new("ScreenGui")
	gui.Name = "PotassiumLoading"
	gui.ResetOnSpawn = false
	gui.Parent = CoreGui
	local dim = Instance.new("Frame")
	dim.Size = UDim2.new(1, 0, 1, 0)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 0.45
	dim.BorderSizePixel = 0
	dim.Parent = gui
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 240, 0, 150)
	card.Position = UDim2.new(0.5, -120, 0.5, -75)
	card.BackgroundColor3 = COLORS.BG_DARK
	card.BorderSizePixel = 0
	card.Parent = gui
	applyGlass(card, 0.28)
	local logo = Instance.new("ImageLabel")
	logo.Size = UDim2.new(0, 52, 0, 52)
	logo.Position = UDim2.new(0.5, -26, 0, 16)
	logo.BackgroundTransparency = 1
	logo.Parent = card
	applyLogo(logo)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -12, 0, 22)
	title.Position = UDim2.new(0, 6, 0, 78)
	title.BackgroundTransparency = 1
	title.Text = "POTASSIUM  ·  99 NIGHTS"
	title.TextColor3 = COLORS.PRIMARY
	title.TextSize = 13
	title.Font = Enum.Font.GothamBold
	title.Parent = card
	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -12, 0, 18)
	sub.Position = UDim2.new(0, 6, 0, 104)
	sub.BackgroundTransparency = 1
	sub.Text = "Loading modules..."
	sub.TextColor3 = COLORS.TEXT_SECONDARY
	sub.TextSize = 11
	sub.Font = Enum.Font.Gotham
	sub.Parent = card
	task.delay(1.3, function() pcall(function() gui:Destroy() end) end)
end

function PotassiumHub:createUI()
	if self.mainGui then pcall(function() self.mainGui:Destroy() end) end
	local gui = Instance.new("ScreenGui")
	gui.Name = "PotassiumUIMain"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = CoreGui
	self.mainGui = gui

	local main = Instance.new("Frame")
	main.Name = "MainFrame"
	main.Size = UDim2.new(0, 500, 0, 660)
	main.Position = UDim2.new(0.5, -250, 0.5, -330)
	main.BackgroundColor3 = COLORS.BG_DARK
	main.BackgroundTransparency = 0.15
	main.BorderSizePixel = 0
	main.Parent = gui
	applyGlass(main, 0.28)
	local mc = main:FindFirstChildOfClass("UICorner")
	if mc then mc.CornerRadius = UDim.new(0, 18) end

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 64)
	header.BackgroundTransparency = 0.35
	header.BorderSizePixel = 0
	header.Parent = main
	applyGlass(header, 0.35)
	local hc = header:FindFirstChildOfClass("UICorner")
	if hc then hc.CornerRadius = UDim.new(0, 18) end

	local hlogo = Instance.new("ImageLabel")
	hlogo.Size = UDim2.new(0, 36, 0, 36)
	hlogo.Position = UDim2.new(0, 16, 0.5, -18)
	hlogo.BackgroundTransparency = 1
	hlogo.Parent = header
	applyLogo(hlogo)

	local htitle = Instance.new("TextLabel")
	htitle.Size = UDim2.new(0, 280, 0, 40)
	htitle.Position = UDim2.new(0, 60, 0.5, -20)
	htitle.BackgroundTransparency = 1
	htitle.Text = "POTASSIUM  ·  99 NIGHTS"
	htitle.TextColor3 = COLORS.PRIMARY
	htitle.TextSize = 16
	htitle.Font = Enum.Font.GothamBold
	htitle.TextXAlignment = Enum.TextXAlignment.Left
	htitle.Parent = header

	local dragging, d0, p0 = false, nil, nil
	local dragBtn = Instance.new("TextButton")
	dragBtn.Size = UDim2.new(0.62, 0, 1, 0)
	dragBtn.BackgroundTransparency = 1
	dragBtn.Text = ""
	dragBtn.Parent = header
	dragBtn.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true d0 = i.Position p0 = main.Position
			i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and d0 and p0 then
			local d = i.Position - d0
			main.Position = UDim2.new(p0.X.Scale, p0.X.Offset + d.X, p0.Y.Scale, p0.Y.Offset + d.Y)
		end
	end)

	local minBtn = Instance.new("TextButton")
	minBtn.Size = UDim2.new(0, 36, 0, 36)
	minBtn.Position = UDim2.new(1, -84, 0, 14)
	minBtn.BackgroundTransparency = 0.4
	minBtn.Text = "–"
	minBtn.TextColor3 = COLORS.PRIMARY
	minBtn.TextSize = 20
	minBtn.Font = Enum.Font.GothamBold
	minBtn.Parent = header
	applyGlass(minBtn, 0.4)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, -42, 0, 14)
	closeBtn.BackgroundTransparency = 0.4
	closeBtn.Text = "×"
	closeBtn.TextColor3 = COLORS.PRIMARY
	closeBtn.TextSize = 20
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = header
	applyGlass(closeBtn, 0.4)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, -64)
	scroll.Position = UDim2.new(0, 0, 0, 64)
	scroll.BackgroundTransparency = 0.2
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = COLORS.PRIMARY
	scroll.CanvasSize = UDim2.new(0, 0, 0, 2000)
	scroll.Parent = main

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 10)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = scroll
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.PaddingTop = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 16)
	pad.Parent = scroll
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 30)
	end)

	local minimized = false
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			TweenService:Create(main, TweenInfo.new(0.25), {Size = UDim2.new(0, 500, 0, 64)}):Play()
			scroll.Visible = false
		else
			TweenService:Create(main, TweenInfo.new(0.25), {Size = UDim2.new(0, 500, 0, 660)}):Play()
			scroll.Visible = true
		end
	end)
	closeBtn.MouseButton1Click:Connect(function()
		gui:Destroy()
		self.mainGui = nil
		self.uiVisible = false
		self:createIcon()
	end)

	local function createToggle(text, key, parent, cb)
		local c = Instance.new("Frame")
		c.Size = UDim2.new(1, 0, 0, 40)
		c.BackgroundTransparency = 0.3
		c.Parent = parent
		applyGlass(c, 0.4)
		local lab = Instance.new("TextLabel")
		lab.Size = UDim2.new(0.7, 0, 1, 0)
		lab.BackgroundTransparency = 1
		lab.Text = text
		lab.TextColor3 = COLORS.TEXT_PRIMARY
		lab.TextSize = 12
		lab.Font = currentFont
		lab.TextXAlignment = Enum.TextXAlignment.Left
		lab.Parent = c
		local lp = Instance.new("UIPadding")
		lp.PaddingLeft = UDim.new(0, 12)
		lp.Parent = lab
		local tog = Instance.new("Frame")
		tog.Size = UDim2.new(0, 40, 0, 20)
		tog.Position = UDim2.new(1, -52, 0.5, -10)
		tog.BackgroundColor3 = COLORS.BG_LIGHT
		tog.Parent = c
		local tc = Instance.new("UICorner")
		tc.CornerRadius = UDim.new(1, 0)
		tc.Parent = tog
		local ball = Instance.new("Frame")
		ball.Size = UDim2.new(0, 16, 0, 16)
		ball.Position = UDim2.new(0, 2, 0.5, -8)
		ball.BackgroundColor3 = COLORS.TEXT_SECONDARY
		ball.Parent = tog
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(1, 0)
		bc.Parent = ball
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.Parent = c
		local function refresh()
			if FEATURES[key] then
				ball.Position = UDim2.new(0, 22, 0.5, -8)
				ball.BackgroundColor3 = COLORS.ACCENT
				tog.BackgroundColor3 = Color3.fromRGB(55, 55, 68)
			else
				ball.Position = UDim2.new(0, 2, 0.5, -8)
				ball.BackgroundColor3 = COLORS.TEXT_SECONDARY
				tog.BackgroundColor3 = COLORS.BG_LIGHT
			end
		end
		refresh()
		btn.MouseButton1Click:Connect(function()
			FEATURES[key] = not FEATURES[key]
			refresh()
			if cb then cb() else PotassiumHub:runAllManagers() end
		end)
	end

	local function createNum(text, key, minV, maxV, parent, cb)
		local c = Instance.new("Frame")
		c.Size = UDim2.new(1, 0, 0, 52)
		c.BackgroundTransparency = 0.3
		c.Parent = parent
		applyGlass(c, 0.4)
		local lab = Instance.new("TextLabel")
		lab.Size = UDim2.new(1, -20, 0, 16)
		lab.Position = UDim2.new(0, 12, 0, 4)
		lab.BackgroundTransparency = 1
		lab.Text = text .. " (" .. tostring(FEATURES[key]) .. ")"
		lab.TextColor3 = COLORS.TEXT_PRIMARY
		lab.TextSize = 11
		lab.Font = Enum.Font.GothamBold
		lab.TextXAlignment = Enum.TextXAlignment.Left
		lab.Parent = c
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, -24, 0, 24)
		box.Position = UDim2.new(0, 12, 0, 22)
		box.BackgroundColor3 = COLORS.BG_LIGHT
		box.BackgroundTransparency = 0.3
		box.Text = tostring(FEATURES[key])
		box.TextColor3 = COLORS.TEXT_PRIMARY
		box.TextSize = 12
		box.Font = currentFont
		box.ClearTextOnFocus = false
		box.Parent = c
		local ic = Instance.new("UICorner")
		ic.CornerRadius = UDim.new(0, 6)
		ic.Parent = box
		box.FocusLost:Connect(function()
			local v = tonumber(box.Text)
			if v then
				v = math.clamp(v, minV, maxV)
				FEATURES[key] = v
				box.Text = tostring(v)
				lab.Text = text .. " (" .. tostring(v) .. ")"
				if cb then cb() else PotassiumHub:runAllManagers() end
			else
				box.Text = tostring(FEATURES[key])
			end
		end)
	end

	local function createDrop(text, key, options, parent, cb)
		local c = Instance.new("Frame")
		c.Size = UDim2.new(1, 0, 0, 40)
		c.BackgroundTransparency = 0.3
		c.Parent = parent
		applyGlass(c, 0.4)
		local lab = Instance.new("TextLabel")
		lab.Size = UDim2.new(1, 0, 1, 0)
		lab.BackgroundTransparency = 1
		lab.Text = text .. ": " .. tostring(FEATURES[key])
		lab.TextColor3 = COLORS.TEXT_PRIMARY
		lab.TextSize = 12
		lab.Font = currentFont
		lab.TextXAlignment = Enum.TextXAlignment.Left
		lab.Parent = c
		local lp = Instance.new("UIPadding")
		lp.PaddingLeft = UDim.new(0, 12)
		lp.Parent = lab
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.Parent = c
		local idx = 1
		for i, o in ipairs(options) do if o == FEATURES[key] then idx = i break end end
		btn.MouseButton1Click:Connect(function()
			idx = idx % #options + 1
			FEATURES[key] = options[idx]
			lab.Text = text .. ": " .. tostring(FEATURES[key])
			if cb then cb() end
		end)
	end

	local function createBtn(text, parent, cb)
		local c = Instance.new("Frame")
		c.Size = UDim2.new(1, 0, 0, 38)
		c.BackgroundTransparency = 0.3
		c.Parent = parent
		applyGlass(c, 0.4)
		local lab = Instance.new("TextLabel")
		lab.Size = UDim2.new(1, 0, 1, 0)
		lab.BackgroundTransparency = 1
		lab.Text = text
		lab.TextColor3 = COLORS.PRIMARY
		lab.TextSize = 12
		lab.Font = Enum.Font.GothamBold
		lab.Parent = c
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.Parent = c
		btn.MouseButton1Click:Connect(function() if cb then cb() end end)
	end

	local function createSub(text, parent)
		local s = Instance.new("Frame")
		s.Size = UDim2.new(1, 0, 0, 28)
		s.BackgroundTransparency = 0.55
		s.Parent = parent
		applyGlass(s, 0.55)
		local lab = Instance.new("TextLabel")
		lab.Size = UDim2.new(1, -16, 1, 0)
		lab.Position = UDim2.new(0, 10, 0, 0)
		lab.BackgroundTransparency = 1
		lab.Text = text
		lab.TextColor3 = COLORS.SECONDARY
		lab.TextSize = 11
		lab.Font = Enum.Font.GothamBold
		lab.TextXAlignment = Enum.TextXAlignment.Left
		lab.Parent = s
	end

	local function createSection(title, key)
		local sec = Instance.new("Frame")
		sec.Size = UDim2.new(1, 0, 0, 40)
		sec.BackgroundTransparency = 1
		sec.ClipsDescendants = true
		sec.Parent = scroll
		local head = Instance.new("Frame")
		head.Size = UDim2.new(1, 0, 0, 40)
		head.BackgroundTransparency = 0.32
		head.Parent = sec
		applyGlass(head, 0.32)
		local hl = Instance.new("TextLabel")
		hl.Size = UDim2.new(0.8, 0, 1, 0)
		hl.Position = UDim2.new(0, 14, 0, 0)
		hl.BackgroundTransparency = 1
		hl.Text = title
		hl.TextColor3 = COLORS.PRIMARY
		hl.TextSize = 12
		hl.Font = Enum.Font.GothamBold
		hl.TextXAlignment = Enum.TextXAlignment.Left
		hl.Parent = head
		local chev = Instance.new("TextLabel")
		chev.Size = UDim2.new(0, 24, 0, 24)
		chev.Position = UDim2.new(1, -32, 0.5, -12)
		chev.BackgroundTransparency = 1
		chev.Text = PotassiumHub.sectionStates[key] and "▼" or "▶"
		chev.TextColor3 = COLORS.PRIMARY
		chev.TextSize = 12
		chev.Font = Enum.Font.GothamBold
		chev.Parent = head
		local content = Instance.new("Frame")
		content.Size = UDim2.new(1, 0, 0, 0)
		content.Position = UDim2.new(0, 0, 0, 40)
		content.BackgroundTransparency = 1
		content.Parent = sec
		local cl = Instance.new("UIListLayout")
		cl.Padding = UDim.new(0, 6)
		cl.SortOrder = Enum.SortOrder.LayoutOrder
		cl.Parent = content
		local cp = Instance.new("UIPadding")
		cp.PaddingLeft = UDim.new(0, 4)
		cp.PaddingRight = UDim.new(0, 4)
		cp.PaddingTop = UDim.new(0, 6)
		cp.PaddingBottom = UDim.new(0, 4)
		cp.Parent = content
		local expanded = PotassiumHub.sectionStates[key] ~= false
		local function upd()
			if expanded then
				local h = cl.AbsoluteContentSize.Y + 14
				sec.Size = UDim2.new(1, 0, 0, 40 + h)
				content.Size = UDim2.new(1, 0, 0, h)
				content.Visible = true
			else
				sec.Size = UDim2.new(1, 0, 0, 40)
				content.Size = UDim2.new(1, 0, 0, 0)
				content.Visible = false
			end
			chev.Text = expanded and "▼" or "▶"
		end
		local hb = Instance.new("TextButton")
		hb.Size = UDim2.new(1, 0, 1, 0)
		hb.BackgroundTransparency = 1
		hb.Text = ""
		hb.Parent = head
		hb.MouseButton1Click:Connect(function()
			expanded = not expanded
			PotassiumHub.sectionStates[key] = expanded
			local h = expanded and (cl.AbsoluteContentSize.Y + 14) or 0
			TweenService:Create(sec, TweenInfo.new(0.28, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, 40 + h)}):Play()
			TweenService:Create(content, TweenInfo.new(0.28, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, h)}):Play()
			content.Visible = expanded
			chev.Text = expanded and "▼" or "▶"
		end)
		cl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() if expanded then upd() end end)
		if expanded then task.defer(upd) else content.Visible = false end
		return content
	end

	-- ===== BUILD SECTIONS =====
	local mainS = createSection("MAIN", "MAIN")
	createSub("Core", mainS)
	createToggle("Infinite Sapling", "infiniteSapling", mainS)
	createToggle("Unlimited Health", "unlimitedHealth", mainS, function() PotassiumHub:manageHealth() end)
	createToggle("Auto-Eat", "autoEat", mainS, function() PotassiumHub:manageAutoEat() end)
	createToggle("Auto Chop Trees", "autoChop", mainS, function() PotassiumHub:manageAutoChop() end)
	createNum("Chop Hits", "chopHits", 1, 20, mainS)
	createNum("Chop Radius", "chopRadius", 10, 200, mainS)
	createToggle("Kill Aura", "killAura", mainS, function() PotassiumHub:manageKillAura() end)
	createNum("Aura Range", "auraRange", 10, 150, mainS)
	createToggle("Finish Haunted Maze", "finishMaze", mainS)
	createToggle("Collect Maze Tickets", "collectMazeTickets", mainS)

	local kidsS = createSection("AUTO FIND KIDS", "KIDS")
	createToggle("Auto Find All Kids", "autoFindKids", kidsS, function() PotassiumHub:manageKids() end)
	createToggle("Auto Collect Lost Kids", "autoCollectKids", kidsS, function() PotassiumHub:manageKids() end)
	createToggle("Auto Pickup Kid", "autoPickupKid", kidsS, function() PotassiumHub:manageKids() end)
	createToggle("Kids Progress UI", "kidsProgressUI", kidsS)

	local autoS = createSection("AUTO SYSTEMS", "AUTO")
	createToggle("Auto Stronghold Raid", "autoStronghold", autoS, function() PotassiumHub:manageStronghold() end)
	createToggle("Auto Corrupted Hardcore", "autoCorrupted", autoS)
	createToggle("Auto Cooking", "autoCook", autoS)
	createToggle("Auto Biofuel", "autoBiofuel", autoS, function() PotassiumHub:manageCampfire() end)
	createToggle("Auto Campfire", "autoCampfire", autoS, function() PotassiumHub:manageCampfire() end)
	createToggle("Auto Close Gate", "autoCloseGate", autoS)
	createToggle("Auto Self Revive", "autoSelfRevive", autoS)
	createToggle("Auto Revive Team", "autoReviveTeam", autoS)
	createToggle("Auto Skip Night", "autoSkipNight", autoS)
	createToggle("Auto Weather Machine", "autoWeather", autoS)
	createToggle("Activate Decorator Class", "classDecorator", autoS)
	createToggle("Activate Explorer Class", "classExplorer", autoS)
	createToggle("Auto Coins", "autoCoins", autoS, function() PotassiumHub:manageAutoCollect() end)
	createToggle("Auto Diamonds", "autoDiamonds", autoS, function() PotassiumHub:manageAutoCollect() end)
	createToggle("Auto Flowers", "autoFlowers", autoS, function() PotassiumHub:manageAutoCollect() end)
	createToggle("Auto Fishing", "autoFish", autoS, function() PotassiumHub:manageAutoCollect() end)
	createToggle("Auto Open Chests", "autoOpenChest", autoS, function() PotassiumHub:manageAutoCollect() end)
	createToggle("Auto Scrap Junk/Logs", "autoScrap", autoS)
	createToggle("Auto Cultist Gem", "autoCultistGem", autoS)
	createToggle("Auto Recycler", "autoRecycler", autoS)
	createToggle("Auto Stew", "autoStew", autoS)
	createToggle("Auto Medicine", "autoMedicine", autoS)

	local combatS = createSection("COMBAT", "COMBAT")
	createToggle("Chop Aura", "chopAura", combatS, function() PotassiumHub:manageKillAura() end)
	createToggle("Auto Kill All Entities", "autoKillAll", combatS, function() PotassiumHub:manageKillAura() end)
	createToggle("Auto Kill Mossy/Wolf/Turkey", "autoKillMossy", combatS)
	createToggle("Auto TP Kill Cultists", "autoKillCultist", combatS)
	createToggle("Auto Sacrifice Corpse", "autoSacrifice", combatS)
	createToggle("Auto Stun (Deer/Ram/Owl/Cat)", "autoStun", combatS)

	local bringS = createSection("BRING", "BRING")
	createToggle("No Bring Amount Limit", "noBringLimit", bringS)
	createNum("Bring Speed", "bringSpeed", 20, 200, bringS)
	createNum("Bring Max Per Item", "bringMax", 1, 200, bringS)
	createNum("Bring Cooldown", "bringCooldown", 0.05, 2, bringS)
	createNum("Bring Height", "bringHeight", 0, 15, bringS)
	createDrop("Bring Method", "bringMethod", {"Tween", "Teleport"}, bringS)
	createToggle("Bring All Items", "bringAllItems", bringS, function() PotassiumHub:manageBringLoops() end)
	createToggle("Bring All Fuels", "bringFuels", bringS, function() PotassiumHub:manageBringLoops() end)
	createToggle("Bring Food & Healing", "bringFood", bringS, function() PotassiumHub:manageBringLoops() end)
	createToggle("Bring Guns & Armor", "bringGuns", bringS, function() PotassiumHub:manageBringLoops() end)
	createToggle("Bring Trees", "bringTrees", bringS, function() PotassiumHub:manageBringLoops() end)
	createToggle("Bring Mobs", "bringMobs", bringS)
	createToggle("Bring Characters", "bringChars", bringS)
	createBtn("Bring Fuels Now", bringS, function() PotassiumHub:bringObjects({"fuel", "log", "coal", "wood", "biofuel"}, FEATURES.bringMax) end)
	createBtn("Bring Food Now", bringS, function() PotassiumHub:bringObjects({"food", "stew", "meat", "berry", "fish"}, FEATURES.bringMax) end)

	local plantS = createSection("AUTO PLANT", "PLANT")
	createToggle("Auto Plant / Sapling", "autoPlant", plantS, function() PotassiumHub:managePlant() end)
	createToggle("Auto Sapling", "autoSapling", plantS, function() PotassiumHub:managePlant() end)
	createNum("Sapling Radius", "plantRadius", 2, 500, plantS)
	createNum("Distance Between", "plantDistance", 1, 50, plantS)
	createNum("Planting Speed", "plantSpeed", 0.05, 2, plantS)
	createDrop("Plant Method", "plantMethod", {"Around Player", "Around Camp"}, plantS)
	createDrop("Plant Shape", "plantShape", {"Circle", "Square", "Triangle", "Cross", "Hexagon", "Spiral", "Grid"}, plantS)
	createToggle("Show Sapling Preview", "plantPreview", plantS)

	local farmS = createSection("FARMING", "FARM")
	createToggle("Auto Tree Farm", "autoTreeFarm", farmS, function() FEATURES.autoChop = FEATURES.autoTreeFarm PotassiumHub:manageAutoChop() end)
	createDrop("Tree Size", "treeFarmSize", {"Small", "Large", "Both"}, farmS)

	local campS = createSection("CAMP", "CAMP")
	createToggle("Upgrade Campfire", "upgradeCampfire", campS)
	createToggle("Auto Fill Campfire", "autoFillCampfire", campS, function() PotassiumHub:manageCampfire() end)
	createNum("Start Fueling When HP%", "fuelWhenHP", 5, 90, campS)
	createToggle("Auto Cook Food", "autoCookFood", campS)

	local baseS = createSection("AUTO MAKE BASE", "BASE")
	createToggle("Auto Make Base", "autoMakeBase", baseS, function() PotassiumHub:manageBase() end)
	createToggle("Auto Place Structures", "autoPlaceStructures", baseS, function() PotassiumHub:manageBase() end)
	createToggle("Auto Pickup Structures", "autoPickupStructures", baseS, function() PotassiumHub:manageBase() end)
	createToggle("Auto Take Blueprints", "autoTakeBlueprints", baseS, function() PotassiumHub:manageBase() end)
	createToggle("Auto Drop Blueprints", "autoDropBlueprints", baseS, function() PotassiumHub:manageBase() end)
	createToggle("Auto Buy Furniture", "autoBuyFurniture", baseS, function() PotassiumHub:manageBase() end)
	createNum("Base Radius", "baseRadius", 5, 100, baseS)
	createNum("Base Spacing", "baseSpacing", 2, 30, baseS)
	createDrop("Base Shape", "baseShape", {"Grid", "Circle"}, baseS)
	createBtn("Place Base Now", baseS, function()
		FEATURES.autoMakeBase = true
		PotassiumHub:manageBase()
		task.delay(8, function() FEATURES.autoMakeBase = false end)
	end)

	local craftS = createSection("CRAFT", "CRAFT")
	createToggle("Auto Craft", "autoCraft", craftS)
	createNum("Craft Amount", "craftAmount", 1, 50, craftS)
	createNum("Craft Delay", "craftDelay", 0.1, 3, craftS)
	createBtn("Quick Craft x10", craftS, function() print("[PH] Quick craft x10") end)
	createBtn("Stop All Craft", craftS, function() FEATURES.autoCraft = false end)

	local antiS = createSection("ANTI / ESCAPE", "ANTI")
	createToggle("Auto Escape", "autoEscape", antiS, function() PotassiumHub:manageAnti() end)
	createToggle("Escape Deer", "escapeDeer", antiS, function() PotassiumHub:manageAnti() end)
	createDrop("Deer Method", "deerMethod", {"Tween", "Teleport", "Safezone"}, antiS)
	createNum("Deer Distance", "deerDist", 10, 100, antiS)
	createNum("Deer Speed", "deerSpeed", 20, 150, antiS)
	createToggle("Escape Owl", "escapeOwl", antiS, function() PotassiumHub:manageAnti() end)
	createDrop("Owl Method", "owlMethod", {"Tween", "Teleport", "Safezone"}, antiS)
	createNum("Owl Distance", "owlDist", 10, 120, antiS)
	createToggle("Auto Avoid Mobs", "autoAvoid", antiS, function() PotassiumHub:manageAnti() end)
	createNum("Avoid Radius", "avoidRadius", 10, 100, antiS)
	createDrop("Avoid Method", "avoidMethod", {"Tween", "Teleport", "Safezone"}, antiS)

	local tpS = createSection("TELEPORT", "TP")
	createBtn("TP Campfire", tpS, function() PotassiumHub:teleportToKeyword({"campfire", "fire", "camp"}) end)
	createBtn("TP Stronghold", tpS, function() PotassiumHub:teleportToKeyword({"stronghold"}) end)
	createBtn("TP Lost Kids", tpS, function() PotassiumHub:teleportToKeyword({"kid", "child", "lost"}) end)
	createBtn("TP Chests", tpS, function() PotassiumHub:teleportToKeyword({"chest", "crate"}) end)
	createBtn("TP Volcano", tpS, function() PotassiumHub:teleportToKeyword({"volcano", "lava"}) end)
	createBtn("TP Cave", tpS, function() PotassiumHub:teleportToKeyword({"cave", "crystal"}) end)
	createBtn("TP Fairy House", tpS, function() PotassiumHub:teleportToKeyword({"fairy"}) end)
	createBtn("TP Beekeeper", tpS, function() PotassiumHub:teleportToKeyword({"bee", "beekeeper"}) end)
	createBtn("TP Crafting Bench", tpS, function() PotassiumHub:teleportToKeyword({"craft", "bench"}) end)
	createToggle("Auto Open All Chests", "autoOpenAllChests", tpS, function() FEATURES.autoOpenChest = FEATURES.autoOpenAllChests PotassiumHub:manageAutoCollect() end)
	createToggle("Create Safe Zone", "createSafeZone", tpS)
	createBtn("TP All Players (cycle)", tpS, function()
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LP and plr.Character then
				local r = getRoot(plr.Character)
				if r then tpTo(r.Position) task.wait(0.5) end
			end
		end
	end)

	local espS = createSection("ESP / VISUALS", "ESP")
	createToggle("Item ESP", "espItems", espS, function() PotassiumHub:manageESP() end)
	createToggle("Mobs ESP", "espMobs", espS, function() PotassiumHub:manageESP() end)
	createToggle("Kids ESP", "espKids", espS, function() PotassiumHub:manageESP() end)
	createToggle("Chest ESP", "espChests", espS, function() PotassiumHub:manageESP() end)
	createToggle("Players ESP", "espChars", espS, function() PotassiumHub:manageESP() end)
	createBtn("Fullbright / Cave Light", espS, function() PotassiumHub:manageFullbright() end)

	local shopS = createSection("SHOP / TRADERS", "SHOP")
	createBtn("Crafting Bench", shopS, function() PotassiumHub:teleportToKeyword({"craft", "bench"}) end)
	createBtn("Fairy House", shopS, function() PotassiumHub:teleportToKeyword({"fairy"}) end)
	createBtn("Furniture Trader", shopS, function() PotassiumHub:teleportToKeyword({"furniture", "trader"}) end)
	createBtn("Beekeeper House", shopS, function() PotassiumHub:teleportToKeyword({"bee", "beekeeper"}) end)
	createBtn("Tool Trader", shopS, function() PotassiumHub:teleportToKeyword({"tool", "trader"}) end)

	local perfS = createSection("PERFORMANCE", "PERF")
	createToggle("FPS Booster", "fpsBoost", perfS, function() PotassiumHub:managePerf() end)
	createToggle("Remove Sky", "removeSky", perfS, function() PotassiumHub:managePerf() end)
	createToggle("Remove Fog", "removeFog", perfS, function() PotassiumHub:managePerf() end)
	createToggle("Delete Camp Logs", "delCampLogs", perfS, function() PotassiumHub:managePerf() end)
	createToggle("Delete Big Trees", "delBigTrees", perfS, function() PotassiumHub:managePerf() end)
	createToggle("Delete Stones", "delStones", perfS, function() PotassiumHub:managePerf() end)
	createToggle("Delete Bushes", "delBushes", perfS, function() PotassiumHub:managePerf() end)
	createToggle("Delete Grass", "delGrass", perfS, function() PotassiumHub:managePerf() end)

	local playerS = createSection("PLAYER", "PLAYER")
	createToggle("Fly", "fly", playerS, function() PotassiumHub:managePlayerMods() end)
	createNum("Fly Speed", "flySpeed", 10, 200, playerS)
	createNum("Walkspeed", "walkSpeed", 16, 200, playerS, function() PotassiumHub:managePlayerMods() end)
	createNum("Jump Power", "jumpPower", 50, 300, playerS, function() PotassiumHub:managePlayerMods() end)
	createNum("Gravity", "gravity", 0, 500, playerS, function() PotassiumHub:managePlayerMods() end)
	createNum("FOV", "fov", 50, 120, playerS, function() PotassiumHub:managePlayerMods() end)
	createToggle("Noclip", "noclip", playerS, function() PotassiumHub:managePlayerMods() end)
	createToggle("Infinite Jump", "infJump", playerS, function() PotassiumHub:managePlayerMods() end)
	createToggle("Freeze Character", "freezeChar", playerS, function() PotassiumHub:managePlayerMods() end)
	createToggle("Anti Void", "antiVoid", playerS, function() PotassiumHub:managePlayerMods() end)
	createToggle("Quick Interact", "quickInteract", playerS, function() PotassiumHub:manageQuickInteract() end)
	createToggle("Anti AFK", "antiAfk", playerS, function() PotassiumHub:manageAntiAfk() end)
	createToggle("TP Click (T + Click)", "tpClick", playerS)

	local cfgS = createSection("CONFIG", "CONFIG")
	createDrop("Toggle UI Key", "toggleKey", {"RightControl", "LeftControl", "RightShift", "LeftShift", "Insert", "Delete", "F4", "F6", "F8", "V", "B", "N", "P"}, cfgS)
	createBtn("Rejoin Server", cfgS, function() pcall(function() TeleportService:Teleport(game.PlaceId, LP) end) end)
	createBtn("Server Hop", cfgS, function()
		pcall(function()
			TeleportService:Teleport(game.PlaceId, LP)
		end)
	end)

	self.uiVisible = true
	if FEATURES.antiAfk then self:manageAntiAfk() end
end

-- Click TP
UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if FEATURES.tpClick and input.KeyCode == Enum.KeyCode.T then
		local conn
		conn = Mouse.Button1Down:Connect(function()
			if Mouse.Hit then tpTo(Mouse.Hit.Position) end
			if conn then conn:Disconnect() end
		end)
	end
	if input.KeyCode == getToggleKeyCode() then
		if CoreGui:FindFirstChild("PotassiumUIMain") then
			CoreGui.PotassiumUIMain:Destroy()
			PotassiumHub.mainGui = nil
			PotassiumHub.uiVisible = false
			PotassiumHub:createIcon()
		elseif CoreGui:FindFirstChild("PotassiumIcon") then
			if PotassiumHub.iconGui then PotassiumHub.iconGui:Destroy() PotassiumHub.iconGui = nil end
			PotassiumHub:createUI()
		else
			PotassiumHub:createUI()
		end
	end
end)

LP.CharacterAdded:Connect(function(c)
	Character = c
	task.wait(0.6)
	PotassiumHub:runAllManagers()
end)

local function init()
	PotassiumHub.active = true
	PotassiumHub:showLoading()
	task.wait(1.3)
	PotassiumHub:createUI()
	print("POTASSIUM HUB · 99 NIGHTS | Toggle: " .. tostring(FEATURES.toggleKey))
end

xpcall(init, function(err)
	warn("POTASSIUM 99 NIGHTS init fail: " .. tostring(err))
end)

if shared.PotassiumHub then shared.PotassiumHub.active = false end
shared.PotassiumHub = PotassiumHub
