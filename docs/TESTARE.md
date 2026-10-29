# Testare înainte de publicare

Scenariile Roblox de mai jos sunt **de executat**, nu sunt bifate automat de testele locale.

## Configurare

1. Deschide fișierul în Studio, verifică Output și harta editabilă.
2. Publică într-o experiență separată de test. Setează Maximum Players la **50** în Creator Dashboard pentru locul respectiv. Confirmă prin `Players.MaxPlayers` în server; acest atribut este doar pentru citire.
3. Studio are profiluri temporare implicit. Pentru testarea DataStore, folosește experiența separată de test, activează API Services pentru ea și setează `Config.StudioPersistence=true`. Nu folosi experiența de producție sau baza live pentru acest test. Regenerează fișierul după orice modificare de Config.
4. Păstrează `MonetizationConfig` cu ID=0 până când există pass-uri corecte și testarea jocului este suficientă.

## Scară și cripte

- Cu 1 client explorează prin portal; runda nu pornește. Cu 2 pornește după 20s. Testează 10/11, 20/21, 30/31, 40/41 și 50 participanți pregătiți.
- Verifică 50 de starturi distincte pe drum, fără coliziuni cu clădirile. Vampiri inițiali: ceil(N/10), minimum 1. Zi: 240s; noapte: 180s; 3 cicluri.
- La fiecare prag, confirmă 1–5 cripte în HUD și pe hartă; cele inactive trebuie să fie invizibile și fără coliziuni.
- Capturează suficienți jucători ca să ocupi toate criptele; confirmă sloturi distincte, distribuție cu diferență de maximum 1, lipsa ieșirii prin mers/salt/reset.
- Deconectează participanți până când se închide o criptă ocupată: captivii trebuie mutați în criptele active, cu sloturi distincte. Numărul depinde de participanții încă conectați, inclusiv captivi; intrările în timpul rundei nu măresc numărul până la runda următoare.
- Verifică resetarea tuturor rolurilor, ancorelor și captivității după rezultat.

## PvP și exploratori

- Investighează om/vampir/infectat; captura funcționează numai ziua, pentru vampir dezvăluit în ultimele 15s.
- Noaptea: hrănire neletală, maximum o infectare/vampir/noapte, transformare la apusul următor. Infecția din ultima noapte nu se transformă după rezultat.
- Testează victoriile ambelor tabere, supraviețuirea, deconectările și resetarea/decesul. Recompensa pentru supraviețuirea sătenilor trebuie să fie acordată taberei corecte.
- Un explorator din afara rundei nu poate folosi sau primi atacuri și nu contribuie la condiția de victorie. Poate colecta și face misiuni; la runda următoare intră automat.
- Cereri PvP cu ținte invalide, NaN/infinit, distanță >10, pereți, rol/fază incorectă sau spam: fără efect.

## RPG și salvare

- Acceptă pe rând cele 4 misiuni, urmărește contoarele și încasează la tablă. Repetarea interacțiunii nu trebuie să dubleze recompensa.
- Doi jucători culeg același nod: amândoi primesc recompensa; același jucător nu poate repeta înainte de 60s. Obiectivul avansează doar pentru tipul activ.
- Expediție: vizitează trei repere distincte, verifică recompensa și cooldown-ul de 5 minute; reînceperea sesiunii resetează acest cooldown.
- Compară bonusurile specializărilor; confirmă 3 trepte de lanternă, deducerea aurului, refuzul fondurilor insuficiente și vindecarea fără eliminarea infecției.
- Reconectează-te pe alt server: XP/aur/misiune/specializare/lanternă/victorii persistă, rolul și captivitatea nu.
- Simulează încărcare/salvare eșuată, profil blocat de altă sesiune, expirarea lease-ului, autosave, plecare în timpul salvării și shutdown cu 50 de profiluri. Nicio eroare de încărcare nu trebuie să suprascrie progresul cu zero.

## Magazin și platforme

- ID=0: butoane indisponibile, fără prompt de plată. Cu ID-uri configurate corect: prețul afișat corespunde dialogului Roblox, inclusiv regional.
- Anulare/eroare: fără efect acordat. Cumpărare/deținere anterioară: efect verificat pe server, reaplicat după respawn și reconectare. Aura nu dezvăluie rolul, iar lanterna aurie nu oferă rază în plus.
- Telefon: joystick, cameră, acțiuni, prompturi R în variantă tactilă, HUD și magazin fără suprapuneri pe ecrane mici.
- PC: mișcare/cameră, E/Q/F/R, selectare și închidere magazin.
- Xbox/PlayStation: X/Y/B sau Pătrat/Triunghi/Cerc, LB/L1, navigare și confirmare în magazin, revenire la joc după închidere.
- Mergi între toate zonele și teleportează-te în/din lobby și cripte cu streaming activ; verifică încărcarea terenului și coliziunile.
- Măsoară FPS, memorie, rețea și timpi de server cu 10/25/50 jucători și pe un telefon modest. Nu declara suportul pentru 50 sau pentru console validat numai pentru că există inputuri/configurare.

Completează chestionarul de conținut conform jocului real și activează numai dispozitivele testate înainte de publicare.
