--[[
in_Game Components of managing program
1: interface of AE2, or some kind of stroage-merging mod
    
2: resource-generating system
3: template storage
    holds resource template
    when provided name of resource, it can provide information of how to set the resource generating system.
    non-accesible by interface
4: resource storage
    holds resources
    records statistics of resource change
    requests change of resource generation environment periodically
    all slots of resource storage are accesible by interface

What this module do

connects each components, and control overall operation
]]--

--main.lua

local class_manage = {}
local function class_manage:init(resource_storage, template_storage, generating_system)
    self.__index = self
    local instance = {}
    instance.resource_storage = 
    setmetatable(instance, self)
    return instance
end

-- local function class_manage:

--WIP