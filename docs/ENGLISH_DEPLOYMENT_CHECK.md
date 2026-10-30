# English build — deployment check, 30 October 2026

The in-game title is **Village After Dusk**. The existing `.rbxlx` filename is retained so existing project links and build commands continue to work.

## Completed

- English building names and signs, landmarks, objects and wayfinding labels. Examples: The Raven Inn, Blacksmith's House, Old Mill, Crossroads Farm, Sunward Chapel and Monastery of Light.
- English weapon inventory, interaction prompts, quests, contracts, rituals, cooking, HUD, specializations, graphics/accessibility settings, cosmetics, host/join menu and failure messages.
- Leaderboard columns renamed to Level and Gold. Existing saved specialization IDs and round phase/role IDs remain compatible; separate English display names are used.
- Removed winner-reward dependence on translated victory messages. Winner rewards now follow a tested rule based on remaining teams.
- 36 local tests: all previous regression tests plus English text/sign coverage, all four quest completions and repeat behavior, upgrades/healing, English specialization notices, saved-class compatibility and language-independent winner selection.
- Generated-place checks: source parity, syntax, streaming, 50 distinct spawns, five crypts, activity nodes and the clear monastery path.

## Studio checks executed on the English build

- Fresh startup, loaded profile, English inventory and Level/Gold leaderboard; all 56 interaction prompts inspected.
- Read HUD text, graphics settings, cosmetic catalogue and multiplayer menu from the client. Checked the menu screenshot and adjusted long message text to fit its existing space.
- Entered the village through the portal and accepted the herb quest using actual prompt input. The notice was “Gather 5 herbs in the southwestern forest”.
- Enabled three bots through the session remote; practice round started with four actors. Investigated and captured the vampire via the same server action handler, then checked English Results/Vampire or Villager presentation. Captured players correctly retain a personal capture notice temporarily instead of the global victory message.
- Final fresh run of the revised winner rules reached Results with zero practice gold. Studio Host returned its English published-experience requirement. Final Output was empty.

Earlier bot acceptance tests also covered night feeding, claws, infection, next-dusk transformation, autonomous movement, round reset, queued bot removal and 12-bot crypt scaling. See BOTS_AND_MULTIPLAYER.md; these were not repeated as a new 50-player load test.

## Public deployment gates still open

Host -> reserved server -> second-account Join and invitations require a published experience and real Roblox clients. Live save/rejoin/teleport handoff, real-client role privacy/replication, mobile/controller checks and device/load benchmarks remain unverified. Roblox audience/content settings also need review in the owner's account. A passing Studio/local suite does not certify those checks.

The saved English artifact is ready for a **private published test**. Public release is not yet certified, and no Roblox publication is claimed by this report.
