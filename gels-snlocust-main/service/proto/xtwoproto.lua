local xtwoproto = {}

xtwoproto.type = [[
#x2玩法出征阵容预设单元
.xtwoLineupCell {
    index 0 :  integer          #坑位
    mainHeroId 1 :  integer     #主将英雄ID
}

#x2玩法出征阵容预设
.xtwoLineup {
    idx 0 :  integer            #出征预设索引
    info 1 : *xtwoLineupCell(index) #主将英雄ID
    name 2 : string             #阵容名称
}

#x2玩法战斗统计报告信息
.xtwoBattleReport {
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

#x2玩法关卡信息单元
.xtwoInfoCell {
    levelID 0 :  integer            #大关卡ID
    isClear 1 :  boolean            #是否通关
    starNum 2 :  integer            #星星数量
    expireTime 3 :  integer         #当前挑战过期时间
    isUnlock 4 : boolean            #是否已经解锁
}

#x2玩法关卡难度信息单元
.xtwoInfoDiffCell {
    diff 0 :  integer               #难度
    diffInfo 1 :  *xtwoInfoCell(levelID) #本难度关卡信息
    isReward 2 :  boolean           #是否已经领取本难度满星奖励
}

#x2玩法章节信息
.xtwoInfo {
    chapterID 0 :  integer          #章节ID
    redPoint 1 :  integer           #章节最大难度小红点 0无小红点 1有小红点 2播完动画有小红点 3无动画无小红点
    maxDiff 2 :  integer            #章节最大难度
    diffInfos 3 :  *xtwoInfoDiffCell(diff) #章节难度信息
    diffTab 4 :  integer            #章节当前在哪个难度页面
}

#x2玩法商店兑换限制单元
.xtwoStoreLimitCell {
    id 0 :  integer              #兑换ID
    num 1 :  integer             #兑换次数
}
.monsterlist{
    id 0 :  integer  #怪物ID
    red 1:integer  #1提示红点 0不提示
}
]]

xtwoproto.c2s = xtwoproto.type .. [[
#x2玩法 2401~2450

#请求x2玩法出征预设信息
reqXtwoLineupInfo 2401 {
    request {
    }
    response {
        code 0 : integer       #错误码
        lineups 1 : *xtwoLineup(idx) #出征阵容预设
    }
}

#设置/更新x2玩法出征预设
reqXtwoUpdateLineup 2402 {
    request {
        lineup 0 : xtwoLineup #出征阵容预设
    }
    response {
        code 0 : integer         #错误码
        lineup 1 : xtwoLineup #出征阵容预设
    }
}

#请求x2玩法关卡信息
reqXtwoInfos 2403 {
    request {
    }
    response {
        code 0 : integer       #错误码
        mopUpUnlock 1 : boolean #扫荡是否已解锁
        mopUpLimit 2 : integer #扫荡次数兑换限制
        mopUpTime 3 : integer  #扫荡次数兑换限制日期
        infos 4 : *xtwoInfo(chapterID)       #主线章节信息
        curDiff 5 : integer       #当前挑战难度
        canAuto 6 : boolean #能否自动战斗
        curAuto 7 : integer #当前自动战斗状态, 0=未开启自动战斗 1=开启自动战斗 2=开启二倍速自动战斗
        idx 8 : integer #当前预设索引
        carIdx 9 : integer #当前战车预设索引
        othinfos 10 : *xtwoInfoCell(levelID) #支线信息
    }
}

#请求x2玩法战斗
reqXtwoBattle 2404 {
    request {
        chapterID 0 : integer  #章节ID
        levelID 1 : integer    #大关卡ID
        diff 2 : integer       #难度ID
        idx 3 :  integer       #出征预设索引
        taskID 4 :  integer    #雷达弹球怪任务ID
        carIdx 5 : integer     #当前战车预设索引
    }
    response {
        code 0 : integer       #错误码
        chapterID 1 : integer  #章节ID
        levelID 2 : integer    #大关卡ID
        diff 3 : integer       #难度ID
        idx 4 :  integer       #出征预设索引
        carIdx 5 : integer     #当前战车预设索引
        monsterlist 6:*monsterlist(id)
    }
}

#确认x2玩法战斗
reqXtwoConfirmBattle 2405 {
    request {
        chapterID 0 : integer  #章节ID
        levelID 1 : integer    #大关卡ID
        diff 2 : integer       #难度ID
        idx 3 :  integer       #出征预设索引
        battleReport 4 :  xtwoBattleReport       #x2玩法战斗统计报告信息
    }
    response {
        code 0 : integer       #错误码
        chapterID 1 : integer  #章节ID
        levelID 2 : integer    #大关卡ID
        diff 3 : integer       #难度ID
        idx 4 :  integer       #出征预设索引

        mopUpUnlock 5 : boolean #扫荡是否已解锁
        diffNewEx 6 :  *xtwoInfo(chapterID)            #新解锁的Ex章节
        diffInfoCell 7 :  xtwoInfoCell #关卡信息
        canAuto 8 : boolean #能否自动战斗
        reward 9 : rewardlib    #奖励数据
    }
}

#x2玩法扫荡
reqXtwoMopUp 2406 {
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
reqXtwoGetChapterReward 2407 {
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
reqXtwoSetDiffTab 2408 {
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
reqXtwoStoreInfo 2409 {
    request {
    }
    response {
        code 0 : integer       #错误码
        storeExp 1 :  integer   #商店经验
        storeLv 2 :  integer   #商店等级
        storeLimit 3 :  *xtwoStoreLimitCell(id)   #商店兑换次数限制
        storeLimitTime 4 :  integer   #商店兑换次数限制时间
        storeSuperID 5 :  integer   #商店超值兑换ID
        storeLvUp 6 :  *xtwoStoreLimitCell   #商店升级终身兑换信息
    }
}

#请求商店购买
reqXtwoStoreBuy 2410 {
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
reqXtwoSetAuto 2411 {
    request {
        curAuto 0 : integer #当前自动战斗状态
    }
    response {
        code 0 : integer    #错误码
        curAuto 1 : integer #当前自动战斗状态, 0=未开启自动战斗 1=开启自动战斗 2=开启二倍速自动战斗
    }
}

#请求x2玩法扫荡信息
reqXtwoMopUpInfo 2412 {
    response {
        code 0 : integer       #错误码
        mopUpLimit 1 : integer #扫荡次数兑换限制
        mopUpTime 2 : integer  #扫荡次数兑换限制日期
    }
}

#请求更新队伍名称
reqXtwoUpdateLineupName 2413 {
    request {
        idx 0 : integer        #阵容idx
        name 1 : string        #阵容名称
    }
    response {
        code 0 : integer       #错误码
        idx 1 : integer        #阵容idx
        name 2 : string        #阵容名称
    }
}

#获取怪物图鉴
reqXtwoGetMonsterlist 2414 {
    response {
        code 0 : integer       #错误码
        monsterlist 1:*monsterlist(id)
    }
}

reqXtwoClearMonsterRed 2415 {
    request {
        monsterlist 0:*monsterlist(id)
    }
    response {
        code 0 : integer       #错误码
    }
}

#请求x2交付功能
reqdeliver 2416 {
    request {
        chapterID 0 : integer  #章节ID
        levelID 1 : integer    #大关卡ID
        diff 2 : integer       #难度ID
    }
    response {
        code 0 : integer       #错误码
        chapterID 1 : integer  #章节ID
        levelID 2 : integer    #大关卡ID
        diff 3 : integer       #难度ID
        isunlock 4 : boolean   #是否解锁
    }
}



]]

xtwoproto.s2c = xtwoproto.type .. [[
#x2玩法 2401~2450

#支线解锁
notifyXtwoOthinfo 2450 {
    request {
        info 0 :  xtwoInfoCell #新解锁的支线信息
    }
}
]]

return xtwoproto