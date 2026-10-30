local Rules={}
function Rules.Count(value)
 if type(value)~='number' or value~=value or value==math.huge or value==-math.huge then return nil end
 if value%1~=0 or value<0 or value>12 then return nil end
 return value
end
function Rules.Action(vampire,targetVampire,phase,revealed,weakened,infections,health)
 if phase=='Zi' then
  if vampire then return nil end
  return targetVampire and revealed and 'Capture' or 'Inspect'
 end
 if phase~='Noapte' or vampire==targetVampire then return nil end
 if vampire then
  if infections>0 then return 'Infect' end
  if health<65 then return 'Feed' end
  return 'Weapon'
 end
 return weakened and 'Capture' or 'Weapon'
end
return Rules
