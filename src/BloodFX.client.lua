-- Brief vampire-only red hit flecks. No stains or persistent emitters.
local Players=game:GetService('Players')
local Tween=game:GetService('TweenService')
local Debris=game:GetService('Debris')
local p=Players.LocalPlayer
local active=0
game.ReplicatedStorage:WaitForChild('ApusNet'):WaitForChild('Feedback').OnClientEvent:Connect(function(event)
 if event.kind~='VampireBlood' or typeof(event.position)~='Vector3' or p:GetAttribute('ApusReducedEffects') then return end
 local camera=workspace.CurrentCamera
 if not camera or (camera.CFrame.Position-event.position).Magnitude>100 or active>=24 then return end
 for i=1,math.min(5,24-active) do
  local fleck=Instance.new('Part'); fleck.Name='VampireHitFleck'; fleck.Anchored=true
  fleck.CanCollide=false; fleck.CanTouch=false; fleck.CanQuery=false; fleck.CastShadow=false
  fleck.Size=Vector3.new(.09,.12,.09); fleck.Color=Color3.fromRGB(148,29,40); fleck.Material=Enum.Material.SmoothPlastic
  fleck.Position=event.position; fleck.Parent=workspace; active=active+1
  local a=i*math.pi*2/5
  Tween:Create(fleck,TweenInfo.new(.35),{Position=event.position+Vector3.new(math.cos(a)*.7,-.4,math.sin(a)*.7),Transparency=1}):Play()
  Debris:AddItem(fleck,.4); task.delay(.4,function() active=math.max(0,active-1) end)
 end
end)
