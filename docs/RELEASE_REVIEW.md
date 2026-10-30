# Release review — 30 October 2026

Latest bot/host-join revision: **29 local tests**, bot round tests with up to 12 NPCs, and a player-facing Multiplayer menu. See [BOTS_AND_MULTIPLAYER.md](BOTS_AND_MULTIPLAYER.md) for current evidence and live-service limitations. Counts and checks below describe the earlier village revision.

## Changes

- Market-centred village with bent lanes, houses facing the street, fenced vegetable plots, market stalls, a mill pond and bridge, farm fields and a chapel. Monastery access runs between the crypts rather than through a jail. House interiors have benches and beds. Trees use deterministic irregular spacing.
- Inn contracts: accept during daytime, collect three different supply crates at market/mill/farm, return within 180 seconds for 80 XP and 40 gold. Duplicate pickups do not count; successful contracts have a 180-second cooldown.
- Dawn investigation: read the chapel inscription by day, then activate the monastery seal at night for 120 XP and 60 gold. Five-minute personal cooldown. These activities do not expose secret PvP roles.
- Cooking: collect two herbs and use the inn hearth to recover up to 25 HP, with a 45-second cooldown. It does not cure infection.
- Solo exploration alternates day/night every 120 seconds. Multiplayer keeps its existing round timings. Short-range, occluded location labels support streamed areas.
- Fixed unpublished Studio startup: disposable profiles never request a DataStore. Windows and water use glass instead of emissive neon.

## Validation

- 19 Python/Lua tests pass, including contract uniqueness/expiry, ritual phase/cooldown, cooking resource consumption, DataStore initialization regression, combat restrictions and existing round rules.
- All 14 Lua sources parse, and generated place validation passes: 1,481 total instances, 50 distinct round spawns, five crypts, new activity nodes, streaming and embedded source parity.
- Studio: initial revision loaded without script errors. A real player completed the three supply prompts and inn delivery: gold increased 0 -> 40. Day clue followed by night shrine prompt increased gold 40 -> 100. Phase flags were explicitly set for that targeted ritual test; it was not a full timed cycle test.
- Final regenerated file reopened in Studio and started without errors. Used the lobby portal, walked to two herb nodes and harvested them, then cooked at the inn hearth. The hearth consumed the ingredients and restored 25 HP (50 -> about 76 including default Roblox regeneration). The revised HUD and streamed labels appeared. A final village screenshot showed 60 FPS, p95 22.2 ms, quality level 3; this is a single-client observation, not a load benchmark.
- Profiling: 128 captured frames reported mean CPU tick duration about 16.67 ms; complete render-step callbacks averaged about 0.011 ms/frame. The visible HUD also reported about 15 FPS during background operation. Sleep scopes were substantial; inclusive CPU scope durations overlap and do not establish GPU render performance. This is not a 60 FPS certification.

## Remaining release gates

- Real two-client round test (role privacy, damage, infection, capture, round reset and reconnect).
- Foreground client/device benchmarks and a 50-player load test.
- Published test experience: DataStore save/rejoin/lease/shutdown and failure handling against real Roblox services.
- Mobile/controller UI and interaction checks on real devices.
- Creator Dashboard: maximum players 50, supported devices, content maturity questionnaire and audience eligibility. Account-only attestations must be completed by the owner.
- Custom texture IDs and cosmetic pass IDs remain zero; built-in materials work and purchases remain disabled.

The file is a candidate for private Roblox testing. It is not certified as a public launch or a finished MMORPG.
