from pathlib import Path
import unittest
from lupa import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]

class CombatTests(unittest.TestCase):
 def setUp(self):
  self.lua=LuaRuntime(unpack_returned_tuples=True)
  self.rules=self.lua.execute((ROOT/'src/CombatRules.lua').read_text())
 def test_sword_range_and_arc(self):
  self.assertTrue(self.rules.CanHit('SilverSword',False,True,'Noapte',8,.25))
  self.assertFalse(self.rules.CanHit('SilverSword',False,True,'Noapte',8.01,1))
  self.assertFalse(self.rules.CanHit('SilverSword',False,True,'Noapte',5,.24))
 def test_crossbow_range_and_aim(self):
  self.assertTrue(self.rules.CanHit('Crossbow',False,True,'Noapte',45,.8))
  self.assertFalse(self.rules.CanHit('Crossbow',False,True,'Noapte',46,1))
  self.assertFalse(self.rules.CanHit('Crossbow',False,True,'Noapte',20,.79))
 def test_no_friendly_fire_and_no_daytime_combat(self):
  for weapon in ['SilverSword','Crossbow','Claws']:
   for role in [True,False]:
    self.assertFalse(self.rules.CanHit(weapon,role,role,'Noapte',1,1))
    self.assertFalse(self.rules.CanHit(weapon,role,not role,'Zi',1,1))
 def test_role_restrictions(self):
  self.assertTrue(self.rules.CanHit('Claws',True,False,'Noapte',5,1))
  self.assertFalse(self.rules.CanHit('Claws',False,True,'Noapte',5,1))
  self.assertFalse(self.rules.CanHit('SilverSword',True,False,'Noapte',5,1))
  self.assertFalse(self.rules.CanHit('Arbitrary',False,True,'Noapte',1,1))
 def test_defeat_never_resets_health_to_zero(self):
  self.assertEqual(self.rules.HealthAfter(25,24),1)
  self.assertEqual(self.rules.HealthAfter(10,24),1)
  self.assertEqual(self.rules.HealthAfter(100,24),76)

if __name__=='__main__': unittest.main()
