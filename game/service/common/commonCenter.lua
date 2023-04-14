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
	-- 全局掉落管理器
	self.dropLimitMgr = require("dropLimitMgr").new()
	self.dropLimitMgr:init()
	-- 拍卖行管理器
	--self.tradeMgr = require("tradeMgr").new()
	--self.tradeMgr:init()

    Log.i("==commonCenter:init end==", kid, idx)
end

function commonCenter:checkDropLimit(itemId,cnt,limit)
	if self.dropLimitMgr then
		local ret = self.dropLimitMgr:checkDropLimit(itemId,cnt,limit)
		return ret
	end
	return 0
end

return commonCenter
