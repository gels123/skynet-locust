local skynet = require("skynet")
local cluster = require("cluster")
local initDBConf = require("initDBConf")
local svrConf = class("svrConf")

-- 获取跨节点服务代理
function svrConf:getSvrProxy(nodeid, svrName)
    local clusterConf = initDBConf:getClusterConf(nodeid)
    return cluster.proxy(clusterConf.nodename, svrName)
end

return svrConf

