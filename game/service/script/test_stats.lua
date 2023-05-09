local skynet = require "skynet"
local util = require "util"
local monitor = require "monitor"

local session = 0
local function get_session()
    session = session + 1
    return session
end

local tests = {}

function tests.test1()
    local s = get_session()
    monitor.time('test', 'test1', s)
    skynet.timeout(20, function()
        monitor.endtime(s, string.len("test1"))
    end)
end

function tests.test2()
    local s = get_session()
    monitor.time('test', 'test2', s)
    skynet.timeout(10, function()
        local failed = math.random(1,5) == 3
        monitor.endtime(s, string.len("test2"), failed)
    end)
end

local fweight = {
    test1 = 1,
    test2 = 2,
}

function main(uid, host)
    util.run(tests, fweight, 2, 2)
end