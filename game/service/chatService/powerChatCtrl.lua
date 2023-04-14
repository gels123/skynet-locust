local skynet = require "skynet"
local myScheduler = require("myScheduler").new()
local json = require "json"
local cluster = require("cluster")
local chatRedisLib = require("chatRedisLib")
local dataCacheCenterLib = require("dataCacheCenterLib")
local groupBaseCtrl = require("groupBaseCtrl")
local nodeAPI = require("nodeAPI")
local powerChatCtrl = class("powerChatCtrl",groupBaseCtrl)
local EXPIRE_TIME = 86400 * 30 --一个月的过期时间

function powerChatCtrl:ctor(channelID)
	powerChatCtrl.super.ctor(self,channelID)
	self.chatKind = gChatKind.POWER_CHAT
	self.logAPI = include("logAPI").new("powerChat")
end

--[[
发送给联军频道
]]
function powerChatCtrl:send2Power(data,isNeedSelf,isCall)
	Log.dump(data,"send2Power data",10)
	Log.d("send2Power isNeedSelf,isCall",isNeedSelf,isCall)
	local kid = data.kid
	local gid = data.gid
	local uid = data.uid or 0
	local msg = data.msg
	local sKid = kid
	local curKid = kid
	local gidKey = string.format("%d",gid)
	local isLamp = false
	if msg.chatType == gChatType.HORSE_RACE_LAMP then
		isLamp = true
	end
	local userinfo = nil
	if not isLamp and uid ~= 0 then
		userinfo = dataCacheCenterLib.getAllColum(uid)
		data.sendUid = data.sendUid or data.uid

		local err = self:checkIsCanSendMsg(kid,uid,msg.text)
		if err ~= gErrDef.Err_None then
			Log.i("send2Power error",err)
			return err
		end

	    if userinfo.sKid and userinfo.sKid ~= 0 then
	    	sKid = userinfo.sKid
	    	curKid = userinfo.kid
	    end
	end
	
	local toAddr = serviceFunctions.getChatServiceAddr(gid)
	local srcAddr = serviceFunctions.getChatServiceAddr(uid)
	if toAddr ~= srcAddr and not isCall then
		skynet.send(toAddr,skynet.PTYPE_LUA,"send2Power", data,isNeedSelf,true)
	else
		local msgid = self:getMsgID()
		--插入与世界相关的数据
		local msgdata = { text=msg.text, extra=msg.extra, userinfo=userinfo, type=msg.chatType, kind=self.chatKind, id=msgid, kid=kid, gid = gid, uid=uid, sendTime=serviceFunctions.systemTime()}
			
		if not isLamp then
			self:loadGroup(self.chatKind,gid)
			local maxsize = self.config.max or 100
			table.insert(self.chatCache[gidKey],1,msgdata)
			serviceFunctions.trimTable(self.chatCache[gidKey],maxsize)
			--改变待存列表状态
			self.needSaveList[gidKey] = true
		end

		local sendMsg = {}
		sendMsg.returnType = gReturnType.insertH
		sendMsg.chatData = {}
		sendMsg.kind = self.chatKind
		table.insert(sendMsg.chatData,msgdata)

		local gateAddr = svrAddressMgr.getSvr(svrAddressMgr.chatgateSvr,nil,dbconf.chatnodeid)
		if isNeedSelf then
			skynet.send(gateAddr,skynet.PTYPE_LUA,"publishGroupMsg",gid,self.chatKind,{gid = gid,sendMsg = sendMsg})
		else
			skynet.send(gateAddr,skynet.PTYPE_LUA,"publishGroupMsg",gid,self.chatKind,{gid = gid,sendMsg = sendMsg,excludeUid = data.sendUid})
		end

		local logdata = {
	    	message = msg.text,
	    	chatType = self.chatKind
	    }
		self.logAPI:writeLog4Mgr(curKid,data.sendUid,gLogType.player_chat,logdata)
		self:setRefreshTime(self.chatKind,gid)
	end
	return err
end

--请求聊天数据
function powerChatCtrl:getPowerChatData(data,isCall,isInit)
	-- Log.dump(data,"powerChatCtrl getPowerChatData data",10)
	local kid = data.kid
	local gid = data.pid or data.gid
	local uid = data.uid
	local num = data.num
	local startIdx = data.startIdx or 1
	local endIdx = data.endIdx or num
	local sendMsg = {}
	local gidKey = tostring(gid)
	local toAddr = serviceFunctions.getChatServiceAddr(gid)
	local srcAddr = serviceFunctions.getChatServiceAddr(uid)

	--还需要判断是否是同一个服务
	if toAddr == srcAddr or isCall then
		self:loadGroup(self.chatKind,gid)
		if isCall then
			return {kind = self.chatKind,chatData = serviceFunctions.getTableByRange(self.chatCache[gidKey],startIdx,endIdx)}
		else
			sendMsg = {kind = self.chatKind,chatData = serviceFunctions.getTableByRange(self.chatCache[gidKey],startIdx,endIdx)}
		end
		self:setRefreshTime(self.chatKind,gid)
	else
		local ok,ret = skynet.call(toAddr,skynet.PTYPE_LUA,"getPowerChatData",data,true)
		sendMsg = ret
	end
	
	self:filterGDPR(sendMsg)
	if isInit then
		return sendMsg
	else
		sendMsg.returnType = gReturnType.insertT
		local key = string.format("%d_%d",self.chatKind,gid)
		self:send2Gate(key, sendMsg, gChatSubscribeType.group,0,uid)
	end
end

return powerChatCtrl