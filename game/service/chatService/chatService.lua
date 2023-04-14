--
-- Author: SuYinXiang (sue602@163.com)
-- Date: 2016-04-05 16:55:56
--
require "configInclude"
require "quickframework.init"
local profile = require "skynet.profile"
local svrAddressMgr = require "svrAddressMgr"
local skynet = require("skynet")
local mysql = require("skynet.db.mysql")
require("skynet.sharedata")
local cluster = require("cluster")
local ti = {}
local instance = ...

skynet.init(function (  )
    --构造
    local chatCenter = require("chatCenter").instance()
    --初始化
    chatCenter:init(instance)
end)

skynet.start(function()

    local chatCenter = require("chatCenter").instance()
    
    --注册dispatch函数,LUA类型
    skynet.dispatch(skynet.PTYPE_LUA, function(session, source, cmd, ...)
        profile.start()

        --分发命令
        chatCenter:dispatch(session, source, cmd, ...)

        local time = profile.stop()
        if time > 3 then
            local p = ti[cmd]
            if p == nil then
                p = { n = 0, ti = 0 }
                ti[cmd] = p
            end
            p.n = p.n + 1
            p.ti = p.ti + time
        end
    end)

    -- 注册 info 函数，便于 debug 指令 INFO 查询。
    skynet.info_func(function()
        dump(ti, "chat service ti=", 10)
        return ti
    end)

    svrAddressMgr.setSvr(skynet.self(),svrAddressMgr.newChatSvr,instance)

end)
