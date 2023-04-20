local gmcommand = {
    name = "gmcommand",
    param = "/fulltoken 10000",
}

local robotConf = {
    serverid = 90, --连接的服务器id
    template = "robot_gels_", --机器人的前缀名称
    begin = 0, --机器人尾缀从多少开始
    num = 100, --开启的数量
    ai = {},
    debuginfo = true,  --是否输出printf打印
    daemon = false,--后台开启
    httphost = "192.168.88.5:8002",
    serverip = "192.168.88.5",
}
local aiset = {}
local function loadai(ai)
    aiset[ai.name] = ai.param
end

do--加载ai
    loadai(gmcommand)
end

--获取ai
function robotConf.getai(name)
    return aiset[name]
end

return robotConf
