-- Stream-safe labels, culled by Roblox. No per-frame search or x-ray markers.
local labels={QuestBoard='QUESTS',ContractBoard='INN / CONTRACTS',
 Merchant='BLACKSMITH',Healer='HEALER',Trainer='GUILDS',RobuxShop='COSMETICS',
 Supply_Market='SUPPLIES: MARKET',Supply_Mill='SUPPLIES: MILL',Supply_Farm='SUPPLIES: FARM',
 DawnClue='CLUE: DAYTIME',DawnShrine='SEAL: NIGHTTIME',Campfire='HEARTH / COOKING',TravelGate='ENTER VILLAGE'}
local function track(part)
 if not part:IsA('BasePart') or not labels[part.Name] or not part.Parent or part.Parent.Name~='WorldNodes' then return end
 if part:FindFirstChild('ApusWayfinding') then return end
 local board=Instance.new('BillboardGui'); board.Name='ApusWayfinding'; board.Size=UDim2.fromOffset(160,28)
 board.StudsOffsetWorldSpace=Vector3.new(0,4,0); board.MaxDistance=50; board.AlwaysOnTop=false; board.Adornee=part
 local text=Instance.new('TextLabel'); text.Size=UDim2.fromScale(1,1); text.BackgroundColor3=Color3.fromRGB(27,25,24)
 text.BackgroundTransparency=.2; text.TextColor3=Color3.fromRGB(238,214,165); text.TextSize=12
 text.Font=Enum.Font.GothamMedium; text.Text=labels[part.Name]; text.Parent=board; board.Parent=part
end
for _,part in ipairs(workspace:GetDescendants()) do track(part) end
workspace.DescendantAdded:Connect(track)
