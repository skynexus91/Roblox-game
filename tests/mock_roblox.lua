-- Minimal deterministic API surface for unit tests; no engine or networking.
STUDIO=true
SAVED={}
local clock=0
os.clock=function() return clock end
function advance(n) clock=clock+n end
math.clamp=function(n,a,b) return math.max(a,math.min(b,n)) end
table.find=function(t,value) for i,v in ipairs(t) do if v==value then return i end end end
local function signal()
 local s={listeners={}}
 function s:Connect(fn) table.insert(self.listeners,fn); return {} end
 function s:Fire(...) for _,fn in ipairs(self.listeners) do fn(...) end end
 return s
end
local methods={}
local mt={}
function mt.__index(o,k)
 if methods[k] then return methods[k] end
 for _,child in ipairs(rawget(o,'children') or {}) do if child.Name==k then return child end end
end
function mt.__newindex(o,k,v)
 rawset(o,k,v)
 if k=='Parent' and v and v.children then table.insert(v.children,o) end
end
function methods:GetChildren() return self.children end
function methods:FindFirstChild(name) return self[name] end
function methods:WaitForChild(name) return assert(self[name],name) end
function methods:FindFirstChildOfClass(cls)
 for _,v in ipairs(self.children) do if v.ClassName==cls then return v end end
end
function methods:IsA(cls) return cls==self.ClassName or (cls=='BasePart' and self.ClassName=='Part') end
function methods:SetAttribute(k,v) self.attributes[k]=v end
function methods:GetAttribute(k) return self.attributes[k] end
function methods:Kick(text) self.kicked=text end
local vecmt={}
vecmt.__sub=function(a,b) return {Magnitude=math.abs(a.x-b.x)} end
local function vec(n) return setmetatable({x=n},vecmt) end
Instance={}
function Instance.new(cls)
 return setmetatable({ClassName=cls,Name=cls,children={},attributes={},Triggered=signal(),Enabled=true,Position=vec(0)},mt)
end
Enum={KeyCode={R=1,ButtonL1=2},RaycastFilterType={Exclude=1}}
RaycastParams={new=function() return {} end}
Vector3={new=function(x) return vec(x) end}
CFrame={new=function() return {} end}
Color3={fromRGB=function() return {} end}
local Players=Instance.new('Players')
local store={}
function store:UpdateAsync(key,fn)
 local result=fn(SAVED[key])
 if result then SAVED[key]=result end
 return result
end
DATASTORE_REQUESTS=0
local services={Players=Players,DataStoreService={GetDataStore=function() DATASTORE_REQUESTS=DATASTORE_REQUESTS+1; return store end},
 RunService={IsStudio=function() return STUDIO end},HttpService={GenerateGUID=function() return 'test-session' end}}
game={JobId='job',GetService=function(_,name) return assert(services[name],name) end,BindToClose=function() end}
local Config={StudioPersistence=false,MaxLevel=30,LockLifetime=300,SaveInterval=90}
script={Parent={Config=Config}}
require=function(module) return module end
task={wait=function(n) advance(n or .1) end,spawn=function() end}
warn=function() end
workspace={Village={},attributes={}}
function workspace:GetAttribute(k) return self.attributes[k] end
function workspace:SetAttribute(k,v) self.attributes[k]=v end
local world=Instance.new('Folder'); workspace.Village.WorldNodes=world
function workspace.Village:WaitForChild(name) return self[name] end
function workspace:Raycast() return nil end
for _,name in ipairs({'QuestBoard','Merchant','Trainer','Healer','RitualAltar','TravelGate','Expedition_Forest','Expedition_Mine','Expedition_Ruins',
 'Herb_0','Herb_1','Herb_2','Herb_3','Herb_4','Ore_0','Ore_1','Ore_2','Ore_3','Relic_0','Relic_1','Relic_2','RobuxShop','ContractBoard',
 'Supply_Market','Supply_Mill','Supply_Farm','DawnClue','DawnShrine','Campfire'}) do
 local part=Instance.new('Part'); part.Name=name; part.Parent=world
end
function newPlayer(id)
 local p=Instance.new('Player'); p.UserId=id; p.Parent=Players
 local char=Instance.new('Model'); p.Character=char
 local root=Instance.new('Part'); root.Name='HumanoidRootPart'; root.Parent=char
 local hum=Instance.new('Humanoid'); hum.Health=100; hum.MaxHealth=100; hum.Parent=char
 return p
end
function trigger(name,p)
 local part=assert(world[name],name)
 local prompt=part:FindFirstChild('RPGInteract')
 assert(prompt,'missing prompt: '..name); prompt.Triggered:Fire(p)
end
