local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local CAS=game:GetService('ContextActionService')
local RunService=game:GetService('RunService')
local player=Players.LocalPlayer
local Actors=require(RS:WaitForChild('Actors'))
local net=RS:WaitForChild('ApusNet')
local action=net:WaitForChild('Action')
local status=net:WaitForChild('Status')
local gui=Instance.new('ScreenGui'); gui.Name='ApusHUD'; gui.ResetOnSpawn=false; gui.Parent=player:WaitForChild('PlayerGui')
local function label(name,pos,size,fontSize)
 local l=Instance.new('TextLabel'); l.Name=name; l.Position=pos; l.Size=size
 l.BackgroundColor3=Color3.fromRGB(18,19,29); l.BackgroundTransparency=0.15
 l.TextColor3=Color3.fromRGB(242,225,183); l.Font=Enum.Font.GothamMedium
 l.TextSize=fontSize; l.TextScaled=true; l.TextWrapped=true; l.Parent=gui
 local limit=Instance.new('UITextSizeConstraint'); limit.MinTextSize=10; limit.MaxTextSize=fontSize; limit.Parent=l
 local c=Instance.new('UICorner'); c.CornerRadius=UDim.new(0,9); c.Parent=l
 return l
end
local header=label('Phase',UDim2.fromScale(.2,.015),UDim2.fromScale(.6,.085),18)
local detail=label('Notice',UDim2.fromScale(.15,.105),UDim2.fromScale(.7,.11),15)
local targetLabel=label('Target',UDim2.fromScale(.25,.76),UDim2.fromScale(.5,.055),16)
local controls=label('Controls',UDim2.fromScale(.15,.82),UDim2.fromScale(.7,.07),13)
local statsLabel=label('RPGStats',UDim2.fromScale(.02,.23),UDim2.fromScale(.38,.07),15)
local questLabel=label('Quest',UDim2.fromScale(.02,.305),UDim2.fromScale(.38,.13),14)
local data=nil
local phaseNames={Asteptare='Waiting',Pregatire='Preparation',Zi='Day',Noapte='Night',Rezultat='Results'}
local roleNames={Vampir='Vampire',Satean='Villager',Explorator='Explorer'}
local classNames={Vanator='Hunter',Cercetas='Scout',Carturar='Scholar'}
local selected=nil
local function nearest()
 local char=player.Character; local r=char and char:FindFirstChild('HumanoidRootPart')
 if not r then return nil end
 local candidates={}
 for _,p in ipairs(Actors.List()) do
  if p~=player and p.Character and p:GetAttribute('RoundActive') and not p:GetAttribute('Captured') then
   local pr=p.Character:FindFirstChild('HumanoidRootPart'); local h=p.Character:FindFirstChildOfClass('Humanoid')
   if pr and h and h.Health>0 then
    local distance=(r.Position-pr.Position).Magnitude
    if distance<=10 then table.insert(candidates,{p=p,root=pr,d=distance}) end
   end
  end
 end
 table.sort(candidates,function(a,b) return a.d<b.d end)
 local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Exclude
 for i=1,math.min(#candidates,8) do
  local c=candidates[i]; ray.FilterDescendantsInstances={char,c.p.Character}
  if not workspace:Raycast(r.Position,c.root.Position-r.Position,ray) then return c.p end
 end
 return nil
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
 local r=s.rpg
 if r and r.ready then
  statsLabel.Text=string.format('Level %d | XP %d/%d | Gold %d | %s',r.level,r.xp,r.nextXP,r.gold,classNames[r.class] or r.class)
  questLabel.Text=r.quest..'\n'..(r.adventure or '')..'\n'..(r.notice or '')..' | '..(r.save or '')
 else statsLabel.Text='Loading profile...'; questLabel.Text='' end
 local phaseName=s.phase=='Asteptare' and ('Exploration: '..(s.night and 'Night' or 'Day')) or (phaseNames[s.phase] or s.phase)
 header.Text=string.format('%s | %ds | %d/%d | %s | Crypts: %d',phaseName,s.time,s.cycle,s.maxCycles or 3,roleNames[s.role] or s.role,s.crypts or 1)
 detail.Text=(s.captured and 'Captured: wait for the next round. ') or (s.pending and 'INFECTED: transformation at the next dusk. ') or ''
 detail.Text=detail.Text..(s.notice or '')
 if s.practice then detail.Text='PRACTICE / BOTS | '..detail.Text end
 local enabled=s.active and not s.captured and ((s.role=='Vampir' and s.phase=='Noapte') or s.role~='Vampir')
 bind(enabled)
 if enabled then
  local a=s.role=='Vampir' and 'Feed' or 'Investigate'
  local b=s.role=='Vampir' and 'Infect' or 'Capture'
  if s.role~='Vampir' and s.phase=='Noapte' then a='Investigate (daytime)'; b='Capture weakened' end
  CAS:SetTitle('ApusPrimary',a); CAS:SetTitle('ApusSecondary',b)
  controls.Text='PC: E '..a..' / Q '..b..' | Controller: X / Y | Mobile: action buttons'
 else controls.Text='Use Roblox movement controls. Abilities unlock in the appropriate phase.' end
end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed=elapsed+dt; if elapsed<.2 then return end; elapsed=0
 selected=(data and data.active and not data.captured) and nearest() or nil
 targetLabel.Text=selected and ('Nearby target: '..selected.DisplayName) or 'Approach a participant to interact'
end)

-- Personal flashlight: available on touch, keyboard, and controller.
local flashlightOn=true
local function installLight(char)
 local head=char:WaitForChild('Head',10); if not head then return end
 local old=head:FindFirstChild('PersonalLantern'); if old then old:Destroy() end
 local light=Instance.new('SpotLight'); light.Name='PersonalLantern'
 light.Face=Enum.NormalId.Front; light.Range=38+6*(player:GetAttribute('LanternTier') or 0); light.Angle=85
 light.Brightness=3; light.Color=player:GetAttribute('OwnsGoldenLantern') and Color3.fromRGB(255,184,64) or Color3.fromRGB(239,224,188)
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
CAS:SetTitle('ApusLight','Lantern')
CAS:SetPosition('ApusLight',UDim2.fromScale(.6,.2))

local function refreshLight()
 local head=player.Character and player.Character:FindFirstChild('Head')
 local light=head and head:FindFirstChild('PersonalLantern')
 if light then
  light.Range=38+6*(player:GetAttribute('LanternTier') or 0)
  light.Color=player:GetAttribute('OwnsGoldenLantern') and Color3.fromRGB(255,184,64) or Color3.fromRGB(239,224,188)
 end
end
player:GetAttributeChangedSignal('LanternTier'):Connect(refreshLight)
player:GetAttributeChangedSignal('OwnsGoldenLantern'):Connect(refreshLight)
