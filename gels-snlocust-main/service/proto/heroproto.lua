local heroproto = {}

heroproto.type = [[
.lotteryaward {#抽奖信息
    type 0 : integer    #奖励类型
    reward 1 : integer  #奖励id
    num 2 : integer     #奖励数量
}
.attrpoint {#属性点
    atk 0 : integer 
    def 1 : integer
    spd 2 : integer
}
.heroskill {
    id 0 : integer     #技能id
    lv 1 : integer     #技能等级
    unlock 2: boolean  #是否未解锁  true=未解锁 false或者nil表示解锁
}
.heropinballskill {
    id 0 : integer     #技能id
    lv 1 : integer     #技能等级
}
.herox2skill {
    id 0 : integer     #技能id
    lv 1 : integer     #技能等级
}
.heroscore {
    basic 0 : integer       #基础战斗力
    level 1 : integer       #等级战斗力
    slgskill 2 : integer    #SLG技能战斗力
    x2skill 3 : integer     #X2技能战斗力
    talent 4 : integer      #天赋点战斗力
    breach 5 : integer      #突破战斗力
    sumscore 6 : integer    #单个英雄总战力
}
.hero {#英雄数据
    heroid 0 : integer      #英雄id
    star 1 : integer        #星级
    level 3 : integer       #等级
    exp 4 : integer         #经验
    point 5 : attrpoint     #已分配的属性点
    skill 9 : *heroskill(id)    #SLG技能数据
    breaked 10 : integer    #是否突破
    freeattrpoint 11 : integer #自由分配属性点
    pinballskill 12 : *heropinballskill(id) #弹球技能数据
    score 13 : heroscore    #英雄战斗力
    x2skill 14 : *herox2skill(id) #x2技能数据
    breakednum 15 : integer #突破次数
}
.herocommonskill {#英雄通用技能
    id 3 : integer          #通用技能流水id
    skillid 0 : integer     #技能id
    skilllv 1 : integer     #技能等级
    usehero 2 : integer     #穿戴的英雄 0表示没有穿戴的英雄
}
.heromaterial {#消耗的材料信息
    itemid 0 : integer  #道具id
    num 1 : integer     #数量
}
.heroFreeLottery {
    type 0 : integer #抽卡类型，draw表Type字段
    nextFreeTime 1 : integer #下一次免费时刻
    usedNumber 2 : integer #已用免费次数
}
.heroShareLevelMasterSlot { #英雄共享等级主槽位信息
    id 0 : integer # 槽位id
    heroID 1 : integer # 放置的英雄id
    putTime 3 : integer # 放置时刻
}
.heroShareLevelSlot { #英雄共享等级槽位信息
    id 0 : integer # 槽位id
    unlockTime 1 : integer # 解锁时刻
    heroID 2 : integer # 放置的英雄id
    putTime 3 : integer # 放置时刻
    takeTime 4 : integer # 移除时刻
}
.heroShareLevelInfo { #英雄共享等级信息
    level 0 : integer # 共享等级
    masterHeroList 1 : *heroShareLevelMasterSlot # 共享等级的英雄列表
}
]]

heroproto.c2s = heroproto.type .. [[
#英雄 701 ～ 800
herolottery 701 {#英雄抽奖
    request {
        type 0 : integer        #1=普通 2=高级
        num 1 : integer         #次数
        auto 2 : boolean        #自动消耗道具
    }
    response {
        code 0 : integer        #返回码
        type 1 : integer        #1=普通 2=高级
        num 2 : integer         #次数
        auto 3 : boolean        #自动消耗道具
        showRewards 4 : *rewardlib #展示用奖励，已获得英雄不转碎片，不用堆叠
        realReward 5 : rewardlib #实际获得奖励，已获得英雄转碎片，需要堆叠
        firstGainHeroIDs 6 : *integer # 第一次获得的英雄id列表
        maxRarityDropID 7 : integer # 稀有度最高的drop表Id
    }
}

reqplayerhero 702 {#请求英雄信息
    response {
        data 0 : *hero #英雄信息
        freeLotteries 1 : *heroFreeLottery(type) #免费抽卡信息列表
        shareLevelInfo 2 : heroShareLevelInfo # 共享等级
        shareLevelSlotList 3 : *heroShareLevelSlot #共享等级槽位列表
    }
}

compositehero 703 {#合成英雄
    request {
        heroid 0 : integer          #英雄id
    }
    response {
        code 0 : integer            #返回码
        heroid 1 : integer          #英雄id
    }
}

leveluphero 704 {#升级英雄
    request {
        heroid 0 : integer          #英雄id
        item 1 : *heromaterial(itemid) #道具
        auto 2 : boolean        #自动消耗道具
        
    }
    response {
        code 0 : integer       #返回码
        item 1 : *heromaterial(itemid) #道具
        hero 2 : hero          #英雄数据
    }
}

upgradeherostar 705 {#英雄升星
    request {
        heroid 0 : integer          #英雄id
    }
    response {
        code 0 : integer            #返回码
        heroid 1 : integer          #英雄id
        star 2 : integer            #星级
    }
}

allocateheropoint 706 {#分配英雄属性点
    request {
        heroid 0 : integer
        point 1 : attrpoint     #分配的属性点
    }
    response {
        heroid 0 : integer
        point 1 : attrpoint     #已分配的属性点
        code 2 : integer        #返回码
        freeattrpoint 3 : integer #自由分配属性点
    }
}

resetheropoint 707 {#重置英雄属性点
    request {
        heroid 0 : integer
    }
    response {
        heroid 0 : integer
        point 1 : attrpoint     #已分配的属性点
        code 2 : integer        #返回码
        freeattrpoint 3 : integer #自由分配属性点
    }
}

unlockheroskill 708 {#解锁英雄通用技能
    request {
        skillid 0 : integer
    }
    response {
        code 0 : integer
        skillid 1 : integer
        newskill 3 : *herocommonskill  #新的英雄通用技能
    }
}

dressheroskill 709 {#穿戴技能
    request {
        heroid 0 : integer
        id 1 : integer      #通用技能流水id
        index 2 : integer   #位置
    }
    response {
        code 2 : integer
        heroid 0 : integer
        id 1 : integer      #通用技能流水id
        skill 3 : *heroskill    #英雄技能数据
        commonskill 4 : herocommonskill  #英雄通用技能数据
        index 5 : integer   #位置
    }
}

undressheroskill 710 {#卸载技能
    request {
        heroid 0 : integer
        index 2 : integer   #位置
    }
    response {
        code 2 : integer
        heroid 0 : integer
        skill 3 : *heroskill    #英雄技能数据
        commonskill 4 : herocommonskill  #英雄通用技能数据
        index 5 : integer   #位置
    }
}

levelupheroskill 711 {#升级英雄技能
    request {
        heroid 0 : integer          #英雄id
        skillid 1 : integer         #技能id
    }
    response {
        code 0 : integer            #返回码
        heroid 1 : integer          #英雄id
        skillid 2 : integer         #技能id
        skill 3 : *heroskill(id)        #英雄技能数据
    }
}

levelupheropinballskill 712 {#升级英雄弹球技能
    request {
        heroid 0 : integer          #英雄id
        skillid 1 : integer         #技能id
    }
    response {
        code 0 : integer            #返回码
        heroid 1 : integer          #英雄id
        skillid 2 : integer         #技能id
        skill 3 : *heropinballskill(id) #英雄弹球技能数据
    }
}

herobreach 713 {#英雄突破
    request {
        heroid 0 : integer          #英雄id

    }
    response {
        code 0 : integer            #返回码
        heroid 1 : integer          #英雄id
        freeattrpoint 2 : integer #自由分配属性点
    }
}

levelupherox2skill 714 {#英雄X2技能升级
    request {
        heroid 0 : integer          #英雄id
        #skillid 1 : integer        #技能id
        auto 2 : boolean            #自动消耗道具
    }
    response {
        code 0 : integer            #返回码
        heroid 1 : integer          #英雄id
        #skillid 2 : integer         #技能id
        #skilllevel 3 : integer      #技能等级
    }
}

resetherox2skill 715 {#重置英雄X2技能
    request {
        heroid 0 : integer          #英雄id
        #skillid 1 : integer         #技能id
    }
    response {
        code 0 : integer            #返回码
        heroid 1 : integer          #英雄id
        #skillid 2 : integer        #技能id
        #skilllevel 3 : integer     #技能等级
        reward 4 : rewardlib        #返还升级消耗
    }
}

putHeroToShareLevelSlot 716 {#将英雄放入共享等级槽位
    request {
        heroID 0 : integer # 英雄id
        slotID 1 : integer # 槽位id
    }
    response {
        code 0 : integer # 返回码
        heroID 1 : integer # 英雄id
        slotID 2 : integer # 槽位id
        reward 3 : rewardlib # 重置返还物品
    }
}

takeHeroFromShareLevelSlot 717 {#将英雄移出共享等级槽位
    request {
        slotID 0 : integer # 槽位id
    }
    response {
        code 0 : integer # 返回码
        slot 1 : heroShareLevelSlot # 槽位信息
    }
}

resetHeroLevel 718 {#重置英雄等级
    request {
        heroID 0 : integer # 英雄id
    }
    response {
        code 0 : integer # 返回码
        heroID 1 : integer # 英雄id
        reward 2 : rewardlib # 重置返还物品
    }
}

]]

heroproto.s2c = heroproto.type .. [[
#英雄 701 ～ 800
syncfreetimes 751 {#同步免费抽取次数
    request {
        freeLotteries 0 : *heroFreeLottery(type) #免费抽卡信息列表
    }
}

noticenewhero 753 {#通知获得新英雄
    request {
        data 0 : *hero              #英雄信息
        from 1 : integer # 获取途径 1=其他，2=抽卡，3=合成
        toFragmentList 2 : *integer # 转换成碎片的英雄id
    }
}

synchero 754 {#同步英雄
    request {
        heroid 0 : integer
        level 1 : integer
        exp 2 : integer
        breaked 3 : integer
        freeattrpoint 4 : integer
        skill 5 : *heroskill(id)  #SLG技能数据
        pinballskill 6 : *heropinballskill(id) #弹球技能数据
        x2skill 7 : *herox2skill(id) #x2技能数据
        breakednum 8 : integer #突破次数
        point 9 : attrpoint # 加点
    }
}

syncheroscore 755 {#同步英雄战斗力
    request {
        heroid 0 : integer     #英雄ID
        score 1 : heroscore    #英雄战斗力
        islvup 2 : integer     #是否是英雄升级，1是0否
        isbreach 3 : integer   #是否是英雄突破，1是0否
    }
}

syncHeroShareLevel 756 { # 同步英雄共享等级信息
    request {
        info 0 : heroShareLevelInfo #共享等级槽位列表
    }
}

syncHeroShareLevelSlot 757 { # 同步英雄共享等级槽位
    request {
        list 0 : *heroShareLevelSlot #共享等级槽位列表
    }
}

]]

return heroproto