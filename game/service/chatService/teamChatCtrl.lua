--[[
	与roomChatCtrl相比没有成员管理的聊天  
]]
local skynet = require "skynet"
local myScheduler = require("myScheduler").new()
local json = require "json"
local cluster = require("cluster")
local chatRedisLib = require("chatRedisLib")
local dataCacheCenterLib = require("dataCacheCenterLib")
local groupBaseCtrl = require("groupBaseCtrl")
local nodeAPI = require("nodeAPI")
local teamChatCtrl = class("teamChatCtrl",groupBaseCtrl)
local EXPIRE_TIME = 86400 * 30 --一个月的过期时间

function teamChatCtrl:ctor(channelID)
	teamChatCtrl.super.ctor(self,channelID)
	self.chatKind = gChatKind.TEAM_CHAT
	self.logAPI = include("logAPI").new("teamChat")
end

--创建
function teamChatCtrl:createGroup(chatKind,data)
	teamChatCtrl.super.createGroup(self,chatKind,data)
	-- local chatdata = {
 --        kid = data.kid,
 --        gid = data.gid,
 --        uid = data.uid,
 --        msg = {
 --            chatType = gChatType.BROADCAST,
 --            text = gSysBroadcastType.team_notice_create,
 --            extra = {name = data.name},
 --        }
 --    }
	-- self:send2Team(chatdata,true)
end

--[[
退出（主动和被动）
]]
function teamChatCtrl:quitGroup(chatKind,data,isInitiative)
	teamChatCtrl.super.quitGroup(self,chatKind,data)
	local name = dataCacheCenterLib.getColum(data.uid, "nickName")
	local chatdata = {
		kid = data.kid,
        gid = data.gid,
        uid = data.optUid or data.uid,
        msg = {
            chatType = gChatType.BROADCAST,
            text = gSysBroadcastType.team_notice_exit,
            extra = {name = name},
        }
	}
	if isInitiative then
		chatdata.msg.text = gSysBroadcastType.team_notice_exit
	else
		chatdata.msg.text = gSysBroadcastType.team_notice_kick
	end
	self:send2Team(chatdata,true)
end

--[[
加入
]]
function teamChatCtrl:joinGroup(chatKind,data,isCreate)
	teamChatCtrl.super.joinGroup(self,chatKind,data)
	if not isCreate then
		local chatdata = {
	        kid = data.kid,
	        gid = data.gid,
	        uid = data.uid,
	        msg = {
	            chatType = gChatType.BROADCAST,
	            text = gSysBroadcastType.team_notice_join,
	        }
	    }
		self:send2Team(chatdata,false)
	end
end

--[[
发送给联军频道
]]
function teamChatCtrl:send2Team(data,isNeedSelf,isCall)
	Log.dump(data,"send2Team data",10)
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
			Log.i("send2Team error",err)
			return err
		end
		if userinfo and userinfo.sKid and userinfo.sKid ~= 0 then
	    	sKid = userinfo.sKid
	    	curKid = userinfo.kid
	    end
	end

	local toAddr = serviceFunctions.getChatServiceAddr(gid)
	local srcAddr = serviceFunctions.getChatServiceAddr(uid)
	Log.d("send2Team isNeedSelf,isCall",isNeedSelf,isCall,srcAddr,toAddr)
	if toAddr ~= srcAddr and not isCall then
		skynet.send(toAddr,skynet.PTYPE_LUA,"send2Team", data,isNeedSelf,true)
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
function teamChatCtrl:getTeamChatData(data,isCall,isInit)
	Log.dump(data,"teamChatCtrl getTeamChatData data",10)
	local kid = data.kid
	local gid = data.gid
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
		local ok,ret = skynet.call(toAddr,skynet.PTYPE_LUA,"getTeamChatData",data,true)
		sendMsg = ret
	end
	
	if data.isInit then
		local groupBCSvr = serviceFunctions.getBCServiceAddr(BC_SERVICE_INSTANCE,gChatSubscribeType.group,uid)
		skynet.call(groupBCSvr,skynet.PTYPE_LUA,"connect",self.chatKind,gid,uid)
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

return teamChatCtrl