--[[
	与teamChatCtrl相比有成员管理的聊天  
]]
local skynet = require "skynet"
local myScheduler = require("myScheduler").new()
local json = require "json"
local nodeAPI = require("nodeAPI")
local cluster = require("cluster")
local chatRedisLib = require("chatRedisLib")
local dataCacheCenterLib = require("dataCacheCenterLib")
local chatBaseCtrl = require("chatBaseCtrl")
local roomChatCtrl = class("roomChatCtrl",chatBaseCtrl)
local EXPIRE_TIME = 86400 * 30 --三个月的过期时间
local INIT_INDEX = 1 --初始化加载的条目
function roomChatCtrl:ctor(channelID)
	roomChatCtrl.super.ctor(self,channelID)
	--[[
		所有与room_id相关的，必须由创建者来请求获得数据,避免重入问题和数据在多处管理的情况
	]]
	--聊天室有人数信息
	self.roominfo = {
		--[[                群名字  类型（普通、灰烬、战场。。。） 玩家列表    
		roomid = { info = {name=xxx,type=1} , list= {{kid=kid1,uid=uid1},{kid=kid2,uid=uid2},... }
		--]]
	}
	--room刷新时间表
	self.roomRefreshTime = {
		--roomid = 21342424
	}
	--正在加载房间数据
	self.loadingRoom = {
		--[[
		roomid = (0 = 加载中,1=完成加载)
		]]
	}
	self.chatKind = gChatKind.ROOM_CHAT
	local time = serviceFunctions.systemTime() + 300
    myScheduler:schedule(handler(self,self.clearDueCache),time,nil,true)
    myScheduler:start()
    self.logAPI = include("logAPI").new("roomChat")
end

--[[
创建聊天室
]]
function roomChatCtrl:createRoom( data,isCall)
	Log.dump(data,"createRoom data",10)
	local ownerkid = data.ownerkid
	local owneruid = data.owneruid
	local name = data.name
	local roomType = data.roomType
	local participantList = data.participantList
	local uidK = tostring(owneruid)
	if type(ownerkid) ~= "number" or type(owneruid) ~= "number" or type(roomType) ~= "number" then
		return {err = gErrDef.Err_ILLEGAL_PARAMS}
	end
	
	if not self:checkRoomNum(owneruid) then
		return {err = gErrDef.Err_CHATROOM_NUM_MAX}
	end
	local cKid = dataCacheCenterLib.getColum(owneruid, "kid") or ownerkid
	local sKid = dataCacheCenterLib.getColum(owneruid, "sKid")
	if sKid and sKid == 0 then
		sKid = ownerkid
	end
	if svrconf.isInSameServer(cKid,sKid) or isCall then
		--生成roomID
		local autoIncrID = serviceFunctions.systemTime() * 10
		local roomID = string.format("%d_%d_%d_%d",roomType,sKid,owneruid,autoIncrID)
		repeat
			roomID = string.format("%d_%d_%d_%d",roomType,sKid,owneruid,autoIncrID)
			local roominfo = self.roominfo[roomID]
			if roominfo then
				autoIncrID = autoIncrID + 1
			else
				break
			end
		until 1

		--清除聊天室聊天数据
		skynet.fork(function (  )
			chatRedisLib.delete(self.channelID, self:getRoomChatSaveKey(roomID) )
		end)
		--聊天消息清空
		self.chatCache[roomID] = nil

		--创建者加入到聊天室中去
		serviceFunctions.makeTable(self.roominfo,roomID)
		roominfo = self.roominfo[roomID]
		roominfo.list = {}
		roominfo.info = {
			owner = owneruid,
			name = name,
			roomType = roomType
		}
		
		--订阅该聊天室
		local gateAddr = svrAddressMgr.getSvr(svrAddressMgr.chatgateSvr,nil,dbconf.chatnodeid)
		skynet.call(gateAddr,skynet.PTYPE_LUA,"makeRoomBroadcast",roomID)
		skynet.send(gateAddr,skynet.PTYPE_LUA,"subscribeOneBroadcast",gChatSubscribeType.room,roomID,owneruid)

		--加入参与者
		local uids = {}
		table.insert(uids,owneruid)
		if participantList and next(participantList) then
			for _, participant in pairs(participantList) do
				table.insert(uids,participant.uid)
			end
		end
		local result = self:joinRoom({kid=sKid,uids=uids,roomID=roomID,optUid=owneruid},nil,true)

		--加载完成标志，就不需要再去加载了
		self.roomRefreshTime[roomID] = serviceFunctions.systemTime()
		self.loadingRoom[roomID] = 1

		-- 数据库操作
		local saveDBSvr = serviceFunctions.getSaveDBServiceAddr(DB_SERVICE_INSTANCE,sKid)
		skynet.send(saveDBSvr,skynet.PTYPE_LUA,"insertToDB",sKid,roomID)

		local logdata = {
	    	types = 6,
	    	crid = roomID,
	    	uids = uids,
	    }
		self.logAPI:writeLog4Mgr(cKid,owneruid,gLogType.discussion_oper_log,logdata)

		return {err = gErrDef.Err_None,roomID = roomID,result = result}
	else
		local nodename,addr = svrconf.getChatAddr(sKid,owneruid)
		local ok,result = cluster.call(nodename,addr,"createRoom",data,true)
		return result
	end
end

--[[
加入聊天室
]]
function roomChatCtrl:joinRoom(data,isCall,isCreate)
	Log.dump(data,"joinRoom data",10)
	local kid = data.kid
	local optUid = data.optUid
	local roomID = data.roomID
	local uids = data.uids
	local isForce = data.isForce
	if type(kid) ~= "number" or type(uids) ~= "table" or type(roomID) ~= "string" then
		return gErrDef.Err_ILLEGAL_PARAMS
	end
	local roomType,createKid,createUid, _ = self:divideRoomID(roomID)
	local result = {}
	--通知到聊天室所在服务
	if svrconf.isInSameServer(kid,createKid) or isCall then
		local toAddr = serviceFunctions.getChatServiceAddr(createUid)
		local srcAddr = serviceFunctions.getChatServiceAddr(optUid)
		if toAddr == srcAddr or isCall then
			--判断聊天室是否存在
			local ok = self:loadRoomChat(roomID)
			if not ok then
				return gErrDef.Err_CHATROOM_NOT_EXIST
			end
			for _,uid in pairs(uids) do
				local curKid = dataCacheCenterLib.getColum(uid, "kid")
				local nickName = dataCacheCenterLib.getColum(uid, "nickName")
				local uidK = tostring(uid)
				local err = gErrDef.Err_None
				
				if roomType == gRoomType.NORMAL then
					local shieldList = dataCacheCenterLib.getUserShieldList(uid,kid)
					if shieldList then
						for _,sheildUid in pairs(shieldList) do
				            if sheildUid == optUid then
				                err = gErrDef.Err_BE_SHIELD
				                break
				            end
				        end
				    end
			    end

				if err == gErrDef.Err_None then
					local roominfo = self.roominfo[roomID]
					
					local participantList = roominfo.list
					if #participantList >= 50 then
						err = gErrDef.Err_CHATROOM_NUM_MAX
					end
					local have = false
					for _,participant in pairs(participantList) do
						if participant.uid == uid then
							have = true
							break
						end
					end
					if have then
						err = gErrDef.Err_CHATROOM_ALREADY_IN
					else
						table.insert(roominfo.list,{kid = curKid,uid = uid})
					end

					--通知到被操作玩家所在服务添加roomID
					if svrconf.isInSameServer(curKid,createKid) then
						local srcAddr = serviceFunctions.getChatServiceAddr(createUid)
						local toAddr = serviceFunctions.getChatServiceAddr(uid)
						if toAddr == srcAddr then
							err = self:roomuserChange(1,{uid=uid,kid=curKid,roomID=roomID,roominfo=roominfo},isCreate)
						else
							ok,err = skynet.call(toAddr,skynet.PTYPE_LUA,"roomuserChange",1,{uid=uid,kid=curKid,roomID=roomID,roominfo=roominfo},isCreate)
						end
					else
						local nodename,addr = svrconf.getChatAddr(curKid,uid)
						ok,err = cluster.call(nodename,addr,"roomuserChange",1,{uid=uid,kid=curKid,roomID=roomID,roominfo=roominfo},isCreate)
					end

					if err == gErrDef.Err_None then
						self.roomRefreshTime[roomID] = serviceFunctions.systemTime()
						-- redis操作
						skynet.fork(function (  )
							chatRedisLib.hSet(createKid,self:getRoomInfoSaveKey(createKid), roomID, json.encode(roominfo))
						end)
					else
						for i=#roominfo.list,1,-1 do
							if roominfo.list[i].uid == uid then
								table.remove(roominfo.list,i)
							end
						end
					end
				end
				table.insert(result,{err = err,nickName = nickName})
			end
			if isCall then
				return result
			end
		else
			ok,result = skynet.call(toAddr,skynet.PTYPE_LUA,"joinRoom",data,true)
		end
	else
		local nodename,addr = svrconf.getChatAddr(createKid,createUid)
		ok,result = cluster.call(nodename,addr,"joinRoom",data,true,isCreate)
	end

	return result
end

--[[
加载聊天室聊天
]]
function roomChatCtrl:loadRoomChat(roomID)
	Log.d("loadRoomChat roomID",roomID)
	Log.d("loadRoomChat self.loadingRoom[roomID] exist =",self.loadingRoom[roomID])
	local roomType,kid,uid,autoIncrID = self:divideRoomID(roomID)
	if not self.loadingRoom[roomID] then
		self.loadingRoom[roomID] = 0 --开始加载
		--加载聊天室基本信息
		if not self.roominfo[roomID] then
			local success,ret = chatRedisLib.hGet(kid, self:getRoomInfoSaveKey(kid), roomID)
			-- Log.dump(ret,"loadRoomChat ret",10)
			if ret then
				ret = json.decode(ret)
			end
			if success and ret and next(ret) then
				self.roominfo[roomID] = ret
			else
				self.loadingRoom[roomID] = nil --加载失败
				return false
			end
		end
		--加载聊天室聊天记录
		self.chatCache[roomID] = self:loadData(self:getRoomChatSaveKey(roomID))
		self.roomRefreshTime[roomID] = serviceFunctions.systemTime()
		self.loadingRoom[roomID] = 1 --完成加载
		return true,serviceFunctions.getTableByRange(self.chatCache[roomID],1,INIT_INDEX)
	elseif self.loadingRoom[roomID] == 1 then
		self.roomRefreshTime[roomID] = serviceFunctions.systemTime()
		return true,serviceFunctions.getTableByRange(self.chatCache[roomID],1,INIT_INDEX)
	end
	self.roomRefreshTime[roomID] = serviceFunctions.systemTime()
	return true,{}
end

--[[
解散聊天室
]]
function roomChatCtrl:dimissRoom(data,isCall)
	Log.dump(data,"dimissRoom data",10)
	local roomID = data.roomID
	local roomType,createKid,createUid, _ = self:divideRoomID(roomID)
	local kid = data.kid or createKid
	local uid = data.uid or createUid
	local optUid = data.optUid or uid
	local isForce = data.isForce
	if type(kid) ~= "number" or type(optUid) ~= "number" or type(roomID) ~= "string" or type(uid) ~= "number" then
		return gErrDef.Err_ILLEGAL_PARAMS
	end
	if svrconf.isInSameServer(kid,createKid) or isCall then
		local toAddr = serviceFunctions.getChatServiceAddr(createUid)
		local srcAddr = serviceFunctions.getChatServiceAddr(optUid)
		if toAddr == srcAddr or isCall then
			self:loadRoomChat(roomID)
			if not self.roominfo[roomID] and not isForce then
				return gErrDef.Err_CHATROOM_NOT_EXIST
			end

			--通知玩家解散聊天室
			local roominfo = self.roominfo[roomID]
			
			if roominfo.info.owner ~= optUid and not isForce then
				return gErrDef.Err_CHATROOM_OPT_MUST_OWNER
			end
			
			if roominfo then
				local participantList = roominfo.list
				if participantList and next(participantList) then
					for _,participant in pairs(participantList) do
						local participantKid = dataCacheCenterLib.getColum(participant.uid, "kid")
						if svrconf.isInSameServer(kid,participantKid) then
							local toAddr = serviceFunctions.getChatServiceAddr(participant.uid)
							local srcAddr = serviceFunctions.getChatServiceAddr(uid)
							if toAddr == srcAddr then
								self:quitRoom({kid=participantKid,uid=participant.uid,roomID=roomID,isForce=true},true)
							else
								skynet.send(toAddr,skynet.PTYPE_LUA,"quitRoom",{kid=participantKid,uid=participant.uid,roomID=roomID,isForce=true},true)
							end
						else
							local nodename,addr = svrconf.getChatAddr(participantKid,participant.uid)
							cluster.send(nodename,addr,"quitRoom",{kid=participantKid,uid=participant.uid,roomID=roomID,isForce=true},true)
						end
						
						if roomType == gRoomType.NORMAL then
							skynet.fork(function ()
								--发送聊天室解散通知
								local kid = dataCacheCenterLib.getColum(participant.uid, "kid")
								local data = {}
								data.contentType = 255 --Content_CHAT_ROOM_DIMISS聊天室解散
								data.content = {npcId = 1000,name = roominfo.info.name}
								local ok,nodename = svrconf.getKingdomNodename(kid)
			    				if ok then
						            local addr = string.format(svrAddressMgr.mailSvr, kid)
						            local ret = cluster.call(nodename,addr,"sendNPCGuideMail", {participant.uid}, data)
						        end
							end)
						end
					end
				end
			end

			--聊天消息清空
			self.chatCache[roomID] = nil

			--清空聊天室
			self.roominfo[roomID] = nil
			self.loadingRoom[roomID] = nil

			skynet.fork(function (  )
				chatRedisLib.delete(self.channelID, self:getRoomChatSaveKey(roomID) )
			end)
			skynet.fork(function (  )
				chatRedisLib.hDel(createKid, self:getRoomInfoSaveKey(createKid), roomID)
			end)

			--数据库操作
			local saveDBSvr = serviceFunctions.getSaveDBServiceAddr(DB_SERVICE_INSTANCE,kid)
			skynet.send(saveDBSvr,skynet.PTYPE_LUA,"deleteFromDB",kid,roomID)

			--删除订阅
			local gateAddr = svrAddressMgr.getSvr(svrAddressMgr.chatgateSvr,nil,dbconf.chatnodeid)
			skynet.call(gateAddr,skynet.PTYPE_LUA,"delRoomBroadcast",roomID)

			local logdata = {
		    	types = 3,
		    	crid = roomID,
		    }
			self.logAPI:writeLog4Mgr(kid,optUid,gLogType.discussion_oper_log,logdata)

			return gErrDef.Err_None
		else
			local ok,err = skynet.call(toAddr,skynet.PTYPE_LUA,"dimissRoom",data,true)
			return err
		end
	else
		local nodename,addr = svrconf.getChatAddr(createKid,createUid)
		local ok,err = cluster.call(nodename,addr,"dimissRoom",data,true)
		return err
	end
end

--[[
退出聊天室
]]
function roomChatCtrl:quitRoom(data,isNotCallOther,isCall)
	Log.dump(data,"quitRoom data",10)
	-- Log.d("quitRoom isNotCallOther",isNotCallOther)
	local kid = data.kid
	local uid = data.uid
	local optUid = data.optUid or uid
	local isForce = data.isForce
	local roomID = data.roomID
	local uidK = tostring(uid)
	if type(kid) ~= "number" or type(optUid) ~= "number" or type(roomID) ~= "string" or type(uid) ~= "number" then
		return gErrDef.Err_ILLEGAL_PARAMS
	end
	local roomType,createKid,createUid,_ = self:divideRoomID(roomID)
	--通知到被操作玩家所在服务添加roomID
	local cKid = dataCacheCenterLib.getColum(uid, "kid") or kid
	local sKid = dataCacheCenterLib.getColum(uid, "sKid")
	if sKid and sKid == 0 then
		sKid = cKid
	end
	if not isCall then
		--只要做一次就可以
		if svrconf.isInSameServer(cKid,sKid) then
			local srcAddr = serviceFunctions.getChatServiceAddr(createUid)
			local toAddr = serviceFunctions.getChatServiceAddr(uid)
			if toAddr == srcAddr then
				self.roomRefreshTime[roomID] = serviceFunctions.systemTime()
				self:roomuserChange(2,{uid=uid,kid=cKid,roomID=roomID,optUid=optUid})
			else
				skynet.call(toAddr,skynet.PTYPE_LUA,"roomuserChange",2,{uid=uid,kid=cKid,roomID=roomID,optUid=optUid})
			end
		else
			local nodename,addr = svrconf.getChatAddr(cKid,uid)
			cluster.call(nodename,addr,"roomuserChange",2,{uid=uid,kid=sKid,roomID=roomID,optUid=optUid})
		end
	end
	if not isNotCallOther then
		if svrconf.isInSameServer(cKid,createKid) or isCall then
			local toAddr = serviceFunctions.getChatServiceAddr(createUid)
			local srcAddr = serviceFunctions.getChatServiceAddr(optUid)
			if toAddr == srcAddr or isCall then
				self:loadRoomChat(roomID)
				--判断聊天室是否存在
				-- Log.dump(self.roominfo[roomID],"quitRoom roominfo before",10)
				if not self.roominfo[roomID] then
					return gErrDef.Err_CHATROOM_NOT_EXIST
				end
				local roominfo = self.roominfo[roomID]
				if (roominfo.info.owner ~= optUid and optUid ~= uid) and not isForce then
					return gErrDef.Err_CHATROOM_OPT_MUST_OWNER
				end
				local participantList = roominfo.list
				-- Log.dump(participantList,"quitRoom participantList",10)
				local tmpLen = #participantList
				for i=tmpLen,1,-1 do
					local participantUID = participantList[i].uid
					if participantUID == uid then
						table.remove(participantList,i) --移除
						break
					end
				end
				if not next(participantList) then
					self:dimissRoom({roomID=roomID,isForce=true})
				else
					-- Log.dump(roominfo,"quitRoom roominfo after",10)
					--redis操作
					skynet.fork(function (  )
						chatRedisLib.hSet(createKid,self:getRoomInfoSaveKey(createKid), roomID, json.encode(roominfo))
					end)
				end
				
				--发送一个退出的系统消息
				local text = gSysBroadcastType.quitRoom
				local sendUid = uid
				if optUid ~= uid then
					sendUid = optUid
					text = gSysBroadcastType.kickRoom
					if roomType == gRoomType.NORMAL then
						skynet.fork(function ()
							local data = {}
							data.contentType = 256 --Content_CHAT_ROOM_KICK踢出聊天室
							data.content = {npcId = 1000,name = roominfo.info.name}
							local ok,nodename = svrconf.getKingdomNodename(cKid)
	        				if ok then
					            local addr = string.format(svrAddressMgr.mailSvr, cKid)
					            local ret = cluster.call(nodename,addr,"sendNPCGuideMail", {uid}, data)
					        end
						end)
					end

					local logdata = {
				    	types = 4,
				    	crid = roomID,
				    	uid = uid
				    }
					self.logAPI:writeLog4Mgr(cKid,optUid,gLogType.discussion_oper_log,logdata)
				else
					sendUid = uid
					text = gSysBroadcastType.quitRoom
					local logdata = {
				    	types = 2,
				    	crid = roomID,
				    	uid = uid
				    }
					self.logAPI:writeLog4Mgr(cKid,uid,gLogType.discussion_oper_log,logdata)
				end
				local sendUserinfo = dataCacheCenterLib.getAllColum(sendUid)
				local quitUserinfo = dataCacheCenterLib.getAllColum(uid)
				local data = {
					kid = cKid,
					uid = sendUid,
					roomID = roomID,
					msg = {
						chatType = gChatType.BROADCAST,
						text = text,
						extra = {nickName = quitUserinfo.nickName,uid=uid},
					},
					userinfo = sendUserinfo
				}
				self:send2room(data,true)
				self.roomRefreshTime[roomID] = serviceFunctions.systemTime()
				return gErrDef.Err_None
			else
				local ok,err = skynet.call(toAddr,skynet.PTYPE_LUA,"quitRoom",data,false,true)
				return err
			end
		else
			local nodename,addr = svrconf.getChatAddr(createKid,createUid)
			local ok,err = cluster.call(nodename,addr,"quitRoom",data,false,true)
			return err
		end
	end
end

--获取聊天室聊天数据
function roomChatCtrl:getInitRoomChatData(data,roomList,isInit)
	Log.dump(data,"roomChatCtrl:getInitRoomChatData data",10)
	local kid = data.kid
	local uid = data.uid
	local uidK = tostring(uid)
	local sendMsg = {}
	local success , roomIDs = chatRedisLib.sMembers( self.channelID, self:getRoomUserSaveKey(uid) )
	if success and roomIDs and next(roomIDs) then
		for _,roomID in pairs(roomIDs) do
			local gateAddr = svrAddressMgr.getSvr(svrAddressMgr.chatgateSvr,nil,dbconf.chatnodeid)
			skynet.call(gateAddr,skynet.PTYPE_LUA,"makeRoomBroadcast",roomID)
			skynet.send(gateAddr,skynet.PTYPE_LUA,"subscribeOneBroadcast",gChatSubscribeType.room,roomID,uid)
			local roomType,createKid,createUid,_ = self:divideRoomID(roomID)
			if isInit and roomType ~= gRoomType.NORMAL then
				local have,ret = self:getOneInitRoomChatData({kid=kid,uid=uid,roomID=roomID})
				if have then
					table.insert(sendMsg,ret)
				else
					Log.i("getInitRoomChatData not have",kid,uid,roomID)
				end
			else
				-- Log.dump(roomList,"roomChatCtrl:getInitRoomChatData roomList"..roomID,10)
				local roomList = roomList
				if not roomList then
					roomList = data.roomList
				end
				for _,v in pairs(roomList) do
					if v.ID == roomID then
						local have,ret = self:getOneInitRoomChatData({kid=kid,uid=uid,roomID=roomID})
						if have then
							local _,score = chatRedisLib.zScore(self.channelID,"user_chat_list"..uid,string.format("%d_%s",gChatKind.ROOM_CHAT,roomID))
							ret.alreadyReadTime = tonumber(score) % 10000000
							ret.isTop = v.isTop
							table.insert(sendMsg,ret)
						else
							Log.i("getInitRoomChatData not have",kid,uid,roomID)
						end
					end
				end
			end
		end
	end
	return sendMsg
end

--获取单一聊天室初始化数据
function roomChatCtrl:getOneInitRoomChatData(data,isCall)
	-- Log.dump(data,"getOneInitRoomChatData data",10)
	-- Log.d("getOneInitRoomChatData isCall",isCall)
	local kid = data.kid
	local uid = data.uid
	local roomID = data.roomID
	local uidK = tostring(uid)
	local roomChatData = {}
	local have = false
	local roomType,createKid,createUid,_ = self:divideRoomID(roomID)
	--如果不相同王国且地址又不一样的时候要跨到其他聊天服取数据
	if svrconf.isInSameServer(kid,createKid) then
		local toAddr = serviceFunctions.getChatServiceAddr(createUid)
		local srcAddr = serviceFunctions.getChatServiceAddr(uid)
		--还需要判断是否是同一个服务
		if toAddr == srcAddr then
			local ok,chatData = self:loadRoomChat(roomID)
			if ok then
				local roominfo = {}
				roominfo.info = self.roominfo[roomID].info
				roominfo.list = {}
				for _,user in pairs(self.roominfo[roomID].list) do
					local userinfo = dataCacheCenterLib.getAllColum(user.uid)
					table.insert(roominfo.list,{kid=userinfo.kid,uid=userinfo.uid,nickName=userinfo.nickName,imageId=userinfo.imageId})
				end
				
				if next(chatData) then
					if isCall then
						-- Log.d("getOneInitRoomChatData ok")
						return {err = gErrDef.Err_None,kind = gChatKind.ROOM_CHAT,roomID = roomID,chatData = serviceFunctions.getTableByRange(chatData,1,2),roomInfo = roominfo}
					else
						have = true
						roomChatData = {err = gErrDef.Err_None,roomID = roomID,kind = gChatKind.ROOM_CHAT,chatData = serviceFunctions.getTableByRange(chatData,1,2),roomInfo = roominfo}
					end
				else
					self:dimissRoom({roomID = roomID, isForce = true})
					if isCall then
						return {err = gErrDef.Err_CHATROOM_NOT_EXIST,kind = gChatKind.ROOM_CHAT,roomID = roomID}
					end
				end	
			else
				if isCall then
					-- Log.d("getOneInitRoomChatData not ok")
					return {err = gErrDef.Err_CHATROOM_NOT_EXIST,kind = gChatKind.ROOM_CHAT,roomID = roomID}
				else
					roomChatData = {err = gErrDef.Err_CHATROOM_NOT_EXIST,kind = gChatKind.ROOM_CHAT,roomID = roomID}
					self:quitRoom({kid=kid,uid=uid,roomID=roomID,isForce=true},true)
				end
			end
		else
			local ok,ret = skynet.call(toAddr,skynet.PTYPE_LUA,"getOneInitRoomChatData",{kid=createKid,uid=createUid,roomID = roomID},true)
			-- Log.dump(ret,"getOneInitRoomChatData ret",10)
			if ok and ret.err == gErrDef.Err_None then
				have = true
				roomChatData = ret
			else
				self:quitRoom({kid=kid,uid=uid,roomID=roomID,isForce=true},true)
			end
		end
	else
		local nodename,addr = svrconf.getChatAddr(createKid,createUid)
		local ok,ret = cluster.call(nodename,addr,"getOneInitRoomChatData",{kid=createKid,uid=createUid,roomID = roomID},true)
		if ok and ret.err == gErrDef.Err_None then
			have = true
			roomChatData = ret
		else
			self:quitRoom({kid=kid,uid=uid,roomID=roomID,isForce=true},true)
		end
	end
	-- Log.dump(roomChatData,"getOneInitRoomChatData roomChatData",10)
	return have,roomChatData
end

--[[
保证房间类型唯一性
]]
function roomChatCtrl:keepRoomTypeUniqueness(data,isCall)
	-- Log.dump(data,"roomChatCtrl:keepRoomTypeUniqueness data",10)
	-- Log.d("keepRoomTypeUniqueness isCall=",isCall)
	local kid = data.kid
	local uid = data.uid
	local roomID = data.roomID
	local roomuser = data.roomuser
	local curRoomType,createKid,createUid,_ = self:divideRoomID(roomID)
	if roomuser and next(roomuser) then
		for i = #roomuser, 1, -1 do
			local roomType,createKid,createUid,_ = self:divideRoomID(roomuser[i])
			if (curRoomType == gRoomType.ASHTEMPLE
			 	or curRoomType == gRoomType.GLORYBATTLE)
				and curRoomType == roomType then
				--移除玩家关联的聊天室
				skynet.fork(function ()
					chatRedisLib.sRem(self.channelID, self:getRoomUserSaveKey(uid), roomuser[i])
				end)
				if svrconf.isInSameServer(kid,createKid) or isCall then
					local toAddr = serviceFunctions.getChatServiceAddr(createUid)
					local srcAddr = serviceFunctions.getChatServiceAddr(uid)
					--还需要判断是否是同一个服务
					if toAddr == srcAddr or isCall then
						self:loadRoomChat(roomuser[i])
						if self.roominfo[roomuser[i]] then
							self:quitRoom({kid=kid,uid=uid,roomID=roomuser[i],isForce=true})
						end
					else
						skynet.send(toAddr,skynet.PTYPE_LUA,"keepRoomTypeUniqueness",{kid=kid,uid=uid,roomID = roomID,roomuser=roomuser},true)
					end
				else
					local nodename,addr = svrconf.getChatAddr(createKid,createUid)
					cluster.send(nodename,addr,"keepRoomTypeUniqueness",{kid=kid,uid=uid,roomID = roomID,roomuser=roomuser},true)
				end
			end
		end
	end
end

--[[
发送给聊天室
]]
function roomChatCtrl:send2room(data,isNeedSelf)
	-- Log.dump(data,"roomChatCtrl:send2room data",10)
	local kid = data.kid
	local uid = data.uid
	local roomID = data.roomID
	local msg = data.msg
	data.sendUid = data.sendUid or data.uid
	if type(kid) ~= "number" or type(roomID) ~= "string" or type(uid) ~= "number" or type(msg) ~= "table" then
		return gErrDef.Err_ILLEGAL_PARAMS
	end
	local userinfo = dataCacheCenterLib.getAllColum(data.sendUid)
	local roomType, createKid, createUid, autoIncrID = self:divideRoomID(roomID)
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

	if svrconf.isInSameServer(createKid,kid) then
		local toAddr = serviceFunctions.getChatServiceAddr(createUid)
		local srcAddr = serviceFunctions.getChatServiceAddr(uid)
		if srcAddr == toAddr then
			self:loadRoomChat(roomID)
			serviceFunctions.makeTable(self.chatCache, roomID)

			local maxsize = self.config.max or 100
			local msgid = self:getMsgID()
			serviceFunctions.trimTable(self.chatCache[roomID],maxsize)
			--插入与世界相关的数据
			local msgdata = {text=msg.text,type=msg.chatType,extra=msg.extra, userinfo=userinfo, id=msgid, kid=kid, uid=data.sendUid, sendTime=serviceFunctions.systemTime()}

			--跑马灯不存库 玩家创建时候加入不存
			if msg.chatType ~= gChatType.HORSE_RACE_LAMP and msg.text ~= gSysBroadcastType.empty then
				table.insert(self.chatCache[roomID],1,msgdata)
				--写入待存列表
				self.needSaveList[roomID] = true
			end
			
			local sendMsg = {}
			sendMsg.returnType = gReturnType.insertH
			sendMsg.chatData = {}
			sendMsg.kind = gChatKind.ROOM_CHAT
			sendMsg.roomID = roomID
			table.insert(sendMsg.chatData,msgdata)
			
			local logdata = {
		    	message = msg.text,
		    	chatType = gChatKind.ROOM_CHAT
		    }
			self.logAPI:writeLog4Mgr(kid,data.sendUid,gLogType.player_chat,logdata)

			--广播聊天
			if self.roominfo[roomID] then
				local uids = {}
				local participantList = self.roominfo[roomID].list
				for _,participant in pairs(participantList) do
					table.insert(uids,participant.uid)

					if roomType == gRoomType.NORMAL then
						--刷新玩家聊天排序表中
						local channelID = serviceFunctions.getChannelID(participant.uid)
						skynet.fork(function (  )
							local ok,score = chatRedisLib.zScore(channelID,"user_chat_list"..participant.uid,string.format("%d_%s",gChatKind.ROOM_CHAT,roomID))
							if not ok or not score or tonumber(score) < 20000000000000000 then
								chatRedisLib.zAdd(channelID,"user_chat_list"..participant.uid,serviceFunctions.systemTime()*10000000,string.format("%d_%s",gChatKind.ROOM_CHAT,roomID))
							end
						end)
					end
				end

				local gateAddr = svrAddressMgr.getSvr(svrAddressMgr.chatgateSvr,nil,dbconf.chatnodeid)
				if not isNeedSelf then
					skynet.send(gateAddr,skynet.PTYPE_LUA,"publishRoomMsg",roomID, {uids = uids,sendMsg = sendMsg,excludeUid = data.sendUid})
				else
					skynet.send(gateAddr,skynet.PTYPE_LUA,"publishRoomMsg",roomID, {uids = uids,sendMsg = sendMsg})
				end
				self.roomRefreshTime[roomID] = serviceFunctions.systemTime()
			end
		else
			skynet.send(toAddr,skynet.PTYPE_LUA,"send2room", {kid = createKid,uid = createUid,sendUid = data.sendUid,roomID = roomID,msg = msg,userinfo = userinfo},isNeedSelf)	
		end
	else
		local nodename,addr = svrconf.getChatAddr(createKid,createUid)
		cluster.send(nodename,addr,"send2room",{kid = createKid,uid = createUid,roomID = roomID,sendUid = data.sendUid,msg = msg,userinfo = userinfo},isNeedSelf)
	end
	return err
end

--请求聊天室聊天数据
function roomChatCtrl:getRoomChatData(data,isCall)
	-- Log.dump(data,"getRoomChatData data",10)
	local kid = data.kid
	local uid = data.uid
	local roomID = data.roomID
	local isServerCall = data.isServerCall
	local startIdx = data.startIdx or 1
	local endIdx = data.endIdx
	if type(kid) ~= "number" or type(roomID) ~= "string" or type(uid) ~= "number" then
		return gErrDef.Err_ILLEGAL_PARAMS
	end
	local roomType, createKid, createUid, autoIncrID = self:divideRoomID(roomID)
	local sendMsg = {}
	--如果不相同王国且地址又不一样的时候要跨到其他聊天服取数据
	local cKid = dataCacheCenterLib.getColum(uid, "kid") or kid
	if svrconf.isInSameServer(cKid,createKid) or isCall then
		local toAddr = serviceFunctions.getChatServiceAddr(createUid)
		local srcAddr = serviceFunctions.getChatServiceAddr(uid)
		--还需要判断是否是同一个服务
		if toAddr == srcAddr or isCall then
			self:loadRoomChat(roomID)
			self.roomRefreshTime[roomID] = serviceFunctions.systemTime()
			if self.chatCache[roomID] then
				if isCall then
					return {roomID = roomID,kind = gChatKind.ROOM_CHAT,chatData = serviceFunctions.getTableByRange(self.chatCache[roomID],startIdx,endIdx)}
				else
					sendMsg = {roomID = roomID,kind = gChatKind.ROOM_CHAT,chatData = serviceFunctions.getTableByRange(self.chatCache[roomID],startIdx,endIdx)}
				end
			else
				if isCall then
					return {roomID = roomID,kind = gChatKind.ROOM_CHAT,chatData = {}}
				else
					sendMsg = {roomID = roomID,kind = gChatKind.ROOM_CHAT,chatData = {}}
				end
			end
		else
			local ok,ret = skynet.call(toAddr,skynet.PTYPE_LUA,"getRoomChatData",{kid = createKid,uid = createUid,roomID = roomID,startIdx = startIdx,endIdx = endIdx},true)
			sendMsg = ret
		end
	else
		local nodename,addr = svrconf.getChatAddr(createKid,createUid)
		local ok,ret = cluster.call(nodename,addr,"getRoomChatData",{kid = createKid,uid = createUid,roomID = roomID,startIdx = startIdx,endIdx = endIdx},true)
		sendMsg = ret
	end
	self:filterGDPR(sendMsg)
	if not isServerCall then
		sendMsg.returnType = gReturnType.insertT
		self:send2Gate(uid, sendMsg, gChatSubscribeType.room)
	else
		return sendMsg
	end
end

--转让聊天室
function roomChatCtrl:replaceOwner(data,isCall)
	-- Log.dump(data,"replaceOwner data",10)
	local roomID = data.roomID
	local optUid = data.optUid
	local uid = data.uid
	if type(optUid) ~= "number" or type(roomID) ~= "string" or type(uid) ~= "number" then
		return gErrDef.Err_ILLEGAL_PARAMS
	end
	local roomType,createKid,createUid, _ = self:divideRoomID(roomID)
	local optKid = dataCacheCenterLib.getColum(optUid, "kid")
	local err = gErrDef.Err_None
	if svrconf.isInSameServer(optKid,createKid) or isCall then
		local toAddr = serviceFunctions.getChatServiceAddr(createUid)
		local srcAddr = serviceFunctions.getChatServiceAddr(optUid)
		--还需要判断是否是同一个服务
		if toAddr == srcAddr or isCall then
			self:loadRoomChat(roomID)
			if not self.roominfo[roomID] then
				if isCall then
					return gErrDef.Err_CHATROOM_NOT_EXIST
				else
					err = gErrDef.Err_CHATROOM_NOT_EXIST
				end
			end

			local roominfo = self.roominfo[roomID]
						
			local participantList = roominfo.list
			local have = false
			for _,participant in pairs(participantList) do
				if participant.uid == uid then
					have = true
					break
				end
			end
			if not have then
				if isCall then
					return gErrDef.Err_CHATROOM_NOT_IN
				else
					err = gErrDef.Err_CHATROOM_NOT_IN
				end
			end

			if roominfo.info.owner ~= optUid and not isForce then
				if isCall then
					return gErrDef.Err_CHATROOM_OPT_MUST_OWNER
				else
					err = gErrDef.Err_CHATROOM_OPT_MUST_OWNER
				end
			end
			
			if err == gErrDef.Err_None then
				roominfo.info.owner = uid
				local userinfo = dataCacheCenterLib.getAllColum(optUid)
				local newOwnNickName = dataCacheCenterLib.getColum(uid, "nickName")
				local data = {
					kid = userinfo.kid,
					uid = optUid,
					roomID = roomID,
					msg = {
						chatType = gChatType.BROADCAST,
						text = gSysBroadcastType.replaceRoom,
						extra = {nickName = newOwnNickName,uid=uid},
					},
					userinfo = userinfo
				}
				self:send2room(data,true)

				skynet.fork(function (  )
					chatRedisLib.hSet(createKid,self:getRoomInfoSaveKey(createKid), roomID, json.encode(roominfo))
				end)

				local logdata = {
			    	types = 7,
			    	crid = roomID,
			    	userName = newOwnNickName,
			    }
				self.logAPI:writeLog4Mgr(userinfo.kid,optUid,gLogType.discussion_oper_log,logdata)
			end
		else
			_,err = skynet.call(toAddr,skynet.PTYPE_LUA,"replaceOwner",data,true)
		end
	else
		local nodename,addr = svrconf.getChatAddr(createKid,createUid)
		_,err = cluster.call(nodename,addr,"replaceOwner",data,true)
	end
	return err
end

--聊天室改名
function roomChatCtrl:changeRoomName(data,isCall)
	Log.dump(data,"changeRoomName data",10)
	local roomID = data.roomID
	local optUid = data.optUid
	local kid = data.kid
	local name = data.name
	if type(optUid) ~= "number" or type(roomID) ~= "string" or type(kid) ~= "number" or type(name) ~= "string" then
		return gErrDef.Err_ILLEGAL_PARAMS
	end
	local roomType,createKid,createUid, _ = self:divideRoomID(roomID)
	local err = gErrDef.Err_None
	if svrconf.isInSameServer(kid,createKid) or isCall then
		local toAddr = serviceFunctions.getChatServiceAddr(createUid)
		local srcAddr = serviceFunctions.getChatServiceAddr(optUid)
		--还需要判断是否是同一个服务
		if toAddr == srcAddr or isCall then
			self:loadRoomChat(roomID)
			if not self.roominfo[roomID] then
				if isCall then
					return gErrDef.Err_CHATROOM_NOT_EXIST
				else
					err = gErrDef.Err_CHATROOM_NOT_EXIST
				end
			end

			local roominfo = self.roominfo[roomID]
			
			if roominfo.info.owner ~= optUid then
				if isCall then
					return gErrDef.Err_CHATROOM_OPT_MUST_OWNER
				else
					err = gErrDef.Err_CHATROOM_OPT_MUST_OWNER
				end
			end
			
			roominfo.info.name = name

			local data = {
				kid = kid,
				uid = optUid,
				roomID = roomID,
				msg = {
					chatType = gChatType.BROADCAST,
					text = gSysBroadcastType.changeRoomNmae,
					extra = {roomName = name},
				},
				userinfo = dataCacheCenterLib.getAllColum(optUid)
			}
			self:send2room(data,true)
			
			skynet.fork(function (  )
				chatRedisLib.hSet(createKid,self:getRoomInfoSaveKey(createKid), roomID, json.encode(roominfo))
			end)

			local logdata = {
		    	types = 5,
		    	crid = roomID,
		    	newName = name,
		    }
			self.logAPI:writeLog4Mgr(kid,optUid,gLogType.discussion_oper_log,logdata)
		else
			_,err = skynet.call(toAddr,skynet.PTYPE_LUA,"changeRoomName",data,true)
		end
	else
		local nodename,addr = svrconf.getChatAddr(createKid,createUid)
		_,err = cluster.call(nodename,addr,"changeRoomName",data,true)
	end

	return err
end

--roomuser数据修改
function roomChatCtrl:roomuserChange(opt,data,isCreate)
	Log.dump(data,"roomChatCtrl:roomuserChange"..opt,10)
	local uid = data.uid
	local kid = data.kid
	local roomID = data.roomID
	local optUid = data.optUid or uid
	local roominfo = data.roominfo
	local uidK = tostring(uid)
	local roomType, createKid, createUid, autoIncrID = self:divideRoomID(roomID)
	local err = gErrDef.Err_None
	local roomuser = {}
	local success , roomIDs = chatRedisLib.sMembers( self.channelID, self:getRoomUserSaveKey(uid) )
	if success and roomIDs and next(roomIDs) then
		roomuser = roomIDs
	end
	if opt == 1 then
		--添加
		if not self:checkRoomNum(uid) then
			return gErrDef.Err_CHATROOM_NUM_MAX
		end

		local found = false
		if next(roomuser) then
			for _,tmpRoomID in pairs(roomuser) do
				if tmpRoomID == roomID then
					found = true
					break
				end
			end
		end
	
		if not found then
			--保证灰烬神殿唯一性
			self:keepRoomTypeUniqueness({kid=kid,uid=uid,roomID=roomID,roomuser=roomuser})
			table.insert(roomuser,roomID)

			local gateAddr = svrAddressMgr.getSvr(svrAddressMgr.chatgateSvr,nil,dbconf.chatnodeid)
			skynet.call(gateAddr,skynet.PTYPE_LUA,"makeRoomBroadcast",roomID)
			skynet.send(gateAddr,skynet.PTYPE_LUA,"subscribeOneBroadcast",gChatSubscribeType.room,roomID,uid)

			local sendMsg = {}
			sendMsg.roomChatData = {}
			local ret = self:getRoomChatData({kid=kid,uid=uid,roomID=roomID,startIdx=1,endIdx=10,isServerCall=true})
			
			local info = {}
			info.info = roominfo.info
			info.list = {}
			for _,user in pairs(roominfo.list) do
				local userinfo = dataCacheCenterLib.getAllColum(user.uid)
				table.insert(info.list,{kid=userinfo.kid,uid=userinfo.uid,nickName=userinfo.nickName,imageId=userinfo.imageId})
			end
			ret.roomInfo = info
			table.insert(sendMsg.roomChatData,ret)
			sendMsg.returnType = gReturnType.init
			self:send2Gate(uid, sendMsg, gChatSubscribeType.room)
			skynet.fork(function ()
				chatRedisLib.sAdd( self.channelID, self:getRoomUserSaveKey(uid), roomID )
			end)

			if roomType == gRoomType.NORMAL then
				--发送一个加入的系统消息
				if roominfo.info.owner ~= uid then
					local text = gSysBroadcastType.joinRoom
					if isCreate then
						text = gSysBroadcastType.empty
					else
						local logdata = {
					    	types = 1,
					    	crid = roomID,
					    	newName = name,
					    }
						self.logAPI:writeLog4Mgr(kid,optUid,gLogType.discussion_oper_log,logdata)
					end
					local userinfo = dataCacheCenterLib.getAllColum(uid)
					local data = {
						kid = kid,
						uid = uid,
						roomID = roomID,
						msg = {
							chatType = gChatType.BROADCAST,
							text = text,
							extra = {nickName = userinfo.nickName,uid=uid},
						},
						userinfo = userinfo
					}
					self:send2room(data)
				else
					local userinfo = dataCacheCenterLib.getAllColum(uid)
					local data = {
						kid = kid,
						uid = uid,
						roomID = roomID,
						msg = {
							chatType = gChatType.BROADCAST,
							text = gSysBroadcastType.createRoom,
							extra = {nickName = userinfo.nickName,uid=uid},
						},
						userinfo = userinfo
					}
					self:send2room(data,true)
				end
			end
			if roomType == gRoomType.NORMAL then
				--刷新玩家聊天排序表
				skynet.fork(function (  )
					chatRedisLib.zAdd(self.channelID,"user_chat_list"..uid,serviceFunctions.systemTime()*10000000,string.format("%d_%s",gChatKind.ROOM_CHAT,roomID))
				end)
			end
			self:checkRoomNum(uid,true)
		end
	elseif opt == 2 then
		--删除
		if next(roomuser) then
			local tmpLen = #roomuser
			for i=tmpLen,1,-1 do
				local tmpRoomID = roomuser[i]
				if tmpRoomID == roomID then
					--移除玩家关联的聊天室
					skynet.fork(function (  )
						chatRedisLib.sRem( self.channelID, self:getRoomUserSaveKey(uid), roomID )
					end)
					table.remove(roomuser,i)
					local sendMsg = {}
					sendMsg.roomID = roomID
					sendMsg.kind = gChatKind.ROOM_CHAT
					sendMsg.returnType = gReturnType.clear
					self:send2Gate(uid, sendMsg, gChatSubscribeType.room)
					--取消订阅该聊天室
					local gateAddr = svrAddressMgr.getSvr(svrAddressMgr.chatgateSvr,nil,dbconf.chatnodeid)
					skynet.call(gateAddr,skynet.PTYPE_LUA,"unSubscribeOneBroadcast",gChatSubscribeType.room,roomID,uid)
					break
				end
			end
		end
		if roomType == gRoomType.NORMAL then
			skynet.fork(function (  )
				chatRedisLib.zRem(self.channelID,"user_chat_list"..uid,string.format("%d_%s",gChatKind.ROOM_CHAT,roomID))
			end)
		end
	end
	return err
end

--判断玩家聊天室是否已满
function roomChatCtrl:checkRoomNum(uid,isNeedSendMail)
	local roomuser = {}
	local success , roomIDs = chatRedisLib.sMembers( self.channelID, self:getRoomUserSaveKey(uid) )
	if success and roomIDs and next(roomIDs) then
		roomuser = roomIDs
	end
	if roomuser then
		local num = 0
		for _,roomID in pairs(roomuser) do
			local roomType, createKid, createUid, autoIncrID = self:divideRoomID(roomID)
			if roomType == gRoomType.NORMAL then
				num = num + 1
			end
		end
		if num >= 32 then
			if isNeedSendMail then
				skynet.fork(function ()
					--发送聊天室已满通知
					local kid = dataCacheCenterLib.getColum(uid, "kid")
					local data = {}
					data.contentType = 254 --Content_CHAT_ROOM_FULL聊天室已满
					data.content = {npcId = 1000}
					local ok,nodename = svrconf.getKingdomNodename(kid)
					if ok then
			            local addr = string.format(svrAddressMgr.mailSvr, kid)
			            local ret = cluster.call(nodename,addr,"sendNPCGuideMail", {uid}, data)
			        end
				end)
			end
			return false
		end
	end
	return true
end

--删除缓存
function roomChatCtrl:clearDueCache()
	Log.i("roomChatCtrl:clearDueCache")
	for roomID,time in pairs(self.roomRefreshTime) do
		if time < serviceFunctions.systemTime() - 300 then
			self.roominfo[roomID] = nil
			self.loadingRoom[roomID] = nil
			self.chatCache[roomID] = nil
			self.roomRefreshTime[roomID] = nil
		end 
	end
end

--获取（玩家拥有聊天室）key
function roomChatCtrl:getRoomUserSaveKey( uid )
	assert(nil~=uid,"getRoomUserSaveKey uid must not nil")
	return string.format("roomuser_%s",tostring(uid))
end

--获取（聊天室信息）key
function roomChatCtrl:getRoomInfoSaveKey( ID )
	assert( nil~=ID,"getRoomInfoSaveKey ID must not nil")
	return string.format("roominfo_%s",tostring(ID))
end

--获取（聊天室内容）key
function roomChatCtrl:getRoomChatSaveKey(roomID)
	assert( nil~=roomID,"getRoomChatSaveKey roomID must not nil")
	return string.format("roomchat_%s",tostring(roomID))
end

function roomChatCtrl:divideRoomID(roomID)
	local roomType, createKid, createUid, autoIncrID = string.match(roomID,"(%d+)_(%d+)_(%d+)_(%d+)")
	return tonumber(roomType),tonumber(createKid),tonumber(createUid),tonumber(autoIncrID)
end
	
return roomChatCtrl