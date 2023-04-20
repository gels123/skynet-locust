local giftproto = {}

giftproto.type = [[
.onlinegift {
    id 0 : integer              #宝箱id
    level 1 : integer           #刷新奖励时等级
    time 2 : integer            #上次领取时间戳
    isnew 3 : boolean           #是否取新手表
}
]]

giftproto.c2s = giftproto.type .. [[
# 4101~4200
reqgift 4101 {#请求礼包数据,玩家上线请求
    response {
        online 0 : onlinegift           #在线礼包数据
    }
}

onlinerew 4102 {#领取在线奖励
    response {
        code 0 : integer
        online 1 : onlinegift           #在线礼包数据
        thing 2 : *thingdata(cfgid)         #奖励物品
    }
}
]]

giftproto.s2c = giftproto.type .. [[
# 4101~4200
synconline 4151 {#同步在线礼包
    request {
        online 0 : onlinegift           #在线礼包数据
    }
}
]]

return giftproto