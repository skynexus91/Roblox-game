# Texturi originale — Satul după Apus

Trei imagini generate pentru acest proiect în Higgsfield / FLUX.2 pro la 29 octombrie 2026:

- `limestone_color.jpg` — zidărie de calcar.
- `walnut_color.jpg` — lemn închis.
- `terracotta_color.jpg` — țiglă de teracotă.

Fișierele sunt ColorMap RGB de 512 × 512, comprimate pentru distribuție. Imaginile sursă 1024 × 1024 sunt păstrate în generațiile Higgsfield, identificate în `provenance.json`. Nu sunt materiale PBR complete. Nu declarăm seamless perfect verificat în motor: după repetare în Studio, verifică muchiile și iluminarea inclusă în imagini, mai ales pe lemn.

## Activare în Roblox

1. În experiența proprie, încarcă cele trei imagini prin Asset Manager/Material Manager și așteaptă să fie disponibile/moderate. Un URL Higgsfield sau un fișier GitHub nu poate fi folosit drept `rbxassetid`.
2. Introdu ID-ul de imagine Roblox corespunzător în `roblox_ids.json`, câmpul `color`. Nu introduce ID de pass sau ID-ul paginii unui decal în locul imaginii acceptate.
3. Rulează `python3 build_place.py`. Generatorul creează cele trei MaterialVariant-uri și le aplică familiilor de piese potrivite.
4. Deschide fișierul regenerat în Studio și inspectează clădirile, criptele și acoperișurile zi/noapte. Ajustează StudsPerTile și repetiția dacă este necesar.

ID=0 păstrează materialele Roblox incluse. Această livrare nu pretinde că texturile au fost încărcate în Roblox sau că sunt deja afișate în joc. Prețurile cosmetice și texturile sunt sisteme separate.
