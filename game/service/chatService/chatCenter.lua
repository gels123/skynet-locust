
local skynet = require "skynet"

local json = require "json"

local cluster = require("cluster")

local myScheduler = require("myScheduler").new()

local chatRedisLib = require("chatRedisLib")

local chatCenter = class("chatCenter")

local respondCtrl = require("respondCtrl")

local instance = nil

local EXPIRE_TIME = 86400 * 30 --一个月的过期时间

function chatCenter:ctor()
	
end

function chatCenter:init(instance)
	self.channelID = tonumber(instance)
	--发送命令,无需返回
	self.sendCmd = {
		recv4user = true,
		send2room = true,
		syncRedenvelope = true,
	}

	--转发规则
	self.transform = {
		--联盟聊天
		[gChatCmd.REQ_NEW_SEND_ALLIANCE_CHAT] = {funcname = "send2Alliance"},
		--势力聊天
		[gChatCmd.REQ_NEW_SEND_POWER_CHAT] = {funcname = "send2Power"},
		--联军聊天
		[gChatCmd.REQ_NEW_SEND_FORCE_CHAT] = {funcname = "send2Force"},
		--队伍聊天
		[gChatCmd.REQ_NEW_SEND_TEAM_CHAT] = {funcname = "send2Team"},
		--王国聊天
		[gChatCmd.REQ_NEW_SEND_KINGDOM_CHAT] = {funcname = "send2Kingdom"},
		--私聊聊天
		[gChatCmd.REQ_NEW_SEND_PRIVATE_CHAT] = {funcname = "send2user"},
		--聊天室聊天
		[gChatCmd.REQ_NEW_SEND_ROOM_CHAT] = {funcname = "send2room"},
		--创建聊天室
		[gChatCmd.REQ_NEW_CREATE_ROOM] = {funcname = "createRoom"},
		--加入聊天室
		[gChatCmd.REQ_NEW_JOIN_ROOM] = {funcname = "joinRoom"},
		--退出聊天室
		[gChatCmd.REQ_NEW_QUIT_ROOM] = {funcname = "quitRoom"},
		--解散聊天室
		[gChatCmd.REQ_NEW_DIMISS_ROOM] = {funcname = "dimissRoom"},
		--创建群组
		[gChatCmd.REQ_NEW_CREATE_GROUP] = {funcname = "createGroup"},
		--加入群组
		[gChatCmd.REQ_NEW_JOIN_GROUP] = {funcname = "joinGroup"},
		--退出群组
		[gChatCmd.REQ_NEW_QUIT_GROUP] = {funcname = "quitGroup"},
		--解散群组
		[gChatCmd.REQ_NEW_DIMISS_GROUP] = {funcname = "dimissGroup"},
		--请求加载私聊
		[gChatCmd.REQ_NEW_GET_PRIVATE_CHAT] = {funcname = "getPrivateChatData"},
		--请求聊天室聊天数据
		[gChatCmd.REQ_NEW_GET_ROOM_CHAT] = {funcname = "getRoomChatData"},
		--请求初始化话聊天室
		[gChatCmd.REQ_NEW_INIT_ROOM_CHAT] = {funcname = "getInitRoomChatData"},
		--请求王国聊天数据
		[gChatCmd.REQ_NEW_GET_KINGDOM_CHAT] = {funcname = "getKingdomChatData"},
		--请求联盟聊天数据
		[gChatCmd.REQ_NEW_GET_ALLIANCE_CHAT] = {funcname = "getAllianceChatData"},
		--请求势力聊天数据
		[gChatCmd.REQ_NEW_GET_POWER_CHAT] = {funcname = "getPowerChatData"},
		--请求队伍聊天数据
		[gChatCmd.REQ_NEW_GET_TEAM_CHAT] = {funcname = "getTeamChatData"},
		--请求联军聊天数据
		[gChatCmd.REQ_NEW_GET_FORCE_CHAT] = {funcname = "getForceChatData"},
		--请求心跳
		[gChatCmd.REQ_NEW_CHAT_HEARTBEAT] = {funcname = "reqHeartbeat"},
		--转让聊天室
		[gChatCmd.REQ_NEW_REPLACE_ROOM_OWNER] = {funcname = "replaceOwner"},
		--聊天室改名
		[gChatCmd.REQ_NEW_CHANGE_ROOM_NAME] = {funcname = "changeRoomName"},
		--请求初始化范围内的聊天(私聊和聊天室)
		[gChatCmd.REQ_NEW_INIT_CHAT_DATA_BY_RANGE] = {funcname = "getInitChatData"},
		--设置聊天置顶
		[gChatCmd.REQ_NEW_SET_CHAT_TOP] = {funcname = "setTopChat"},
		--设置聊天已读
		[gChatCmd.REQ_NEW_SET_CHAT_ALREADYREAD] = {funcname = "setAlreadyRead"},
		--设置聊天删除
		[gChatCmd.REQ_NEW_SET_CHAT_DELETE] = {funcname = "setDelete"},
	}

	self.privateChatCtrl = require("privateChatCtrl").new(self.channelID)
	self.allianceChatCtrl = require("allianceChatCtrl").new(self.channelID)
	self.kingdomChatCtrl = require("kingdomChatCtrl").new(self.channelID)
	self.roomChatCtrl = require("roomChatCtrl").new(self.channelID)
	self.forceChatCtrl = require("forceChatCtrl").new(self.channelID)
	self.powerChatCtrl = require("powerChatCtrl").new(self.channelID)
	self.teamChatCtrl = require("teamChatCtrl").new(self.channelID)

	self.kingdomChatCtrl:init()
	self.allianceChatCtrl:init()
	self.roomChatCtrl:init()
	self.privateChatCtrl:init()
	self.forceChatCtrl:init()
	self.powerChatCtrl:init()
	self.teamChatCtrl:init()
end

-- get chatCenter
function chatCenter.instance()
	if not instance then
		instance = chatCenter.new()
	end
	return instance
end

--[[
请求心跳
]]
function chatCenter:reqHeartbeat(data)
	-- Log.dump(data,"chatCenter:reqHeartbeat data",10)
	local sendMsg = {}
	local gateAddr = svrAddressMgr.getSvr(svrAddressMgr.chatgateSvr,nil,dbconf.chatnodeid)
	sendMsg.returnType = gReturnType.heartBeat
	skynet.send(gateAddr,skynet.PTYPE_LUA,"send2Client",data.uid,sendMsg)
end

--[[
	请求回调
]]
function chatCenter:response(uid,ret)
	local gateAddr = svrAddressMgr.getSvr(svrAddressMgr.chatgateSvr,nil,dbconf.chatnodeid)
	ret.returnType = gReturnType.response
	skynet.send(gateAddr,skynet.PTYPE_LUA,"send2Client",uid,ret)
end

--发送初始化聊天数据
function chatCenter:getInitChatData(data)
	Log.dump(data,"chatCenter:getInitChatData data",10)
	skynet.fork(function ()
		local kid = data.kid
		local aid = data.aid
		local fid = data.fid
		local pid = data.pid
		local uid = data.uid
		local tid = data.tid
		local optUid = data.optUid
		local startIdx = data.startIdx or 0
		local endIdx = data.endIdx or 9
		local isPull = data.isPull
		local isInit = true
		local chatData = {}
		data.num = 10
		if optUid then
			isInit = false
		else
			chatData.kingdomChatData = self.kingdomChatCtrl:getKingdomChatData(data,nil,isInit)
			if aid and aid ~= 0 then
				chatData.allianceChatData = self.allianceChatCtrl:getAllianceChatData(data,nil,isInit)
			else
				chatData.allianceChatData = {}
			end
			if fid and fid ~= 0 then
				chatData.forceChatData = self.forceChatCtrl:getForceChatData(data,nil,isInit)
			else
				chatData.forceChatData = {}
			end
			if pid and pid ~= 0 then
				chatData.powerChatData = self.powerChatCtrl:getPowerChatData(data,nil,isInit)
			else
				chatData.powerChatData = {}
			end
			if tid and tid ~= 0 then
				chatData.teamChatData = self.teamChatCtrl:getTeamChatData(data,nil,isInit)
			else
				chatData.teamChatData = {}
			end
		end
		
		--玩家的私聊和聊天室排序列表
		local ok,ret = chatRedisLib.zRevRange(self.channelID,"user_chat_list"..uid,startIdx,endIdx,true)
		if ok then
			ret = serviceFunctions.tableFormat(ret, { "ID", "time" })
		end
		Log.dump(ret,"chatCenter:getInitChatData userChatList ret",10)
		local userChatList = {}
		if ret then
			for _,v in pairs(ret) do
				--判断不在删除状态
				if tonumber(v.time) > 10000000000 then
					--判断是否置顶
					if tonumber(v.time) >= 20000000000000000 then
						table.insert(userChatList,{ID = v.ID,isTop = true})
					else
						table.insert(userChatList,{ID = v.ID,isTop = false})
					end
				end
			end
		end
		-- Log.dump(userChatList,"chatCenter:getInitChatData userChatList",10)
		local roomList = {}
		local privateList = {}
		for _,v in pairs(userChatList) do
			local chatKind,ID = string.match(v.ID,"(%S)_(%S+)")
			Log.d("chatCenter:getInitChatData",chatKind,ID)
			if tonumber(chatKind) == gChatKind.PRIVATE_CHAT then
				table.insert(privateList,{ID=ID,isTop=v.isTop})
			elseif tonumber(chatKind) == gChatKind.ROOM_CHAT then
				table.insert(roomList,{ID=ID,isTop=v.isTop})
			end
		end
		chatData.roomChatData = self.roomChatCtrl:getInitRoomChatData(data,roomList,isInit)
		chatData.privateChatData = self.privateChatCtrl:getInitPrivateChatData(data,privateList,isInit)
		chatData.returnType = gReturnType.init
		if isPull then
			chatData.initType = gChatInitType.pull
		else
			chatData.initType = gChatInitType.login
		end
		-- Log.dump(chatData,"chatCenter:getInitChatData chatData",10)
		local gateAddr = svrAddressMgr.getSvr(svrAddressMgr.chatgateSvr,nil,dbconf.chatnodeid)
		skynet.send(gateAddr,skynet.PTYPE_LUA,"send2Client",uid,chatData)
	end)
end

--[[
	刷新配置
]]
function chatCenter:updateClusterConf()
	Log.i("chatCenter:updateClusterConf")
	self.roomChatCtrl.chatClusterConf = confAPI.getClusterConf(dbconf.chatnodeid)
	self.privateChatCtrl.chatClusterConf = confAPI.getClusterConf(dbconf.chatnodeid)
	self.kingdomChatCtrl.chatClusterConf = confAPI.getClusterConf(dbconf.chatnodeid)
	self.allianceChatCtrl.chatClusterConf = confAPI.getClusterConf(dbconf.chatnodeid)
	self.forceChatCtrl.chatClusterConf = confAPI.getClusterConf(dbconf.chatnodeid)
	self.powerChatCtrl.chatClusterConf = confAPI.getClusterConf(dbconf.chatnodeid)
	self.teamChatCtrl.chatClusterConf = confAPI.getClusterConf(dbconf.chatnodeid)
end

--[[
聊天落地
]]
function chatCenter:saveChatDataToRedis()
	Log.i("chatCenter:saveChatDataToRedis")
	self.roomChatCtrl:update()
	self.privateChatCtrl:update()
	self.kingdomChatCtrl:update()
	self.allianceChatCtrl:update()
	self.forceChatCtrl:update()
	self.powerChatCtrl:update()
	self.teamChatCtrl:update()
end
---------------------------私有聊天-----------------------
--[[
加载私有聊天
]]
function chatCenter:getPrivateChatData(data)
	self.privateChatCtrl:getPrivateChatData(data)
end

--[[
发送给某一个玩家
]]
function chatCenter:send2user(data,isNeedSelf)
	self.privateChatCtrl:send2user(data,isNeedSelf)
end

--[[
收到某一玩家的消息
]]
function chatCenter:recv4user(data)
	self.privateChatCtrl:recv4user(data)
end

---------------------------王国聊天-----------------------
--[[
加载王国聊天
]]
function chatCenter:loadKingdom( kid )
	self.kingdomChatCtrl:loadKingdom(kid)
end

--[[
发送给王国频道(一个服务器)
]]
function chatCenter:send2Kingdom(data,isNeedSelf,isCall)
	return self.kingdomChatCtrl:send2Kingdom(data,isNeedSelf,isCall)
end

--[[
同步红包状态到王国聊天频道(一个服务器)
]]
function chatCenter:syncRedenvelope(data,isNeedSelf,isCall)
	self.kingdomChatCtrl:syncRedenvelope(data,isNeedSelf,isCall)
end

--[[
call调用,发送给王国频道(一个服务器)
]]
function chatCenter:call2Kingdom(data,isNeedSelf,isCall)
	return self.kingdomChatCtrl:send2Kingdom(data,isNeedSelf,isCall)
end

--请求王国聊天数据
function chatCenter:getKingdomChatData(data,isCall)
	return self.kingdomChatCtrl:getKingdomChatData(data,isCall)
end

--删除王国聊天数据
function chatCenter:deledeKingdomChat(kid)
	self.kingdomChatCtrl:deledeKingdomChat(kid)
end

---------------------------群组公共方法-----------------------
--[[
加载群组聊天
]]
function chatCenter:loadGroup(chatKind,gid)
	Log.d("chatCenter:loadGroup",chatKind,gid)
	local ctrlStr = gGroupCtrl[chatKind]
	self[ctrlStr]:loadGroup(chatKind,gid)
end

--[[
创建群组
]]
function chatCenter:createGroup(data)
	local ctrlStr = gGroupCtrl[data.chatKind]
	self[ctrlStr]:createGroup(data.chatKind,data)
end

--[[
加入群组
]]
function chatCenter:joinGroup(data)
	local ctrlStr = gGroupCtrl[data.chatKind]
	self[ctrlStr]:joinGroup(data.chatKind,data)
end

--[[
退出群组
]]
function chatCenter:quitGroup(data,isInitiative)
	local ctrlStr = gGroupCtrl[data.chatKind]
	self[ctrlStr]:quitGroup(data.chatKind,data,isInitiative)
end

--[[
解散群组
]]
function chatCenter:dimissGroup(data)
	local ctrlStr = gGroupCtrl[data.chatKind]
	self[ctrlStr]:dimissGroup(data.chatKind,data)
end

---------------------------联盟聊天-----------------------
--[[
联盟聊天
]]
function chatCenter:send2Alliance(data,isNeedSelf,isCall)
	self.allianceChatCtrl:send2Alliance(data,isNeedSelf,isCall)
end

--请求联盟聊天数据
function chatCenter:getAllianceChatData(data,isCall)
	return self.allianceChatCtrl:getAllianceChatData(data,isCall)
end
---------------------------势力聊天-----------------------
--[[
势力聊天
]]
function chatCenter:send2Power(data,isNeedSelf,isCall)
	self.powerChatCtrl:send2Power(data,isNeedSelf,isCall)
end

--请求势力聊天数据
function chatCenter:getPowerChatData(data,isCall)
	return self.powerChatCtrl:getPowerChatData(data,isCall)
end
---------------------------联军聊天-----------------------
--[[
联军聊天
]]
function chatCenter:send2Force(data,isNeedSelf,isCall)
	self.forceChatCtrl:send2Force(data,isNeedSelf,isCall)
end

--请求联军聊天数据
function chatCenter:getForceChatData(data,isCall)
	return self.forceChatCtrl:getForceChatData(data,isCall)
end
---------------------------队伍聊天-----------------------
--[[
联军聊天
]]
function chatCenter:send2Team(data,isNeedSelf,isCall)
	self.teamChatCtrl:send2Team(data,isNeedSelf,isCall)
end

--请求联军聊天数据
function chatCenter:getTeamChatData(data,isCall)
	return self.teamChatCtrl:getTeamChatData(data,isCall)
end

---------------------------聊天室聊天-----------------------
--[[
加载聊天室聊天
]]
function chatCenter:loadRoomChat(roomID)
	return self.roomChatCtrl:loadRoomChat(roomID)
end

--[[
发送给聊天室
]]
function chatCenter:send2room(data,isNeedSelf)
 	self.roomChatCtrl:send2room(data,isNeedSelf)
end

--[[
创建聊天室
]]
function chatCenter:createRoom(data,isCall)
	-- Log.dump(data,"chatCenter:createRoom data before",10)
	local ret = self.roomChatCtrl:createRoom(data,isCall)
	-- Log.dump(ret,"chatCenter:createRoom ret",10)
	data.refuse = false
	data.err = ret.err
	if data.err == gErrDef.Err_None then
		data.roomID = ret.roomID
		for _,v in pairs(ret.result) do
			if v.err ~= gErrDef.Err_None then
				data.refuse = true
				break
			end
		end
	end
	data.result = ret
	-- Log.dump(data,"chatCenter:createRoom data after",10)
	self:response(data.owneruid,data)

	return ret
end

--[[
解散聊天室
]]
function chatCenter:dimissRoom(data,isCall)
	local ret = self.roomChatCtrl:dimissRoom(data,isCall)
	if data.optUid then
		data.err = ret
		-- Log.dump(data,"chatCenter:dimissRoom after data",10)
		self:response(data.optUid,data)
	end
	return ret
end

--[[
加入聊天室
]]
function chatCenter:joinRoom(data,isCall)
	-- Log.d(data,"chatCenter:joinRoom",10)
	local result = self.roomChatCtrl:joinRoom(data,isCall)
	if data.optUid and not isCall then
		--请求回调
		data.refuse = false
		if type(result) == "table" then
			for _,v in pairs(result) do
				if v.err ~= gErrDef.Err_None then
					data.refuse = true
					break
				end
			end
			data.err = gErrDef.Err_None
			data.result = result
		else
			data.err = result
		end
		
		-- Log.dump(data,"chatCenter:joinRoom after data",10)
		self:response(data.optUid,data)
	end
	return result
end

--[[
退出聊天室
]]
function chatCenter:quitRoom(data,isNotCallOther,isCall)
	local ret = self.roomChatCtrl:quitRoom(data,isNotCallOther,isCall)
	if data.optUid and not isCall then
		data.err = ret
		-- Log.dump(data,"chatCenter:quitRoom after data",10)
		self:response(data.optUid,data)
	end
	return ret
end

--[[
转让聊天室
]]
function chatCenter:replaceOwner(data,isCall)
	local ret = self.roomChatCtrl:replaceOwner(data,isCall)
	if data.optUid then
		data.err = ret
		-- Log.dump(data,"chatCenter:replaceOwner after data",10)
		self:response(data.optUid,data)
	end
	return ret
end

--初始化聊天室聊天数据
function chatCenter:getInitRoomChatData(data,roomList,isInit)
	local ret = self.roomChatCtrl:getInitRoomChatData(data,roomList,isInit)
	if data.optUid then
		data.roomChatData = ret
		data.err = gErrDef.Err_None
		self:filterGDPR(data)
		self:response(data.optUid,data)
	end
	return self.roomChatCtrl:getInitRoomChatData(data,roomList,isInit)
end

--过滤gdpr
function chatCenter:filterGDPR(msg)
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

--获取单一聊天室聊天数据
function chatCenter:getOneInitRoomChatData(data,isCall)
	return self.roomChatCtrl:getOneInitRoomChatData(data,isCall)
end

--保证房间类型唯一性
function chatCenter:keepRoomTypeUniqueness(data,isCall)
	self.roomChatCtrl:keepRoomTypeUniqueness(data,isCall)
end

--请求聊天室聊天数据
function chatCenter:getRoomChatData(data,isCall)
	return self.roomChatCtrl:getRoomChatData(data,isCall)
end

--roomuser数据修改
function chatCenter:roomuserChange(opt,data,isCreate)
	return self.roomChatCtrl:roomuserChange(opt,data,isCreate)
end

--聊天室改名
function chatCenter:changeRoomName(data,isCall)
	local ret = self.roomChatCtrl:changeRoomName(data,isCall)
	if data.optUid then
		data.err = ret
		-- Log.dump(data,"chatCenter:changeRoomName after data",10)
		self:response(data.optUid,data)
	end
	return ret
end
------------------------玩家聊天设置------------------------
--置顶一个聊天
function chatCenter:setTopChat(data)
	local uid = data.uid
	local chatType = data.chatType
	local oType = data.oType
	local ID = data.ID
	if oType == 1 then
		--设置
		skynet.fork(function ()
			chatRedisLib.zAdd(self.channelID,"user_chat_list"..uid,20000000000000000,string.format("%d_%s",chatType,ID))
		end)
	else
		--取消
		skynet.fork(function ()
			chatRedisLib.zAdd(self.channelID,"user_chat_list"..uid,serviceFunctions.systemTime()*10000000,string.format("%d_%s",chatType,ID))
		end)
	end
	data.err = gErrDef.Err_None
	self:response(data.uid,data)
end

--设置已读
function chatCenter:setAlreadyRead(data)
	local uid = data.uid
	local chatType = data.chatType
	local ID = data.ID
	skynet.fork(function ()
		local ok,score = chatRedisLib.zScore(self.channelID,"user_chat_list"..uid,string.format("%d_%s",chatType,ID))
		if ok and score then
			local score = math.ceil(tonumber(score)/10000000)*10000000
			chatRedisLib.zAdd(self.channelID,"user_chat_list"..uid,score+serviceFunctions.systemTime()%10000000,string.format("%d_%s",chatType,ID))
		end
	end)
	data.err = gErrDef.Err_None
	self:response(data.uid,data)
end

--设置删除
function chatCenter:setDelete(data)
	-- Log.dump(data,"chatCenter:setDelete data",10)
	local uid = data.uid
	local chatType = data.chatType
	local ID = data.ID
	skynet.fork(function ()
		chatRedisLib.zAdd(self.channelID,"user_chat_list"..uid,serviceFunctions.systemTime(),string.format("%d_%s",chatType,ID))
	end)
	data.err = gErrDef.Err_None
	self:response(data.uid,data)
end

--清除玩家相关数据(移除玩家时使用)
function chatCenter:clearPlayerData(uid)
	Log.i("clearPlayerData==",uid)
	local ok,ret = chatRedisLib.zRevRange(self.channelID,"user_chat_list"..uid,0,-1,true)
	if ok then
		ret = serviceFunctions.tableFormat(ret, { "ID", "time" })
	end
	Log.dump(ret,"chatCenter:clearPlayerData ret",10)
	for _,data in pairs(ret) do
		local IDList = string.split(data.ID, '_')
		Log.dump(IDList,"chatCenter:clearPlayerData IDList",10)
		if tonumber(IDList[1]) == gChatKind.PRIVATE_CHAT then
			--清除相关私聊
			toUid = tonumber(IDList[2])
			chatRedisLib.zRem(self.channelID,"user_chat_list"..uid,string.format("%d_%d",gChatKind.PRIVATE_CHAT,toUid))
			chatRedisLib.zRem(self.channelID,"user_chat_list"..toUid,string.format("%d_%d",gChatKind.PRIVATE_CHAT,uid))
		else
			--清除相关聊天室
			local createKid = tonumber(IDList[3])
			local roomID = string.format("%d_%d_%d_%d",tonumber(IDList[2]),tonumber(IDList[3]),tonumber(IDList[4]),tonumber(IDList[5]))
			local roominfo = {}
			local saveKey = string.format("roominfo_%s",tostring(createKid))
			local success,ret = chatRedisLib.hGet(createKid, saveKey, roomID)
			if ret then
				ret = json.decode(ret)
			end
			if success and ret and next(ret) then
				roominfo = ret
			end
			if next(roominfo) then
				if roominfo.info.owner == uid then
					local data = {
						kid = createKid,
						roomID = roomID,
						uid = uid,
					}
					self:dimissRoom(data)
				else
					local data = {
						kid = createKid,
						roomID = roomID,
						uid = uid,
					}
					self:quitRoom(data)
				end
			else
				chatRedisLib.zRem(self.channelID,"user_chat_list"..uid,data.ID)
			end
		end
	end
end

----------------------------------------------------------
--客户端发上来的tcp消息
function chatCenter:receive(fd, msg )
	
	assert(nil~=msg,"msg is nil")
	local msgjson = json.decode(msg)
	assert(nil~=msgjson,"json decode error")
	
	if msgjson.cmd ~= gChatCmd.REQ_NEW_CHAT_HEARTBEAT then
		Log.i("receive= =",fd,msg)
	end

	local cmd = msgjson.cmd
	local param = {}
	if not self.transform[cmd] then
		Log.i(transformTableToString(msgjson,"not self.transform[cmd]"))
		return
	end
	assert(self.transform[cmd],"invalid cmd =" .. cmd )
	local funcname = self.transform[cmd].funcname
	local fun = assert(instance[funcname])
	local ok,ret = xpcall(fun,serviceFunctions.exception, self, msgjson)
	if not ok then
		Log.i("chatCenter:receive error= ",cmd)
	end
end

--玩家中心分发消息

function chatCenter:dispatch(session, source, cmd, ...)
	local f = assert(instance[cmd])
    if self.sendCmd[cmd] then
        f(self, ...)
    else
        local ok,ret = xpcall(f,serviceFunctions.exception,self, ...)
        skynet.ret(skynet.pack(ok,ret))
    end
end

return chatCenter