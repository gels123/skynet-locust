--[[
	数据中心接口
]]
local skynet = require("skynet")
local svrAddrMgr = require("svrAddrMgr")
local publicRedisLib = require("publicRedisLib")
local playerDataLib = class("playerDataLib")

-- 服务数量
playerDataLib.serviceNum = 16
-- 业务ID关联王国KID的redis哈希
playerDataLib.redisHashKidOfId = "gamedata_hash_id2kid"
playerDataLib.cacheKidOfId = {}

-- 根据id返回服务id
function playerDataLib:svrIdx(id)
	return (id - 1) % playerDataLib.serviceNum + 1
end

-- 获取地址
function playerDataLib:getAddress(curKid, id)
    if not playerDataLib.addr then
        playerDataLib.addr = svrAddrMgr.getSvr(svrAddrMgr.dataCenterSvr, curKid, self:svrIdx(id))
    end
    return playerDataLib.addr
end

--[[
    查询
    @curKid         [必填]传本王国ID
    @id             [必填]数据ID
    @module         [必填]数据名
    @multi          [选填]根据多个条件查询
    @isForce        [选填]查询跨服数据时, 是否强制查询
    示例:
        1. playerDataLib:query(1, 1201, "lordinfo")
]]
function playerDataLib:query(curKid, id, module, multi, isForce)
    Log.d("playerDataLib:query", curKid, id, module, multi, isForce)
    return skynet.call(self:getAddress(curKid, id), "lua", "query", id, module, multi, isForce)
end

--[[
    更新
    @curKid         [必填]传本王国ID
    @id             [必填]数据ID
    @module         [必填]数据名
    @data           [必填]数据
    @multi          [选填]是否复杂更新: 为true时, 可同时更新多个字段, data中非空字段都需要传
]]
function playerDataLib:update(curKid, id, module, data, multi)
	return skynet.call(self:getAddress(curKid, id), "lua", "update", id, module, data, multi)
end

--[[
    更新(异步)
    @curKid         [必填]传本王国ID
    @id             [必填]数据ID
    @module         [必填]数据名
    @data           [必填]数据
    @multi          [选填]是否复杂更新: 为true时, 可同时更新多个字段, data中非空字段都需要传
]]
function playerDataLib:sendUpdate(curKid, id, module, data, multi)
	return skynet.send(self:getAddress(curKid, id), "lua", "sendUpdate", id, module, data, multi)
end

--[[
    删除
    @id             [必填]数据ID
    @module         [必填]数据名
    @multi          [选填]根据多个条件删除
    示例:
        1. playerDataLib:delete(1, 1201, "lordinfo")
        2. playerDataLib:delete(1, 1201, "lordinfo", {id = 1201, })
]]
function playerDataLib:delete(curKid, id, module, multi)
	return skynet.call(self:getAddress(curKid, id), "lua", "delete", id, module, multi)
end

--[[
    删除(异步)
    @id             [必填]数据ID
    @module         [必填]数据名
    @multi          [选填]根据多个条件删除
    示例:
        1. playerDataLib:sendDelete(1, 1201, "lordinfo")
        2. playerDataLib:sendDelete(1, 1201, "lordinfo", {id = 1201, })
]]
function playerDataLib:sendDelete(curKid, id, module, multi)
	return skynet.send(self:getAddress(curKid, id), "lua", "sendDelete", id, module, multi)
end

-- 执行sql(非安全)
function playerDataLib:executeSql(curKid, id, sql)
    return skynet.call(self:getAddress(curKid, id), "lua", "executeSql", sql)
end

-- 玩家/联盟彻底离线(数据落地)
-- @newKid 迁服时传, 同时删除本地redis数据
function playerDataLib:logout(curKid, id, newKid)
    Log.i("playerDataLib:logout", curKid, id, newKid)
    return skynet.call(self:getAddress(curKid, uid or aid), "lua", "logout", id, newKid)
end

--[[
    获取Id当前所在王国KID
    注：非数据中心调用, global服动态扩容数据迁服时cache可能是错的, 需要传flag=true
]]
function playerDataLib:getKidOfId(curKid, id, flag)
    --Log.d("playerDataLib:getKidOfId=", curKid, id, flag)
    id = tonumber(id)
    if id and id > 0 then
        if flag or skynet.self() ~= self:getAddress(curKid, id) then
            return skynet.call(self:getAddress(curKid, id), "lua", "getKidOfId", id)
        end
        local kid = playerDataLib.cacheKidOfId[id]
        if not kid then
            kid = tonumber(publicRedisLib:hGet(playerDataLib.redisHashKidOfId, tostring(id)))
            if not kid then
                kid = curKid
                self:setKidOfId(id, kid)
            else
                playerDataLib.cacheKidOfId[id] = kid
            end
        end
        return kid
    end
end

-- 设置玩家当前所在王国KID
function playerDataLib:setKidOfId(id, kid)
    -- Log.d("playerDataLib:setKidOfId", id, kid)
    id, kid = tonumber(id), tonumber(kid)
    if id and id > 0 then
        if kid and kid > 0 then
            playerDataLib.cacheKidOfId[id] = kid
            xpcall(function ()
                publicRedisLib:hSet(playerDataLib.redisHashKidOfId, tostring(id), kid)
            end, svrFunc.exception)
        else
            playerDataLib.cacheKidOfId[id] = nil
        end
    end
end

return playerDataLib
