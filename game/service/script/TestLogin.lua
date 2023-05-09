--[[
    压测登录
]]
local skynet = require "skynet"
local util = require "util"
local svrFunc = require "svrFunc"
local simAgent = class("simAgent", require("simGate"))

function simAgent:ctor(host, user)
    simAgent.super.ctor(self, host, user)

    -- 压测函数与权重配置
    self.minInterval = 30
    self.maxInterval = 35
    self.test =
    {
        reqHeartbeat = function()
            self:request("reqHeartbeat")
        end
    }
    self.fweight = {
        reqHeartbeat = 1,
    }
end

function main(host, uid)
    Log.d("simAgent main=", host, uid)
    local user = string.format("robot_%s", uid)
    local instance = simAgent.new(host, user)
    instance:connectLogin()
end

