--[[
    main函数
]]
local skynet = require("skynet")
local cluster = require("cluster")
local dbconf = require("dbconf")
local svrConf = require("svrConf")
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
    assert(dbconf.globalnodeid and dbconf.loginnodeid)
    Log.i("====== main start 2 =======")

    -- 配置数据DB服务
    local confDBSvr = skynet.newservice("mysqlService", "master", dbconf.mysql_confdb.instance)
    svrAddrMgr.setSvr(confDBSvr, svrAddrMgr.confDBSvr)
    skynet.call(confDBSvr, "lua", "connect", dbconf.mysql_confdb)
    Log.i("====== main start 3 =======")

    -- 游戏数据DB服务
    local gameDBSvr = skynet.newservice("mysqlService", "master", dbconf.mysql_gamedb.instance)
    svrAddrMgr.setSvr(gameDBSvr, svrAddrMgr.gameDBSvr)
    skynet.call(gameDBSvr, "lua", "connect", dbconf.mysql_gamedb)
    Log.i("====== main start 4 =======")

    -- 本地redis服务
    local redisSvr = skynet.newservice("redisService", "master", dbconf.redis.instance)
    svrAddrMgr.setSvr(redisSvr, svrAddrMgr.redisSvr)
    skynet.call(redisSvr, "lua", "connect", dbconf.redis)
    Log.i("====== main start 5 =======")

    -- 公共redis服务
    local redisSvr = skynet.newservice("redisService", "master", dbconf.publicRedis.instance)
    svrAddrMgr.setSvr(redisSvr, svrAddrMgr.publicRedisSvr)
    skynet.call(redisSvr, "lua", "connect", dbconf.publicRedis)
    Log.i("====== main start 6 =======")

    -- 加载服务器配置、刷库
    initDBConf:set()
    initDBConf:executeGlobalDataSql()
    Log.i("====== main start 7 =======")

	-- 调试控制台服务
	skynet.newservice("debug_console", svrConf:debugConfGlobal().port)
	Log.i("====== main start 8 =======")

    -- 集群配置
    cluster.open(svrConf:clusterConfGlobal().listennodename)
    Log.i("====== main start 9 =======")

    -- 启动服务
    skynet.newservice("serverStartService")
    Log.i("====== main start 10 =======")

    -- 数据中心服务
    local playerDataLib = require("playerDataLib")
    for i = 1, playerDataLib.serviceNum do
        skynet.newservice("playerDataService", dbconf.globalnodeid, i)
    end
    Log.i("====== main start 11 =======")

    -- 公共杂项服务
    local commonLib = require("commonLib")
    for i = 1, commonLib.serviceNum do
        skynet.newservice("commonService", dbconf.globalnodeid, i)
    end
    Log.i("====== main start 12 =======")

    -- 标记启动成功并生成文件
    if require("serverStartLib"):getIsOk() then
        Log.i("====== main start success locust =======")
        local file = io.open('./.startsuccess_locust', "w+")
        file:close()
    end
    -- 退出
    skynet.exit()
end)