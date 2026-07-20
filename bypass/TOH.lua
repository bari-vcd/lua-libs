-------------------------------------------
--[[
	
	Scripted by @vcd_
	
	Last Updated: 17/07/26

    Tower of Hell Anti Cheat Bypass
	
--]]
-------------------------------------------

local cloneref = (cloneref or function<T>(reference: T): T return reference end)
local st       = cloneref(game:GetService('StarterPlayer'))
local player   = cloneref(game:GetService('Players').LocalPlayer)

Destroy  = game.Destroy
ls1, ls2 = player.PlayerScripts.LocalScript, player.PlayerScripts.LocalScript2

for _, v in pairs(getconnections(ls1.Changed)) do
    v:Disable()
end

for _, v in pairs(getconnections(st.StarterPlayerScripts.LocalScript.Changed)) do
    v:Disable()
end

ls1.Enabled, ls2.Enabled = false, false
if getscriptthread then
	t1, t2 = getscriptthread(ls1), getscriptthread(ls2);
	coroutine.close(t1)
	coroutine.close(t2)
end
Destroy(ls1)
Destroy(ls2)
Destroy(st.StarterPlayerScripts.LocalScript)
Destroy(st.StarterPlayerScripts.LocalScript2)
Destroy(st.StarterPlayerScripts.jump)
Destroy(st.StarterPlayerScripts.AnchorPlayer)
print('[+] ok')
