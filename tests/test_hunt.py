from pathlib import Path
import unittest
from lupa import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]

class HuntRulesTests(unittest.TestCase):
 def setUp(self):
  self.lua=LuaRuntime(unpack_returned_tuples=True)
  self.hunt=self.lua.execute((ROOT/'src/HuntRules.lua').read_text())
  self.combat=self.lua.execute((ROOT/'src/CombatRules.lua').read_text())
 def test_losing_team_receives_support_and_ties_receive_none(self):
  for humans,vampires,expected in [(0,0,'None'),(2,2,'None'),(0,1,'Priest'),(3,1,'Bat'),(1,4,'Priest')]:
   self.assertEqual(self.hunt.Support(humans,vampires),expected)
 def test_sanctuary_bounds_and_faction_protection(self):
  self.assertTrue(self.hunt.Protected(False,55,4,-150))
  self.assertFalse(self.hunt.Protected(True,55,4,-150))
  for pos in [(43,4,-150),(67,4,-150),(55,24,-150),(55,4,-133),(55,4,-167)]:
   self.assertFalse(self.hunt.Protected(False,*pos))
 def test_holy_tools_work_for_humans_only_without_friendly_fire(self):
  for key in ['Crucifix','HolyWater','WoodenStake']:
   self.assertTrue(self.combat.CanHit(key,False,True,'Zi',5,1))
   self.assertTrue(self.combat.CanHit(key,False,True,'Noapte',5,1))
   self.assertFalse(self.combat.CanHit(key,True,False,'Noapte',5,1))
   self.assertFalse(self.combat.CanHit(key,False,False,'Zi',5,1))
   self.assertFalse(self.combat.CanHit(key,False,True,'Rezultat',5,1))
 def test_stake_cannot_capture_healthy_hidden_vampire(self):
  self.assertFalse(self.hunt.StakeFinishes('Zi',100,False,False))
  self.assertTrue(self.hunt.StakeFinishes('Zi',100,True,False))
  self.assertFalse(self.hunt.StakeFinishes('Noapte',100,True,False))
  self.assertTrue(self.hunt.StakeFinishes('Noapte',25,False,False))
  self.assertTrue(self.hunt.StakeFinishes('Noapte',100,False,True))
 def test_holy_tool_range_and_cooldown_balance(self):
  for key,limit in [('Crucifix',12),('HolyWater',18),('WoodenStake',6)]:
   self.assertFalse(self.combat.CanHit(key,False,True,'Noapte',limit+.01,1))
   self.assertGreaterEqual(self.combat.Weapons[key].cooldown,2)
 def test_longer_live_cycle(self):
  config=self.lua.execute((ROOT/'src/Config.lua').read_text())
  self.assertEqual((config.Day,config.Night,config.Cycles),(480,360,3))

if __name__=='__main__': unittest.main()
