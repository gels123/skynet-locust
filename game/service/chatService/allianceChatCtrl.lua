local skynet = require "skynet"
local myScheduler = require("myScheduler").new()
local json = require "json"
local cluster = require("cluster")
local chatRedisLib = require("chatRedisLib")
local dataCacheCenterLib = require("dataCacheCenterLib")
local groupBaseCtrl = require("groupBaseCtrl")
local nodeAPI = require("nodeAPI")
local allianceChatCtrl = class("allianceChatCtrl",groupBaseCtrl)
local EXPIRE_TIME = 86400 * 30 --一个月的过期时间

function allianceChatCtrl:ctor(channelID)
	allianceChatCtrl.super.ctor(self,channelID)
	self.chatKind = gChatKind.ALLIANCE_CHAT
	self.logAPI = include("logAPI").new("allianceChat")
end

--创建联盟
function allianceChatCtrl:createGroup(chatKind,data)
	allianceChatCtrl.super.createGroup(self,chatKind,data)
	local chatdata = {
        kid = data.kid,
        aid = data.gid,
        uid = data.uid,
        msg = {
            chatType = gChatType.BROADCAST,
            text = gSysBroadcastType.alliance_notice_create,
            extra = {name = data.name},
        }
    }
	self:send2Alliance(chatdata,true)
end

--[[
退出联盟（主动和被动）
]]
function allianceChatCtrl:quitGroup(chatKind,data,isInitiative)
	Log.d("allianceChatCtrl:quitGroup",isInitiative)
	allianceChatCtrl.super.quitGroup(self,chatKind,data)
	local name = dataCacheCenterLib.getColum(data.uid, "nickName")
	local chatdata = {
		kid = data.kid,
        aid = data.gid,
        uid = data.optUid or data.uid,
        msg = {
            chatType = gChatType.BROADCAST,
            text = gSysBroadcastType.alliance_notice_exit,
            extra = {name = name},
        }
	}
	if isInitiative then
		chatdata.msg.text = gSysBroadcastType.alliance_notice_exit
	else
		chatdata.msg.text = gSysBroadcastType.alliance_notice_kick
	end
	self:send2Alliance(chatdata,true)
end

--[[
加入联盟
]]
function allianceChatCtrl:joinGroup(chatKind,data,isCreate)
	Log.d("allianceChatCtrl:joinGroup",isCreate)
	allianceChatCtrl.super.joinGroup(self,chatKind,data)
	if not isCreate then
		local chatdata = {
	        kid = data.kid,
	        aid = data.gid,
	        uid = data.uid,
	        msg = {
	            chatType = gChatType.BROADCAST,
	            text = gSysBroadcastType.alliance_notice_join,
	            extra = {x=data.x,y=data.y},
	        }
	    }
		self:send2Alliance(chatdata,true)
	end
end

--[[
发送给联盟频道
]]
function allianceChatCtrl:send2Alliance(data,isNeedSelf,isCall)
	Log.dump(data,"send2Alliance data",10)
	Log.d("send2Alliance isNeedSelf,isCall",isNeedSelf,isCall)
	local kid = data.kid
	local gid = data.aid
	local uid = data.uid or gid
	local msg = data.msg
	local sKid = kid
	local curKid = kid
	local gidKey = string.format("%d",gid)
	local isLamp = false
	if msg.chatType == gChatType.HORSE_RACE_LAMP then
		isLamp = true
	end
	local userinfo = nil
	if not isLamp then
		userinfo = dataCacheCenterLib.getAllColum(uid)
		data.sendUid = data.sendUid or data.uid

		local err = self:checkIsCanSendMsg(kid,uid,msg.text)
		if err ~= gErrDef.Err_None then
			Log.i("send2Alliance error",err)
			return err
		end

	    if userinfo.sKid and userinfo.sKid ~= 0 then
	    	sKid = userinfo.sKid
	    	curKid = userinfo.kid
	    end
	end
	if svrconf.isInSameServer(curKid,sKid) or isCall then
		local toAddr = serviceFunctions.getChatServiceAddr(gid)
		local srcAddr = serviceFunctions.getChatServiceAddr(uid)
		if toAddr ~= srcAddr and not isCall then
			skynet.send(toAddr,skynet.PTYPE_LUA,"send2Alliance", data,isNeedSelf,true)
		else
			local msgid = self:getMsgID()
			--插入与世界相关的数据
			local msgdata = { text=msg.text, extra=msg.extra, userinfo=userinfo, type=msg.chatType, kind=self.chatKind, id=msgid, kid=kid, aid = gid, uid=uid, sendTime=serviceFunctions.systemTime()}
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

			--发送手机推送
			local nodeid = svrconf.getNodeIDByKingdomID(curKid)
			local svrName = string.format(svrAddressMgr.externalSvr, curKid)
			local address = nodeAPI.getSvrProxy(nodeid,svrName)
			local chatType = 4
			if msg.chatType and msg.chatType == gChatType.EMOTICON then
				chatType = 3
			end
			xpcall(skynet.send, serviceFunctions.exception, address, "lua", "allianceChatNotice",gid,{aid=gid,type=chatType,content={text=msg.text},nickName=userinfo.nickName})
			self:setRefreshTime(self.chatKind,gid)
		end
	else
		local nodename,addr = svrconf.getChatAddr(sKid,gid)
		cluster.send(nodename,addr,"send2Alliance",data,isNeedSelf,true)
	end
	return err
end

--请求聊天室聊天数据
function allianceChatCtrl:getAllianceChatData(data,isCall,isInit)
	Log.dump(data,"allianceChatCtrl getAllianceChatData data",10)
	local kid = data.kid
	local aid = data.aid
	local uid = data.uid
	local num = data.num
	local startIdx = data.startIdx or 1
	local endIdx = data.endIdx or num
	local sendMsg = {}
	local aidKey = tostring(aid)
	local toAddr = serviceFunctions.getChatServiceAddr(aid)
	local srcAddr = serviceFunctions.getChatServiceAddr(uid)
	local cKid = dataCacheCenterLib.getColum(uid, "kid") or kid
	local sKid = dataCacheCenterLib.getColum(uid, "sKid") or 0
	if not sKid or sKid == 0 then
		sKid = cKid
	end
	--如果不相同王国且地址又不一样的时候要跨到其他聊天服取数据
	if svrconf.isInSameServer(cKid,sKid) or isCall then
		--还需要判断是否是同一个服务
		if toAddr == srcAddr or isCall then
			self:loadGroup(self.chatKind,aid)
			if isCall then
				return {kind = self.chatKind,chatData = serviceFunctions.getTableByRange(self.chatCache[aidKey],startIdx,endIdx)}
			else
				sendMsg = {kind = self.chatKind,chatData = serviceFunctions.getTableByRange(self.chatCache[aidKey],startIdx,endIdx)}
			end
			self:setRefreshTime(self.chatKind,aid)
		else
			local ok,ret = skynet.call(toAddr,skynet.PTYPE_LUA,"getAllianceChatData",data,true)
			sendMsg = ret
		end
	else
		local nodename,addr = svrconf.getChatAddr(sKid,aid)
		local ok,ret = cluster.call(nodename,addr,"getAllianceChatData",data,true)
		sendMsg = ret
	end
	
	self:filterGDPR(sendMsg)
	if isInit then
		return sendMsg
	else
		sendMsg.returnType = gReturnType.insertT
		local key = string.format("%d_%d",self.chatKind,aid)
		self:send2Gate(key, sendMsg, gChatSubscribeType.group,0,uid)
	end
end

return allianceChatCtrl