local Players=game:GetService('Players')
local Marketplace=game:GetService('MarketplaceService')
local RS=game:GetService('ReplicatedStorage')
local GuiService=game:GetService('GuiService')
local UIS=game:GetService('UserInputService')
local CAS=game:GetService('ContextActionService')
local player=Players.LocalPlayer
local catalog=require(RS:WaitForChild('MonetizationConfig'))
local gui=Instance.new('ScreenGui'); gui.Name='RobuxShop'; gui.ResetOnSpawn=false
-- Keep above the gameplay HUD and inside the device safe area.
gui.DisplayOrder=10; gui.Parent=player:WaitForChild('PlayerGui')
local frame=Instance.new('Frame'); frame.AnchorPoint=Vector2.new(.5,.5)
frame.Position=UDim2.fromScale(.5,.5); frame.Size=UDim2.fromScale(.88,.82)
frame.BackgroundColor3=Color3.fromRGB(18,19,29); frame.Visible=false; frame.Parent=gui
local cap=Instance.new('UISizeConstraint'); cap.MaxSize=Vector2.new(620,440); cap.Parent=frame
local title=Instance.new('TextLabel'); title.BackgroundTransparency=1
 title.Size=UDim2.fromScale(.96,.16); title.Position=UDim2.fromScale(.02,0)
 title.Text='Optional cosmetics | Robux\nNo combat advantages'; title.TextWrapped=true
 title.TextSize=18; title.TextColor3=Color3.fromRGB(245,222,171); title.Parent=frame
local function button(text,y)
 local b=Instance.new('TextButton'); b.Size=UDim2.fromScale(.92,.17)
 b.Position=UDim2.fromScale(.04,y); b.Text=text; b.TextWrapped=true; b.TextSize=15
 b.BackgroundColor3=Color3.fromRGB(48,49,68); b.TextColor3=Color3.new(1,1,1)
 b.Selectable=true; b.Parent=frame; return b
end
local close=button('Close',.79)
local previous=nil
local function hide()
 frame.Visible=false; CAS:UnbindAction('CloseRobuxShop')
 if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(frame) then
  GuiService.SelectedObject=previous and previous.Parent and previous or nil
 end
end
close.Activated:Connect(hide)
local buttons={}; local infos={}; local fetching={}; local lastInfo={}
local busy=false
local function refresh(index)
 local entry=catalog[index]; local b=buttons[index]
 if player:GetAttribute('Owns'..entry.key) then b.Text=entry.title..' | Owned'; return end
 if entry.id<=0 then b.Text=entry.title..' | Currently unavailable'; return end
 local info=infos[index]
 if not info then b.Text=entry.title..' | Checking price...'
 else b.Text=entry.title..' | '..(info.IsForSale and tostring(info.PriceInRobux)..' Robux' or 'Not for sale')..'\n'..entry.description end
end
for i,entry in ipairs(catalog) do
 local index=i; local product=entry
 buttons[index]=button(product.title,.18+(index-1)*.20)
 player:GetAttributeChangedSignal('Owns'..product.key):Connect(function() refresh(index) end)
 buttons[index].Activated:Connect(function()
  if busy or product.id<=0 or player:GetAttribute('Owns'..product.key) then return end
  local info=infos[index]; if not info or not info.IsForSale then return end
  busy=true
  local ok=pcall(function() Marketplace:PromptGamePassPurchase(player,product.id) end)
  if not ok then busy=false; buttons[index].Text='Purchase unavailable. Please try again.' end
 end)
 refresh(index)
end
-- The client only clears its UI debounce; ONLY the server grants ownership effects.
Marketplace.PromptGamePassPurchaseFinished:Connect(function(p)
 if p==player then busy=false end
end)
RS:WaitForChild('OpenRobuxShop').OnClientEvent:Connect(function()
 previous=GuiService.SelectedObject; frame.Visible=true
 CAS:BindActionAtPriority('CloseRobuxShop',function(_,state)
  if state==Enum.UserInputState.Begin then hide() end
  return Enum.ContextActionResult.Sink
 end,false,3000,Enum.KeyCode.ButtonB,Enum.KeyCode.Escape)
 if UIS.GamepadEnabled then GuiService.SelectedObject=close end
 for i,entry in ipairs(catalog) do
  local index=i; local product=entry
  refresh(index)
  if product.id>0 and not fetching[index] and os.clock()-(lastInfo[index] or -100)>60 then
   fetching[index]=true; lastInfo[index]=os.clock()
   task.spawn(function()
    -- Fetch on THIS client so displayed prices follow Roblox regional pricing.
    local ok,info=pcall(function() return Marketplace:GetProductInfoAsync(product.id,Enum.InfoType.GamePass) end)
    if ok then infos[index]=info end
    fetching[index]=false; refresh(index)
   end)
  end
 end
end)
