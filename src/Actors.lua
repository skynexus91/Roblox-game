-- Clients see public actor attributes, never the server's hidden role table.
local Players=game:GetService('Players')
local Actors={}
function Actors.List()
 local result=Players:GetPlayers()
 local folder=workspace:FindFirstChild('ApusBots')
 if folder then
  for _,model in ipairs(folder:GetChildren()) do
   local id=model:GetAttribute('ActorId')
   if type(id)=='number' and id<0 then
    local actor={Character=model,UserId=id,DisplayName=model.Name}
    function actor:GetAttribute(key) return self.Character:GetAttribute(key) end
    table.insert(result,actor)
   end
  end
 end
 return result
end
return Actors
