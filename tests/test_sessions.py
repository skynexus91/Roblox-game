from pathlib import Path
import unittest
from lupa import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]

class SessionRoutingTests(unittest.TestCase):
 def setUp(self):
  self.lua=LuaRuntime(unpack_returned_tuples=True)
  self.lua.execute((ROOT/'tests/mock_sessions.lua').read_text())
  for name in ['SessionRules','BotRules']:
   self.lua.globals().script.Parent[name]=self.lua.execute((ROOT/'src'/f'{name}.lua').read_text())
  self.sessions=self.lua.execute((ROOT/'src/Sessions.lua').read_text())
  self.lua.globals().SESSIONS=self.sessions
  self.lua.execute('SESSIONS.Init(function(n) return true,"bots changed" end); p=player(1)')
 def invoke(self,kind,value=None):
  g=self.lua.globals()
  return g.REMOTE.OnServerInvoke(g.p,kind,value)
 def test_host_keeps_access_secret_and_reuses_reservation(self):
  r=self.invoke('Host')
  self.assertTrue(r.ok)
  self.assertEqual(r.code,'AB12CD34')
  self.assertIsNone(r.access)
  self.assertEqual(self.lua.globals().LAST_OPTIONS.ReservedServerAccessCode,'secret-access')
  self.assertEqual(self.lua.globals().MAP.AB12CD34.privateId,'private-1')
  self.lua.execute('NOW=NOW+6')
  self.invoke('Host')
  self.assertEqual(self.lua.globals().RESERVATIONS,1)
 def test_join_resolves_only_server_stored_code(self):
  self.invoke('Host'); self.lua.execute('p=player(2); NOW=NOW+6')
  self.assertTrue(self.invoke('Join',' ab12cd34 ').ok)
  self.assertEqual(self.lua.globals().LAST_PLACE,123)
 def test_expired_code_and_rate_limit_reject_teleport(self):
  self.invoke('Host'); self.lua.execute('p=player(2); NOW=NOW+7201')
  self.assertFalse(self.invoke('Join','AB12CD34').ok)
  self.assertFalse(self.invoke('Host').ok)
  self.assertEqual(self.lua.globals().TELEPORTS,1)
 def test_teleport_failure_can_retry_same_host_code(self):
  self.lua.execute('FAIL_TELEPORT=true')
  self.assertFalse(self.invoke('Host').ok)
  self.lua.execute('FAIL_TELEPORT=false; NOW=NOW+6')
  self.assertTrue(self.invoke('Host').ok)
  self.assertEqual(self.lua.globals().RESERVATIONS,1)
 def test_studio_explains_unavailable_teleport(self):
  self.lua.execute('STUDIO=true; SESSIONS.Init(function() return true,"bots" end)')
  self.assertFalse(self.invoke('Host').ok)
  self.assertEqual(self.lua.globals().RESERVATIONS,0)

if __name__=='__main__': unittest.main()
