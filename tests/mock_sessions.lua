STUDIO=false; MAP={}; RESERVATIONS=0; TELEPORTS=0; NOW=1000; FAIL_TELEPORT=false
os.time=function() return NOW end
os.clock=function() return NOW end
local function signal() return {Connect=function(self,fn) self.callback=fn end} end
local players={PlayerAdded=signal(),PlayerRemoving=signal()}
function players:GetPlayers() return {} end
local map={}
function map:UpdateAsync(key,fn,ttl) local value=fn(MAP[key]); MAP[key]=value; return value end
function map:GetAsync(key) return MAP[key] end
local teleport={TeleportInitFailed=signal()}
function teleport:ReserveServerAsync() RESERVATIONS=RESERVATIONS+1; return 'secret-access','private-1' end
function teleport:TeleportAsync(place,roster,options)
 TELEPORTS=TELEPORTS+1; if FAIL_TELEPORT then error('teleport unavailable') end
 LAST_OPTIONS=options; LAST_PLACE=place
end
local services={Players=players,ReplicatedStorage={},RunService={IsStudio=function() return STUDIO end},
 TeleportService=teleport,MemoryStoreService={GetHashMap=function() return map end},
 HttpService={GenerateGUID=function() return 'ab12cd34-1111-2222-3333-444455556666' end}}
game={PlaceId=123,PrivateServerId='',GetService=function(_,name) return assert(services[name],name) end}
workspace={GetAttribute=function() return 0 end}
Instance={new=function(cls)
 local obj={}
 function obj:SetTeleportData(data) self.data=data end
 if cls=='RemoteFunction' then REMOTE=obj end
 return obj
end}
task={spawn=function(fn,...) fn(...) end}
script={Parent={}}
require=function(module) return module end
function player(id)
 local p={UserId=id,attributes={}}
 function p:SetAttribute(k,v) self.attributes[k]=v end
 function p:GetAttribute(k) return self.attributes[k] end
 function p:GetJoinData() return {} end
 return p
end
