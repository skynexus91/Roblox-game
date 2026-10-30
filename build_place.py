"""Generate editable Roblox XML place using only Python's standard library."""
from pathlib import Path
import xml.etree.ElementTree as E
import math
import json
import random
random_layout=random.Random(301026)
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
def yaw_model(model,x,z,angle):
 c,s=math.cos(angle),math.sin(angle)
 for cf in model.iter('CoordinateFrame'):
  px,pz=float(cf.findtext('X'))-x,float(cf.findtext('Z'))-z
  cf.find('X').text=str(x+c*px+s*pz); cf.find('Z').text=str(z-s*px+c*pz)
  for column in range(3):
   a,b=float(cf.findtext(f'R0{column}')),float(cf.findtext(f'R2{column}'))
   cf.find(f'R0{column}').text=str(c*a+s*b); cf.find(f'R2{column}').text=str(-s*a+c*b)

def path(name,points,width=12):
 for (ax,az),(bx,bz) in zip(points,points[1:]):
  x,z=(ax+bx)/2,(az+bz)/2
  part=block(village,name,(x,.1,z),(width,.18,math.hypot(bx-ax,bz-az)+width/2),(112,103,86),880)
  yaw_model(part,x,z,math.atan2(bx-ax,bz-az))

path('MarketRoad',[(-340,0),(-180,0),(-95,8),(-35,0),(35,0),(115,-8),(210,0),(350,0)],18)
path('ChapelLane',[(0,-380),(0,-250),(-12,-155),(0,-75),(0,0)],12)
path('MonasteryLane',[(0,0),(0,80),(60,110),(60,220),(0,285),(0,330)],12)
path('MillLane',[(-95,8),(-125,-45),(-155,-115),(-180,-160)],10)
path('FarmLane',[(115,-8),(150,50),(180,110),(215,130)],10)
path('ForestTrail',[(-180,0),(-230,65),(-270,125),(-300,220),(-300,290)],9)
block(village,'MarketSquare',(0,.13,0),(68,.2,62),(116,109,96),880)
# Fountain basin, four low rim walls and central column.
block(village,'FountainBasin',(0,.5,0),(13,1,13),(68,74,77),880)
for x,z,sx,sz in [(0,-6,13,1),(0,6,13,1),(-6,0,1,13),(6,0,1,13)]:
 block(village,'FountainRim',(x,1.2,z),(sx,1.4,sz),(137,137,127),880)
block(village,'Water',(0,1.1,0),(11,.2,11),(52,119,141),1568,transparent=.35,collision=False)
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

def house(name,x,z,w=24,d=22,h=15,c=(183,166,139),facing=0):
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
  block(m,'Window',(x+dx,9,z-d/2-.56),(4,4,.1),(163,132,83),1568,transparent=.12,collision=False)
 # Two pitched roof panels meet at the ridge.
 angle=math.radians(32); roofwidth=(w/2+2)/math.cos(angle)
 for side in [-1,1]:
  block(m,'Roof',(x+side*(w/4+1),h+math.tan(angle)*(w/4+1),z),
        (roofwidth,1.3,d+4),(97,47,40),512,roll=-side*angle)
 block(m,'Chimney',(x+w/3,h+7,z+4),(3,9,3),(75,69,64),816)
 if 'CHAPEL' not in name and 'MONASTERY' not in name:
  block(m,'Table',(x,3,z+4),(7,.8,4),(69,45,31),512)
  for dx in [-2.5,2.5]: block(m,'TableLeg',(x+dx,1.5,z+4),(1,3,1),(69,45,31),512)
  block(m,'Bench',(x,1.8,z+7),(8,.7,2),(91,65,43),512)
  block(m,'BedFrame',(x-w/3,1,z+d/4),(5,1.4,8),(76,54,37),512)
  block(m,'Blanket',(x-w/3,1.9,z+d/4),(4.8,.4,6),(95,109,101),512)
  block(m,'Pillow',(x-w/3,2,z+d/4+3),(4,.6,1.6),(185,176,150),512)
 sign(m,name,(x,12,z-d/2-.8),w-2)
 yaw_model(m,x,z,facing)
 return m
for args in [('THE RAVEN INN',-47,-45,30,25,17,(174,147,117)),
 ('BLACKSMITH\'S HOUSE',-47,36,24,24,15,(154,143,130)),
 ('IVY COTTAGE',44,38,25,25,15,(155,173,140)),
 ('APOTHECARY',46,-44,28,23,16,(185,176,148)),
 ('FORESTER\'S HOUSE',-82,-68,22,20,14,(160,151,135)),
 ('OLD COTTAGE',78,73,24,22,14,(162,145,124))]:
 house(*args,facing=math.pi if args[2]<0 else 0)
# Bell tower landmark.
tower,_=item(village,'Model','Clock Tower')
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
 sign(crypt,f'CRYPT {index}',(x,12,138),26)
 block(crypt,'JailPoint',(x,.8,155),(1,1,1),transparent=1,collision=False)
# Waiting lobby is physically separate from the active village.
block(village,'LobbyFloor',(0,1,625),(45,2,38),(73,78,85),880)
for x,z,sx,sz in [(-22,625,1,38),(22,625,1,38),(0,606,45,1),(0,644,45,1)]:
 block(village,'LobbyWall',(x,12,z),(sx,22,sz),(75,80,86),transparent=.4)
block(village,'LobbyPoint',(0,2,625),(1,1,1),transparent=1,collision=False)
spawn=block(village,'LobbySpawn',(0,2,625),(5,1,5),(150,125,68),cls='SpawnLocation')
prop(spawn.find('Properties'),'bool','Neutral','true'); prop(spawn.find('Properties'),'float','Duration',0)
sign(village,'VILLAGE AFTER DUSK',(0,9,643),30)
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
for i in range(64):
 a=i*math.tau/64+random_layout.uniform(-.025,.025); radius=random_layout.uniform(420,466)
 x,z=radius*math.cos(a),radius*math.sin(a)
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
for name,x,z in [('GUILD QUARTER',-220,0),('SILVER MINE',300,0),
                 ('WATCHKEEPER RUINS',0,-300),('MONASTERY OF LIGHT',0,300)]:
 sign(village,name,(x,9,z-18),34)
for i,(x,z) in enumerate([(-265,-42),(-205,-48),(-145,-38),(-220,42),(-155,48),(135,-46),(195,-50),(245,45)]):
 house(['WEAVER\'S HOUSE','BAKER\'S HOUSE','CARPENTER\'S HOUSE'][i%3],x,z,24+(i%3)*2,23,14+i%3,
       (176-i*3,160-i*2,133+i*2),math.pi if z<0 else 0)
 path('DoorLane',[(x,z+(14 if z<0 else -14)),(x,0)],6)
 # Private kitchen gardens behind the street frontage, with a gap toward the house.
 gz=z+(-27 if z<0 else 27)
 for dx in [-13,13]: block(village,'GardenFence',(x+dx,1.7,gz),(1,3.4,22),(92,73,48),512)
 block(village,'GardenFence',(x,1.7,gz+(-11 if z<0 else 11)),(27,3.4,1),(92,73,48),512)
 for row in range(3):
  block(village,'VegetableBed',(x-8+row*8,.22,gz),(4,.4,17),(80,57,38),1280)
  for dz in [-6,0,6]: block(village,'Cabbage',(x-8+row*8,.9,gz+dz),(2,1.3,2),(91,121,60),1280,collision=False)
node('TravelGate',(0,4,615))
node('RobuxShop',(34,3,15),(225,184,76))
# Town services use the standard cross-platform ProximityPrompt interface.
for name,pos in [('QuestBoard',(-23,3,-15)),('Merchant',(23,3,-15)),
                 ('Trainer',(-23,3,15)),('Healer',(23,3,15))]: node(name,pos)
# Forest west: predictable tree grid leaves room for paths and herb nodes.
for i in range(45):
 x=-410+(i%9)*22+random_layout.uniform(-5,5); z=150+(i//9)*24+random_layout.uniform(-5,5)
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
house('MONASTERY',0,330,62,50,25,(188,180,153))
node('RitualAltar',(0,3,285),(231,207,119),(8,4,8))
node('Expedition_Forest',(-300,3,290),(101,170,112))
# A working village: market stalls by the well, trade on the road, fields outside.
for x,z in [(-19,-29),(19,-29)]:
 stall,_=item(village,'Model','MarketStall')
 for dx in [-6,6]:
  for dz in [-3,3]: block(stall,'StallPost',(x+dx,3,z+dz),(.5,6,.5),(91,64,43),512)
 block(stall,'Canvas',(x,6.2,z),(14,.4,8),(139,74,56),512)
 block(stall,'Counter',(x,2.6,z),(12,1,5),(109,79,49),512)
 for dx in [-4,0,4]: block(stall,'Produce',(x+dx,3.5,z),(2.5,1,3),(168,131,58),512)
house('OLD MILL',-180,-160,28,26,19,(172,160,131),-math.pi/2)
block(village,'MillPond',(-208,.12,-160),(22,.2,72),(64,106,119),1568,transparent=.25,collision=False)
block(village,'MillBridge',(-208,.7,-130),(30,1,8),(104,77,47),512)
for i in range(8):
 a=i*math.tau/8
 block(village,'WheelSpoke',(-196,7+5*math.cos(a),-160+5*math.sin(a)),(1,1.4,1.4),(75,53,36),512)
house('CROSSROADS FARM',215,130,30,25,16,(178,154,118))
for row in range(8):
 block(village,'FieldFurrow',(240+row*6,.12,205),(3,.22,76),(103,77,43),1280)
 for z in range(175,240,12): block(village,'Wheat',(240+row*6,1.1,z),(2.5,2,5),(180,159,82),1280,collision=False)
house('SUNWARD CHAPEL',55,-150,24,34,22,(190,182,158),math.pi)
block(village,'ChurchSanctuary',(55,11.5,-150),(22,23,32),transparent=1,collision=False)
block(village,'ChurchAltar',(55,2,-160),(7,4,3),(178,168,141),880)
block(village,'ChurchCrossStem',(55,9,-164),(.6,7,.6),(178,162,111),512)
block(village,'ChurchCrossArm',(55,10,-164),(4,.6,.6),(178,162,111),512)
for x in [48,62]:
 for z in [-154,-149,-144]: block(village,'ChurchPew',(x,1.6,z),(5,2,2),(105,77,48),512)
sign(village,'CHURCH - HUMAN SANCTUARY',(55,8,-129),23)
path('ChapelWalk',[(0,-155),(55,-155),(55,-125)],7)
path('CemeteryWalk',[(55,-125),(55,-87),(80,-87)],6)
path('InnWalk',[(-35,0),(-47,-22)],8)
path('ShrineWalk',[(0,285),(30,285),(30,265)],7)
node('ContractBoard',(-47,3,-26),(139,103,57),(5,4,1))
node('Supply_Market',(-19,3,-24),(176,135,74),(4,3,3))
node('Supply_Mill',(-160,2,-155),(176,135,74),(4,3,3))
node('Supply_Farm',(215,2,110),(176,135,74),(4,3,3))
node('DawnClue',(55,3,-127),(204,187,139),(4,4,1))
node('DawnShrine',(30,3,265),(157,166,203),(5,5,5))
node('Campfire',(-31,1,-40),(183,106,53),(4,1,4))
for name,text,pos in [('InnGuide','CONTRACTS / REST',(-47,7,-25)),
 ('FarmGuide','SUPPLIES: FARM',(215,7,111)),('MillGuide','SUPPLIES: MILL',(-159,7,-155)),
 ('ShrineGuide','DAWN SEAL',(30,8,265))]: sign(village,text,pos,19)
# Replace abstract service cubes with readable counters and silhouettes, using no NPC AI loops.
for name,part in [(n.findtext("Properties/string[@name='Name']"),n) for n in world.findall('Item')]:
 if name.startswith('Supply_') or name in ('QuestBoard','ContractBoard','Merchant','Trainer','Healer','RobuxShop'):
  part.find("Properties/token[@name='Material']").text='512'
  part.find("Properties/Color3uint8[@name='Color3uint8']").text=str(0x916B43)
 if name in ('Merchant','Trainer','Healer','RobuxShop'):
  p=part.find('Properties'); x=float(p.findtext('CoordinateFrame/X')); z=float(p.findtext('CoordinateFrame/Z'))
  vecp=p.find("Vector3[@name='size']"); vecp.find('X').text='5'; vecp.find('Y').text='2'; vecp.find('Z').text='3'
  block(village,'ServiceTorso',(x,3.7,z+2),(2,2.8,1),(72,89,100),512,collision=False)
  block(village,'ServiceHead',(x,5.7,z+2),(1.5,1.5,1.5),(197,162,125),256,collision=False)
  sign(village,{'Merchant':'BLACKSMITH','Trainer':'GUILDS','Healer':'HEALER','RobuxShop':'COSMETICS'}[name],(x,8,z+2),12)
for x,z in [(-300,0),(300,0),(0,-300),(0,270)]:
 block(village,'DistrictPlaza',(x,.15,z),(68,.3,48),(111,105,91),880)
for x,z in [(-350,0),(-200,0),(200,0),(350,0),(0,-200),(0,-350),(0,180),(0,380)]:
 block(village,'RoadLamp',(x+13,7,z),(1,14,1),(52,47,40),1088)
 lamp=block(village,'RoadLantern',(x+13,14,z),(2,2,2),(241,183,93),288,collision=False)
 light,lp=item(lamp,'PointLight','Light'); prop(lp,'float','Range',30); prop(lp,'float','Brightness',1.2)

server,_=item(xml,'ServerScriptService','ServerScriptService')
for module in ['Config','Progression','Monetization','Rules','Weapons','AdventureRules','BotRules','Bots','Sessions','SessionRules','HuntRules','CharacterDesign','WorldLife']:
 s,p=item(server,'ModuleScript',module); prop(p,'ProtectedString','Source',(ROOT/'src'/f'{module}.lua').read_text())
s,p=item(server,'Script','Game'); prop(p,'ProtectedString','Source',(ROOT/'src/Game.server.lua').read_text())
rs,_=item(xml,'ReplicatedStorage','ReplicatedStorage')
for module in ['MonetizationConfig','CombatRules','Actors']:
 s,p=item(rs,'ModuleScript',module); prop(p,'ProtectedString','Source',(ROOT/'src'/f'{module}.lua').read_text())
starter,_=item(xml,'StarterPlayer','StarterPlayer')
local,_=item(starter,'StarterPlayerScripts','StarterPlayerScripts')
for filename in ['Controls.client.lua','Shop.client.lua','Combat.client.lua','Presentation.client.lua','Wayfinding.client.lua','Multiplayer.client.lua','BloodFX.client.lua']:
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
