--[[
    玩家数据中心配置
--]]
local skynet = require "skynet"
local playerDataConfig = class("playerDataConfig")

-- redis数据类型
gRedisType = {
    player = "game-player-%s-%s",       -- 玩家数据类型, 一个玩家对应一个哈希表, 存放多条数据, %s王国ID-%s玩家ID
    alliance = "game-alliance-%s-%s",   -- 联盟数据类型, 一个联盟对应一个哈希表, 存放多条数据, %s王国ID-%s联盟ID
    kingdom = "game-kingdom-%s-%s",     -- 王国数据类型, 一个王国对应一个哈希表, 存放多条数据, %s王国ID-%s王国ID
    mail = "game-mail-%s-%s",           -- 邮件数据类型, 一个王国对应一个哈希表, 存放多条数据, %s王国ID-%s王国ID
    common = "game-%s-%s-%s",           -- 通常数据类型, 一条数据对应一个键值, %s数据名-%s王国ID-%s数据ID, 该类型通常只存redis不存mysql, redis数据不会被清理
}

-- mysql数据类型
gMysqlType = {
    sql = 0,    -- 关系型数据库表, 会有多个字段
    nosql = 1,  -- 非关系型数据库表, 一般只有"id"和"data"两个字段, 尽量使用本类型, mysql闪断时, 会有更好的异常处理
}

--[[
    模块配置
    @table [必填]数据表名
    @columns [必填(落地mysql)/不填]mysql: 数据字段名
    @keyColumns [必填(落地mysql)/不填]mysql: 主键数据字段名
    @dataColumns [必填(落地mysql)/不填]mysql: {"data"}查询/更新时处理的字段, 有配置则查询/更新将处理这些字段, 非关系型数据库表一般"data"字段放第1位
    @redisType [必填]本地redis数据类型, 参见gRedisType
    @mysqlType [必填]mysql数据类型, 参见gMysqlType
    @queryResultCallback [选填]自定义返回数据处理方法，不配置使用默认处理方法
]]
playerDataConfig.moduleSettings = {
    -- 聊天信息, 存到王国哈希表, 且落库
    ["chatinfo"] = {
        ["table"] = "chatinfo",
        ["columns"] = {"id", "data"},
        ["keyColumns"] = {"id"},
        ["dataColumns"] = {"data"},
        ["redisType"] = gRedisType.kingdom,
        ["mysqlType"] = gMysqlType.nosql,
    },
    -- 交易信息, 存到王国哈希表, 且落库
    ["tradeinfo"] = {
        ["table"] = "tradeinfo",
        ["columns"] = {"id", "data"},
        ["keyColumns"] = {"id"},
        ["dataColumns"] = {"data"},
        ["redisType"] = gRedisType.kingdom,
        ["mysqlType"] = gMysqlType.nosql,
    },
    -- 全局掉落信息, 存到王国哈希表, 且落库
    ["droplimitinfo"] = {
        ["table"] = "droplimitinfo",
        ["columns"] = {"id", "data"},
        ["keyColumns"] = {"id"},
        ["dataColumns"] = {"data"},
        ["redisType"] = gRedisType.kingdom,
        ["mysqlType"] = gMysqlType.nosql,
    },
}

-- 获取本地redis数据类型
function playerDataConfig:getRedisType(module)
    return playerDataConfig.moduleSettings[module] and playerDataConfig.moduleSettings[module].redisType
end

-- 获取本地mysql数据类型
function playerDataConfig:getMysqlType(module)
    return playerDataConfig.moduleSettings[module] and playerDataConfig.moduleSettings[module].mysqlType
end

-- 校验配置
function playerDataConfig:check()
    for module,v in pairs(playerDataConfig.moduleSettings) do
        assert(v.table, string.format("playerDataConfig:check error1: module=%s", module))
        assert(((v.columns and next(v.columns) and v.keyColumns and next(v.keyColumns) and v.dataColumns and next(v.dataColumns)) or (not v.columns and not v.keyColumns and not v.dataColumns)), string.format("playerDataConfig:check error2: module=%s", module))
        assert(v.redisType, string.format("playerDataConfig:check error3: module=%s", module))
        assert((v.mysqlType and v.columns and v.keyColumns and v.dataColumns) or (not v.columns and not v.keyColumns and not v.dataColumns), string.format("playerDataConfig:check error4: module=%s", module))
    end
    -- Log.dump(playerDataConfig.moduleSettings, "playerDataConfig:check ok=", 10)
end

playerDataConfig:check()

return playerDataConfig