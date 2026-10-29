"""Generate editable Roblox XML place using only Python's standard library."""
from pathlib import Path
import xml.etree.ElementTree as E
import math
import json
ROOT=Path(__file__).resolve().parent
xml=E.Element('roblox',{'version':'4'})
E.SubElement(xml,'External').text='null'
E.SubElement(xml,'External').text='nil'
uid=0
texture_ids=json.loads((ROOT/'assets/textures/roblox_ids.json').read_text())

def item(parent,cls,name):
 global uid
 uid+=1
 obj=E.SubElement(parent,'Item',{'class':cls,'referent':f'RBX{uid}'})
 props=E.SubElement(obj,'Properties')
 E.SubElement(props,'string',{'name':'Name'}).text=name
 return obj,props

def prop(p,t,n,v): E.SubElement(p,t,{'name':n}).text=str(v)
def vec(p,n,v):
 el=E.SubElement(p,'Vector3',{'name':n})
 for k,x in zip('XYZ',v): E.SubElement(el,k).text=str(x)
def color(p,n,c):
 el=E.SubElement(p,'Color3',{'name':n})
 for k,x in zip(('R','G','B'),c): E.SubElement(el,k).text=str(x/255)
def frame(p,pos,roll=0):
 el=E.SubElement(p,'CoordinateFrame',{'name':'CFrame'})
 c,s=math.cos(roll),math.sin(roll)
 for k,v in zip(('X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22'),(*pos,c,-s,0,s,c,0,0,0,1)):
  E.SubElement(el,k).text=str(v)
def block(parent,name,pos,size,c=(110,110,110),material=256,roll=0,transparent=0,collision=True,cls='Part'):
 obj,p=item(parent,cls,name); vec(p,'size',size); frame(p,pos,roll)
 prop(p,'Color3uint8','Color3uint8',(c[0]<<16)+(c[1]<<8)+c[2]); prop(p,'bool','Anchored','true'); prop(p,'bool','CanCollide',str(collision).lower())
 prop(p,'float','Transparency',transparent); prop(p,'token','Material',material)
 prop(p,'token','TopSurface',0); prop(p,'token','BottomSurface',0)
 prop(p,'bool','CanTouch','false')
 if not collision: prop(p,'bool','CanQuery','false')
 if name in ('Canopy','ForestCanopy'): prop(p,'token','shape',0)
 decorative=name in ('Window','Timber','Chimney','Clock','ClockHand','Sign','Gravestone','Canopy','ForestCanopy','Lantern','RoadLantern','FountainCrown')
 prop(p,'bool','CastShadow','false' if decorative else 'true')
 # Shared MaterialVariants reuse three color maps instead of adding per-face decals.
 family=None
 if name in ('Roof',): family='terracotta'
 elif material==512: family='walnut'
 elif name in ('Wall','Front','Back','Side','RuinedPillar','Tower','FountainRim'): family='limestone'
 if family and texture_ids[family]['color']>0:
  prop(p,'string','MaterialVariant','Apus_'+family)
  # MaterialVariant base must match the part's material.
  material_prop=p.find("token[@name='Material']")
  material_prop.text=str({'limestone':880,'walnut':512,'terracotta':816}[family])
  p.find("Color3uint8[@name='Color3uint8']").text=str(0xFFFFFF)
 return obj
workspace,wp=item(xml,'Workspace','Workspace')
prop(wp,'bool','StreamingEnabled','true')
prop(wp,'int','StreamingMinRadius',64)
prop(wp,'int','StreamingTargetRadius',256)
village,_=item(workspace,'Model','Village')
block(village,'Ground',(0,-1,0),(960,2,960),(60,77,55),1280)
block(village,'EastWestRoad',(0,.06,0),(920,.12,20),(94,89,81),880)
block(village,'NorthSouthRoad',(0,.08,0),(20,.15,920),(94,89,81),880)
block(village,'Piata',(0,.13,0),(58,.2,58),(116,109,96),880)
# Fountain basin, four low rim walls and central column.
block(village,'FountainBasin',(0,.5,0),(13,1,13),(68,74,77),880)
for x,z,sx,sz in [(0,-6,13,1),(0,6,13,1),(-6,0,1,13),(6,0,1,13)]:
 block(village,'FountainRim',(x,1.2,z),(sx,1.4,sz),(137,137,127),880)
block(village,'Water',(0,1.1,0),(11,.2,11),(52,119,141),288,transparent=.35,collision=False)
block(village,'FountainColumn',(0,3,0),(2,5,2),(125,125,116),880)
block(village,'FountainCrown',(0,5.5,0),(5,.8,5),(125,125,116),880)

def sign(parent,text,pos,width=15):
 anchor=block(parent,'Sign',pos,(width,3,.4),(39,30,26),512)
 surface,p=item(anchor,'SurfaceGui','Text'); prop(p,'token','Face',5); prop(p,'float','PixelsPerStud',40)
 lab,p=item(surface,'TextLabel','Label'); prop(p,'string','Text',text)
 prop(p,'bool','TextScaled','true'); prop(p,'float','BackgroundTransparency',1)
 color(p,'TextColor3',(240,216,161)); prop(p,'token','Font',4)
 size=E.SubElement(p,'UDim2',{'name':'Size'})
 for k,v in [('XS',1),('XO',0),('YS',1),('YO',0)]: E.SubElement(size,k).text=str(v)

def house(name,x,z,w=24,d=22,h=15,c=(183,166,139)):
 m,mp=item(village,'Model',name)
 prop(mp,'token','ModelStreamingMode',1)
 block(m,'Floor',(x,.3,z),(w,.6,d),(93,73,54),512)
 block(m,'Back',(x,h/2,z+d/2),(w,h,1),c,816)
 for dx in [-w/2,w/2]: block(m,'Side',(x+dx,h/2,z),(1,h,d),c,816)
 # South-facing doorway; front is split, not a solid box.
 for dx in [-1,1]: block(m,'Front',(x+dx*(w/4+2),h/2,z-d/2),(w/2-4,h,1),c,816)
 block(m,'DoorLintel',(x,12,z-d/2),(8,6,1),c,816)
 for side in [-1,1]:
  block(m,'DoorFrame',(x+side*4.2,4.5,z-d/2-.1),(.5,9,.7),(65,49,35),512)
  block(m,'WindowSill',(x+side*w/4,6.7,z-d/2-.7),(5,.45,1.2),(82,67,49),512)
 block(m,'DoorArch',(x,9,z-d/2-.2),(9,.7,1),(65,49,35),512)
 for dx in [-w/2,w/2]:
  for dz in [-d/2,d/2]: block(m,'Timber',(x+dx,h/2,z+dz),(1.2,h+1,1.2),(50,34,28),512)
 for dx in [-w/4,w/4]:
  block(m,'Window',(x+dx,9,z-d/2-.56),(4,4,.1),(225,166,79),288,collision=False)
 # Two pitched roof panels meet at the ridge.
 angle=math.radians(32); roofwidth=(w/2+2)/math.cos(angle)
 for side in [-1,1]:
  block(m,'Roof',(x+side*(w/4+1),h+math.tan(angle)*(w/4+1),z),
        (roofwidth,1.3,d+4),(97,47,40),512,roll=-side*angle)
 block(m,'Chimney',(x+w/3,h+7,z+4),(3,9,3),(75,69,64),816)
 block(m,'Table',(x,3,z+4),(7,.8,4),(69,45,31),512)
 for dx in [-2.5,2.5]: block(m,'TableLeg',(x+dx,1.5,z+4),(1,3,1),(69,45,31),512)
 sign(m,name,(x,12,z-d/2-.8),w-2)
 return m
for args in [('HANUL CORBULUI',-47,-45,30,25,17,(174,147,117)),
 ('CASA FIERARULUI',-47,36,24,24,15,(154,143,130)),
 ('CASA CU IEDERA',44,38,25,25,15,(155,173,140)),
 ('FARMACIA',46,-44,28,23,16,(185,176,148)),
 ('CASA PADURARULUI',-82,-68,22,20,14,(160,151,135)),
 ('CASA VECHE',78,73,24,22,14,(162,145,124))]: house(*args)
# Bell tower landmark.
tower,_=item(village,'Model','Turnul cu ceas')
block(tower,'Tower',(-83,15,25),(16,30,16),(126,124,113),880)
block(tower,'Top',(-83,31,25),(20,3,20),(65,51,44),512)
block(tower,'Clock',(-83,25,16.8),(8,8,.3),(232,213,165),256)
block(tower,'ClockHand',(-83,26,16.5),(.5,4,.5),(20,20,24))
# Up to five crypts. Server activates ceil(round participants / 10).
crypts,_=item(village,'Folder','Crypts')
for index,x in enumerate([-240,-120,0,120,240],1):
 crypt,cp=item(crypts,'Model',f'Crypt{index}')
 prop(cp,'token','ModelStreamingMode',1)
 block(crypt,'Floor',(x,.4,155),(36,.8,32),(74,77,79),880)
 for dx,z,sx,sz in [(-18,155,1,32),(18,155,1,32),(0,171,36,1)]:
  block(crypt,'Wall',(x+dx,7,z),(sx,14,sz),(82,84,86),880)
 block(crypt,'Roof',(x,14.5,155),(38,1,34),(60,63,65),880)
 for dx in range(-18,19,2): block(crypt,'Bars',(x+dx,7,139),(.5,14,.5),(38,40,45),1088)
 sign(crypt,f'CRIPTA {index}',(x,12,138),26)
 block(crypt,'JailPoint',(x,.8,155),(1,1,1),transparent=1,collision=False)
# Waiting lobby is physically separate from the active village.
block(village,'LobbyFloor',(0,1,625),(45,2,38),(73,78,85),880)
for x,z,sx,sz in [(-22,625,1,38),(22,625,1,38),(0,606,45,1),(0,644,45,1)]:
 block(village,'LobbyWall',(x,12,z),(sx,22,sz),(75,80,86),transparent=.4)
block(village,'LobbyPoint',(0,2,625),(1,1,1),transparent=1,collision=False)
spawn=block(village,'LobbySpawn',(0,2,625),(5,1,5),(150,125,68),cls='SpawnLocation')
prop(spawn.find('Properties'),'bool','Neutral','true'); prop(spawn.find('Properties'),'float','Duration',0)
sign(village,'SATUL DUPA APUS',(0,9,643),30)
spawns,_=item(village,'Folder','Spawns')
for i in range(50):
 # Five lanes on each side of the central east/west road; clear of buildings.
 x=-300+(i%25)*25; z=-9 if i<25 else 9
 block(spawns,f'Spawn{i}',(x,.5,z),(1,1,1),transparent=1,collision=False)
# Cemetery.
for row in range(3):
 for col in range(4):
  x,z=61+col*7,-91+row*8
  block(village,'Gravestone',(x,2,z),(3,4,1),(103,106,99),880)
  block(village,'Grave',(x,.2,z+2),(3,.3,5),(65,61,50),1280)
# Trees around perimeter, lamps on roads.
for i in range(96):
 a=i*math.tau/96; x,z=455*math.cos(a),455*math.sin(a)
 block(village,'Trunk',(x,5,z),(2,10,2),(64,46,35),512)
 block(village,'Canopy',(x,13,z),(9,13,9),(32,58,43),1280,collision=False)
for x,z in [(-23,-23),(23,-23),(-23,23),(23,23),(-65,0),(65,0),(0,-60),(0,57)]:
 block(village,'LampPost',(x,5,z),(.7,10,.7),(43,40,36),1088)
 lamp=block(village,'Lantern',(x,10,z),(2.2,2.5,2.2),(249,181,86),288,collision=False)
 light,p=item(lamp,'PointLight','WarmLight'); color(p,'Color',(255,196,119))
 prop(p,'float','Range',28); prop(p,'float','Brightness',1.7); prop(p,'bool','Shadows','false')
# Invisible arena perimeter prevents wandering off the playable map.
for x,z,sx,sz in [(-479,0,2,960),(479,0,2,960),(0,-479,960,2),(0,479,960,2)]:
 block(village,'ArenaBoundary',(x,35,z),(sx,70,sz),transparent=1)
# Districts, outdoor quest nodes and repeatable expeditions.
world,_=item(village,'Folder','WorldNodes')
def node(name,pos,c=(184,148,68),size=(3,3,3)):
 return block(world,name,pos,size,c,880)
for name,x,z in [('CARTIERUL BRESLELOR',-220,0),('MINA ARGINTIE',300,0),
                 ('RUINELE STRAJERILOR',0,-300),('MANASTIREA LUMINII',0,300)]:
 sign(village,name,(x,9,z-18),34)
for x in [-300,-220,-140,140,220,300]:
 for z in [-58,58]:
  house('CASA BRESLEI',x,z,28,26,16)
node('TravelGate',(0,4,615))
node('RobuxShop',(34,3,15),(225,184,76))
# Town services use the standard cross-platform ProximityPrompt interface.
for name,pos in [('QuestBoard',(-23,3,-15)),('Merchant',(23,3,-15)),
                 ('Trainer',(-23,3,15)),('Healer',(23,3,15))]: node(name,pos)
# Forest west: predictable tree grid leaves room for paths and herb nodes.
for i in range(45):
 x=-410+(i%9)*22; z=150+(i//9)*24
 block(village,'ForestTrunk',(x,5,z),(2,10,2),(64,46,35),512)
 block(village,'ForestCanopy',(x,15,z),(12,16,12),(32,58,43),1280,collision=False)
for i in range(18): node(f'Herb_{i}',(-400+(i%6)*32,1,135+(i//6)*45),(94,176,108),(3,2,3))
# Mine yard: open tunnel gate, ore outcrops and an expedition obelisk.
for x,z in [(270,-30),(330,-30),(270,30),(330,30)]:
 block(village,'MineRock',(x,9,z),(14,18,14),(75,81,92),880)
block(village,'MineGate',(300,18,-30),(70,4,16),(60,51,41),512)
for i in range(12): node(f'Ore_{i}',(275+(i%4)*17,2,50+(i//4)*20),(161,176,206),(5,4,5))
node('Expedition_Mine',(300,3,100),(123,167,214))
# Ruined courtyard with open perimeter and walkable central area.
for x in [-45,45]:
 for z in [-340,-300,-260]: block(village,'RuinedPillar',(x,9,z),(5,18,5),(101,103,100),880)
for i in range(9): node(f'Relic_{i}',(-30+(i%3)*30,2,-330+(i//3)*30),(180,133,213))
node('Expedition_Ruins',(0,3,-365),(160,108,184))
# Monastery and exterior ritual altar, reachable without entering a building.
house('MANASTIRE',0,330,62,50,25,(188,180,153))
node('RitualAltar',(0,3,285),(231,207,119),(8,4,8))
node('Expedition_Forest',(-300,3,290),(101,170,112))
for x,z in [(-300,0),(300,0),(0,-300),(0,270)]:
 block(village,'DistrictPlaza',(x,.15,z),(68,.3,48),(111,105,91),880)
for x,z in [(-350,0),(-200,0),(200,0),(350,0),(0,-200),(0,-350),(0,180),(0,380)]:
 block(village,'RoadLamp',(x+13,7,z),(1,14,1),(52,47,40),1088)
 lamp=block(village,'RoadLantern',(x+13,14,z),(2,2,2),(241,183,93),288,collision=False)
 light,lp=item(lamp,'PointLight','Light'); prop(lp,'float','Range',30); prop(lp,'float','Brightness',1.2)

server,_=item(xml,'ServerScriptService','ServerScriptService')
for module in ['Config','Progression','Monetization','Rules','Weapons']:
 s,p=item(server,'ModuleScript',module); prop(p,'ProtectedString','Source',(ROOT/'src'/f'{module}.lua').read_text())
s,p=item(server,'Script','Game'); prop(p,'ProtectedString','Source',(ROOT/'src/Game.server.lua').read_text())
rs,_=item(xml,'ReplicatedStorage','ReplicatedStorage')
for module in ['MonetizationConfig','CombatRules']:
 s,p=item(rs,'ModuleScript',module); prop(p,'ProtectedString','Source',(ROOT/'src'/f'{module}.lua').read_text())
starter,_=item(xml,'StarterPlayer','StarterPlayer')
local,_=item(starter,'StarterPlayerScripts','StarterPlayerScripts')
for filename in ['Controls.client.lua','Shop.client.lua','Combat.client.lua','Presentation.client.lua']:
 s,p=item(local,'LocalScript',filename.split('.')[0]); prop(p,'ProtectedString','Source',(ROOT/'src'/filename).read_text())
light,p=item(xml,'Lighting','Lighting'); prop(p,'float','ClockTime',14); prop(p,'float','Brightness',2)
color(p,'Ambient',(130,125,115)); prop(p,'float','FogEnd',500); prop(p,'float','FogStart',70)
color(p,'FogColor',(96,107,123))
prop(p,'token','LightingStyle',0)
prop(p,'bool','PrioritizeLightingQuality','false')
prop(p,'float','ShadowSoftness',.35)
color(p,'OutdoorAmbient',(145,151,163))
prop(p,'float','EnvironmentDiffuseScale',.65); prop(p,'float','EnvironmentSpecularScale',.45)
atmosphere,ap=item(light,'Atmosphere','ApusAtmosphere')
prop(ap,'float','Density',.22); prop(ap,'float','Offset',.1); prop(ap,'float','Haze',1.2)
color(ap,'Color',(193,204,218)); color(ap,'Decay',(112,119,143))
bloom,bp=item(light,'BloomEffect','ApusBloom')
prop(bp,'float','Intensity',.12); prop(bp,'float','Size',18); prop(bp,'float','Threshold',1.4)
cc,cp=item(light,'ColorCorrectionEffect','ApusGrade')
prop(cp,'float','Contrast',.08); prop(cp,'float','Saturation',-.08); color(cp,'TintColor',(255,245,231))
sun,sp=item(light,'SunRaysEffect','ApusSunRays'); prop(sp,'float','Intensity',.025); prop(sp,'float','Spread',.75)
prop(sp,'bool','Enabled','false')
materials,mp=item(xml,'MaterialService','MaterialService'); prop(mp,'bool','Use2022Materials','true')
for family,base in [('limestone',880),('walnut',512),('terracotta',816)]:
 data=texture_ids[family]
 if data['color']>0:
  v,vp=item(materials,'MaterialVariant','Apus_'+family)
  prop(vp,'token','BaseMaterial',base); prop(vp,'float','StudsPerTile',data['studsPerTile'])
  content=E.SubElement(vp,'Content',{'name':'ColorMap'})
  E.SubElement(content,'url').text='rbxassetid://'+str(data['color'])
E.indent(xml)
E.ElementTree(xml).write(ROOT/'Satul_dupa_Apus.rbxlx',encoding='utf-8',xml_declaration=True)
print(f'Generated {uid} instances; editable .rbxlx place.')
