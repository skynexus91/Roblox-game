-- Pure combat rules. Values never come from the client.
local Combat={}
Combat.Weapons={
 SilverSword={name='Silver Sword',range=8,cooldown=1.0,damage=24,arc=.25,color={188,211,227}},
 Crossbow={name='Crossbow',range=45,cooldown=2.6,damage=16,arc=.80,color={109,75,48}},
 Claws={name='Claws',range=7,cooldown=1.2,damage=19,arc=.15,color={149,72,108}},
 Crucifix={name='Crucifix',range=12,cooldown=12,damage=0,arc=.3,day=true},
 HolyWater={name='Holy Water',range=18,cooldown=8,damage=18,arc=.5,day=true},
 WoodenStake={name='Wooden Stake',range=6,cooldown=2,damage=8,arc=.3,day=true},
}
function Combat.CanHit(key,attackerVampire,targetVampire,phase,distance,facing)
 local w=Combat.Weapons[key]
 if not w or (phase~='Noapte' and not (w.day and phase=='Zi')) or attackerVampire==targetVampire then return false end
 if (key=='Claws')~=attackerVampire then return false end
 return distance<=w.range and facing>=w.arc
end
-- Defeat disables temporarily; never resets a profile or erases infection.
function Combat.HealthAfter(health,damage) return math.max(1,health-damage) end
return Combat
