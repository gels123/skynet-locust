local lru_core = require("lru")
local lru = lru_core.new(2)
local ret = lru:set("test1","value1")
lru:set("test2","value2")
lru:set("test3","value3")
print("ret == ",ret)
local ret,err = lru:get("test2")
print("ret == err ",ret,err)
local ret,err = lru:get("test4")
print("ret == err ",ret,err)
lru:dump()