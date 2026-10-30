local Players=game:GetService('Players')
local Marketplace=game:GetService('MarketplaceService')
local RS=game:GetService('ReplicatedStorage')
local catalog=require(RS:WaitForChild('MonetizationConfig'))
local Monetization={}
local function decorate(p,char)
 if p.Character~=char then return end
 local head=char:FindFirstChild('Head')
 if not head then return end
 local aura=char:FindFirstChild('PaidMoonAura')
 if p:GetAttribute('OwnsMoonAura') and not aura then
  aura=Instance.new('Highlight'); aura.Name='PaidMoonAura'
  aura.FillTransparency=1; aura.OutlineColor=Color3.fromRGB(114,173,255)
  aura.DepthMode=Enum.HighlightDepthMode.Occluded; aura.Parent=char
 end
 if p:GetAttribute('OwnsSupporter') and not head:FindFirstChild('SupporterTitle') then
  local board=Instance.new('BillboardGui'); board.Name='SupporterTitle'
  board.Size=UDim2.fromOffset(180,28); board.StudsOffset=Vector3.new(0,3,0); board.MaxDistance=60
  local text=Instance.new('TextLabel'); text.Size=UDim2.fromScale(1,1)
  text.BackgroundTransparency=1; text.Text='VILLAGE SUPPORTER'
  text.TextColor3=Color3.fromRGB(245,211,124); text.TextSize=12; text.Parent=board; board.Parent=head
 end
end
function Monetization.Refresh(p,onlyID)
 for _,entry in ipairs(catalog) do
  if entry.id>0 and (not onlyID or entry.id==onlyID) then
   local ok,owns=pcall(function() return Marketplace:UserOwnsGamePassAsync(p.UserId,entry.id) end)
   if ok and p.Parent==Players then p:SetAttribute('Owns'..entry.key,owns) end
  end
 end
 if p.Character then decorate(p,p.Character) end
end
function Monetization.Join(p)
 p.CharacterAdded:Connect(function(char)
  char:WaitForChild('Head',10); decorate(p,char)
 end)
 task.spawn(Monetization.Refresh,p)
end
function Monetization.Init()
 local remote=Instance.new('RemoteEvent'); remote.Name='OpenRobuxShop'; remote.Parent=RS
 -- This is server -> client only. No remote grants entitlements or currency.
 local part=workspace.Village.WorldNodes:WaitForChild('RobuxShop')
 local prompt=Instance.new('ProximityPrompt'); prompt.ActionText='Browse cosmetics'
 prompt.ObjectText='Robux Shop'; prompt.KeyboardKeyCode=Enum.KeyCode.R
 prompt.GamepadKeyCode=Enum.KeyCode.ButtonL1; prompt.MaxActivationDistance=10
 prompt.HoldDuration=.3; prompt.Parent=part
 local last={}
 prompt.Triggered:Connect(function(p)
  local char=p.Character; local root=char and char:FindFirstChild('HumanoidRootPart')
  local hum=char and char:FindFirstChildOfClass('Humanoid')
  if not root or not hum or hum.Health<=0 or p:GetAttribute('Captured') or not prompt.Enabled
    or (root.Position-part.Position).Magnitude>10 or os.clock()<(last[p] or 0) then return end
  local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances={char,part}
  if workspace:Raycast(root.Position,part.Position-root.Position,params) then return end
  last[p]=os.clock()+2; remote:FireClient(p)
 end)
 Marketplace.PromptGamePassPurchaseFinished:Connect(function(p,id,purchased)
  if purchased then task.spawn(Monetization.Refresh,p,id) end
 end)
 Players.PlayerRemoving:Connect(function(p) last[p]=nil end)
end
return Monetization
