--!strict

local Signal   = {}
Signal.__index = Signal

function Signal.new()
	local self = setmetatable({
		_handlers = {}
	}, Signal)
	return self
end

function Signal:Connect(fn)
	table.insert(self._handlers, fn)
	return {
		Disconnect = function()
			for i, v in ipairs(self._handlers) do
				if v == fn then table.remove(self._handlers, i) break end
			end
		end
	}
end

function Signal:Fire(...)
	for _, fn in ipairs(self._handlers) do
		task.spawn(fn, ...)
	end
end

return Signal;
