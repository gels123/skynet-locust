local playerproto = {}

playerproto.type = [[
.rolebase {#角色基础属性
    id 0 : integer          #角色id
    sex 1 : integer         #性别
    name 2 : string         #角色名字
    level 3 : integer       #等级
    exp 4 : integer         #经验
    head 5 : integer        #头像
    lastname 6 : string     #曾用名
    account 7 : string      #账号
    language 8 : integer    #语言/国旗
    offlinetime 9 : integer   #上次离线时间
    border 10 : integer          #头像边框
    lastlanguage 12 : integer  #上次国旗
    activity 13 : integer   #活跃度
    activitychest 14 : *integer #活跃度宝箱领取信息
    guildid 15 : integer #公会id
    guildname 16 : string #公会名
    guildshort 17 : string #公会简称
    serverid 18 : integer #服务器ID

}
.unlockborder {#已解锁边框
    id 0 : integer              #配置id
    new 2 : boolean             #是否为新获得的边框
}
.unlockavatar {#已解锁头像
    id 0 : integer              #配置id
    new 1 : boolean             #是否为新获得的头像
}
.playerbuff {#君主buff
    type 0 : integer            #buff type(该字段为key)
    buffid 1 : integer          #id(用来取配置数据)
    expiretime 2 : integer      #过期时间
    begintime 3 : integer       #起始时间
}

.playerscore {#战斗力
    sumscore 0 : integer        #总战斗力
    historyscore 1 : integer    #历史战斗力
    cityscore 2 : integer       #城建战斗力
    heroscore 3 : integer       #英雄战斗力
    armyscore 4 : integer       #部队战斗力
    carscore 5 : integer        #战车战斗力
}
]]

playerproto.c2s = playerproto.type .. [[
#角色 401 ～ 500
reqrolebase 401 {#请求玩家基本信息
    response {
        info 0 : rolebase           #角色基础属性
        score 1 : playerscore       #角色战斗力
        vitality 3 : integer        #活力
        vitalitytime 4 : integer    #行动力回复满时间戳
        borders 5 : *unlockborder   #已解锁的头像边框
        setheadstatus 6 : integer   #自定义头像状态
        lasthead 7 : integer        #最新的自定义头像
        setheadtime 8 : integer     #自定义头像时间
        avatars 9 : *unlockavatar   #已解锁头像
        zoneid 10 : integer         #出生区域
    }
}

changehead 402 {#更换头像
    request {
        head 0 : integer          #头像id
    }
    response {
        code 0 : integer        #返回码
        head 1 : integer          #头像id

    }
}

changesex 403 {#更换性别
    request {
        sex 0 : integer          #性别id
    }
    response {
        code 0 : integer         #返回码
        sex 1 : integer          #性别id
    }
}

changelanguage 404 {#更换国旗
    request {
        language 0 : integer     #国旗
    }
    response {
        code 0 : integer         #返回码
        language 1 : integer     #国旗
    }
}

usevitalityitem 405 {#使用行动力道具
    request {
        item 0 : integer        #道具id
        num 1 : integer         #数量
        auto 2 : boolean        #
    }
    response {
        item 0 : integer        #道具id
        num 1 : integer         #数量
        code 2 : integer        #返回码
        vitality 3 : integer    #当前行动力
        auto 4 : boolean        #
    }
}

checkrolename 406 {#检查名字合法性
    request {
        name 0 : string         #名字
    }
}

changerolename 407 {#角色改名
    request {
        name 0 : string         #名字
        auto 1 : integer        #是否花元宝购买
    }
}

reqdetailplayerinfo 408 {#请求角色详细信息
    request {
        playerid 0 : integer    #角色id
    }
}

changeavatarborder 409 {#替换头像边框
    request {
        border 0 : integer
    }
    response {
        code 0 : integer
        border 1 : integer
    }
}

viewunlockborder 410 {#查看已解锁边框（去掉小红点）
    response {
        code 0 : integer
    }
}

activityreward 411 {#领取活跃度奖励
    request {
        id 0 : integer          #宝箱id
    }
    response {
        code 0 : integer        #返回码
        id 1 : integer          #宝箱id
        rewardlib 2 : rewardlib
    }
}

reqplayerbuff 412 {#请求角色buff
    response {
        buff 0 : *playerbuff    #buff信息
    }
}

usebuffitem 413 {#使用buff道具
    request {
        item 0 : integer        #道具id
        auto 1 : boolean        #自动消耗电池
    }
    response {
        code 0 : integer        #返回码
        item 1 : integer        #道具id
        auto 2 : boolean        #自动消耗元宝
    }
}

viewunlockavatar 414 {#查看已解锁头像（去掉小红点）
    response {
        code 0 : integer
    }
}

.playerattr {
    id 0 : integer
    val 1 : integer
}

lookplayerattr 449 { #查看玩家属性
    request {
        playerid 0 : integer
    }
    response {
        attr 0 : *playerattr(id)
    }
}
]]


playerproto.s2c = playerproto.type .. [[
#角色 401 ～ 500
changerolenameret 451 {#角色改名返回
    request {
        code 0 : integer        #返回码
        name 1 : string         #名字
        lastname 3 : string     #曾用名
    }
}

checkrolenameret 452 {#检查名字合法性返回
    request {
        code 0 : integer        #返回码
        name 1 : string         #名字
    }
}

.detailplayerinfo {
    playerid        0 : integer     #玩家ID
    serverid        1 : integer     #服务器id
    level           2 : integer     #等级
    name            3 : string      #名字
    head            4 : integer     #头像
    guildid         5 : integer     #帮派id
    guildname       6 : string      #帮派名字
    score           7 : integer     #战斗力
    border          8 : integer     #头像框
    guildshort      9 : string      #帮派缩写
    sex             10 : integer    #性别
    language        11 : integer    #国旗
}
syncdetailplayerinfo 453 {#角色详细信息返回
    request {
        info        0 : detailplayerinfo   #玩家信息
        code        1 : integer            #返回码
    }
}

noticeplayerlevelup 454 {#通知角色升级
    request {
        oldlv 0 : integer       #旧等级
        newlv 1 : integer       #新等级
        reward 2 : *thingdata   #奖励
    }
}

syncplayerexpchange 455 { #人物经验变动
    request {
        exp 0 : integer  #获得经验
        nowexp 1 : integer #当前经验
    }
}

updateplayerscore 456 {#同步角色战斗力
    request {
        score 1 : playerscore   #角色战斗力
    }
}

noticeviplevelup 457 {#通知vip升级
    request {
        oldlv 0 : integer       #旧等级
        newlv 1 : integer       #新等级
        vipexp 3 : integer      #
    }
}

updatevitality 458 {#更新行动力
    request {
        vitality 1 : integer        #活力
        vitalitytime 2 : integer    #行动力回复满时间戳
    }
}

syncsetheadstatus 459 {#同步自定义头像状态
    request {
        head 0 : integer        #头像
        setheadtime 1 : integer     #自定义头像时间
        setheadstatus 2 : integer   #自定义头像状态
        lasthead 3 : integer    #最新的自定义头像
    }
}

unlockavatarborder 460 {#解锁新的边框
    request {
        info 0 : *unlockborder
    }
}

noticedeletebuff 461 {#通知buff到期
    request {
        ids 0 : *integer        #buff id 列表
    }
}

updatebuff 462 {#更新buff数据 没有就添加  有就更新 以type为key
    request {
        buff 0 : playerbuff     #
    }
}

unlockavatarhead 463 {#解锁新的头像
    request {
        info 0 : *unlockavatar
    }
}
]]

return playerproto