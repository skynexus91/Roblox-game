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
 'Expedition_Forest','Expedition_Mine','Expedition_Ruins']:
 assert required in nodes,required
for kind,count in [('Herb_',18),('Ore_',12),('Relic_',9)]:
 assert sum(n.startswith(kind) for n in nodes)==count
for required in ('LobbyPoint','LobbySpawn','Ground'):
 assert any(name(n)==required for n in village.findall('Item')),required
scripts=[n.findtext("Properties/ProtectedString[@name='Source']") for n in items
 if n.attrib['class'] in ('Script','LocalScript','ModuleScript')]
assert len(scripts)==len(sources)
assert sorted(scripts)==sorted(p.read_text() for p in sources), 'embedded sources differ'
workspace=next(n for n in items if n.attrib['class']=='Workspace')
assert workspace.findtext("Properties/bool[@name='StreamingEnabled']")=='true'
ground=next(n for n in village.findall('Item') if name(n)=='Ground')
assert ground.findtext("Properties/Vector3[@name='size']/X")=='960'
for part in items:
 if part.attrib['class'] in ('Part','SpawnLocation'):
  assert part.findtext("Properties/bool[@name='Anchored']")=='true'
  dimensions=part.find("Properties/Vector3[@name='size']")
  assert all(float(v.text)>0 for v in dimensions)
 for c in part.findall('Properties/Color3'):
  assert all(0<=float(v.text)<=1 for v in c), 'color outside normalized range'
print('PASS XML: 960x960 map, 50 unique spawns, 5 crypts, RPG nodes, streaming, embedded sources')
print('NOT RUN: Roblox import, runtime, real DataStores, purchases, multiplayer, device/load tests')

lighting=next(n for n in items if n.attrib['class']=='Lighting')
assert lighting.findtext("Properties/token[@name='LightingStyle']")=='0'
assert any(n.attrib['class']=='Atmosphere' for n in lighting.findall('Item'))
assert not any(n.attrib['class']=='ParticleEmitter' for n in items)
print('PASS presentation: Realistic lighting, atmosphere, no continuous particle emitters')
