-- Client-only scalability. Never changes hit validation, visibility range of targets or rewards.
local Players=game:GetService('Players')
local Lighting=game:GetService('Lighting')
local RS=game:GetService('ReplicatedStorage')
local RunService=game:GetService('RunService')
local UIS=game:GetService('UserInputService')
local CAS=game:GetService('ContextActionService')
local player=Players.LocalPlayer
local Actors=require(RS:WaitForChild('Actors'))
local bloom=Lighting:FindFirstChild('ApusBloom')
local rays=Lighting:FindFirstChild('ApusSunRays')
local quality=UIS.TouchEnabled and 1 or 2
local mode=0 -- 0 auto, 1 low, 2 balanced, 3 high
local reduced=false
local bright=false
local lights={}
local shadowDefaults={}
local samples={}; local sampleTime=0; local total=0; local elapsed=0; local adjustmentAt=0
local nearbyLights=0
local gui=Instance.new('ScreenGui'); gui.Name='ApusSettings'; gui.ResetOnSpawn=false
 gui.Parent=player:WaitForChild('PlayerGui')
local function button(text,y)
 local b=Instance.new('TextButton'); b.Text=text; b.TextSize=12; b.TextWrapped=true
 b.Position=UDim2.fromScale(.02,y); b.Size=UDim2.fromScale(.22,.045)
 b.BackgroundColor3=Color3.fromRGB(24,29,38); b.TextColor3=Color3.fromRGB(240,223,183)
 b.Selectable=true; b.Parent=gui; return b
end
local graphics=button('Graphics: Auto',.46)
local motion=button('Reduced effects: Off',.51)
local brightness=button('Brightness: Normal',.56)
local metrics=Instance.new('TextLabel'); metrics.Size=UDim2.fromScale(.22,.04)
metrics.Position=UDim2.fromScale(.02,.61); metrics.BackgroundTransparency=1
metrics.TextColor3=Color3.fromRGB(202,211,221); metrics.TextSize=12; metrics.Parent=gui
local hit=Instance.new('TextLabel'); hit.AnchorPoint=Vector2.new(.5,.5)
hit.Position=UDim2.fromScale(.5,.5); hit.Size=UDim2.fromOffset(90,40)
hit.BackgroundTransparency=1; hit.TextColor3=Color3.fromRGB(246,217,146)
hit.Text='HIT'; hit.TextSize=20; hit.Visible=false; hit.Parent=gui
local hitExpires=0
local function track(obj)
 if obj:IsA('PointLight') or obj:IsA('SurfaceLight') then
  lights[obj]=true
 elseif obj:IsA('BasePart') and obj:GetAttribute('ApusDecoration') then
  shadowDefaults[obj]=obj.CastShadow
 end
end
for _,obj in ipairs(workspace:GetDescendants()) do track(obj) end
workspace.DescendantAdded:Connect(track)
workspace.DescendantRemoving:Connect(function(obj) lights[obj]=nil; shadowDefaults[obj]=nil end)
local function apply()
 if bloom then bloom.Enabled=not reduced and quality>=2 end
 if rays then rays.Enabled=not reduced and quality>=3 end
 Lighting.GlobalShadows=quality>=2
 Lighting.ExposureCompensation=bright and .45 or 0
 for part,original in pairs(shadowDefaults) do if part.Parent then part.CastShadow=quality>=3 and original end end
end
graphics.Activated:Connect(function()
 mode=(mode+1)%4
 if mode>0 then quality=mode end
 graphics.Text='Graphics: '..({'Auto','Low','Balanced','High'})[mode+1]
 apply()
end)
motion.Activated:Connect(function()
 reduced=not reduced; motion.Text='Reduced effects: '..(reduced and 'On' or 'Off'); apply()
 player:SetAttribute('ApusReducedEffects',reduced)
end)
brightness.Activated:Connect(function()
 bright=not bright; brightness.Text='Brightness: '..(bright and 'Boosted' or 'Normal'); apply()
end)
RS:WaitForChild('ApusNet'):WaitForChild('Feedback').OnClientEvent:Connect(function(event)
 if event.kind=='Hit' then hit.Text='HIT'; hit.Visible=true; hitExpires=os.clock()+.3
 elseif event.kind=='Hurt' then
  -- No flashing screen or camera shake; readable text only.
  hit.Text='UNDER ATTACK'; hit.Visible=true; hitExpires=os.clock()+.5
 end
end)
-- Local spectating prevents a captured player waiting on a fixed camera.
local spectating=false; local spectateIndex=0
local function spectate()
 if not player:GetAttribute('Captured') then return end
 local targets={}
 for _,p in ipairs(Actors.List()) do
  local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
  if p~=player and p:GetAttribute('RoundActive') and not p:GetAttribute('Captured') and h and p.Character:FindFirstChild('HumanoidRootPart') then table.insert(targets,h) end
 end
 if #targets==0 then return end
 spectateIndex=spectateIndex%#targets+1; spectating=true
 workspace.CurrentCamera.CameraSubject=targets[spectateIndex]
end
CAS:BindAction('ApusSpectate',function(_,state)
 if state==Enum.UserInputState.Begin then spectate() end
 return Enum.ContextActionResult.Pass
end,true,Enum.KeyCode.G,Enum.KeyCode.DPadRight)
CAS:SetTitle('ApusSpectate','Spectate'); CAS:SetPosition('ApusSpectate',UDim2.fromScale(.62,.12))
local function resetCamera()
 spectating=false
 local hum=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
 if hum then workspace.CurrentCamera.CameraSubject=hum end
end
player:GetAttributeChangedSignal('Captured'):Connect(function()
 if not player:GetAttribute('Captured') then resetCamera() end
end)
player.CharacterAdded:Connect(function(char)
 char:WaitForChild('Humanoid',10); resetCamera()
end)
apply()
RunService.RenderStepped:Connect(function(dt)
 if dt<=0 then return end
 -- One small sample ring; never send per-frame telemetry to the server.
 samples[#samples+1]=dt*1000; if #samples>180 then table.remove(samples,1) end
 total=total+dt; elapsed=elapsed+dt; sampleTime=sampleTime+1
 if hit.Visible and os.clock()>hitExpires then hit.Visible=false end
 if elapsed<1 then return end
 elapsed=0
 local fps=sampleTime/total; total=0; sampleTime=0
 if mode==0 and os.clock()>adjustmentAt then
  if fps<48 and quality>1 then quality=quality-1; adjustmentAt=os.clock()+8; apply()
  elseif fps>=58 and quality<3 then quality=quality+1; adjustmentAt=os.clock()+25; apply() end
 end
 local sorted=table.clone(samples); table.sort(sorted)
 local p95=sorted[math.max(1,math.ceil(#sorted*.95))] or 0
 metrics.Text=string.format('%.0f FPS | p95 %.1f ms | Q%d',fps,p95,quality)
 player:SetAttribute('LocalFPS',math.floor(fps)); player:SetAttribute('LocalFrameP95',p95)
 local camera=workspace.CurrentCamera
 if camera then
  local radius=({70,110,150})[quality]; nearbyLights=0
  for light in pairs(lights) do
   local part=light.Parent
   if part and part:IsA('BasePart') then
    local enabled=workspace:GetAttribute('ApusNight') and (camera.CFrame.Position-part.Position).Magnitude<=radius
    light.Enabled=enabled; light.Shadows=false
    if enabled then nearbyLights=nearbyLights+1 end
   end
  end
 end
end)
