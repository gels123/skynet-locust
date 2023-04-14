--[[
	群组聊天基类
	和聊天室相比减少成员管理模块
	联盟、联军、势力使用该基类
]]
local skynet = require "skynet"
local myScheduler = require("myScheduler").new()
local json = require "json"
local cluster = require("cluster")
local chatRedisLib = require("chatRedisLib")
local dataCacheCenterLib = require("dataCacheCenterLib")
local chatBaseCtrl = require("chatBaseCtrl")
local nodeAPI = require("nodeAPI")
local groupBaseCtrl = class("groupBaseCtrl",chatBaseCtrl)
local EXPIRE_TIME = 86400 * 30 --一个月的过期时间

function groupBaseCtrl:ctor(channelID)
	groupBaseCtrl.super.ctor(self,channelID)
	self.groupRefreshTime = {}
	local time = serviceFunctions.systemTime() + 300
	myScheduler:schedule(handler(self,self.clearDueCache),time,nil,true)
    myScheduler:start()
end

--[[
加载群组聊天
]]
function groupBaseCtrl:loadGroup( chatKind, gid )
	-- Log.d("groupBaseCtrl:loadGroup",chatKind,gid)
	--从数据库加载出群组
	local gidKey = string.format("%d",gid)
	if not self.chatCache[gidKey] then
		serviceFunctions.makeTable(self.chatCache,gidKey)
		local pushkey = string.format("%s_%d",gGroupKey[chatKind],gid)
		self.chatCache[gidKey] = self:loadData(pushkey)
		-- Log.dump(self.chatCache[gidKey],"self.group".. gid,10)
	end
end

--[[
	验证是否可以进行聊天
]]
function groupBaseCtrl:checkIsCanSendMsg(kid,uid,text)
	local GDPRSvr = svrAddressMgr.getSvr(svrAddressMgr.GDPRSvr)
	local GDPR = skynet.call(GDPRSvr, "lua", "getUserGDPRStatus", {uid})
	if GDPR and GDPR[1] and GDPR[1].status == 1 then
		return gErrDef.Err_BE_GDPR
	end
	local err = self:supervise(kid,uid,text)
	if err ~= gErrDef.Err_None then
		return err
	end

	if string.utf8len(text) > self.config.maxlen then
    	return gErrDef.Err_CHAT_LENGTH_OUT
    end
    return gErrDef.Err_None
end

--[[
创建群组
]]
function groupBaseCtrl:createGroup(chatKind,data)
	-- Log.dump(data,"createGroup data",10)
	local gid = string.format("%d",data.gid)
	local gateAddr = svrAddressMgr.getSvr(svrAddressMgr.chatgateSvr,nil,dbconf.chatnodeid)
	skynet.call(gateAddr,skynet.PTYPE_LUA,"makeGroupBroadcast",data.gid)
	self:joinGroup(chatKind,data,true)
end

--[[
加入群组
]]
function groupBaseCtrl:joinGroup(chatKind,data)
	-- Log.dump(data,"joinGroup data",10)
	if data.uid and data.uid ~= 0 then
		local gid = string.format("%d",data.gid)
		local groupBCSvr = serviceFunctions.getBCServiceAddr(BC_SERVICE_INSTANCE,gChatSubscribeType.group,data.uid)
		skynet.call(groupBCSvr,skynet.PTYPE_LUA,"connect",chatKind,data.gid,data.uid)
		local gateAddr = svrAddressMgr.getSvr(svrAddressMgr.chatgateSvr,nil,dbconf.chatnodeid)
		skynet.send(gateAddr,skynet.PTYPE_LUA,"subscribeOneBroadcast",gChatSubscribeType.group,data.gid,data.uid)
		local sendMsg = {}
		local chatData = {
			chatData = {},
			kind = chatKind,
		}
		sendMsg.returnType = gReturnType.init
		if chatKind == gChatKind.ALLIANCE_CHAT then
			sendMsg.allianceChatData = chatData
		elseif chatKind == gChatKind.FORCE_CHAT then
			sendMsg.forceChatData = chatData
		elseif chatKind == gChatKind.POWER_CHAT then
			sendMsg.powerChatData = chatData
		elseif chatKind == gChatKind.TEAM_CHAT then
			sendMsg.powerChatData = chatData
		end
		local key = string.format("%d_%d",self.chatKind,gid)
		self:send2Gate(key, sendMsg, gChatSubscribeType.group,nil,data.uid)
	end
end

--[[
退出联盟（主动和被动）
]]
function groupBaseCtrl:quitGroup(chatKind,data)
	-- Log.dump(data,"quitGroup data",10)
	local sendMsg = {}
	sendMsg.returnType = gReturnType.clear
	sendMsg.chatData = {}
	sendMsg.kind = chatKind
	table.insert(sendMsg.chatData,{})
	local key = string.format("%d_%d",self.chatKind,data.gid)
	self:send2Gate(key, sendMsg, gChatSubscribeType.group,nil,data.uid)
	local groupBCSvr = serviceFunctions.getBCServiceAddr(BC_SERVICE_INSTANCE,gChatSubscribeType.group,data.uid)
	skynet.send(groupBCSvr,skynet.PTYPE_LUA,"disconnect",chatKind,data.gid,data.uid,true)
end

--[[
解散联盟
]]
function groupBaseCtrl:dimissGroup(chatKind,data)
	Log.dump(data,"dimissGroup data",10)
	local bcStr = string.format("%d_%d",chatKind,data.gid)
	local gateAddr = svrAddressMgr.getSvr(svrAddressMgr.chatgateSvr,nil,dbconf.chatnodeid)
	skynet.call(gateAddr,skynet.PTYPE_LUA,"unSubscribeAllBroadcast",gChatSubscribeType.group,bcStr)
	local pushkey = string.format("%s_%d",gGroupKey[chatKind],data.gid)
	chatRedisLib.delete(self.channelID,pushkey)
	self.chatCache[tostring(data.gid)] = nil
end

--[[
	设置刷新时间
]]
function groupBaseCtrl:setRefreshTime(chatKind,gid)
	if not self.groupRefreshTime[chatKind] then
		self.groupRefreshTime[chatKind] = {}
	end
	self.groupRefreshTime[chatKind][tostring(gid)] = serviceFunctions.systemTime()
end

--[[
	清理缓存
]]
function groupBaseCtrl:clearDueCache()
	Log.d("groupBaseCtrl:clearDueCache")
	for chatKind,data in pairs(self.groupRefreshTime) do
		for gidKey,time in pairs(data) do
			if time < serviceFunctions.systemTime() - 300 then
				self.chatCache[gidKey] = nil
			end
		end
	end
end

return groupBaseCtrl