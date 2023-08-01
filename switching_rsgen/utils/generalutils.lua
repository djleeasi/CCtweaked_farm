local generalutils = {}

local function generalutils.nilCheck(varName, varValue, errmsg)
    if varValue == nil then
        if errmsg == nil then
            error(varName .. " is nil")
        else
            error(varName .. " : " .. errmsg)
        end
    end
    return  varValue
end

local function generalutils.isEmpty(t)
    return next(t) == nil
end

return generalutils