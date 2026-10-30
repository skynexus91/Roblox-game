local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Social=game:GetService('SocialService')
local CAS=game:GetService('ContextActionService')
local p=Players.LocalPlayer
local remote=RS:WaitForChild('ApusSessions')
local gui=Instance.new('ScreenGui'); gui.Name='ApusMultiplayer'; gui.ResetOnSpawn=false; gui.DisplayOrder=20; gui.Parent=p:WaitForChild('PlayerGui')
local open=Instance.new('TextButton'); open.Name='Open'; open.Text='Multiplayer'; open.Position=UDim2.fromScale(.76,.23); open.Size=UDim2.fromScale(.22,.055); open.Parent=gui
local panel=Instance.new('ScrollingFrame'); panel.Name='Panel'; panel.CanvasSize=UDim2.new(); panel.AutomaticCanvasSize=Enum.AutomaticSize.Y; panel.ScrollBarThickness=6; panel.AnchorPoint=Vector2.new(.5,.5); panel.Position=UDim2.fromScale(.5,.5)
panel.Size=UDim2.new(.9,0,.85,0); panel.BackgroundColor3=Color3.fromRGB(29,30,38); panel.Visible=false; panel.Parent=gui
local bounds=Instance.new('UISizeConstraint'); bounds.MaxSize=Vector2.new(450,510); bounds.Parent=panel
local layout=Instance.new('UIListLayout'); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Padding=UDim.new(0,6); layout.HorizontalAlignment=Enum.HorizontalAlignment.Center; layout.Parent=panel
local order=0
local function place(obj) order=order+1; obj.LayoutOrder=order end
local padding=Instance.new('UIPadding'); padding.PaddingTop=UDim.new(0,12); padding.PaddingLeft=UDim.new(0,12); padding.PaddingRight=UDim.new(0,12); padding.Parent=panel
local function button(name,text,callback)
 local b=Instance.new('TextButton'); b.Name=name; b.Text=text; b.Size=UDim2.new(1,-24,0,30); b.TextSize=14
 b.BackgroundColor3=Color3.fromRGB(73,63,49); b.TextColor3=Color3.fromRGB(245,225,184); b.Selectable=true; b.Parent=panel
 place(b); b.Activated:Connect(callback); return b
end
local message=Instance.new('TextLabel'); message.Name='Message'; message.Size=UDim2.new(1,-24,0,52); message.BackgroundTransparency=1
message.TextColor3=Color3.fromRGB(243,222,178); message.TextWrapped=true; message.TextSize=14
message.Text='MULTIPLAYER\nHost: sesiune privata. Distribuie codul celor cu care vrei sa joci (expira in 2 ore).'; place(message); message.Parent=panel
local waiting=false
local function request(kind,value)
 if waiting then return end
 waiting=true; message.Text='Se proceseaza...'
 task.spawn(function()
  local ok,r=pcall(function() return remote:InvokeServer(kind,value) end)
  message.Text=ok and type(r)=='table' and r.message or 'Conexiune indisponibila. Reincearca.'
  waiting=false
 end)
end
button('Host','Host / creeaza sesiune',function() request('Host') end)
local code=Instance.new('TextBox'); code.Name='JoinCode'; code.PlaceholderText='Cod de 8 caractere'; code.Text=''; code.ClearTextOnFocus=false
code.Size=UDim2.new(1,-24,0,32); code.TextSize=16; place(code); code.Parent=panel
button('Join','Join / intra cu cod',function() request('Join',code.Text) end)
button('Invite','Invita in joc (trimite si codul)',function()
 task.spawn(function()
  local ok,allowed=pcall(function() return Social:CanSendGameInviteAsync(p) end)
  if ok and allowed then
   local sent=pcall(function() Social:PromptGameInvite(p) end)
   if not sent then message.Text='Invitatia nu este disponibila. Foloseste codul sesiunii.' end
  else message.Text='Invitatiile nu sunt disponibile aici. Foloseste codul sesiunii.' end
 end)
end)
local counts={0,3,7,12}
local botButton=button('Bots','Studio: boti 0 / 3 / 7 / 12',function()
 local current=workspace:GetAttribute('ApusPendingBotCount') or workspace:GetAttribute('ApusBotCount') or 0
 local index=table.find(counts,current) or 1
 request('Bots',counts[index%#counts+1])
end)
local function refreshBots()
 local count=workspace:GetAttribute('ApusBotCount') or 0
 local waitingPhase=workspace:GetAttribute('ApusPhase')=='Asteptare'
 local pending=workspace:GetAttribute('ApusPendingBotCount')
 botButton.Text='Studio: '..count..' boti | '..(pending~=nil and ('urmeaza '..pending) or (waitingPhase and 'schimba 0/3/7/12' or 'schimba dupa runda'))
end
workspace:GetAttributeChangedSignal('ApusBotCount'):Connect(refreshBots)
workspace:GetAttributeChangedSignal('ApusPhase'):Connect(refreshBots)
workspace:GetAttributeChangedSignal('ApusPendingBotCount'):Connect(refreshBots)
refreshBots()
button('Close','Inchide',function() panel.Visible=false end)
local function refreshCode()
 local value=p:GetAttribute('ApusJoinCode')
 if value then code.Text=value; message.Text='Codul sesiunii: '..value..' (2 ore)' end
end
p:GetAttributeChangedSignal('ApusJoinCode'):Connect(refreshCode)
p:GetAttributeChangedSignal('ApusSessionError'):Connect(function() message.Text=p:GetAttribute('ApusSessionError') or '' end)
local function toggle() panel.Visible=not panel.Visible; if panel.Visible then refreshCode() end end
open.Activated:Connect(toggle)
CAS:BindAction('ApusMultiplayerMenu',function(_,state) if state==Enum.UserInputState.Begin then toggle() end return Enum.ContextActionResult.Pass end,false,Enum.KeyCode.M,Enum.KeyCode.ButtonSelect)
task.spawn(function()
 local ok,info=pcall(function() return remote:InvokeServer('Info') end)
 if ok and type(info)=='table' then botButton.Visible=info.studio end
end)
