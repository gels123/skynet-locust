--[[
	连接游戏网关服登录
]]
local skynet = require "skynet"
local crypt = require "client.crypt"
local lfs = require("lfs")
local socket = require("client.socket")
local sproto = require "sproto"
local sprotoparser = require "sprotoparser"
local monitor = require "monitor"
local util = require "util"
local svrFunc = require "svrFunc"
local simSocket = require("simSocket")
local simGate = class("simGate", simSocket)

-- 定义事件
simGate.Gate_Success = "Gate_Success" -- 连接游戏服网关成功事件, 下面开始处理业务

-- 网关相关错误类型
simGate.Err_Gate_HandshakeSuccess = 200 --网关握手成功
simGate.Err_Gate_UserNotFound = 404 --用户没找到
simGate.Err_Gate_IndexExpired = 403 --index版本错误
simGate.Err_Gate_Unauthorized = 401 --网关认证没通过
simGate.Err_Gate_BadRequest = 400 --错误的请求
simGate.Err_Gate_tcpConnected = 100 --simGate tcp connected

-- 状态
local eGateStatus =
{
	handshake = 0,	--握手状态, 客户端发起握手包, 服务器回应
	logined = 1, 	--登录状态, 客户端发起业务包, 服务器回应
}

-- 构造
function simGate:ctor(host, user)
	simGate.super.ctor(self, "simGate")

	cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()

	self.host = host
	self.user = user
	self.index = 0 		-- 连接版本号, 需要>=1, 每次连接都需要比之前的大, 这样可以保证握手包不会被人恶意截获复用
	self.sessionid = 0	-- 请求编号, 防止恶意截获复用
	self.session = {}

	self.status = eGateStatus.handshake

	self.last = "" --上次的socket数据缓存

	self.sproto_host = nil    -- sproto
	self.sproto_request = nil -- sproto

	self:init()

	self.simLogin = require("simLogin").new()
	self.simLogin:addEventListener(self.simLogin.Login_Success, handler(self, self.connectLoginOk))
	self:addEventListener(self.Gate_Success, handler(self, self.connectGateOk))

	-- 数据缓存
	self.data = {
		time = nil, --当前时间
	}

	-- 压测函数与权重配置
	self.minInterval = 2
	self.maxInterval = 10
	self.test =
	{
		reqHeartbeat = function()
			self:request("reqHeartbeat")
		end
	}
	self.fweight = {
		reqHeartbeat = 1,
	}
end

-- 初始化
function simGate:init()
	--Log.d("simGate:init begin==")
	-- c2s客户端到服务端的协议
	local c2sFiles = {"types.sproto",}
	for fileName in lfs.dir("game/service/proto/sproto/") do
		if string.find(fileName, "[%w_]+.c2s.sproto$") then
			table.insert(c2sFiles, fileName)
		end
	end
	local c2sSproto = ""
	for _,fileName in pairs(c2sFiles) do
		c2sSproto = c2sSproto.."\n"..io.readfile("game/service/proto/sproto/"..fileName)
	end
	--Log.d("simGate:init c2sSproto=", c2sSproto)
	local c2sPb = assert(sprotoparser.parse(c2sSproto))
	-- s2c服务端到客户端的协议
	local s2cFiles = {"types.sproto",}
	for fileName in lfs.dir("game/service/proto/sproto/") do
		if string.find(fileName, "[%w_]+.s2c.sproto$") then
			table.insert(s2cFiles, fileName)
		end
	end
	local s2cSproto = ""
	for _,fileName in pairs(s2cFiles) do
		s2cSproto = s2cSproto.."\n"..io.readfile("game/service/proto/sproto/"..fileName)
	end
	--Log.d("simGate:init s2cSproto=", s2cSproto)
	local s2cPb = assert(sprotoparser.parse(s2cSproto))
	self.sproto_host = sproto.new(s2cPb):host("package")
	self.sproto_request = self.sproto_host:attach(sproto.new(c2sPb))
	--Log.d("simGate:init end")
end

-- 连接登录服
function simGate:connectLogin()
	Log.d("simGate:connectLogin host=", self.host, "user=", self.user)
	local token = {
		user = self.user,
		pass = "_",
		subtoken = "_",
	}
	local arr = svrFunc.split(self.host, ":")
	local ip, port = tostring(arr[1]), tonumber(arr[2])
	assert(ip and ip ~= "nil" and port and port > 0)
	self.simLogin:connectLogin(ip, port, token)
end

-- 连接登录服成功
function simGate:connectLoginOk(event)
	Log.i("simGate:connectLoginOk", self.simLogin.ip, self.simLogin.port)
	assert(self.simLogin.ip and self.simLogin.port)
	self:connectGate(self.simLogin.ip, self.simLogin.port)
end

-- 连接网关成功
function simGate:connectGateOk(event)
	Log.i("simGate:connectGateOk nodeid=", self.simLogin.nodeid, "uid=", self.simLogin.uid, "subid=", self.simLogin.subid, "secret=", self.simLogin.secret, "index=", self.index)
	assert(self.simLogin.nodeid and self.simLogin.uid and self.simLogin.subid and self.simLogin.secret)
	self:handshake(self.simLogin.uid, self.simLogin.nodeid, self.simLogin.subid, self.simLogin.secret)
	-- 删除simLogin
	self.simLogin:removeEventListenersByEvent(self.simLogin.Login_Success)
	self.simLogin = nil
end

-- 连接网关
function simGate:connectGate(host, port)
    --Log.d("simGate:connectGate host=", host, "port=", port)
	self.index = self.index + 1
	self.status = eGateStatus.handshake
	self:connect(host, port)
end

-- @override 连接成功
function simGate:onConnected()
	--Log.d("simSocket:onConnected", self.name, self.host, self.port)
	self:dispatchEvent({name = simGate.Gate_Success})
	while(true) do
		local r = self:recv()
		if r then
			self:handleMsg(r)
		elseif self.connected then
			--Log.d("simGate:onConnected loop", self.user)
			skynet.sleep(20)
		else
			Log.d("simGate:onConnected break, sockect close!", self.name)
			break
		end
		local line = socket.readstdin()
		if line then
			self:handleCmd(line)
		end
	end
	self:onFailure()
end

-- @override 连接网关服务器失败
function simGate:onFailure(code)
	Log.w("simGate:onFailure user=", self.user, "code=", code)
    self:close()
	self.last = ""
	skynet.exit()
end

-- 握手
function simGate:handshake(uid, nodeid, subid, secret)
    local handshake = string.format("%s@%s#%s:%d", crypt.base64encode(uid), crypt.base64encode(nodeid), crypt.base64encode(subid), self.index)
    local hmac = crypt.hmac64(crypt.hashkey(handshake), secret)
    local text = handshake .. ":" .. crypt.base64encode(hmac)
	self.sessionid = 0
	self:request("reqHandshake", {text = text,})
end

-- 握手回包处理
function simGate:handshakeRsp(msg)
	local _, t, sessionid, rsp = pcall(function()
		return self.sproto_host:dispatch(msg)
	end)
	local cmd = self.session[sessionid] and self.session[sessionid].cmd
	local code = rsp.code
	if cmd == "reqHandshake" and code == simGate.Err_Gate_HandshakeSuccess then
		Log.d("simGate:handshakeRsp success, code=", code, "text=", rsp.text, "\n")
		self.status = eGateStatus.logined
		-- 统计
		monitor.endtime(sessionid, 1, false)
		monitor.incr(cmd)
		-- 关闭心跳
		self:request("reqHeartbeat")
		self:request("reqHeartbeatSwitch", {close = true,})
		-- 循环：随机请求接口
		skynet.fork(function()
			util.run(self.test, self.fweight, self.minInterval, self.maxInterval)
		end)
	else
		-- 网关握手失败, 登录失败
		Log.d("simGate:handshakeRsp fail", cmd, code, rsp.text)
		-- 统计
		if cmd then
			monitor.incr(cmd)
		end
		monitor.endtime(sessionid, 1, true)
		-- 如果业务拒绝断开连接防止界面一直登陆死循环
		self:onFailure(code)
	end
end

function simGate:reqHeartbeatRsp(ret)
	Log.i("simGate:reqHeartbeatRsp", self.user)
end

function simGate:reqHeartbeatSwitchRsp(ret)
	Log.i("simGate:reqHeartbeatSwitchRsp", self.user)
end
----------------------------------------
-- 数据解包处理和打包
----------------------------------------
-- @override 处理消息
function simGate:handleMsg(r)
	local left = r
	if self.last then
		left = self.last..r
	end
	while true do
		local msg
		msg, left = self:unpackMsg(left)
		if msg then
			self:dispatchMsg(msg)
		else
			break
		end
		if not left then
			break
		end
	end
	self.last = left
end

-- 解包消息
function simGate:unpackMsg(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s + 2 then
		return nil, text --msg, left(result已经把size去掉了)
	end
	return text:sub(3, 2 + s), text:sub(3 + s)
end

-- 处理消息
function simGate:dispatchMsg(msg)
	if self.status == eGateStatus.handshake then
		self:handshakeRsp(msg)
	else
		local _, t, sessionid, rsp = pcall(function()
			return self.sproto_host:dispatch(msg)
		end)
		local cmd = self.session[sessionid] and self.session[sessionid].cmd or sessionid
		--Log.d("simGate:dispatchMsg receive cmd=", cmd, "rsp=", transformTableToString(rsp))
		self.session[sessionid] = nil
		local f = self[cmd.."Rsp"]
		if f then
			local ok = f(self, rsp)
			monitor.incr(cmd)
			if t == 'RESPONSE' then
				monitor.endtime(sessionid, 1, ok == false)
			end
		else
			monitor.incr(cmd)
			if t == 'RESPONSE' then
				monitor.endtime(sessionid, 1, false)
			end
		end
	end
end

--eg: reqHeartbeat time=1665283633
function simGate:handleCmd(line)
	--Log.d("simGate:handleCmd line=", line)
	local cmd
	local p = string.gsub(line, "([%w-_]+)", function (s)
		cmd = s
		return ""
	end, 1)
	local t = {}
	local f = load (p, "=" .. cmd, "t", t)
	if f then
		f()
	end
	if not next (t) then
		t = nil
	end
	if cmd then
		local ok, err = pcall(self.request, self, cmd, t)
		if not ok then
			Log.d(string.format("invalid command (%s), error (%s)", cmd, err))
		end
	end
end

-- 发送消息
function simGate:request(cmd, args)
	Log.d("simGate:request cmd=", cmd, "args=", transformTableToString(args))
	--
	self.sessionid = self.sessionid + 1
	self.session[self.sessionid] = {cmd = cmd, args = args,}
	local package = self.sproto_request(cmd, args, self.sessionid)
	self:send(string.pack(">s2", package))
	-- 统计
	monitor.time('test', cmd, self.sessionid)
end

return simGate
