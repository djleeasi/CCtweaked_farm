
local tableutils = {}

local function tableutils.keyTable(tbl, index)
    --change index of table 
    local result = {}
    for _, item in pairs(tbl) do
        result[item[index]] = item
        
    end
    return result
end

local function tableutils.sortTableByIndex(tbl, index, ascending)
    table.sort(tbl,
        function(a, b) 
            if ascending == true then
                return a[index] < b[index]
            else--descending
                return a[index] > b[index]
            end
        end
    )
    return tbl
end


return testtable