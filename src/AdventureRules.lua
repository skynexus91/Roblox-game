-- Pure rules shared by server progression and deterministic tests.
local Rules={}
function Rules.ContractExpired(started,now)
 return started~=nil and now-started>=180
end
function Rules.CanDeliver(started,now,packages)
 return started~=nil and not Rules.ContractExpired(started,now) and packages>=3
end
function Rules.CanRitual(clue,night,now,readyAt)
 return clue==true and night==true and now>=(readyAt or 0)
end
return Rules
