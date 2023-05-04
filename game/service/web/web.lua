local skynet = require "skynet"
local runner = require "runner"
local dataset = require "dataset"
local skynetqueue = require "skynet.queue"

local sq_counter
local sq_stats

function init()
    sq_counter = skynetqueue()
    sq_stats = skynetqueue()
    local conf = require("initDBConf"):getClusterConf(dbconf.nodeid)
    runner.start(conf.porthttp, conf.portwebsock)
end

function accept.broadcast(type, body)
    runner.broadcast(type, body)
end

function response.stats_service(method, name)
    local addr
    sq_stats(function()
    addr = dataset.stats_service(method, name)
    end)
    return addr
end

function response.counter_service(name)
    local addr
    sq_counter(function()
    addr = dataset.counter_service(name)
    end)
    return addr
end

function accept.report_stats(...)
    dataset.report_stats(...)
end

function accept.report_counter(...)
    dataset.report_counter(...)
end
