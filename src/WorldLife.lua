-- Bounded shared updates: ten wildlife models, at most three hostile helpers.
local Pathfinding=game:GetService('PathfindingService')
local Hunt=require(script.Parent.HuntRules)
local Life={actors={},support='None',phase='Asteptare'}
local ctx,creatures,scenery
local fauna={}
local function model(name,kind)
 local m=Instance.new('Model'); m.Name=name; m:SetAttribute('CreatureKind',kind)
 local root=Instance.new('Part'); root.Name='HumanoidRootPart'; root.Size=Vector3.new(1,1,1); root.Transparency=1
 root.Anchored=true; root.CanCollide=false; root.CanTouch=false; root.CanQuery=false; root.Parent=m; m.PrimaryPart=root
 local function part(name,size,pos,color,cls)
  local p=Instance.new(cls or 'Part'); p.Name=name; p.Size=size; p.CFrame=CFrame.new(pos); p.Color=color
  p.Material=Enum.Material.SmoothPlastic; p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.CastShadow=false; p.Parent=m
  return p
 end
 local coat=kind=='NightHound' and Color3.fromRGB(48,47,60) or Color3.fromRGB(128,92,58)
 if kind=='Bat' then
  part('Body',Vector3.new(.8,1.1,.8),Vector3.zero,Color3.fromRGB(54,30,47))
  for _,side in ipairs({-1,1}) do
   part('Wing',Vector3.new(2.3,.15,1.8),Vector3.new(side*1.35,0,0),Color3.fromRGB(89,32,48),'WedgePart')
   part('Ear',Vector3.new(.22,.6,.3),Vector3.new(side*.27,.7,0),Color3.fromRGB(61,33,48))
   part('Eye',Vector3.new(.09,.09,.05),Vector3.new(side*.18,.2,-.43),Color3.fromRGB(191,49,49))
  end
 elseif kind=='Priest' then
  part('Robe',Vector3.new(2.1,3,1.1),Vector3.new(0,-.35,0),Color3.fromRGB(224,214,181))
  part('Stole',Vector3.new(.65,2.9,1.18),Vector3.new(0,-.3,0),Color3.fromRGB(75,57,93))
  part('Head',Vector3.new(1.5,1.3,1.2),Vector3.new(0,1.8,0),Color3.fromRGB(191,159,129))
  part('Beard',Vector3.new(1,.6,.22),Vector3.new(0,1.3,-.67),Color3.fromRGB(186,184,175))
  part('Cross',Vector3.new(.15,.75,.1),Vector3.new(0,.4,-.65),Color3.fromRGB(187,158,85))
  part('CrossArm',Vector3.new(.5,.12,.1),Vector3.new(0,.55,-.65),Color3.fromRGB(187,158,85))
 elseif kind=='Chicken' then
  part('Body',Vector3.new(.9,.8,1.1),Vector3.zero,Color3.fromRGB(207,192,161))
  part('Head',Vector3.new(.5,.6,.5),Vector3.new(0,.5,-.5),Color3.fromRGB(222,211,184))
  part('Comb',Vector3.new(.15,.25,.35),Vector3.new(0,.9,-.5),Color3.fromRGB(154,48,43))
  part('Beak',Vector3.new(.3,.2,.35),Vector3.new(0,.5,-.8),Color3.fromRGB(192,146,56))
  for _,s in ipairs({-1,1}) do part('Leg',Vector3.new(.12,.6,.12),Vector3.new(s*.25,-.6,0),Color3.fromRGB(192,146,56)) end
 else
  local rabbit=kind=='Rabbit'
  local scale=rabbit and .5 or 1
  part('Body',Vector3.new(1.4,1.4,2.4)*scale,Vector3.zero,coat)
  part('Head',Vector3.new(.9,1,1.1)*scale,Vector3.new(0,.45,-1.35)*scale,coat)
  for _,s in ipairs({-1,1}) do
   part('Eye',Vector3.new(.1,.1,.12),Vector3.new(s*.38,.65,-1.86)*scale,kind=='NightHound' and Color3.fromRGB(155,48,51) or Color3.fromRGB(35,28,25))
   part('Ear',Vector3.new(.2,rabbit and 1.3 or .6,.35)*scale,Vector3.new(s*.3,1.1,-1.4)*scale,coat)
   for _,z in ipairs({-.75,.75}) do part('Leg',Vector3.new(.3,1.4,.4)*scale,Vector3.new(s*.5,-1.2,z)*scale,coat) end
  end
  part('Tail',Vector3.new(.3,.3,1)*scale,Vector3.new(0,.2,1.5)*scale,coat)
  if kind=='Deer' then
   for _,s in ipairs({-1,1}) do part('Antler',Vector3.new(.15,1.1,.15),Vector3.new(s*.3,1.6,-1.25),Color3.fromRGB(162,145,110)) end
  end
 end
 return m
end
local function clearHelpers()
 for id,a in pairs(Life.actors) do ctx.remove(a); a.Character:Destroy(); Life.actors[id]=nil end
 if Life.priest then Life.priest:Destroy(); Life.priest=nil end
end
local function spawnHostile(id,kind,pos)
 local m=model(kind=='Bat' and 'Crimson Bat' or 'Night Hound',kind)
 local hum=Instance.new('Humanoid'); hum.RequiresNeck=false; hum.BreakJointsOnDeath=false; hum.MaxHealth=kind=='Bat' and 60 or 70; hum.Health=hum.MaxHealth; hum.DisplayName=m.Name; hum.Parent=m
 m:SetAttribute('ActorId',id); m:SetAttribute('RoundActive',true); m:SetAttribute('Captured',false); m.Parent=creatures; m:PivotTo(CFrame.new(pos))
 local actor={IsBot=true,IsCreature=true,UserId=id,Name=m.Name,DisplayName=m.Name,Character=m,Parent=game.Players,kind=kind,nextHit=0}
 function actor:GetAttribute(k) return self.Character:GetAttribute(k) end
 function actor:SetAttribute(k,v) self.Character:SetAttribute(k,v) end
 Life.actors[id]=actor; ctx.register(actor)
end
function Life.Resolve(id) return Life.actors[id] end
function Life.Defeat(actor)
 if Life.actors[actor.UserId] then ctx.remove(actor); Life.actors[actor.UserId]=nil; actor.Character:Destroy() end
end
function Life.BeginRound(scores)
 Life.support=Hunt.Support(scores.humans,scores.vampires)
 workspace:SetAttribute('ApusSupport',Life.support)
end
function Life.OnPhase(phase)
 Life.phase=phase; clearHelpers()
 if phase~='Zi' and phase~='Noapte' then return end
 if Life.support=='Priest' then
  Life.priest=model('Father Alden','Priest'); Life.priest.Parent=scenery; Life.priest:PivotTo(CFrame.new(55,2.5,-148)); Life.nextHeal=0
  local b=Instance.new('BillboardGui'); b.Size=UDim2.fromOffset(160,32); b.StudsOffset=Vector3.new(0,4,0); b.MaxDistance=50; b.Parent=Life.priest.PrimaryPart
  local t=Instance.new('TextLabel'); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Text='FATHER ALDEN\nHealing nearby humans'; t.TextColor3=Color3.fromRGB(238,220,168); t.TextSize=12; t.Parent=b
 end
 if phase=='Noapte' then
  spawnHostile(-1001,'NightHound',Vector3.new(-95,2,-75))
  spawnHostile(-1002,'NightHound',Vector3.new(95,2,75))
  if Life.support=='Bat' then spawnHostile(-1003,'Bat',Vector3.new(0,12,-80)) end
 end
end
function Life.Init(context)
 ctx=context
 creatures=Instance.new('Folder'); creatures.Name='ApusCreatures'; creatures.Parent=workspace
 scenery=Instance.new('Folder'); scenery.Name='ApusWildlife'; scenery.Parent=workspace
 for i=1,10 do
  local kind=i<=3 and 'Deer' or i<=6 and 'Rabbit' or 'Chicken'
  local pos=i<=3 and Vector3.new(-340+i*20,2,210) or i<=6 and Vector3.new(185+(i-3)*9,1,190) or Vector3.new(200+(i-6)*7,1,160)
  local m=model(kind,kind); m.Parent=scenery; m:PivotTo(CFrame.new(pos)); table.insert(fauna,{model=m,home=pos,index=i})
 end
 task.spawn(function()
  local tick=0
  while true do
   task.wait(.5); tick=tick+1
   if tick%4==0 then
    for _,a in ipairs(fauna) do
     local now=os.clock()*.1+a.index
     local pos=a.home+Vector3.new(math.sin(now)*5,0,math.cos(now*.8)*5)
     a.model:PivotTo(CFrame.new(pos)*CFrame.Angles(0,now,0))
    end
   end
   if Life.priest and os.clock()>=(Life.nextHeal or 0) then
    Life.nextHeal=os.clock()+8
    for p,s in pairs(ctx.states) do if not s.vampire and not s.creature and ctx.alive(p) and (ctx.root(p).Position-Life.priest:GetPivot().Position).Magnitude<=20 then
     local h=p.Character:FindFirstChildOfClass('Humanoid'); h.Health=math.min(h.MaxHealth,h.Health+12)
    end end
   end
   for _,a in pairs(Life.actors) do
    if os.clock()>=(a.stunnedUntil or 0) then
     local r=a.Character.PrimaryPart; local nearest,distance=nil,120
     for p,s in pairs(ctx.states) do
      if not s.vampire and not s.creature and ctx.alive(p) and not ctx.protected(p) then
       local d=(ctx.root(p).Position-r.Position).Magnitude
       if d<distance then nearest=p; distance=d end
      end
     end
     if nearest then
      local target=ctx.root(nearest).Position; local goal=target+Vector3.new(0,a.kind=='Bat' and 8 or -1,0)
      if a.kind~='Bat' then
       if not a.routeAt or os.clock()>=a.routeAt then
        a.routeAt=os.clock()+3
        local path=Pathfinding:CreatePath({AgentRadius=2,AgentHeight=4,AgentCanJump=false})
        local ok=pcall(function() path:ComputeAsync(r.Position,target) end)
        a.points=ok and path.Status==Enum.PathStatus.Success and path:GetWaypoints() or nil; a.index=2
       end
       local point=a.points and a.points[a.index]
       if point then
        goal=point.Position+Vector3.new(0,2,0)
        if (goal-r.Position).Magnitude<3 then a.index=a.index+1 end
       end
      end
      local delta=goal-r.Position
      if delta.Magnitude>.3 then
       local pos=r.Position+delta.Unit*math.min(delta.Magnitude,(a.kind=='Bat' and 14 or 12)*.5)
       local facing=Vector3.new(delta.X,0,delta.Z)
       if Life.actors[a.UserId]==a and not Hunt.InSanctuary(pos.X,pos.Y,pos.Z) and facing.Magnitude>.01 then a.Character:PivotTo(CFrame.lookAt(pos,pos+facing)) end
      end
      local range=a.kind=='Bat' and 12 or 6
      if Life.actors[a.UserId]==a and Life.phase=='Noapte' and ctx.alive(nearest) and not ctx.protected(nearest) and (ctx.root(nearest).Position-r.Position).Magnitude<=range and os.clock()>=a.nextHit then
       target=ctx.root(nearest).Position
       local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Exclude; ray.FilterDescendantsInstances={a.Character,nearest.Character}
       if not workspace:Raycast(r.Position,target-r.Position,ray) then
        a.nextHit=os.clock()+(a.kind=='Bat' and 5 or 6); ctx.hurt(nearest,a.kind=='Bat' and 8 or 5)
       end
      end
     end
    end
   end
  end
 end)
end
return Life
