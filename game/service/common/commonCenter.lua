--[[
	公共杂项服务中心
]]
local skynet = require "skynet"
local serviceCenterBase = require("serviceCenterBase2")
local commonCenter = class("commonCenter", serviceCenterBase)

-- 构造
function commonCenter:ctor()
	commonCenter.super.ctor(self)
    
	-- 不返回数据的指令集
	--self.sendCmd["xxxx"] = true
end

-- 初始化
function commonCenter:init(kid, idx)
	Log.i("==commonCenter:init begin==", kid, idx)

	-- 王国ID
	self.kid = kid
	self.idx = idx
	-- 拍卖行管理器
	--self.tradeMgr = require("tradeMgr").new()
	--self.tradeMgr:init()

    Log.i("==commonCenter:init end==", kid, idx)
end

return commonCenter
