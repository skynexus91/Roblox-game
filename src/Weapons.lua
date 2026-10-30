local Weapons={}
local Combat=require(game:GetService('ReplicatedStorage'):WaitForChild('CombatRules'))
local function piece(tool,name,size,offset,color,handle)
 local part=Instance.new('Part'); part.Name=name; part.Size=size
 part.Color=color; part.Material=Enum.Material.Metal
 part.CanCollide=false; part.CanTouch=false; part.CanQuery=false; part.Massless=true
 part.CastShadow=false; part.Parent=tool
 if handle then
  part.CFrame=handle.CFrame*CFrame.new(offset)
  local weld=Instance.new('WeldConstraint'); weld.Part0=handle; weld.Part1=part; weld.Parent=part
 end
 return part
end
function Weapons.Give(p)
 local pack=p:WaitForChild('Backpack',10); if not pack then return end
 for _,old in ipairs(pack:GetChildren()) do if old:GetAttribute('ApusWeapon') then old:Destroy() end end
 -- Everyone receives the same gear. Inventory never leaks the secret role by day.
 for _,key in ipairs({'SilverSword','Crossbow','Claws','Crucifix','HolyWater','WoodenStake'}) do
  local w=Combat.Weapons[key]
  local tool=Instance.new('Tool'); tool.Name=w.name; tool.ToolTip=w.name
  tool.CanBeDropped=false; tool:SetAttribute('ApusWeapon',key)
  tool.Grip=CFrame.new(0,-.6,0)
  local handle=piece(tool,'Handle',Vector3.new(.3,1.2,.3),Vector3.zero,Color3.fromRGB(69,47,38))
  if key=='SilverSword' then
   piece(tool,'Blade',Vector3.new(.30,3,.12),Vector3.new(0,2,0),Color3.fromRGB(188,211,227),handle)
   piece(tool,'Guard',Vector3.new(1.2,.18,.25),Vector3.new(0,.65,0),Color3.fromRGB(163,131,73),handle)
  elseif key=='Crossbow' then
   piece(tool,'Stock',Vector3.new(.4,.45,2),Vector3.new(0,.4,-.6),Color3.fromRGB(109,75,48),handle)
   piece(tool,'Bow',Vector3.new(2.6,.15,.2),Vector3.new(0,.5,-1.4),Color3.fromRGB(158,165,175),handle)
  elseif key=='Crucifix' then
   piece(tool,'CrossStem',Vector3.new(.18,1.5,.18),Vector3.new(0,1,0),Color3.fromRGB(195,190,157),handle)
   piece(tool,'CrossArm',Vector3.new(.95,.18,.18),Vector3.new(0,1.35,0),Color3.fromRGB(195,190,157),handle)
  elseif key=='HolyWater' then
   local bottle=piece(tool,'HolyWaterVial',Vector3.new(.65,1.1,.65),Vector3.new(0,.85,0),Color3.fromRGB(134,198,215),handle)
   bottle.Material=Enum.Material.Glass; bottle.Transparency=.25
   piece(tool,'Stopper',Vector3.new(.4,.25,.4),Vector3.new(0,1.5,0),Color3.fromRGB(147,114,65),handle)
  elseif key=='WoodenStake' then
   local stake=piece(tool,'AshwoodStake',Vector3.new(.35,2.4,.35),Vector3.new(0,1.2,0),Color3.fromRGB(119,78,43),handle)
   stake.Material=Enum.Material.Wood
  else
   for i=-1,1 do piece(tool,'Claw',Vector3.new(.12,1.6,.12),Vector3.new(i*.3,1.1,0),Color3.fromRGB(149,72,108),handle) end
  end
  tool.Parent=pack
 end
end
return Weapons
