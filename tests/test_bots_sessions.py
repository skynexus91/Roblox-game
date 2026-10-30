from pathlib import Path
import unittest
from lupa import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]

class BotRulesTests(unittest.TestCase):
 def setUp(self):
  self.lua=LuaRuntime(unpack_returned_tuples=True)
  self.rules=self.lua.execute((ROOT/'src/BotRules.lua').read_text())
 def test_bot_count_rejects_remote_garbage(self):
  for bad in [None,True,'3',-1,13,2.5,float('inf'),float('nan')]:
   self.assertIsNone(self.rules.Count(bad))
  for count in [0,3,7,12]: self.assertEqual(self.rules.Count(count),count)
 def test_day_investigation_precedes_capture(self):
  self.assertEqual(self.rules.Action(False,True,'Zi',False,False,0,100),'Inspect')
  self.assertEqual(self.rules.Action(False,True,'Zi',True,False,0,100),'Capture')
  self.assertIsNone(self.rules.Action(True,False,'Zi',False,False,1,100))
 def test_night_role_restrictions_and_priorities(self):
  self.assertEqual(self.rules.Action(True,False,'Noapte',False,False,1,100),'Infect')
  self.assertEqual(self.rules.Action(True,False,'Noapte',False,False,0,50),'Feed')
  self.assertEqual(self.rules.Action(True,False,'Noapte',False,False,0,100),'Weapon')
  self.assertEqual(self.rules.Action(False,True,'Noapte',True,True,0,100),'Capture')
  self.assertIsNone(self.rules.Action(True,True,'Noapte',True,False,1,100))
  self.assertIsNone(self.rules.Action(False,True,'Rezultat',True,False,0,100))

class SessionRulesTests(unittest.TestCase):
 def setUp(self):
  self.rules=LuaRuntime(unpack_returned_tuples=True).execute((ROOT/'src/SessionRules.lua').read_text())
 def test_join_code_normalization(self):
  self.assertEqual(self.rules.Code(' ab12 cd34 '),'AB12CD34')
 def test_reject_invalid_join_codes(self):
  for value in [None,123,True,'','A'*25,'ABCDEFGH','ABC123','../../ab','AB12CD34!']:
   self.assertIsNone(self.rules.Code(value))

if __name__=='__main__': unittest.main()
