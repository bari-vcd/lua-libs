-- Wild Horse Islands

-- Copyright (c) | @vcd_ | 2026

-- Version: 0.6
-- @Update-Notice: Version 0.6 introduces a complete architectural overhaul. 
-- Key features include the integration of CascadeUI for a native, responsive interface, 
-- a completely rewritten project, function fallbacks for external users,
-- optimized Pathfinding. Added: uptime tracker + analitics, auto anims skip, calculation skill points,
-- antigameplaypaused, go to larry, auto select task, auto horse equip, anti in-game captcha-clicker -> and general stability improvements.

--[[

   ! ATTENTION ! 
 
   This project is unfinished and closed. 
   
   A full rewrite/recode is expected in the future.

--]]

--!native
--!optimize 2
--!nocheck 

-- [ Upvalue Caching / Fastcall Optimization ]
const task_wait       = task.wait
const task_defer      = task.defer
const task_spawn      = task.spawn
const math_floor      = math.floor
const math_round      = math.round
const string_match    = string.match
const string_find     = string.find
const string_format   = string.format
const string_gsub     = string.gsub
const string_split    = string.split
const table_insert    = table.insert
const table_find      = table.find
const typeof          = typeof
const assert          = assert
const pcall           = pcall
const ipairs          = ipairs
const pairs           = pairs
const Vector3_zero    = Vector3.zero
const CFrame_new      = CFrame.new
const Destroy         = game.Destroy

-- [ Environment Setup ]
gv = getgenv or getfenv
sharedEnv = gv()

function missing(t, f, fallback)
	if type(f) == t then return f; end;
	return fallback;
end;

-- [ Unified Naming Convention (UNC) & Fallbacks ]
cloneref = cloneref or function<T>(reference: T): T
	return reference;
end;

request           = request or sharedEnv.request;
assert(request, `[WX] Executor doesn't support HTTP requests.`);

queueteleport     = queue_on_teleport or queueonteleport or queueteleport
getthreadidentity = getthreadidentity or getidentity or function() return 3 end
getexecutorname   = getexecutorname   or identifyexecutor or function() return 'Unknown' end
getnamecallmethod = getnamecallmethod;
hookfunction      = hookfunction;
getconnections    = getconnections;

getscripthash = getscripthash or function(base_script: BaseScript)
	assert(typeof(base_script) == 'Instance', "Invalid argument #1 tu 'getscripthash' (Instance expected)");
	assert(base_script:IsA('LuaSourceContainer'), "Invalid argument #1 to 'getscripthash' (Must be a LuaSourceContainer)");
	return base_script:GetHash();
end;

firetouchinterest = firetouchinterest or function(source: Instance, target: BasePart, touch: boolean | number)
	-- simple 'firetouchinterest' version (toTouch, touchWith, state)
	
	if typeof(touch) == 'boolean' then touch = if touch then 1 else 0 end

	if touch == 0 or not target then return end

	local targetPart = if source:IsA('BasePart') then source :: BasePart else source:FindFirstAncestorOfClass('BasePart') :: BasePart
	if not targetPart then return end

	local oldCFrame, oldCanCollide = targetPart.CFrame, targetPart.CanCollide
	targetPart.CanCollide = false
	targetPart.CFrame = target.CFrame
	task_wait()
	targetPart.CFrame = oldCFrame
	targetPart.CanCollide = oldCanCollide
end

hookmetamethod = hookmetamethod or function(object: any, metamethod: string, hook: (...any) -> ...any)
	local gmt = getrawmetatable or (debug and debug.getmetatable)
	if not gmt then error('[WX] Executor lacks metatable manipulation capabilities.', 2) end

	local mt = gmt(object)
	local setreadonly = setreadonly or (make_writeable and function(t, v) if v then make_writeable(t) else make_readonly(t) end end)

	if setreadonly then setreadonly(mt, false) end
	local old = mt[metamethod]
	mt[metamethod] = hook
	if setreadonly then setreadonly(mt, true) end

	return old;
end;

-- [ Engine Services ]
const Players                  = cloneref(game:GetService('Players'))
const RunService               = cloneref(game:GetService('RunService'))
const ReplicatedStorage        = cloneref(game:GetService('ReplicatedStorage'))
const RobloxReplicatedStorage  = cloneref(game:GetService('RobloxReplicatedStorage'))
const VirtualUser              = cloneref(game:GetService('VirtualUser') or game:FindService('VirtualUser'))
const VIM                      = cloneref(game:GetService('VirtualInputManager'))
const PathfindingService       = cloneref(game:GetService('PathfindingService'))
const ScriptContext            = cloneref(game:GetService('ScriptContext'))
const LogService               = cloneref(game:GetService('LogService'))
const HttpService              = cloneref(game:GetService('HttpService'))
const UserInputService         = cloneref(game:GetService('UserInputService'))
const LocalizationService      = cloneref(game:GetService('LocalizationService'))
const GuiService               = cloneref(game:GetService('GuiService'))
const COREGUI                  = cloneref(game:FindService('CoreGui') or game.CoreGui)

-- [ Type Definitions ]
export type ConfigType =
{
	Movement:    { MaxSpeed: number, MinSpeed: number, HighSpeedThreshold: number, Timeout: number, NormalJumpPower: number, NormalSpeed: number },
	Pathfinding: { Timeout: number, ArrivalDistance: number, StuckDistanceThreshold: number },
	Farming:     { CheckpointSize: number, CheckpointDistanceThreshold: number, TaskCooldown: number, WaitTime: number },
	Executor:    { Name: string, Identity: number, Capabilities: number }
}

export type CheckpointStateType = 
{ 
	LastCheckpoint: BasePart?;
	LastCheckpointPosition: Vector3?;
	IsProcessing: boolean; 
	History: { any };
};

-- [ State & Initialization ]
local LocalPlayer: Player = Players.LocalPlayer :: Player
local RawVersion: string  = sharedEnv.version()
local ScriptStartTime     = os.clock()

const Config: ConfigType = {
	Movement = {
		NormalJumpPower    = 50,
		NormalSpeed        = 16,
		MaxSpeed           = 2000,
		MinSpeed           = 1,
		HighSpeedThreshold = 100,
		Timeout            = 10,
	},
	Pathfinding = {
		Timeout                = 10,
		ArrivalDistance        = 3,
		StuckDistanceThreshold = 3,
	},
	Farming = {
		CheckpointSize              = 10,
		CheckpointDistanceThreshold = 11,
		TaskCooldown                = 0.40,
		CheckpointTimeout           = 0.50,
	},
	Executor = {
		Name         = getexecutorname() or 'Unknown',
		Identity     = getthreadidentity(),
		Capabilities = 0xFFFFFFFF,
	},
}

local CacheFolder = Instance.new('Folder', RobloxReplicatedStorage);
CacheFolder.Name  = 'CacheFolder';

-- [ Bootstrapper ]
local function importRelease(owner: string, repo: string, repo_version: string, file: string, ...) 
	-- Load CascadeUI library from GitHub

	-- old ui library: https://raw.githubusercontent.com/bari-vcd/lua-libs/refs/heads/main/libs/wx-ui.lua

	return loadstring(
		game:HttpGetAsync(
			`https://github.com/{owner}/{repo}/releases/{
			repo_version == 'latest' and 'latest/download'
				or `download/{repo_version}`
			}/{file}`
		),
		file
	)(...)
end;

local function importRaw(owner: string, repo: string, file: string, ...)
	-- Load raw file from GitHub

	return loadstring(
		game:HttpGetAsync(`https://raw.githubusercontent.com/{owner}/{repo}/{file}`)
	)(...);
end;

-- [ Utilities Module/Section ]
local Utils = { ... };

function Utils.GetLastPairKey(t: {any}): any
	-- Returns the final key of a table

	local v;
	for k in pairs(t) do v = k end;
	return v;
end;

function Utils:GetCharacter(player: Player): Model
	-- Get player character safely

	return player.Character or player.CharacterAdded:Wait();
end;

function Utils:GetHumanoid(player: Player): Humanoid?
	-- Get player humanoid safely

	local char = self:GetCharacter(player);
	return if char then char:FindFirstChildWhichIsA('Humanoid') else nil;
end;

function Utils.Jump(player: Player)
	-- Trigger a jump for a player

	local hum = Utils:GetHumanoid(player)
	if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end;
end;

function Utils:GetHRP(player: Player): BasePart?
	-- Get HumanoidRootPart safely

	local char = self:GetCharacter(player)
	local hrp = char:FindFirstChild('HumanoidRootPart')
	return if hrp and hrp:IsA('BasePart') then hrp else nil
end

function Utils.IsUUID(str: string): boolean
	-- Check if string is a valid UUID format

	return string_match(str, "^{%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x}$") ~= nil;
end;

function Utils:GetIslandsFolder(): Folder
	-- Get the Islands folder from workspace

	return workspace:WaitForChild('Islands', math.huge) :: Folder
end;

function Utils.FormatTime(seconds: number): string
	-- Convert raw seconds into HH:MM:SS format

	local h = math_floor(seconds / 3600)
	local m = math_floor((seconds % 3600) / 60)
	local s = math_floor(seconds % 60)

	return string_format('%02d:%02d:%02d', h, m, s)
end;

function Utils:GetIslandFolderByName(name: string): Folder?
	-- Get a specific island folder by name

	local islands = self:GetIslandsFolder();
	local folder = islands:FindFirstChild(name);
	return if folder and folder:IsA('Folder') then folder else nil;
end;

function Utils.fetch(url: string): string?
	-- Fetch data from a URL

	local success, response = pcall(request, { Url = url, Method = 'GET' });
	return if success and response and response.StatusCode == 200 then response.Body else nil;
end;

function Utils.SetVip(player: Player)
	-- Set VIP attribute for player ( client side only )

	player:SetAttribute('isVip', true);
end;

function Utils:MergeTable(t1, t2)
	for i, v in pairs(t2) do t1[i] = v end
	return t1
end

function Utils:try(f, ...)
	return (pcall(f, ...))
end;

function Utils.GetCurrentIslandName(player: Player): string
	return player:GetAttribute('island') or 'unknown';
end;

function Utils.GetCurrentRidingAnimalUUID(player: Player): string?
	-- Get UUID of the animal player is currently riding

	return player:GetAttribute('ridingAnimal');
end;

do
	local function GetLastVersion(channel: string?): (string?, string?)
		local response = Utils.fetch(`https://clientsettings.roblox.com/v2/client-version/WindowsPlayer?channel={channel or 'LIVE'}`)
		if response then
			local succ, data = pcall(HttpService.JSONDecode, HttpService, response)
			if succ and data and data.clientVersionUpload then
				return data.clientVersionUpload, data.version
			end
		end
		return nil, nil
	end

	local function findInDeployHistory(deployFormatVersion: string): string?
		local body = Utils.fetch('https://setup.rbxcdn.com/DeployHistory.txt')
		if body then 
			local lines = string_split(body, '\n')
			for i = #lines, 1, -1 do
				local line = lines[i]
				if string_find(line, 'WindowsPlayer', 1, true) and string_find(line, deployFormatVersion, 1, true) then
					local hash = string_match(line, '(version%-%w+)')
					if hash then return hash end
				end
			end
		end
		return nil
	end

	function Utils.GetCurrentRobloxClientVersion(): string
		local vn = string_match(RawVersion, '%.%d+%.%d+%.(%d+)')
		local last_hash, last_version_num = GetLastVersion('LIVE')
		if last_version_num and vn and string_find(last_version_num, vn, 1, true) then return last_hash; end;
		return findInDeployHistory(string_gsub(RawVersion, '%.', ', ')) or 'version-unknown'
	end
end

function Utils.IsBeginActivityButton(button: Instance): boolean
	-- Check if button is a Begin Activity button

	if not button:IsA('TextButton') then return false end
	return button:FindFirstChildWhichIsA('TextLabel') ~= nil and button:FindFirstChildWhichIsA('TextLabel').Text == 'Begin Activity';
end;

function Utils.GerCharCurrentPos(player: Player): Vector3
	-- Get the current position of the player character

	local hrp = Utils:GetHRP(player)
	if hrp then return hrp.Position end

	local char = Utils:GetCharacter(player);
	if char and char.PrimaryPart then return char.PrimaryPart.Position end;
	return Vector3_zero;
end;

-- getmenv = getsenv

function Utils.getallthreads()
	local threads = {}
	local index = 1

	while true do
		local thread = debug.getthread(index)
		if thread then
			threads[index] = thread
			index = index + 1
		else
			break
		end
	end

	return threads
end

function Utils.GetRegionCode(): string
	-- Get the region code of the player

	local success, regionCode = pcall(LocalizationService.GetCountryRegionForPlayerAsync, LocalizationService, LocalPlayer);
	return success and regionCode or 'US';
end;

function Utils.FindFirstDescendantByClass(parent: Instance, name: string, className: string): Instance?
	-- Find first descendant of parent with name and class name

	local instance = parent:FindFirstChild(name, true);
	if instance and instance:IsA(className) then
		return instance;
	elseif instance then
		for _, v in ipairs(parent:GetChildren()) do
			local found = Utils.FindFirstDescendantByClass(v, name, className);
			if found then return found end;
		end;
	end;
	return nil;
end;

-- [ AnimalManager Section ]
local AnimalManager = { ... };
AnimalManager.__index = AnimalManager;

function AnimalManager:GetPlayerAnimalByUUID(player: Player): Model?
	-- Get Player Animal by UUID

	local uuid = Utils.GetCurrentRidingAnimalUUID(player);
	if uuid then
		local islands = Utils.GetIslandsFolder()
		return islands:FindFirstChild(uuid, true) or workspace:FindFirstChild(uuid, true);
	end;
	return nil;
end;

function AnimalManager:DestroyPlayerAnimal(player: Player)
	-- Destroy Player Animal

	local animal = self:GetPlayerAnimalByUUID(player);
	if animal then
		animal:Destroy();
	end;
end;

-- [ Math ]
function AnimalManager:SkillPointsPerTimePeriod(quantity: number, avg_time_per_qty: number, total_time: number): number
	-- Get Skill Points Per Time Period

	return math_round((quantity / avg_time_per_qty) * total_time);
end

-- [ Character Manager Module ]
local CharacterManager = {
	__cache = {};
	HumanoidMod = { CharacterAdded = nil; WalkSpeedLoop = nil };
	InfJumpConnection = nil;
};
CharacterManager.__index = CharacterManager;

function CharacterManager:breakVelocity()
	local char = Utils:GetCharacter(LocalPlayer);
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA('BasePart') then
			v.AssemblyLinearVelocity  = Vector3_zero;
			v.AssemblyAngularVelocity = Vector3_zero;
		end;
	end;
end;

function CharacterManager:SetWalkSpeed(speed: number)
	-- Set Looped Walk Speed

	local humanoid = Utils:GetHumanoid(LocalPlayer)
	if humanoid then
		humanoid.WalkSpeed = speed
		if self.HumanoidMod.WalkSpeedLoop then self.HumanoidMod.WalkSpeedLoop:Disconnect() end;

		self.HumanoidMod.WalkSpeedLoop = humanoid:GetPropertyChangedSignal('WalkSpeed'):Connect(function( ... )
			humanoid.WalkSpeed = speed;
		end);
	end;
end;

function CharacterManager:EnableSpeedLoop(speed: number): boolean
	-- Enable continuous speed modification

	if (not speed) or (speed > Config.Movement.MaxSpeed) or (speed < Config.Movement.MinSpeed) then
		return false;
	end;

	self:DisableSpeedLoop();

	if Utils:GetCharacter(LocalPlayer) then
		self:SetWalkSpeed(speed);
	end;

	self.HumanoidMod.CharacterAdded = LocalPlayer.CharacterAdded:Connect(function( character: Model )
		self:SetWalkSpeed(speed);
	end);

	return true;
end;

function CharacterManager:DisableSpeedLoop()
	-- Disable continuous speed modification

	if self.HumanoidMod.WalkSpeedLoop then
		self.HumanoidMod.WalkSpeedLoop:Disconnect();
		self.HumanoidMod.WalkSpeedLoop = nil;
	end;

	if self.HumanoidMod.CharacterAdded then
		self.HumanoidMod.CharacterAdded:Disconnect();
		self.HumanoidMod.CharacterAdded = nil;
	end;
end;

function CharacterManager:GoTo(Possition: Vector3)
	-- Teleport to a given position

	const hrp = Utils:GetHRP(LocalPlayer);

	if hrp then
		--hrp.CFrame = CFrame_new(Possition);
		hrp:PivotTo(CFrame_new(Possition));
	end;
end;

function CharacterManager:SetInfJump(value: boolean)
	-- Enable/Disable infinite jump

	if value then
		if self.InfJumpConnection then self.InfJumpConnection:Disconnect() end;
		self.InfJumpConnection = UserInputService.JumpRequest:Connect(function()
			Utils.Jump(LocalPlayer);
		end);
	else
		if self.InfJumpConnection then
			self.InfJumpConnection:Disconnect();
			self.InfJumpConnection = nil;
		end;
	end;
end;

function CharacterManager:DisableFunnyBall()
	-- Disable funny ball movement

	if self.__cache['RS']  then self.__cache['RS']:Disconnect()  self.__cache['RS']  = nil end;
	if self.__cache['UIS'] then self.__cache['UIS']:Disconnect() self.__cache['UIS'] = nil end;

	local hrp = Utils:GetHRP(LocalPlayer);
	if hrp then
		hrp.Shape = Enum.PartType.Block
		hrp.Size  = Vector3.new(2, 2, 1)
		hrp.CanCollide = false
	end;

	local humanoid = Utils:GetHumanoid(LocalPlayer)
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.JumpPower     = Config.Movement.NormalJumpPower
		humanoid.WalkSpeed     = Config.Movement.NormalSpeed
		self:breakVelocity()
	end
end

function CharacterManager:FunnyBall()
	-- Setup funny ball movement

	local SPEED_MULTIPLIER, JUMP_POWER, JUMP_GAP = 30, 60, 0.3;
	local player_char, Camera = Utils:GetCharacter(LocalPlayer), workspace.CurrentCamera;

	for _, v in ipairs(player_char:GetDescendants()) do
		if v:IsA('BasePart') then v.CanCollide = false end
	end

	local hrp = Utils:GetHRP(LocalPlayer)
	hrp.Shape = Enum.PartType.Ball
	hrp.Size  = Vector3.new(5, 5, 5)

	local humanoid = Utils:GetHumanoid(LocalPlayer)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player_char }

	self.__cache['RS'] = RunService.RenderStepped:Connect(function(deltaTime: number)
		humanoid.PlatformStand, hrp.CanCollide = true, true

		if UserInputService:GetFocusedTextBox() then return end
		local cam_cframe = Camera.CFrame

		if UserInputService:IsKeyDown('W') then hrp.RotVelocity -= cam_cframe.RightVector * deltaTime * SPEED_MULTIPLIER end
		if UserInputService:IsKeyDown('A') then hrp.RotVelocity -= cam_cframe.LookVector  * deltaTime * SPEED_MULTIPLIER end
		if UserInputService:IsKeyDown('S') then hrp.RotVelocity += cam_cframe.RightVector * deltaTime * SPEED_MULTIPLIER end
		if UserInputService:IsKeyDown('D') then hrp.RotVelocity += cam_cframe.LookVector  * deltaTime * SPEED_MULTIPLIER end
	end)

	self.__cache['UIS'] = UserInputService.JumpRequest:Connect(function()
		local result = workspace:Raycast(hrp.Position, Vector3.new(0, -( (hrp.Size.Y / 2) + JUMP_GAP ), 0), params)
		if result then
			hrp.Velocity += Vector3.new(0, JUMP_POWER, 0)
		end
	end)

	Camera.CameraSubject = hrp;
	humanoid.Died:Connect(self.DisableFunnyBall, self);
end;

-- [ local framework ]
local Framework = {
	__cache = {
		AlertTypes = { ['E2'] = 'An error occurred (E2)'; ['TF1'] = 'Too Far!' };
	};
};
Framework.__index = Framework;

function Framework.Set3dRender( value: boolean )
	-- Enable/disable 3D rendering

	RunService:Set3dRenderingEnabled(value);
end;

function Framework.ClearHuiError()
	GuiService:ClearError();
end;

function Framework.AntiKick()
	GuiService.UiMessageChanged:Connect(function(msgType: Enum.UiMessageType, newUiMessage: string)
		-- clear visual kick message
		if msgType == Enum.UiMessageType.Error then Framework.ClearHuiError() end
	end)

	local oldhmmi, oldhmmnc, oldKickFunction;
	if hookfunction then 
		oldKickFunction = hookfunction(LocalPlayer.Kick, function() end) 
	end

	oldhmmi = hookmetamethod(game, '__index', function(self, method)
		if (self == LocalPlayer and method:lower() == 'kick') then
			return error(`Expected ':' not '.' calling member function Kick`, 2)
		end
		return oldhmmi(self, method)
	end)

	oldhmmnc = hookmetamethod(game, '__namecall', function(self, ...)
		if self == LocalPlayer and getnamecallmethod():lower() == 'kick' then return end
		return oldhmmnc(self, ...)
	end)
end

function Framework.SetGameplayPaused( value: boolean )
	-- Remove Visual "GameplayPaused" modal message
	
	GuiService:SetGameplayPausedNotificationEnabled(value);
	
	--Framework.networkPaused = COREGUI.RobloxGui.ChildAdded:Connect(function( Instance: Instance )
	--	if Instance.Name == 'CoreScripts/NetworkPause' then
	--		task_defer(Instance.Destroy, Instance);
	--	end;
	--end);

	-- Framework.networkPaused:Disconnect(); Framework.networkPaused = nil;
	
	local np = COREGUI.RobloxGui:FindFirstChild('CoreScripts/NetworkPause');
	if value and np then np:Destroy(); end;
end;

function Framework:DisableAntiAFK()
	-- Disable Anti AFK

	if Framework.playerIdled then
		Framework.playerIdled:Disconnect();
		Framework.playerIdled = nil;
	end;
end;

function Framework:AntiAFK()
	-- Prevent AFK/idle kick

	self:DisableAntiAFK();

	if getconnections and getconnections(LocalPlayer.Idled) and (not string.find(Config.Executor.Name, 'Xeno')) then
		for _, connection in pairs(getconnections(LocalPlayer.Idled)) do
			if connection['Disable'] then connection['Disable'](connection)
			elseif connection['Disconnect'] then connection['Disconnect'](connection) end;
		end
	else
		Framework.playerIdled = LocalPlayer.Idled:Connect(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new()) --VIM:SendMouseWheelEvent(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y, true, game);
		end);
	end;
end;

function Framework.AntiCaptchaInGame()
	-- anti in-game captcha-clicker

end;

-- Handle alert messages
function Framework:ExternalAlertsHandler( alertType: string, callback)
	local callback_tick = tick();
	self.__cache[callback_tick] = LocalPlayer.PlayerGui:WaitForChild('Alerts').ChildAdded:Connect(function( child: Instance )
		if child:IsA('TextButton') and child.Name == 'MessageItem' then
			local Label = child:FindFirstChild('Label') :: TextLabel;
			--local AlertIcon  = child:FindFirstChild('Icon')  :: ImageLabel;

			if Label and Framework.__cache['AlertTypes'][alertType] == Label.Text then
				callback(alertType, callback_tick);
			end;
		end;
	end);
end;

--https://create.roblox.com/docs/reference/engine/classes/Player#RequestStreamAroundAsync

function Framework.GoToLarry()
	-- Go to Larry's shop

	local currentIsland = Utils:GetIslandFolderByName(Utils.GetCurrentIslandName(LocalPlayer))
	if currentIsland then
		local larry = Utils.FindFirstDescendantByClass(currentIsland, 'Larry', 'Model')
		if larry and larry:GetAttribute('shopName') then
			CharacterManager:GoTo(larry:GetPivot().Position)
		end
	end
end

function Framework.GoToOutdoorArena()
	local CurrentIsland = Utils:GetIslandFolderByName(Utils.GetCurrentIslandName(LocalPlayer));

	if CurrentIsland then
		local outdoorArena = CurrentIsland:FindFirstChild('Outdoor Arena');
		if outdoorArena and outdoorArena:IsA('Model') then 
			local part = outdoorArena:WaitForChild('Letters'):FindFirstChild('Part');
			if part then
				CharacterManager:GoTo(part.CFrame.Position);
			end;
		end;
	end;
end;

function Framework:SetupNetwork()
	local refs = require(ReplicatedStorage:WaitForChild('References', math.huge)) :: any
	if refs then
		local network   = refs.Utilities.Network
		local caHandler = require(refs.PlayerScripts.Secondary:WaitForChild('CheckpointActivityHandler'))

		self.__cache['Network'] = network
		self.__cache['CheckpointActivityHandler'] = caHandler
		return network
	end
end

-- [ External UI (Compatibility Mode) ]
-- for xeno and other externals with 30-40 sunc :>

local ExternalUI = { ... }
ExternalUI.__index = ExternalUI;

function ExternalUI.GetBeginActivityButton(): TextButton?
	for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
		if gui:IsA('ScreenGui') then
			local btn = gui:FindFirstChild('Button')
			if btn and Utils.IsBeginActivityButton(btn) then return btn :: TextButton end
		end
	end
	return nil
end

function ExternalUI.ExternalClick( button : TextButton )
	-- Simulate a click on the Begin Activity button

	button.Visible, button.Active, button.Interactable = true, true, true
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position    = UDim2.fromScale(0.5, 0.5)
	button.Size        = UDim2.fromScale(4, 4)
	button.ZIndex      = 999999

	local screenGui = button:FindFirstAncestorWhichIsA('ScreenGui') :: ScreenGui
	if screenGui and screenGui.Enabled then
		VIM:SendMouseMoveEvent(500, 500, game)
		VIM:SendMouseButtonEvent(500, 500, 0, true, game, 0)
		VIM:SendMouseButtonEvent(500, 500, 0, false, game, 0)
	end
end;

function Utils.CheckpointQuit()
	-- External checkpopint/task quit

	local hud = LocalPlayer.PlayerGui:FindFirstChild('HUD')
	local checkpointFrame = hud and hud:FindFirstChild('Mid') and hud.Mid:FindFirstChild('Checkpoint') :: Frame?
	if checkpointFrame and checkpointFrame.Visible then
		local quitBtn = checkpointFrame:FindFirstChild('Quit')
		if quitBtn and quitBtn:IsA('TextButton') then ExternalUI.ExternalClick(quitBtn) end
	end
end;

function ExternalUI.TryBeginActivity()
	-- Attempt to begin an activity

	local currentIsland = Utils:GetIslandFolderByName(Utils.GetCurrentIslandName(LocalPlayer))
	if not currentIsland then return end

	local dynamicArena = currentIsland:FindFirstChild('Outdoor Arena') and currentIsland['Outdoor Arena']:FindFirstChild('DynamicArena');
	local beginActivityInstance = dynamicArena and dynamicArena:FindFirstChild('ActivityFlags') and dynamicArena.ActivityFlags:FindFirstChild('BeginActivity') :: BasePart?

	if beginActivityInstance then
		--if Config.Executor.Identity >= 7 and Framework.__cache['Network'] then
		-- internal method
		Framework.__cache['Network']:FireServer('CheckpointActivity', 'TriggerInteractable', beginActivityInstance)
		--else
		-- external method
		beginActivityInstance.CFrame = CFrame_new(Utils.GerCharCurrentPos(LocalPlayer))
		local begin_button = ExternalUI.GetBeginActivityButton()
		if begin_button then
			ExternalUI.ExternalClick(begin_button)
		end
		--end
	end
end

-- [ AutoFarm Section ]
local AutoFarm = {
	__cache = {};
	__break = false;
	SAFE_SPEED_LIMIT = 90; -- server limit 100 stud/sec.
	VERTICAL_FLIGHT_HEIGHT = 100;
	PLATFORM_OFFSET = 2.5;
};
AutoFarm.__index = AutoFarm;

function AutoFarm.new( ... )
	-- Constructor

	local self = setmetatable({}, AutoFarm);
	return self;
end;

function AutoFarm:DynamicArenaProps( value: boolean )
	-- Restore the arena props

	local CurrentIsland = Utils:GetIslandFolderByName(Utils.GetCurrentIslandName(LocalPlayer));
	if not CurrentIsland then return; end;

	local ArenaProps = CurrentIsland:FindFirstChild('Outdoor Arena')
		and CurrentIsland['Outdoor Arena']:FindFirstChild('DynamicArena')
		and CurrentIsland['Outdoor Arena'].DynamicArena:FindFirstChild('_LAYOUT')
		and CurrentIsland['Outdoor Arena'].DynamicArena._LAYOUT:FindFirstChild('Props');

	if not ArenaProps then return; end;

	local PropsFolder = CacheFolder:FindFirstChild('PropsFolder');

	if value then
		-- Restore the props
		if ArenaProps and PropsFolder then
			for _, obj in ipairs(PropsFolder:GetChildren()) do obj.Parent = ArenaProps; end;
		end;

		if PropsFolder then PropsFolder:Destroy(); end;
	else
		-- We remove props from the arena for convenience, caching them first
		if PropsFolder then PropsFolder:Destroy(); end;

		PropsFolder = Instance.new('Folder', CacheFolder); 
		PropsFolder.Name = 'PropsFolder';
		for _, prop in ipairs(ArenaProps:GetChildren()) do
			prop.Parent = PropsFolder;
		end;
	end;
end;

function AutoFarm:GetOrCreatePlatform(): Part
	if not self.__cache['SkyPlatform'] or not self.__cache['SkyPlatform'].Parent then
		local platform        = Instance.new('Part', workspace)
		platform.Name         = 'LocalSkyPlatform'
		platform.Size         = Vector3.new(30, 1, 30)
		platform.Transparency = 1;
		platform.Anchored, platform.CanCollide = true, true

		self.__cache['SkyPlatform'] = platform
	end
	return self.__cache['SkyPlatform']
end

function AutoFarm:IsValidCheckpoint(instance: Instance?)
	-- Check if the checkpoint is valid

	if not instance then return false end;

	return (instance.Name == 'Part' 
		and instance:IsA('BasePart') 
		and instance.Parent ~= nil
		and instance:FindFirstChildOfClass('TouchTransmitter') ~= nil);
end;

function AutoFarm:FindActiveCheckpoint(): BasePart?
	-- Find the current active checkpoint  ( Why not just 'workspace:FindFirstChild('Part');' That's a strange question.. because a workspace can have two or more 'Part' objects. )

	local hrp = Utils:GetHRP(LocalPlayer)
	if not hrp then return nil end

	local Part, ShortestDist = nil, math.huge;

	for _, instance in ipairs(workspace:GetChildren()) do
		if self:IsValidCheckpoint(instance) then
			local dist = (instance.Position - hrp.Position).Magnitude;
			if dist < ShortestDist then
				ShortestDist, Part = dist, instance;
			end;
		end;
	end;

	return Part;
end;

function AutoFarm:FindCurrentActivity()
	-- internal method ( FindActiveCheckpoint )

	local activity = Framework.__cache['CheckpointActivityHandler'].currentObject

	if not activity then
		return nil
	end

	if activity.active and not activity.isCleanedUp and activity.currentCheckpointObjects then
		return activity
	end

	return nil
end;

function AutoFarm:UpdateCacheTable(checkpoint_part: BasePart)
	-- Update the cache table ( checkpoints data )

	self.__cache['LastCheckpoint'] = checkpoint_part;
	self.__cache['LastCheckpointPosition'] = checkpoint_part.CFrame.Position;
	self.__cache[tostring(os.clock())] = { checkpoint_part, checkpoint_part.CFrame.Position };
end;

function AutoFarm:ClearCacheTable()
	-- Clear the cache table

	self.__cache = {};
end;

function AutoFarm:GetLastPointPos(): Vector3?
	-- Get the lastest checkpoint position 

	return self.__cache['LastCheckpointPosition'];
end;

function AutoFarm:CalculateMovementDuration(horizontalDistance: number): number
	local rawDuration = (horizontalDistance - 30) / self.SAFE_SPEED_LIMIT

	if rawDuration < 0.75 then return 0; end

	return rawDuration +  0.35
end

function AutoFarm:MoveToValidPos(PartPos: Vector3): boolean
	local hrp = Utils:GetHRP(LocalPlayer)
	if not hrp then return false; end

	local platform  = self:GetOrCreatePlatform() :: Part
	local startPos  = hrp.Position               :: Vector3

	local startXZ   = Vector3.new(startPos.X, 0, startPos.Z)
	local targetXZ  = Vector3.new(PartPos.X, 0, PartPos.Z)

	local minDuration = self:CalculateMovementDuration((targetXZ - startXZ).Magnitude) -- calc. min duration ( horizontal distance  )

	if not self:PerformSmoothMovement(platform, hrp, startXZ, targetXZ, PartPos.Y, minDuration) then return false; end

	platform.CFrame = CFrame_new(PartPos.X, (PartPos.Y + self.VERTICAL_FLIGHT_HEIGHT), PartPos.Z);
	hrp.AssemblyLinearVelocity = Vector3.zero;
	hrp.CFrame = platform.CFrame + Vector3.new(0, self.PLATFORM_OFFSET, 0);

	return true
end

function AutoFarm:PerformSmoothMovement(
	platform: BasePart,
	hrp:      BasePart,
	startXZ:  Vector3,
	targetXZ: Vector3,
	targetY:  number,
	duration: number
	
): boolean
	if duration <= 0 then return true; end

	local startTime: number = os.clock();

	while (os.clock() - startTime) < duration do
		if self.__break then return false; end;

		const cxz = startXZ:Lerp(targetXZ, (os.clock() - startTime) / duration)

		platform.CFrame = CFrame_new(cxz.X, (targetY + self.VERTICAL_FLIGHT_HEIGHT), cxz.Z)
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.CFrame = platform.CFrame + Vector3.new(0, self.PLATFORM_OFFSET, 0)

		RunService.Heartbeat:Wait()
	end

	return true
end

function AutoFarm:Touch(hrp: BasePart, part: BasePart)
	if not self.__break then
		firetouchinterest(hrp, part, false);
		
		RunService.Heartbeat:Wait();

		if part:IsDescendantOf(workspace) then
			firetouchinterest(hrp, part, true);
		end;
	end;
end;

function AutoFarm:DestroyPlatform()
	if self.__cache['SkyPlatform'] then
		self.__cache['SkyPlatform']:Destroy()
		self.__cache['SkyPlatform'] = nil
	end
end

function AutoFarm:ExternalAutoFarm( )

	local function RegisterCheckpoint(ActivePointPart: BasePart)
		ActivePointPart.Size = Vector3.new(Config.Farming.CheckpointSize, Config.Farming.CheckpointSize, Config.Farming.CheckpointSize);

		self:DynamicArenaProps(false);
		AnimalManager:DestroyPlayerAnimal(LocalPlayer);

		local hrp = Utils:GetHRP(LocalPlayer);

		if hrp then
			self:UpdateCacheTable(ActivePointPart);

			local ok = self:MoveToValidPos(ActivePointPart.Position);
			if ok and not self.__break then
				local timeout = os.clock() + Config.Farming.CheckpointTimeout;

				while (ActivePointPart == self:FindActiveCheckpoint()) and (os.clock() < timeout) do
					if self.__break then break; end;
					self:Touch(hrp, ActivePointPart);
					RunService.Heartbeat:Wait();
				end;
			end;
		end;
	end;

	local ActivePointPart = self:FindActiveCheckpoint();

	if ActivePointPart then
		RegisterCheckpoint(ActivePointPart);
	end;

	local connect;
	connect = workspace.ChildAdded:Connect(function(instance: Instance)
		if self.__break and connect then	
			connect:Disconnect();connect = nil;
		end;

		if self:IsValidCheckpoint(instance) then
			RegisterCheckpoint(instance);
		end;
	end);
end;

function AutoFarm:InternalAutoFarm()
	-- for executor 100% sunc 

	local CurrentActivity = self:FindCurrentActivity();

	if CurrentActivity then
		self:DynamicArenaProps(false);
		AnimalManager:DestroyPlayerAnimal(LocalPlayer);

		local hrp = Utils:GetHRP(LocalPlayer);

		if hrp then

		end;
	end;
end;

function AutoFarm:StartAutoFarm()
	-- Start the auto-farming system

	self.__break = false;

	task_spawn(function( ... )
		local function run( name: string )
			while not self.__break do
				self[name]( self );
				task_wait( Config.Farming.TaskCooldown );
			end;
		end;

		--if (Config.Executor.Identity >= 7) then
		-- using internal methods for farming
		--run('InternalAutoFarm');
		--else
		-- using external methods for farming

		local function callback(alertType: string, callback_tick: number)
			-- I'm too lazy to implement anything more for the external version, so let it stay like this
			Config.Farming.TaskCooldown += 0.1;
			task_wait(15);
			Config.Farming.TaskCooldown -= 0.1;
		end;

		Framework:ExternalAlertsHandler( 'TF1', callback);
		Framework:ExternalAlertsHandler( 'E2', callback);

		run('ExternalAutoFarm');
		--end;
	end);
end;

function AutoFarm:BreakAutoFarm()
	-- Stop the auto-farming system

	self.__break = true;
	self:ClearCacheTable();
	self:DestroyPlatform();
	self:DynamicArenaProps(true);
end;

-- [ Setup ]

-- // Set up default values
do
	local Humanoid = Utils:GetHumanoid(LocalPlayer);
	if Humanoid then
		Config.Movement.NormalSpeed, Config.Movement.NormalJumpPower = Humanoid.WalkSpeed, Humanoid.JumpPower;
	end;

	if Config.Executor.Identity >= 7 then
		task_spawn(Framework.SetupNetwork, Framework);
	end;
end;

-- [ ThirdParty ]

-------------------------------------------
-- [ UI INTERFACE SECTION ]
-------------------------------------------
do
	-- [ UI Setup ]
	local cascade = importRelease('cascadeui', 'Cascade', 'latest', 'dist.luau');

	--// Create the application instance
	local app = cascade.New({
		WindowPill = true;
		Theme      = cascade.Themes.Dark,
		Accent     = cascade.Accents.Purple
	});

	--// Create the main window
	local window = app:Window({
		Title       = 'Luau Easy Coding <3';
		Subtitle    = `Roblox Client: {Utils.GetCurrentRobloxClientVersion()}`;
		Searching   = true;
		Draggable   = true;
		Resizable   = true;
		CanExit     = true;
		CanMinimize = true;
		CanZoom     = true;
		Dropshadow  = true;
	});

	--// Create sidebar navigation
	local section = window:Section({
		Title      = 'Navigation';
		Disclosure = false;
	});

	-------------------------------------------
	-- [ TAB: MAIN (DASHBOARD) ]
	-------------------------------------------
	do
		local mainTab = section:Tab({
			Title    = 'Main';
			Icon     = cascade.Symbols.house;
			Selected = true;
		});
		local form = mainTab:Form();

		local infoSection = form:PageSection({
			Title    = `Hello, {LocalPlayer.DisplayName}`;
			Subtitle = 'Welcome to the WareX Dashboard.';
		});
		local infoForm = infoSection:Form();

		--// Uptime Tracker
		local uptimeRow = infoForm:Row({ SearchIndex = 'Environment Uptime' });
		local uptimeStack = uptimeRow:Left():TitleStack({
			Title    = 'Session Runtime';
			Subtitle = '00:00:00';
		});

		task_spawn(function()
			while task_wait(1) do
				uptimeStack.Subtitle = Utils.FormatTime(os.clock() - ScriptStartTime); -- uptimeStack:SetSubtitle(...)
			end;
		end);

		--// Current Island
		local islandRow = infoForm:Row({ SearchIndex = 'Current Island' });
		islandRow:Left():TitleStack({
			Title    = 'Current Location';
			Subtitle = `You are currently on: {Utils.GetCurrentIslandName(LocalPlayer)}`;
		});

		--// Remove Mount
		local mountRow = infoForm:Row({ SearchIndex = 'Remove Mount' });
		mountRow:Left():TitleStack({
			Title    = 'Dismount';
			Subtitle = 'Destroy your current horse/mount.';
		});
		mountRow:Right():Button({
			Label  = 'Execute';
			State  = 'Primary';
			Pushed = function()
				AnimalManager:DestroyPlayerAnimal(LocalPlayer);
				app:Notification({
					Title    = 'Done!';
					Subtitle = 'Mount has been destroyed successfully.';
					App      = 'WAREX';
					Duration = 3;
				});
			end;
		});

		--// Anti AFK
		local antiafkRow = infoForm:Row({ SearchIndex = 'Anti AFK/Idle' });
		antiafkRow:Left():TitleStack({
			Title    = 'AntiAfk';
			Subtitle = 'Prevent Afk/Idle kick.';
		});
		antiafkRow:Right():Button({
			Label  = 'Execute';
			State  = 'Primary';
			Pushed = function()
				Framework:AntiAFK();
				app:Notification({
					Title    = 'Done!';
					Subtitle = 'Anti AFK Enabled.';
					App      = 'WAREX';
					Duration = 3;
				});
			end;
		});

		--// Go To Larry Shop
		local gotolarryRow = infoForm:Row({ SearchIndex = `Go to Larry's shop` });
		gotolarryRow:Left():TitleStack({
			Title    = 'Go To Larry';
			Subtitle = `Teleport you to the nearest Larry's shop`;
		});
		gotolarryRow:Right():Button({
			Label  = 'Execute';
			State  = 'Primary';
			Pushed = function()
				Framework.GoToLarry();
				app:Notification({
					Title    = 'Done!';
					Subtitle = 'You have successfully teleported';
					App      = 'WAREX';
					Duration = 3;
				});
			end;
		});

		--// GoToOutdoorArena
		local GoToOutdoorArenaRow = infoForm:Row({ SearchIndex = `Go to Outdoor Arena` });
		GoToOutdoorArenaRow:Left():TitleStack({
			Title    = 'GoToOutdoorArena';
			Subtitle = `Teleport you to Outdoor Arena`;
		});
		GoToOutdoorArenaRow:Right():Button({
			Label  = 'Execute';
			State  = 'Primary';
			Pushed = function()
				Framework.GoToOutdoorArena();
				app:Notification({
					Title    = 'Done!';
					Subtitle = 'You have successfully teleported';
					App      = 'WAREX';
					Duration = 3;
				});
			end;
		});

		--// AntiGameplayPaused
		local AntiGameplayPausedRow = infoForm:Row({ SearchIndex = `Anti Gameplay Paused` });
		AntiGameplayPausedRow:Left():TitleStack({
			Title    = 'AntiGameplayPaused';
			Subtitle = `Prevent Gameplay Paused message.`;
		});
		AntiGameplayPausedRow:Right():Button({
			Label  = 'Execute';
			State  = 'Primary';
			Pushed = function()
				Framework.SetGameplayPaused(true);
				app:Notification({
					Title    = 'Done!';
					Subtitle = 'AntiGameplayPaused';
					App      = 'WAREX';
					Duration = 3;
				});
			end;
		});
	end; -- [ TAB: END ]


	-------------------------------------------
	-- [ TAB: AUTOMATION (FARMING & RAGE) ]
	-------------------------------------------
	do
		local automationTab = section:Tab({
			Title = 'Automation';
			Icon  = cascade.Symbols.cpu;
		});

		-- [ Section: Training & Farming ]
		local farmSection = automationTab:PageSection({
			Title    = 'Training Auto Farm';
			Subtitle = 'Configure automated resource and training routines.';
		});
		local farmForm = farmSection:Form();

		-- Toggle: Auto Farm
		local autoFarmRow = farmForm:Row({ SearchIndex = 'Auto Farm' });
		autoFarmRow:Left():TitleStack({
			Title    = 'Enable Auto Farm';
			Subtitle = 'Automatically progress through training checkpoints.';
		});
		autoFarmRow:Right():Toggle({
			Value = false;
			ValueChanged = function(self: any, value: boolean)
				--Config.Farming.AutoFarm = value;

				if value then
					AutoFarm:StartAutoFarm();
					app:Notification({
						Title    = 'Done!';
						Subtitle = 'Auto Farm has been enabled.';
						App      = 'WAREX';
						Duration = 3;
					});
				else
					AutoFarm:BreakAutoFarm();
					app:Notification({
						Title    = 'Done!';
						Subtitle = 'Auto Farm has been disabled.';
						App      = 'WAREX';
						Duration = 3;
					});
				end;
			end;
		});

		-- Slider: Checkpoint Size
		local cpSizeRow = farmForm:Row({ SearchIndex = 'Checkpoint Size' });
		cpSizeRow:Left():TitleStack({
			Title    = 'Checkpoint Size';
			Subtitle = 'Detection radius for reaching a target node.';
		});
		cpSizeRow:Right():Slider({
			Value = Config.Farming.CheckpointSize;
			Minimum = 1;
			Maximum = 50;
			ValueChanged = function(self: any, value: number)
				Config.Farming.CheckpointSize = value;
			end;
		});

		--// UI Section: Rage & Exploits
		local rageSection = automationTab:PageSection({
			Title    = 'Rage Features';
			Subtitle = 'Aggressive automation options (use with caution).';
		});
		local rageForm = rageSection:Form();

		-- Toggle: Auto Skip Animations
		local skipAnimRow = rageForm:Row({ SearchIndex = 'Skip Animations' });
		skipAnimRow:Left():TitleStack({
			Title    = 'Auto Skip Animations';
			Subtitle = 'Bypass internal wait times and cutscenes instantly.';
		});
		skipAnimRow:Right():Toggle({
			Value = false;
			ValueChanged = function(self: any, value: boolean)

			end;
		});
	end;

	-------------------------------------------
	-- [ TAB: MOVEMENT (SPEED & VELOCITY) ]
	-------------------------------------------
	do
		local movementTab = section:Tab({
			Title = 'Movement';
			Icon  = cascade.Symbols.bolt or cascade.Symbols.activity;
		});

		-- [ Section: Character Speed ]
		local speedSection = movementTab:PageSection({
			Title    = 'Character Speed';
			Subtitle = 'Configure client-side speed modifications and loop state.';
		});
		local speedForm = speedSection:Form();

		-- TextField: Speed Value Input
		local speedInputRow = speedForm:Row({ SearchIndex = 'WalkSpeed Loop Configuration' });
		speedInputRow:Left():TitleStack({
			Title    = 'WalkSpeed Loop';
			Subtitle = 'Enter target speed value to hook CharacterManager.';
		});

		local currentSpeed = 16;
		local speedField = speedInputRow:Right():TextField({
			Placeholder  = 'e.g., 50';
			Value        = tostring(currentSpeed);
			ValueChanged = function(self: any, value: string)
				local targetSpeed = tonumber(value);
				if targetSpeed and targetSpeed > 0 then
					currentSpeed = targetSpeed;
					CharacterManager:EnableSpeedLoop(targetSpeed);
					app:Notification({
						Title    = 'Speed Updated!';
						Subtitle = `WalkSpeed set to {targetSpeed}`;
						App      = 'MOVEMENT';
						Duration = 2;
					});
				end;
			end;
		});

		-- Slider: Speed Control (Alternative)
		local speedSliderRow = speedForm:Row({ SearchIndex = 'Speed Slider' });
		speedSliderRow:Left():TitleStack({
			Title    = 'Speed Slider';
			Subtitle = 'Adjust speed using a slider control.';
		});
		speedSliderRow:Right():Slider({
			Value = currentSpeed;
			Minimum = Config.Movement.MinSpeed;
			Maximum = Config.Movement.MaxSpeed;
			ValueChanged = function(self: any, value: number)
				currentSpeed = value;
				speedField.Value = tostring(math.floor(value));
				CharacterManager:EnableSpeedLoop(value);
			end;
		});

		-- Toggle: Disable Speed Loop
		local disableSpeedRow = speedForm:Row({ SearchIndex = 'Disable Speed Loop' });
		disableSpeedRow:Left():TitleStack({
			Title    = 'Disable Speed Loop';
			Subtitle = 'Turn off the speed modification loop.';
		});
		disableSpeedRow:Right():Button({
			Label  = 'Disable';
			State  = 'Destructive';
			Pushed = function()
				CharacterManager:DisableSpeedLoop();
				app:Notification({
					Title    = 'Disabled!';
					Subtitle = 'Speed loop has been disabled.';
					App      = 'MOVEMENT';
					Duration = 2;
				});
			end;
		});

		-- [ Section: Special Movement ]
		local specialSection = movementTab:PageSection({
			Title    = 'Special Movement';
			Subtitle = 'Enable special movement modes and effects.';
		});
		local specialForm = specialSection:Form();

		-- Toggle: Funny Ball Mode
		local funnyBallEnabled = false;
		local funnyBallRow = specialForm:Row({ SearchIndex = 'Funny Ball Mode' });
		funnyBallRow:Left():TitleStack({
			Title    = 'Funny Ball Mode';
			Subtitle = 'Enable the funny ball movement effect.';
		});
		funnyBallRow:Right():Toggle({
			Value = false;
			ValueChanged = function(self: any, value: boolean)
				funnyBallEnabled = value;
				if value then
					CharacterManager:FunnyBall();
					app:Notification({
						Title    = 'Enabled!';
						Subtitle = 'Funny Ball mode is now active.';
						App      = 'MOVEMENT';
						Duration = 2;
					});
				else
					CharacterManager:DisableFunnyBall();

					app:Notification({
						Title    = 'Disabled!';
						Subtitle = 'Funny Ball mode has been disabled.';
						App      = 'MOVEMENT';
						Duration = 2;
					});
				end;
			end;
		});

		-- [ Section: Jump & Flight ]
		local jumpSection = movementTab:PageSection({
			Title    = 'Jump & Flight';
			Subtitle = 'Modify jump power and enable flight capabilities.';
		});
		local jumpForm = jumpSection:Form();

		-- Slider: Jump Power
		local jumpPowerRow = jumpForm:Row({ SearchIndex = 'Jump Power' });
		jumpPowerRow:Left():TitleStack({
			Title    = 'Jump Power';
			Subtitle = 'Adjust character jump power.';
		});
		jumpPowerRow:Right():Slider({
			Value = 50;
			Minimum = 1;
			Maximum = 300;
			ValueChanged = function(self: any, value: number)
				local humanoid = Utils:GetHumanoid(LocalPlayer);
				if humanoid then
					humanoid.JumpPower = tonumber(value);
				end;
			end;
		});

		-- Toggle: Infinite Jump
		local infJumpRow = jumpForm:Row({ SearchIndex = 'Infinite Jump' });
		infJumpRow:Left():TitleStack({
			Title    = 'Infinite Jump';
			Subtitle = 'Jump infinitely in the air.';
		});
		infJumpRow:Right():Toggle({
			Value = false;
			ValueChanged = function(self: any, value: boolean)
				CharacterManager:SetInfJump( value )

				if value then
					app:Notification({
						Title    = 'Enabled!';
						Subtitle = 'Infinite Jump is now active.';
						App      = 'MOVEMENT';
						Duration = 2;
					});
				else
					app:Notification({
						Title    = 'Disabled!';
						Subtitle = 'Infinite Jump has been disabled.';
						App      = 'MOVEMENT';
						Duration = 2;
					});
				end;
			end;
		});
	end;

	-------------------------------------------
	-- [ TAB: SETTINGS ]
	-------------------------------------------
	do
		local settingsTab = section:Tab({
			Title = 'Settings';
			Icon  = cascade.Symbols.gear;
		});

		do -- Appearance
			local appearanceForm = settingsTab:PageSection({ Title = 'Appearance' }):Form();

			local themeRow = appearanceForm:Row({ SearchIndex = 'Dark mode' });
			themeRow:Left():TitleStack({
				Title    = 'Dark mode';
				Subtitle = 'Uses a dark color palette to provide a comfortable viewing experience.';
			});
			themeRow:Right():Toggle({
				Value = true,
				ValueChanged = function(self, value)
					app.Theme = value and cascade.Themes.Dark or cascade.Themes.Light
				end;
			});
		end;

		do -- Input Settings
			local inputForm = settingsTab:PageSection({ Title = 'Input' }):Form();
			local function createWindowToggle(name: string, description: string, property: string)
				local row = inputForm:Row({ SearchIndex = name });
				row:Left():TitleStack({ Title = name, Subtitle = description });

				local winDynamic = window :: any;
				row:Right():Toggle({
					Value = winDynamic[property] or false;
					ValueChanged = function(self: any, value: boolean)
						winDynamic[property] = value;
					end;
				});
			end;
			createWindowToggle('Searchable', 'Allows pages to be searched using a text field.', 'Searching');
			createWindowToggle('Draggable', 'Allows users to move the window.', 'Draggable');
			createWindowToggle('Resizable', 'Allows users to resize the window.', 'Resizable');
		end;

		do -- Effects Settings
			local effectsForm = settingsTab:PageSection({
				Title    = 'Effects';
				Subtitle = 'These effects may be resource intensive across different systems.';
			}):Form();

			local shadowRow = effectsForm:Row({ SearchIndex = 'Dropshadow' });
			shadowRow:Left():TitleStack({
				Title    = 'Dropshadow';
				Subtitle = 'Enables a dropshadow effect on the window.';
			});
			shadowRow:Right():Toggle({
				Value = window.Dropshadow;
				ValueChanged = function(self: any, value: boolean)
					window.Dropshadow = value;
				end;
			});

			local blurRow = effectsForm:Row({ SearchIndex = 'Background blur' });
			blurRow:Left():TitleStack({
				Title    = 'Background blur';
				Subtitle = 'Enables a UI background blur effect. Can be detectable in some games.';
			});
			local winDynamic = window :: any;
			blurRow:Right():Toggle({
				Value = winDynamic.UIBlur or false;
				ValueChanged = function(self: any, value: boolean)
					winDynamic.UIBlur = value;
				end;
			});
		end;

		do -- Keybind Settings
			local keybindForm = settingsTab:PageSection({
				Title    = 'Keybinds',
				Subtitle = 'Configure keyboard shortcuts'
			}):Form()

			local keybindRow = keybindForm:Row({ SearchIndex = 'UI Toggle Key' })
			keybindRow:Left():TitleStack({ Title = 'UI Toggle Key', Subtitle = 'Key to open/close menu' })

			keybindRow:Right():KeybindField({
				Value = Enum.KeyCode.Insert,

				ValueChanged = function(self, value: Enum.KeyCode)
					app:Notification({
						Title    = 'Keybind Updated!',
						Subtitle = string_format('UI Toggle set to: %s', value.Name),
						App      = 'Settings',
						Duration = 3
					})
				end,

				BindPressed = function(self, 
					value: Enum.KeyCode,
					inputComplete: boolean,
					gameProcessedEvent: boolean
				)
					if not inputComplete or gameProcessedEvent then return; end

					if window.CanMinimize then
						window.Minimized = not window.Minimized
					end;
				end,
			});
		end;
	end;

	-- [ Initialization Notification ]
	app:Notification({
		Title    = 'Loaded!';
		Subtitle = 'WareX has been initialized successfully.';
		App      = 'WaX';
		Duration = 3;
	});
end;

-- [ EOF ] // (End of File)
