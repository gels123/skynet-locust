--[[
	mysql数据库服务
]]
require "quickframework.init"
require "svrFunc"
require "constValue"
require "sharedataLib"
local skynet = require("skynet")
local cluster = require("skynet.cluster")
local mysql = require("skynet.db.mysql")

local mode, instance = ...

if mode == "master" then
	local agents = {}
	local balance = 1

	local CMD = {}

	--连接mysql数据库
	function CMD.connect(conf)
	    for i=1, #agents do
      		skynet.call(agents[i], "lua", "connect", conf)
    	end
	end

	--断开数据库连接
	function CMD.disconnect()
	    for i=1, #agents do
			local ret = skynet.call(agents[i], "lua", "disconnect")
	    end
	end

	--测试数据库连接
	function CMD.testconnect()
		local sql = "select 1"
		for i=1, #agents do
			local ret = skynet.call(agents[i], "lua", "execute", sql)
	    end
	    return true
	end

	--重连数据库连接
	function CMD.reconnect(conf)
		Log.dump(agents, "mysqllt reconnect 1", 10)
		for i=1, #agents do
			--断开旧连接
			skynet.send(agents[i], "lua", "disconnect")
			--杀掉旧服务
			skynet.kill(agents[i])
			--生成新服务
			agents[i] = skynet.newservice(SERVICE_NAME, "sub")
			--新服务连接
			skynet.call(agents[i], "lua", "connect", conf)
	    end
	    Log.dump(agents, "mysqllt reconnect 2", 10)
	    return true
	end

	skynet.start(function()
		-- 启动多个代理服务
		instance = math.max(2, math.ceil((instance or 8)/2.0) * 2)
    	for i=1, instance do
      		agents[i] = skynet.newservice(SERVICE_NAME, "sub")
    	end

    	-- 消息分发
    	skynet.dispatch("lua", function(session, source, cmd, ...)
    		local f = CMD[cmd]
    		if f then
				skynet.ret(skynet.pack(f(...)))
    		else
      			local agent = agents[balance]
    			if balance >= #agents then
    				balance = 1
    			else 
    				balance = balance + 1
    			end
    			-- Log.d("mysqllt master dispatch cmd to agent", cmd, agent)
		      	if string.find(cmd, "send") then -- send指令
	      			skynet.send(agent, "lua", cmd, ...)
	      		else
	      			skynet.ret(skynet.pack(skynet.call(agent, "lua", cmd, ...)))
	      		end
    		end
    	end)
	end)

elseif mode == "sub" then
	local db = nil

	local CMD = {}

	-- 连接数据库
	function CMD.connect(conf)
	    db = mysql.connect(conf)
	    if db then
	    	db:query("set names utf8mb4")
	    	Log.i("mysqllt connect mysql success, dbname=", conf.database)
	    	return true
	    else
	    	Log.i("mysqllt connect mysql failed, dbname=", conf.database)
	    	return false
	    end
	end

	-- 断开连接数据库
	function CMD.disconnect()
	    if db then
	      	db:disconnect()
	      	Log.i("mysqllt disconnect mysql success, dbname=", conf.database)
	      	return true
	    else
	    	Log.i("mysqllt disconnect mysql failed, dbname=", conf.database)
	    	return false
	    end
	end

	-- 执行sql语句
	function CMD.execute(sql)
	    Log.i("mysql execute sql=", sql)
	    local ret = nil
	    if db then
	    	local startTime = svrFunc.skynetTime()

			ret = db:query(sql)

			local optTime = svrFunc.skynetTime() - startTime
			if optTime > 1 then
				Log.i("mysql execute timeout time=, sql=", optTime, sql)
			end
		else
			Log.i("[SQL ERROR] not connected, sql=", sql)
	    end
	    return ret
	end

	-- 执行sql语句
	function CMD.sendExecute(sql)
		Log.i("mysql sendExecute sql=", sql)
	    if db then
	    	local startTime = svrFunc.skynetTime()

			local ret = db:query(sql)
			if not ret then
				Log.i("[SQL ERROR] no ret sql=", sql)
			elseif ret.badresult or ret.err then
				Log.i("[SQL ERROR] badresult err=", ret.err, "sql=", sql)
				-- 如果为批量提交语句，需要重新执行一次commit，防止事务挂起
				if string.find(sql, "transaction") then
					db:query("commit;")
				end
	        elseif ret.mulitresultset then
	        	-- 多条执行的sql语句错误返回值需要特殊处理
	        	for i,retCell in pairs(ret) do
	        		if "table" == type(retCell) and i~=1 and i~=#ret and (not retCell.affected_rows or retCell.affected_rows ~= 1) then
	        			ret.sql = sql
	        			Log.dump(ret, "[SQL ERROR] mulit affected_rows error", 10)
	        			break
	        		end
	        	end
	        end

			local optTime = svrFunc.skynetTime() - startTime
			if optTime > 1 then
				Log.i("mysql sendExecute timeout time=, sql=", optTime, sql)
			end
	    end
	end

  	skynet.start(function()
  		-- 消息分发
    	skynet.dispatch("lua", function(session, source, cmd, ...)
        	local f = assert(CMD[cmd], string.format('mysql unknown operation: %s', cmd))
        	if string.find(cmd, "send") then -- send指令
        		f(...)
        	else
        		skynet.ret(skynet.pack(f(...)))
        	end
    	end)
  	end)

end

