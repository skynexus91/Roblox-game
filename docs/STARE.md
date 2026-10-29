# Starea versiunii mini RPG — îmbunătățiri de gameplay și prezentare

## Adăugat în această revizie

Arme gratuite (sabie, arbaletă, gheare), reguli de lovire pe server, slăbire temporară și capturare nocturnă a vampirilor învinși; feedback de lovitură; cameră spectator; setări de accesibilitate; grafică adaptivă; atmosferă și tranziții; trei texturi proprii generate în Higgsfield, comprimate și pregătite pentru import. Texturile NU sunt încă încărcate în Roblox: ID-urile sunt 0 și materialele incluse rămân fallback.

14 teste locale de logică trec, alături de validarea celor 12 surse Lua și a fișierului XML. Toate măsurătorile de motor/FPS și aprobarea pentru lansare rămân deschise. Vezi PERFORMANTA.md.

## Implementat în proiect

- Lume de 960 × 960 studs: centru, cartier de bresle, pădure, mină, ruine, mănăstire; 50 de poziții distincte de start.
- Runde pentru 2–50 de participanți; 1–5 vampiri inițiali; control zi/noapte și capturare.
- 1–5 cripte active, câte una la 10 participanți, distribuție echilibrată și relocare la închidere. Captivii au rădăcina ancorată pe server.
- Niveluri până la 30, XP, aur, 4 misiuni repetabile, expediții, 3 specializări și îmbunătățirea lanternei.
- Salvare cu UpdateAsync, lease de sesiune, autosave distribuit, salvare la plecare și la închidere. Nu se creează un profil implicit dacă încărcarea live eșuează. Studio folosește implicit progres temporar.
- Magazin cu 3 pass-uri cosmetice, verificare server și prețuri regionale citite pe client. Implicit ID=0, deci vânzări dezactivate.
- Explorare în afara rundelor, inclusiv pentru un singur jucător. Rolurile PvP nu sunt persistente; progresul RPG este.
- Streaming activ; clădirile/criptele sunt modele atomice mici. Inputuri tactil, tastatură și controller.

## Verificat local

Sintaxa celor 12 fișiere Lua; integritatea XML; 50 spawn-uri unice; 5 cripte; noduri de misiuni; dimensiunea hărții; culori și geometrie; egalitatea scripturilor încorporate cu sursele. Testele de logică execută Lua cu mock-uri: populații 1–50, capacitate/repartizare, relocare, scalare vampiri, niveluri, recompense, cooldown de colectare, încasare unică, blocare de sesiune, salvare/elibereare și refuzul interacțiunilor nepermise.

## De verificat în Roblox

Importul și execuția în Studio, streaming și teleportare, multiplayer real, funcționarea DataStore sub throttling/erori/reconectare și shutdown, proprietatea pass-urilor și achizițiile, UI pe dispozitive reale, balansul și încărcarea cu 50 de jucători. Testele cu mock-uri nu dovedesc aceste comportamente. Limita locului publicat trebuie setată separat la 50 în Creator Dashboard.

## Limite de produs

Este o bază de mini MMORPG cu progres și activități RPG în jurul rundelor, nu un MMORPG complet. Nu include adversari PvE cu AI, boss-uri, raiduri, inventar/echipamente, crafting, trading, guild-uri sociale, lumi persistente între servere, sunete originale, artă finală sau localizare completă. Specializările sunt bonusuri mici de economie, nu arbori de abilități. Rezistența la teleport/speed hacks necesită lucru suplimentar; distanța și cooldown-ul server nu sunt un anti-cheat complet.

Nu există tranzacții Robux active, venit verificat, acces la dashboard sau publicare Roblox din acest mediu. Progresul salvat poate pierde ultima parte de după autosave în caz de crash sau indisponibilitate prelungită a serviciului; erorile sunt semnalate, nu ascunse ca salvări reușite.
