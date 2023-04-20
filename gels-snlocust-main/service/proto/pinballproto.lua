local pinballproto = {}

pinballproto.type = [[
#弹珠出征阵容预设单元
.pinballLineupCell {
    index 0 :  integer          #坑位
    mainHeroId 1 :  integer     #主将英雄ID
    assitHeroId 2 :  integer    #副将英雄ID
}

#弹珠出征阵容预设
.pinballLineup {
    idx 0 :  integer            #出征预设索引
    info 1 : *pinballLineupCell(index) #主将英雄ID
}

#弹珠战斗统计报告信息
.pinballBattleReport {
    isClear 0 :  boolean            #是否过关
    costTime 1 :  integer           #
    totalHitDmg 2 :  integer        #
    totalSkillDmg 3 :  integer      #
    totalFlipSkillDmg 4 :  integer  #
    totalSkillHeal 5 :  integer     #
    totalFeverTimes 6 :  integer    #
    totalRushTimes 7 :  integer     #
    totalFlipTimes 8 :  integer     #
    totalReviveTimes 9 :  integer   #
    maxCombo 10 :  integer          #
    starNum 11 :  integer           #星星数量
}

#弹珠关卡信息单元
.pinballInfoCell {
    levelID 0 :  integer            #大关卡ID
    isClear 1 :  boolean            #是否通关
    starNum 2 :  integer            #星星数量
    expireTime 3 :  integer         #当前挑战过期时间
}

#弹珠关卡难度信息单元
.pinballInfoDiffCell {
    diff 0 :  integer               #难度
    diffInfo 1 :  *pinballInfoCell(levelID) #本难度关卡信息
    isReward 2 :  boolean           #是否已经领取本难度满星奖励
}

#弹珠章节信息
.pinballInfo {
    chapterID 0 :  integer          #章节ID
    redPoint 1 :  integer           #章节最大难度小红点 0无小红点 1有小红点 2播完动画有小红点 3无动画无小红点
    maxDiff 2 :  integer            #章节最大难度
    diffInfos 3 :  *pinballInfoDiffCell(diff) #章节难度信息
    diffTab 4 :  integer            #章节当前在哪个难度页面
}

#弹珠商店兑换限制单元
.pinballStoreLimitCell {
    id 0 :  integer              #兑换ID
    num 1 :  integer             #兑换次数
}
]]

pinballproto.c2s = pinballproto.type .. [[
#弹珠 2301~2400

#请求弹珠出征预设信息
reqPinballLineupInfo 2301 {
    request {
    }
    response {
        code 0 : integer       #错误码
        lineups 1 : *pinballLineup(idx) #出征阵容预设
    }
}

#设置/更新弹珠出征预设
reqPinballUpdateLineup 2302 {
    request {
        lineup 0 : pinballLineup #出征阵容预设
    }
    response {
        code 0 : integer         #错误码
        lineup 1 : pinballLineup #出征阵容预设
    }
}

#请求弹珠关卡信息
reqPinballInfos 2303 {
    request {
    }
    response {
        code 0 : integer       #错误码
        mopUpUnlock 1 : boolean #扫荡是否已解锁
        mopUpLimit 2 : integer #扫荡次数兑换限制 
        mopUpTime 3 : integer  #扫荡次数兑换限制日期
        infos 4 : *pinballInfo(chapterID)       #章节信息
        curDiff 5 : integer       #当前挑战难度
        canAuto 6 : boolean #能否自动战斗
        curAuto 7 : integer #当前自动战斗状态, 0=未开启自动战斗 1=开启自动战斗 2=开启二倍速自动战斗
        idx 8 : integer #当前预设索引
    }
}

#请求弹珠战斗
reqPinballBattle 2304 {
    request {
        chapterID 0 : integer  #章节ID
        levelID 1 : integer    #大关卡ID
        diff 2 : integer       #难度ID
        idx 3 :  integer       #出征预设索引
        taskID 4 :  integer    #雷达弹球怪任务ID
    }
    response {
        code 0 : integer       #错误码
        chapterID 1 : integer  #章节ID
        levelID 2 : integer    #大关卡ID
        diff 3 : integer       #难度ID
        idx 4 :  integer       #出征预设索引
    }
}

#确认弹珠战斗
reqPinballConfirmBattle 2305 {
    request {
        chapterID 0 : integer  #章节ID
        levelID 1 : integer    #大关卡ID
        diff 2 : integer       #难度ID
        idx 3 :  integer       #出征预设索引
        battleReport 4 :  pinballBattleReport       #弹珠战斗统计报告信息
    }
    response {
        code 0 : integer       #错误码
        chapterID 1 : integer  #章节ID
        levelID 2 : integer    #大关卡ID
        diff 3 : integer       #难度ID
        idx 4 :  integer       #出征预设索引

        mopUpUnlock 5 : boolean #扫荡是否已解锁
        diffNewEx 6 :  *pinballInfo(chapterID)            #新解锁的Ex章节
        diffInfoCell 7 :  pinballInfoCell #关卡信息
        canAuto 8 : boolean #能否自动战斗
        reward 9 : rewardlib    #奖励数据
    }
}

#弹珠扫荡
reqPinballMopUp 2306 {
    request {
    }
    response {
        code 0 : integer       #错误码
        mopUpLimit 1 : integer #扫荡次数兑换限制 
        mopUpTime 2 : integer  #扫荡次数兑换限制日期
        reward 3 : rewardlib   #扫荡奖励
    }
}

#请求领取章节满星奖励
reqPinballGetChapterReward 2307 {
    request {
        chapterID 0 : integer  #章节ID
        diff 1 : integer       #难度ID
    }
    response {
        code 0 : integer       #错误码
        chapterID 1 : integer  #章节ID
        diff 2 : integer       #难度ID
        reward 3 : rewardlib   #奖励
    }
}

#设置章节当前在哪个难度页面
reqPinballSetDiffTab 2308 {
    request {
        chapterID 0 : integer  #章节ID
        diffTab 1 :  integer   #章节当前在哪个难度页面
        redPoint 2 :  integer  #章节最大难度小红点 0无小红点 1有小红点 2播完动画有小红点 3无动画无小红点
    }
    response {
        code 0 : integer       #错误码
        chapterID 1 : integer  #章节ID
        diffTab 2 :  integer   #章节当前在哪个难度页面
        redPoint 3 :  integer  #章节最大难度小红点 0无小红点 1有小红点 2播完动画有小红点 3无动画无小红点
    }
}

#请求商店信息
reqPinballStoreInfo 2309 {
    request {
    }
    response {
        code 0 : integer       #错误码
        storeExp 1 :  integer   #商店经验
        storeLv 2 :  integer   #商店等级
        storeLimit 3 :  *pinballStoreLimitCell(id)   #商店兑换次数限制
        storeLimitTime 4 :  integer   #商店兑换次数限制时间
        storeSuperID 5 :  integer   #商店超值兑换ID
        storeLvUp 6 :  *pinballStoreLimitCell   #商店升级终身兑换信息
    }
}

#请求商店购买
reqPinballStoreBuy 2310 {
    request {
        id 0 : integer       #兑换ID
        num 1 : integer      #兑换次数
        lv 2 : integer       #兑换终身道具
    }
    response {
        code 0 : integer       #错误码
        id 1 : integer       #兑换ID
        num 2 : integer       #兑换次数
        lv 3 : integer       #兑换终身道具
        storeLv 4 :  integer   #商店等级
        storeExp 5 :  integer   #商店经验
    }
}

#设置自动战斗
reqPinballSetAuto 2311 {
    request {
        curAuto 0 : integer #当前自动战斗状态
    }
    response {
        code 0 : integer    #错误码
        curAuto 1 : integer #当前自动战斗状态, 0=未开启自动战斗 1=开启自动战斗 2=开启二倍速自动战斗
    }
}

#请求弹珠扫荡信息
reqPinballMopUpInfo 2312 {
    response {
        code 0 : integer       #错误码
        mopUpLimit 1 : integer #扫荡次数兑换限制
        mopUpTime 2 : integer  #扫荡次数兑换限制日期
    }
}

]]

pinballproto.s2c = pinballproto.type .. [[
#弹珠 2301~2400

#支线解锁
notifyPinballOthinfo 2399 {
    request {
        info 0 :  pinballInfoCell #新解锁的支线信息
    }
}
]]

return pinballproto