--[[
    web路由
--]]
local skynet = require "skynet"
local codecache = require "skynet.codecache"
local template = require "resty.template"
local lfs = require "lfs"
local json = require "dkjson"
local dataset = require "dataset"
local webCenter = require("webCenter"):shareInstance()
local route = class("route")

local setting_file_path = "./setting.json"
local header = {['content-type'] = 'application/json;charset=utf-8'}
local STATE = {READY = 'ready', HATCHING = 'hatching', RUNNING = 'running', STOPPING = 'stopping', STOPPED = 'stopped'}
local script_path = 'game/service/script'
local static_path = "game/static"

local state = STATE.READY
local operation_ver = 0
local _config = nil

local function config(cfg)
    if cfg then -- set
        if not _config then
            _config = {}
        end
        table.merge(_config, cfg)
        local f = io.open(setting_file_path, 'wb')
        if f then
            f:write(json.encode(_config))
            f:close()
        end
    else -- get
        if not _config then
            local f = io.open(setting_file_path, 'rb')
            if f then
                _config = json.decode(f:read('*a'))
                f:close()
            end
            _config = {}
            _config.first_id = _config.first_id or 1
            _config.num_users = _config.num_users or 1
            _config.hatch_rate = _config.hatch_rate or 1
            _config.host = _config.host or '127.0.0.1:26000'
            _config.script = _config.script or ''
        end
    end
    return _config
end

route['/'] = function()
    local cfg = config()
    local scripts = {}
    local valid_script = false

    for file in lfs.dir(script_path) do
        if string.sub(file, -4) == '.lua' then
            table.insert(scripts,file)
            if not valid_script and cfg.script == file then 
                valid_script = true 
            end
        end
    end
    if not valid_script and #scripts > 0 then
        cfg.script = scripts[1]
    end

    local options = {
        state = state,
        first_id = cfg.first_id,
        user_count = webCenter:get_agent_count(),
        version = 1,
        num_users = cfg.num_users,
        hatch_rate = cfg.hatch_rate,
        host = cfg.host,
        wsport = webCenter:get_wsport(),
        scripts = scripts,
        script = cfg.script,
        static_path = static_path,
    }
    local html = template.compile(static_path .. '/index.html')(options)
    return 200, html
end

route['/swarm'] = function(body)
    operation_ver = operation_ver + 1
    local cfg = config({
        script = body.script,
        host = body.host,
        first_id = tonumber(body.first_id or 1) // 1,
        num_users = tonumber(body.user_count or 1) // 1,
        hatch_rate = tonumber(body.hatch_rate or 1) // 1
    })

    webCenter:stop_agent()
    dataset.reset()
    codecache.clear()

    local script = string.sub(cfg.script,1,-5) -- cut .lua
    skynet.fork(function()
        webCenter:run_agent(operation_ver, cfg.first_id, cfg.num_users, cfg.hatch_rate, cfg.host, script, function()
            state = STATE.RUNNING
        end)
    end)
    state = STATE.HATCHING
    local res = json.encode({success = true, script = cfg.script})
    return 200, res, header
end

route['/stop'] = function()
    skynet.fork(function()
        webCenter:stop_agent(function()
            state = STATE.STOPPED
        end)
    end)
    state = STATE.STOPPING
    return 200
end

route['/stats/reset'] = function()
    dataset.reset()
    return 200
end

route['/stats/requests/csv'] = function()
    return 200
end

route['/stats/failures/csv'] = function()
    return 200
end

route['/stats/requests'] = function()
    local report = dataset.report()
    report.state = state
    report.user_count = webCenter:get_agent_count()
    return 200, json.encode(report), header
end

route['/exceptions'] = function()
    local exceptions = {}
    return 200, json.encode({exceptions = exceptions}), header
end

route['/exceptions/csv'] = function()
    return 200
end

function route.hatching()
    return state == STATE.HATCHING
end

function route.old_operation(ver)
    return operation_ver ~= ver
end

return route