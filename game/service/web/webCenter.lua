--[[
    web服务中心
]]
local skynet = require "skynet.manager"
local dbconf = require "dbconf"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local websocket = require "http.websocket"
local urllib = require "http.url"
local json = require "dkjson"
local dataset = require "dataset"
local serviceCenterBase = require("serviceCenterBase2")
local webCenter = class("webCenter", serviceCenterBase)


function webCenter:ctor()
    webCenter.super.ctor(self)

    -- 不返回数据的指令集
    self.sendCmd["xxx"] = true
end

-- 初始化
function webCenter:init()
    Log.i("webCenter:init begin=")
    webCenter.super.init(self)

    self.sq_counter = self:getSq("counter")
    self.sq_stats = self:getSq("stats")

    self.port = nil
    self.wsport = nil
    self.route = nil
    self.agents = {}
    self.agent_count = 0
    self.ws_socks = {}
    self:start()

    Log.i("webCenter:init end=")
    return true
end

-- 启动web
function webCenter:start()
    local conf = require("initDBConf"):getClusterConf(dbconf.nodeid)
    self.port, self.wsport = conf.porthttp, conf.portwebsock

    local sock = socket.listen("0.0.0.0", self.port)
    socket.start(sock, function(fd, addr)
        self:do_http_request(fd, addr)
    end)
    skynet.error("webCenter:start http server address: http://127.0.0.1:"..self.port)

    local wsock = socket.listen("0.0.0.0", self.wsport)
    socket.start(wsock, function(fd, addr)
        local handle = {}

        function handle.connect(fd)
            self.ws_socks[fd] = fd
        end

        function handle.close(fd, code, reason)
            self.ws_socks[fd] = nil
        end

        function handle.error(fd)
            self.ws_socks[fd] = nil
        end

        local ok, err = websocket.accept(fd, handle, 'ws', addr)
        if not ok then
            skynet.error(err)
        end
    end)
end

function webCenter:do_http_request(fd, addr)
    socket.start(fd)
    local read = sockethelper.readfunc(fd)
    local write = sockethelper.writefunc(fd)
    local code, url, method, header, body = httpd.read_request(read, 8192)
    if not code then
        return socket.close(fd)
    end
    if code ~= 200 then
        self:http_response(fd, write, code)
    else
        local path, query = urllib.parse(url)
        if path == '/index.html' then
            path = '/'
        end
        if not self.route then
            self.route = require "route"
        end
        local f = self.route[path]
        if f then
            self:http_response(fd, write, f(urllib.parse_query(body)))
        else
            local data
            path = '.' .. path
            local f = io.open(path, 'rb')
            if f then
                data = f:read('*a')
                f:close()
            else
                code = 404
            end
            local header
            if string.sub(path,-4) == '.css' then
                header = {['Content-Type']='text/css;charset=utf-8'}
            end
            self:http_response(fd, write, code, data, header)
        end
    end
    socket.close(fd)
end

function webCenter:http_response(id, write, ...)
    local ok, err = httpd.write_response(write, ...)
    if not ok then
        skynet.error(string.format("fd = %d, %s", id, err))
    end
end

function webCenter:broadcast(type, body)
    local msg = json.encode({type = type, body = body})
    for _, sock in pairs(self.ws_socks) do
        websocket.write(sock, msg)
    end
end

function webCenter:stats_service(method, name)
    local addr
    self.sq_stats(function()
        addr = dataset.stats_service(method, name)
    end)
    return addr
end

function webCenter:counter_service(name)
    local addr
    self.sq_counter(function()
        addr = dataset.counter_service(name)
    end)
    return addr
end

function webCenter:report_stats(...)
    dataset.report_stats(...)
end

function webCenter:report_counter(...)
    dataset.report_counter(...)
end

function webCenter:get_agent_count()
    return self.agent_count
end

function webCenter:get_wsport()
    return self.wsport
end

function webCenter:stop_agent(cb)
    for id, agent in pairs(self.agents) do
        skynet.send(agent, "lua", "exit")
        skynet.kill(agent)
        skynet.error('agent:', id, 'exit!')
    end
    self.agents = {}
    self.agent_count = 0
    if cb then
        cb()
    end
end

function webCenter:run_agent(ver, id_start, id_count, per_sec, host, script, cb)
    Log.i("webCenter:run_agent ver=", ver, "id_start=", id_start, "id_count=", id_count, "per_sec=", per_sec, "host=", host, "script=", script, "cb=", cb)
    if not self.route or not self.route.hatching() then -- stopped
        Log.w("webCenter:run_agent failed ver=", ver, "id_start=", id_start, "id_count=", id_count, "per_sec=", per_sec, "host=", host, "script=", script, "cb=", cb)
        return
    end
    if not self.route or self.route.old_operation(ver) then -- expire operation
        Log.w("webCenter:run_agent failed ver=", ver, "id_start=", id_start, "id_count=", id_count, "per_sec=", per_sec, "host=", host, "script=", script, "cb=", cb)
        return
    end

    local swarm_num = per_sec
    if self.agent_count + swarm_num > id_count then
        swarm_num = id_count - self.agent_count
    end

    local id = id_start
    for i = 1, swarm_num do
        self.agents[id] = skynet.newservice("agent", script, host, id)
        self.agent_count = self.agent_count + 1
        id = id + 1
    end

    if self.agent_count >= id_count then
        return cb()
    else
        skynet.timeout(100, function()
            webCenter:run_agent(ver, id, id_count, per_sec, host, script, cb)
        end)
    end
end

return webCenter
