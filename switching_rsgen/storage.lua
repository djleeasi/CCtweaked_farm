local Inventory_storage = require("customization.customenv").Inventory_storage
local utils = require("utils.generalutils")
local tableutils = require("utils.tableutils")

local Storage = {}

local function Storage:new(config)
    --set Class variable
    self.recording_interval = utils.nilCheck("config/INTERVAL_RECORDING",config["INTERVAL_RECORDING"])
    --set instance
    local storage_instance = {}
    storage_instance.inventory = Inventory_storage.new()
    storage_instance.tunnel = nil
    storage_instance.templates = nil
    --set Metatable
    setmetatable(storage_instance, self)
    self.__index = self
    return storage_instance
end

local function Storage:getTemplates()
    --this Class shares list of resources with template
    --TODO:Check if synchronization works
    nilCheck("tunnel", self.tunnel)
    while not self.templates do
        self.templates = self.tunnel.template.templates--wait until the template initialize templates
        sleep(5)
    end
end

local function Storage:generate_rank()
    local list_exist = {}
    local zero_list = {}
    local exist_list = {}
    local sorted = tableutils.sortTableByIndex(self.inventory.inventory,"quantity", true)
    for index , item in ipairs(sorted) do
        local itemname = item.name
        table.insert(exist_list, itemname)
        list_exist[itemname] = index
    end
    for itemname, _ in self.templates do
        if not list_exist[itemname] then
            table.insert(zero_list,itemname)
        end
    end
    for _, itemname in ipairs(exist_list)
        table.insert(zero_list, itemname)
    end
    return zero_list
end
