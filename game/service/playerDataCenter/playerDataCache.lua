--[[
    玩家数据中心缓存(本王国数据则同步本地redis)
--]]
local skynet = require("skynet")
local json = require("json")
local svrFunc = require("svrFunc")
local redisLib = require("redisLib")
local playerDataConfig = require("playerDataConfig")
local playerDataCenter = require("playerDataCenter"):shareInstance()
local playerDataCache = class("playerDataCache")

-- 构造
function playerDataCache:ctor()
    -- 缓存数据
    self.cacheDataHash = {}
    self.cacheDataComm = {}
    -- 内存数据淘汰
    self.clearMemTime = 1800
    self.zset = require("zset").new()
    -- redis数据淘汰
    self.clearRedisKey = string.format("game-data-clear-%s", playerDataCenter.kid)
    self.clearRedisTime = 86400 * 8
    -- sq数据淘汰
    self.zsetSq = require("zset").new()
end

-- 获取内存数据淘汰时间
function playerDataCache:getMemTime()
    local time = svrFunc.systemTime()+self.clearMemTime
    time = time - time%60
    return time
end

-- 获取redis数据淘汰时间
function playerDataCache:getRedisTime()
    local time = svrFunc.systemTime()+self.clearRedisTime
    time = time - time%86400
    return time
end

-- 获取内存缓存
function playerDataCache:getMemCache(kid, id, module)
    if kid and id and module then
        local redisType = playerDataConfig:getRedisType(module)
        if redisType ~= gRedisType.common then
            local key = string.format(redisType, kid, id)
            if self.cacheDataHash[key] then
                self.zset:add(self:getMemTime(), key) -- 更新内存数据淘汰时间
                return self.cacheDataHash[key][module]
            end
        else
            local key = string.format(redisType, module, kid, id)
            self.zset:add(self:getMemTime(), key) -- 更新内存数据淘汰时间
            return self.cacheDataComm[key]
        end
    else
        Log.e("playerDataCache:getMemCache error1", kid, id, module)
    end
end

-- 更新内存缓存
function playerDataCache:setMemCache(kid, id, module, data)
    if kid and id and module and data ~= nil then
        local redisType = playerDataConfig:getRedisType(module)
        if redisType ~= gRedisType.common then
            local key = string.format(redisType, kid, id)
            if not self.cacheDataHash[key] then
                self.cacheDataHash[key] = {}
            end
            self.cacheDataHash[key][module] = data
            self.zset:add(self:getMemTime(), key) -- 更新内存数据淘汰时间
        else
            local key = string.format(redisType, module, kid, id)
            self.cacheDataComm[key] = data
            self.zset:add(self:getMemTime(), key) -- 更新内存数据淘汰时间
        end
    else
        Log.e("playerDataCache:setMemCache error1", kid, id, module, data)
    end
end

-- 删除内存缓存
function playerDataCache:deleteMemCache(kid, id, module)
    if kid and id and module then
        local redisType = playerDataConfig:getRedisType(module)
        if redisType ~= gRedisType.common then
            local key = string.format(redisType, kid, id)
            if self.cacheDataHash[key] then
                self.cacheDataHash[key][module] = nil
                self.zset:rem(key) -- 更新数据淘汰时间
            end
        else
            local key = string.format(redisType, module, kid, id)
            self.cacheDataComm[key] = nil
            self.zset:rem(key) -- 更新数据淘汰时间
        end
    else
        Log.e("playerDataCache:deleteMemCache error1", kid, id, module)
    end
end

-- 查询
function playerDataCache:query(kid, id, module)
    if kid and id and module then
        -- 先查询内存
        local data = self:getMemCache(kid, id, module)
        -- 若是本王国数据, 再查询本地redis
        if data == nil and kid == playerDataCenter.kid then
            local redisType = playerDataConfig:getRedisType(module)
            if redisType ~= gRedisType.common then
                local key = string.format(redisType, kid, id)
                local ok, str = xpcall(function ()
                    return redisLib:hGet(key, module)
                end, svrFunc.exception)
                if ok then
                    if str ~= nil then
                        data = json.decode(str) or str
                        -- 更新内存缓存
                        self:setMemCache(kid, id, module, data)
                        -- 更新redis数据淘汰时间
                        redisLib:sendzAdd(self.clearRedisKey, self:getRedisTime(), key)
                    end
                else
                    -- 本地redis宕机, 中断业务
                    playerDataCenter.playerDataTimer:addTimerRedisReconnect()
                    error(string.format("playerDataCache:query error: local redis crash %s %s %s", kid, id, module))
                end
            else
                local key = string.format(redisType, module, kid, id)
                local ok, str = xpcall(function ()
                    return redisLib:get(key)
                end, svrFunc.exception)
                if ok then
                    if str ~= nil then
                        data = json.decode(str) or str
                        -- 更新内存缓存
                        self:setMemCache(kid, id, module, data)
                    end
                else
                    -- 本地redis宕机, 中断业务
                    playerDataCenter.playerDataTimer:addTimerRedisReconnect()
                    error(string.format("playerDataCache:query error: local redis crash %s %s %s", kid, id, module))
                end
            end
        end
        return data
    else
        Log.e("playerDataCache:query error1", kid, id, module)
    end
end

-- 更新
function playerDataCache:update(kid, id, module, data, sql, flag)
    Log.d("playerDataCache:update", kid, id, module, data, sql, flag)
    if kid and id and module and data ~= nil then
        local redisType = playerDataConfig:getRedisType(module)
        if redisType ~= gRedisType.common then
            -- 若是本王国数据, 则更新redis哈希表
            if kid == playerDataCenter.kid then
                local str = json.encode(data) or data
                local key = string.format(redisType, kid, id)
                local ok = xpcall(function ()
                    return redisLib:hSet(key, module, str)
                end, svrFunc.exception)
                if not ok then
                    -- 本地redis宕机, 中断业务, 并增加到redis任务队列
                    playerDataCenter.playerDataTimer:addTimerRedisReconnect()
                    if flag then
                        local taskKey = playerDataCenter:getTaskKey(id, module)
                        playerDataCenter.redisTask:push(taskKey, {method = "update", id = id, module = module, data = data, sql = sql, time = skynet.time(),})
                    end
                    --playerDataCenter.playerDataFileWriter2:writeFile(string.format("require('redisLib'):hSet('%s', '%s', '%s');", key, module, str))
                    error(string.format("playerDataCache:update error: local redis crash %s %s %s", kid, id, module))
                end
                -- 更新redis数据淘汰时间
                redisLib:sendzAdd(self.clearRedisKey, self:getRedisTime(), key)
            end
            -- 更新内存缓存
            self:setMemCache(kid, id, module, data)
        else
            -- 若是本王国数据, 则更新redis
            if kid == playerDataCenter.kid then
                local str = json.encode(data) or data
                local key = string.format(redisType, module, kid, id)
                local ok = xpcall(function ()
                    return redisLib:set(key, str)
                end, svrFunc.exception)
                if not ok then
                    -- 本地redis宕机, 中断业务, 并增加到redis任务队列
                    playerDataCenter.playerDataTimer:addTimerRedisReconnect()
                    if flag then
                        local taskKey = playerDataCenter:getTaskKey(id, module)
                        playerDataCenter.redisTask:push(taskKey, {method = "update", id = id, module = module, data = data, sql = sql, time = skynet.time(),})
                    end
                    --playerDataCenter.playerDataFileWriter2:writeFile(string.format("require('redisLib'):set('%s', '%s');", key, str))
                    error(string.format("playerDataCache:update error: local redis crash %s %s %s", kid, id, module))
                end
            end
            -- 更新内存缓存
            self:setMemCache(kid, id, module, data)
        end
    else
        Log.e("playerDataCache:update error3", kid, id, module, data)
    end
end

-- 删除
function playerDataCache:delete(kid, id, module)
    Log.d("playerDataCache:delete", kid, id, module)
    if kid and id and module then
        local redisType = playerDataConfig:getRedisType(module)
        if redisType ~= gRedisType.common then
            -- 删除内存缓存
            self:deleteMemCache(kid, id, module)
            -- 若是本王国数据, 则删除redis哈希表
            if kid == playerDataCenter.kid then
                local key = string.format(redisType, kid, id)
                local ok = xpcall(function ()
                    return redisLib:hDel(key, module)
                end, svrFunc.exception)
                if not ok then
                    -- 本地redis宕机, 中断业务, 并增加到redis任务队列
                    playerDataCenter.playerDataTimer:addTimerRedisReconnect()
                    local taskKey = playerDataCenter:getTaskKey(id, module)
                    playerDataCenter.redisTask:push(taskKey, {method = "delete", id = id, module = module, time = skynet.time(),})
                    --playerDataCenter.playerDataFileWriter2:writeFile(string.format("require('redisLib'):hDel('%s', '%s');", key, module))
                    error(string.format("playerDataCache:delete error: local redis crash %s %s %s", kid, id, module))
                end
                -- 更新redis数据淘汰时间
                redisLib:sendzRem(self.clearRedisKey, key)
            end
        else
            -- 删除内存缓存
            self:deleteMemCache(kid, id, module)
            -- 若是本王国数据, 则删除redis
            if playerDataCenter.kid == kid then
                local key = string.format(redisType, module, kid, id)
                local ok = xpcall(function ()
                    return redisLib:delete(key)
                end, svrFunc.exception)
                if not ok then
                    -- 本地redis宕机, 中断业务, 并增加到redis任务队列
                    playerDataCenter.playerDataTimer:addTimerRedisReconnect()
                    local taskKey = playerDataCenter:getTaskKey(id, module)
                    playerDataCenter.redisTask:push(taskKey, {method = "delete", id = id, module = module, time = skynet.time(),})
                    --playerDataCenter.playerDataFileWriter2:writeFile(string.format("require('redisLib'):delete('%s');", key))
                    error(string.format("playerDataCache:delete error: local redis crash %s %s %s", kid, id, module))
                end
            end
        end
    else
        Log.e("playerDataCache:delete error1", kid, id, module)
    end
end

-- 定时清理内存缓存
function playerDataCache:onTimerClearCache()
    local time = svrFunc.systemTime()
    Log.i("== playerDataCache:onTimerClearCache begin =", time)
    local count, isEnd = 0, false
    while(true) do
        local keyList = self.zset:range(1, 500) or {}
        --Log.dump(keyList, "playerDataCache:onTimerClearCache keyList=", 10)
        for _,key in pairs(keyList) do
            if self.zset:score(key) > time then
                isEnd = true
                break
            end
            count = count + 1
            self.cacheDataHash[key] = nil
            self.cacheDataComm[key] = nil
            self.zset:rem(key)
            Log.d("playerDataCache:onTimerClearCache do=", count, key)
        end
        if #keyList < 500 or isEnd or count >= 50000 then
            break
        end
        skynet.sleep(2)
    end
    Log.i("== playerDataCache:onTimerClearCache end =", time, count)
end

-- 定时清理redis
function playerDataCache:onTimerClearRedis()
    local time = svrFunc.systemTime()
    Log.i("== playerDataCache:onTimerClearRedis begin =", time)
    local count, isEnd, key, score = 0, false, nil, nil
    while(true) do
        local keyList = redisLib:zRange(self.clearRedisKey, 0, 99, true) or {}
        --Log.dump(keyList, "playerDataCache:onTimerClearRedis keyList=", 10)
        for i=1,#keyList,2 do
            key, score = tostring(keyList[i]), tonumber(keyList[i+1])
            if not score or score > time then
                isEnd = true
                break
            end
            count = count + 1
            redisLib:sendDelete(key)
            redisLib:sendzRem(self.clearRedisKey, key)
            Log.d("playerDataCache:onTimerClearRedis do=", count, key)
        end
        if #keyList < 100 or isEnd or count >= 50000 then
            break
        end
        skynet.sleep(2)
    end
    Log.i("== playerDataCache:onTimerClearRedis end =", time, count)
end

function playerDataCache:getClearRedisKey()
    return self.clearRedisKey
end

function playerDataCache:addZsetSq(key)
    self.zsetSq:add(self:getMemTime(), key)
end

-- 定时清理sq数据
function playerDataCache:onTimerClearSq()
    local time = svrFunc.systemTime()
    Log.i("== playerDataCache:onTimerClearSq begin =", time)
    local count, isEnd = 0, false
    while(true) do
        local keyList = self.zsetSq:range(1, 500) or {}
        --Log.dump(keyList, "playerDataCache:onTimerClearSq keyList=", 10)
        for _,key in pairs(keyList) do
            if self.zsetSq:score(key) > time then
                isEnd = true
                break
            end
            count = count + 1
            self.zsetSq:rem(key)
            playerDataCenter:delSq(key)
            Log.d("playerDataCache:onTimerClearSq do=", count, key)
        end
        if #keyList < 500 or isEnd or count >= 50000 then
            break
        end
        skynet.sleep(2)
    end
    Log.i("== playerDataCache:onTimerClearSq end =", time, count)
    --Log.dump(playerDataCenter, "playerDataCache:onTimerClearSq playerDataCenter=")
end

-- 打印
function playerDataCache:dump()
    Log.dump(self.cacheDataComm, "playerDataCache:dump cacheDataComm=", 10)
    Log.dump(self.cacheDataHash, "playerDataCache:dump cacheDataHash=", 10)
    Log.d("playerDataCache:dump zset count=", self.zset:count())
end

return playerDataCache