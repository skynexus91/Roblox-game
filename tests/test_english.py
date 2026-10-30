from pathlib import Path
import importlib.util
import unittest
import xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('english',ROOT/'tools/english.py')
english=importlib.util.module_from_spec(spec); spec.loader.exec_module(english)

class EnglishPresentationTests(unittest.TestCase):
 def test_no_untranslated_catalogue_literals_remain(self):
  for path in [*(ROOT/'src').glob('*.lua'),ROOT/'build_place.py']:
   for match in english.LITERAL.finditer(path.read_text(encoding='utf-8')):
    self.assertNotIn(match['body'],english.TRANSLATIONS,f'{path.name}: {match["body"]}')
 def test_generated_signs_and_building_names(self):
  xml=E.parse(ROOT/'Satul_dupa_Apus.rbxlx')
  texts=[p.text or '' for p in xml.findall('.//Properties/string[@name="Text"]')]
  self.assertIn('THE RAVEN INN',texts)
  self.assertIn('OLD MILL',texts)
  self.assertIn('CROSSROADS FARM',texts)
  self.assertIn('VILLAGE AFTER DUSK',texts)
  for text in texts:
   self.assertFalse(any(word in text for word in ['CASA ','HANUL','CRIPTA','PROVIZII','MANASTIRE']))
 def test_role_and_phase_ids_still_drive_actions(self):
  code=(ROOT/'src/Controls.client.lua').read_text()
  self.assertIn("s.role=='Vampir'",code)
  self.assertIn("s.phase=='Noapte'",code)
  self.assertIn("Vampir='Vampire'",code)
  self.assertIn("Noapte='Night'",code)

if __name__=='__main__': unittest.main()
