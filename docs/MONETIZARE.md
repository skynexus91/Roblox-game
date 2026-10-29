# Activarea magazinului cosmetic

Integrarea este pregătită, dar nu au fost create game pass-uri sau stabilite prețuri în contul Roblox. Fără ID-uri valide, butoanele sunt indisponibile și nu deschid achiziții.

1. Publică mai întâi experiența de test din Studio, sub proprietarul care trebuie să primească veniturile.
2. În Creator Dashboard → experiența ta → Monetization → Passes, creează pass-uri pentru Lanterna aurie, Aura lunii și Susținător al satului. Descrierile trebuie să corespundă efectelor din README.
3. Configurează vânzarea și prețul fiecăruia în dashboard. ID-ul pass-ului nu este ID-ul imaginii sale. Prețurile și disponibilitatea pot varia; jocul le citește de la Roblox, fără sume Robux scrise în UI.
4. În `src/MonetizationConfig.lua`, înlocuiește fiecare `id=0` cu ID-ul pass-ului corespunzător, care aparține experienței tale. Păstrează cheile `GoldenLantern`, `MoonAura`, `Supporter`.
5. Rulează generatorul și verificările, deschide noul `.rbxlx` și publică actualizarea în experiența corectă.
6. Testează anularea, erorile, deținerea anterioară, efectele după respawn/reconectare și controlul cu telefon/gamepad. Nu presupune că testarea în Studio dovedește o tranzacție reală. O achiziție live autorizată separat consumă Robux.

Nu se acordă aur, XP sau putere pentru aceste achiziții. Serverul verifică proprietatea prin `UserOwnsGamePassAsync`; numai serverul acordă efectele. Nu există un remote de „acordare pass”. După o eroare de verificare nu se acordă drepturi; reconectarea reia verificarea. Game pass-urile sunt achiziții unice; nu sunt produse consumabile repetabile și nu necesită `ProcessReceipt`.

## Cine câștigă Robux

Cumpărătorul cheltuiește Robux pentru cosmeticul descris; creatorul experienței poate primi venituri din vânzări. Sumele nete, comisioanele, perioada pending, eligibilitatea și eventuala conversie prin DevEx sunt stabilite de Roblox, nu de codul jocului. Nu este promis un venit sau un procent net.

Jocul nu transferă Robux către jucători, nu convertește aurul în Robux și nu include loterii sau recompense Robux. O astfel de funcție nu poate fi simulată credibil printr-un contor local.

Surse oficiale consultate la 29 octombrie 2026:

- https://create.roblox.com/docs/production/monetization/passes
- https://create.roblox.com/docs/production/monetization/regional-pricing
- https://create.roblox.com/docs/reference/engine/classes/MarketplaceService
