local skynet = require "skynet"
local snax = require "skynet.snax"

skynet.start(function()
    local web = snax.uniqueservice "web"

    local logger_addr = skynet.localname ".logger"
    skynet.call(logger_addr, 'lua', 'webservice', web.handle)

    skynet.exit()
end)