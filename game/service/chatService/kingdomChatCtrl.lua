local skynet = require "skynet"
local myScheduler = require("myScheduler").new()
local json = require "json"
local cluster = require("cluster")
local chatRedisLib = require("chatRedisLib")
local dataCacheCenterLib = require("dataCacheCenterLib")
local chatBaseCtrl = require("chatBaseCtrl")
local kingdomChatCtrl = class("kingdomChatCtrl",chatBaseCtrl)
local EXPIRE_TIME = 86400 * 30 --一个月的过期时间

function kingdomChatCtrl:ctor(channelID)
	kingdomChatCtrl.super.ctor(self,channelID)
	self.chatKind = gChatKind.KINGDOM_CHAT
	self.logAPI = include("logAPI").new("kingdomChat")
end

--[[
加载王国
]]
function kingdomChatCtrl:loadKingdom( kid )
	Log.i("loadKingdom kid=",kid)
	serviceFunctions.makeTable(self.chatCache,tostring(kid))
	local pushkey = "chat_kingdom"..kid
	self.chatCache[tostring(kid)] = self:loadData(pushkey)
	-- Log.dump(self.chatCache,"load self.chatCache",10)
end

--[[
加载红包redis
]]
function chatBaseCtrl:loadRedData(key)
	-- Log.d("loadData key=",key)
	local data = {}
	xpcall(function ()
		local success,ret = chatRedisLib.lRange(self.channelID,key,0,-1)
		-- Log.dump(ret,"loadData ret",10)
		if success and ret and next(ret) then
			local chatListLen = #ret
			for idx=1,chatListLen,1 do
				if ret[idx] then
					table.insert(data,json.decode(ret[idx]))
				end
			end
		end
	end,serviceFunctions.exception,self,key)
	return data
end

-- 同步红包状态
function kingdomChatCtrl:syncRedenvelope(data,isNeedSelf,isCall)
	Log.dump(data,"syncRedenvelope data",10)
	Log.d("syncRedenvelope isNeedSelf,isCall",data.syntype,isNeedSelf,isCall)
	local kid = data.kid
	local syntype = data.syntype --同步类型

	if syntype == 0 then -- 清理红包数据
		local clear = data.clear --红包活动结束,清理红包中的聊天数据
		if kid and clear then
			self:clearRedenvelope(kid)
			Log.i("clear redenvelope",kid)
			return
		end
	elseif syntype == 1 then --初始化同步
		local syndata = data.init
		if not syndata then
			return
		end
		local loopcount = 0
		for rid,logs in pairs(syndata) do
			local chatdata = self.chatCache[tostring(kid)]
			local change = false
			if chatdata then
				for _, item in pairs(chatdata) do
					if item.extra and (item.extra.rid and item.extra.rid == rid) and item.extra.log and next(item.extra.log) then
						item.extra.log = logs
						change = true
						break --单条查找
					end
				end
			end
			loopcount = loopcount + 1
			if loopcount > 20 then
				skynet.sleep(1) --让出cpu
			end
		end
		self.needSaveList[tostring(kid)] = change
	else
		local uid = data.uid or kid
		local rid = data.rid --红包ID
		local done = data.done --红包是否领完
		local log = data.log --领取记录
		if not kid or not uid or not rid then
			Log.i("syn redenvelope err =",kid,uid,rid,done)
			return
		end
		
		local chatdata = self.chatCache[tostring(kid)]
		local change = false
		if chatdata and rid then
			for _, item in pairs(chatdata) do
				if item.extra and (item.extra.rid and item.extra.rid == rid) then
					if done and done == 1 then
						item.extra.done = 1
						change = true
					end
					if log and item.extra.log then
						local found = false --安全检查
						for _,v in ipairs(item.extra.log) do
							if tonumber(v) == tonumber(log.uid) then
								found = true
								break
							end
						end
						if not found then
							table.insert(item.extra.log,log.uid)
							change = true
						end
					end
					-- 找到记录跳出
					break
				end
			end
		end
		self.needSaveList[tostring(kid)] = change
	end
end

-- 清理聊天中的红包数据
function kingdomChatCtrl:clearRedenvelope(kid)
	local chatdata = self.chatCache[tostring(kid)]
	local len = #chatdata
	local tremove = table.remove
	local change = false
	for i=len,1,-1 do
		local data = chatdata[i]
		if data.extra and data.extra.rid then
			tremove(chatdata,i)
			change = true
		end
	end
	if change then
		self.needSaveList[tostring(kid)] = true
	end
end

--[[
发送给王国频道
]]
function kingdomChatCtrl:send2Kingdom(data,isNeedSelf,isCall)
	Log.dump(data,"send2Kingdom data",10)
	Log.d("send2Kingdom isNeedSelf,isCall",isNeedSelf,isCall)
	local kid = data.kid
	local uid = data.uid or kid
	local msg = data.msg
	local isLamp = false
	if msg.chatType == gChatType.HORSE_RACE_LAMP then
		isLamp = true
	end
	local userinfo = nil
	if not isLamp then
		userinfo = dataCacheCenterLib.getAllColum(uid,kid)
		data.sendUid = data.sendUid or data.uid
		
		local GDPRSvr = svrAddressMgr.getSvr(svrAddressMgr.GDPRSvr)
		local GDPR = skynet.call(GDPRSvr, "lua", "getUserGDPRStatus", {uid})
		if GDPR and GDPR[1] and GDPR[1].status == 1 then
			return gErrDef.Err_BE_GDPR
		end
		local err = self:supervise(kid,uid,msg.text)
		if err ~= gErrDef.Err_None then
			return err
		end

		if string.utf8len(msg.text) > self.config.maxlen then
	    	return gErrDef.Err_CHAT_LENGTH_OUT
	    end
	end

	local toAddr = serviceFunctions.getChatServiceAddr(kid)
	local srcAddr = serviceFunctions.getChatServiceAddr(uid)
	if toAddr ~= srcAddr and not isCall then
		skynet.send(toAddr,skynet.PTYPE_LUA,"send2Kingdom", data,isNeedSelf,true)
	else
		local msgid = self:getMsgID()

		-- 红包相关记录操作
		if msg.chatType and msg.chatType == gChatType.REDENVELOPE then
			-- 此数据无用
			msg.extra.mini = nil
			msg.extra.userinfo = nil --不保留从王国发来的红包数据信息
		end
		--插入与世界相关的数据
		local msgdata = { text=msg.text, extra=msg.extra, userinfo=userinfo, type=msg.chatType, kind=gChatKind.KINGDOM_CHAT, id=msgid, kid=kid, uid=uid, sendTime=serviceFunctions.systemTime() }
		
		if not isLamp then
			--跑马灯不存库
			serviceFunctions.makeTable(self.chatCache,tostring(kid))
			local maxsize = self.config.max or 100
			table.insert(self.chatCache[tostring(kid)],1,msgdata)
			serviceFunctions.trimTable(self.chatCache[tostring(kid)],maxsize)
			--改变待存列表状态
			self.needSaveList[tostring(kid)] = true
			Log.dump(self.needSaveList,"send2Kingdom data needSaveList",10)
		end
		
		local excludeUid = data.sendUid
		if isNeedSelf then
			excludeUid = 0
		end
		local sendMsg = {}
		sendMsg.returnType = gReturnType.insertH
		sendMsg.chatData = {}
		sendMsg.kind = gChatKind.KINGDOM_CHAT
		table.insert(sendMsg.chatData,msgdata)
		local gateAddr = svrAddressMgr.getSvr(svrAddressMgr.chatgateSvr,nil,dbconf.chatnodeid)
		skynet.send(gateAddr,skynet.PTYPE_LUA,"publishKingdomMsg",kid, {kid = kid,sendMsg = sendMsg,excludeUid = excludeUid})
		
		-- 日志相关
		local logdata = {
	    	message = msg.text,
	    	chatType = gChatKind.KINGDOM_CHAT
	    }
		self.logAPI:writeLog4Mgr(kid,data.sendUid,gLogType.player_chat,logdata)
	end
	return gErrDef.Err_None
end

--请求聊天室聊天数据
function kingdomChatCtrl:getKingdomChatData(data,isCall,isInit)
	-- Log.dump(data,"kingdomChatCtrl getKingdomChatData data",10)
	local kid = data.kid
	local uid = data.uid
	local num = data.num
	local startIdx = data.startIdx or 1
	local endIdx = data.endIdx or num
	local sendMsg = {}
	local cKid = dataCacheCenterLib.getColum(uid, "kid") or kid
	local toAddr = serviceFunctions.getChatServiceAddr(cKid)
	local srcAddr = serviceFunctions.getChatServiceAddr(uid)
	--还需要判断是否是同一个服务
	if toAddr == srcAddr or isCall then
		if isCall then
			return {kind = gChatKind.KINGDOM_CHAT,chatData = serviceFunctions.getTableByRange(self.chatCache[tostring(cKid)],startIdx,endIdx)}
		else
			sendMsg = {kind = gChatKind.KINGDOM_CHAT,chatData = serviceFunctions.getTableByRange(self.chatCache[tostring(cKid)],startIdx,endIdx)}
		end
	else
		local ok,ret = skynet.call(toAddr,skynet.PTYPE_LUA,"getKingdomChatData",data,true)
		sendMsg = ret
	end
	self:filterGDPR(sendMsg)
	if isInit then
		return sendMsg
	else
		sendMsg.returnType = gReturnType.insertT
		self:send2Gate(cKid, sendMsg, gChatSubscribeType.kingdom, 0, uid)
	end
end

--删除王国聊天数据
function kingdomChatCtrl:deledeKingdomChat(kid)
	self.chatCache[tostring(kid)] = {}
	local pushkey = "chat_kingdom"..tostring(kid)
	chatRedisLib.delete(self.channelID,pushkey)
end

return kingdomChatCtrl