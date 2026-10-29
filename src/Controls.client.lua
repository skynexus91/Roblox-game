local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local CAS=game:GetService('ContextActionService')
local RunService=game:GetService('RunService')
local player=Players.LocalPlayer
local net=RS:WaitForChild('ApusNet')
local action=net:WaitForChild('Action')
local status=net:WaitForChild('Status')
local gui=Instance.new('ScreenGui'); gui.Name='ApusHUD'; gui.ResetOnSpawn=false; gui.Parent=player:WaitForChild('PlayerGui')
local function label(name,pos,size,fontSize)
 local l=Instance.new('TextLabel'); l.Name=name; l.Position=pos; l.Size=size
 l.BackgroundColor3=Color3.fromRGB(18,19,29); l.BackgroundTransparency=0.15
 l.TextColor3=Color3.fromRGB(242,225,183); l.Font=Enum.Font.GothamMedium
 l.TextSize=fontSize; l.TextWrapped=true; l.Parent=gui
 local c=Instance.new('UICorner'); c.CornerRadius=UDim.new(0,9); c.Parent=l
 return l
end
local header=label('Phase',UDim2.fromScale(.2,.015),UDim2.fromScale(.6,.085),18)
local detail=label('Notice',UDim2.fromScale(.15,.105),UDim2.fromScale(.7,.11),15)
local targetLabel=label('Target',UDim2.fromScale(.25,.76),UDim2.fromScale(.5,.055),16)
local controls=label('Controls',UDim2.fromScale(.15,.82),UDim2.fromScale(.7,.07),13)
local data=nil
local selected=nil
local function nearest()
 local char=player.Character; local r=char and char:FindFirstChild('HumanoidRootPart')
 if not r then return nil end
 local best=nil; local distance=10
 for _,p in ipairs(Players:GetPlayers()) do if p~=player and p.Character then
  local pr=p.Character:FindFirstChild('HumanoidRootPart'); local h=p.Character:FindFirstChildOfClass('Humanoid')
  if pr and h and h.Health>0 then
   local d=(r.Position-pr.Position).Magnitude
   if d<distance then
    local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Exclude; ray.FilterDescendantsInstances={char,p.Character}
    if not workspace:Raycast(r.Position,pr.Position-r.Position,ray) then best=p; distance=d end
   end
  end
 end end
 return best
end
local function use(which)
 if not data or not data.active or data.captured or not selected then return end
 local kind
 if data.role=='Vampir' then kind=which==1 and 'Feed' or 'Infect'
 else kind=which==1 and 'Inspect' or 'Capture' end
 action:FireServer(kind,selected.UserId)
end
local function primary(_,state)
 if state==Enum.UserInputState.Begin then use(1) end
 return Enum.ContextActionResult.Sink
end
local function secondary(_,state)
 if state==Enum.UserInputState.Begin then use(2) end
 return Enum.ContextActionResult.Sink
end
local bound=false
local function bind(enabled)
 if enabled==bound then return end
 bound=enabled
 if enabled then
  CAS:BindAction('ApusPrimary',primary,true,Enum.KeyCode.E,Enum.KeyCode.ButtonX)
  CAS:BindAction('ApusSecondary',secondary,true,Enum.KeyCode.Q,Enum.KeyCode.ButtonY)
  CAS:SetPosition('ApusPrimary',UDim2.fromScale(.7,.48))
  CAS:SetPosition('ApusSecondary',UDim2.fromScale(.84,.32))
 else CAS:UnbindAction('ApusPrimary'); CAS:UnbindAction('ApusSecondary') end
end
status.OnClientEvent:Connect(function(s)
 data=s
 header.Text=string.format('%s  |  %ds  |  Ciclul %d/3  |  %s',s.phase,s.time,s.cycle,s.role)
 detail.Text=(s.captured and 'Capturat: asteapta urmatoarea runda. ') or (s.pending and 'INFECTAT: transformare la urmatorul apus. ') or ''
 detail.Text=detail.Text..(s.notice or '')
 local enabled=s.active and not s.captured and ((s.role=='Vampir' and s.phase=='Noapte') or (s.role~='Vampir' and s.phase=='Zi'))
 bind(enabled)
 if enabled then
  local a=s.role=='Vampir' and 'Hranire' or 'Investigare'
  local b=s.role=='Vampir' and 'Infectare' or 'Capturare'
  CAS:SetTitle('ApusPrimary',a); CAS:SetTitle('ApusSecondary',b)
  controls.Text='PC: E '..a..' / Q '..b..' | Controller: X / Y | Mobil: butoanele de actiune'
 else controls.Text='Misca-te cu comenzile Roblox. Actiunile se activeaza in faza potrivita.' end
end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed=elapsed+dt; if elapsed<.15 then return end; elapsed=0
 selected=nearest()
 targetLabel.Text=selected and ('Tinta apropiata: '..selected.DisplayName) or 'Apropie-te de un jucator pentru actiune'
end)

-- Personal flashlight: available on touch, keyboard, and controller.
local flashlightOn=true
local function installLight(char)
 local head=char:WaitForChild('Head',10); if not head then return end
 local old=head:FindFirstChild('PersonalLantern'); if old then old:Destroy() end
 local light=Instance.new('SpotLight'); light.Name='PersonalLantern'
 light.Face=Enum.NormalId.Front; light.Range=38; light.Angle=85
 light.Brightness=3; light.Color=Color3.fromRGB(239,224,188)
 light.Shadows=false; light.Enabled=flashlightOn; light.Parent=head
end
player.CharacterAdded:Connect(installLight)
if player.Character then task.spawn(installLight,player.Character) end
CAS:BindAction('ApusLight',function(_,state)
 if state==Enum.UserInputState.Begin then
  flashlightOn=not flashlightOn
  local head=player.Character and player.Character:FindFirstChild('Head')
  local light=head and head:FindFirstChild('PersonalLantern')
  if light then light.Enabled=flashlightOn end
 end
 return Enum.ContextActionResult.Sink
end,true,Enum.KeyCode.F,Enum.KeyCode.ButtonB)
CAS:SetTitle('ApusLight','Lanterna')
CAS:SetPosition('ApusLight',UDim2.fromScale(.6,.2))
