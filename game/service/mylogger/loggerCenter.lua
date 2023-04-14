--[[
	日志服务中心
]]
local skynet = require "skynet"
local dbconf = require "dbconf"
local lfs = require "lfs"
local loggerCenter = class("loggerCenter")

local mathfloor = math.floor
local tableinsert = table.insert
local osdate = os.date
local tableconcat = table.concat
local osclock = os.clock
local stringsub = string.sub
local iotype = io.type
local osrename = os.rename
local stringformat = string.format
local ESC = string.char(27, 91)

-- 获取单例
local instance = nil
function loggerCenter.shareInstance()
    if not instance then
        instance = loggerCenter.new()
    end
    return instance
end

-- 构造
function loggerCenter:ctor()
	-- 日志等级标识
	self.logLvStr = {
		[0] = " [DEBUG]",
		[1] = " [INFO]",
		[2] = " [WARN]",
		[3] = " [ERROR]",
		[4] = " [FATAL]",
	}

	-- 颜色,参考 https://github.com/kikito/ansicolors.lua/blob/master/ansicolors.lua ; https://github.com/randrews/color
	self.color = {
		reset = ESC .. "0m",
		clear = ESC .. "2J",
		bold = ESC .. "1m",
		faint = ESC .. "2m",
		normal = ESC .. "22",
		invert = ESC .. "7m",
		underline = ESC .. "4m",
		hide = ESC .. "?25l",
		show = ESC .. "?25h",

		--foreground colors
		black = ESC .. "30" .. "m",
		red = ESC .. "31" .. "m",
		green = ESC .. "32" .. "m",
		yellow = ESC .. "33" .. "m",
	}

	-- 初始化
	self:init()
end

-- 初始化
function loggerCenter:init()
    print("==== loggerCenter:init begin ====")
	-- 日志配置
	self.conf = dbconf.DEBUG and require("loggerConf").debug or require("loggerConf").release
    -- 今日零点的UTC时间
    self.today0clock = 0
    -- 文件写入长度
    self.infolen = 0
    local curDir = lfs.currentdir()
    self.writedir = curDir
    local exist = lfs.exist(self.conf.path)
   	if exist then
   		self.writedir = self.conf.path
    end
    print("self.writedir = ",self.writedir)
    if not self.conf.console then
	   	self:newFiles()
	else
		self.stdout = io.stdout
		-- 判断文件是否存在,存在的话,重新命名
		local debugfilename = "/.gameserver.nohup"
		local curnohupfile = tableconcat({curDir,debugfilename})
		local exist = lfs.exist(curnohupfile)
		if exist then
			local msec = stringsub(osclock(),3,6)
			local now = osdate("*t", mathfloor(skynet.time()) )
		    local curYear = now.year % 100
		    local suffix = stringformat("%d%02d%02d%s",curYear,now.month,now.day,msec)
			local newnohupfile = tableconcat({curDir,debugfilename,".",suffix})
			osrename(curnohupfile,newnohupfile)
			print("self.init rename= ",curnohupfile,newnohupfile)
		end
	end
	print("==== loggerCenter:init end ====")
end

-- 生成文件对象
function loggerCenter:newFiles()
    -- 生成两份文件,一份普通文件,一份错误日志文件
	local infoFilename = self:getNewFile(self.writedir,self.conf.filename)
    -- 打开文件
    print("new file success1 ",infoFilename)
    self.infoFile = io.open(infoFilename, "w")
    if not self.infoFile then
    	print("open failed=",infoFilename)
    else
    	-- 设置缓冲大小
    	self.infolen = 0
    	self.infoFile:setvbuf("full",8192)
    end
    print("new file success1 ",infoFilename)
end

-- 获取最大值
function loggerCenter:getNewFile(path, filename)
	local curTime = math.floor(skynet.time())
	local now = osdate("*t", curTime)
    local curYear = now.year % 100
    local nowfilename = stringformat("%s.%d-%d-%d.1",filename,curYear,now.month,now.day)
    local matchstr = filename .. ".(%d+)-(%d+)-(%d+).(%d+)"
	local maxIdx = 0
	for file in lfs.dir(path) do
		-- 检测年月日是否匹配
		local tmpyear,tmpmonth, tmpday,tmpIdx = string.match(file, matchstr)
	    if tmpyear and tonumber(tmpyear) == curYear and tmpmonth and tonumber(tmpmonth) == now.month and tmpday and tonumber(tmpday) == now.day and tmpIdx then
	    	tmpIdx = tonumber(tmpIdx)
	    	if maxIdx < tmpIdx then
	    		maxIdx = tmpIdx
	    	end
	    end
	end
	-- print("needRename == ",filename,", maxIdx=",maxIdx)
	maxIdx = maxIdx + 1
	local newfilename = stringformat("%s/%s.%d-%d-%d.%d",path,filename,curYear,now.month,now.day,maxIdx)
	-- print("new file max idx =",maxIdx,newfilename)
	-- 获取当前时间的时分秒
    self:takeToday0clock( curTime )

	return newfilename
end

-- 获得当前时间0点
function loggerCenter:takeToday0clock(curTime)
	local h = tonumber(osdate("%H", curTime))
    local m = tonumber(osdate("%M", curTime))
    local s = tonumber(osdate("%S", curTime))
    self.today0clock = curTime - ( h * 3600 + m * 60 + s )
    -- print("today  ===", self.today0clock)
end

-- 将缓存输出到文件
function loggerCenter:flush()
	if self.infoFile and iotype(self.infoFile) == "file" then
		self.infoFile:flush()
	end
end

-- 文件关闭
function loggerCenter:close()
	if self.infoFile and iotype(self.infoFile) == "file" then
		self.infoFile:close()
	end
end

-- 系统信号
function loggerCenter:sigup()
	if not self.conf.console then
		print(" loggerCenter:sigup ")
    	-- self.infoFile:close()
	    -- self:newFiles()
	end
end

-- 检测是否需要换新文件名字
function loggerCenter:checkNew(curTime)
	if (curTime > self.today0clock + 86400) or self.infolen > self.conf.maxsize then
		self:takeToday0clock( curTime )
		return true
	end
	return false
end

-----------------------------指令分发begin----------------------------------------
function loggerCenter:dispatch(session, address, cmd, level, tag, file, line, ...)
	local curTime = mathfloor(skynet.time())
	local timedata = osdate("%Y-%m-%d %H:%M:%S",curTime)
	local startIdx = 5
	local msgtab
	if level >= 2 and self.conf.console then --输出到控制台才标注颜色
		startIdx = 6
		msgtab = {self.color.red, timedata, " ", skynet.time(), self.logLvStr[level], tag, ... , "\n",self.color.reset}
	else
		msgtab = {timedata, " ", skynet.time(), self.logLvStr[level], tag, ... , "\n"}
	end
	-- print("level === ",level,",tag=", tag,",file=", file,",line=", line)
	if file then
		tableinsert(msgtab,startIdx+1,"[")
		tableinsert(msgtab,startIdx+2,file)
	end
	if line then
		tableinsert(msgtab,startIdx+3,":")
		tableinsert(msgtab,startIdx+4,line)
		tableinsert(msgtab,startIdx+5,"] ")
	end

	local msgstr = tableconcat(msgtab)
	if not self.conf.console and self.infoFile then
	    self.infoFile:write(msgstr)
	    if level >= 2 then --WARN后的马上刷到缓存
		    self.infoFile:flush()
		end
	    self.infolen = self.infolen + #msgstr
	    if self:checkNew(curTime) then
	    	self.infoFile:flush()
	    	self.infoFile:close()
	    	self:newFiles()
	    end
	else
		self.stdout:write(msgstr)
		self.stdout:flush()
	end
	-- 报错信息同步到企业微信or钉钉
	if string.find(msgstr, "stack traceback:") then
		require("alertLib"):alert(msgstr, address)
	end
end

-- 记录由skynet.error转发过来的日志
function loggerCenter:skyneterr(session, address, msg)
	local curTime = mathfloor(skynet.time())
	local timedata = osdate("%Y-%m-%d %H:%M:%S",curTime)
	local addrstr = stringformat(":%08x ",address)
	local msgtab = {timedata, " ", skynet.time(), " [SNERR] ", addrstr, msg, "\n"}
	local msgstr = tableconcat(msgtab)
	if not self.conf.console and self.infoFile then
	    self.infoFile:write(msgstr)
	    self.infoFile:flush()
	    self.infolen = self.infolen + #msgstr
	    if self:checkNew(curTime) then
	    	self.infoFile:close()
	    	self:newFiles()
	    end
	else
		self.stdout:write(msgstr)
	end
	-- 报错信息同步到企业微信or钉钉
	if string.find(msgstr, "stack traceback:") then
		require("alertLib"):alert(msgstr, address)
	end
end
-----------------------------指令分发end----------------------------------------

return loggerCenter
