# Bots and multiplayer — acceptance report, 30 October 2026

## How to use

Open `Satul_dupa_Apus.rbxlx` in Studio and press Play. Open **Multiplayer** with the on-screen button, **M**, or the controller Select button. The Studio bot button cycles **0 / 3 / 7 / 12** NPC participants. A change during a round is queued for its end. Bots start disabled and are available only in Studio.

Practice preparation lasts 5 seconds, with 20-second days and nights, up to three cycles. These NPCs move using pathfinding, investigate/capture during daytime and fight/feed/infect at night. They are explicitly named BOT. They are valid targets for player combat, investigation, capture and spectator cameras. Their hidden role is kept in the server state table. Practice rounds award no round XP or gold. Ordinary PvE rewards are still available to the real player.

In a published Roblox experience, **Host** reserves a private session and teleports the host. Share the eight-character join code with friends; **Join** resolves that code server-side and teleports the joining player. Codes expire after two hours. Reserved-server access tokens are never returned to clients. Hosting retries reuse an existing unexpired reservation when teleport initiation fails. Friend invitations open Roblox's native invitation prompt; share the session code as well, since the invitation itself may enter the public experience.

In Studio, Host/Join reports that a published experience and Roblox client are required. It does not pretend a teleport succeeded. The bot practice option is separate from live host/join.

## Executed Studio checks

- Actual Multiplayer menu button enabled three bots. One real player plus three bots entered a practice round.
- Daytime infection was rejected. A villager bot investigated a vampire, which became revealed; capture put it in crypt 1 and ended the round.
- At night, a vampire bot infected a human bot. Feeding reduced target health to 80 and restored attacker health; claws then reduced target health to 61. The infected actor became a vampire at the next dusk in the same round.
- Resumed autonomous AI. Three bots moved approximately 18–23 studs in a six-second sample, fought and infected targets, and later completed a capture round without scripted action calls.
- One real player plus twelve bots started with **two vampires and two crypts**. Corrected a startup race by preventing roster selection while bots are being created.
- Client actor list included the NPCs; server-only test hooks were absent from the client. No public vampire-role attribute was present.
- Requested zero bots during a running round. Request was queued, then all bots were removed after the result phase. The real player returned to inactive, uncaptured exploration with zero round gold.
- Menu was visually checked; fixed control ordering, overlay priority and oversized rows that pushed bot controls below the visible area.
- Studio Host request returned the explicit unsupported-environment message. No game-script errors appeared in the final Output checks.

Controlled combat checks used a Studio-only BindableFunction in ServerStorage to stage NPC pairs and call the same action handler used by real players. These hooks are not created on published servers. Automated staging and accelerated movement are test instrumentation, not proof that normal-speed navigation and multiplayer latency are fully validated.

## Local tests

29 Lua/Python tests pass. Bot decisions and count validation are tested; session-routing mocks cover hosting, code normalization, joining, expiry, rate limiting, private-token non-disclosure, retry after teleport failure and Studio rejection. Existing combat, quest, save-lock, cooldown and layout checks also pass. Mock routing tests do not contact Roblox's live services.

## Still requires published testing

Real Host -> private-server arrival -> second account Join, MemoryStore service permissions/throttling, teleport failure/retry across real servers, private-server code display, native invitations, live profile handoff/save/rejoin, real two-client role privacy and gameplay replication, mobile/controller checks and load/device benchmarks. NPC participants do not emulate independent network clients or 50 real players.

Status: bot practice has passed the checks above. The host/join implementation is present and locally tested; live multiplayer connection is **not yet confirmed**.
