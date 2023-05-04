--[[
    服务器配置
]]
local skynet = require("skynet")
local cluster = require("cluster")
local initDBConf = class("initDBConf")

-- 共享数据KEY
local SVRCONF_CONF_KEY_CLUSTER = "SVRCONF_CONF_KEY_CLUSTER"

-- 加载服务器配置
function initDBConf:set(isUpdate)
    Log.i("==initDBConf:set begin==", isUpdate)
    -- 设置cluster配置
    self:setClusterConf(isUpdate)
    -- 重新加载cluster配置
    local cluster = require("cluster")
    cluster.reload()
    -- 查询关联
    self.sharedataRef = {}
    Log.i("==initDBConf:set end==", isUpdate)
end

-- 设置cluster配置
function initDBConf:setClusterConf(isUpdate)
    local strSQL = "select * from conf_cluster"
    local svrAddrMgr = require("svrAddrMgr")
    local dbSvr = svrAddrMgr.getSvr(svrAddrMgr.dbSvr)
    local values = skynet.call(dbSvr, "lua", "execute", strSQL)
    -- Log.dump(values, "initDBConf:setClusterConf values=", 10)
    local sharedataLib = require("sharedataLib")
    if isUpdate then
        sharedataLib.update(SVRCONF_CONF_KEY_CLUSTER, values)
    else
        sharedataLib.new(SVRCONF_CONF_KEY_CLUSTER, values)
    end

    -- 写入本地cluster配置文件
    local content = ""
    for k, v in pairs(values) do
        if v.web ~= "127.0.0.1" and v.web ~= "localhost" then
            local cell = string.format("%s = \"%s:%s\"", v.nodename, v.web, v.port)
            content = content .. cell .. "\n"
        else
            local cell = string.format("%s = \"%s:%s\"", v.nodename, v.ip, v.port)
            content = content .. cell .. "\n"
        end
        local cell2 = string.format("%s = \"%s:%s\"", v.listennodename, v.listen, v.port)
        content = content .. cell2 .. "\n"
    end
    local filename = skynet.getenv("cluster")
    local file = assert(io.open(filename, 'w'))
    file:write(content)
    file:close()
end

-- 获取cluster配置
function initDBConf:getClusterConf(nodeid)
    return self:getConf(SVRCONF_CONF_KEY_CLUSTER, nodeid)
end

-- 获取配置
function initDBConf:getConf(key, nodeid)
    if not self.sharedataRef then
        self.sharedataRef = {}
    end
    local ret = self.sharedataRef[key]
    if not ret then
        local sharedataLib = require("sharedataLib")
        ret = sharedataLib.query(key)
        self.sharedataRef[key] = ret
    end
    -- Log.dump(ret, string.format("initDBConf:getConf key = %s, ret=", key), 10)
    if nodeid then
        for k,v in pairs(ret) do
            if tonumber(nodeid) == v.nodeid then
                return v
            end
        end
    else
        return ret
    end
end

-- 刷库
function initDBConf:executeDbSql()
    local sql = io.readfile("locust.sql")
    Log.d("initDBConf:executeDbSql sql=", sql)
    local dbSvr = require("svrAddrMgr").getSvr(svrAddrMgr.dbSvr)
    local ret = skynet.call(dbSvr, "lua", "execute", sql)
    Log.dump(ret, "initDBConf:executeDbSql ret=")
    assert(ret and not ret.err, "initDBConf:executeDbSql error, ret="..transformTableToString(ret))
end

return initDBConf

