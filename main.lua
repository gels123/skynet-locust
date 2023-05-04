--[[
    main函数
]]
local skynet = require("skynet")
local snax = require("skynet.snax")
local cluster = require("cluster")
local dbconf = require("dbconf")
local initDBConf = require("initDBConf")
local svrAddrMgr = require("svrAddrMgr")
local sharedataLib = require("sharedataLib")

skynet.start(function ()
    print("====== main start begin =======")
    Log.i("====== main start begin =======")
    -- 设置统一的随机种子
    math.randomseed(os.time())
    Log.i("====== main start 0 =======")

    -- 报错信息推送服务
    skynet.newservice("alertService")
    Log.i("====== main start 1 =======")

    -- 检查节点配置
    assert(dbconf.nodeid)
    Log.i("====== main start 2 =======")

    -- 配置数据DB服务
    local dbSvr = skynet.newservice("mysqlService", "master", dbconf.mysql_db.instance)
    svrAddrMgr.setSvr(dbSvr, svrAddrMgr.dbSvr)
    skynet.call(dbSvr, "lua", "connect", dbconf.mysql_db)
    Log.i("====== main start 3 =======")

    -- 本地redis服务
    local redisSvr = skynet.newservice("redisService", "master", dbconf.redis.instance)
    svrAddrMgr.setSvr(redisSvr, svrAddrMgr.redisSvr)
    skynet.call(redisSvr, "lua", "connect", dbconf.redis)
    Log.i("====== main start 4 =======")

    -- 加载服务器配置、刷库
    initDBConf:executeDbSql()
    initDBConf:set()
    Log.i("====== main start 5 =======")

	-- 调试控制台服务
	skynet.newservice("debug_console", initDBConf:getClusterConf(dbconf.nodeid).portdebug)
	Log.i("====== main start 6 =======")

    -- 集群配置
    cluster.open(initDBConf:getClusterConf(dbconf.nodeid).listennodename)
    Log.i("====== main start 7 =======")

    -- 启动服务
    skynet.newservice("serverStartService")
    Log.i("====== main start 8 =======")

    -- 协议共享服务
    skynet.newservice("protoService")
    Log.i("====== main start 9 =======")

    -- 数据中心服务
    --local playerDataLib = require("playerDataLib")
    --for i = 1, playerDataLib.serviceNum do
    --    skynet.newservice("playerDataService", dbconf.globalnodeid, i)
    --end
    Log.i("====== main start 10 =======")

    local web = snax.uniqueservice("web")
    Log.i("====== main start 13 =======")

    --local logger_addr = skynet.localname ".logger"
    --skynet.call(logger_addr, 'lua', 'webservice', web.handle)

    -- 标记启动成功并生成文件
    if require("serverStartLib"):getIsOk() then
        Log.i("====== main start success locust =======")
        local file = io.open('./.startsuccess_locust', "w+")
        file:close()
    end
    -- 退出
    skynet.exit()
end)