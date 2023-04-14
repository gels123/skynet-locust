require "quickframework.init"
require "svrFunc"
require "constValue"
require "sharedataLib"
local skynet = require "skynet"
local cluster = require "cluster"

local mode, instance = ...

if mode == "master" then
	local agents = {}
	local balance = 1
	local namedAgents = {}

	local CMD = {}

	-- 创建命名redis通道
	function CMD.createNamedChannel(channelName, conf)
		Log.dump(conf, "CMD.createNamedChannel" .. channelName)
	    local address = skynet.newservice(SERVICE_NAME, "sub")
	    skynet.call(address, "lua", "connect", conf)
	    namedAgents[channelName] = address
	    return address
	end

	-- 连接redis
	function CMD.connect(conf)
	    for i = 1, #agents do
      		skynet.call(agents[i], "lua", "connect", conf)
    	end
	end

	-- 断开redis
	function CMD.disconnect()
	    for i = 1, #agents do
			local ret = skynet.call(agents[i], "lua", "disconnect")
	    end
	end

	-- 测试redis连接
	function CMD.ping()
		local result = true
		for i = 1, #agents do
			local ret = skynet.call(agents[i], "lua", "ping")
			if ret ~= "PONG" then
				result = false
			end
	    end
	    return result
	end

	-- 重新连接redis
	function CMD.reconnect(conf)
		for i = 1, #agents do
			-- 断开旧连接
			skynet.send(agents[i], "lua", "disconnect")
			-- 杀掉旧服务
			skynet.kill(agents[i])
			-- 生成新服务
			agents[i] = skynet.newservice(SERVICE_NAME, "sub")
			-- 新服务连接
			skynet.call(agents[i], "lua", "connect", conf)
		end
		return true
	end

	skynet.start(function()
		-- 启动多个代理服务
		instance = math.max(2, math.ceil((instance or 8)/2.0) * 2)
    	for i = 1, instance do
      		agents[i] = skynet.newservice(SERVICE_NAME, "sub")
    	end

    	-- 消息分发
    	skynet.dispatch("lua", function(session, source, cmd, ...)
    		-- Log.d("redislt master cmd =", cmd, ...)
    		local f = CMD[cmd]
    		if f then
				skynet.ret(skynet.pack(f(...)))
    		else
    			local agent = agents[balance]
    			if balance >= instance then
    				balance = 1
    			else 
    				balance = balance + 1
    			end
    			-- Log.d("redislt master dispatch cmd to agent", cmd, agent)
    			if string.find(cmd, "send") then -- send指令
	      			skynet.send(agent, "lua", cmd, ...)
	      		else
	      			skynet.ret(skynet.pack(skynet.call(agent, "lua", cmd, ...)))
	      		end
    		end
    	end)
	end)

else
	local redisOpt = require "redisOpt"
	
  	skynet.start(function()
  		-- 消息分发
    	skynet.dispatch("lua", function(session, source, cmd, ...)
    		Log.d("redislt agent cmd =", cmd, ...)
    		local startTime = svrFunc.skynetTime()

    		local f = assert(redisOpt[cmd], string.format('redislt unknown redis operation: %s', cmd))
    		if string.find(cmd, "send") then -- send指令
    			f(...)
	    	else
        		skynet.ret(skynet.pack(f(...)))
	    	end

	    	local optTime = svrFunc.skynetTime() - startTime
			if optTime > 1 then
				Log.i("redislt opt timeout time=", optTime, cmd, ...)
			end
    	end)
  	end)

end

