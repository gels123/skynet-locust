local skynet = require("skynet")
local loggerConf = {}

if skynet.getenv "daemon" then
    -- debug配置
    loggerConf.debug =
    {
        console = false,
        level = 0, -- DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3, FATAL = 4
        filename = "global_debug",
        path = "./log",
        maxsize = 1024000000,
    }

    -- release配置
    loggerConf.release =
    {
        console = false,
        level = 1, -- DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3, FATAL = 4
        filename = "global_release",
        path = "./log",
        maxsize = 1024000000,
    }
else
    -- debug配置
    loggerConf.debug =
    {
        console = true,
        level = 0, -- DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3, FATAL = 4
        filename = "global_debug",
        path = "./log",
        maxsize = 1024000000,
    }

    -- release配置
    loggerConf.release =
    {
        console = true,
        level = 1, -- DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3, FATAL = 4
        filename = "global_release",
        path = "./log",
        maxsize = 1024000000,
    }
end

return loggerConf
