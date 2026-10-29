"""Generate editable Roblox XML place using only Python's standard library."""
from pathlib import Path
import xml.etree.ElementTree as E
import math
ROOT=Path(__file__).resolve().parent
xml=E.Element('roblox',{'version':'4'})
E.SubElement(xml,'External').text='null'
E.SubElement(xml,'External').text='nil'
uid=0

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
 return obj
workspace,_=item(xml,'Workspace','Workspace')
village,_=item(workspace,'Model','Village')
block(village,'Ground',(0,-1,0),(230,2,230),(60,77,55),1280)
block(village,'EastWestRoad',(0,.06,0),(220,.12,17),(94,89,81),880)
block(village,'NorthSouthRoad',(0,.08,0),(17,.15,220),(94,89,81),880)
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
 m,_=item(village,'Model',name)
 block(m,'Floor',(x,.3,z),(w,.6,d),(93,73,54),512)
 block(m,'Back',(x,h/2,z+d/2),(w,h,1),c,816)
 for dx in [-w/2,w/2]: block(m,'Side',(x+dx,h/2,z),(1,h,d),c,816)
 # South-facing doorway; front is split, not a solid box.
 for dx in [-1,1]: block(m,'Front',(x+dx*(w/4+2),h/2,z-d/2),(w/2-4,h,1),c,816)
 block(m,'DoorLintel',(x,12,z-d/2),(8,6,1),c,816)
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
# Sealed crypt, with bars facing the square. Captured players can look out.
crypt,_=item(village,'Model','Cripta')
block(crypt,'Floor',(0,.4,83),(25,.8,23),(74,77,79),880)
for x,z,sx,sz in [(-12,83,1,23),(12,83,1,23),(0,94,25,1)]:
 block(crypt,'Wall',(x,7,z),(sx,14,sz),(82,84,86),880)
block(crypt,'Roof',(0,14.5,83),(27,1,25),(60,63,65),880)
for x in range(-12,13,2): block(crypt,'Bars',(x,7,72),(0.5,14,.5),(38,40,45),1088)
sign(crypt,'CRIPTA SIGILATA',(0,12,71),22)
block(village,'JailPoint',(0,.8,83),(1,1,1),transparent=1,collision=False)
# Waiting lobby is physically separate from the active village.
block(village,'LobbyFloor',(0,1,255),(45,2,38),(73,78,85),880)
for x,z,sx,sz in [(-22,255,1,38),(22,255,1,38),(0,236,45,1),(0,274,45,1)]:
 block(village,'LobbyWall',(x,12,z),(sx,22,sz),(75,80,86),transparent=.4)
block(village,'LobbyPoint',(0,2,255),(1,1,1),transparent=1,collision=False)
spawn=block(village,'LobbySpawn',(0,2,255),(5,1,5),(150,125,68),cls='SpawnLocation')
prop(spawn.find('Properties'),'bool','Neutral','true'); prop(spawn.find('Properties'),'float','Duration',0)
sign(village,'SATUL DUPA APUS',(0,9,273),30)
spawns,_=item(village,'Folder','Spawns')
for i,(x,z) in enumerate([(-18,-18),(18,-18),(-18,18),(18,18),(-30,0),(30,0),(0,-30),(0,33)]):
 block(spawns,f'Spawn{i}',(x,.5,z),(1,1,1),transparent=1,collision=False)
# Cemetery.
for row in range(3):
 for col in range(4):
  x,z=61+col*7,-91+row*8
  block(village,'Gravestone',(x,2,z),(3,4,1),(103,106,99),880)
  block(village,'Grave',(x,.2,z+2),(3,.3,5),(65,61,50),1280)
# Trees around perimeter, lamps on roads.
for i in range(32):
 a=i*math.tau/32; x,z=103*math.cos(a),103*math.sin(a)
 block(village,'Trunk',(x,5,z),(2,10,2),(64,46,35),512)
 block(village,'Canopy',(x,13,z),(9,13,9),(32,58,43),1280)
for x,z in [(-23,-23),(23,-23),(-23,23),(23,23),(-65,0),(65,0),(0,-60),(0,57)]:
 block(village,'LampPost',(x,5,z),(.7,10,.7),(43,40,36),1088)
 lamp=block(village,'Lantern',(x,10,z),(2.2,2.5,2.2),(249,181,86),288,collision=False)
 light,p=item(lamp,'PointLight','WarmLight'); color(p,'Color',(255,196,119))
 prop(p,'float','Range',28); prop(p,'float','Brightness',1.7); prop(p,'bool','Shadows','false')
# Invisible arena perimeter prevents wandering off the playable map.
for x,z,sx,sz in [(-114,0,2,230),(114,0,2,230),(0,-114,230,2),(0,114,230,2)]:
 block(village,'ArenaBoundary',(x,35,z),(sx,70,sz),transparent=1)
server,_=item(xml,'ServerScriptService','ServerScriptService')
s,p=item(server,'Script','Game'); prop(p,'ProtectedString','Source',(ROOT/'src/Game.server.lua').read_text())
starter,_=item(xml,'StarterPlayer','StarterPlayer')
local,_=item(starter,'StarterPlayerScripts','StarterPlayerScripts')
s,p=item(local,'LocalScript','Controls'); prop(p,'ProtectedString','Source',(ROOT/'src/Controls.client.lua').read_text())
light,p=item(xml,'Lighting','Lighting'); prop(p,'float','ClockTime',14); prop(p,'float','Brightness',2)
color(p,'Ambient',(130,125,115)); prop(p,'float','FogEnd',300); prop(p,'float','FogStart',70)
color(p,'FogColor',(96,107,123))
E.indent(xml)
E.ElementTree(xml).write(ROOT/'Satul_dupa_Apus.rbxlx',encoding='utf-8',xml_declaration=True)
print(f'Generated {uid} instances; editable .rbxlx place.')
