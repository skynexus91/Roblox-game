# Hunting, sanctuary and world life — 30 October 2026

## Gameplay

- Live rounds now have **8-minute days and 6-minute nights**, up to three cycles (42 minutes before preparation/results, unless a team wins early). Solo exploration uses the same longer day/night durations. Studio bot practice deliberately retains 20-second phases for testing.
- Humans wear a blue hunter tunic, leather belt, shoulder detail and silver insignia. Vampires gain a crimson mantle/cape, pale complexion, red eyes and small fangs at night or while revealed. Unrevealed vampires retain the common daytime disguise so the investigation mechanic still works. All factions receive the same six inventory tools; inventory does not identify a secret role.
- **Crucifix:** human-only, 12-stud range, 12-second weapon cooldown; reveals and immobilizes a vampire for 3 seconds. No direct damage. Also repels hostile helper creatures.
- **Holy Water:** human-only, 18-stud range, 8-second weapon cooldown; 18 damage and 12-second reveal. Works by day or night. Reusable vial governed by cooldown; no ammunition or purchase requirement.
- **Wooden Stake:** human-only, 6-stud range, 2-second weapon cooldown. Subdues a vampire at 25 HP or lower, during the weakened window, or when revealed during daytime. Otherwise deals 8 nonlethal damage. Healthy hidden vampires cannot be instantly captured. Captured players remain in their round's crypt.
- Weapons share a server-controlled weapon cooldown, preventing cooldown bypass by swapping tools. Holy tools still require facing, line of sight, enemy faction and a live active participant.
- The **Sunward Chapel church** protects humans inside its marked interior. PvP cannot enter or leave the sanctuary. Vampires are moved outside consecrated ground; it is a refuge rather than an attack platform. The central aisle has pews and an altar instead of household furniture.
- Ten ambient animals: three deer, three rabbits and four chickens, with small bounded roaming paths. Ambient wildlife is not a combat target or source of rewards.
- Two night hounds assist vampires at night. Humans can defeat them with weapons. Helpers cannot infect, capture, affect player counts, occupy crypt slots or determine victory; defeating them awards no farmable XP/gold.
- Server **round-win scores** determine comeback support at the next round's start. If vampires lead, Father Alden appears at the church and restores up to 12 HP every 8 seconds to nearby active humans within 20 studs. If humans lead, an additional Crimson Bat assists vampires at night. Ties receive no bonus helper. Practice uses separate temporary scores and does not change the live score.
- Hounds deal 5 nonlethal damage per 6 seconds; the bat deals 8 per 5 seconds. Range, sanctuary and line of sight are checked. Helpers clear between phases/results; hounds and bat return at the next night. These are small support NPCs, not extra players.
- Vampire hit feedback uses five brief red flecks, with a local cap of 24, 100-stud visibility distance and automatic cleanup after 0.4 seconds. No persistent stains or gore. Reduced Effects suppresses the red flecks.

## Verification

- 42 local tests pass, covering support selection, sanctuary bounds/faction protection, holy-tool faction/range/phase restrictions, stake thresholds and longer configured cycles, plus the existing 36 regressions.
- Studio loaded the six-tool inventory, Hunter outfit and ten animals without game-script errors.
- Controlled server fixtures verified: healthy hidden stake attack cannot finish; Holy Water damages/reveals; Crucifix stuns; daytime revealed stake capture and nighttime weakened stake capture succeed.
- Church fixture: a protected human's outward attack and a vampire's inward feeding attack were blocked. With vampires ahead, the priest healed a bot from 50 to 74 HP during an 8.5-second sample.
- Score fixtures verified Priest, Bat and tied-score behavior. Two hounds spawned at night; a bat made three hostile helpers when humans led. The bat was defeated by three sword hits. Team counts remained three humans/one vampire, excluding helper NPCs.
- Client observed five red flecks on a vampire hit, none on the next hit with Reduced Effects enabled, and zero lingering fleck parts after cleanup.
- Human appearance, vampire night appearance and hidden daytime disguise were checked in Studio.

Controlled tests use the existing Studio-only ServerStorage fixture, including forced phase/score and staged actor positions. They are not proof of a full uninterrupted 42-minute live round. Earlier failed fixture attempts used stale roles after a new round; tests were rerun using current-round actors and passed. Live multi-client balance, real device/load tests and published-service validation remain open.

Scores are per-server round wins, not a persistent/global leaderboard. Safe-zone rules are not a complete movement anti-cheat. The changes are saved in the local place and source; publication must be verified separately against the experience's actual start place.
