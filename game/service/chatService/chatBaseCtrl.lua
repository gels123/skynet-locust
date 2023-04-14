local chatBaseCtrl = class("chatBaseCtrl")
local skynet = require "skynet"
local myScheduler = require("myScheduler").new()
local json = require "json"
local cluster = require("cluster")
local chatRedisLib = require("chatRedisLib")
local dataCacheCenterLib = require("dataCacheCenterLib")
local securityLib = require("securityLib")
local EXPIRE_TIME = 86400 * 30 --一个月的过期时间

function chatBaseCtrl:ctor(channelID)
	self.config = { max = 100,maxlen = 512 }
	self.chatKind = nil
	self.channelID = channelID
	--聊天缓存
	self.chatCache = {}
	--待存聊天记录表
	self.needSaveList = {}
	--配置读取
	self.chatClusterConf = confAPI.getClusterConf(dbconf.chatnodeid)
end

function chatBaseCtrl:init()
	myScheduler:schedule(handler(self,self.update),os.time()+300,nil,true)
	myScheduler:start()
end

--[[
加载redis
]]
function chatBaseCtrl:loadData(key)
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

--每秒刷新,判断是否有需要写入redis的数据
function chatBaseCtrl:update()
	if self.chatKind then
		local needSaveList = serviceFunctions.table_copy_table(self.needSaveList)
		-- Log.dump(self.needSaveList,"chatBaseCtrl:update self.needSaveList==="..self.chatKind,10)
		self.needSaveList = {}
		for k,_ in pairs(needSaveList) do
			local pushkey = k
			local needAutoDelete = false

			if gChatKind.KINGDOM_CHAT == self.chatKind then
				pushkey = "chat_kingdom"..tostring(k)
			elseif gChatKind.ROOM_CHAT == self.chatKind then
				pushkey = "roomchat_"..tostring(k)
				needAutoDelete = true
			elseif gChatKind.ALLIANCE_CHAT == self.chatKind then
				pushkey = "chat_alliance_"..tostring(k)
			elseif gChatKind.FORCE_CHAT == self.chatKind then
				pushkey = "chat_force_"..tostring(k)
				needAutoDelete = true
			elseif gChatKind.POWER_CHAT == self.chatKind then
				pushkey = "chat_power_"..tostring(k)
				needAutoDelete = true
			elseif gChatKind.TEAM_CHAT == self.chatKind then
				pushkey = "chat_team_"..tostring(k)
				needAutoDelete = true
			elseif gChatKind.PRIVATE_CHAT == self.chatKind then
				pushkey = "chatprivate_"..tostring(k)
				needAutoDelete = true
			end
			local valueList = {}
			
			if self.chatCache[k] then
				for _,data in pairs(self.chatCache[k]) do
					table.insert(valueList,json.encode(data))
				end
				if next(valueList) then
					--先删除表
					chatRedisLib.delete(self.channelID,pushkey)
					--再插入
					chatRedisLib.rpushs(self.channelID,pushkey,valueList)
					--过期自动删除
					if needAutoDelete then
						local expireTime = serviceFunctions.systemTime() + EXPIRE_TIME
						chatRedisLib.expireAt(self.channelID,pushkey,expireTime)
					end
				end
			end
		end
	end
end

--聊天内容监管
function chatBaseCtrl:supervise(kid,uid,text,toUid)
	local err = gErrDef.Err_None

	--获取玩家禁言状态
	local gateAddr = svrAddressMgr.getSvr(svrAddressMgr.chatgateSvr,nil,dbconf.chatnodeid)
	local chatStatusType = skynet.call(gateAddr,skynet.PTYPE_LUA,"getChatStatusType",uid)
	if chatStatusType == gChatStatusType.ban then
		err = gErrDef.Err_CHAT_BAN
	else
		local dataType = nil
		if gChatKind.KINGDOM_CHAT == self.chatKind then
			dataType = gSuperviseDataType.worldChat
		elseif gChatKind.ALLIANCE_CHAT == self.chatKind then
			dataType = gSuperviseDataType.allianceChat
		elseif gChatKind.FORCE_CHAT == self.chatKind then
			dataType = gSuperviseDataType.forceChat
		elseif gChatKind.TEAM_CHAT == self.chatKind then
			dataType = gSuperviseDataType.teamChat
		elseif gChatKind.POWER_CHAT == self.chatKind then
			dataType = gSuperviseDataType.powerChat
		elseif gChatKind.ROOM_CHAT == self.chatKind then
			dataType = gSuperviseDataType.roomChat
		elseif gChatKind.PRIVATE_CHAT == self.chatKind then
			dataType = gSuperviseDataType.priavteChat
		end
			
		--过滤热更敏感词
		local superviseData = {
	    	uid = uid,
	    	kid = kid,
	    	content = text,
	    	castleLevel = dataCacheCenterLib.getColum(uid, "castleLv"),
	    	dataType = dataType,
	    	target = toUid,
		}
	    local ok, superviseRet = securityLib.callSupervise(superviseData,uid)
	    -- Log.i("ok, superviseRet", ok, superviseRet)
	    if not ok then
	    	Log.i("chatCtrl:sendMessage(ret) callSupervise fail err =", superviseRet)
			err = superviseRet
		end

		--过滤配置敏感词
		if "string" == type(text) then
		    local sensitiveWordsCtrl = include("sensitiveWordsCtrl")
		    text = sensitiveWordsCtrl:sharedInstance():replaceShieldedWords(text)
		end
	end
	
	return err
end

--过滤gdpr
function chatBaseCtrl:filterGDPR(msg)
	local GDPRSvr = svrAddressMgr.getSvr(svrAddressMgr.GDPRSvr)
	local uids = {}
	if msg.chatData and next(msg.chatData) then
		for i=#msg.chatData,1,-1 do
			local have = false
			for _,uid in pairs(uids) do
				if uid == msg.chatData[i].uid then
					break
				end
			end
			if not have then
				table.insert(uids,msg.chatData[i].uid)
			end
		end
	end
	local GDPRList = skynet.call(GDPRSvr, "lua", "getUserGDPRStatus", uids)
	if msg.chatData and next(msg.chatData) then
		for i=#msg.chatData,1,-1 do
			for _,data in pairs(GDPRList) do
				if data.status == 1 and data.uid == msg.chatData[i].uid then
					table.remove(msg.chatData,i)
					break
				end
			end
		end
	end
end

--[[
公共的聊天id
]]
function chatBaseCtrl:getMsgID()
	local rnd1 =  math.random(1000000000,9999999999)
	local rnd2 =  math.random(100000,999999)
	return string.format("%d_%d_%d",rnd1,rnd2,serviceFunctions.systemTime())
end

--发送消息给客户端
function chatBaseCtrl:send2Gate(key,msg,subType,excludeUid,onlyUid)
	Log.dump(msg,"chatBaseCtrl:send2Gate",10)
	if subType == gChatSubscribeType.kingdom or subType == gChatSubscribeType.group and onlyUid and onlyUid ~= 0 then
		local address = serviceFunctions.getBCServiceAddr(BC_SERVICE_INSTANCE,subType,onlyUid)
		skynet.send(address,skynet.PTYPE_LUA,"send2Client",key,msg,excludeUid,onlyUid)
	else
		local address = serviceFunctions.getBCServiceAddr(BC_SERVICE_INSTANCE,subType,key)
		skynet.send(address,skynet.PTYPE_LUA,"send2Client",{key},msg,excludeUid)
	end
end

return chatBaseCtrl