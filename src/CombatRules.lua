-- Pure combat rules. Values never come from the client.
local Combat={}
Combat.Weapons={
 SilverSword={name='Silver Sword',range=8,cooldown=1.0,damage=24,arc=.25,color={188,211,227}},
 Crossbow={name='Crossbow',range=45,cooldown=2.6,damage=16,arc=.80,color={109,75,48}},
 Claws={name='Claws',range=7,cooldown=1.2,damage=19,arc=.15,color={149,72,108}},
}
function Combat.CanHit(key,attackerVampire,targetVampire,phase,distance,facing)
 local w=Combat.Weapons[key]
 if not w or phase~='Noapte' or attackerVampire==targetVampire then return false end
 if (key=='Claws')~=attackerVampire then return false end
 return distance<=w.range and facing>=w.arc
end
-- Defeat disables temporarily; never resets a profile or erases infection.
function Combat.HealthAfter(health,damage) return math.max(1,health-damage) end
return Combat
