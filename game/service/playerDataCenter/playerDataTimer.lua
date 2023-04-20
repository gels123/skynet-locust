--[[
	玩家数据中心定时器
]]
local skynet = require("skynet")
local svrAddrMgr = require("svrAddrMgr")
local playerDataCenter = require("playerDataCenter"):shareInstance()
local playerDataTimer = class("playerDataTimer", cc.mvc.ModelBase)

-- 倒计时: 定时处理redis更新任务列表
local dealRedisTask = "dealRedisTask"
-- 倒计时: 定时处理mysql更新任务列表
local dealMysqlTask = "dealMysqlTask"
-- 倒计时: 定时清理缓存
local clearCache = "clearCache"
-- 倒计时: 定时清理redis
local clearRedis = "clearRedis"
-- 倒计时: 定时mysql断线重连
local mysqlReconnect = "mysqlReconnect"
-- 倒计时: 定时redis断线重连
local redisReconnect = "redisReconnect"

function playerDataTimer:ctor()
	playerDataTimer.super.ctor(self)

    -- 时间队列
    self.queue = {}

    -- 处理mysql更新任务列表间隔
    self.dealTaskTime = dbconf.DEBUG and 10 or 20
    -- 清理缓存间隔
    self.clearCacheInterval = 3600
    -- 清理redis间隔
    self.clearRedisInterval = 86400
    -- mysql断线重连间隔
    self.mysqlReconnectTime = 10
    -- mysql断线重连中
    self.mysqlReconnect = nil
    -- redis断线重连间隔
    self.redisReconnectTime = 10
    -- redis断线重连中
    self.redisReconnect = nil

	-- 注册倒计时回调
    self:addEventListener(dealRedisTask, handler(self, self.onDealRedisTask))
    self:addEventListener(dealMysqlTask, handler(self, self.onDealMysqlTask))
    self:addEventListener(clearCache, handler(self, self.onTimerClearCache))
    self:addEventListener(clearRedis, handler(self, self.onTimerClearRedis))
    self:addEventListener(mysqlReconnect, handler(self, self.onTimerMysqlReconnect))
	self:addEventListener(redisReconnect, handler(self, self.onTimerRedisReconnect))
end

-- 初始化
function playerDataTimer:init()
    -- 添加倒计时: 定时处理redis更新任务列表
    self:addQueue(dealRedisTask, svrFunc.systemTime()+self.dealTaskTime)
    -- 添加倒计时: 定时处理mysql更新任务列表
    self:addQueue(dealMysqlTask, svrFunc.systemTime()+self.dealTaskTime)
    -- 添加倒计时: 定时清理缓存
    self:addQueue(clearCache, svrFunc.systemTime()+self.clearCacheInterval)
    -- 添加倒计时: 定时清理redis
    self:addQueue(clearRedis, svrFunc.systemTime()+self.clearRedisInterval)
end

-- 停服
function playerDataTimer:stop()
    -- 加快倒计时
    self.redisReconnectTime = 5
    self.mysqlReconnectTime = 5
    self.dealTaskTime = 1
    -- 触发倒计时
    local qtypes = {redisReconnect, mysqlReconnect, dealRedisTask, dealMysqlTask}
    for _,qtype in pairs(qtypes) do
        skynet.fork(function()
            local timerId = self.queue[qtype] and self.queue[qtype].timerId
            if timerId then
                playerDataCenter.myTimer:dispatchRightNow(timerId)
            end
        end)
    end
end

--查询时间队列
function playerDataTimer:queryQueue(qtype)
    return self.queue[tostring(qtype)]
end

--移除时间队列
function playerDataTimer:removeQueue(qtype)
	qtype = tostring(qtype)
    local queue = self:queryQueue(qtype)
    if queue and queue.timerId then
		playerDataCenter.myTimer:cancelTimer(queue.timerId)
		self.queue[qtype] = nil
        Log.i("playerDataTimer:removeQueue qtype=", qtype)
    end
end

--增加时间队列
function playerDataTimer:addQueue(qtype, endTime, data)
    -- Log.d("playerDataTimer:addQueue", qtype, endTime, transformTableToSrting(data))
    qtype = tostring(qtype)
    local queue = self:queryQueue(qtype)
    if queue then
        self:removeQueue(qtype)
    end
    --Log.i("playerDataTimer:addQueue qtype", qtype, endTime)
    local queue = {
        qtype = qtype,
        endTime = endTime,
        data = data,
        timerId = nil,
    }
    local function dispatchQueueEvent()
        self.queue[qtype] = nil
        self:dispatchEvent({name = qtype, data = data})
    end
    queue.timerId = playerDataCenter.myTimer:schedule(timerHandler(dispatchQueueEvent), endTime)
    self.queue[qtype] = queue
end

-- 倒计时回调: 定时处理mysql更新任务列表
function playerDataTimer:onDealRedisTask(event)
    -- 定时处理mysql更新任务列表
    xpcall(function()
        playerDataCenter:onDealRedisTask()
    end, svrFunc.exception)
    -- 添加倒计时: 定时处理mysql更新任务列表
    self:addQueue(dealRedisTask, svrFunc.systemTime()+self.dealTaskTime)
end

-- 倒计时回调: 定时处理mysql更新任务列表
function playerDataTimer:onDealMysqlTask(event)
    -- 定时处理mysql更新任务列表
    xpcall(function()
        playerDataCenter:onDealMysqlTask()
    end, svrFunc.exception)
    -- 添加倒计时: 定时处理mysql更新任务列表
    self:addQueue(dealMysqlTask, svrFunc.systemTime()+self.dealTaskTime)
end

-- 倒计时回调: 定时清理缓存
function playerDataTimer:onTimerClearCache(event)
    -- 定时清理缓存
    xpcall(function()
        playerDataCenter.playerDataCache:onTimerClearCache()
    end, svrFunc.exception)
    -- 定时清理sq数据
    xpcall(function()
        playerDataCenter.playerDataCache:onTimerClearSq()
    end, svrFunc.exception)
    -- 添加倒计时: 定时清理缓存
    self:addQueue(clearCache, svrFunc.systemTime()+self.clearCacheInterval)
end

-- 倒计时回调: 定时清理redis
function playerDataTimer:onTimerClearRedis(event)
    -- 定时清理缓存
    xpcall(function()
        playerDataCenter.playerDataCache:onTimerClearRedis()
    end, svrFunc.exception)
    -- 添加倒计时: 定时清理缓存
    self:addQueue(clearRedis, svrFunc.systemTime()+self.clearRedisInterval)
end

-- 增加倒计时: 定时mysql断线重连
function playerDataTimer:addTimerMysqlReconnect()
    if self.mysqlReconnect then
        return
    end
    self.mysqlReconnect = true
    self:onTimerMysqlReconnect()
end

-- 倒计时: 定时mysql断线重连
function playerDataTimer:onTimerMysqlReconnect()
    local xpcallOk, ok = xpcall(function ()
        local dbSvr = svrAddrMgr.getSvr(svrAddrMgr.dbSvr)
        skynet.call(dbSvr, "lua", "reconnect", dbconf.mysql_db)
        return skynet.call(dbSvr, "lua", "testconnect")
    end, svrFunc.exception)
    Log.i("playerDataTimer:onTimerMysqlReconnect xpcallOk=", xpcallOk, "ok=", ok)
    if not xpcallOk or not ok then
        -- 断线重连失败
        self:addQueue(mysqlReconnect, svrFunc.systemTime()+self.mysqlReconnectTime)
    else
        -- 断线重连成功
        self.mysqlReconnect = nil
        -- 断线重连成功, 读取db异常处理文件并落库
        --playerDataCenter.playerDataFileWriter1:close()
        --playerDataCenter.playerDataFileWriter1:loadFile1()
    end
end

-- 增加倒计时: 定时redis断线重连
function playerDataTimer:addTimerRedisReconnect()
    if self.redisReconnect then
        return
    end
    self.redisReconnect = true
    self:onTimerRedisReconnect()
end

-- 倒计时回调: 定时redis断线重连
function playerDataTimer:onTimerRedisReconnect()
    local pcallOk, ok = xpcall(function ()
        local redisSvr = svrAddrMgr.getSvr(svrAddrMgr.redisSvr)
        skynet.call(redisSvr, "lua", "reconnect", dbconf.redis)
        return skynet.call(redisSvr, "lua", "ping")
    end, svrFunc.exception)
    Log.i("playerDataTimer:onTimerRedisReconnect pcallOk=", pcallOk, "ok=", ok)
    if not pcallOk or not ok then
        -- 断线重连失败
        self:addQueue(redisReconnect, svrFunc.systemTime()+self.redisReconnectTime)
    else
        -- 断线重连成功
        self.redisReconnect = nil
    end
end

function playerDataTimer:dispatchMysqlReconnect()
    if self.queue[mysqlReconnect] then
        Log.d("playerDataTimer:dispatchMysqlReconnect", playerDataCenter.svrIdx)
        playerDataCenter.myTimer:dispatchRightNow(self.queue[mysqlReconnect].timerId)
    end
end

return playerDataTimer