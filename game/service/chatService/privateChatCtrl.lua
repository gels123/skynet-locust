local skynet = require "skynet"
local myScheduler = require("myScheduler").new()
local json = require "json"
local cluster = require("cluster")
local chatBaseCtrl = require("chatBaseCtrl")
local dataCacheCenterLib = require("dataCacheCenterLib")
local chatRedisLib = require("chatRedisLib")
local nodeAPI = require("nodeAPI")
local privateChatCtrl = class("privateChatCtrl",chatBaseCtrl)
local EXPIRE_TIME = 86400 * 30 --一个月的过期时间
local INIT_INDEX = 1
function privateChatCtrl:ctor(channelID)
	privateChatCtrl.super.ctor(self,channelID)
	--玩家联系人
	self.userContacts = {
		--[[["uid"] = 
		{
			contacts = {uid1_time,uid2_time,...},
			time = 12313123 --记入写入时间，用于清缓存
		},
		]]
	}
	--已经初始化过的聊天
	self.alreadyInit = {
		--[[
			[uid] = {uid1,uid2}
		]]
	}
	self.chatKind = gChatKind.PRIVATE_CHAT
    local time = serviceFunctions.systemTime() + 300
    myScheduler:schedule(handler(self,self.clearDueCache),time,nil,true)
    myScheduler:start()
    self.logAPI = include("logAPI").new("privateChat")
end

--[[
加载私聊
]]
function privateChatCtrl:loadPrivate(uid,toUid)
	--从数据库加载出私聊
	if not self.chatCache[uid.."_"..toUid] then
		serviceFunctions.makeTable(self.chatCache,uid.."_"..toUid)
		local pushkey = self:privateContentKey(uid,toUid)
		self.chatCache[uid.."_"..toUid] = self:loadData(pushkey)
		-- Log.dump(self.chatCache[uid.."_"..toUid],"self.loadPrivate"..uid.."_"..toUid,10)
	end
	return true,serviceFunctions.getTableByRange(self.chatCache[uid.."_"..toUid],1,INIT_INDEX)
end

--获取聊天初始化数据
function privateChatCtrl:getInitPrivateChatData(data,privateList,isInit)
	-- Log.dump(data,"privateChatCtrl:getInitPrivateChatData data",10)
	local kid = data.kid
	local uid = data.uid
	local uidK = tostring(uid)
	self.userContacts[uidK] = {}
	local sendMsg = {}
	local success , contacts = chatRedisLib.sMembers( self.channelID, self:getUserContactsKey(uid) )
	if success and contacts and next(contacts) then
		self.userContacts[uidK].time = serviceFunctions.systemTime()
		self.userContacts[uidK].contacts = contacts
		if isInit then
			self.alreadyInit[uid] = {}
		end
		for _,v in pairs(privateList) do
			for _,vv in pairs(contacts) do
				local toUid, time = self:divideContacts(vv)
				if toUid == tonumber(v.ID) then
					local have,ret = self:getOneInitPrivateChatData({kid=kid,uid=uid,toUid=toUid})
					if have then
						ret.touserinfo = dataCacheCenterLib.getAllColum(toUid)
						ret.privateID = string.format("%d_%d_%d",uid,toUid,time)
						local _,score = chatRedisLib.zScore(self.channelID,"user_chat_list"..uid,string.format("%d_%d",gChatKind.PRIVATE_CHAT,toUid))
						ret.alreadyReadTime = tonumber(score) % 10000000
						ret.isTop = v.isTop
						table.insert(sendMsg,ret)
						table.insert(self.alreadyInit[uid],toUid)
					else
						Log.i("getInitPrivateChatData ",kid,uid,toUid)
					end
				end
			end
		end
	end
	return sendMsg
end

--获取单一聊天室初始化数据
function privateChatCtrl:getOneInitPrivateChatData(data)
	-- Log.dump(data,"getOneInitPrivateChatData data",10)
	local kid = data.kid
	local uid = data.uid
	local toUid = data.toUid
	local privateChatData = {}
	local have = false
	
	local ok,chatData = self:loadPrivate(uid,toUid)
	if ok then
		if next(chatData) then
			have = true
			privateChatData = {kind = gChatKind.PRIVATE_CHAT,chatData = serviceFunctions.getTableByRange(chatData,1,1)}
		else
			chatRedisLib.zRem(self.channelID,"user_chat_list"..uid,string.format("%d_%d",gChatKind.PRIVATE_CHAT,toUid))
		end
	end

	-- Log.dump(privateChatData,"getOneInitprivateChatData privateChatData",10)
	return have,privateChatData
end

--[[
请求私有聊天数据
]]
function privateChatCtrl:getPrivateChatData(data)
	Log.dump(data,"privateChatCtrl:getPrivateChatData data",10)
	local kid = data.kid
	local uid = data.uid
	local toUid = data.toUid
	local num = data.num
	local startIdx = data.startIdx or 1
	local endIdx = data.endIdx or num
	local uidK = tostring(uid)
	local isInit = data.isInit
	if type(kid) ~= "number" or type(uid) ~= "number" or type(toUid) ~= "number" then
		Log.e("privateChatCtrl:getPrivateChatDat send data error")
		return
	end
	local sendMsg = {}
	sendMsg.returnType = gReturnType.insertT
	local beFriendTime = 0
	if self.userContacts[uidK] and next(self.userContacts[uidK]) and self.userContacts[uidK].contacts then
		for _,v in pairs(self.userContacts[uidK].contacts) do
			local friendUid, time = self:divideContacts(v)
			if friendUid == toUid then
				have = true
				beFriendTime = time
				break
			end
		end
		if have then
			if not self.chatCache[uid.."_"..toUid] then
				self:loadPrivate(uid,toUid)
			end
			if isInit then
				local data = {kind = gChatKind.PRIVATE_CHAT,chatData = serviceFunctions.getTableByRange(self.chatCache[uid.."_"..toUid],startIdx,endIdx)}
				self:filterGDPR(data)
				data.touserinfo = dataCacheCenterLib.getAllColum(toUid)
				data.privateID = string.format("%d_%d_%d",uid,toUid,beFriendTime)
				sendMsg.privateChatData = {}
				table.insert(sendMsg.privateChatData,data)
				sendMsg.returnType = gReturnType.init
			else
				sendMsg = {kind = gChatKind.PRIVATE_CHAT,chatData = serviceFunctions.getTableByRange(self.chatCache[uid.."_"..toUid],startIdx,endIdx)}
				self:filterGDPR(data)
				sendMsg.privateID = string.format("%d_%d_%d",uid,toUid,beFriendTime)
				sendMsg.returnType = gReturnType.insertT
			end
		else
			sendMsg.kind = gChatKind.PRIVATE_CHAT
			sendMsg.chatData = {}
		end
	end
	
	Log.dump(sendMsg,"privateChatCtrl:getPrivateChatData sendMsg",10)
	self:send2Client(uid, sendMsg)

end

--[[
发送给某一个玩家
]]
function privateChatCtrl:send2user(data,isNeedSelf)
	-- Log.dump(data,"privateChatCtrl:send2user data",10)
	local kid = data.kid
	local uid = data.uid
	local toUid = data.toUid
	local msg = data.msg
	data.sendUid = data.sendUid or data.uid
	if type(kid) ~= "number" or type(uid) ~= "number" or type(toUid) ~= "number" or type(msg) ~= "table" then
		Log.e("privateChatCtrl:getPrivateChatDat send data error")
		return
	end
	local userinfo = dataCacheCenterLib.getAllColum(uid,kid)
	local uidK = tostring(uid)
	local GDPRSvr = svrAddressMgr.getSvr(svrAddressMgr.GDPRSvr)
	local GDPR = skynet.call(GDPRSvr, "lua", "getUserGDPRStatus", {uid})
	if GDPR and GDPR[1] and GDPR[1].status == 1 then
		return gErrDef.Err_BE_GDPR
	end
	local shieldList = dataCacheCenterLib.getUserShieldList(toUid)
	if shieldList then
		for _,sheildUid in pairs(shieldList) do
	        if sheildUid == uid then
	           return gErrDef.Err_BE_SHIELD
	        end
	    end
	end

	local err = self:supervise(kid,uid,msg.text,toUid)
	if err ~= gErrDef.Err_None then
		return err
	end

	if string.utf8len(msg.text) > self.config.maxlen then
    	return gErrDef.Err_CHAT_LENGTH_OUT
    end

	data.msg = msg
	local alreadyInit = false
	if self.alreadyInit[uid] then
		for _,id in pairs(self.alreadyInit[uid]) do
			if id == toUid then
				alreadyInit = true
				break
			end
		end
	else
		self.alreadyInit[uid] = {}
	end

	local maxsize = self.config.max or 50
	serviceFunctions.makeTable(self.chatCache, uid.."_"..toUid)
	--裁剪的大小,原始数组长度
	serviceFunctions.trimTable(self.chatCache[uid.."_"..toUid],maxsize)
	
	local msgid = self:getMsgID()
	data.msgid = msgid

	--插入与玩家相关的数据
	local msgdata = {text=msg.text,type=msg.chatType,extra=msg.extra, userinfo=userinfo, id=msgid, kid=kid, uid=data.sendUid, sendTime=serviceFunctions.systemTime()}
	table.insert(self.chatCache[uid.."_"..toUid],1,msgdata)

	self.needSaveList[uid.."_"..toUid] = true
	
	local time = serviceFunctions.systemTime()
	local haveFriend = false
	local beFriendTime = time
	if self.userContacts[uidK] and self.userContacts[uidK].contacts then
		self.userContacts[uidK].time = serviceFunctions.systemTime()
	else
		self.userContacts[uidK] = {}
		self.userContacts[uidK].contacts = {}
		local success , contacts = chatRedisLib.sMembers( self.channelID, self:getUserContactsKey(uid) )
		if success and contacts and next(contacts) then
			self.userContacts[uidK].contacts = contacts
		end
		self.userContacts[uidK].time = serviceFunctions.systemTime()
	end
	for _,v in pairs(self.userContacts[uidK].contacts) do
		local friendUid, time = self:divideContacts(v)
		if friendUid == toUid then
			haveFriend = true
			beFriendTime = time
			break
		end
	end
	if not haveFriend and not alreadyInit then
		table.insert(self.userContacts[uidK].contacts,string.format("%d".."_".."%d", toUid,time))
		skynet.fork(function ()
			chatRedisLib.sAdd( self.channelID, self:getUserContactsKey(uid), string.format("%d".."_".."%d", toUid,time))
		end)
	end
	local touserinfo = dataCacheCenterLib.getAllColum(toUid)
	if not alreadyInit or isNeedSelf then
		local sendMsg = {}
		sendMsg.returnType = gReturnType.init
		sendMsg.privateChatData = {}
		local data = {}
		data.chatData = {}
		table.insert(data.chatData,msgdata)
		data.kind = gChatKind.PRIVATE_CHAT
		data.privateID = string.format("%d_%d_%d",uid,toUid,beFriendTime)
		data.touserinfo = touserinfo
		table.insert(sendMsg.privateChatData,data)
		self:send2Client(uid, sendMsg)
		table.insert(self.alreadyInit[uid],toUid)
	end

	--添加到玩家聊天排序表中
	skynet.fork(function (  )
		local ok,score = chatRedisLib.zScore(self.channelID,"user_chat_list"..uid,string.format("%d_%d",gChatKind.PRIVATE_CHAT,toUid))
		if not ok or not score or tonumber(score) < 20000000000000000 then
			chatRedisLib.zAdd(self.channelID,"user_chat_list"..uid,time*10000000,string.format("%d_%d",gChatKind.PRIVATE_CHAT,toUid))
		end
	end)

	--给接收方发信息
	if svrconf.isInSameServer(kid,touserinfo.kid) then
		local toAddr = serviceFunctions.getChatServiceAddr(toUid)
		local srcAddr = serviceFunctions.getChatServiceAddr(uid)
		if toAddr ~= srcAddr then
			skynet.send(toAddr,skynet.PTYPE_LUA,"recv4user", data )
		else
			self:recv4user(data)
		end
	else --广播到其它服务器
		local nodename,addr = svrconf.getChatAddr(touserinfo.kid,toUid)
		cluster.send(nodename,addr,"recv4user",data)
	end
	--发送手机推送
	if msg.chatType == gChatType.DEFAULT then
		local nodeid = svrconf.getNodeIDByKingdomID(touserinfo.kid)
		local svrName = string.format(svrAddressMgr.externalSvr, touserinfo.kid)
		local address = nodeAPI.getSvrProxy(nodeid,svrName)
		xpcall(skynet.send, serviceFunctions.exception, address, "lua", "privateChatNotice",toUid,userinfo.nickName,msg.text)
	end

	local logdata = {
    	receiver = toUid,
    	sender = uid,
    	mailData = msg,
    	status = 1,
    }
	self.logAPI:writeLog4Mgr(kid,uid,gLogType.pm_log,logdata)
end

--[[
收到某一玩家的消息
]]
function privateChatCtrl:recv4user(data)
	-- Log.dump(data,"privateChatCtrl:recv4user(data)",10)
	local kid = data.kid
	local uid = data.uid
	local toUid = data.toUid
	local msg = data.msg 
	local userinfo = dataCacheCenterLib.getAllColum(uid,kid)
	local msgid = data.msgid
	local toUidK = tostring(toUid)

	if self.userContacts[toUidK] then
		self.userContacts[toUidK].time = serviceFunctions.systemTime()
	end

	local alreadyInit = false
	if self.alreadyInit[toUid] then
		for _,id in pairs(self.alreadyInit[toUid]) do
			if id == uid then
				alreadyInit = true
				break
			end
		end
	else
		self.alreadyInit[toUid] = {}
	end

	local maxsize = self.config.max or 50
	serviceFunctions.makeTable(self.chatCache, toUid.."_"..uid)
	--裁剪的大小,原始数组长度
	serviceFunctions.trimTable(self.chatCache[toUid.."_"..uid],maxsize)
	
	--插入与玩家相关的数据
	local msgdata = {text=msg.text,type=msg.chatType,extra=msg.extra, userinfo=userinfo, id=msgid, kid=kid, uid=data.sendUid, sendTime=serviceFunctions.systemTime()}
	table.insert(self.chatCache[toUid.."_"..uid],1,msgdata)

	self.needSaveList[toUid.."_"..uid] = true

	if not self.userContacts[toUidK] or not self.userContacts[toUidK].contacts then
		self.userContacts[toUidK] = {}
		self.userContacts[toUidK].contacts = {}
		self.userContacts[toUidK].time = serviceFunctions.systemTime()
		local success , contacts = chatRedisLib.sMembers( self.channelID, self:getUserContactsKey(toUid) )
		if success and contacts and next(contacts) then
			self.userContacts[toUidK].contacts = contacts
		end
	end

	local time = serviceFunctions.systemTime()
	local haveFriend = false
	local beFriendTime = time	
	for _,v in pairs(self.userContacts[toUidK].contacts) do
		local friendUid, time = self:divideContacts(v)
		if friendUid == uid then
			haveFriend = true
			beFriendTime = time
			break
		end
	end
	
	if not haveFriend and not alreadyInit then
		table.insert(self.userContacts[toUidK].contacts,string.format("%d".."_".."%d", uid,time))
		skynet.fork(function ()
			local ok,score = chatRedisLib.zScore(self.channelID,"user_chat_list"..uid,string.format("%d_%d",gChatKind.PRIVATE_CHAT,toUid))
			if not ok or not score or tonumber(score) < 20000000000000000 then
				chatRedisLib.sAdd( self.channelID, self:getUserContactsKey(toUid), string.format("%d".."_".."%d", uid,time))
			end
		end)
	end
	local sendMsg = {}
	if alreadyInit then
		sendMsg.chatData = {}
		sendMsg.kind = gChatKind.PRIVATE_CHAT
		sendMsg.returnType = gReturnType.insertH
		sendMsg.privateID = string.format("%d_%d_%d",toUid,uid,beFriendTime)
		table.insert(sendMsg.chatData,msgdata)
	else
		sendMsg.privateChatData = {}
		sendMsg.returnType = gReturnType.init
		local data = {}
		data.kind = gChatKind.PRIVATE_CHAT
		data.chatData = {}
		table.insert(data.chatData,msgdata)
		data.privateID = string.format("%d_%d_%d",toUid,uid,serviceFunctions.systemTime())
		data.touserinfo = userinfo
		table.insert(sendMsg.privateChatData,data)
		table.insert(self.alreadyInit[toUid],uid)
	end
	--刷新玩家聊天排序表中
	skynet.fork(function (  )
		local ok,score = chatRedisLib.zScore(self.channelID,"user_chat_list"..toUid,string.format("%d_%d",gChatKind.PRIVATE_CHAT,uid))
		if not ok or not score or tonumber(score) < 20000000000000000 then
			chatRedisLib.zAdd(self.channelID,"user_chat_list"..toUid,time*10000000,string.format("%d_%d",gChatKind.PRIVATE_CHAT,uid))
		end
	end)
	self:send2Client(toUid, sendMsg)
end

--删除缓存
function privateChatCtrl:clearDueCache()
	-- Log.dump(self.userContacts,"privateChatCtrl:clearDueCache",10)
	for k,v in pairs(self.userContacts) do
		if next(v) then
			if v.time < serviceFunctions.systemTime() - 300 then
				for _,data in pairs(v.contacts) do
					local toUid, _ = self:divideContacts(data)
					self.chatCache[k..toUid] = nil
				end
				self.userContacts[k] = nil
				Log.i("privateChatCtrl:clearDueCache"..k)
			end
		end
	end
end

--通知客户端
function privateChatCtrl:send2Client(uid,sendMsg)
	local gateAddr = svrAddressMgr.getSvr(svrAddressMgr.chatgateSvr,nil,dbconf.chatnodeid)
	skynet.send(gateAddr,skynet.PTYPE_LUA,"send2Client",uid,sendMsg)
end

--[[
私有聊天内容key
]]
function privateChatCtrl:privateContentKey( uid, touid )
	return string.format("chatprivate_%d_%d",uid,touid)
end

--获取（玩家拥有聊天室）key
function privateChatCtrl:getUserContactsKey( uid )
	assert(nil~=uid,"getUserContactsKey uid must not nil")
	return string.format("usercontacts_%s",tostring(uid))
end

function privateChatCtrl:divideContacts(key)
	local uid, time = string.match(key,"(%d+)_(%d+)")
	return tonumber(uid),tonumber(time)
end

return privateChatCtrl