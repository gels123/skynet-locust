--[[
    服务器配置
]]
local skynet = require("skynet")
local cluster = require("cluster")
local initDBConf = class("initDBConf")

-- 共享数据KEY
local SVRCONF_CONF_KEY_CLUSTER = "SVRCONF_CONF_KEY_CLUSTER"
local SVRCONF_CONF_KEY_DEBUG = "SVRCONF_CONF_KEY_DEBUG"
local SVRCONF_CONF_KEY_HTTP = "SVRCONF_CONF_KEY_HTTP"
local SVRCONF_CONF_KEY_KINGDOM = "SVRCONF_CONF_KEY_KINGDOM"
local SVRCONF_CONF_KEY_LOGIN = "SVRCONF_CONF_KEY_LOGIN"
local SVRCONF_CONF_KEY_GATE = "SVRCONF_CONF_KEY_GATE"
local SVRCONF_CONF_KEY_NOTICE_HTTP = "SVRCONF_CONF_KEY_NOTICE_HTTP"
local SVRCONF_CONF_KEY_IP_WHITE_LIST = "SVRCONF_CONF_KEY_IP_WHITE_LIST"

-- 加载服务器配置
function initDBConf:set(isUpdate)
    Log.i("==initDBConf:set begin==", isUpdate)

    -- 设置cluster配置
    self:setClusterConf(isUpdate)
    -- 设置debug配置
    self:setDebugConf(isUpdate)
    -- 设置http配置
    self:setHttpConf(isUpdate)
    -- 设置kingdom配置
    self:setKingdomConf(isUpdate)
    -- 设置login配置
    self:setLoginConf(isUpdate)
    -- 设置gate配置
    self:setGateConf(isUpdate)
    -- 设置notice http配置
    self:setNoticeHttp(isUpdate)
    -- 设置ip白名单配置
    self:setIpWhiteListConf(isUpdate)

    -- 重新加载cluster配置
    local cluster = require("cluster")
    cluster.reload()

    -- 查询关联
    self.sharedataRef = {}
    -- global服一致性哈希、global服节点
    self.globalHash = nil
    self.globalCluster = nil
    Log.i("==initDBConf:set end==", isUpdate)

    -- 打印
    self:dump()
end

-- 设置cluster配置
function initDBConf:setClusterConf(isUpdate)
    local strSQL = "select * from conf_cluster"
    local svrAddrMgr = require("svrAddrMgr")
    local confDBSvr = svrAddrMgr.getSvr(svrAddrMgr.confDBSvr)
    local values = skynet.call(confDBSvr, "lua", "execute", strSQL)
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

-- 设置debug配置
function initDBConf:setDebugConf(isUpdate)
    local strSQL = "select * from conf_debug"
    local svrAddrMgr = require("svrAddrMgr")
    local confDBSvr = svrAddrMgr.getSvr(svrAddrMgr.confDBSvr)
    local values = skynet.call(confDBSvr, "lua", "execute", strSQL)
    -- Log.dump(values, "initDBConf:setDebugConf values=", 10)
    local sharedataLib = require("sharedataLib")
    if isUpdate then
        sharedataLib.update(SVRCONF_CONF_KEY_DEBUG, values)
    else
        sharedataLib.new(SVRCONF_CONF_KEY_DEBUG, values)
    end
end

-- 获取debug配置
function initDBConf:getDebugConf(nodeid)
    return self:getConf(SVRCONF_CONF_KEY_DEBUG, nodeid)
end

-- 设置http配置
function initDBConf:setHttpConf(isUpdate) 
    local strSQL = "select * from conf_http"
    local svrAddrMgr = require("svrAddrMgr")
    local confDBSvr = svrAddrMgr.getSvr(svrAddrMgr.confDBSvr)
    local values = skynet.call(confDBSvr, "lua", "execute", strSQL)
    -- Log.dump(values, "initDBConf:setHttpConf values=", 10)
    local sharedataLib = require("sharedataLib")
    if isUpdate then
        sharedataLib.update(SVRCONF_CONF_KEY_HTTP, values)
    else
        sharedataLib.new(SVRCONF_CONF_KEY_HTTP, values)
    end
end

-- 获取http配置
function initDBConf:getHttpConf(nodeid)
    return self:getConf(SVRCONF_CONF_KEY_HTTP, nodeid)
end

-- 设置kingdom配置
function initDBConf:setKingdomConf(isUpdate)
    local strSQL = "select * from conf_kingdom"
    local svrAddrMgr = require("svrAddrMgr")
    local confDBSvr = svrAddrMgr.getSvr(svrAddrMgr.confDBSvr)
    local values = skynet.call(confDBSvr, "lua", "execute", strSQL)
    local values2 = {}
    for k,v in pairs(values) do
        values2[v.kid] = v
    end
    Log.dump(values2, "initDBConf:setKingdomConf values2=", 10)
    local sharedataLib = require("sharedataLib")
    if isUpdate then
        sharedataLib.update(SVRCONF_CONF_KEY_KINGDOM, values2)
    else
        sharedataLib.new(SVRCONF_CONF_KEY_KINGDOM, values2)
    end
end

-- 获取kingdom配置
function initDBConf:getKingdomConf()
    return self:getConf(SVRCONF_CONF_KEY_KINGDOM)
end

-- 设置login配置
function initDBConf:setLoginConf(isUpdate)
    local strSQL = "select * from conf_login"
    local svrAddrMgr = require("svrAddrMgr")
    local confDBSvr = svrAddrMgr.getSvr(svrAddrMgr.confDBSvr)
    local values = skynet.call(confDBSvr, "lua", "execute", strSQL)
    -- Log.dump(values, "initDBConf:setLoginConf values=", 10)
    local sharedataLib = require("sharedataLib")
    if isUpdate then
        sharedataLib.update(SVRCONF_CONF_KEY_LOGIN, values)
    else
        sharedataLib.new(SVRCONF_CONF_KEY_LOGIN, values)
    end
end

-- 获取login配置(仅login服节点有该配置)
function initDBConf:getLoginConf(nodeid)
    return self:getConf(SVRCONF_CONF_KEY_LOGIN, nodeid)
end

-- 设置gate配置
function initDBConf:setGateConf(isUpdate)
    local strSQL = "select * from conf_gate"
    local svrAddrMgr = require("svrAddrMgr")
    local confDBSvr = svrAddrMgr.getSvr(svrAddrMgr.confDBSvr)
    local values = skynet.call(confDBSvr, "lua", "execute", strSQL)
    -- Log.dump(values, "initDBConf:setGateConf values=", 10)
    local sharedataLib = require("sharedataLib")
    if isUpdate then
        sharedataLib.update(SVRCONF_CONF_KEY_GATE, values)
    else
        sharedataLib.new(SVRCONF_CONF_KEY_GATE, values)
    end
end

-- 获取gate配置(仅game服节点有该配置)
function initDBConf:getGateConf(nodeid)
    return self:getConf(SVRCONF_CONF_KEY_GATE, nodeid)
end

-- 设置notice http配置
function initDBConf:setNoticeHttp(isUpdate)
    local strSQL = "select * from conf_noticehttp"
    local svrAddrMgr = require("svrAddrMgr")
    local confDBSvr = svrAddrMgr.getSvr(svrAddrMgr.confDBSvr)
    local values = skynet.call(confDBSvr, "lua", "execute", strSQL)
    -- Log.dump(values, "initDBConf:setNoticeHttp values=", 10)
    values = values[1] or ""
    local sharedataLib = require("sharedataLib")
    if isUpdate then
        sharedataLib.update(SVRCONF_CONF_KEY_NOTICE_HTTP, values)
    else
        sharedataLib.new(SVRCONF_CONF_KEY_NOTICE_HTTP, values)
    end
end

-- 设置notice http配置
function initDBConf:getNoticeHttpConf()
    return self:getConf(SVRCONF_CONF_KEY_NOTICE_HTTP)
end

-- 设置ip白名单配置
function initDBConf:setIpWhiteListConf(isUpdate)
    local strSQL = "select * from conf_ipwhitelist"
    local svrAddrMgr = require("svrAddrMgr")
    local confDBSvr = svrAddrMgr.getSvr(svrAddrMgr.confDBSvr)
    local values = skynet.call(confDBSvr, "lua", "execute", strSQL)
    local values2 = {}
    for k, v in pairs(values) do
        values2[v.nodeid] = v
    end
    -- Log.dump(values2, "initDBConf:setIpWhiteListConf values2=", 10)
    local sharedataLib = require("sharedataLib")
    if isUpdate then
        sharedataLib.update(SVRCONF_CONF_KEY_IP_WHITE_LIST, values2)
    else
        sharedataLib.new(SVRCONF_CONF_KEY_IP_WHITE_LIST, values2)
    end
end

-- 获取ip白名单配置
function initDBConf:getIpWhiteListConf(nodeid)
    return self:getConf(SVRCONF_CONF_KEY_IP_WHITE_LIST, nodeid)
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
function initDBConf:executeGlobalDataSql()
    local sql = io.readfile("globaldata.sql")
    Log.d("initDBConf:executeGlobalDataSql sql=", sql)
    local gameDBSvr = require("svrAddrMgr").getSvr(svrAddrMgr.gameDBSvr)
    local ret = skynet.call(gameDBSvr, "lua", "execute", sql)
    Log.dump(ret, "initDBConf:executeGlobalDataSql ret=")
    assert(ret and not ret.err, "initDBConf:executeGlobalDataSql error, ret="..transformTableToString(ret))
end

-- 根据业务id一致性哈希获取global服
function initDBConf:hashGlobalCluster(id)
    if not self.globalHash then
        self.globalHash = require("conhash").new()
        self.globalCluster = {}
        local ret = self:getClusterConf()
        for k, v in pairs(ret) do
            if v.type == 2 then --cluster集群类型: 1登陆服 2全局服 3游戏服
                self.globalHash:addnode(tostring(v.nodeid), 512)
                table.insert(self.globalCluster, v)
            end
        end
    end
    return tonumber(self.globalHash:lookup(tostring(id)))
end

function initDBConf:getGlobalCluster()
    local globalCluster = {}
    local ret = self:getClusterConf()
    for k, v in pairs(ret) do
        if v.type == 2 then --cluster集群类型: 1登陆服 2全局服 3游戏服
            table.insert(globalCluster, v)
        end
    end
    return globalCluster
end

-- 打印
function initDBConf:dump()
    Log.i("====== initDBConf:dump begin======")
    local clusterConf = self:getClusterConf()
    local debugConf = self:getDebugConf()
    local httpConf = self:getHttpConf()
    local kingdomConf = self:getKingdomConf()
    local loginConf = self:getLoginConf()
    local gateConf = self:getGateConf()
    local noticeHttpConf = self:getNoticeHttpConf()
    local whiteListConf = self:getIpWhiteListConf()

    Log.dump(clusterConf, "initDBConf:dump clusterConf", 10)
    Log.dump(debugConf, "initDBConf:dump debugConf", 10)
    Log.dump(httpConf, "initDBConf:dump httpConf", 10)
    Log.dump(kingdomConf, "initDBConf:dump kingdomConf", 10)
    Log.dump(loginConf, "initDBConf:dump loginConf", 10)
    Log.dump(gateConf, "initDBConf:dump gateConf", 10)
    Log.dump(noticeHttpConf, "initDBConf:dump noticeHttpConf", 10)
    Log.dump(whiteListConf, "initDBConf:dump whiteListConf", 10)
    Log.dump(self.globalCluster, "initDBConf:dump globalCluster", 10)

    Log.i("====== initDBConf:dump end======")
end

return initDBConf

