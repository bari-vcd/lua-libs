--!optimize 2

-- Wild Horse Islands

---- Initialization ----
cloneref = cloneref or function(object) return object; end;

firetouchinterest = firetouchinterest or function(...) end;

queueteleport = queueteleport or queue_on_teleport;

---- Services ----
local Players:                   Players                   = cloneref(game:GetService('Players'));
local RunService:                RunService                = cloneref(game:GetService('RunService'));
local ReplicatedStorage:         ReplicatedStorage         = cloneref(game:GetService('ReplicatedStorage'));
local RobloxReplicatedStorage:   RobloxReplicatedStorage   = cloneref(game:GetService('RobloxReplicatedStorage'));
local VirtualUser:               VirtualUser               = cloneref(game:GetService('VirtualUser')) or cloneref(game:FindService('VirtualUser'));
local PathfindingService:        PathfindingService        = cloneref(game:GetService('PathfindingService'));

---- Types ----
type ConnectionsType = {
	[string]: RBXScriptConnection | thread | boolean
};

type HumanoidModsType = {
	walkSpeedLoop: RBXScriptConnection?;
	characterAdded: RBXScriptConnection?;
};

type CheckpointStateType = {
	lastCheckpoint: BasePart?;
	lastCheckpointPosition: Vector3?;
	isProcessing: boolean;
	history: { any };
};

---- Constants ----
local LocalPlayer: Player = Players.LocalPlayer :: Player;

local CONFIG = {
	DEFAULT_MOVE_TIMEOUT = 10;
	DEFAULT_TASK_COOLDOWN = 0.40;
	MAX_SPEED = 2000;
	MIN_SPEED = 1;
	CHECKPOINT_DISTANCE_THRESHOLD = 11;
	STUCK_DISTANCE_THRESHOLD = 3;
	ARRIVAL_DISTANCE = 3;
	PATHFINDING_TIMEOUT = 10;
	HIGH_SPEED_THRESHOLD = 100; -- Use BodyVelocity above this speed
};

---- State Management ----
local Connections: ConnectionsType = {};
local HumanoidModifications: HumanoidModsType = {
	walkSpeedLoop = nil;
	characterAdded = nil;
};

local CheckpointState: CheckpointStateType = {
	lastCheckpoint         = nil;
	lastCheckpointPosition = nil;
	isProcessing           = false;
	history                = {};
};

local CacheFolder: Folder = Instance.new('Folder', RobloxReplicatedStorage);
CacheFolder.Name          = 'CacheFolder';

local load_script_queueteleport: boolean = true;

_G.task_run_wait = CONFIG.DEFAULT_TASK_COOLDOWN;

---- UI Library ----
local WX_UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/hsddhdidj-ops/h/refs/heads/main/lib'))();
WX_UI:Wind(true);

---- Utility Functions ----
local Utils = { ... };

function Utils.GetTableIndex( t: { any } ) : number
	local idx = 0;
	for i, v in pairs(t) do idx = i; end;
	return idx;
end;

function Utils.GetCharacter(player: Player): Model?
	-- Get player character safely
	return player.Character or workspace:FindFirstChild(player.Name, false) or player.CharacterAdded:Wait();
end;

function Utils.GetHumanoid(player: Player?): Humanoid?
	-- Get humanoid from player character
	if player and player.Character then
		return player.Character:FindFirstChildOfClass('Humanoid');
	end;
	return nil;
end;

function Utils.GetHumanoidRootPart(player: Player?): BasePart?
	-- Get HumanoidRootPart from player character
	local character = Utils.GetCharacter(player);
	if character then
		return character:FindFirstChild('HumanoidRootPart', true);
	end;
	return nil;
end;

function Utils.IsUUID(str: string): boolean
	-- Check if string is a valid UUID format
	return string.match(str, "^{%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x}$") ~= nil;
end;

function Utils.GetIslandsFolder(): Folder?
	-- Get the Islands folder from workspace
	if workspace:FindFirstChild('Islands', true) then
		return workspace:WaitForChild('Islands');
	end;
	return nil;
end;

function Utils.GetIslandFolderByName(name: string): Folder?
	-- Get specific island folder by name
	local islandsFolder = Utils.GetIslandsFolder();
	if islandsFolder then
		return islandsFolder:FindFirstChild(name, true);
	end;
	return nil;
end;

function Utils.GetCurrentIslandName(player: Player): string?
	-- Get the island name the player is currently on
	return player:GetAttribute('island') :: string?;
end;

function Utils.GetCurrentRidingAnimalUUID(player: Player): string?
	-- Get UUID of the animal player is currently riding
	return player:GetAttribute('ridingAnimal') :: string?;
end;

---- Character Management ----
local CharacterManager = {};

function CharacterManager.SetWalkSpeed(speed: number): ()
	-- Set and monitor character walk speed
	local humanoid: Humanoid? = Utils.GetHumanoid(LocalPlayer);
	if not humanoid then return end;

	humanoid.WalkSpeed = speed;

	HumanoidModifications.walkSpeedLoop = humanoid:GetPropertyChangedSignal('WalkSpeed'):Connect(function()
		humanoid.WalkSpeed = speed;
	end);
end;

function CharacterManager.EnableSpeedLoop(speed: number

): boolean
	-- Enable continuous speed modification

	if (not speed) or (speed > CONFIG.MAX_SPEED) or (speed < CONFIG.MIN_SPEED) then
		return false;
	end;

	CharacterManager.DisableSpeedLoop();

	if Utils.GetCharacter(LocalPlayer) then
		CharacterManager.SetWalkSpeed(speed);
	end;

	HumanoidModifications.characterAdded = LocalPlayer.CharacterAdded:Connect(function()
		CharacterManager.SetWalkSpeed(speed);
	end);

	return true;
end;

function CharacterManager.DisableSpeedLoop(): ()
	if HumanoidModifications.walkSpeedLoop then
		HumanoidModifications.walkSpeedLoop:Disconnect();
		HumanoidModifications.walkSpeedLoop = nil;
	end;

	if HumanoidModifications.characterAdded then
		HumanoidModifications.characterAdded:Disconnect();
		HumanoidModifications.characterAdded = nil;
	end;
end;

---- Animal Management ----
local AnimalManager = {};

function AnimalManager.GetPlayerAnimalByUUID(player: Player?): Model?

	-- Get player's animal by UUID (O(1))
	if not player then return nil end;

	local uuid = Utils.GetCurrentRidingAnimalUUID(player);
	if not uuid then return nil end;

	local islandName = Utils.GetCurrentIslandName(player);
	local islandFolder = Utils.GetIslandsFolder();

	if islandFolder then
		return islandFolder:FindFirstChild(uuid, true) or workspace:FindFirstChild(uuid, true);
	end;

	return nil;
end;

function AnimalManager.DeletePlayerAnimal(player: Player): boolean
	-- Delete player's animal from workspace
	if not player then return false end;

	local animal = AnimalManager.GetPlayerAnimalByUUID(player);
	if animal then
		animal:Destroy();
		return true;
	end;

	return false;
end;

---- Arena Management ----
local ArenaManager = {};

function ArenaManager.CacheDynamicArenaProps(

): ()
	-- Cache dynamic arena props to prevent interference

	local islandFolder = Utils.GetIslandFolderByName(Utils.GetCurrentIslandName(LocalPlayer));

	if not islandFolder then return end;

	local outdoorArena: Model? = islandFolder:FindFirstChild('Outdoor Arena', true);
	if not outdoorArena then return end;

	local dynamicArena = outdoorArena:FindFirstChild('DynamicArena', true);
	if not dynamicArena then return end;

	local layout = dynamicArena:WaitForChild('_LAYOUT', 9e9);
	if not layout then return end;

	for _, prop in ipairs(layout:WaitForChild('Props', 9e9):GetChildren()) do
		prop.Parent = CacheFolder;
	end;
end;

function ArenaManager.TeleportToOutdoorArena(): ()
	-- Teleport player to outdoor arena
	local islandName = Utils.GetCurrentIslandName(LocalPlayer);
	local islandFolder = Utils.GetIslandFolderByName(islandName);

	if not islandFolder then return end;

	local outdoorArena: Model? = islandFolder:FindFirstChild('Outdoor Arena', true);
	if not outdoorArena then return end;

	local letters = outdoorArena:WaitForChild('Letters');
	if not letters then return end;

	local part = letters:FindFirstChild('Part');
	if not part then return end;

	local character = Utils.GetCharacter(LocalPlayer);
	if character then
		character:MoveTo(part.CFrame.Position);
	end;
end;

---- Pathfinding System ----
local PathfindingSystem = {};

function PathfindingSystem.MoveToPositionDirect(
	rootPart: BasePart,
	targetPosition: Vector3,
	speed: number
): ()
	local humanoid = Utils.GetHumanoid(LocalPlayer);
	if humanoid then
		humanoid.PlatformStand = true;
	end;

	local startTime = tick();
	local t_max_time = 30;

	while (tick() - startTime) < t_max_time do
		local currentPosition = rootPart.Position;
		local distance = (targetPosition - currentPosition).Magnitude;

		-- Arrived at destination
		if distance < CONFIG.ARRIVAL_DISTANCE then
			break;
		end;

		local direction = (targetPosition - currentPosition).Unit;
		local step_size = math.min(speed * 0.05, distance); -- Speed per frame (20 FPS)

		local new_position = currentPosition + (direction * step_size);
		new_position = Vector3.new(new_position.X, currentPosition.Y, new_position.Z);

		rootPart.CFrame = CFrame.new(new_position) * CFrame.Angles(0, math.atan2(direction.X, direction.Z), 0);

		task.wait(0.05);
	end;

	if humanoid then
		humanoid.PlatformStand = false;
	end;
end;

function PathfindingSystem.CreatePath(startPosition: Vector3, 
	targetPosition: Vector3
): Path?

	-- Create optimized path for movement
	local pathParams = {
		AgentRadius = 2;
		AgentHeight = 5;
		AgentCanJump = true;
		AgentCanClimb = false;
		WaypointSpacing = 8;
		Costs = {
			Water = 20;
		};
	};

	local path = PathfindingService:CreatePath(pathParams);

	local success, error = pcall(function( ... )
		path:ComputeAsync(startPosition, targetPosition);
	end);

	if not success or path.Status ~= Enum.PathStatus.Success then
		return nil;
	end;

	return path;
end;

function PathfindingSystem.MoveAlongPath(
	humanoid: Humanoid,
	rootPart: BasePart,
	targetPosition: Vector3,
	timeout: number
): boolean
	-- Move character with speed-aware pathfinding
	local currentSpeed = humanoid.WalkSpeed;

	if currentSpeed >= CONFIG.HIGH_SPEED_THRESHOLD then
		PathfindingSystem.MoveToPositionDirect(rootPart, targetPosition, currentSpeed);
		return true;
	end;

	local path = PathfindingSystem.CreatePath(rootPart.Position, targetPosition);

	if not path then
		-- Fallback to direct movement
		humanoid:MoveTo(targetPosition);
		return false;
	end;

	local waypoints = path:GetWaypoints();
	if #waypoints == 0 then
		return false;
	end;

	local currentWaypointIndex = 1;

	while currentWaypointIndex <= #waypoints do
		local waypoint = waypoints[currentWaypointIndex];

		-- Handle jump waypoints
		if waypoint.Action == Enum.PathWaypointAction.Jump then
			humanoid.Jump = true;
			task.wait(0.15);
		end;

		humanoid:MoveTo(waypoint.Position);

		-- Wait for movement completion
		local moveToFinished = false;
		local startTime = tick();

		local moveConnection: RBXScriptConnection?;
		moveConnection = humanoid.MoveToFinished:Connect(function()
			moveToFinished = true;
			if moveConnection then
				moveConnection:Disconnect();
			end;
		end);

		-- Wait with timeout
		while not moveToFinished and (tick() - startTime) < timeout do
			task.wait(0.1);
		end;

		if moveConnection then
			moveConnection:Disconnect();
		end;

		-- Check if stuck
		if not moveToFinished then
			local distanceToWaypoint = (rootPart.Position - waypoint.Position).Magnitude;

			if distanceToWaypoint > CONFIG.STUCK_DISTANCE_THRESHOLD then
				humanoid.Jump = true;
				task.wait(0.2);
			end;
		end;

		currentWaypointIndex += 1;
	end;

	return true;
end;

---- Checkpoint System ----
local CheckpointSystem = { ... };

function CheckpointSystem.IsNewCheckpoint(checkpointPart: BasePart): boolean
	-- Check if this is a new checkpoint
	if not CheckpointState.lastCheckpoint then
		return true;
	end;

	if CheckpointState.lastCheckpointPosition then
		local distance = (checkpointPart.Position - CheckpointState.lastCheckpointPosition).Magnitude;
		return distance > CONFIG.ARRIVAL_DISTANCE;
	end;

	return CheckpointState.lastCheckpoint ~= checkpointPart;
end;

function CheckpointSystem.UpdateLastCheckpoint(checkpoint_part: BasePart): ()
	-- Update the last visited checkpoint
	CheckpointState.lastCheckpoint         = checkpoint_part;
	CheckpointState.lastCheckpointPosition = checkpoint_part.Position;

	CheckpointState.history[#CheckpointState.history + 1] = 
		{
			Point_part = checkpoint_part,
			Position   = checkpoint_part.Position,
			Time       = tick()
		};
end;

function CheckpointSystem.IsCloseEnough(playerPosition: Vector3, targetPosition: Vector3): boolean
	-- Check if player is close enough to trigger checkpoint
	local xDistance = math.abs(playerPosition.X - targetPosition.X);
	return xDistance <= CONFIG.CHECKPOINT_DISTANCE_THRESHOLD;
end;

function CheckpointSystem.MoveToCheckpoint(
	checkpointPart: BasePart,
	targetCFrame: CFrame,
	moveTimeout: number
): boolean
	-- Move to checkpoint with speed-aware pathfinding

	if CheckpointState.isProcessing then
		return false;
	end;

	-- ! safe - against fucking captcha hahahaha. if it weren't for the fucking external, it would be easier

	--if not CheckpointSystem.IsNewCheckpoint(checkpointPart) then
	--end;

	if (#CheckpointState.history > 3) then
		local s1, s2, s3 = 
			CheckpointState.history[(#CheckpointState.history - 1)], 
		CheckpointState.history[(#CheckpointState.history - 2)], 
		CheckpointState.history[(#CheckpointState.history - 3)];

		if  (checkpointPart.Position == s2.Position and tick() ~= s2.Time) or
			(checkpointPart.Position == s3.Position and tick() ~= s3.Time) 
		then
			warn('[Checkpoint] Skipping duplicate checkpoint');
			return false;
		end;

	end;
	-- !

	checkpointPart.Size = Vector3.new(20, 20, 20); -- Checkpoint size

	CheckpointState.isProcessing = true;

	ArenaManager.CacheDynamicArenaProps();
	AnimalManager.DeletePlayerAnimal(LocalPlayer);

	local root_part = Utils.GetHumanoidRootPart(LocalPlayer);
	if not root_part then
		CheckpointState.isProcessing = false;
		return false;
	end;

	if CheckpointSystem.IsCloseEnough(root_part.Position, targetCFrame.Position) then
		firetouchinterest(checkpointPart, root_part, 0);
		CheckpointSystem.UpdateLastCheckpoint(checkpointPart);
		CheckpointState.isProcessing = false;
		return true;
	end;

	-- Move to checkpoint
	local humanoid = Utils.GetHumanoid(LocalPlayer);
	if not humanoid then
		CheckpointState.isProcessing = false;
		return false;
	end;

	local success = PathfindingSystem.MoveAlongPath(
		humanoid,
		root_part,
		targetCFrame.Position,
		moveTimeout
	);

	CheckpointSystem.UpdateLastCheckpoint(checkpointPart);
	CheckpointState.isProcessing = false;

	return success;
end;

function CheckpointSystem.FindActiveCheckpoint(): BasePart?
	-- Find the current active checkpoint
	local checkpointPart = workspace:FindFirstChild('Part', true) :: Part;

	if checkpointPart and checkpointPart:FindFirstChildOfClass('TouchTransmitter') then
		return checkpointPart :: Part;
	end;

	return nil;
end;

---- Anti-AFK ----
function AntiAFK(): () 	-- Prevent AFK/idle kick
	LocalPlayer.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
		VirtualUser:ClickButton1(Vector2.new())
	end);
end;

---- UI Setup ----
local UISetup = {};

function UISetup.Initialize(): ()
	-- WX_UI:ChangeSexFrameColor(Color3.fromRGB(13, 13, 17));
	WX_UI:DragifyEffect(WX_UI:GetOpUiButton());
end;

function UISetup.CreateAntiAFKButton(): ()
	WX_UI:AddButtToggle(
		WX_UI:WX_CreateButton({
			text = 'Anti-Afk/Anti-Idled';
			ButtonTextSize = 14;
		}),
		function()
			if not Connections['Anti-Afk'] then
				Connections['Anti-Afk'] = true;
				AntiAFK();
				WX_UI:AddKeyBinds({ KeyBindText = 'Anti-Afk'; });
			end;
		end
	);
end;

function UISetup.CreateTeleportButton(): ()
	WX_UI:AddButtToggle(
		WX_UI:WX_CreateButton({
			text = 'Teleport To Outdoor Arena';
			ButtonTextSize = 13;
		}),
		function()
			local currentIsland = Utils.GetCurrentIslandName(LocalPlayer);
			if (currentIsland == 'Training Island') then
				ArenaManager.TeleportToOutdoorArena();
			end;
		end
	);
end;

function UISetup.CreateDeleteHorseButton(): ()
	WX_UI:AddButtToggle(
		WX_UI:WX_CreateButton({
			text = 'Delete My Horse';
			ButtonTextSize = 14;
		}),
		function()
			AnimalManager.DeletePlayerAnimal(LocalPlayer);
		end
	);
end;

function UISetup.CreateSpeedSlider(): ()
	WX_UI:CreateSlider(
		'LoopSpeed:',
		0,
		1500,
		function(speed: number)
			CharacterManager.EnableSpeedLoop(speed);
		end
	);
end;

function UISetup.CreateCooldownInput(): ()
	local frame, button, textBox = WX_UI:WX_TextButtonAndBox({
		ButtonText = 'Change Run Cooldown';
		ButtonTextSize = 13;
		TextBoxText = 'enter cooldown value...';
		TextBoxTextSize = 13;
		FocusLostCallback = function() end;
		FocusedCallback = function() end;
	});

	WX_UI:AddButtToggle(
		button,
		function()
			_G.task_run_wait = tonumber(textBox.Text) or _G.task_run_wait;
		end
	);
end;

function UISetup.Create_Arrival_Distance(): ()
	local frame, button, textBox = WX_UI:WX_TextButtonAndBox({
		ButtonText = 'Change arrival distance';
		ButtonTextSize = 13;
		TextBoxText = 'enter arrival distance...';
		TextBoxTextSize = 13;
		FocusLostCallback = function() end;
		FocusedCallback = function() end;
	});

	WX_UI:AddButtToggle(
		button,
		function()
			CONFIG.ARRIVAL_DISTANCE = tonumber(textBox.Text) or CONFIG.ARRIVAL_DISTANCE;
		end
	);
end;

function UISetup.CreateFarmButton(): ()
	WX_UI:AddButtToggle(
		WX_UI:WX_CreateButton({
			text = 'MoveTo/Farm Arena CheckPoints';
			ButtonTextSize = 13;
		}),
		function()
			if not Connections['MoveToArenaCheckPoints'] then
				WX_UI:AddKeyBinds({ KeyBindText = 'Farm Arena-CheckPoints'; });

				Connections['MoveToArenaCheckPoints'] = task.spawn(function()
					while task.wait(_G.task_run_wait) do
						local checkpoint = CheckpointSystem.FindActiveCheckpoint();

						if checkpoint then
							CheckpointSystem.MoveToCheckpoint(
								checkpoint,
								checkpoint.CFrame,
								CONFIG.PATHFINDING_TIMEOUT
							);
						else
							warn('[Farm] No active checkpoint found. Take the task!');
						end;
					end;
				end);
			elseif Connections['MoveToArenaCheckPoints'] then
				task.cancel(Connections['MoveToArenaCheckPoints']);
				Connections['MoveToArenaCheckPoints'] = nil;
				WX_UI:deleteKeyBinds('Farm Arena-CheckPoints');

				-- Reset state
				CheckpointState.lastCheckpoint         = nil;
				CheckpointState.lastCheckpointPosition = nil;
				CheckpointState.isProcessing           = false;
			end;
		end
	);
end;

UISetup.Initialize();
UISetup.CreateAntiAFKButton();
UISetup.CreateTeleportButton();
UISetup.CreateDeleteHorseButton();
UISetup.CreateSpeedSlider();
UISetup.CreateCooldownInput();
UISetup.CreateFarmButton();
UISetup.Create_Arrival_Distance();

LocalPlayer.OnTeleport:Connect(function(...)
	if queueteleport and load_script_queueteleport then
		load_script_queueteleport = false :: boolean
		queueteleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/bari-vcd/lua-libs/refs/heads/main/libs/Wild-Horse-Islands.lua'))()");
	else
		warn('Incompatible Exploit', 'Your executor does not support queue_on_teleport');
	end;
end);
