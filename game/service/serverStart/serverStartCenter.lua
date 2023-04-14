--[[
	服务器启动服务中心
]]
local skynet = require "skynet"
local serviceCenterBase = require("serviceCenterBase2")
local serverStartCenter = class("serverStartCenter", serviceCenterBase)

-- 构造
function serverStartCenter:ctor()
	serverStartCenter.super.ctor(self)
    
	-- 不返回数据的指令集
	self.sendCmd["finishInit"] = true
end

-- 初始化
function serverStartCenter:init()
	Log.i("==serverStartCenter:init begin==")

	-- 服务器启动服务管理
    self.serverStartMgr = require("serverStartMgr").new()

    Log.i("==serverStartCenter:init end==")
end

-- 获取频道
function serverStartCenter:getChannel()
	return self.serverStartMgr:getChannel()
end

-- 获取是否所有服均已初始化好
function serverStartCenter:getIsOk()
	return self.serverStartMgr:getIsOk()
end

-- 完成初始化
function serverStartCenter:finishInit(svrName, address)
	self.serverStartMgr:finishInit(svrName, address)
end

-- 停止所有服务
function serverStartCenter:stop()
	Log.i("serverStartCenter:stop")
	return self.serverStartMgr:stop()
end

-- 收到信号停止所有服务
function serverStartCenter:stopSignal()
	Log.i("serverStartCenter:stopSignal")
	self:stop()
end

-- 加载服务器配置
function serverStartCenter:reloadConf(nodeid)
	Log.i("serverStartCenter:reloadConf", nodeid)
	require("initDBConf"):set(true)
end

return serverStartCenter
