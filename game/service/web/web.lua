--[[
    web服务
--]]
require("quickframework.init")
require("cluster")
require("svrFunc")
local skynet = require "skynet"
local profile = require "skynet.profile"
local webCenter = require("webCenter"):shareInstance()

local ti = {}

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        --Log.d("webCenter cmd enter => ", session, source, cmd, ...)
        profile.start()

        webCenter:dispatchCmd(session, source, cmd, ...)

        local time = profile.stop()
        if time > 1 then
            Log.w("webCenter:dispatchCmd timeout time=", time, " cmd=", cmd, ...)
            if not ti[cmd] then
                ti[cmd] = {n = 0, ti = 0}
            end
            ti[cmd].n = ti[cmd].n + 1
            ti[cmd].ti = ti[cmd].ti + time
        end
    end)
    -- 设置本服地址
    svrAddrMgr.setSvr(skynet.self(), svrAddrMgr.webSvr)
    -- 初始化
    skynet.call(skynet.self(), "lua", "init")
end)

