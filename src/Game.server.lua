-- Satul dupa Apus: server-authoritative prototype. No external assets.
local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local Lighting = game:GetService('Lighting')
local TweenService=game:GetService('TweenService')
local Combat=require(RS:WaitForChild('CombatRules'))
local Weapons=require(script.Parent.Weapons)
local Bots=require(script.Parent.Bots)
local Sessions=require(script.Parent.Sessions)
local Hunt=require(script.Parent.HuntRules)
local Design=require(script.Parent.CharacterDesign)
local Life=require(script.Parent.WorldLife)
local RunService=game:GetService('RunService')
local function isBot(p) return type(p)=='table' and p.IsBot==true end
local function emit(remote,p,data) if not isBot(p) then remote:FireClient(p,data) end end
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
local setPhase
local practiceRound=false
local pendingBotCount=nil
local scores={humans=0,vampires=0}
local practiceScores={humans=0,vampires=0}
local message = 'At least two participants are required.'
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
local function protected(p)
 local s,r=states[p],root(p)
 return s and not s.captured and r and Hunt.Protected(s.vampire,r.Position.X,r.Position.Y,r.Position.Z)
end
local function paint(p)
 local s=states[p]; if not s or not p.Character then return end
 if s.creature then return end
 Design.Apply(p.Character,s.vampire and s.active and (phase=='Noapte' or s.captured or (s.reveal or 0)>os.clock()))
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
  local stopped=s.captured or (s.stunnedUntil or 0)>os.clock()
  hum.WalkSpeed=(stopped and 0) or ((s.weakened or 0)>os.clock() and 10) or (phase=='Noapte' and s.vampire and s.active and 20) or 16
  hum.JumpPower=stopped and 0 or 50; hum.JumpHeight=stopped and 0 or 7.2
 end
end
local function counts()
 local humans,vamps=0,0
 for p,s in pairs(states) do if s.active and not s.creature and not s.captured and p.Parent==Players then
  if s.vampire then vamps=vamps+1 else humans=humans+1 end
 end end
 return humans,vamps
end
local function winner()
 local h,v=counts()
 if v==0 then return 'Villagers win: all vampires have been captured.' end
 if h==0 then return 'Vampires win: the village has fallen.' end
 return nil
end
local function validTarget(p, id, range)
 if type(id)~='number' or id~=id or id==math.huge or id==-math.huge or id%1~=0 or math.abs(id)>9007199254740991 then return nil end
 local target=id<0 and (Bots.Resolve(id) or Life.Resolve(id)) or Players:GetPlayerByUserId(id)
 if not target or target==p or not alive(p) or not alive(target) then return nil end
 if protected(p) or protected(target) then return nil end
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
 for p,s in pairs(states) do if s.active and not s.creature and p.Parent==Players then count=count+1 end end
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
 tell(target,'Captured in crypt '..s.jail..' until the round ends.')
end
local function damageActor(target,amount)
 local s,h=states[target],humanoid(target)
 if not s or not h then return end
 if s.creature then
  h.Health=math.max(0,h.Health-amount)
  if h.Health<=0 then Life.Defeat(target) end
  return
 end
 h.Health=Combat.HealthAfter(h.Health,amount)
 if s.vampire and amount>0 and root(target) then
  feedback:FireAllClients({kind='VampireBlood',position=root(target).Position+Vector3.new(0,1,0)})
 end
 if h.Health<=1 then
  s.weakened=os.clock()+8; s.reveal=os.clock()+8; paint(target)
  tell(target,'Weakened for 8 seconds. Escape or call for help!')
 end
end
Life.Init({states=states,root=root,alive=alive,protected=protected,hurt=damageActor,
 register=function(p) states[p]={active=true,vampire=true,creature=true,captured=false,cooldowns={},infections=0} end,
 remove=function(p) states[p]=nil end})
updateCrypts()
RPG.Init(function(p)
 local s=states[p]
 return s and not s.captured and phase~='Rezultat'
end)
local allowed={Inspect=true,Capture=true,Feed=true,Infect=true,Weapon=true}
local function handleAction(p, kind, id)
 local s=states[p]
 if not s or type(kind)~='string' or not allowed[kind] then return end
 local now=os.clock()
 if now<(s.nextRequest or 0) then return end
 s.nextRequest=now+0.25
 if not running or (s.stunnedUntil or 0)>now then return end
 local tool=p.Character and p.Character:FindFirstChildOfClass('Tool')
 local weaponKey=isBot(p) and (s.testWeapon or (s.vampire and 'Claws' or 'SilverSword')) or (tool and tool:GetAttribute('ApusWeapon'))
 local weapon=Combat.Weapons[weaponKey]
 if kind=='Weapon' and not weapon then return end
 local target=validTarget(p,id,kind=='Weapon' and weapon.range or C.Range); if not target then tell(p,'Approach a visible target within 10 studs.'); return end
 local t=states[target]
 if t.creature and kind~='Weapon' then return end
 local cd=kind=='Weapon' and weapon.cooldown or C[kind..'Cooldown']
 if now<(s.cooldowns[kind] or 0) then tell(p,'Ability is on cooldown.'); return end
 if kind=='Weapon' then
  local a,b=root(p),root(target); local delta=b.Position-a.Position
  if delta.Magnitude<.01 then return end
  local key=weaponKey
  if not Combat.CanHit(key,s.vampire,t.vampire,phase,delta.Magnitude,a.CFrame.LookVector:Dot(delta.Unit)) then return end
  s.cooldowns[kind]=now+cd
  if key=='Crucifix' then
   t.stunnedUntil=now+3; t.reveal=now+8
   if t.creature then target.stunnedUntil=now+3 else paint(target) end
   tell(p,'Consecrated light repels the vampire for 3 seconds.')
  elseif key=='WoodenStake' and not t.creature and Hunt.StakeFinishes(phase,humanoid(target).Health,(t.reveal or 0)>now,(t.weakened or 0)>now) then
   capture(target); tell(p,'Vampire subdued with the wooden stake.')
  else
   damageActor(target,weapon.damage)
   if key=='HolyWater' and states[target] then t.reveal=now+12; paint(target); tell(p,'Holy water exposes the vampire for 12 seconds.') end
  end
  emit(feedback,p,{kind='Hit',weapon=key,target=target.UserId})
  emit(feedback,target,{kind='Hurt'})
 elseif kind=='Inspect' then
  if s.vampire or phase~='Zi' then return end
  s.cooldowns[kind]=now+cd
  if t.vampire then t.reveal=now+15; paint(target); tell(p,'Vampire revealed! Capture them within 15 seconds.')
  elseif t.pending then tell(p,'The target is infected and transforms at the next dusk.')
  else tell(p,'The target is human.') end
 elseif kind=='Capture' then
  if s.vampire or (phase~='Zi' and not ((t.weakened or 0)>now)) then return end
  s.cooldowns[kind]=now+cd
  if t.vampire and (t.reveal or 0)>now then capture(target); tell(p,'Vampire captured in a crypt.')
  else tell(p,'You can only capture vampires revealed by investigation.') end
 elseif kind=='Feed' then
  if not s.vampire or phase~='Noapte' or t.vampire then return end
  s.cooldowns[kind]=now+cd
  local th=humanoid(target); local sh=humanoid(p)
  -- Nonlethal stylized feed: nobody is removed from play by health damage.
  th.Health=math.max(25,th.Health-20); sh.Health=math.min(sh.MaxHealth,sh.Health+25)
  tell(target,'A vampire fed on you! Seek safety with others.'); tell(p,'You recovered health.')
 elseif kind=='Infect' then
  if not s.vampire or phase~='Noapte' or t.vampire or t.pending or s.infections<1 then return end
  s.cooldowns[kind]=now+cd; s.infections=s.infections-1; t.pending=true
  tell(target,'You are infected. You become a vampire at the next dusk.'); tell(p,'Infection successful. Transformation occurs at the next dusk.')
 end
end
action.OnServerEvent:Connect(handleAction)
local function attach(p,char)
 local h=char:WaitForChild('Humanoid',10); local r=char:WaitForChild('HumanoidRootPart',10)
 if not h or not r or not states[p] then return end
 local s=states[p]
 if s.active then
  if s.captured then move(p,jailPosition(p))
  else move(p,spawns[math.random(#spawns)].Position+Vector3.new(0,3,0)) end
 else move(p,lobby.Position+Vector3.new(0,3,0)) end
 paint(p)
 if not isBot(p) then Weapons.Give(p) end
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
 if not isBot(p) then task.spawn(RPG.Join,p); Monetization.Join(p) end
end
Players.PlayerAdded:Connect(join)
Players.PlayerRemoving:Connect(function(p)
 states[p]=nil; updateCrypts(); RPG.Remove(p)
end)
for _,p in ipairs(Players:GetPlayers()) do join(p) end
Sessions.Init(function(count)
 if not RunService:IsStudio() then return false,'Test bots are available only in Studio.' end
 if running or phase~='Asteptare' then
  pendingBotCount=count; workspace:SetAttribute('ApusPendingBotCount',count)
  return true,'Setting '..count..' bots will apply after this round.'
 end
 Bots.SetCount(count,join,function(p) states[p]=nil end)
 updateCrypts()
 return true,'Bots: '..count..'. Practice rounds award no round rewards.'
end)
Bots.Start(states,function() return phase end,handleAction,alive,root)
-- Server-only test harness; never created in published servers or replicated to clients.
if RunService:IsStudio() then
 local probe=Instance.new('BindableFunction'); probe.Name='ApusStudioTest'; probe.Parent=game:GetService('ServerStorage')
 local function resolve(id) return id<0 and (Bots.Resolve(id) or Life.Resolve(id)) or Players:GetPlayerByUserId(id) end
 probe.OnInvoke=function(kind,a,b)
  if kind=='Action' then
   local actor=resolve(a.actor); if actor then handleAction(actor,a.kind,a.target) end
  elseif kind=='Stage' then
   local actor,target=resolve(a),resolve(b)
   if actor and target then
    move(actor,Vector3.new(-100,4,0)); move(target,Vector3.new(-100,4,-5))
    local r=root(actor); if r then actor.Character:PivotTo(CFrame.lookAt(r.Position,root(target).Position)) end
   end
  elseif kind=='Bots' then
   if phase~='Asteptare' then return {error='Between rounds only'} end
   Bots.SetCount(a,join,function(p) states[p]=nil end)
  elseif kind=='Equip' then
   local actor=resolve(a); if actor and isBot(actor) and Combat.Weapons[b] then states[actor].testWeapon=b end
  elseif kind=='Health' then
   local actor=resolve(a); if actor and type(b)=='number' then humanoid(actor).Health=math.clamp(b,1,100) end
  elseif kind=='Position' then
   local actor=resolve(a); if actor and typeof(b)=='Vector3' then move(actor,b) end
  elseif kind=='Score' then
   practiceScores={humans=a,vampires=b}; Life.BeginRound(practiceScores); Life.OnPhase(phase)
  elseif kind=='Phase' and (a=='Zi' or a=='Noapte') then
   setPhase(a,20)
  end
  local result={phase=phase,round=roundId,practice=practiceRound,actors={},humans=0,vampires=0,support=Life.support}
  result.humans,result.vampires=counts()
  for p,s in pairs(states) do
   table.insert(result.actors,{id=p.UserId,bot=isBot(p),active=s.active,vampire=s.vampire,captured=s.captured,
    pending=s.pending,health=humanoid(p) and humanoid(p).Health,revealed=(s.reveal or 0)>os.clock(),jail=s.jail,creature=s.creature,stunned=(s.stunnedUntil or 0)>os.clock()})
  end
  return result
 end
end
local function readyRoster()
 local roster={}
 if workspace:GetAttribute('ApusBotsConfiguring') then return roster end
 for p in pairs(states) do
  local h=humanoid(p)
  if not states[p].creature and (isBot(p) or RPG.Ready(p)) and h and h.Health>0 and root(p) then table.insert(roster,p) end
 end
 return roster
end
local function setSky(night)
 workspace:SetAttribute('ApusNight',night)
 TweenService:Create(Lighting,TweenInfo.new(4,Enum.EasingStyle.Sine),{
  ClockTime=night and 0 or 14.5,Brightness=night and 1.3 or 2.2,
  Ambient=night and Color3.fromRGB(76,83,116) or Color3.fromRGB(133,126,112),
  OutdoorAmbient=night and Color3.fromRGB(85,96,126) or Color3.fromRGB(145,151,163)
 }):Play()
end
setPhase=function(name,seconds)
 phase=name; remaining=seconds
 workspace:SetAttribute('ApusPhase',name)
 workspace:SetAttribute('ApusRoundId',roundId)
 setSky(name=='Noapte')
 Life.OnPhase(name)
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
   local role='Explorator'
   if s.active then role=s.vampire and 'Vampir' or 'Satean' end
   local note=(s.noticeUntil or 0)>os.clock() and s.notice or message
   if not isBot(p) then status:FireClient(p,{phase=phase,time=remaining,cycle=cycle,maxCycles=C.Cycles,role=role,
    captured=s.captured,pending=s.pending,active=s.active,notice=note,
    infections=s.infections,crypts=activeCrypts,night=workspace:GetAttribute('ApusNight'),practice=practiceRound,
    score=practiceRound and practiceScores or scores,support=Life.support,sanctuary=protected(p) and true or false,rpg=RPG.Snapshot(p)}) end
   if s.active and not s.creature and s.vampire and root(p) then
    local pos=root(p).Position
    if Hunt.InSanctuary(pos.X,pos.Y,pos.Z) then move(p,Vector3.new(55,4,-125)); tell(p,'Consecrated ground repels vampires.') end
   end
   if (s.stunnedUntil or 0)>0 and s.stunnedUntil<=os.clock() then s.stunnedUntil=0; paint(p) end
   if phase=='Zi' and (s.reveal or 0)>0 and s.reveal<=os.clock() then s.reveal=0; paint(p) end
   if (s.weakened or 0)>0 and s.weakened<=os.clock() then
    s.weakened=0; local h=humanoid(p); if h and h.Health<=1 then h.Health=35 end; paint(p)
   end
  end
  task.wait(1)
 end
end)
while true do
 if pendingBotCount~=nil then
  Bots.SetCount(pendingBotCount,join,function(p) states[p]=nil end)
  pendingBotCount=nil; workspace:SetAttribute('ApusPendingBotCount',nil); updateCrypts()
 end
 running=false; practiceRound=false; cycle=0; setPhase('Asteptare',0)
 message='Enter the portal to explore. Inn contracts by day; monastery seal at night. PvP: 2+ participants.'
 local explorationTime=0
 local explorationDuration=C.Day
 repeat
  task.wait(1); explorationTime=explorationTime+1
  remaining=explorationDuration-explorationTime
  if explorationTime>=explorationDuration then
   local night=not workspace:GetAttribute('ApusNight'); setSky(night)
   explorationTime=0; explorationDuration=night and C.Night or C.Day
  end
 until #readyRoster()>=C.MinPlayers
 practiceRound=RunService:IsStudio() and (workspace:GetAttribute('ApusBotCount') or 0)>0
 message=practiceRound and 'BOT PRACTICE - no round rewards.' or 'The round starts soon.'
 local preparation=practiceRound and 5 or C.Intermission
 setPhase('Pregatire',preparation); waitPhase(preparation,false)
 if #readyRoster()>=C.MinPlayers then
  roundId=roundId+1
  local roster=readyRoster()
  while #roster>C.MaxPlayers do table.remove(roster) end
  -- Fisher-Yates shuffle; 1 initial vampire per 10 players, maximum 5.
  for i=#roster,2,-1 do local j=math.random(i); roster[i],roster[j]=roster[j],roster[i] end
  local initialVampires=Rules.InitialVampires(#roster)
  for index,p in ipairs(roster) do
   local s=states[p]; s.active=true; s.vampire=(index<=initialVampires); s.captured=false; s.pending=false
   s.cooldowns={}; s.infections=0; s.reveal=0; s.jail=nil; s.jailSlot=nil; s.weakened=0; s.stunnedUntil=0; s.testWeapon=nil
   local h=humanoid(p)
   if not h or h.Health<=0 then p:LoadCharacterAsync() else
    h.Health=h.MaxHealth; move(p,practiceRound and Vector3.new(-70+(index-1)*9,4,-10) or spawns[index].Position+Vector3.new(0,3,0))
   end
  end
  updateCrypts()
  running=true
  Life.BeginRound(practiceRound and practiceScores or scores)
  local result=nil
  for n=1,C.Cycles do
   cycle=n; message='Day: investigate and capture revealed vampires.'
   local day=practiceRound and 20 or C.Day
   setPhase('Zi',day); result=waitPhase(day,true); if result then break end
   for p,s in pairs(states) do if s.active and not s.creature and not s.captured then
    if s.pending then s.vampire=true; s.pending=false; tell(p,'Transformation complete. You are a vampire!') end
    if s.vampire then s.infections=1 end
   end end
   message='Night: stay together. Vampires can hunt.'
   local night=practiceRound and 20 or C.Night
   setPhase('Noapte',night); result=waitPhase(night,true); if result then break end
  end
  running=false
  local humansLeft,vampiresLeft=counts()
  local vampireVictory=Rules.VampireVictory(humansLeft,vampiresLeft)
  local roundScores=practiceRound and practiceScores or scores
  if vampireVictory then roundScores.vampires=roundScores.vampires+1 else roundScores.humans=roundScores.humans+1 end
  for p,s in pairs(states) do
   if s.active and not isBot(p) and not practiceRound then RPG.RoundReward(p,s.vampire==vampireVictory) end
  end
  message=result or 'Villagers win: they survived all three nights.'
  setPhase('Rezultat',10); waitPhase(10,false)
  for p,s in pairs(states) do
   s.active=false; s.captured=false; s.pending=false; s.vampire=false; s.weakened=0; s.stunnedUntil=0
   paint(p); move(p,lobby.Position+Vector3.new(0,3,0))
  end
  updateCrypts()
 end
end
