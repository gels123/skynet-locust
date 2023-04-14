-- 服务器配置

local dbconf = {}

-- 游戏配置库配置
dbconf.mysql_confdb =
{
    host = "127.0.0.1",
    port = 3306,
    database = "game_conf",
    user = "root",
    password = "Zeasn123_",
    max_packet_size = 1024 * 1024,
    instance = 4,
}

-- 游戏数据库配置
dbconf.mysql_gamedb =
{
    host = "127.0.0.1",
    port = 3306,
    database = "game_data",
    user = "root",
    password = "Zeasn123_",
    max_packet_size = 1024 * 1024,
    instance = 16,
}

-- 本地redis配置
dbconf.redis =
{
    host="127.0.0.1",
    port=6379,
    db=0,
    --auth="1",
    instance = 10,
}

-- 共享redis配置
dbconf.publicRedis =
{
    host="127.0.0.1",
    port=6379,
    db=0,
    --auth="1",
    instance = 10,
}

-- 钉钉/微信报错信息通知url
dbconf.robotTag = "gels-global"
--dbconf.robotUrl = "https://oapi.dingtalk.com/robot/send?access_token=9848749207a29936a54e559b77be02c9293f5c04e90c6601776fc87b6bd39663"

-- 是否开启调试
dbconf.DEBUG = true

-- 是否开启后台
dbconf.BACK_DOOR = true

-- 登陆节点id
dbconf.loginnodeid = 10001

-- 全局服节点id
dbconf.globalnodeid = 10002

-- 测试服dbconf重定向
if dbconf.DEBUG then
    local lfs = require("lfs")
    if tostring(...) == "dbconf" and lfs.exist(lfs.currentdir().."/dbconflocal.lua") then
        --print("dbconf.lua redict to dbconflocal.lua")
        return require("dbconflocal")
    end
end

return dbconf
