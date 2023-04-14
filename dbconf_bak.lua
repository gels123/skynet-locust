-- 服务器配置

local dbconf = {}

-- 游戏配置库配置
dbconf.mysql_confdb =
{
    host = "127.0.0.1",
    port = 3306,
    database = "game_conf",
    user = "root",
    password = "1",
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
    password = "1",
    max_packet_size = 1024 * 1024,
    instance = 16,
}

-- 本地redis配置
dbconf.redis =
{
    host="127.0.0.1",
    port=6379,
    db=0,
    auth="1",
    instance = 10,
}

-- 共享redis配置
dbconf.publicRedis =
{
    host="127.0.0.1",
    port=6379,
    db=0,
    auth="1",
    instance = 10,
}

-- 企业微信报错信息通知url
dbconf.wxRobotUrl = "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=9f7c5bc1-a6b8-443a-8c0e-af157ccc6844"

-- 是否开启调试
dbconf.DEBUG = true

-- 是否开启后台
dbconf.BACK_DOOR = true

-- 登陆节点id
dbconf.loginnodeid = 10001

-- 全局服节点id
dbconf.globalnodeid = 10002

return dbconf
