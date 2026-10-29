"""Execute actual Lua rules and RPG code against small mocks, not the Roblox engine."""
from pathlib import Path
import unittest
from lupa import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]

class RulesTests(unittest.TestCase):
 def setUp(self):
  self.lua=LuaRuntime(unpack_returned_tuples=True)
  self.rules=self.lua.execute((ROOT/'src/Rules.lua').read_text())
 def test_crypt_boundaries_and_balanced_capacity(self):
  for population in range(1,51):
   count=self.rules.CryptCount(population)
   self.assertEqual(count,(population+9)//10)
   prisoners=self.lua.table()
   slots=set(); sizes=[0]*count
   for i in range(population):
    jail,slot=self.rules.JailSlot(prisoners,count)
    self.assertNotIn((jail,slot),slots)
    slots.add((jail,slot)); sizes[jail-1]+=1
    prisoners[i+1]=self.lua.table_from({'jail':jail,'jailSlot':slot})
   self.assertLessEqual(max(sizes)-min(sizes),1)
   self.assertLessEqual(max(sizes),10)
 def test_close_crypt_relocation(self):
  prisoners=self.lua.table_from([
   self.lua.table_from({'jail':5,'jailSlot':i}) for i in range(10)])
  # Same relocation flow as the controller when population falls to ten.
  for i in range(1,11):
   others=self.lua.table_from([prisoners[j] for j in range(1,11) if i!=j])
   jail,slot=self.rules.JailSlot(others,1)
   prisoners[i].jail=jail; prisoners[i].jailSlot=slot
  self.assertEqual(len({(prisoners[i].jail,prisoners[i].jailSlot) for i in range(1,11)}),10)
  self.assertTrue(all(prisoners[i].jail==1 for i in range(1,11)))
 def test_initial_vampire_scaling(self):
  for population,expected in [(2,1),(10,1),(11,2),(20,2),(21,3),(50,5)]:
   self.assertEqual(self.rules.InitialVampires(population),expected)

class RPGTests(unittest.TestCase):
 def setUp(self):
  self.lua=LuaRuntime(unpack_returned_tuples=True)
  self.lua.execute((ROOT/'tests/mock_roblox.lua').read_text())
  self.rpg=self.lua.execute((ROOT/'src/Progression.lua').read_text())
  self.lua.globals().RPG=self.rpg
 def test_load_levels_round_rewards_and_temporary_profile(self):
  self.lua.execute('p=newPlayer(1); RPG.Join(p)')
  p=self.lua.globals().p
  self.assertTrue(self.rpg.Ready(p))
  self.assertEqual(self.rpg.Level(0),1)
  self.assertEqual(self.rpg.Level(100),2)
  self.assertEqual(self.rpg.Level(10000000),30)
  self.rpg.RoundReward(p,True)
  snap=self.rpg.Snapshot(p)
  self.assertEqual((snap.xp,snap.gold),(160,80))
  self.rpg.Remove(p)
  self.assertFalse(self.rpg.Ready(p))
 def test_live_session_lock_and_release(self):
  self.lua.execute('STUDIO=false')
  self.rpg=self.lua.execute((ROOT/'src/Progression.lua').read_text())
  self.lua.globals().RPG=self.rpg
  self.lua.execute('p=newPlayer(2); RPG.Join(p)')
  p=self.lua.globals().p
  self.assertTrue(self.rpg.Ready(p))
  self.rpg.RoundReward(p,True)
  self.rpg.Remove(p)
  saved=self.lua.globals().SAVED['u_2']
  self.assertEqual(saved.data.gold,80)
  self.assertIsNone(saved.lock)
 def test_failed_load_does_not_overwrite_profile(self):
  # Module's temporary flag is determined at require time, so reload it in live mode.
  self.lua.execute("STUDIO=false; SAVED.u_3={data={gold=999},lock={id='other-server',at=os.time()}}")
  rpg=self.lua.execute((ROOT/'src/Progression.lua').read_text())
  self.lua.globals().RPG=rpg
  self.lua.execute('p=newPlayer(3); RPG.Join(p)')
  self.assertFalse(rpg.Ready(self.lua.globals().p))
  self.assertEqual(self.lua.globals().SAVED.u_3.data.gold,999)
  self.assertIsNotNone(self.lua.globals().p.kicked)
 def test_reward_claim_and_node_cooldown_are_server_owned(self):
  self.lua.execute('p=newPlayer(4); RPG.Join(p); RPG.Init(function() return true end)')
  self.lua.execute('trigger("QuestBoard",p)')
  # 5 distinct herbs advance the objective. Reusing a node is rejected.
  for i in range(5): self.lua.execute(f'advance(2); trigger("Herb_{i}",p)')
  snap=self.rpg.Snapshot(self.lua.globals().p)
  self.assertIn('(5/5)',snap.quest)
  before=snap.gold
  self.lua.execute('advance(2); trigger("Herb_0",p)')
  self.assertEqual(self.rpg.Snapshot(self.lua.globals().p).gold,before)
  self.lua.execute('advance(2); trigger("QuestBoard",p)')
  self.assertEqual(self.rpg.Snapshot(self.lua.globals().p).gold,before+50)
  self.lua.execute('advance(2); trigger("QuestBoard",p)')
  self.assertEqual(self.rpg.Snapshot(self.lua.globals().p).gold,before+50)
 def test_captured_player_interaction_is_rejected(self):
  self.lua.execute('p=newPlayer(5); RPG.Join(p); RPG.Init(function() return false end); trigger("QuestBoard",p)')
  self.assertIn('Vorbeste',self.rpg.Snapshot(self.lua.globals().p).quest)

 def test_far_away_prompt_is_rejected(self):
  self.lua.execute('p=newPlayer(6); RPG.Join(p); RPG.Init(function() return true end)')
  self.lua.execute('p.Character.HumanoidRootPart.Position=Vector3.new(100); trigger("QuestBoard",p)')
  self.assertIn('Vorbeste',self.rpg.Snapshot(self.lua.globals().p).quest)

if __name__=='__main__': unittest.main()
