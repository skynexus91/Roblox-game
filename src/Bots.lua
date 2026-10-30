-- Studio-only NPC participants. They call the actual round action handler.
local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local Pathfinding=game:GetService('PathfindingService')
local Rules=require(script.Parent.BotRules)
local Bots={actors={},paths={}}
local names={'Mira','Radu','Ana','Luca','Ilinca','Matei','Daria','Vlad','Sofia','Andrei','Elena','Toma'}
local function rig(index)
 local model=Instance.new('Model'); model.Name='BOT '..names[index]
 local function part(name,size,position,visible)
  local p=Instance.new('Part'); p.Name=name; p.Size=size; p.Position=position
  p.Color=name=='Head' and Color3.fromRGB(195,163,130) or Color3.fromRGB(75+index*5,89,102)
  p.CanCollide=name=='Torso'; p.CanTouch=false; p.Transparency=visible and 0 or 1; p.Parent=model
  return p
 end
 local root=part('HumanoidRootPart',Vector3.new(2,2,1),Vector3.zero,false)
 local torso=part('Torso',Vector3.new(2,2,1),Vector3.zero,true)
 local function joint(name,a,b,offset)
  local m=Instance.new('Motor6D'); m.Name=name; m.Part0=a; m.Part1=b; m.C0=CFrame.new(offset); m.Parent=a
 end
 joint('RootJoint',root,torso,Vector3.zero)
 joint('Neck',torso,part('Head',Vector3.new(2,1,1),Vector3.new(0,1.5,0),true),Vector3.new(0,1.5,0))
 for _,side in ipairs({-1,1}) do
  joint(side<0 and 'Left Shoulder' or 'Right Shoulder',torso,part(side<0 and 'Left Arm' or 'Right Arm',Vector3.new(1,2,1),Vector3.new(side*1.5,0,0),true),Vector3.new(side*1.5,0,0))
  joint(side<0 and 'Left Hip' or 'Right Hip',torso,part(side<0 and 'Left Leg' or 'Right Leg',Vector3.new(1,2,1),Vector3.new(side*.5,-2,0),true),Vector3.new(side*.5,-2,0))
 end
 local hum=Instance.new('Humanoid'); hum.DisplayName=model.Name; hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.Viewer; hum.Parent=model
 model.PrimaryPart=root; model:SetAttribute('ActorId',-index)
 return model
end
function Bots.Resolve(id) return Bots.actors[id] end
function Bots.SetCount(count,join,remove)
 if not RunService:IsStudio() or Rules.Count(count)==nil then return false end
 workspace:SetAttribute('ApusBotsConfiguring',true)
 workspace:SetAttribute('ApusBotCount',count)
 local folder=workspace:FindFirstChild('ApusBots')
 if not folder then folder=Instance.new('Folder'); folder.Name='ApusBots'; folder.Parent=workspace end
 for id,actor in pairs(Bots.actors) do
  remove(actor); actor.Character:Destroy(); actor.signal:Destroy(); Bots.actors[id]=nil; Bots.paths[id]=nil
 end
 for i=1,count do
  local model=rig(i); model.Parent=folder; model:PivotTo(CFrame.new(i*5-30,5,-20))
  model.HumanoidRootPart:SetNetworkOwner(nil)
  local signal=Instance.new('BindableEvent')
  local actor={IsBot=true,UserId=-i,Name=model.Name,DisplayName=model.Name,Character=model,Parent=Players,signal=signal,CharacterAdded=signal.Event}
  function actor:GetAttribute(k) return self.Character:GetAttribute(k) end
  function actor:SetAttribute(k,v) self.Character:SetAttribute(k,v) end
  function actor:LoadCharacterAsync()
   local old=self.Character
   self.Character=rig(i); self.Character.Parent=folder; self.Character:PivotTo(CFrame.new(0,5,-20))
   self.Character.HumanoidRootPart:SetNetworkOwner(nil)
   old:Destroy(); self.signal:Fire(self.Character)
  end
  Bots.actors[-i]=actor; join(actor)
  task.wait()
 end
 workspace:SetAttribute('ApusBotCount',count)
 workspace:SetAttribute('ApusBotsConfiguring',false)
 return true
end
function Bots.Start(states,getPhase,act,alive,root)
 if not RunService:IsStudio() then return end
 task.spawn(function()
  while true do
   task.wait(.5)
   for id,p in pairs(Bots.actors) do
    local s=states[p]
    if s and alive(p) and not workspace:GetAttribute('ApusBotsPaused') then
     local nearest,distance=nil,math.huge
     local phase=getPhase()
     for target,t in pairs(states) do
      if target~=p and alive(target) and (phase=='Zi' or s.vampire~=t.vampire) then
       local d=(root(p).Position-root(target).Position).Magnitude
       if d<distance then nearest=target; distance=d end
      end
     end
     if nearest then
      local r,goal=root(p),root(nearest).Position
      local h=p.Character.Humanoid
      local destination=goal
      if phase=='Zi' and s.vampire then
       local away=r.Position-goal
       destination=r.Position+(away.Magnitude>.1 and away.Unit or Vector3.new(1,0,0))*20
      end
      if distance>6 then
       local path=Bots.paths[id]
       if not path or os.clock()>=path.at then
        path={at=os.clock()+3}; Bots.paths[id]=path
        local route=Pathfinding:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=6})
        local ok=pcall(function() route:ComputeAsync(r.Position,destination) end)
        if ok and route.Status==Enum.PathStatus.Success then path.points=route:GetWaypoints(); path.index=2 end
       end
       local point=path.points and path.points[path.index]
       if point then
        if (r.Position-point.Position).Magnitude<4 then path.index=path.index+1 end
        h:MoveTo(point.Position); if point.Action==Enum.PathWaypointAction.Jump then h.Jump=true end
       else h:MoveTo(destination) end
      elseif (goal-r.Position).Magnitude>.1 then
       h:MoveTo(r.Position); p.Character:PivotTo(CFrame.lookAt(r.Position,Vector3.new(goal.X,r.Position.Y,goal.Z)))
      end
      local t=states[nearest]
      local kind=Rules.Action(s.vampire,t.vampire,phase,(t.reveal or 0)>os.clock(),(t.weakened or 0)>os.clock(),s.infections,h.Health)
      if kind and distance<=(kind=='Weapon' and 8 or 10) then act(p,kind,nearest.UserId) end
     end
    end
   end
  end
 end)
end
return Bots
