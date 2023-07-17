--[[
    Minecraft world components
        required mods
            Drawer_like mode
            CC:tweaked
            Botanypots
            Applied Energistics 2
        blocks
            A CC:Tweaked computer
            Botanypots
            Soil Storage Drawer
            Product Storage Drawer
                Slot 1: Main Product template
                    holds only one item
                Slot 2: Soil template
                    holds only one Soil
                Slot 3: Seed template
                    holds only one seed
                --slot 4 and thereafters, each drawers are conntected to an individual AE2 storage bus. this may waste channels. you should get over it.
                Slot 4: all products
                slot 5: all seeds
                slot 6~: byproducts

]]
local TYPE_DRAWER_CONTROLLER = "functionalstorage:storage_controller"
local TYPE_SOILCONTAINER = TYPE_DRAWER_CONTROLLER --if item in the first slot is insanium farmland, then it is a soil container
local SOILCONTAINER_FILTER = "mysticalagradditions:insanium_farmland"
local TYPE_BOTANY_POT = "botanypots:botany_pot"
local TYPE_INTERFACE = "ae2:interface"
local REPLANTATION_DELAY = 200 --seconds
local DEPOSIT_DELAY = 10 --seconds

--table utils
local function sortTable(tbl, index, ascending)
    table.sort(tbl, function(a, b) 
        if ascending == true then
            return a[index] < b[index]
        else--descending
            return a[index] > b[index]
        end
    end)
    return tbl
end

local function keyTable(tbl, index)
    local result = {}
    for _, item in pairs(tbl) do
        result[item[index]] = item
        sleep(0)
    end
    return result
end

local function isEmpty(t)
    return next(t) == nil
end

local function zipNameHandles(type, filterfunc)
    --Handle is a tuple of (name, methods)
    local names = nil
    if filterfunc == nil then 
        names = peripheral.find(type)
    else
        names = peripheral.find(type, filterfunc)
    end
    local result = {}
    for i =1, #names do
        result[i] = {names[i], peripheral.wrap(names[i])}
        sleep(0)
    end
    return result
end

local function nilCheck(varName, varValue, errmsg)
    if varValue == nil then
        if errmsg == nil then
            error(varName .. " is nil")
        else
            error(varName .. " : " .. errmsg)
        end
    end
end

--Scan is a table of (infos, unpacked_handle)
local function controllerScan(controllerhandles)
    --[[
        1: Main_Product
        2: main_product_count
        3: Soil
        4: Seed
        5: Seed_count
        6: Controller_name
        7: methods
        ]]--
    local result = {}
    for _, controllerhandle in pairs(controllerhandles) do
        local itemlist = controllerhandle[2].list()
        --main_product
        local main_product = itemlist[1]
        nilCheck("main_product", main_product, "the main product assigning slot is empty")
        local main_product_name = main_product.name
        local main_product_count = 0
        if itemlist[4] ~= nil then
            main_product_count = itemlist[4].count
        end
        --soil
        nilCheck("soil", itemlist[2], "the soil assigning slot is empty")
        local soil_name = itemlist[2].name
        --seed
        local seed = itemlist[3]
        nilCheck("seed", seed, "the seed assigning slot is empty")
        local seed_name = seed.name
        local seed_count = 0
        if itemlist[5] ~= nil then
            seed_count = itemlist[5].count
        end
        local toinserted = {main_product_name, main_product_count, soil_name, seed_name, seed_count , controllerhandle[1], controllerhandle[2]}
        table.insert(result,toinserted)
        sleep(0)
    end
    return result
end

local function soilcontainerScan(soilcontainerhandle) --single container!!!
    --(Soil, Quantity, slot)
    local result = {}
        local itemlist = soilcontainerhandle[2].list()
        for slotindex, item in pairs(itemlist) do
        local toinsert = {item.name, item.count, slotindex}
            table.insert(result, toinsert)
            sleep(0)
        end
    end

local function botanypotScan(botanypothandles)
    --(Soil, Seed, pot_name, methods)
    local result = {}
    for _, botanypothandle in pairs(botanypothandles) do
        local itemlist = botanypothandle[2].list()
        local soil = itemlist[1]
        local seed = itemlist[2]
        if soil ~= nil and seed ~= nil  then
            local toinserted = {soil.name, seed.name, botanypothandle[1], botanypothandle[2]}
            table.insert(result,toinserted)
        else
            --assume all pots are valid(all pots are either empty or both soil and seed are present)
            local toinserted = {nil, nil, botanypothandle[1], botanypothandle[2]}
            table.insert(result,toinserted)
        end
        sleep(0)
    end
    return result
end

--Action functions
local function cleanAPot(botanypothandle, soilcontainername, controller_keyed_byseed)
    local botanypotmethods = botanypothandle[2]
    local itemlist = botanypotmethods.list()
    if not isEmpty(itemlist) then
        local soil = itemlist[1]
        local seed = itemlist[2]
        botanypotmethods.pushItems(soilcontainername, 1)
        if seed ~= nil then
            local controller = controller_keyed_byseed[seed.name]
            if controller == nil then
                error("the seeds in a pot has no place to go!!!")
            end
            botanypotmethods.pushItems(controller[5], 2, 1, 1)
        end
    end
end

local function cleanpots(botanypothandles, soilcontainername, controller_keyed_byseed, cleanall)
    if cleanall == true then
        for i=1, #botanypothandles do
            cleanAPot(botanypothandles[i], soilcontainername, controller_keyed_byseed)
            sleep(0)
        end
    else
        --clean only unvalid pots
        for i=1, #botanypothandles do
            local itemlist = botanypothandles[i][2].list()
            if not isEmpty(itemlist) then
                local soil = itemlist[1]
                local seed = itemlist[2]
                if soil ~= nil or seed ~= nil  then --instead of implementing xor, the cleatApot does nothing if both are nil
                    cleanAPot(botanypothandles[i], soilcontainername, controller_keyed_byseed)
                end
            end
            sleep(0)
        end
    end
end

local function plantSeed(controllerhandle, botanypothandle, soilcontainerhandle, controller_keyed_byseed)
    --first clean the pot
    cleanAPot(botanypothandle, soilcontainerhandle[1], controller_keyed_byseed)
    --then plant the seed
    local soilname = controllerhandle[3]
    local controllermethods = controllerhandle[2]
    local seedstack = controllermethods.list()[5]
    local soilstack = keyTable(soilcontainerScan(soilcontainerhandle),1)[soilname]
    if soilstack == nil or seedstack == nil then
        --not plantable
        return false
    else
        local sentsoils = soilcontainerhandle.pushItems(botanypothandle[1], soilstack[3], 1, 1)
        local sentseeds = controllermethods.pushItems(botanypothandle[1], 5, 1, 2)
        if sentsoils*sentseeds == 0 then
            --plantation failed!!
            error("plantation failed!!")
        else
            return true
        end
    end
end


local function deposit()
    local botanypothandles = zipNameHandles(TYPE_BOTANY_POT)
    local interfacehandle = zipNameHandles(TYPE_INTERFACE)[1]
    while true do
        for index, botanypothandle in pairs(botanypothandles) do
            local itemlist = botanypothandle.list()
            for slot, value in pairs(itemlist) do
                if slot>2 then
                    botanypothandle.pushItems(interfacehandle[1], slot)
                end
                sleep(0)
            end
            sleep(0)
        end
        sleep(DEPOSIT_DELAY)
    end
end

local function soilContainerFileter(name, wrapped)
    if wrapped.list()[1].name == SOILCONTAINER_FILTER then
        return true
    else
        return false
    end
end

local function manage()
    local botanypothandles = zipNameHandles(TYPE_BOTANY_POT)
    local controllerhandles = zipNameHandles(TYPE_DRAWER_CONTROLLER)
    local soilcontainerhandle = zipNameHandles(TYPE_SOILCONTAINER, soilContainerFileter)[1]
    while true do --infinite loop
        local controller_scan = controllerScan(controllerhandles)
        local controller_keyed_byseed = keyTable(controller_scan, 4) --key is seed name
        --make sure all pots are valid
        cleanpots(botanypothandles, soilcontainerhandle[1], controller_keyed_byseed, false)
        controller_scan = controllerScan(controllerhandles) --scan again
        --sort storage_table in ascending order of quantity
        controller_scan = sortTable(controller_scan, 2, true)

        local botanypot_scan = botanypotScan(botanypothandles)
        --sort botanypot also. the sorting order is most unwanted to most wanted
        local botanypot_sorted = {}
        --empty pots first
        for index, apot in pairs(botanypot_scan) do
            if apot[2] == nil then
                table.insert(botanypot_sorted, apot)
                botanypot_scan[index] = nil
            end
            sleep(0)
        end
        local botanypot_scan_seedkeyed = keyTable(botanypot_scan, 2)
        local number_controllers = #controller_scan
        for index = 1,  number_controllers do
            for index, apot in pairs(botanypot_scan) do
                if apot[2] == controller_scan[number_controllers-index][4] then
                    table.insert(botanypot_sorted, apot)
                    botanypot_scan[index] = nil
                end
                sleep(0)
            end
            sleep(0)
        end
        if not isEmpty(botanypot_scan) then
            error("not all pots are sorted")
        end
        --now start planting seeds
        controller_keyed_byseed = keyTable(controller_scan, 4)
        local processed_pots = 0
        local total_pots = #botanypot_sorted
        local mostwanted_index = 1
        while processed_pots < total_pots do
            local wantedcontroller = controller_scan[mostwanted_index]
            if wantedcontroller == nil then
                --no more wanted controller
                break 
            end
            local wantedseedname = wantedcontroller[4]
            --remove already planted pots from the table
            for index, pot in pairs(botanypot_sorted) do
                if pot[2] == wantedcontroller[4] then
                    processed_pots = processed_pots + 1
                    botanypot_sorted[index] = nil
                end
                sleep(0)
            end
            for index, pot in pairs(botanypot_sorted) do
                --plant seed
                local planted = plantSeed(wantedcontroller, pot, soilcontainerhandle, controller_keyed_byseed)
                if planted == true then
                    processed_pots = processed_pots + 1
                    botanypot_sorted[index] = nil
                else--current crop is unplantable. change wanted crop.
                    mostwanted_index = mostwanted_index+1
                    break
                end
                sleep(0)
            end
        end
        sleep(REPLANTATION_DELAY)
    end
end

local function main()
    parallel.waitForAll(manage,deposit)
end

main()