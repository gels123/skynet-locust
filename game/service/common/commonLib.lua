--[[
	公共杂项服务接口（注: global服为分布式服, 每个global节点有一组公共杂项服务, 业务根据id映射节点和svrIdx）
]]
local skynet = require ("skynet")
local dbconf = require ("dbconf")
local svrAddrMgr = require ("svrAddrMgr")
local svrConf = require ("svrConf")
local initDBConf = require ("initDBConf")
local commonLib = class("commonLib")

commonLib.serviceNum = 16

-- 根据id返回服务id
function commonLib:svrIdx(id)
    return (id - 1)%commonLib.serviceNum + 1
end

-- 获取地址
function commonLib:getAddress(id)
    if dbconf.globalnodeid then -- global服使用本文件
        return svrAddrMgr.getSvr(svrAddrMgr.commonSvr, dbconf.globalnodeid, self:svrIdx(id))
    else -- 非global服使用本文件
        local globalnodeid = initDBConf:hashGlobalCluster(id)
        return svrConf:getSvrProxy(globalnodeid, svrAddrMgr.getSvrName(svrAddrMgr.commonSvr, globalnodeid, self:svrIdx(id)))
    end
end

-- call调用
function commonLib:call(id, ...)
    return skynet.call(self:getAddress(id), "lua", ...)
end

-- send调用
function commonLib:send(id, ...)
    skynet.send(self:getAddress(id), "lua", ...)
end

return commonLib
