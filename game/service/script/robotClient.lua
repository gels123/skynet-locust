--[[
	伪客户端
]]
local socket = require "client.socket"
local crypt = require "client.crypt"
local robotConf = require "robotConf"
local sproto = require "sproto"
local game_proto = require "game_proto"
local curl = require "luacurl"
local util = require "common.util"
local monitor = require "monitor"
local json = require "json"
local socket2 = require "skynet.socket"
local sc = require "skynet.socketchannel"
local robotClient = class("robotClient")

local instance = nil
function robotClient:ctor(user)
    self.device = user
    self.httpRet = nil
    self.channel = nil
    self.fd = nil
    self.sessionid = 0
	self.session = {}
    self.host = sproto.new(game_proto.s2c):host "package"
	self.sproto = sproto.new(game_proto.c2s)
    self.pack = self.host:attach(self.sproto)

	self.test =
	{
		reqplayercity = function()
			print("===reqplayercity=====")
			self:send_request("reqplayercity")
		end
	}
	self.fweight = {
		reqplayercity = 1,
	}
end

function robotClient:send_request(name, args)
    print("robotClient:send_request=", name, args)
	self.sessionid = self.sessionid + 1
	self.session[self.sessionid] = {name = name, args = args,}
	--
	local str = self.pack(name, args or {}, self.sessionid)
    local package = string.pack (">s2", str)
	--
	monitor.time('test', name, self.sessionid)
	--
	return self.channel:request(package, self.sessionid)
end

function robotClient:read_response(sock)
	local sz = socket2.header(sock:read(2))
	local data = sock:read(sz)
	local type, sessionid, msg = self.host:dispatch(data)
	print("robotClient:read_response", type, sessionid, transformTableToString(msg), "sz=", sz)
	if type == 'RESPONSE' then
		monitor.endtime(sessionid, sz)
		return sessionid, true, msg
	else
		--server notification
		local name = sessionid
		monitor.incr(name)
		return self:read_response(sock)
	end
end

function robotClient:login()
	-------------------------webserver-------------------------
	-- HTTP Get
	local c = curl.easy()
	c:setopt(curl.OPT_URL, string.format('http://%s/accountserver.php?device=%s', robotConf.httphost, self.device))
	c:setopt(curl.OPT_WRITEFUNCTION, function(userparam, t)
		self.httpRet = json.decode(t)
		print("===robotClient:login httpRet====", userparam, transformTableToString(self.httpRet))
	end)
	c:perform()
	c:close()

    -------------------------loginserver-------------------------
    local result
    local token = {
	    server = robotConf.serverid,
	    user = self.httpRet.account,
	    pass = "password",
    }
    local fd = assert(socket.connect(robotConf.serverip, self.httpRet.port))

    local function writeline(fd, text)
	    socket.send(fd, text .. "\n")
    end

    local function unpack_line(text)
	    local from = text:find("\n", 1, true)
	    if from then
		    return text:sub(1, from-1), text:sub(from+1)
	    end
	    return nil, text
    end

    local last = ""

    local function unpack_f(f)
	    local function try_recv(fd, last)
		    local result
		    result, last = f(last)
		    if result then
			    return result, last
		    end
		    local r = socket.recv(fd)
		    if not r then
			    return nil, last
		    end
		    if r == "" then
			    error "Server closed"
		    end
		    return f(last .. r)
	    end

	    return function()
		    while true do
			    local result
			    result, last = try_recv(fd, last)
			    if result then
				    return result
			    end
			    socket.usleep(100)
		    end
	    end
    end

    local readline = unpack_f(unpack_line)

    local challenge = crypt.base64decode(readline())

    local clientkey = crypt.randomkey()
    writeline(fd, crypt.base64encode(crypt.dhexchange(clientkey)))
    local secret = crypt.dhsecret(crypt.base64decode(readline()), clientkey)

    local hmac = crypt.hmac64(challenge, secret)
    writeline(fd, crypt.base64encode(hmac))

    local function encode_token(token)
	    return string.format("%s@%s:%s", crypt.base64encode(token.user), crypt.base64encode(token.server), crypt.base64encode(token.pass))
    end

    local etoken = crypt.desencode(secret, encode_token(token))
    local b = crypt.base64encode(etoken)
    writeline(fd, crypt.base64encode(etoken))

    result = readline()
    local code = tonumber(string.sub(result, 1, 3))
    assert(code == 200)
    socket.close(fd)

    local subid = crypt.base64decode(string.sub(result, 5))

    local _, gameip, gameport = string.match(subid, "(%w+)@(%g+):(%w+)")

    ----------------------------gameserver-------------------------------------------------
	self.channel = sc.channel({host = gameip, port = tonumber(gameport), nodelay = false, response = handler(self, self.read_response)})
	self.channel:connect(false)

    local version = 1
    local handshake = string.format("%s@%s#%s:%d", crypt.base64encode(token.user), crypt.base64encode(token.server),crypt.base64encode(subid) , version)
    local hmac = crypt.hmac64(crypt.hashkey(handshake), secret)

    local vtoken = handshake .. ":" .. crypt.base64encode(hmac)

	self:send_request("login", {token = vtoken, datetime = self.httpRet.datetime, sign = self.httpRet.sign,})
	self:send_request("createrole", {name = tostring(self.account), roleid=1001,})
	self:send_request("entergameok")

	print("robotClient:login success, device=", self.device)
end

function main(uid, host)
	print("robotClient main", uid, host)
	if not instance then
		local user = robotConf.template..tostring(uid)
		instance = robotClient.new(user)
		instance:login()
	end
	util.run(instance.test, instance.fweight,2,2)
end

return robotClient