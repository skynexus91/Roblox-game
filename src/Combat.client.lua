local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local CAS=game:GetService('ContextActionService')
local TweenService=game:GetService('TweenService')
local player=Players.LocalPlayer
local Combat=require(RS:WaitForChild('CombatRules'))
local action=RS:WaitForChild('ApusNet'):WaitForChild('Action')
local equipped=nil
local nextAttack=0
local function attack()
 if not equipped or not equipped.Parent or player:GetAttribute('Captured') then return end
 local key=equipped:GetAttribute('ApusWeapon'); local w=Combat.Weapons[key]
 local char=player.Character; local root=char and char:FindFirstChild('HumanoidRootPart')
 if not w or not root or os.clock()<nextAttack or not player:GetAttribute('RoundActive') then return end
 nextAttack=os.clock()+w.cooldown
 local tool=equipped; local rest=tool.Grip
 local swing=TweenService:Create(tool,TweenInfo.new(.10),{Grip=rest*CFrame.Angles(math.rad(-40),0,0)})
 swing:Play()
 task.delay(.12,function()
  if tool.Parent then TweenService:Create(tool,TweenInfo.new(.15),{Grip=rest}):Play() end
 end)
 -- Aim assistance for all input types; the server independently validates every hit.
 local candidates={}
 for _,other in ipairs(Players:GetPlayers()) do
  local pr=other.Character and other.Character:FindFirstChild('HumanoidRootPart')
  if other~=player and pr and other:GetAttribute('RoundActive') and not other:GetAttribute('Captured') then
   local delta=pr.Position-root.Position; local d=delta.Magnitude
   if d>.01 and d<=w.range then
    local dot=root.CFrame.LookVector:Dot(delta.Unit)
    if dot>=w.arc then table.insert(candidates,{p=other,d=d,dot=dot}) end
   end
  end
 end
 table.sort(candidates,function(a,b) return a.dot-.01*a.d>b.dot-.01*b.d end)
 local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Exclude
 for i=1,math.min(#candidates,8) do
  local candidate=candidates[i]
  local pr=candidate.p.Character and candidate.p.Character:FindFirstChild('HumanoidRootPart')
  if pr then
   ray.FilterDescendantsInstances={char,candidate.p.Character}
   if not workspace:Raycast(root.Position,pr.Position-root.Position,ray) then
    nextAttack=os.clock()+w.cooldown; action:FireServer('Weapon',candidate.p.UserId); return
   end
  end
 end
end
local function equip(tool)
 if not tool:IsA('Tool') or not tool:GetAttribute('ApusWeapon') then return end
 equipped=tool
 CAS:BindAction('ApusAttack',function(_,state)
  if state==Enum.UserInputState.Begin then attack() end
  return Enum.ContextActionResult.Sink
 end,true,Enum.KeyCode.ButtonR2)
 CAS:SetTitle('ApusAttack','Ataca'); CAS:SetPosition('ApusAttack',UDim2.fromScale(.84,.55))
end
local function attach(char)
 equipped=nil; CAS:UnbindAction('ApusAttack')
 char.ChildAdded:Connect(equip)
 char.ChildRemoved:Connect(function(obj)
  if obj==equipped then equipped=nil; CAS:UnbindAction('ApusAttack') end
 end)
 for _,obj in ipairs(char:GetChildren()) do equip(obj) end
end
UIS.InputBegan:Connect(function(input,processed)
 if not processed and input.UserInputType==Enum.UserInputType.MouseButton1 then attack() end
end)
player.CharacterAdded:Connect(attach)
if player.Character then attach(player.Character) end
