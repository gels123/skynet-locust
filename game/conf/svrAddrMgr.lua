--[[
	服务地址管理
]]
local skynet = require("skynet.manager")
local svrAddrMgr = {}

--------------------------- 服务名称 BEGIN -------------------------
-- 配置数据DB服务名称
svrAddrMgr.dbSvr = ".dbSvr"
-- 本地REDIS服务名称
svrAddrMgr.redisSvr = ".redisSvr"
-- 日志服务名称
svrAddrMgr.newLoggerSvr = ".newLoggerSvr"
-- 报错信息通知服务名称
svrAddrMgr.alertSvr = ".alertSvr"
-- 启动服务名称
svrAddrMgr.startSvr = ".startSvr"
-- 公共服务名称
svrAddrMgr.commonSvr = ".commonSvr@%d@%d"
-- 数据中心服务名称
svrAddrMgr.dataCenterSvr = ".dataCenterSvr@%d@%d"
-- 协议共享服务名称
svrAddrMgr.sprotoSvr = ".sprotoSvr"
-- web服务名称
svrAddrMgr.webSvr = ".webSvr"
--------------------------- 服务名称 END ---------------------------

--------------------------- 服务地址操作 API BEGIN -------------------------
-- 获取服务名称
function svrAddrMgr.getSvrName(key, kid, otherId)
	if kid and otherId then
		return string.format(key, kid, otherId)
	elseif kid then
		return string.format(key, kid)
	elseif otherId then
		return string.format(key, otherId)
	end
	return key
end

-- 设置王国服务地址
function svrAddrMgr.setSvr(address, key, kid, otherId)
	key = svrAddrMgr.getSvrName(key, kid, otherId)
	skynet.name(key, address)
end

-- 获取服务地址
function svrAddrMgr.getSvr(key, kid, otherId)
	key = svrAddrMgr.getSvrName(key, kid, otherId)
	-- 获取本节点服务地址
	local address = skynet.localname(key)
	-- 若非本节点服务地址, 则跨节点获取服务地址
	if not address and kid then
		local svrConf = require("svrConf")
		address = svrConf:getSvrProxyGame(kid, key)
	end
	if not address then
		local errMsg = string.format("svrAddrMgr.getSvr error: %s %s %s", key, kid, otherId)
		svrFunc.exception(errMsg)
		error(errMsg)
	end
	return address
end
--------------------------- 服务地址操作 API END ---------------------------

return svrAddrMgr