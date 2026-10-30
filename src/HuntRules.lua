local Rules={}
function Rules.Support(humanScore,vampireScore)
 if vampireScore>humanScore then return 'Priest' end
 if humanScore>vampireScore then return 'Bat' end
 return 'None'
end
function Rules.InSanctuary(x,y,z)
 return x>=44 and x<=66 and y>=0 and y<=23 and z>=-166 and z<=-134
end
function Rules.Protected(vampire,x,y,z)
 return not vampire and Rules.InSanctuary(x,y,z)
end
function Rules.StakeFinishes(phase,health,revealed,weakened)
 return health<=25 or weakened or (phase=='Zi' and revealed)
end
return Rules
