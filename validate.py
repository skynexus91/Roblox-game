"""Validate source syntax and generated place, without claiming Roblox runtime tests."""
from pathlib import Path
import xml.etree.ElementTree as E
from luaparser import ast
ROOT=Path(__file__).resolve().parent
sources=list((ROOT/'src').glob('*.lua'))
for source in sources:
 ast.parse(source.read_text())
 print('PASS syntax:',source.name)
xml=E.parse(ROOT/'Satul_dupa_Apus.rbxlx').getroot()
items=list(xml.iter('Item'))
refs=[n.attrib['referent'] for n in items]
assert len(refs)==len(set(refs)), 'duplicate references'
def name(n): return n.findtext("Properties/string[@name='Name']")
village=next(n for n in items if name(n)=='Village')
spawns=next(n for n in village.findall('Item') if name(n)=='Spawns')
assert len(spawns.findall('Item'))==50
positions=[E.tostring(n.find("Properties/CoordinateFrame[@name='CFrame']")) for n in spawns.findall('Item')]
assert len(set(positions))==50, 'spawn positions must be unique'
crypts=next(n for n in village.findall('Item') if name(n)=='Crypts')
assert len(crypts.findall('Item'))==5
for crypt in crypts.findall('Item'):
 assert any(name(n)=='JailPoint' for n in crypt.findall('Item'))
world=next(n for n in village.findall('Item') if name(n)=='WorldNodes')
nodes={name(n):n for n in world.findall('Item')}
for required in ['TravelGate','QuestBoard','Merchant','Trainer','Healer','RobuxShop','RitualAltar',
 'Expedition_Forest','Expedition_Mine','Expedition_Ruins','ContractBoard','Supply_Market',
 'Supply_Mill','Supply_Farm','DawnClue','DawnShrine','Campfire']:
 assert required in nodes,required
for kind,count in [('Herb_',18),('Ore_',12),('Relic_',9)]:
 assert sum(n.startswith(kind) for n in nodes)==count
for required in ('LobbyPoint','LobbySpawn','Ground'):
 assert any(name(n)==required for n in village.findall('Item')),required
sanctuary=next(n for n in village.findall('Item') if name(n)=='ChurchSanctuary')
assert sanctuary.findtext("Properties/bool[@name='CanCollide']")=='false'
assert [float(sanctuary.findtext('Properties/CoordinateFrame/'+axis)) for axis in 'XYZ']==[55,11.5,-150]
assert [float(sanctuary.findtext("Properties/Vector3[@name='size']/"+axis)) for axis in 'XYZ']==[22,23,32]
scripts=[n.findtext("Properties/ProtectedString[@name='Source']") for n in items
 if n.attrib['class'] in ('Script','LocalScript','ModuleScript')]
assert len(scripts)==len(sources)
assert sorted(scripts)==sorted(p.read_text() for p in sources), 'embedded sources differ'
workspace=next(n for n in items if n.attrib['class']=='Workspace')
assert workspace.findtext("Properties/bool[@name='StreamingEnabled']")=='true'
ground=next(n for n in village.findall('Item') if name(n)=='Ground')
assert ground.findtext("Properties/Vector3[@name='size']/X")=='960'
# Keep the monastery lane outside every crypt footprint, including the road width.
# Sample the oriented road strip at two-stud intervals, not just its centreline.
for lane in (n for n in village.findall('Item') if name(n)=='MonasteryLane'):
 p=lane.find('Properties'); cf=p.find('CoordinateFrame'); size=p.find("Vector3[@name='size']")
 x,z=float(cf.findtext('X')),float(cf.findtext('Z'))
 width,length=float(size.findtext('X')),float(size.findtext('Z'))
 for step in range(int(length/2)+1):
  local_z=-length/2+step*2
  for local_x in [-width/2,0,width/2]:
   px=x+local_x*float(cf.findtext('R00'))+local_z*float(cf.findtext('R02'))
   pz=z+local_x*float(cf.findtext('R20'))+local_z*float(cf.findtext('R22'))
   assert not any(abs(px-cx)<19 and 138<pz<172 for cx in [-240,-120,0,120,240]), 'monastery road intersects crypt'
for part in items:
 if part.attrib['class'] in ('Part','SpawnLocation'):
  assert part.findtext("Properties/bool[@name='Anchored']")=='true'
  dimensions=part.find("Properties/Vector3[@name='size']")
  assert all(float(v.text)>0 for v in dimensions)
 for c in part.findall('Properties/Color3'):
  assert all(0<=float(v.text)<=1 for v in c), 'color outside normalized range'
print('PASS XML: 960x960 map, 50 unique spawns, 5 crypts, RPG nodes, streaming, embedded sources')
print('PASS layout: monastery road strip clears all five crypts')
print('NOT RUN: Roblox import, runtime, real DataStores, purchases, multiplayer, device/load tests')

lighting=next(n for n in items if n.attrib['class']=='Lighting')
assert lighting.findtext("Properties/token[@name='LightingStyle']")=='0'
assert any(n.attrib['class']=='Atmosphere' for n in lighting.findall('Item'))
assert not any(n.attrib['class']=='ParticleEmitter' for n in items)
print('PASS presentation: Realistic lighting, atmosphere, no continuous particle emitters')
