-- Private-session routing. Access tokens stay server-side; clients receive short join codes.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local RunService=game:GetService('RunService')
local Teleport=game:GetService('TeleportService')
local Memory=game:GetService('MemoryStoreService')
local Http=game:GetService('HttpService')
local Rules=require(script.Parent.SessionRules)
local BotRules=require(script.Parent.BotRules)
local Sessions={}
function Sessions.Init(setBots)
 local request=Instance.new('RemoteFunction'); request.Name='ApusSessions'; request.Parent=RS
 local last,busy,created={},{},{}
 local map=not RunService:IsStudio() and game.PlaceId>0 and Memory:GetHashMap('ApusSessions_v1') or nil
 local function teleport(p,entry)
  local options=Instance.new('TeleportOptions'); options.ReservedServerAccessCode=entry.access
  options:SetTeleportData({apusCode=entry.code})
  Teleport:TeleportAsync(game.PlaceId,{p},options)
 end
 request.OnServerInvoke=function(p,kind,value)
  if type(kind)~='string' then return {ok=false,message='Cerere invalida.'} end
  if kind=='Info' then return {ok=true,studio=RunService:IsStudio(),code=p:GetAttribute('ApusJoinCode') or '',bots=workspace:GetAttribute('ApusBotCount') or 0} end
  if busy[p] or os.clock()<(last[p] or 0) then return {ok=false,message='Asteapta cateva secunde.'} end
  last[p]=os.clock()+5; busy[p]=true
  local ok,result=pcall(function()
   if kind=='Bots' then
    local count=BotRules.Count(value)
    if count==nil then return {ok=false,message='Alege intre 0 si 12 boti.'} end
    local success,message=setBots(count); return {ok=success,message=message}
   end
   if kind~='Host' and kind~='Join' then return {ok=false,message='Cerere necunoscuta.'} end
   if not map then return {ok=false,message='Host / Join necesita joc publicat si aplicatia Roblox. In Studio foloseste botii sau Server & Clients.'} end
   local entry
   if kind=='Host' then
    entry=created[p]
    if not entry or os.time()>=entry.expires then
     local access,privateId=Teleport:ReserveServerAsync(game.PlaceId)
     -- Atomic reservation prevents accidental overwriting of an existing invite code.
     for _=1,4 do
      local code=Http:GenerateGUID(false):gsub('-',''):sub(1,8):upper()
      local candidate={code=code,access=access,privateId=privateId,expires=os.time()+7200}
      local chosen=map:UpdateAsync(code,function(old) return old or candidate end,7200)
      if chosen and chosen.access==access then entry=candidate; break end
     end
     assert(entry,'Unable to allocate session code')
     created[p]=entry
    end
   else
    local code=Rules.Code(value)
    if not code then return {ok=false,message='Codul trebuie sa aiba 8 caractere (0-9 / A-F).'} end
    entry=map:GetAsync(code)
    if type(entry)~='table' or type(entry.access)~='string' or type(entry.expires)~='number' or entry.expires<=os.time() then
     return {ok=false,message='Cod invalid sau expirat (2 ore).'}
    end
   end
   p:SetAttribute('ApusJoinCode',entry.code)
   teleport(p,entry)
   return {ok=true,message='Conectare la sesiune. Cod: '..entry.code,code=entry.code}
  end)
  busy[p]=nil
  if not ok then return {ok=false,message='Conectarea a esuat. Incearca din nou; sesiunea gazduita pastreaza acelasi cod.'} end
  return result
 end
 Teleport.TeleportInitFailed:Connect(function(p)
  busy[p]=nil; p:SetAttribute('ApusSessionError','Teleport nereusit. Reincearca din meniul Multiplayer.')
 end)
 local function arriving(p)
  if not map then return end
  -- TeleportData is untrusted. Only show codes backed by this server's actual reservation.
  local data=p:GetJoinData().TeleportData
  local code=type(data)=='table' and Rules.Code(data.apusCode)
  if code and game.PrivateServerId~='' then
   local ok,entry=pcall(function() return map:GetAsync(code) end)
   if ok and type(entry)=='table' and entry.privateId==game.PrivateServerId then p:SetAttribute('ApusJoinCode',code) end
  end
 end
 Players.PlayerAdded:Connect(function(p) task.spawn(arriving,p) end)
 for _,p in ipairs(Players:GetPlayers()) do task.spawn(arriving,p) end
 Players.PlayerRemoving:Connect(function(p) last[p]=nil; busy[p]=nil; created[p]=nil end)
end
return Sessions
