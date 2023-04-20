local protos = {}

local types = require "prototype"
local thingproto = require "thingproto"
local tokenproto = require "tokenproto"
local systemproto = require "systemproto"
local playerproto = require "playerproto"
local shopproto = require "shopproto"
local chatproto = require "chatproto"
local mailproto = require "mailproto"
local commonproto = require "commonproto"
local chargeproto = require "chargeproto"
local cityproto = require "cityproto"
local taskproto = require "taskproto"
local heroproto = require "heroproto"
local guildproto = require "guildproto"
local cacheproto = require "cacheproto"
local ranklistproto = require "ranklistproto"
local worldproto = require "worldproto"
local mapproto = require "mapproto"
local armyproto = require "armyproto"
local giftproto = require "giftproto"
local battleproto = require "battleproto"
local queueproto = require "queueproto"
local pinballproto = require "pinballproto"
local logproto = require "logproto"
local activityproto = require "activityproto"
local battlecarproto = require "battlecarproto"
local arenaproto = require "arenaproto"
local gatebattleproto = require "gatebattleproto"
local xtwoproto = require "xtwoproto"

protos.types = types
protos.c2s = types 
    .. systemproto.c2s
    .. thingproto.c2s 
    .. tokenproto.c2s 
    .. chatproto.c2s
    .. mailproto.c2s
    .. chargeproto.c2s
    .. playerproto.c2s
    .. cityproto.c2s
    .. taskproto.c2s
    .. heroproto.c2s
    .. guildproto.c2s
    .. cacheproto.c2s
    .. shopproto.c2s
    .. ranklistproto.c2s
    .. worldproto.c2s
    .. mapproto.c2s
    .. armyproto.c2s
    .. giftproto.c2s
    .. battleproto.c2s
    .. queueproto.c2s
    .. pinballproto.c2s
    .. logproto.c2s
    .. activityproto.c2s
    .. arenaproto.c2s
    .. gatebattleproto.c2s
    .. xtwoproto.c2s
    .. battlecarproto.c2s

protos.s2c = types
    .. systemproto.s2c
    .. thingproto.s2c 
    .. tokenproto.s2c 
    .. playerproto.s2c
    .. chatproto.s2c
    .. mailproto.s2c
    .. chargeproto.s2c
    .. cityproto.s2c
    .. taskproto.s2c
    .. heroproto.s2c
    .. guildproto.s2c
    .. cacheproto.s2c
    .. shopproto.s2c
    .. ranklistproto.s2c
    .. worldproto.s2c
    .. mapproto.s2c
    .. queueproto.s2c
    .. pinballproto.s2c
    .. armyproto.s2c
    .. giftproto.s2c
    .. battleproto.s2c
    .. logproto.s2c
    .. activityproto.s2c
    .. arenaproto.s2c
    .. gatebattleproto.s2c
    .. xtwoproto.s2c
    .. battlecarproto.s2c

return protos
