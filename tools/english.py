"""Apply the reviewed English display-text catalogue without changing state IDs."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
PAIRS=r'''
HANUL CORBULUI|THE RAVEN INN
CASA FIERARULUI|BLACKSMITH'S HOUSE
CASA CU IEDERA|IVY COTTAGE
FARMACIA|APOTHECARY
CASA PADURARULUI|FORESTER'S HOUSE
CASA VECHE|OLD COTTAGE
Turnul cu ceas|Clock Tower
CRIPTA {index}|CRYPT {index}
SATUL DUPA APUS|VILLAGE AFTER DUSK
CARTIERUL BRESLELOR|GUILD QUARTER
MINA ARGINTIE|SILVER MINE
RUINELE STRAJERILOR|WATCHKEEPER RUINS
MANASTIREA LUMINII|MONASTERY OF LIGHT
CASA TESATORULUI|WEAVER'S HOUSE
CASA BRUTARULUI|BAKER'S HOUSE
CASA TAMPLARULUI|CARPENTER'S HOUSE
MANASTIRE|MONASTERY
MOARA VECHE|OLD MILL
FERMA DE LA RASCRUCE|CROSSROADS FARM
CAPELA SFANTULUI SOARE|SUNWARD CHAPEL
CONTRACTE / ODIHNA|CONTRACTS / REST
PROVIZII: FERMA|SUPPLIES: FARM
PROVIZII: MOARA|SUPPLIES: MILL
PROVIZII: PIATA|SUPPLIES: MARKET
SIGILIUL ZORILOR|DAWN SEAL
FIERAR|BLACKSMITH
BRESLE|GUILDS
VINDECATOR|HEALER
COSMETICE|COSMETICS
MISIUNI|QUESTS
HAN / CONTRACTE|INN / CONTRACTS
INDICIU: ZIUA|CLUE: DAYTIME
SIGILIU: NOAPTEA|SEAL: NIGHTTIME
VATRA / GATIT|HEARTH / COOKING
SPRE SAT|ENTER VILLAGE
Culege 5 ierburi in padurea de la sud-vest|Gather 5 herbs in the southwestern forest
Aduna 4 minereuri din mina de la est|Collect 4 ore deposits at the eastern mine
Gaseste 3 relicve in ruinele de la nord|Find 3 relics in the northern ruins
Activeaza altarul manastirii din sud|Activate the monastery altar to the south
Serverul se inchide. Reconecteaza-te.|The server is shutting down. Please reconnect.
Profil indisponibil sau deschis pe alt server. Reincearca in cateva minute.|Your profile is unavailable or open on another server. Please try again in a few minutes.
Nivel|Level
Aur|Gold
TEST - progres temporar|TEST - temporary progress
Salvare activa|Saving enabled
Sfat: tabla de misiuni este langa fantana. Interactiune: R / L1 / atingere.|Tip: the quest board is beside the fountain. Interact: R / L1 / touch.
Salvat|Saved
Salvare esuata - reincercare automata|Save failed - retrying automatically
Conexiunea cu salvarea s-a intrerupt. Reconecteaza-te.|The connection to your saved profile was lost. Please reconnect.
Livrare: |Delivery: 
s | Han|s | Inn
Sigiliu descifrat: activeaza altarul noaptea|Seal deciphered: activate the shrine at night
Contracte la han | Indiciu la capela ziua|Contracts at the inn | Chapel clue by day
Vorbeste cu tabla de misiuni din piata|Visit the quest board in the market square
Obiectiv complet. Revino la tabla de misiuni pentru recompensa.|Objective complete. Return to the quest board for your reward.
Interactioneaza|Interact
Ierburi|Herbs
Culege|Gather
Minereu|Ore
Extrage|Mine
Relicva|Relic
Cerceteaza|Investigate
Misiuni|Quests
Accepta / Incaseaza|Accept / Claim reward
Fierar|Blacksmith
Lanterna +1 (100/200/300 aur)|Lantern +1 (100/200/300 gold)
Vindecator|Healer
Vindeca (30 aur)|Heal (30 gold)
Breasla|Guild trainer
Schimba specializarea|Change specialization
Spre sat|Enter village
Exploreaza|Explore
Hanul Corbului|The Raven Inn
Contract: 3 livrari / 180s|Contract: 3 supplies / 180s
Provizii|Supplies
Ridica pentru han|Collect for the inn
Inscripția capelei|Chapel inscription
Cerceteaza ziua|Read by daylight
Sigiliul zorilor|Dawn Seal
Ritual nocturn|Night ritual
Vatra hanului|Inn hearth
Gateste: 2 ierburi / +25 HP|Cook: 2 herbs / +25 HP
Expeditie|Expedition
Exploreaza 3 repere|Explore 3 landmarks
Activeaza ritualul|Perform ritual
Contract expirat. Poti accepta din nou la han.|Contract expired. Accept another at the inn.
Explorare PvE. Vei participa la urmatoarea runda.|PvE exploration. You will join the next round.
Provizii livrate: +80 XP / +40 aur. Urmatorul contract in 3 minute.|Supplies delivered: +80 XP / +40 gold. Next contract in 3 minutes.
Ridica provizii din piata, de la moara si de la ferma. Revino in 180s.|Collect supplies from the market, mill and farm. Return within 180s.
Hangiul are provizii. Revino mai tarziu.|The inn is stocked. Come back later.
Contractele se accepta ziua. Noaptea cauta sigiliul.|Accept contracts by day. Search for the seal at night.
Contract acceptat: piata, moara, ferma -> han, in 180s.|Contract accepted: market, mill, farm -> inn, within 180s.
Accepta intai un contract la han.|Accept a contract at the inn first.
Ai ridicat deja proviziile de aici.|You have already collected these supplies.
Provizii |Supplies 
/3. Revino la han.|/3. Return to the inn.
Inscripția poate fi citita doar la lumina zilei.|The inscription can only be read by daylight.
Indiciu: la noapte, aprinde sigiliul din curtea manastirii.|Clue: tonight, awaken the seal in the monastery courtyard.
Sigiliu restaurat: +120 XP / +60 aur. Poti cerceta din nou dupa 5 minute.|Seal restored: +120 XP / +60 gold. Investigate again after 5 minutes.
Ai nevoie de indiciul capelei, noapte si ritual reincarcat (5 minute).|You need the chapel clue, nighttime and a ready ritual (5-minute cooldown).
Sanatatea este deja completa.|Your health is already full.
Culege 2 ierburi pentru o masa calda.|Gather 2 herbs to cook a warm meal.
Asteapta 45 secunde intre mese.|Wait 45 seconds between meals.
Masa calda: +25 HP. Infectia ramane.|Warm meal: +25 HP. Infection remains.
Recompensa: |Reward: 
 aur. Accepta urmatoarea misiune.| gold. Accept the next quest.
Lanterna este deja la nivelul maxim.|Your lantern is already fully upgraded.
Ai nevoie de |You need 
 aur.| gold.
Lanterna imbunatatita permanent.|Lantern permanently upgraded.
Vindecarea costa 30 aur.|Healing costs 30 gold.
Sanatate refacuta. Infectia NU este vindecata.|Health restored. Infection is NOT cured.
Specializare: |Specialization: 
. Vanator: aur +2, Cercetas: expeditii +20 XP, Carturar: cules +2 XP.|. Hunter: +2 gathering gold; Scout: +20 expedition XP; Scholar: +2 gathering XP.
Expeditie terminata: XP si aur primite.|Expedition complete: XP and gold awarded.
Recompensa expeditiei este disponibila o data la 5 minute.|Expedition rewards are available once every 5 minutes.
Expeditie: |Expedition: 
/3 repere vizitate (padure, mina, ruine).|/3 landmarks visited (forest, mine, ruins).
Resursa se reface pentru tine.|This resource is replenishing for you.
Sunt necesari minimum doi jucatori.|At least two participants are required.
Satenii au castigat: toti vampirii au fost capturati.|Villagers win: all vampires have been captured.
Vampirii au castigat: satul a fost cucerit.|Vampires win: the village has fallen.
Vampirii au castigat|Vampires win
Capturat in cripta |Captured in crypt 
 pana la sfarsitul rundei.| until the round ends.
Apropie-te de o tinta vizibila, la maximum 10 studs.|Approach a visible target within 10 studs.
Abilitatea se reincarca.|Ability is on cooldown.
Slabit timp de 8 secunde. Fugi sau cere ajutor!|Weakened for 8 seconds. Escape or call for help!
Vampir descoperit! Captureaza-l in 15 secunde.|Vampire revealed! Capture them within 15 seconds.
Tinta este infectata. Se transforma la urmatorul apus.|The target is infected and transforms at the next dusk.
Tinta este om.|The target is human.
Vampir capturat in cripta.|Vampire captured in a crypt.
Capturezi doar vampiri descoperiti prin investigare.|You can only capture vampires revealed by investigation.
Un vampir s-a hranit! Cauta protectia celorlalti.|A vampire fed on you! Seek safety with others.
Ti-ai refacut sanatatea.|You recovered health.
Esti infectat. Devii vampir la urmatorul apus.|You are infected. You become a vampire at the next dusk.
Infectare reusita. Transformarea are loc la urmatorul apus.|Infection successful. Transformation occurs at the next dusk.
Botii de test sunt disponibili numai in Studio.|Test bots are available only in Studio.
Setarea |Setting 
 boti se aplica dupa runda curenta.| bots will apply after this round.
Boti: |Bots: 
. Runde de practica, fara recompense de runda.|. Practice rounds award no round rewards.
Exploreaza prin portal. Contracte la han ziua; sigiliul manastirii noaptea. PvP: minimum 2 jucatori.|Enter the portal to explore. Inn contracts by day; monastery seal at night. PvP: 2+ participants.
PRACTICA CU BOTI - fara recompense de runda.|BOT PRACTICE - no round rewards.
Runda incepe curand.|The round starts soon.
Ziua: investigheaza si captureaza vampirii descoperiti.|Day: investigate and capture revealed vampires.
Transformarea s-a incheiat. Esti vampir!|Transformation complete. You are a vampire!
Noaptea: ramaneti impreuna. Vampirii pot vana.|Night: stay together. Vampires can hunt.
Satenii au castigat: au supravietuit celor trei nopti.|Villagers win: they survived all three nights.
Nivel %d | XP %d/%d | Aur %d | %s|Level %d | XP %d/%d | Gold %d | %s
Se incarca profilul...|Loading profile...
Explorare: |Exploration: 
%s | %ds | %d/%d | %s | Cripte: %d|%s | %ds | %d/%d | %s | Crypts: %d
Capturat: asteapta urmatoarea runda. |Captured: wait for the next round. 
INFECTAT: transformare la urmatorul apus. |INFECTED: transformation at the next dusk. 
PRACTICA / BOTI |PRACTICE / BOTS 
Hranire|Feed
Investigare|Investigate
Infectare|Infect
Capturare|Capture
Investigare (ziua)|Investigate (daytime)
Captureaza slabit|Capture weakened
 | Controller: X / Y | Mobil: butoanele de actiune| | Controller: X / Y | Mobile: action buttons
Misca-te cu comenzile Roblox. Actiunile se activeaza in faza potrivita.|Use Roblox movement controls. Abilities unlock in the appropriate phase.
Tinta apropiata: |Nearby target: 
Apropie-te de un jucator pentru actiune|Approach a participant to interact
Lanterna|Lantern
Sabie de argint|Silver Sword
Arbaleta|Crossbow
Gheare|Claws
Ataca|Attack
Grafica: Auto|Graphics: Auto
Efecte reduse: Nu|Reduced effects: Off
Luminozitate: Normal|Brightness: Normal
Grafica: |Graphics: 
Redusa|Low
Echilibrata|Balanced
Ridicata|High
Efecte reduse: |Reduced effects: 
Da|On
Nu|Off
Luminozitate: |Brightness: 
Sporita|Boosted
LOVIT|HIT
ATACAT|UNDER ATTACK
Urmareste|Spectate
Cosmetice optionale | Robux\nFara avantaje in lupta|Optional cosmetics | Robux\nNo combat advantages
Inchide|Close
 | Detinut| | Owned
 | Indisponibil momentan| | Currently unavailable
 | Verific pretul...| | Checking price...
Nu este de vanzare|Not for sale
Achizitie indisponibila. Reincearca.|Purchase unavailable. Please try again.
Lanterna aurie|Golden Lantern
Culoare aurie, fara bonus de raza sau putere.|Golden color with no range or power advantage.
Aura lunii|Moon Aura
Efect albastru cosmetic, indiferent de rol.|Blue cosmetic effect, independent of your role.
Sustinator al satului|Village Supporter
Titlu cosmetic deasupra personajului.|Cosmetic title above your character.
SUSTINATOR AL SATULUI|VILLAGE SUPPORTER
Vezi cosmetice|Browse cosmetics
Magazin Robux|Robux Shop
MULTIPLAYER\nHost: sesiune privata. Distribuie codul celor cu care vrei sa joci (expira in 2 ore).|MULTIPLAYER\nHost a private session. Share its code with your group (expires in 2 hours).
Se proceseaza...|Working...
Conexiune indisponibila. Reincearca.|Connection unavailable. Please try again.
Host / creeaza sesiune|Host / create session
Cod de 8 caractere|8-character join code
Join / intra cu cod|Join / enter code
Invita in joc (trimite si codul)|Invite friends (also share your code)
Invitatia nu este disponibila. Foloseste codul sesiunii.|Invitation unavailable. Use the session code.
Invitatiile nu sunt disponibile aici. Foloseste codul sesiunii.|Invitations are unavailable here. Use the session code.
Studio: boti 0 / 3 / 7 / 12|Studio: bots 0 / 3 / 7 / 12
 boti | | bots | 
urmeaza |next: 
schimba 0/3/7/12|change 0/3/7/12
schimba dupa runda|change after round
Codul sesiunii: |Session code: 
 (2 ore)| (2 hours)
Cerere invalida.|Invalid request.
Asteapta cateva secunde.|Please wait a few seconds.
Alege intre 0 si 12 boti.|Choose between 0 and 12 bots.
Cerere necunoscuta.|Unknown request.
Host / Join necesita joc publicat si aplicatia Roblox. In Studio foloseste botii sau Server & Clients.|Host / Join requires a published experience and the Roblox app. In Studio, use bots or Server & Clients.
Codul trebuie sa aiba 8 caractere (0-9 / A-F).|The code must have 8 characters (0-9 / A-F).
Cod invalid sau expirat (2 ore).|Invalid or expired code (2 hours).
Conectare la sesiune. Cod: |Joining session. Code: 
Conectarea a esuat. Incearca din nou; sesiunea gazduita pastreaza acelasi cod.|Connection failed. Try again; your hosted session keeps the same code.
Teleport nereusit. Reincearca din meniul Multiplayer.|Teleport failed. Try again from the Multiplayer menu.
'''
# Strings containing the catalogue delimiter are supplied explicitly below.
# Exact literals avoid translating role/phase IDs and persisted specialization keys.
TRANSLATIONS={}
for line in PAIRS.splitlines():
 if line:
  old,sep,new=line.partition('|')
  if sep: TRANSLATIONS[old]=new
TRANSLATIONS.update({
 'Nivel %d | XP %d/%d | Aur %d | %s':'Level %d | XP %d/%d | Gold %d | %s',
 '%s | %ds | %d/%d | %s | Cripte: %d':'%s | %ds | %d/%d | %s | Crypts: %d',
 's | Han':'s | Inn',
 'Contracte la han | Indiciu la capela ziua':'Contracts at the inn | Chapel clue by day',
 'PRACTICA / BOTI | ':'PRACTICE / BOTS | ',
 ' | Controller: X / Y | Mobil: butoanele de actiune':' | Controller: X / Y | Mobile: action buttons',
 r'Cosmetice optionale | Robux\nFara avantaje in lupta':r'Optional cosmetics | Robux\nNo combat advantages',
 ' | Detinut':' | Owned',' | Indisponibil momentan':' | Currently unavailable',
 ' | Verific pretul...':' | Checking price...',
 ' boti | ':' bots | ',
})
# Remove entries whose separator was itself part of the original text.
for key in ['Nivel %d ','%s ','s ','Contracte la han ','PRACTICA / BOTI ',' ','Cosmetice optionale ',' boti ']:
 TRANSLATIONS.pop(key,None)
LITERAL=re.compile(r"(?P<quote>['\"])(?P<body>(?:\\.|(?!\1)[^\\\n])*)(?P=quote)")
def translate(text):
 def replace(match):
  body=match['body']; new=TRANSLATIONS.get(body)
  if new is None: return match[0]
  quote=match['quote']
  return quote+new.replace(quote,'\\'+quote)+quote
 return LITERAL.sub(replace,text)
if __name__=='__main__':
 for path in [*sorted((ROOT/'src').glob('*.lua')),ROOT/'build_place.py']:
  source=path.read_text(encoding='utf-8'); updated=translate(source)
  if source!=updated:
   path.write_text(updated,encoding='utf-8'); print('Translated',path.name)
