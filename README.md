# Village After Dusk — multiplayer Roblox RPG

**Hunting/world-life update:** human/vampire outfits, Crucifix, Holy Water, Wooden Stake, church sanctuary, ambient animals, vampire night hounds and score-driven priest/bat support. Live days/nights are now **8 / 6 minutes**. **42 local tests** plus targeted Studio fixtures pass. [Rules and test evidence](docs/HUNTING_AND_WORLD_LIFE.md).

**The game now uses English throughout its signs, objects, prompts, HUD and menus.** Saved role/class identifiers remain compatible. The English revision passes **36 local tests** and targeted Studio checks. See [English deployment check](docs/ENGLISH_DEPLOYMENT_CHECK.md) for evidence and remaining live release gates.

## Revizie 30 octombrie 2026

**Boti si multiplayer:** meniul **Multiplayer** (buton / M / Select) include Host, Join cu cod si invitatii. In Studio poti activa **0 / 3 / 7 / 12 boti**, cu runde rapide fara recompense de runda. Schimbarile se aplica dupa runda curenta. **29 de teste locale trec**; luptele, infectarea, transformarea, capturarea si resetarea au fost probate cu boti in Studio. Host/Join necesita validare intr-o experienta publicata, cu aplicatia Roblox. [Instructiuni si probe](docs/BOTS_AND_MULTIPLAYER.md).

Sat reorganizat în jurul pieței, ulițe, grădini, moară, fermă și capelă. Contractele hangiului leagă piața, moara și ferma (3 provizii / 180s). Inscripția capelei se citește ziua, iar sigiliul mănăstirii se activează noaptea. Două ierburi permit gătitul la vatra hanului pentru +25 HP. Explorarea solo alternează zi/noapte la 120s. Activitățile folosesc R / L1 / prompt tactil și nu dezvăluie rolurile secrete.

**19 teste locale trec.** Contractul și ritualul au fost executate în Studio cu un jucător. Verificările multiplayer, salvările live și performanța pe dispozitive rămân deschise: [raportul de lansare](docs/RELEASE_REVIEW.md).

Un orășel transilvănean de **960 × 960 studs**, cu explorare, misiuni și progres persistent, peste conflictul dintre săteni și vampiri. Un singur proiect, cu inputuri pentru PC, telefon și controller. **Maximum 50 de participanți într-o rundă.**

**Stare: prototip de mini MMORPG, nu lansare finală.** Codul și fișierul sunt verificate local; importul, multiplayer-ul, salvările și achizițiile reale nu au fost executate în motorul Roblox. Nu este încă un MMORPG complet cu lumi persistente, raiduri și economie între jucători.

## Arme, prezentare și performanță — actualizare

**Versiune pre-release îmbunătățită; FPS și lansarea rămân de validat în Roblox.** Vezi [criteriile de performanță](docs/PERFORMANTA.md).

- Sabie de argint și arbaletă pentru săteni; gheare pentru vampiri. Toate cele trei unelte sunt gratuite și identice în inventarul tuturor, pentru a nu dezvălui rolul secret ziua. Serverul permite folosirea numai pentru tabăra și faza corecte.
- Atacă noaptea cu click stânga, R2 sau butonul tactil Atacă, după echiparea uneltei prin inventarul Roblox. Fără friendly fire. Raze: sabie 8, arbaletă 45, gheare 7 studs; cooldown 1 / 2,6 / 1,2s. Loviturile necesită orientare și linie de vedere.
- Sănătatea nu scade sub 1. La înfrângere devii slăbit 8s, apoi revii la 35 HP dacă ai rămas la 1 HP. Un vampir slăbit poate fi capturat cu Q inclusiv noaptea. Rămân valabile capturarea de zi și infectarea întârziată.
- LightingStyle Realistic, atmosferă, paletă caldă/rece, tranziții zi/noapte de 4s, bloom discret și grafică Auto/Redusă/Echilibrată/Ridicată. Setări separate pentru efecte reduse și luminozitate; fără camera shake sau ecran care clipește.
- Camera de spectator: G, D-pad dreapta sau buton Urmărește când ești captiv. Are nevoie de ținte încărcate prin streaming.
- Cele trei [texturi originale Higgsfield](assets/textures/README.md) sunt incluse în repository, cu configurarea MaterialVariant pregătită. **Încărcarea în Roblox și completarea ID-urilor rămân necesare**; în lipsa lor se folosesc materialele Roblox.
- Actualizări de stare la 1 Hz, raycast-uri limitate, lumini locale după distanță, umbre reduse și măsurare FPS/p95 pe client. Aceste schimbări nu reprezintă un benchmark de 60 FPS.

## Joacă și explorare

1. Deschide `Satul_dupa_Apus.rbxlx` în Roblox Studio pe Windows/Mac.
2. În lobby, interacționează cu portalul **Spre sat** pentru a explora inclusiv singur. În afara rundei ești explorator fără acces la atacurile PvP și nu poți fi atacat de participanți. La următoarea rundă intri automat, dacă profilul și personajul sunt pregătite.
3. Lângă fântână găsești tabla de misiuni, fierarul, vindecătorul, instructorul și magazinul cosmetic.
4. Misiuni: 5 ierburi în pădurea de sud-vest → 4 minereuri în est → 3 relicve în ruinele din nord → altarul mănăstirii din sud. Revino la tablă să încasezi fiecare recompensă și interacționează din nou pentru următoarea misiune. Lanțul se repetă.
5. Vizitează cele trei obeliscuri de expediție: pădure, mină, ruine. Recompensa se poate obține o dată la 5 minute pe sesiune.

Resursele au reîncărcare personală de 60s: nu trebuie să concureze 50 de oameni pentru același nod. XP, aurul, specializarea, misiunea, victoriile și îmbunătățirile lanternei se salvează. Personajul poate ajunge la nivelul 30; nivelul nu mărește puterea de luptă. Nu există inventar de echipamente sau tranzacții între jucători.

Specializări gratuite, schimbate la instructor:

| Specializare | Bonus |
|---|---|
| Vânător | +2 aur la colectare |
| Cercetaș | +20 XP la expediție |
| Cărturar | +2 XP la colectare |

Fierarul îmbunătățește permanent raza lanternei în trei trepte, pentru 100/200/300 aur din joc. Vindecarea costă 30 aur, reface sănătatea, dar nu vindecă infecția.

## Runde, vampiri și cripte adaptive

Rundele pornesc cu minimum 2 participanți pregătiți, după 20s. Maximum 3 cicluri: **zi 240s / noapte 180s**. Între runde, rolurile și captivitatea se resetează; progresul RPG rămâne. Cei care intră în timpul unei runde pot explora fără PvP și participă din runda următoare.

| Participanți în rundă | Cripte active | Vampiri inițiali |
|---|---:|---:|
| 2–10 | 1 | 1 |
| 11–20 | 2 | 2 |
| 21–30 | 3 | 3 |
| 31–40 | 4 | 4 |
| 41–50 | 5 | 5 |

Criptele se ajustează și când participanții se deconectează. Numărul include captivii, dar nu exploratorii din afara rundei. Captivii sunt distribuiți echilibrat, pe locuri distincte. Dacă o criptă se dezactivează, ocupanții ei sunt mutați într-una activă. În așteptare rămâne o criptă vizibilă.

Ziua, investighezi un jucător apropiat. Vampirii descoperiți pot fi capturați în 15s. Noaptea, vampirii sunt vizibili și mai rapizi; hrănirea este stilizată, neletală, iar infectarea este limitată la una/vampir/noapte. Infectatul se transformă la următorul apus. Sătenii câștigă prin capturarea tuturor vampirilor sau prin supraviețuire după noaptea a treia. Vampirii câștigă dacă nu mai există săteni liberi. Infecțiile din ultima noapte nu se transformă după terminarea rundei.

Resetarea/decesul duce la captivitate pentru restul rundei. Rolurile se validează pe server; clientul primește numai propriul rol secret. Recompense: 160 XP/80 aur pentru echipa câștigătoare, 60 XP/25 aur pentru cealaltă echipă, inclusiv captivii.

## Comenzi

| Acțiune | PC | Xbox | PlayStation | Telefon |
|---|---|---|---|---|
| Investighează / Hrănește | E | X | Pătrat | Acțiune 1 |
| Capturează / Infectează | Q | Y | Triunghi | Acțiune 2 |
| Lanternă | F | B | Cerc | Lanternă |
| NPC, resurse, magazin | R | LB | L1 | Prompt tactil |
| Închide magazinul | Buton / Escape | B | Cerc | Buton Închide |

Mișcarea și camera folosesc comenzile Roblox. Ținta PvP este cel mai apropiat participant liber, vizibil, la maximum 10 studs. Magazinul folosește butoane selectabile cu controllerul; dialogul Roblox confirmă orice achiziție.

## Magazin Robux

Trei game pass-uri cosmetice: **Lanternă aurie**, **Aura lunii**, **Susținător al satului**. Culoarea lanternei nu îi modifică raza. Aura și titlul sunt independente de rol și nu dezvăluie vampirii. Nu există cumpărare de infectări, evadări sau victorii.

**Achizițiile sunt dezactivate implicit** (`id=0`). Creează pass-urile pe experiența ta și introdu ID-urile în `src/MonetizationConfig.lua`, apoi regenerează fișierul. Prețurile se configurează pe Roblox și sunt citite dinamic pentru jucător, inclusiv prețurile regionale. Drepturile sunt verificate de server prin MarketplaceService la intrare și după cumpărare. [Activare și venituri](docs/MONETIZARE.md).

Robux cheltuiți în magazin pot genera venituri proprietarului experienței conform regulilor Roblox. Jucătorii primesc XP și aur prin joc; nu există Robux gratuit, premii Robux automate sau retrageri din aur.

## Configurare obligatorie înainte de lansare

- În Creator Dashboard, setează **Maximum Players = 50** pentru locul publicat. `Config.MaxPlayers=50` limitează runda; nu modifică limita de admitere Roblox, care nu poate fi setată prin script.
- În Studio, progresul este temporar în mod implicit. Pentru testarea salvărilor, folosește o experiență separată de test și setările din [TESTARE.md](docs/TESTARE.md). Nu testa pe profilurile reale.
- Verifică StreamingEnabled (activat în fișier), dispozitivele acceptate, toate scenariile multiplayer și chestionarul de conținut înainte de publicare.

## Dezvoltare și verificări

```sh
python3 -m pip install -r requirements-dev.txt
python3 build_place.py
python3 validate.py
python3 -m unittest discover -s tests -v
```

Generatorul include cele 12 scripturi/module și harta, fără modele sau pluginuri externe obligatorii. Regenerarea suprascrie orice modificare făcută numai în `.rbxlx`. Fișierul generat conține aproximativ 1.200 de instanțe; streamingul este activ, iar resursele sunt gestionate prin prompturi, fără bucle per NPC.

- `src/Game.server.lua`: runde, roluri, capturare, cripte și validări PvP.
- `src/Rules.lua`: reguli pure pentru capacitate și repartizare.
- `src/Progression.lua`: profiluri, misiuni, aur, niveluri și interacțiuni.
- `src/Config.lua`: durate, capacitate și salvare.
- `src/Controls.client.lua`: HUD, target și inputuri.
- `src/Monetization.lua`, `src/MonetizationConfig.lua`, `src/Shop.client.lua`: cosmetice și magazin.
- `tests/`: teste de logică Lua cu mock-uri; nu emulează motorul sau serviciile Roblox.
- [Stare și limite](docs/STARE.md), [Plan de testare](docs/TESTARE.md).
