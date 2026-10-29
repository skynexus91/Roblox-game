# 60 FPS: țintă și criterii de validare

Nu există măsurători în motorul Roblox în această livrare. Un test Python/Lua nu poate certifica FPS, timpi GPU, latență sau comportamentul a 50 de clienți. 60 FPS este ținta de proiectare, nu un rezultat măsurat.

## Optimizări implementate

- Actualizarea stării proprii: 1 Hz, anterior 2 Hz. Rolurile altora nu sunt trimise clientului.
- Snapshot RPG reutilizat până când datele/mesajele se schimbă; dicționarele de cooldown nefolosite au fost eliminate din pachete.
- Selectarea țintei din apropiere la 5 Hz, cu sortare după distanță și maximum 8 raycast-uri per actualizare; se oprește când jucătorul nu este participant liber. Loviturile se verifică pe server numai la acțiune, fără proiectile simulate fizic.
- Armele folosesc puține piese fără coliziuni, touch, query sau umbre; trei unelte/jucător și fără bucle de simulare pe unealtă. Vizualurile nu dezvăluie rolul secret.
- Harta este ancorată, CanTouch este oprit, coliziunile/query sunt dezactivate pentru vizualuri necolizibile. Copacii folosesc coroane fără coliziuni. Clădirile și criptele rămân grupuri atomice locale, cu streaming.
- Lumini locale: fără umbre, activate pe client numai noaptea și în raza 70/110/150 studs în funcție de nivel. Fără emitatoare de particule continue sau lumini care urmăresc 50 de personaje pe server.
- Trei texturi ColorMap partajate de 512 × 512, fără sute de decaluri; sursele 1024 rămân în Higgsfield. ID-urile se configurează după importul Roblox. Nu sunt hărți Normal/Roughness sintetizate pretins dintr-o imagine.
- Grafică Auto/Redusă/Echilibrată/Ridicată. Auto reduce efectele dacă FPS observat scade sub 48 și încearcă recuperarea peste 58, cu pauze între schimbări. Nu poate depăși limitele hardware, setarea FPS sau limitele platformei.
- HUD afișează FPS și p95 frame time pe fereastra recentă; nu transmite aceste date pe server. Efecte reduse și luminozitate sporită sunt disponibile separat.

## Matrice de măsurare

Completează `docs/performance-results.csv` cu rezultate reale. Profilarea se face după încălzire și streaming inițial, minimum 5 minute/scenariu. Nu folosi un singur calculator care simulează 50 de clienți pentru a pretinde performanța unui server real cu 50 de dispozitive.

| Scenariu | Număr de clienți | Ce urmărești |
|---|---:|---|
| Explorare singur / streaming între zone | 1 | Harta, join time, stutter, memorie |
| Piață și schimbare zi/noapte | 10 / 25 / 50 | Frame time, lumini, rețea, heartbeat server |
| Luptă simultană / capturare / relocare | 10 / 25 / 50 | CPU, input latency, ancore, raycast-uri |
| Intrare/ieșire / autosave / shutdown | 50 | Throttling DataStore, lease, pierderi de date |
| Telefon modest / mediu / PC / Xbox / PlayStation | După capacitate | Grafică Auto și manuală, cameră, HUD |

Prag orientativ pentru o experiență apropiată de 60 FPS: p95 frame time în jur de **16,7 ms**, fără vârfuri repetate peste 33 ms după încălzire. Pentru scene încărcate urmărește și p99 în MicroProfiler; numărul mediu FPS singur poate ascunde blocări. Notează dispozitivul, setarea Roblox, temperatura și limita FPS. Pe un dispozitiv care nu poate atinge ținta, prioritizează stabilitatea și lizibilitatea prin nivelul Redus.

## Ce împiedică declararea unei versiuni de lansare

Import și rulare în Studio; încărcarea și moderarea texturilor; testarea cu 50 de clienți reali; teste pe dispozitive; verificarea achizițiilor și salvărilor; playtest pentru balans și accesibilitate; remedierea problemelor observate. Fără aceste rezultate versiunea rămâne pre-release, chiar dacă verificările locale trec.

Referințe oficiale:
- https://create.roblox.com/docs/performance-optimization
- https://create.roblox.com/docs/performance-optimization/improve
- https://create.roblox.com/docs/performance-optimization/microprofiler
