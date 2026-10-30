-- Pure rules shared by the round controller and behavior tests.
local Rules={}
function Rules.CryptCount(players)
 return math.max(1,math.min(5,math.ceil(players/10)))
end
function Rules.InitialVampires(players)
 return Rules.CryptCount(players)
end
function Rules.VampireVictory(humans,vampires)
 return humans==0 and vampires>0
end
function Rules.JailSlot(prisoners,count)
 local used={}; local sizes={}
 for i=1,count do used[i]={}; sizes[i]=0 end
 for _,s in ipairs(prisoners) do
  if s.jail and s.jail<=count then
   sizes[s.jail]=sizes[s.jail]+1; used[s.jail][s.jailSlot or 0]=true
  end
 end
 local best=1
 for i=2,count do if sizes[i]<sizes[best] then best=i end end
 local slot=0; while used[best][slot] do slot=slot+1 end
 return best,slot
end
return Rules
