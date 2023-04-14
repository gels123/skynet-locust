--[[
	mysql数据库服务
	Created by Gels on 2021/8/26.
]]
require "quickframework.init"
require "svrFunc"
require "constDef"
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
		assert(conf, "mysqlService connect error: no conf!")
	    for i=1, #agents do
      		skynet.call(agents[i], "lua", "connect", conf)
    	end
    	Log.dump(agents, "mysqlService connect end=", 10)
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
		assert(conf, "mysqlService connect error: no conf!")
		Log.dump(agents, "mysqlService reconnect 1", 10)
		for i=1, #agents do
			--断开旧连接
			skynet.call(agents[i], "lua", "disconnect")
			--杀死旧服务
			skynet.send(agents[i], "lua", "kill")
			--生成新服务
			agents[i] = skynet.newservice(SERVICE_NAME, "sub", i)
			--新服务连接
			skynet.call(agents[i], "lua", "connect", conf)
	    end
	    Log.dump(agents, "mysqlService reconnect end=", 10)
	    return true
	end

	skynet.start(function()
		-- 启动多个代理服务
		instance = math.max(2, math.ceil((instance or 8)/2.0) * 2)
    	for i=1, instance do
      		agents[i] = skynet.newservice(SERVICE_NAME, "sub", i)
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
    			-- Log.d("mysqlService master dispatch cmd to agent", cmd, agent)
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
		assert(conf, "mysqlService connect error: no conf!")
	    db = mysql.connect(conf)
	    if db then
	    	db:query("set names utf8mb4")
	    	Log.i("mysqlService connect mysql success, dbname=", conf.database, instance)
	    	return true
	    else
	    	Log.e("mysqlService connect mysql failed, dbname=", conf.database, instance)
	    	return false
	    end
	end

	-- 断开连接数据库
	function CMD.disconnect()
	    if db then
	      	db:disconnect()
	      	Log.i("mysqlService disconnect mysql success", instance)
	      	return true
	    else
	    	Log.e("mysqlService disconnect mysql failed", instance)
	    	return false
	    end
	end

	-- 杀死服务
	function CMD.kill()
		Log.i("mysqlService kill", instance)
		skynet.exit()
	end

	-- 执行sql语句
	-- 报错示例1: 查询错误=>ret={badresult = true, err = "Table 'gels_gamedata.sdfasdf' doesn't exist", errno = 1146, sqlstate = "42S02"} 
	-- 报错示例2: Mysql服务器宕机=>无ret,报错Connect to 127.0.0.1:3306 failed (Connection refused)
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

