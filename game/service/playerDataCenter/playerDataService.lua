--[[
	玩家数据中心服务(注:全局服为无状态服, 与游戏服不同)
]]
require "quickframework.init"
require "svrFunc"
require "configInclude"
require "sharedataLib"
local skynet = require "skynet"
local cluster = require "skynet.cluster"
local profile = require "skynet.profile"
local playerDataCenter = require("playerDataCenter"):shareInstance()

local ti = {}

local kid, svrIdx = ...
kid, svrIdx = tonumber(kid), tonumber(svrIdx)
assert(kid and svrIdx)

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        -- Log.d("playerDataCenter cmd enter => ", session, source, cmd, ...)

        profile.start()

        xpcall(playerDataCenter.dispatchCmd, svrFunc.exception, playerDataCenter, session, source, cmd, ...)

        local time = profile.stop()
        if time > gOptTimeOut then
            Log.w("playerDataCenter:dispatchCmd timeout time=", time, " cmd=", cmd, ...)
            if not ti[cmd] then
                ti[cmd] = {n = 0, ti = 0}
            end
            ti[cmd].n = ti[cmd].n + 1
            ti[cmd].ti = ti[cmd].ti + time
        end
    end)

    -- 设置地址
    svrAddrMgr.setSvr(skynet.self(), svrAddrMgr.dataCenterSvr, kid, svrIdx)

    -- 初始化
    skynet.call(skynet.self(), "lua", "init", kid, svrIdx)

    -- 通知启动服务，本服务已初始化完成
    require("serverStartLib"):finishInit(svrAddrMgr.getSvrName(svrAddrMgr.dataCenterSvr, kid, svrIdx), skynet.self())
end)