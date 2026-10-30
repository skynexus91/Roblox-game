local Rules={}
function Rules.Code(value)
 if type(value)~='string' or #value>24 then return nil end
 local code=value:upper():gsub('%s','')
 if #code~=8 or not code:match('^[A-F0-9]+$') then return nil end
 return code
end
return Rules
