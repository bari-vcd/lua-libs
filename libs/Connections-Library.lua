-------------------------------------------
--[[
	
	Scripted by @vcd_
	
	Last Updated: 01/13/26
	
--]]
-------------------------------------------

-- [ Upvalue Caching / Performance Optimization ]
local cloneref = (cloneref or function<T>(reference: T): T return reference end)

local CoreGui = cloneref(game:FindService('CoreGui'))

-- [ Types Definitions ]
export type ConnectiosType = {
	[string]: RBXScriptConnection,
}

export type LoggerModule = {
	new: (self: LoggerModule) -> LoggerModule,
	
	-- [ Methods ]
	RemoveConnection: (this: LoggerModule, connection: RBXScriptConnection) -> (),
	AddConnection: (this: LoggerModule, connection: RBXScriptConnection) -> (),
	
	-- [ Properties ]
	Connections: ConnectiosType,
}

-- [ Module Definition ]
local Module = {
	Connections = {}
};
Module.__index = Module

-- [ Module Methods ]
function Module.new(): LoggerModule
	-- Constructor
	return (setmetatable({}, Module) :: any) :: LoggerModule;
end;

function Module:Close()
	-- destructor
	for _, connection in self:GetConnections() do
		connection:Disconnect();
	end;
end;

function Module:RemoveConnection(func_pointer)
	-- Remove Connection by function pointer ( in connections table ) 
	
	if self.Connections[tostring(func_pointer)] then
		self.Connections[tostring(func_pointer)]:Disconnect();
		self.Connections[tostring(func_pointer)] = nil;
	end;
end;

function Module:AddConnection(func_pointer, signal: RBXScriptConnection)
	if not self.Connections[tostring(func_pointer)] then
		self.Connections[tostring(func_pointer)] = signal;
	end;
end;

function Module:GetConnection(func_pointer): RBXScriptConnection?
	return self.Connections[tostring(func_pointer)];
end;

function Module:GetConnections(): ConnectiosType?
	return self.Connections;
end;

return Module :: LoggerModule;

-------------------------------------------
-- [ EOF ]
-------------------------------------------
