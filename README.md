# Satul după Apus — Roblox

Prototip multiplayer original, plasat într-un orășel transilvănean. Un singur proiect pentru telefon, PC și console, cu comenzi adaptate dispozitivului.

**Stare: prototip pentru testare, nu versiune finală de lansare.** Fișierul a fost generat și verificat structural; nu a fost deschis sau executat în Roblox Studio în acest mediu. Compatibilitatea efectivă pe dispozitive nu este încă certificată.

## Deschidere

1. Descarcă și extrage pachetul pe un calculator Windows sau Mac.
2. Deschide `Satul_dupa_Apus.rbxlx` în Roblox Studio. Harta este deja în fișier, editabilă, nu necesită pluginuri sau modele externe.
3. Rulează o simulare multiplayer locală cu minimum **doi jucători**. Testarea cu un singur jucător rămâne în așteptare intenționat.
4. Pentru modificări, editează `src/Game.server.lua` și `src/Controls.client.lua`, apoi rulează `python3 build_place.py`. Alternativ, editează scripturile direct în Studio și salvează locul. Regenerarea suprascrie modificările făcute doar în `.rbxlx`.
5. Înainte de lansare, parcurge `docs/TESTARE.md`. Publicarea în Roblox și configurarea dispozitivelor acceptate se fac din contul proprietarului, după testare. Proiectul nu este publicat automat.

Roblox Studio este disponibil pe Windows și Mac: https://create.roblox.com/docs/studio/setup

## Reguli implementate în cod

- Minimum 2 participanți, maximum 8 participanți într-o rundă. Cei în plus sau intrați după începere așteaptă runda următoare în zona separată.
- Pauză de 15 secunde, urmată de maximum 3 cicluri. Zi: 100 secunde. Noapte: 80 secunde.
- Un participant ales aleator începe vampir. Rolul secret rămâne în starea serverului; fiecare client primește doar propriul rol.
- Ziua, un sătean investighează un jucător apropiat. Un vampir descoperit devine vizibil timp de 15 secunde și poate fi capturat de un sătean. Investigarea se reîncarcă în 20 secunde; capturarea în 5.
- Vampirii capturați sunt mutați în criptă și imobilizați până la următoarea rundă.
- Noaptea, vampirii sunt marcați vizual, se mișcă mai repede și pot folosi hrănirea și infectarea.
- Hrănirea scade 20 puncte de sănătate țintei, fără a o coborî sub 25; vampirul recuperează până la 25. Reîncărcare: 8 secunde. Fără sânge sau scene grafice.
- Fiecare vampir poate infecta un om pe noapte. Omul se transformă la următorul apus, nu imediat. Infectarea și hrănirea sunt acțiuni separate.
- Sătenii câștigă dacă sunt capturați toți vampirii sau dacă există săteni liberi după a treia noapte. Infecția produsă în ultima noapte nu produce o transformare după încheierea rundei.
- Vampirii câștigă dacă nu mai există niciun sătean liber.
- Resetarea personajului sau moartea în timpul rundei duc la capturare pentru restul rundei; nu anulează consecințele prin respawn.
- Acțiunile verifică pe server rolul, faza, ținta, distanța de maximum 10 studs, obstacolele și reîncărcarea. Limitarea cererilor este tot pe server.

## Comenzi

Mișcarea și camera folosesc comenzile standard Roblox.

| Acțiune | PC | Controller Xbox | Controller PlayStation | Telefon/tabletă |
|---|---|---|---|---|
| Investighează / Hrănește-te | E | X | Pătrat | Butonul de acțiune 1 |
| Capturează / Infectează | Q | Y | Triunghi | Butonul de acțiune 2 |
| Lanternă | F | B | Cerc | Butonul Lanternă |

Prima și a doua acțiune depind de rol și de momentul zilei; butoanele se activează numai în faza potrivită. Ținta este automat cel mai apropiat jucător vizibil la maximum 10 studs. Numele țintei apare în interfață. Etichetele X/Y din explicația interfeței folosesc convenția Xbox; tastele echivalente PlayStation sunt în tabel. Testarea ambelor familii de controllere este necesară.

## Harta inclusă

Piață cu fântână, Hanul Corbului, farmacie, fierărie, trei case, turn cu ceas decorativ, cimitir, criptă cu gratii, alei, copaci, felinare și zonă separată de așteptare. Clădirile au intrări și interioare simple. Stil geometric de prototip, cu 321 de instanțe în fișier. Nu include sunete sau modele descărcate.

## Structură

- `Satul_dupa_Apus.rbxlx` — locul Roblox cu hartă și ambele scripturi încorporate.
- `src/Game.server.lua` — starea rundei, roluri, abilități și validări.
- `src/Controls.client.lua` — HUD, selectarea țintei, comenzi și lanternă locală.
- `build_place.py` — generator determinist al hărții și al fișierului Roblox; Python standard.
- `validate.py` — verificări structurale ale pachetului și verificarea sintaxei scripturilor.
- `requirements-dev.txt` — parser folosit doar pentru verificări locale, nu pentru joc.
- `docs/TESTARE.md` — scenarii multiplayer și platforme.
- `docs/STARE.md` — limite și ce mai trebuie făcut.

## Verificare locală

```sh
python3 -m pip install -r requirements-dev.txt
python3 build_place.py
python3 validate.py
```

Aceste verificări nu înlocuiesc rularea în motorul Roblox. Parserul validează sintaxa Lua comună folosită de scripturi; API-urile Roblox și comportamentul Luau sunt verificate efectiv în Studio.

## GitHub

Încarcă întregul conținut al acestui director într-un depozit dedicat. Nu este necesar să încarci arhiva ZIP alături de fișierele deja extrase. Nu sunt incluse parole, tokenuri, achiziții sau salvări de date personale.
