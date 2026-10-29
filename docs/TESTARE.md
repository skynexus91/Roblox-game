# Verificări înainte de lansare

Toate scenariile de mai jos sunt **de executat în Roblox Studio sau pe dispozitive reale**. Nu sunt bifate ca trecute.

## Import și rundă

- Deschide `.rbxlx`; confirmă că harta este vizibilă înainte de Play și că nu există erori în Output.
- Cu 1 client, runda nu pornește. Cu 2, pauza de 15 secunde precedă runda. Repetă cu 4 și cu 8.
- Verifică mutarea din lobby în cele 8 puncte, accesul în case, coliziunile, acoperișurile, iluminarea de noapte și lizibilitatea HUD.
- Confirmă că exact un participant începe vampir și ceilalți nu îi văd rolul ascuns ziua.
- Verifică zi 100s, noapte 80s, maximum 3 cicluri și revenirea în lobby după rezultat.
- Un participant nou intră în lobby și nu influențează victoria până la următoarea rundă.

## Abilități și rezultat

- Ziua: investigarea unui om produce mesaj de om; a unui vampir dezvăluie pentru 15s; a unui infectat arată infecția.
- Capturarea funcționează numai ziua asupra unui vampir dezvăluit. Testează și după expirarea celor 15s.
- Noaptea: hrănirea modifică sănătatea, dar nu ucide. Infectarea este limitată la 1/vampir/noapte.
- Infectatul rămâne om în ziua următoare și se transformă la apus. După a treia noapte se aplică regula de supraviețuire din README.
- Vampirul nou primește comenzile corecte și propria utilizare de infectare la transformare.
- Testează capturarea ultimului vampir, transformarea ultimului om, expirarea rundei, deconectarea ultimului om/vampir și plecarea tuturor.
- Reset/deces: jucătorul nu poate reintra liber în aceeași rundă; următoarea rundă îl eliberează.
- Verifică distanțe >10 studs, obstacole între personaje, trimiterea rapidă a cererilor și roluri nepotrivite. Acțiunile trebuie respinse de server.

## Platforme

| Mediu | Verificări de făcut |
|---|---|
| PC | WASD, mouse, salt, E/Q/F, ferestre mici și mari |
| Android/iOS | Joystick, cameră tactilă, salt, cele 3 butoane, peisaj/portret, interfață fără suprapuneri |
| Controller în Studio | Mișcare, cameră, X/Y/B, trecere tastatură-controller |
| Xbox real | Aceleași acțiuni, ecran TV și margini sigure, participare multiplayer |
| PlayStation real | Pătrat/Triunghi/Cerc, cameră, ecran TV, participare multiplayer |

Măsoară performanța pe un telefon modest și cu 8 participanți. Ajustează umbrele, luminile și HUD pe baza măsurătorilor, nu pe presupuneri. Folosește emularea dispozitivelor pentru prima trecere, apoi dispozitive reale.

## Publicare

După corectarea erorilor: verifică drepturile asupra activelor adăugate ulterior, completează informațiile și chestionarele cerute de Roblox conform conținutului efectiv, selectează dispozitivele validate și publică din contul proprietarului. Nu declara consola sau mobilul testate doar fiindcă inputurile există în cod.
