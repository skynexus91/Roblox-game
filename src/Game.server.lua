-- Satul dupa Apus: server-authoritative prototype. No external assets.
local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local Lighting = game:GetService('Lighting')
local TweenService=game:GetService('TweenService')
local Combat=require(RS:WaitForChild('CombatRules'))
local Weapons=require(script.Parent.Weapons)
local net = Instance.new('Folder'); net.Name = 'ApusNet'; net.Parent = RS
local action = Instance.new('RemoteEvent'); action.Name = 'Action'; action.Parent = net
local status = Instance.new('RemoteEvent'); status.Name = 'Status'; status.Parent = net
local feedback=Instance.new('RemoteEvent'); feedback.Name='Feedback'; feedback.Parent=net
local C=require(script.Parent.Config)
local Rules=require(script.Parent.Rules)
local RPG=require(script.Parent.Progression)
local Monetization=require(script.Parent.Monetization)
Monetization.Init()
local states = {}
local phase, remaining, cycle, running, roundId = 'Asteptare', 0, 0, false, 0
local message = 'Sunt necesari minimum doi jucatori.'
local spawns = workspace:WaitForChild('Village'):WaitForChild('Spawns'):GetChildren()
table.sort(spawns,function(a,b) return tonumber(a.Name:match('%d+'))<tonumber(b.Name:match('%d+')) end)
local cryptFolder=workspace.Village:WaitForChild('Crypts')
local crypts=cryptFolder:GetChildren()
table.sort(crypts,function(a,b) return a.Name<b.Name end)
local activeCrypts=1
local cryptVisuals={}
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
 p:SetAttribute('RoundActive',s.active); p:SetAttribute('Captured',s.captured)
 local old=p.Character:FindFirstChild('Revealed'); if old then old:Destroy() end
 if s.active and not s.captured and s.vampire and (phase=='Noapte' or (s.reveal or 0)>os.clock()) then
  local h=Instance.new('Highlight'); h.Name='Revealed'; h.FillColor=Color3.fromRGB(155,20,55)
  h.FillTransparency=0.6; h.OutlineColor=Color3.fromRGB(255,90,95)
  h.DepthMode=Enum.HighlightDepthMode.Occluded; h.Parent=p.Character
 end
 local pr=root(p); if pr then pr.Anchored=s.captured end
 local hum=humanoid(p)
 if hum then
  hum.WalkSpeed=(s.captured and 0) or ((s.weakened or 0)>os.clock() and 10) or (phase=='Noapte' and s.vampire and s.active and 20) or 16
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
local function validTarget(p, id, range)
 if type(id)~='number' or id~=id or id==math.huge or id==-math.huge or id%1~=0 or math.abs(id)>9007199254740991 then return nil end
 local target=Players:GetPlayerByUserId(id)
 if not target or target==p or not alive(p) or not alive(target) then return nil end
 local a,b=root(p),root(target)
 if (a.Position-b.Position).Magnitude>(range or C.Range) then return nil end
 local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Exclude
 ray.FilterDescendantsInstances={p.Character,target.Character}
 if workspace:Raycast(a.Position,b.Position-a.Position,ray) then return nil end
 return target
end
local function jailPosition(p)
 local s=states[p]; local index=s and s.jail or 1
 local point=crypts[math.clamp(index,1,activeCrypts)].JailPoint
 -- A fixed personal slot prevents up to ten captives occupying the same point.
 local slot=s and s.jailSlot or 0
 return point.Position+Vector3.new((slot%4-1.5)*6,3,(math.floor(slot/4)-1)*6)
end
local function assignJail(p)
 local prisoners={}
 for other,t in pairs(states) do
  if other~=p and t.active and t.captured then table.insert(prisoners,t) end
 end
 local jail,slot=Rules.JailSlot(prisoners,activeCrypts)
 states[p].jail=jail; states[p].jailSlot=slot
end
local function updateCrypts()
 local count=0
 for p,s in pairs(states) do if s.active and p.Parent==Players then count=count+1 end end
 local desired=Rules.CryptCount(count)
 activeCrypts=desired
 -- Move prisoners out before closing any occupied crypt.
 for p,s in pairs(states) do
  if s.active and s.captured and (not s.jail or s.jail>desired) then
   assignJail(p); move(p,jailPosition(p))
  end
 end
 for i,crypt in ipairs(crypts) do
  local enabled=i<=desired
  crypt:SetAttribute('Active',enabled)
  for _,obj in ipairs(crypt:GetDescendants()) do
   if obj:IsA('BasePart') then
    if not cryptVisuals[obj] then cryptVisuals[obj]={obj.Transparency,obj.CanCollide} end
    obj.Transparency=enabled and cryptVisuals[obj][1] or 1
    obj.CanCollide=enabled and cryptVisuals[obj][2] or false
   elseif obj:IsA('SurfaceGui') then obj.Enabled=enabled end
  end
 end
 workspace.Village:SetAttribute('ActiveCrypts',desired)
end
local function capture(target)
 local s=states[target]; s.captured=true; s.pending=false
 assignJail(target); move(target,jailPosition(target)); paint(target)
 tell(target,'Capturat in cripta '..s.jail..' pana la sfarsitul rundei.')
end
updateCrypts()
RPG.Init(function(p)
 local s=states[p]
 return s and not s.captured and phase~='Rezultat'
end)
local allowed={Inspect=true,Capture=true,Feed=true,Infect=true,Weapon=true}
action.OnServerEvent:Connect(function(p, kind, id)
 local s=states[p]
 if not s or type(kind)~='string' or not allowed[kind] then return end
 local now=os.clock()
 if now<(s.nextRequest or 0) then return end
 s.nextRequest=now+0.25
 if not running then return end
 local tool=p.Character and p.Character:FindFirstChildOfClass('Tool')
 local weapon=tool and Combat.Weapons[tool:GetAttribute('ApusWeapon')]
 if kind=='Weapon' and not weapon then return end
 local target=validTarget(p,id,kind=='Weapon' and weapon.range or C.Range); if not target then tell(p,'Apropie-te de o tinta vizibila, la maximum 10 studs.'); return end
 local t=states[target]
 local cd=kind=='Weapon' and weapon.cooldown or C[kind..'Cooldown']
 if now<(s.cooldowns[kind] or 0) then tell(p,'Abilitatea se reincarca.'); return end
 if kind=='Weapon' then
  local a,b=root(p),root(target); local delta=b.Position-a.Position
  if delta.Magnitude<.01 then return end
  local key=tool:GetAttribute('ApusWeapon')
  if not Combat.CanHit(key,s.vampire,t.vampire,phase,delta.Magnitude,a.CFrame.LookVector:Dot(delta.Unit)) then return end
  s.cooldowns[kind]=now+cd
  local th=humanoid(target); local health=Combat.HealthAfter(th.Health,weapon.damage)
  th.Health=health
  feedback:FireClient(p,{kind='Hit',weapon=key,target=target.UserId})
  feedback:FireClient(target,{kind='Hurt'})
  if health<=1 then
   -- A defeat opens a brief capture window, without death/respawn exploits.
   t.weakened=now+8; t.reveal=now+8; paint(target)
   tell(target,'Slabit timp de 8 secunde. Fugi sau cere ajutor!')
  end
 elseif kind=='Inspect' then
  if s.vampire or phase~='Zi' then return end
  s.cooldowns[kind]=now+cd
  if t.vampire then t.reveal=now+15; paint(target); tell(p,'Vampir descoperit! Captureaza-l in 15 secunde.')
  elseif t.pending then tell(p,'Tinta este infectata. Se transforma la urmatorul apus.')
  else tell(p,'Tinta este om.') end
 elseif kind=='Capture' then
  if s.vampire or (phase~='Zi' and not ((t.weakened or 0)>now)) then return end
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
  if s.captured then move(p,jailPosition(p))
  else move(p,spawns[math.random(#spawns)].Position+Vector3.new(0,3,0)) end
 else move(p,lobby.Position+Vector3.new(0,3,0)) end
 paint(p)
 Weapons.Give(p)
 h.Died:Connect(function()
  if states[p] and running and states[p].active then
   -- Reset/death cannot erase infection or escape capture.
   capture(p)
  end
 end)
end
local function join(p)
 states[p]={active=false,vampire=false,captured=false,pending=false,cooldowns={},infections=0}
 p.CharacterAdded:Connect(function(char) attach(p,char) end)
 if p.Character then task.spawn(attach,p,p.Character) end
 task.spawn(RPG.Join,p)
 Monetization.Join(p)
end
Players.PlayerAdded:Connect(join)
Players.PlayerRemoving:Connect(function(p)
 states[p]=nil; updateCrypts(); RPG.Remove(p)
end)
for _,p in ipairs(Players:GetPlayers()) do join(p) end
local function readyRoster()
 local roster={}
 for _,p in ipairs(Players:GetPlayers()) do
  local h=humanoid(p)
  if RPG.Ready(p) and h and h.Health>0 and root(p) then table.insert(roster,p) end
 end
 return roster
end
local function setPhase(name,seconds)
 phase=name; remaining=seconds
 local night=name=='Noapte'
 workspace:SetAttribute('ApusNight',night)
 TweenService:Create(Lighting,TweenInfo.new(4,Enum.EasingStyle.Sine),{
  ClockTime=night and 0 or 14.5,Brightness=night and 1.3 or 2.2,
  Ambient=night and Color3.fromRGB(76,83,116) or Color3.fromRGB(133,126,112),
  OutdoorAmbient=night and Color3.fromRGB(85,96,126) or Color3.fromRGB(145,151,163)
 }):Play()
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
   status:FireClient(p,{phase=phase,time=remaining,cycle=cycle,maxCycles=C.Cycles,role=role,
    captured=s.captured,pending=s.pending,active=s.active,notice=note,
    infections=s.infections,crypts=activeCrypts,rpg=RPG.Snapshot(p)})
   if phase=='Zi' and (s.reveal or 0)>0 and s.reveal<=os.clock() then s.reveal=0; paint(p) end
   if (s.weakened or 0)>0 and s.weakened<=os.clock() then
    s.weakened=0; local h=humanoid(p); if h and h.Health<=1 then h.Health=35 end; paint(p)
   end
  end
  task.wait(1)
 end
end)
while true do
 running=false; cycle=0; setPhase('Asteptare',0)
 message='Sunt necesari minimum doi jucatori. Cei intrati in timpul rundei asteapta aici.'
 repeat task.wait(1) until #readyRoster()>=C.MinPlayers
 message='Runda incepe curand.'; setPhase('Pregatire',C.Intermission); waitPhase(C.Intermission,false)
 if #readyRoster()>=C.MinPlayers then
  roundId=roundId+1
  local roster=readyRoster()
  while #roster>C.MaxPlayers do table.remove(roster) end
  -- Fisher-Yates shuffle; 1 initial vampire per 10 players, maximum 5.
  for i=#roster,2,-1 do local j=math.random(i); roster[i],roster[j]=roster[j],roster[i] end
  local initialVampires=Rules.InitialVampires(#roster)
  for index,p in ipairs(roster) do
   local s=states[p]; s.active=true; s.vampire=(index<=initialVampires); s.captured=false; s.pending=false
   s.cooldowns={}; s.infections=0; s.reveal=0; s.jail=nil; s.jailSlot=nil; s.weakened=0
   local h=humanoid(p)
   if not h or h.Health<=0 then p:LoadCharacterAsync() else
    h.Health=h.MaxHealth; move(p,spawns[index].Position+Vector3.new(0,3,0))
   end
  end
  updateCrypts()
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
  local vampireVictory=result~=nil and string.find(result,'Vampirii au castigat',1,true)~=nil
  for p,s in pairs(states) do
   if s.active then RPG.RoundReward(p,s.vampire==vampireVictory) end
  end
  message=result or 'Satenii au castigat: au supravietuit celor trei nopti.'
  setPhase('Rezultat',10); waitPhase(10,false)
  for p,s in pairs(states) do
   s.active=false; s.captured=false; s.pending=false; s.vampire=false; s.weakened=0
   paint(p); move(p,lobby.Position+Vector3.new(0,3,0))
  end
  updateCrypts()
 end
end
