local thingproto = {}

thingproto.type = [[
.useitem {
    cfgid 0 : integer       #配置id
    num 1 : integer         #数量
}
]]

thingproto.c2s = thingproto.type .. [[
#物品 101 ～ 200
reqthings 101 {#请求所有物品数据
    response {
        info 0 : *thingdata
        newitem 1 : *integer        #新获得的物品类型
        dailyuse 2 : *useitem       #今日使用次数上限的道具
        vitalitytimes 3 : integer   #活力道具购买次数
    }
}

userewarditem 102 {#使用资源类道具
    request {
        cfgid 0 : integer   #配置id
        num 1 : integer     #数量
        auto 2 : boolean    #数量不够自动消耗元宝补足
    }
    response {
        code 0 : integer    #返回码
        token 1 : tokendata #获取的代币数据
        auto 2 : boolean    #数量不够自动消耗元宝补足
    }
}

usegiftitem 103 {#使用礼包类道具
    request {
        cfgid 0 : integer   #配置id
        num 1 : integer     #数量
    }
    response {
        code 0 : integer    #返回码
        info 1 : *thingdata #获取的物品数据
    }
}

viewthing 104 {#查看物品
    request {
        id 0 : *integer     #物品id
    }
    response {
        code 0 : integer    #返回码
    }
}

useselectitem 105 {#使用N选1道具
    request {
        id 0 : integer          #使用礼包id
        num 1 : integer         #使用礼包数量
        rewardid 2 : integer    #获得物品id
    }
    response {
        code 0 : integer    #返回码
        rewardid 1 : integer      #物品id
        rewardnum 2 : integer     #物品数量
    }
}

syntheticitem 106 {#合成道具
    request {
        id 0 : integer           #合成配置表的ID
        num 1 : integer          #合成的道具数量
    }
    response {
        code 0 : integer    #返回码
        passreward 1 : rewardlib    #奖励内容
    }
}

usemistitem 107 {#使用解锁迷雾道具
    request {
        id 0 : integer          #id
        num 1 : integer         #数量=1
        auto 2 : integer        #自动购买=1
        x 3 : integer           #x
        y 4 : integer           #y
    }
    response {
        code 0 : integer        #返回码
    }
}
]]


thingproto.s2c = thingproto.type .. [[
#物品 101 ～ 200
updatethings 151 {#更新物品 物品数量为0时删除物品
    request {
        info 0 : *thingdata
    }
}

.rewardmsg {
    systemmsg 0 : string        #系统消息tid
    itemid 1 : integer          #道具id
    num 2 : integer             #数量
}
rewardlib_announce 152 {#奖励库公告
    request {
        playerid 0 : integer    #角色id
        name 1 : string         #角色名字
        reward 2 : *rewardmsg   #公告信息
    }
}

updatedailyuseitem 153 {#更新每日使用次数
    request {
        dailyuse 2 : useitem     #今日使用次数上限的道具
    }
}

syncdailyuseitem 154 {#同步每日使用上限次数的道具
    request {
        dailyuse 2 : *useitem     #今日使用次数上限的道具
    }
}

syncitemoverdue 155 {#同步道具过期信息
    request {
        itemId 0 : integer    #道具id
        overdue 1 : integer   #道具过期时间(overdue<=0表示删除)
    }
}
]]

return thingproto