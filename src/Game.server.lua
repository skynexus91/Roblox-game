-- Satul dupa Apus: server-authoritative prototype. No external assets.
local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local Lighting = game:GetService('Lighting')
local net = Instance.new('Folder'); net.Name = 'ApusNet'; net.Parent = RS
local action = Instance.new('RemoteEvent'); action.Name = 'Action'; action.Parent = net
local status = Instance.new('RemoteEvent'); status.Name = 'Status'; status.Parent = net
local C = {MinPlayers=2, MaxPlayers=8, Day=100, Night=80, Cycles=3, Intermission=15,
 Range=10, InspectCooldown=20, CaptureCooldown=5, FeedCooldown=8, InfectCooldown=25}
local states = {}
local phase, remaining, cycle, running, roundId = 'Asteptare', 0, 0, false, 0
local message = 'Sunt necesari minimum doi jucatori.'
local spawns = workspace:WaitForChild('Village'):WaitForChild('Spawns'):GetChildren()
local jail = workspace.Village.JailPoint
local lobby = workspace.Village.LobbyPoint
local function root(p) return p.Character and p.Character:FindFirstChild('HumanoidRootPart') end
local function humanoid(p) return p.Character and p.Character:FindFirstChildOfClass('Humanoid') end
local function alive(p)
 local s=states[p]; local h=humanoid(p)
 return s and s.active and not s.captured and h and h.Health>0 and root(p)
end
local function move(p, pos)
 local r=root(p); if r then p.Character:PivotTo(CFrame.new(pos)) end
end
local function tell(p,t) local s=states[p]; if s then s.notice=t; s.noticeUntil=os.clock()+5 end end
local function paint(p)
 local s=states[p]; if not s or not p.Character then return end
 local old=p.Character:FindFirstChild('Revealed'); if old then old:Destroy() end
 if s.active and not s.captured and s.vampire and (phase=='Noapte' or (s.reveal or 0)>os.clock()) then
  local h=Instance.new('Highlight'); h.Name='Revealed'; h.FillColor=Color3.fromRGB(155,20,55)
  h.FillTransparency=0.6; h.OutlineColor=Color3.fromRGB(255,90,95)
  h.DepthMode=Enum.HighlightDepthMode.Occluded; h.Parent=p.Character
 end
 local hum=humanoid(p)
 if hum then
  hum.WalkSpeed=(s.captured and 0) or (phase=='Noapte' and s.vampire and s.active and 20) or 16
  hum.JumpPower=s.captured and 0 or 50; hum.JumpHeight=s.captured and 0 or 7.2
 end
end
local function counts()
 local humans,vamps=0,0
 for p,s in pairs(states) do if s.active and not s.captured and p.Parent==Players then
  if s.vampire then vamps=vamps+1 else humans=humans+1 end
 end end
 return humans,vamps
end
local function winner()
 local h,v=counts()
 if v==0 then return 'Satenii au castigat: toti vampirii au fost capturati.' end
 if h==0 then return 'Vampirii au castigat: satul a fost cucerit.' end
 return nil
end
local function validTarget(p, id)
 if type(id)~='number' then return nil end
 local target=Players:GetPlayerByUserId(id)
 if not target or target==p or not alive(p) or not alive(target) then return nil end
 local a,b=root(p),root(target)
 if (a.Position-b.Position).Magnitude>C.Range then return nil end
 local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Exclude
 ray.FilterDescendantsInstances={p.Character,target.Character}
 if workspace:Raycast(a.Position,b.Position-a.Position,ray) then return nil end
 return target
end
local function capture(target)
 local s=states[target]; s.captured=true; s.pending=false
 move(target,jail.Position+Vector3.new(0,3,0)); paint(target)
 tell(target,'Capturat pana la sfarsitul rundei. Poti urmari actiunea din cripta.')
end
local allowed={Inspect=true,Capture=true,Feed=true,Infect=true}
action.OnServerEvent:Connect(function(p, kind, id)
 local s=states[p]
 if not s or type(kind)~='string' or not allowed[kind] then return end
 local now=os.clock()
 if now<(s.nextRequest or 0) then return end
 s.nextRequest=now+0.25
 if not running then return end
 local target=validTarget(p,id); if not target then tell(p,'Apropie-te de o tinta vizibila, la maximum 10 studs.'); return end
 local t=states[target]
 local cd=C[kind..'Cooldown']
 if now<(s.cooldowns[kind] or 0) then tell(p,'Abilitatea se reincarca.'); return end
 if kind=='Inspect' then
  if s.vampire or phase~='Zi' then return end
  s.cooldowns[kind]=now+cd
  if t.vampire then t.reveal=now+15; paint(target); tell(p,'Vampir descoperit! Captureaza-l in 15 secunde.')
  elseif t.pending then tell(p,'Tinta este infectata. Se transforma la urmatorul apus.')
  else tell(p,'Tinta este om.') end
 elseif kind=='Capture' then
  if s.vampire or phase~='Zi' then return end
  s.cooldowns[kind]=now+cd
  if t.vampire and (t.reveal or 0)>now then capture(target); tell(p,'Vampir capturat in cripta.')
  else tell(p,'Capturezi doar vampiri descoperiti prin investigare.') end
 elseif kind=='Feed' then
  if not s.vampire or phase~='Noapte' or t.vampire then return end
  s.cooldowns[kind]=now+cd
  local th=humanoid(target); local sh=humanoid(p)
  -- Nonlethal stylized feed: nobody is removed from play by health damage.
  th.Health=math.max(25,th.Health-20); sh.Health=math.min(sh.MaxHealth,sh.Health+25)
  tell(target,'Un vampir s-a hranit! Cauta protectia celorlalti.'); tell(p,'Ti-ai refacut sanatatea.')
 elseif kind=='Infect' then
  if not s.vampire or phase~='Noapte' or t.vampire or t.pending or s.infections<1 then return end
  s.cooldowns[kind]=now+cd; s.infections=s.infections-1; t.pending=true
  tell(target,'Esti infectat. Devii vampir la urmatorul apus.'); tell(p,'Infectare reusita. Transformarea are loc la urmatorul apus.')
 end
end)
local function attach(p,char)
 local h=char:WaitForChild('Humanoid',10); local r=char:WaitForChild('HumanoidRootPart',10)
 if not h or not r or not states[p] then return end
 local s=states[p]
 if s.active then
  if s.captured then move(p,jail.Position+Vector3.new(0,3,0))
  else move(p,spawns[math.random(#spawns)].Position+Vector3.new(0,3,0)) end
 else move(p,lobby.Position+Vector3.new(0,3,0)) end
 paint(p)
 h.Died:Connect(function()
  if states[p] and running and states[p].active then
   -- Reset/death cannot erase infection or escape capture.
   states[p].captured=true; states[p].pending=false
  end
 end)
end
local function join(p)
 states[p]={active=false,vampire=false,captured=false,pending=false,cooldowns={},infections=0}
 p.CharacterAdded:Connect(function(char) attach(p,char) end)
 if p.Character then task.spawn(attach,p,p.Character) end
end
Players.PlayerAdded:Connect(join)
Players.PlayerRemoving:Connect(function(p) states[p]=nil end)
for _,p in ipairs(Players:GetPlayers()) do join(p) end
local function setPhase(name,seconds)
 phase=name; remaining=seconds
 Lighting.ClockTime=(name=='Noapte' and 0) or 14
 Lighting.Brightness=(name=='Noapte' and 1) or 2
 Lighting.Ambient=(name=='Noapte' and Color3.fromRGB(65,65,95)) or Color3.fromRGB(130,125,115)
 for p in pairs(states) do paint(p) end
end
local function waitPhase(seconds,check)
 for i=seconds,1,-1 do
  remaining=i
  if check then local result=winner(); if result then return result end end
  task.wait(1)
 end
 return check and winner() or nil
end
task.spawn(function()
 while true do
  for p,s in pairs(states) do
   local role='Spectator'
   if s.active then role=s.vampire and 'Vampir' or 'Satean' end
   local note=(s.noticeUntil or 0)>os.clock() and s.notice or message
   status:FireClient(p,{phase=phase,time=remaining,cycle=cycle,role=role,
    captured=s.captured,pending=s.pending,active=s.active,notice=note,
    infections=s.infections, cooldowns={Inspect=math.max(0,(s.cooldowns.Inspect or 0)-os.clock()),
    Feed=math.max(0,(s.cooldowns.Feed or 0)-os.clock()),Infect=math.max(0,(s.cooldowns.Infect or 0)-os.clock())}})
   if s.active and s.vampire and phase=='Zi' and (s.reveal or 0)<=os.clock() then paint(p) end
  end
  task.wait(0.5)
 end
end)
while true do
 running=false; cycle=0; setPhase('Asteptare',0)
 message='Sunt necesari minimum doi jucatori. Cei intrati in timpul rundei asteapta aici.'
 repeat task.wait(1) until #Players:GetPlayers()>=C.MinPlayers
 message='Runda incepe curand.'; setPhase('Pregatire',C.Intermission); waitPhase(C.Intermission,false)
 if #Players:GetPlayers()>=C.MinPlayers then
  roundId=roundId+1
  local roster=Players:GetPlayers()
  while #roster>C.MaxPlayers do table.remove(roster) end
  local first=roster[math.random(#roster)]
  for _,p in ipairs(roster) do
   local s=states[p]; s.active=true; s.vampire=(p==first); s.captured=false; s.pending=false
   s.cooldowns={}; s.infections=0; s.reveal=0
   local h=humanoid(p)
   if not h or h.Health<=0 then p:LoadCharacterAsync() else
    h.Health=h.MaxHealth; move(p,spawns[math.random(#spawns)].Position+Vector3.new(0,3,0))
   end
  end
  running=true
  local result=nil
  for n=1,C.Cycles do
   cycle=n; message='Ziua: investigheaza si captureaza vampirii descoperiti.'
   setPhase('Zi',C.Day); result=waitPhase(C.Day,true); if result then break end
   for p,s in pairs(states) do if s.active and not s.captured then
    if s.pending then s.vampire=true; s.pending=false; tell(p,'Transformarea s-a incheiat. Esti vampir!') end
    if s.vampire then s.infections=1 end
   end end
   message='Noaptea: ramaneti impreuna. Vampirii pot vana.'
   setPhase('Noapte',C.Night); result=waitPhase(C.Night,true); if result then break end
  end
  running=false
  message=result or 'Satenii au castigat: au supravietuit celor trei nopti.'
  setPhase('Rezultat',10); waitPhase(10,false)
  for p,s in pairs(states) do
   s.active=false; s.captured=false; s.pending=false; s.vampire=false
   paint(p); move(p,lobby.Position+Vector3.new(0,3,0))
  end
 end
end
