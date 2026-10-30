-- Server-owned RPG profiles, session leases, quests and contextual interactions.
local Players=game:GetService('Players')
local DSS=game:GetService('DataStoreService')
local RunService=game:GetService('RunService')
local Http=game:GetService('HttpService')
local Config=require(script.Parent.Config)
local Adventure=require(script.Parent.AdventureRules)
local RPG={}
local profiles={}
local session=game.JobId..':'..Http:GenerateGUID(false)
local temporary=RunService:IsStudio() and not Config.StudioPersistence
local store=not temporary and DSS:GetDataStore('ApusRPG_v1') or nil
local closing=false
local classes={'Vanator','Cercetas','Carturar'}
local classNames={Vanator='Hunter',Cercetas='Scout',Carturar='Scholar'}
local quests={
 {kind='Herb',need=5,text='Gather 5 herbs in the southwestern forest',xp=100,gold=50},
 {kind='Ore',need=4,text='Collect 4 ore deposits at the eastern mine',xp=140,gold=70},
 {kind='Relic',need=3,text='Find 3 relics in the northern ruins',xp=180,gold=90},
 {kind='Ritual',need=1,text='Activate the monastery altar to the south',xp=240,gold=120},
}
local function integer(n,max)
 if type(n)~='number' or n~=n or n==math.huge or n==-math.huge then return 0 end
 return math.clamp(math.floor(n),0,max)
end
local function clean(raw)
 raw=type(raw)=='table' and raw or {}
 local q=integer(raw.quest,4); if q<1 then q=1 end
 local class='Vanator'
 for _,v in ipairs(classes) do if raw.class==v then class=v end end
 return {xp=integer(raw.xp,10000000),gold=integer(raw.gold,10000000),
  lantern=integer(raw.lantern,3),class=class,quest=q,
  count=integer(raw.count,quests[q].need),accepted=raw.accepted==true,
  completed=integer(raw.completed,1000000),wins=integer(raw.wins,1000000)}
end
local function copy(d) local c={}; for k,v in pairs(d) do c[k]=v end; return c end
function RPG.Level(xp)
 return math.min(Config.MaxLevel,1+math.floor(math.sqrt(xp/100)))
end
local function publish(p,s)
 local d=s.data
 p:SetAttribute('RPGReady',true)
 p:SetAttribute('LanternTier',d.lantern)
 local stats=p:FindFirstChild('leaderstats')
 if stats then stats.Level.Value=RPG.Level(d.xp); stats.Gold.Value=d.gold end
end
local function reward(p,s,xp,gold)
 -- No client can supply reward amounts, item prices or quest completion.
 s.data.xp=math.min(10000000,s.data.xp+xp)
 s.data.gold=math.min(10000000,s.data.gold+gold)
 publish(p,s)
end
local function notice(p,text) p:SetAttribute('RPGNotice',text) end
function RPG.Ready(p) return profiles[p]~=nil and not profiles[p].leaving end
function RPG.Join(p)
 if closing then p:Kick('The server is shutting down. Please reconnect.'); return end
 local data=nil
 if temporary then data=clean(nil) else
  for attempt=1,3 do
   local ok,result=pcall(function()
    return store:UpdateAsync('u_'..p.UserId,function(old)
     old=type(old)=='table' and old or {}
     local lock=old.lock
     if type(lock)=='table' and lock.id~=session and type(lock.at)=='number'
       and os.time()-lock.at<Config.LockLifetime then return nil end
     return {version=1,data=clean(old.data),lock={id=session,at=os.time()}}
    end)
   end)
   if ok and type(result)=='table' and result.lock and result.lock.id==session then
    data=clean(result.data); break
   end
   task.wait(attempt)
  end
 end
 if not data then
  if p.Parent==Players then p:Kick('Your profile is unavailable or open on another server. Please try again in a few minutes.') end
  return
 end
 profiles[p]={data=data,saving=false,leaving=false,lastSave=os.clock(),nodes={},visits={},nextUse=0,packages={}}
 if p.Parent~=Players or closing then RPG.Remove(p); return end
 local stats=Instance.new('Folder'); stats.Name='leaderstats'; stats.Parent=p
 for _,n in ipairs({'Level','Gold'}) do local v=Instance.new('IntValue'); v.Name=n; v.Parent=stats end
 p:SetAttribute('SaveStatus',temporary and 'TEST - temporary progress' or 'Saving enabled')
 notice(p,'Tip: the quest board is beside the fountain. Interact: R / L1 / touch.')
 publish(p,profiles[p])
end
local function save(p,release)
 local s=profiles[p]; if not s then return true end
 local deadline=os.clock()+20
 while s.saving and os.clock()<deadline do task.wait(.1) end
 if s.saving then return false end
 s.saving=true
 if temporary then s.saving=false; return true end
 local payload=copy(s.data)
 local succeeded=false
 local lost=false
 for attempt=1,3 do
  local ok,result=pcall(function()
   return store:UpdateAsync('u_'..p.UserId,function(old)
    if type(old)~='table' or type(old.lock)~='table' or old.lock.id~=session then
     lost=true; return nil
    end
    return {version=1,data=payload,lock=not release and {id=session,at=os.time()} or nil}
   end)
  end)
  if ok and result and not lost then succeeded=true; break end
  if lost then break end
  task.wait(attempt)
 end
 s.saving=false
 if succeeded then
  s.lastSave=os.clock(); p:SetAttribute('SaveStatus','Saved')
 else
  p:SetAttribute('SaveStatus','Save failed - retrying automatically')
  warn('Apus profile save failed for user '..p.UserId)
  if lost or os.clock()-s.lastSave>Config.LockLifetime-30 then
   s.leaving=true
   if p.Parent==Players then p:Kick('The connection to your saved profile was lost. Please reconnect.') end
  end
 end
 return succeeded
end
function RPG.Remove(p)
 local s=profiles[p]; if not s then return end
 if s.removing then return end
 s.removing=true; s.leaving=true
 local ok=save(p,true)
 if not ok then warn('Final save failed; lock expires automatically for '..p.UserId) end
 profiles[p]=nil
end
function RPG.Snapshot(p)
 local s=profiles[p]
 if not s then return {ready=false} end
 local d=s.data; local q=quests[d.quest]
 local adventure=s.contractAt and ('Delivery: '..(s.packageCount or 0)..'/3 | '..math.max(0,180-math.floor(os.clock()-s.contractAt))..'s | Inn')
  or (s.clue and 'Seal deciphered: activate the shrine at night' or 'Contracts at the inn | Chapel clue by day')
 local signature=table.concat({d.xp,d.gold,d.class,d.lantern,d.quest,d.count,tostring(d.accepted),d.completed,adventure,p:GetAttribute('SaveStatus') or '',p:GetAttribute('RPGNotice') or ''},'|')
 if signature==s.snapshotKey then return s.snapshot end
 s.snapshotKey=signature
 s.snapshot={ready=true,level=RPG.Level(d.xp),xp=d.xp,nextXP=Config.MaxLevel>RPG.Level(d.xp)
  and 100*RPG.Level(d.xp)^2 or d.xp,gold=d.gold,class=d.class,lantern=d.lantern,
  quest=d.accepted and (q.text..' ('..d.count..'/'..q.need..')') or 'Visit the quest board in the market square',
  completed=d.completed,adventure=adventure,save=p:GetAttribute('SaveStatus'),notice=p:GetAttribute('RPGNotice')}
 return s.snapshot
end
function RPG.RoundReward(p,won)
 local s=profiles[p]; if not s or s.leaving then return end
 reward(p,s,won and 160 or 60,won and 80 or 25)
 if won then s.data.wins=s.data.wins+1 end
end
local function progress(p,s,kind)
 local d=s.data; local q=quests[d.quest]
 if not d.accepted or kind~=q.kind or d.count>=q.need then return end
 d.count=d.count+1
 notice(p,d.count>=q.need and 'Objective complete. Return to the quest board for your reward.'
  or (q.text..' '..d.count..'/'..q.need))
end
function RPG.Init(canInteract)
 local nodes=workspace.Village:WaitForChild('WorldNodes')
 for _,part in ipairs(nodes:GetChildren()) do
  if part:IsA('BasePart') and part.Name~='RobuxShop' then
   local name=part.Name
   local prompt=Instance.new('ProximityPrompt')
   prompt.Name='RPGInteract'; prompt.MaxActivationDistance=10
   prompt.RequiresLineOfSight=true; prompt.HoldDuration=.5
   prompt.KeyboardKeyCode=Enum.KeyCode.R; prompt.GamepadKeyCode=Enum.KeyCode.ButtonL1
   prompt.ObjectText=name; prompt.ActionText='Interact'
   if name:match('^Herb_') then prompt.ObjectText='Herbs'; prompt.ActionText='Gather'
   elseif name:match('^Ore_') then prompt.ObjectText='Ore'; prompt.ActionText='Mine'
   elseif name:match('^Relic_') then prompt.ObjectText='Relic'; prompt.ActionText='Investigate'
   elseif name=='QuestBoard' then prompt.ObjectText='Quests'; prompt.ActionText='Accept / Claim reward'
   elseif name=='Merchant' then prompt.ObjectText='Blacksmith'; prompt.ActionText='Lantern +1 (100/200/300 gold)'
   elseif name=='Healer' then prompt.ObjectText='Healer'; prompt.ActionText='Heal (30 gold)'
   elseif name=='Trainer' then prompt.ObjectText='Guild trainer'; prompt.ActionText='Change specialization'
   elseif name=='TravelGate' then prompt.ObjectText='Enter village'; prompt.ActionText='Explore'
   elseif name=='ContractBoard' then prompt.ObjectText='The Raven Inn'; prompt.ActionText='Contract: 3 supplies / 180s'
   elseif name:match('^Supply_') then prompt.ObjectText='Supplies'; prompt.ActionText='Collect for the inn'
   elseif name=='DawnClue' then prompt.ObjectText='Chapel inscription'; prompt.ActionText='Read by daylight'
   elseif name=='DawnShrine' then prompt.ObjectText='Dawn Seal'; prompt.ActionText='Night ritual'
   elseif name=='Campfire' then prompt.ObjectText='Inn hearth'; prompt.ActionText='Cook: 2 herbs / +25 HP'
   elseif name:match('^Expedition_') then prompt.ObjectText='Expedition'; prompt.ActionText='Explore 3 landmarks'
   elseif name=='RitualAltar' then prompt.ObjectText='Altar'; prompt.ActionText='Perform ritual' end
   prompt.Parent=part
   prompt.Triggered:Connect(function(p)
    local s=profiles[p]; local char=p.Character
    local root=char and char:FindFirstChild('HumanoidRootPart')
    local hum=char and char:FindFirstChildOfClass('Humanoid')
    if not s or s.leaving or not root or not hum or hum.Health<=0 or not canInteract(p)
      or not prompt.Enabled or (root.Position-part.Position).Magnitude>10 then return end
    local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Exclude
    ray.FilterDescendantsInstances={char,part}
    if workspace:Raycast(root.Position,part.Position-root.Position,ray) then return end
    local now=os.clock(); if now<s.nextUse then return end
    s.nextUse=now+1
    local d=s.data
    if Adventure.ContractExpired(s.contractAt,now) then
     s.contractAt=nil; s.packages={}; s.packageCount=0
     notice(p,'Contract expired. Accept another at the inn.')
    end
    if name=='TravelGate' then
     if p:GetAttribute('RoundActive') then return end
     char:PivotTo(CFrame.new(0,4,-20)); notice(p,'PvE exploration. You will join the next round.'); return
    elseif name=='ContractBoard' then
     if s.contractAt then
      if Adventure.CanDeliver(s.contractAt,now,s.packageCount or 0) then
       reward(p,s,80,40); s.contractAt=nil; s.packages={}; s.packageCount=0; s.contractReady=now+180
       notice(p,'Supplies delivered: +80 XP / +40 gold. Next contract in 3 minutes.')
      else notice(p,'Collect supplies from the market, mill and farm. Return within 180s.') end
     elseif now<(s.contractReady or 0) then notice(p,'The inn is stocked. Come back later.')
     elseif workspace:GetAttribute('ApusNight') then notice(p,'Accept contracts by day. Search for the seal at night.')
     else s.contractAt=now; s.packages={}; s.packageCount=0; notice(p,'Contract accepted: market, mill, farm -> inn, within 180s.') end
    elseif name:match('^Supply_') then
     if not s.contractAt then notice(p,'Accept a contract at the inn first.')
     elseif s.packages[name] then notice(p,'You have already collected these supplies.')
     else s.packages[name]=true; s.packageCount=(s.packageCount or 0)+1; notice(p,'Supplies '..s.packageCount..'/3. Return to the inn.') end
    elseif name=='DawnClue' then
     if workspace:GetAttribute('ApusNight') then notice(p,'The inscription can only be read by daylight.')
     else s.clue=true; notice(p,'Clue: tonight, awaken the seal in the monastery courtyard.') end
    elseif name=='DawnShrine' then
     if Adventure.CanRitual(s.clue,workspace:GetAttribute('ApusNight'),now,s.ritualReady) then
      s.clue=false; s.ritualReady=now+300; reward(p,s,120,60)
      notice(p,'Seal restored: +120 XP / +60 gold. Investigate again after 5 minutes.')
     else notice(p,'You need the chapel clue, nighttime and a ready ritual (5-minute cooldown).') end
    elseif name=='Campfire' then
     if hum.Health>=hum.MaxHealth then notice(p,'Your health is already full.')
     elseif (s.herbs or 0)<2 then notice(p,'Gather 2 herbs to cook a warm meal.')
     elseif now<(s.cookReady or 0) then notice(p,'Wait 45 seconds between meals.')
     else s.herbs=s.herbs-2; s.cookReady=now+45; hum.Health=math.min(hum.MaxHealth,hum.Health+25); notice(p,'Warm meal: +25 HP. Infection remains.') end
    elseif name=='QuestBoard' then
     local q=quests[d.quest]
     if not d.accepted then d.accepted=true; notice(p,q.text)
     elseif d.count>=q.need then
      reward(p,s,q.xp,q.gold); d.completed=d.completed+1
      d.quest=d.quest%#quests+1; d.count=0; d.accepted=false
      notice(p,'Reward: '..q.xp..' XP, '..q.gold..' gold. Accept the next quest.')
     else notice(p,q.text..' '..d.count..'/'..q.need) end
    elseif name=='Merchant' then
     local cost=100*(d.lantern+1)
     if d.lantern>=3 then notice(p,'Your lantern is already fully upgraded.')
     elseif d.gold<cost then notice(p,'You need '..cost..' gold.')
     else d.gold=d.gold-cost; d.lantern=d.lantern+1; publish(p,s); notice(p,'Lantern permanently upgraded.') end
    elseif name=='Healer' then
     if hum.Health>=hum.MaxHealth then notice(p,'Your health is already full.')
     elseif d.gold<30 then notice(p,'Healing costs 30 gold.')
     else d.gold=d.gold-30; hum.Health=hum.MaxHealth; publish(p,s); notice(p,'Health restored. Infection is NOT cured.') end
    elseif name=='Trainer' then
     local index=table.find(classes,d.class) or 1
     d.class=classes[index%#classes+1]; publish(p,s)
     notice(p,'Specialization: '..classNames[d.class]..'. Hunter: +2 gathering gold; Scout: +20 expedition XP; Scholar: +2 gathering XP.')
    elseif name:match('^Expedition_') then
     s.visits[name]=true
     local count=0; for _ in pairs(s.visits) do count=count+1 end
     if count>=3 then
      if now>=(s.expeditionAt or 0) then
       reward(p,s,d.class=='Cercetas' and 200 or 180,90)
       s.expeditionAt=now+300; s.visits={}; notice(p,'Expedition complete: XP and gold awarded.')
      else notice(p,'Expedition rewards are available once every 5 minutes.') end
     else notice(p,'Expedition: '..count..'/3 landmarks visited (forest, mine, ruins).') end
    else
     local kind=name:match('^(%a+)_')
     if name=='RitualAltar' then kind='Ritual' end
     if kind~='Herb' and kind~='Ore' and kind~='Relic' and kind~='Ritual' then return end
     -- Personal node cooldowns: 50 players never compete for one resource spawn.
     if now<(s.nodes[name] or 0) then notice(p,'This resource is replenishing for you.'); return end
     s.nodes[name]=now+60
     if kind=='Herb' then s.herbs=math.min(10,(s.herbs or 0)+1) end
     reward(p,s,d.class=='Carturar' and 10 or 8,d.class=='Vanator' and 6 or 4)
     progress(p,s,kind)
    end
   end)
  end
 end
 task.spawn(function()
  while not closing do
   task.wait(2)
   -- Spread saves across the interval instead of issuing 50 writes at once.
   for p,s in pairs(profiles) do
    if not s.leaving and not s.saving and os.clock()-s.lastSave>=Config.SaveInterval then
     task.spawn(save,p,false); task.wait(.2)
    end
   end
  end
 end)
 game:BindToClose(function()
  closing=true
  for p in pairs(profiles) do task.spawn(RPG.Remove,p) end
  local deadline=os.clock()+25
  while next(profiles) and os.clock()<deadline do task.wait(.1) end
 end)
end
return RPG
