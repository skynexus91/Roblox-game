-- The admission cap must ALSO be set to 50 in Creator Dashboard place settings.
return {
 MinPlayers=2, MaxPlayers=50, Day=480, Night=360, Cycles=3, Intermission=30,
 Range=10, InspectCooldown=20, CaptureCooldown=5, FeedCooldown=8, InfectCooldown=25,
 SaveInterval=90, LockLifetime=300, MaxLevel=30,
 -- Studio uses disposable profiles by default. Never enable API access on live data for tests.
 StudioPersistence=false,
}
