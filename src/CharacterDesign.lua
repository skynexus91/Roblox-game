-- Original role silhouettes; concealed vampires retain the common daytime outfit.
local Design={}
local original=setmetatable({},{__mode='k'})
function Design.Apply(char,vampire)
 local style=vampire and 'Vampire' or 'Hunter'
 if char:GetAttribute('ApusOutfitStyle')==style then return end
 local torso=char:FindFirstChild('UpperTorso') or char:FindFirstChild('Torso')
 local head=char:FindFirstChild('Head')
 if not torso or not head then return end
 local old=char:FindFirstChild('ApusOutfit'); if old then old:Destroy() end
 local outfit=Instance.new('Model'); outfit.Name='ApusOutfit'; outfit.Parent=char
 if not original[head] then original[head]=head.Color end
 head.Color=vampire and Color3.fromRGB(190,196,204) or original[head]
 local function piece(name,anchor,size,offset,color)
  local p=Instance.new('Part'); p.Name=name; p.Size=size; p.Material=Enum.Material.Fabric; p.Color=color
  p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Massless=true; p.CastShadow=false
  p.CFrame=anchor.CFrame*CFrame.new(offset); p.Parent=outfit
  local weld=Instance.new('WeldConstraint'); weld.Part0=anchor; weld.Part1=p; weld.Parent=p
  return p
 end
 local width=torso.Size.X
 piece('Tunic',torso,Vector3.new(width+.1,torso.Size.Y*.85,torso.Size.Z+.1),Vector3.zero,
  vampire and Color3.fromRGB(42,28,43) or Color3.fromRGB(49,68,82))
 piece('LeatherBelt',torso,Vector3.new(width+.18,.22,torso.Size.Z+.18),Vector3.new(0,-torso.Size.Y*.32,0),Color3.fromRGB(94,64,40))
 if vampire then
  piece('CrimsonMantle',torso,Vector3.new(width+1.1,.35,torso.Size.Z+.45),Vector3.new(0,torso.Size.Y*.4,.1),Color3.fromRGB(105,25,39))
  piece('CrimsonCape',torso,Vector3.new(width+.5,torso.Size.Y*1.5,.18),Vector3.new(0,-.55,torso.Size.Z/2+.25),Color3.fromRGB(88,20,34))
  for _,side in ipairs({-1,1}) do
   local eye=piece('RedEye',head,Vector3.new(.16,.1,.04),Vector3.new(side*.25,.08,-head.Size.Z/2-.02),Color3.fromRGB(160,32,39)); eye.Material=Enum.Material.SmoothPlastic
   piece('Fang',head,Vector3.new(.09,.14,.07),Vector3.new(side*.15,-.23,-head.Size.Z/2-.04),Color3.fromRGB(227,222,203))
  end
 else
  piece('HunterShoulder',torso,Vector3.new(.5,.3,torso.Size.Z+.25),Vector3.new(width*.4,torso.Size.Y*.42,0),Color3.fromRGB(104,79,47))
  local badge=piece('SilverInsignia',torso,Vector3.new(.28,.4,.08),Vector3.new(-width*.28,.15,-torso.Size.Z/2-.1),Color3.fromRGB(179,189,192)); badge.Material=Enum.Material.Metal
 end
 char:SetAttribute('ApusOutfitStyle',style)
end
return Design
