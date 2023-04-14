--[[
    玩家数据中心服务中心
]]
local skynet = require("skynet")
local skynetQueue = require("skynet.queue")
local svrAddrMgr = require("svrAddrMgr")
local json = require("json")
local playerDataLib = require("playerDataLib")
local playerDataConfig = require("playerDataConfig")
local serviceCenterBase = require("serviceCenterBase2")
local playerDataCenter = class("playerDataCenter", serviceCenterBase)

function playerDataCenter:ctor()
    playerDataCenter.super.ctor(self)
    
    -- 不返回数据的指令集
    self.sendCmd["sendUpdate"] = true
    self.sendCmd["sendDelete"] = true
    self.sendCmd["stop"] = true

    -- redis更新任务列表
    self.redisTask = require("filterList").new()
    -- mysql更新任务列表
    self.mysqlTask = require("filterList").new()
    -- 串行队列
    self.sq = {}
end

-- 初始化
function playerDataCenter:init(kid, svrIdx)
    Log.i("==playerDataCenter:init begin==", kid, svrIdx)
    playerDataCenter.super.init(self, kid)

    -- 服务ID
    self.svrIdx = svrIdx

    -- 创建模块
    self.playerDataCache = require("playerDataCache").new()
    --self.playerDataFileWriter1 = require("playerDataFileWriter").new()
    --self.playerDataFileWriter2 = require("playerDataFileWriter").new()
    self.playerDataTimer = require("playerDataTimer").new()

    -- 初始化
    --self.playerDataFileWriter1:init(nil, "mysql_error"..svrIdx)
    --self.playerDataFileWriter1:loadFile1()
    --self.playerDataFileWriter2:init(nil, "redis_error"..svrIdx)
    --self.playerDataFileWriter2:loadFile2()
    self.playerDataTimer:init()

    Log.i("==playerDataCenter:init end==", kid, svrIdx)
end

-- 停止服务
function playerDataCenter:stop()
    Log.i("==playerDataCenter:stop begin==", self.kid, self.svrIdx)
    -- 标记停服中
    if self.stoping then
        return
    end
    self.stoping = true
    -- 等待所有任务队列都处理完, 再标记已停服
    skynet.fork(function()
        self.playerDataTimer:stop()
        while(true) do
            if self.redisTask:count() <= 0 and self.mysqlTask:count() then
                -- 检查消息队列和协程
                local mqlen = skynet.mqlen() or 0
                local task = {}
                local taskLen = skynet.task(task) or 0
                if mqlen > 0 or taskLen > 0 then
                    Log.i("playerDataCenter:stop waiting mq and task, mqlen=", mqlen, "taskLen=", taskLen, "task=", transformTableToString(task))
                else
                    --Log.i("playerAgentCenter:stop waiting mq and task, mqlen=", mqlen, "taskLen=", taskLen, "task=", transformTableToString(task))
                    break
                end
                break
            end
            skynet.sleep(200)
        end
        -- 标记已停服
        self.stoped = true
        if self.myTimer then
            self.myTimer:pause()
        end
    end)
    Log.i("==playerDataCenter:stop end==", self.kid, self.svrIdx)
end

-- 玩家/联盟彻底离线(数据落地)
-- @newKid 迁服时传, 同时删除本地redis数据
function playerDataCenter:logout(id, newKid)
    Log.i("playerDataCenter:logout begin=", id, newKid)
    local f = function(id, redisType)
        for k,v in pairs(playerDataConfig.moduleSettings) do
            if v.redisType == redisType then
                local taskKey = self:getTaskKey(id, v.table)
                if self.redisTask:has(taskKey) or self.mysqlTask:has(taskKey) then
                    Log.i("playerDataCenter:logout do=", id, v.table)
                    local sq = self:getSq(id, v.table)
                    sq(function()
                        self:dealRedisTask(id, v.table)
                        self:dealMysqlTask(id, v.table)
                    end)
                end
            end
        end
        -- 删除该玩家/联盟所有sq
        for k,v in pairs(playerDataConfig.moduleSettings) do
            if v.redisType == redisType then
                local key = self:getTaskKey(id, v.table)
                self:delSq(key)
            end
        end
        if newKid then
            local key = string.format(redisType, self.kid, id)
            local redisLib = require("redisLib")
            redisLib:sendDelete(key)
            redisLib:sendzRem(self.playerDataCache:getClearRedisKey(), key)
        end
    end
    if id then
        f(id, gRedisType.kingdom)
        playerDataLib:setKidOfId(id, newKid)
    end
    Log.i("playerDataCenter:logout end=", id, newKid)
    --Log.dump(self, "playerDataCenter:logout self=")
    return true
end

-- 获取联盟当前所在王国KID
function playerDataCenter:getKidOfId(id)
    --Log.d("playerDataCenter:getKidOfId", id)
    return playerDataLib:getKidOfId(self.kid, id)
end

--[[
    查询
    @id             [必填]数据ID
    @module         [必填]数据名
    @multi          [选填]根据多个条件查询
    @isForce        [选填]查询跨服数据时, 是否强制查询
]]
function playerDataCenter:query(id, module, multi, isForce)
    local sq = self:getSq(id, module)
    return sq(function()
        Log.d("playerDataCenter:query=", id, module, multi, isForce)
        -- 获取当前所在王国KID
        local kid = playerDataLib:getKidOfId(self.kid, id)
        -- 校验参数
        if not kid or not id or not module then
            svrFunc.exception(string.format("playerDataCenter:query error1: kid=%s, id=%s, module=%s", kid, id, module))
            return
        end
        local data = nil
        -- 先查询缓存
        if kid == self.kid or not isForce then
            -- 需提前处理redis更新任务
            self:dealRedisTask(id, module)
            data = self.playerDataCache:query(kid, id, module)
        end
        if data ~= nil then
            return data
        end
        -- 若是本王国数据, 再查询mysql; 若非本王国数据, 跨服查询
        if kid == self.kid then
            local sql = self:getQuerySql(id, module, multi)
            Log.d("playerDataCenter:query sql=", sql)
            if sql then
                -- 需提前处理更新任务
                self:dealMysqlTask(id, module)
                -- 查询mysql
                local ok, ret = xpcall(function ()
                    local gameDBSvr = svrAddrMgr.getSvr(svrAddrMgr.gameDBSvr)
                    return skynet.call(gameDBSvr, "lua", "execute", sql)
                end, svrFunc.exception)
                if not ok then -- mysql宕机, 中断执行
                    error(string.format("playerDataCenter:query error2: kid=%s, id=%s, module=%s", kid, id, module))
                end
                if type(ret) == "table" then
                    if ret.err then
                        -- sql异常, 中断业务
                        error(string.format("playerDataCenter:query error3: kid=%s, id=%s, module=%s ret=%s", kid, id, module, json.encode(ret)))
                    else
                        -- 查询结果包装
                        data = self:queryResultPack(ret, module)
                        if data ~= nil then
                            -- 更新缓存
                            self.playerDataCache:update(kid, id, module, data)
                        end
                    end
                end
            end
        else
            data = playerDataLib:query(kid, id, module, multi, isForce)
            -- 更新缓存, 非本王国数据, 暂不存内存缓存
            --if data ~= nil and not (type(data) == "table" and data.err) then
            --    self.playerDataCache:update(kid, id, module, data)
            --end
        end
        return data
    end)
end

-- 获取查询sql
function playerDataCenter:getQuerySql(id, module, multi)
    local setting = playerDataConfig.moduleSettings[module]
    if not id or not setting or not setting.columns then
        return
    end
    if multi and type(multi) == "table" and next(multi) then
        -- 复杂查询, 根据传入字段, 查询所有dataColumns字段
        local where = {}
        for _, k in ipairs(setting.keyColumns) do
            if multi[k] then
                table.insert(where, string.format("%s = '%s'", k, multi[k]))
            end
        end
        return string.format("SELECT %s FROM %s WHERE %s", table.concat(setting.dataColumns, " , "), setting.table, table.concat(where, " and "))
    else
        -- 简单查询, 根据第一个keyColumns字段, 查询所有dataColumns字段
        return string.format("SELECT %s FROM %s WHERE %s = '%s'", table.concat(setting.dataColumns, " , "), setting.table, setting.keyColumns[1], id)
    end
end

-- 查询结果包装
function playerDataCenter:queryResultPack(ret, module)
    -- Log.dump(ret, "playerDataCenter:queryResultPack module="..tostring(module), 10)
    if ret and #ret >= 1 then -- 查询结果必须至少得有1条
        local setting = playerDataConfig.moduleSettings[module]
        if not setting then
            svrFunc.exception(string.format("playerDataCenter:queryResultPack error: module=%s", module))
            return
        end
        for _,cell in pairs(ret) do
            for k,v in pairs(cell) do
                if type(v) == "string" then
                    cell[k] = json.decode(v) or v
                end
            end
        end
        if setting.mysqlType == gMysqlType.nosql and #setting.keyColumns == 1 and #ret == 1 then
            if table.nums(ret[1]) == 1 then
                local _,v = next(ret[1])
                return v
            else
                return ret[1]
            end
        end
        return ret
    end
    return nil
end

--[[
    更新
    @id             [必填]数据ID
    @module         [必填]数据名
    @data           [必填]数据
    @multi          [选填]是否复杂更新: 为true时, 可同时更新多个字段, data中非空字段都需要传
    示例:
        1. update(1, 1201, "lordinfo", {uid = 1201, name = "ABC"})
        2. update(1, 1201, "lordinfo", {id = 1201, data = {uid = 1201, name = "ABC"}}, true)
]]
function playerDataCenter:update(id, module, data, multi)
    local sq = self:getSq(id, module)
    return sq(function()
        Log.d("playerDataCenter:update", id, module, data, multi)
        -- 获取当前所在王国KID
        local kid = playerDataLib:getKidOfId(self.kid, id)
        -- 不能在本王国更新别王国的数据
        if not kid or kid ~= self.kid or not id or not module or data == nil then
            svrFunc.exception(string.format("playerDataCenter:update error1: kid=%s, id=%s, module=%s", kid, id, module))
            return false
        end
        local sql = self:getUpdateSql(id, module, data, multi)
        Log.d("playerDataCenter:update sql=", sql)
        -- 需提前处理redis更新任务
        self:dealRedisTask(id, module)
        -- 需要落库mysql
        if sql then
            -- 更新缓存
            self.playerDataCache:update(kid, id, module, data, sql, true)
            -- 更新mysql
            if kid == self.kid then
                -- 需提前处理更新任务
                self:dealMysqlTask(id, module)
                -- 执行sql(安全的)
                local ok, ret = self:executeSqlSafe(sql, id, module)
                if not ok or not ret or ret.err then
                    return false
                end
            end
        -- 无需落库mysql
        else
            -- 更新缓存
            self.playerDataCache:update(kid, id, module, data, nil, true)
        end
        return true
    end)
end

--[[
    更新(异步)
    @id             [必填]数据ID
    @module         [必填]数据名
    @data           [必填]数据
    @multi          [选填]是否复杂更新: 为true时, 可同时更新多个字段, data中非空字段都需要传
    示例:
        1. sendUpdate(1, 1201, "lordinfo", {uid = 1201, name = "ABC"})
        2. sendUpdate(1, 1201, "lordinfo", {id = 1201, data = {uid = 1201, name = "ABC"}}, true)
    注意: 此方法不能有阻塞调用
]]
function playerDataCenter:sendUpdate(id, module, data, multi)
    local sq = self:getSq(id, module)
    return sq(function()
        -- 获取当前所在王国KID
        Log.d("playerDataCenter:sendUpdate", id, module, data, multi)
        local kid = playerDataLib:getKidOfId(self.kid, id)
        -- 不能在本王国更新别王国的数据
        if not kid or kid ~= self.kid or not id or not module or data == nil then
            svrFunc.exception(string.format("playerDataCenter:sendUpdate error: kid=%s, id=%s, module=%s", kid, id, module))
            return
        end
        local sql = self:getUpdateSql(id, module, data, multi)
        Log.d("playerDataCenter:sendUpdate sql=", sql)
        -- 需提前处理redis更新任务
        self:dealRedisTask(id, module)
        -- 需要落库mysql
        if sql then
            -- 更新缓存
            self.playerDataCache:update(kid, id, module, data, sql, true)
            -- 更新mysql
            if kid == self.kid then
                -- 添加到mysql任务队列
                local taskKey = self:getTaskKey(id, module)
                self.mysqlTask:push(taskKey, {method = "sendUpdate", id = id, module = module, sql = sql, time = skynet.time(),})
            end
            -- 无需落库mysql
        else
            -- 更新缓存
            self.playerDataCache:update(kid, id, module, data, nil, true)
        end
    end)
end

-- 获取更新sql
function playerDataCenter:getUpdateSql(id, module, data, multi)
    local setting = playerDataConfig.moduleSettings[module]
    if not id or not module or data == nil or not setting or not setting.columns then
        return
    end
    if multi and type(data) == "table" then
        -- 复杂更新, 根据条件, 查询所有dataColumns字段
        local keyList, valueList, setList = {}, {}, {}
        for _,v in pairs(setting.columns) do
            if data[v] then
                table.insert(keyList, v)
                local dt = nil
                if type(data[v]) == "table" then
                    dt = svrFunc.escape(json.encode(data[v]))
                else
                    dt = data[v]
                end
                dt = string.format("'%s'", dt)
                table.insert(valueList, dt)
                if v ~= setting.keyColumns[1] then
                    table.insert(setList, string.format("%s=%s", v, dt))
                end
            end
        end
        return string.format("INSERT INTO %s(%s) VALUES (%s) ON DUPLICATE KEY UPDATE %s", setting.table, table.concat(keyList, ","), table.concat(valueList, ","), table.concat(setList, ","))
    else
        -- 简单更新, 根据第一个 keyColumns 字段(通常为id字段), 更新第一个dataColumns字段(通常为data字段)
        local dt = nil
        if type(data) == "table" then
            dt = svrFunc.escape(json.encode(data))
        else
            dt = data
        end
        return string.format("INSERT INTO %s(%s, %s) VALUES ('%s', '%s') ON DUPLICATE KEY UPDATE %s='%s'", setting.table, setting.keyColumns[1], setting.dataColumns[1], id, dt, setting.dataColumns[1], dt)
    end
end

--[[
    删除
    @kid            [必填]数据王国ID
    @id             [必填]数据ID
    @module         [必填]数据名
    @multi          [选填]根据多个条件删除
    示例:
        1. delete(1, 1201, "lordinfo")
        2. delete(1, 1201, "lordinfo", {id = 1201, })
]]
function playerDataCenter:delete(id, module, multi)
    local sq = self:getSq(id, module)
    return sq(function()
        Log.d("playerDataCenter:delete", id, module, multi)
        -- 获取当前所在王国KID
        local kid = playerDataLib:getKidOfId(self.kid, id)
        -- 不能在本王国删除别王国的数据
        if not kid or kid ~= self.kid or not id or not module then
            svrFunc.exception(string.format("playerDataCenter:delete error1: kid=%s, id=%s, module=%s", kid, id, module))
            return
        end
        local sql = self:getDeleteSql(id, module, multi)
        Log.d("playerDataCenter:delete sql=", sql)
        -- 需提前处理redis更新任务
        self:dealRedisTask(id, module)
        -- 需要落库mysql
        if sql then
            -- 删除缓存
            self.playerDataCache:delete(kid, id, module)
            -- 更新mysql
            if kid == self.kid then
                self:dealMysqlTask(id, module)
                local ok, ret = self:executeSqlSafe(sql, id, module)
                if not ok or not ret or ret.err then
                    return false
                end
            end
        -- 无需落库mysql
        else
            -- 删除缓存
            self.playerDataCache:delete(kid, id, module)
        end
        return true
    end)
end

--[[
    删除(异步)
    @kid            [必填]数据王国ID
    @id             [必填]数据ID
    @module         [必填]数据名
    @multi          [选填]根据多个条件删除
    示例:
        1. sendDelete(1, 1201, "lordinfo")
        2. sendDelete(1, 1201, "lordinfo", {id = 1201,})
    注意: 此方法不能有阻塞调用
]]
function playerDataCenter:sendDelete(id, module, multi)
    local sq = self:getSq(id, module)
    return sq(function()
        Log.d("playerDataCenter:sendDelete", id, module, multi)
        -- 获取当前所在王国KID
        local kid = playerDataLib:getKidOfId(self.kid, id)
        -- 不能在本王国删除别王国的数据
        if not kid or kid ~= self.kid or not id or not module then
            svrFunc.exception(string.format("playerDataCenter:sendDelete error: kid=%s, id=%s, module=%s", kid, id, module))
            return
        end
        local sql = self:getDeleteSql(id, module, multi)
        Log.d("playerDataCenter:sendDelete sql=", sql)
        -- 需提前处理redis更新任务
        self:dealRedisTask(id, module)
        -- 需要落库mysql
        if sql then
            -- 删除缓存
            self.playerDataCache:delete(kid, id, module)
            -- 更新mysql
            if kid == self.kid then
                -- 添加mysql任务队列
                local taskKey = self:getTaskKey(id, module)
                self.mysqlTask:push(taskKey, {method = "sendDelete", id = id, module = module, sql = sql, time = skynet.time(),})
            end
            -- 无需落库mysql
        else
            -- 删除缓存
            self.playerDataCache:delete(kid, id, module)
        end
    end)
end

-- 获取删除sql
function playerDataCenter:getDeleteSql(id, module, multi)
    local setting = playerDataConfig.moduleSettings[module]
    if not id or not module or not setting or not setting.columns then
        return
    end
    if multi and type(multi) == "table" and next(multi) then
        -- 复杂更新, 根据条件, 查询所有dataColumns字段
        local whereList = {}
        for _,v in pairs(setting.columns) do
            if multi[v] then
                table.insert(whereList, string.format("%s='%s'", v, multi[v]))
            end
        end
        return string.format("DELETE FROM %s WHERE %s", setting.table, table.concat(whereList, " and "))
    else
        -- 简单删除, 根据第一个keyColumns字段删除
        return string.format("DELETE FROM %s WHERE %s='%s'", setting.table, setting.keyColumns[1], id)
    end
end

-- 执行sql(非安全)
function playerDataCenter:executeSql(sql)
    Log.d("playerDataCenter:executeSql sql=", sql)
    assert(type(sql) == "string")
    local gameDBSvr = svrAddrMgr.getSvr(svrAddrMgr.gameDBSvr)
    return skynet.call(gameDBSvr, "lua", "execute", sql)
end

-- 执行sql(安全的)
-- @id & module 数据ID&数据数据名, 两者都传时, 可以在内存耗尽crash前异常处理
function playerDataCenter:executeSqlSafe(sql, id, module)
    --Log.d("playerDataCenter:executeSqlSafe sql=", sql, id, module)
    assert(type(sql) == "string")
    --
    local ok, ret = xpcall(function ()
        local gameDBSvr = svrAddrMgr.getSvr(svrAddrMgr.gameDBSvr)
        return skynet.call(gameDBSvr, "lua", "execute", sql)
    end, svrFunc.exception)
    -- Log.dump(ret, "playerDataCenter:executeSqlSafe ret=", 10)
    if not ok or not ret or ret.err then
        svrFunc.exception(string.format("playerDataCenter:executeSqlSafe sql=%s ok=%s ret=%s", sql, ok, transformTableToString(ret)))
        -- mysql宕机, 写库异常时, 重新加到mysql任务队列, 并开启mysql断线重连
        if not ok then
            self.playerDataTimer:addTimerMysqlReconnect()
            --
            if id and module then
                local sql2 = string.lower(sql)
                if string.find(sql2, "insert") or string.find(sql2, "update") or string.find(sql2, "delete") then
                    local taskKey = self:getTaskKey(id, module)
                    self.mysqlTask:push(taskKey, {method = "executeSqlSafe", id = id, module = module, sql = sql, time = skynet.time(),})
                end
            end
        end
    end
    return ok, ret
end

-- 任务key
function playerDataCenter:getTaskKey(id, module)
    return string.format("%s-%s", id, module)
end

-- 定时处理mysql更新任务列表(类漏桶排队算法)
function playerDataCenter:onDealMysqlTask()
    --Log.d("playerDataCenter:onDealMysqlTask begin=", self.svrIdx, self.mysqlTask:count())
    local opt, time = 0, skynet.time()
    while(true) do
        local data = self.mysqlTask:pop()
        if data then
            opt = opt + 1
            --Log.d("playerDataCenter:onDealMysqlTask do=", opt, data.id, data.module, data.method, "sql=", data.sql)
            local sq = self:getSq(data.id, data.module)
            sq(function()
                self:executeSqlSafe(data.sql, data.id, data.module)
            end)
            if opt%100 == 0 then -- 每处理100个, 睡眠2/100秒(20ms), 单个service每秒处理上限100*100/2 = 5000, 8个service每秒处理上限4w, 需根据mysql的qps来调整(rok全服实时在线1w+,阿里云QPS峰值5000左右,平均300)
                if opt > 50000 then -- 任务队列爆炸, 可能是mysql爆了, 报错跳出
                    svrFunc.exception(string.format("playerDataCenter:onDealMysqlTask error: task overload, opt=%d", opt))
                    break
                end
                skynet.sleep(2)
            end
            if (data.time or time) >= time then
                break
            end
        else
            -- 任务队列全部处理完成, 跳出
            break
        end
    end
     --Log.d("playerDataCenter:onDealMysqlTask end=", self.svrIdx, self.mysqlTask:count())
end

-- 提前处理mysql更新任务
function playerDataCenter:dealMysqlTask(id, module)
    xpcall(function()
        local taskKey = self:getTaskKey(id, module)
        local data = self.mysqlTask:remove(taskKey)
        if data then
            self:executeSqlSafe(data.sql, id, module)
        end
    end, svrFunc.exception)
end

-- 定时处理redis更新任务列表(类漏桶排队算法)
function playerDataCenter:onDealRedisTask()
    --Log.d("playerDataCenter:onDealRedisTask begin=", self.svrIdx, self.redisTask:count())
    local opt, time = 0, skynet.time()
    while(true) do
        local data = self.redisTask:pop()
        if data then
            opt = opt + 1
            Log.d("playerDataCenter:onDealRedisTask do=", opt, data.id, data.module, data.method, transformTableToString(data.data))
            local sq = self:getSq(data.id, data.module)
            sq(function()
                if data.method == "update" then
                    -- 需要落库mysql
                    if data.sql then
                        -- 更新缓存
                        self.playerDataCache:update(self.kid, data.id, data.module, data.data, data.sql, true)
                        -- 需提前处理mysql更新任务
                        self:dealMysqlTask(data.id, data.module)
                        -- 执行sql(安全的)
                        self:executeSqlSafe(data.sql, data.id, data.module)
                    -- 无需落库mysql
                    else
                        -- 更新缓存
                        self.playerDataCache:update(self.kid, data.id, data.module, data.data, nil, true)
                    end
                elseif data.method == "delete" then
                    -- 需要落库mysql
                    if data.sql then
                        -- 删除缓存
                        self.playerDataCache:delete(self.kid, data.id, data.module)
                        -- 需提前处理mysql更新任务
                        self:dealMysqlTask(data.id, data.module)
                        -- 执行sql(安全的)
                        self:executeSqlSafe(data.sql, data.id, data.module)
                    -- 无需落库mysql
                    else
                        -- 删除缓存
                        self.playerDataCache:delete(self.kid, data.id, data.module)
                    end
                end
            end)
            if opt%100 == 0 then -- 每处理100个, 睡眠2/100秒(20ms), 单个service每秒处理上限100*100/2 = 10000, 8个service每秒处理上限8w, 需根据redis的qps来调整(redis的qps一般能达到10w-15w)
                if opt > 50000 then -- 任务队列爆炸, 可能是redis爆了, 报错跳出
                    svrFunc.exception(string.format("playerDataCenter:onDealRedisTask error: task overload, opt=%d", opt))
                    break
                end
                skynet.sleep(1)
            end
            if (data.time or time) >= time then
                break
            end
        else
            -- 任务队列全部处理完成, 跳出
            break
        end
    end
     --Log.d("playerDataCenter:onDealRedisTask end=", self.svrIdx, self.redisTask:count())
end

-- 提前处理mysql更新任务
function playerDataCenter:dealRedisTask(id, module)
    xpcall(function()
        local taskKey = self:getTaskKey(id, module)
        local data = self.redisTask:remove(taskKey)
        if data then
            -- 需要落库mysql
            if data.sql then
                -- 更新缓存
                self.playerDataCache:update(self.kid, data.id, data.module, data.data, data.sql, true)
                -- 执行sql(安全的)
                self:executeSqlSafe(data.sql, data.id, data.module)
            -- 无需落库mysql
            else
                -- 更新缓存
                self.playerDataCache:update(self.kid, data.id, data.module, data.data, nil, true)
            end
        end
    end, svrFunc.exception)
end

-- 获取串行队列
function playerDataCenter:getSq(id, module)
    local key = self:getTaskKey(id, module)
    if not self.sq[key] then
        self.sq[key] = skynetQueue()
    end
    self.playerDataCache:addZsetSq(key)
    return self.sq[key]
end

-- 删除串行队列
function playerDataCenter:delSq(key)
    if self.sq[key] then
        self.sq[key] = nil
    end
end

return playerDataCenter
