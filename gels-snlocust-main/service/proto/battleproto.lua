local proto = {}

proto.type = [[
.heroSkillInBattleConfig {
    ID 0 : integer
    Level 1 : integer
}

.heroAttrInBattleConfig {
    Atk 0 : double
    Def 1 : double
    Spd 2 : double
}

.heroInBattleConfig {
    ID 0 : integer # 英雄ID
    Level 1 : integer # 英雄等级
    Skills 2 : *heroSkillInBattleConfig(ID) # 英雄技能
    AI 3 : aiInBattle # 英雄AI
    Attr 4 : heroAttrInBattleConfig # 英雄属性
}

.soldierAttrInBattleConfig {
    SoldierAttackAddition 0 : double
    SoldierHpAddition 1 : double
}

.soldierInBattleConfig {
    ID 0 : integer # 士兵ID
    Num 1 : integer # 士兵数量
    Attr 2 : soldierAttrInBattleConfig # 士兵属性
}

.legionAttrInBattleConfig {
    SoldierAttackAddition 0 : double
    SoldierHpAddition 1 : double
    LegionCommonAttackAddition 2 : double
    LegionCommonAttackDeduction 3 : double
}

.legionInBattleConfig {
    fpos 0 : integer # 阵位
    BtreeName 1 : string # 行为树名
    Hero 2 : heroInBattleConfig # 英雄配置
    Soldier 3 : soldierInBattleConfig # 士兵配置
    Attr 4 : legionAttrInBattleConfig # 科技带入的军团属性
}
]]

proto.c2s = proto.type .. [[
#战斗 2001~2100
#请求内城战斗
reqBattle 2001 {
    request {
        objID 0 : integer  #怪物ID
        warlineupIdx 1 : integer # 出征预设索引
        riotId 2 : integer #工人暴动建筑ID
    }
    response {
        code 0 : integer  #错误码
        objID 1 : integer #怪物id
        warlineupIdx 2 : integer # 出征预设索引
        seeds 3 : *integer #随机数
        playerCfg 4 : *legionInBattleConfig(fpos) # 玩家配置
        battleID 5 : integer #战斗id
        riotId 7 : integer #工人暴动建筑ID
    }
}

#确认内城战斗
reqConfirmBattle 2002 {
    request {
        objID 0 : integer #怪物ID
        report 1 : battleReport #战报
        riotId 2 : integer #工人暴动建筑ID
    }
    response {
        code 0 : integer  #错误码
        objID 1 : integer #怪物ID
        rewards 2 : *thingdata # 奖励数据
        riotId 3 : integer #工人暴动建筑ID
    }
}
]]

proto.s2c = [[
]]

return proto