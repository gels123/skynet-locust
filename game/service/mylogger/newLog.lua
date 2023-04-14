--[[
    日志
        需要在 gamestartconf 中自定义
        logger = "myloggers"
        logservice = "snlua"
]]
local skynet = require "skynet"
local svrAddrMgr = require "svrAddrMgr"
local tableinsert = table.insert
local tableconcat = table.concat
local tablepack = table.pack
local localtostring = tostring
local newLog = {}
local lServiceName = gServiceName

newLog.defaultLogTag = function () -- 定制log tag
	-- local concatLog = {"[svc",skynet.address(skynet.self()), " ", lServiceName}
    local concatLog = {" ",skynet.address(skynet.self()), " ", lServiceName}
    -- 加王国前缀
    -- if not newLog.kid then newLog.kid = gKingdomID end
    -- if newLog.kid then
    --     tableinsert(concatLog," kid:")
    --     tableinsert(concatLog,newLog.kid)
    -- end
    -- 加玩家ID前缀
    if not newLog.uid then newLog.uid = gUid end
    if newLog.uid then
        tableinsert(concatLog," uid:")
        tableinsert(concatLog,newLog.uid)
    end
    -- tableinsert(concatLog,"]")
    tableinsert(concatLog," ")
    return tableconcat(concatLog)
end

-- 是否打印一些文件信息
if dbconf.DEBUG then
   newLog.logFileInfo = true
   newLog.debug = true
end

newLog.getInfo = function ( )
	local di = debug.getinfo(3, 'Sl')
    -- 只返回文件名,行数
    return string.match(di.source,"%a+.lua"), di.currentline
end

newLog.concat = function ( ... )
    local ret = {}
    local data = tablepack(...)
    for i = 1, data.n do
        local v = data[i]
        local tmpType = type(v)
        if tmpType ~= "number" or tmpType ~= "string" then
            tableinsert(ret, localtostring(v))
        else
            tableinsert(ret, v)
        end 
    end
    return tableconcat(ret," ")
end

newLog.d = function ( ... )
    if not newLog.debug then
        return
    end
	local file, line
	if newLog.logFileInfo then
		file, line = newLog.getInfo()
	end
    if not newLog.loggerAddr then
        newLog.loggerAddr = svrAddrMgr.getSvr(svrAddrMgr.newLoggerSvr)
    end
    local tag = newLog.defaultLogTag()
	skynet.send(newLog.loggerAddr, skynet.PTYPE_LUA, "log", 0, tag, file, line, newLog.concat( ... ) )
end

newLog.i = function ( ... )
    local file, line
	if newLog.logFileInfo then
		file, line = newLog.getInfo()
	end
    if not newLog.loggerAddr then
        newLog.loggerAddr = svrAddrMgr.getSvr(svrAddrMgr.newLoggerSvr)
    end
    local tag = newLog.defaultLogTag()
    skynet.send(newLog.loggerAddr, skynet.PTYPE_LUA, "log", 1, tag, file, line, newLog.concat( ... ) )
end

newLog.w = function ( ... )
    local file, line
    if newLog.logFileInfo then
        file, line = newLog.getInfo()
    end
    if not newLog.loggerAddr then
        newLog.loggerAddr = svrAddrMgr.getSvr(svrAddrMgr.newLoggerSvr)
    end
    local tag = newLog.defaultLogTag()
    skynet.send(newLog.loggerAddr, skynet.PTYPE_LUA, "log", 2, tag, file, line, newLog.concat( ... ) )
end

newLog.e = function ( ... )
    local file, line
	if newLog.logFileInfo then
		file, line = newLog.getInfo()
	end
    if not newLog.loggerAddr then
        newLog.loggerAddr = svrAddrMgr.getSvr(svrAddrMgr.newLoggerSvr)
    end
    local tag = newLog.defaultLogTag()
    local logMsg = newLog.concat( ... )
    local logMsgAppendedTb = debug.traceback(logMsg, 3)
    skynet.send(newLog.loggerAddr, skynet.PTYPE_LUA, "log", 3, tag, file, line, logMsgAppendedTb )
end

newLog.dump = function (tbl, desc, nesting, logLevel)
    if not newLog.debug then
        return
    end

    local file, line
	if newLog.logFileInfo then
		file, line = newLog.getInfo()
	end

    if type(logLevel) ~= 'number' then
        logLevel = 1
    end

    if not newLog.loggerAddr then
        newLog.loggerAddr = svrAddrMgr.getSvr(svrAddrMgr.newLoggerSvr)
    end
    local tag = newLog.defaultLogTag()
    skynet.send(newLog.loggerAddr, skynet.PTYPE_LUA, "log", 1, tag, file, line, transformTableToString(tbl, desc, nesting))
end

return newLog