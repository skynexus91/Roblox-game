-- Server-owned RPG profiles, session leases, quests and contextual interactions.
local Players=game:GetService('Players')
local DSS=game:GetService('DataStoreService')
local RunService=game:GetService('RunService')
local Http=game:GetService('HttpService')
local Config=require(script.Parent.Config)
local RPG={}
local profiles={}
local session=game.JobId..':'..Http:GenerateGUID(false)
local store=DSS:GetDataStore('ApusRPG_v1')
local temporary=RunService:IsStudio() and not Config.StudioPersistence
local closing=false
local classes={'Vanator','Cercetas','Carturar'}
local quests={
 {kind='Herb',need=5,text='Culege 5 ierburi in padurea de la sud-vest',xp=100,gold=50},
 {kind='Ore',need=4,text='Aduna 4 minereuri din mina de la est',xp=140,gold=70},
 {kind='Relic',need=3,text='Gaseste 3 relicve in ruinele de la nord',xp=180,gold=90},
 {kind='Ritual',need=1,text='Activeaza altarul manastirii din sud',xp=240,gold=120},
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
 if stats then stats.Nivel.Value=RPG.Level(d.xp); stats.Aur.Value=d.gold end
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
 if closing then p:Kick('Serverul se inchide. Reconecteaza-te.'); return end
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
  if p.Parent==Players then p:Kick('Profil indisponibil sau deschis pe alt server. Reincearca in cateva minute.') end
  return
 end
 profiles[p]={data=data,saving=false,leaving=false,lastSave=os.clock(),nodes={},visits={},nextUse=0}
 if p.Parent~=Players or closing then RPG.Remove(p); return end
 local stats=Instance.new('Folder'); stats.Name='leaderstats'; stats.Parent=p
 for _,n in ipairs({'Nivel','Aur'}) do local v=Instance.new('IntValue'); v.Name=n; v.Parent=stats end
 p:SetAttribute('SaveStatus',temporary and 'TEST - progres temporar' or 'Salvare activa')
 notice(p,'Sfat: tabla de misiuni este langa fantana. Interactiune: R / L1 / atingere.')
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
  s.lastSave=os.clock(); p:SetAttribute('SaveStatus','Salvat')
 else
  p:SetAttribute('SaveStatus','Salvare esuata - reincercare automata')
  warn('Apus profile save failed for user '..p.UserId)
  if lost or os.clock()-s.lastSave>Config.LockLifetime-30 then
   s.leaving=true
   if p.Parent==Players then p:Kick('Conexiunea cu salvarea s-a intrerupt. Reconecteaza-te.') end
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
 return {ready=true,level=RPG.Level(d.xp),xp=d.xp,nextXP=Config.MaxLevel>RPG.Level(d.xp)
  and 100*RPG.Level(d.xp)^2 or d.xp,gold=d.gold,class=d.class,lantern=d.lantern,
  quest=d.accepted and (q.text..' ('..d.count..'/'..q.need..')') or 'Vorbeste cu tabla de misiuni din piata',
  completed=d.completed,save=p:GetAttribute('SaveStatus'),notice=p:GetAttribute('RPGNotice')}
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
 notice(p,d.count>=q.need and 'Obiectiv complet. Revino la tabla de misiuni pentru recompensa.'
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
   prompt.ObjectText=name; prompt.ActionText='Interactioneaza'
   if name:match('^Herb_') then prompt.ObjectText='Ierburi'; prompt.ActionText='Culege'
   elseif name:match('^Ore_') then prompt.ObjectText='Minereu'; prompt.ActionText='Extrage'
   elseif name:match('^Relic_') then prompt.ObjectText='Relicva'; prompt.ActionText='Cerceteaza'
   elseif name=='QuestBoard' then prompt.ObjectText='Misiuni'; prompt.ActionText='Accepta / Incaseaza'
   elseif name=='Merchant' then prompt.ObjectText='Fierar'; prompt.ActionText='Lanterna +1 (100/200/300 aur)'
   elseif name=='Healer' then prompt.ObjectText='Vindecator'; prompt.ActionText='Vindeca (30 aur)'
   elseif name=='Trainer' then prompt.ObjectText='Breasla'; prompt.ActionText='Schimba specializarea'
   elseif name=='TravelGate' then prompt.ObjectText='Spre sat'; prompt.ActionText='Exploreaza'
   elseif name:match('^Expedition_') then prompt.ObjectText='Expeditie'; prompt.ActionText='Exploreaza 3 repere'
   elseif name=='RitualAltar' then prompt.ObjectText='Altar'; prompt.ActionText='Activeaza ritualul' end
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
    if name=='TravelGate' then
     if p:GetAttribute('RoundActive') then return end
     char:PivotTo(CFrame.new(0,4,-20)); notice(p,'Explorare PvE. Vei participa la urmatoarea runda.'); return
    elseif name=='QuestBoard' then
     local q=quests[d.quest]
     if not d.accepted then d.accepted=true; notice(p,q.text)
     elseif d.count>=q.need then
      reward(p,s,q.xp,q.gold); d.completed=d.completed+1
      d.quest=d.quest%#quests+1; d.count=0; d.accepted=false
      notice(p,'Recompensa: '..q.xp..' XP, '..q.gold..' aur. Accepta urmatoarea misiune.')
     else notice(p,q.text..' '..d.count..'/'..q.need) end
    elseif name=='Merchant' then
     local cost=100*(d.lantern+1)
     if d.lantern>=3 then notice(p,'Lanterna este deja la nivelul maxim.')
     elseif d.gold<cost then notice(p,'Ai nevoie de '..cost..' aur.')
     else d.gold=d.gold-cost; d.lantern=d.lantern+1; publish(p,s); notice(p,'Lanterna imbunatatita permanent.') end
    elseif name=='Healer' then
     if hum.Health>=hum.MaxHealth then notice(p,'Sanatatea este deja completa.')
     elseif d.gold<30 then notice(p,'Vindecarea costa 30 aur.')
     else d.gold=d.gold-30; hum.Health=hum.MaxHealth; publish(p,s); notice(p,'Sanatate refacuta. Infectia NU este vindecata.') end
    elseif name=='Trainer' then
     local index=table.find(classes,d.class) or 1
     d.class=classes[index%#classes+1]; publish(p,s)
     notice(p,'Specializare: '..d.class..'. Vanator: aur +2, Cercetas: expeditii +20 XP, Carturar: cules +2 XP.')
    elseif name:match('^Expedition_') then
     s.visits[name]=true
     local count=0; for _ in pairs(s.visits) do count=count+1 end
     if count>=3 then
      if now>=(s.expeditionAt or 0) then
       reward(p,s,d.class=='Cercetas' and 200 or 180,90)
       s.expeditionAt=now+300; s.visits={}; notice(p,'Expeditie terminata: XP si aur primite.')
      else notice(p,'Recompensa expeditiei este disponibila o data la 5 minute.') end
     else notice(p,'Expeditie: '..count..'/3 repere vizitate (padure, mina, ruine).') end
    else
     local kind=name:match('^(%a+)_')
     if name=='RitualAltar' then kind='Ritual' end
     if kind~='Herb' and kind~='Ore' and kind~='Relic' and kind~='Ritual' then return end
     -- Personal node cooldowns: 50 players never compete for one resource spawn.
     if now<(s.nodes[name] or 0) then notice(p,'Resursa se reface pentru tine.'); return end
     s.nodes[name]=now+60
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
