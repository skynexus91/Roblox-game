"""Validate the distributable structure; does not execute the Roblox engine."""
from pathlib import Path
import xml.etree.ElementTree as E
from luaparser import ast
ROOT=Path(__file__).resolve().parent
for source in (ROOT/'src').glob('*.lua'):
 ast.parse(source.read_text())
 print('PASS syntax:',source.name)
xml=E.parse(ROOT/'Satul_dupa_Apus.rbxlx').getroot()
items=list(xml.iter('Item'))
refs=[n.attrib['referent'] for n in items]
assert len(refs)==len(set(refs)), 'duplicate references'
def name(n): return n.findtext("Properties/string[@name='Name']")
village=next(n for n in items if name(n)=='Village')
spawns=next(n for n in village.findall('Item') if name(n)=='Spawns')
assert len(spawns.findall('Item'))==8
for required in ('JailPoint','LobbyPoint','LobbySpawn','Ground','Cripta'):
 assert any(name(n)==required for n in village.findall('Item')),required
for cls,path in [('Script','Game.server.lua'),('LocalScript','Controls.client.lua')]:
 script=next(n for n in items if n.attrib['class']==cls)
 assert script.findtext("Properties/ProtectedString[@name='Source']")== (ROOT/'src'/path).read_text()
for part in items:
 if part.attrib['class'] in ('Part','SpawnLocation'):
  assert part.findtext("Properties/bool[@name='Anchored']")=='true'
  dimensions=part.find("Properties/Vector3[@name='size']")
  assert all(float(v.text)>0 for v in dimensions)
print('PASS XML: unique references, 8 spawns, required map objects, anchored geometry, embedded source equality')
print('NOT RUN: Roblox import, runtime, multiplayer, device tests')
