--[[
    交易所管理器
]]
local skynet = require("skynet")
local svrFunc = require("svrFunc")
local playerDataLib = require("playerDataLib")
local commonCenter = require("commonCenter"):shareInstance()
local tradeMgr = class("tradeMgr")

function tradeMgr:ctor()
    self.module = "tradeinfo"	        -- 数据表名
    self.data = nil		                -- 数据
end

-- 数据id
function tradeMgr:dataId()
    return tonumber(string.format("%s%s", commonCenter.kid, commonCenter.idx))
end

-- 默认数据
function tradeMgr:defaultData()
    return {
        round = 0,      -- 轮次
        startTime = 0,  -- 开始时间
        endTime = 0,    -- 结束时间
        goods = {},     -- 交易品
    }
end

-- 初始化
function tradeMgr:init()
    self.data = self:queryDB()
    if "table" ~= type(self.data) then
        self.data = self:defaultData()
        self:updateDB()
    end
end

-- 查询数据库
function tradeMgr:queryDB()
    assert(self.module, "tradeMgr:queryDB error!")
    return playerDataLib:query(commonCenter.kid, self:dataId(), self.module)
end

-- 更新数据库
function tradeMgr:updateDB()
    local data = self:getDataDB()
    assert(self.module and data, "tradeMgr:updateDB error!")
    playerDataLib:sendUpdate(commonCenter.kid, self:dataId(), self.module, data)
end

-- 获取存库数据
function tradeMgr:getDataDB()
    return self.data
end

-- 添加交易品
function tradeMgr:addGood(good)
    if type(good) ~= "table" then
        return false
    end
    good.time = svrFunc.skynetTime()
    table.insert(self.data.goods, good)
    tradeMgr:updateDB()
    return true
end

-- 获取交易品
function tradeMgr:getGoods()
    return self.data.goods
end

return tradeMgr
