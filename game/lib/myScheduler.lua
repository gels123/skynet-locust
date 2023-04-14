--[[
    计时器
    示例:
        local myScheduler = require("myScheduler").new()
        local curtime = now()
        for i=1,10 do
            local ID = myScheduler:schedule(function ( param )
                -- skynet.sleep(2*100)
                print("time out=",param,curtime+i,now())
            end,curtime+i,"test" .. i)
            myScheduler:delay(ID,1)
        end
        myScheduler:start()
--]]
local skynet = require("skynet")
local zset = require("zset")
local myScheduler = class("myScheduler")

local defaultRefreshTime = 1

local now = function()
    return math.floor(skynet.time())
end

------------------API--------------------
function myScheduler.create(fun, time)
    local sche = myScheduler.new()
    sche:scheduleUpdate(fun)
    sche:setRefreshTime(time)
    return sche
end

-- 获取定时器数量
function myScheduler:getSchedulerCount()
    return self.zset:count()
end

-- 设置刷新函数
function myScheduler:schedule(fun,endtime,param,repeats)
    if "function" == type(fun) then
        assert(self.list[self.ID] == nil, "timer ID is duplicate")
        local retID = self.ID
        local ID = tostring(self.ID)
        -- item[1] = 回调函数,item[2] = 参数,item[3] = 是否重复,item[4] = 定时间隔
        local nowTime = now()
        local interval = endtime - nowTime
        -- if interval <= 0 then 
        --     Log.e("error interval <= 0", interval, endtime, nowTime)
        -- end
        if repeats then assert(interval > 0, "if repeats then interval must > 0") end
        self.list[ID] = {fun,param,repeats,interval}
        self.zset:add(endtime,ID)
        self.ID = self.ID + 1
        return retID
    end
end

-- 设置刷新函数
function myScheduler:repeatSchedule(fun,interval,param)
    if "function" == type(fun) then
        assert(self.list[self.ID] == nil,"timer ID is duplicate")
        local retID = self.ID
        local ID = tostring(self.ID)
        -- item[1] = 回调函数,item[2] = 参数,item[3] = 是否重复,item[4] = 定时间隔
        assert(interval>0,"if repeats then interval must > 0")
        local endtime = now() + interval
        self.list[ID] = {fun,param,true,interval}
        self.zset:add(endtime,ID)
        self.ID = self.ID + 1
        return retID
    end
end

-- 设置定时器刷新时间
function myScheduler:setRefreshTime(time)
    if "number" == type(time) and time > 0 then
        self.refreshTime_ = time
    end
end

-- 获取定时器刷新时间
function myScheduler:getRefreshTime()
    return self.refreshTime_
end

-- 启动计时器
function myScheduler:start()
    self.continue = true
    if self.schedulerCo then
        skynet.wakeup(self.schedulerCo)
    end
end

-- 暂停计时器
function myScheduler:pause()
    self.continue = false
end

-- 刷新
function myScheduler:update()
    local ret = self.zset:range_by_score(0, now())
    for _, ID in ipairs(ret) do
        local item = self.list[ID]
        if item then
            if not item[3] then
                self.list[ID] = nil
                self.zset:rem(ID)
            elseif item[4] then --重复性计时器
                if item[4] ~= 1 then -- 每秒的无需每次都添加
                    self.zset:add(now() + item[4],ID)
                end
            end
            -- print("ID=",ID,now())
            skynet.fork(item[1], item[2])
        end
    end
end

-- 更新计时器ID到某一时刻
function myScheduler:reset(myschedulerID, newEndtime)
    if myschedulerID and newEndtime and type(newEndtime) == "number" then
        local ID = tostring(myschedulerID)
        local score = self.zset:score(ID)
        if score ~= newEndtime then
            self.zset:add(newEndtime,ID)
        end
        return true
    end
    return false
end

-- 加速计时器ID,提前n秒结束
function myScheduler:speedup(myschedulerID, second)
    if myschedulerID and second and type(second) == "number" and second > 0 then
        local ID = tostring(myschedulerID)
        local endtime = self.zset:score(ID)
        if endtime then
            self.zset:add(endtime-second,ID)
            return true
        end
    end
    return false
end

-- 加速计时器ID,延迟n秒结束
function myScheduler:delay(myschedulerID, second)
    if myschedulerID and second and type(second) == "number" and second > 0 then
        local ID = tostring(myschedulerID)
        local endtime = self.zset:score(ID)
        if endtime then
            self.zset:add(endtime+second,ID)
            return true
        end
    end
    return false
end

-- 是否正在运行
function myScheduler:isRunning()
    return self.continue
end

-- 停止计时器ID
function myScheduler:stop(myschedulerID)
    if myschedulerID then
        local ID = tostring(myschedulerID)
        local item = self.list[ID]
        if item then
            self.list[ID] = nil
            self.zset:rem(ID)
            return true
        end
    end
    return false
end

-- 立即执行某一计时器ID(阻塞调用)
function myScheduler:dispatchRightNow(myschedulerID)
    local ID = tostring(myschedulerID)
    local item = self.list[ID]
    if item then
        -- 立马从定时列表删除
        self.zset:rem(ID)
        local func = item[1]
        -- 回调
        xpcall(func, svrFunc.exception, item[2])
        -- 列表置空
        self.list[ID] = nil
        return true
    end
    return false
end

-- 清空所有计时器
function myScheduler:clear()
    self.zset:limit(0)
    self.list = {}
end

----------------------------------------

local function coFun(self)
    while true do
        -- Log.d("==myScheduler coFun==", self.name, self.zset:count())
        if self.continue then
            skynet.sleep(self:getRefreshTime() * 100)
            self:update()
        else
            skynet.wait()
        end
    end
end

function myScheduler:ctor(name)
    self.name = name
    -- 是否继续运行，默认未不继续
    self.continue = false
    self.list = {}
    self.ID = now()
    self.zset = zset.new()
    self.refreshTime_ = defaultRefreshTime
    -- 定时器协程
    self.schedulerCo = skynet.fork(coFun, self)
end

return myScheduler