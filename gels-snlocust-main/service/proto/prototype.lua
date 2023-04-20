local types = [[
.mappos {#地图对象坐标数据
	x 0 : integer		#x
	y 1 : integer		#y
}

.aiInBattle {
    highPrioritySkillID 0 : integer # 高优先级技能id
}

.inputInBattle {
    tick 0 : integer # 第几帧
    skillID 1 : integer # 使用的技能id
    targetID 2 : integer # 目标id
}

.legionInBattleFormation {
    fpos 0 : integer # 阵位
    ai 1 : aiInBattle # AI
    heroID 2 : integer # 英雄id
    soldierID 3 : integer # 士兵id，soldier表的id
    soldierNum 4 : integer # 士兵数量
    heroLv 5 : integer # 英雄等级(战斗无用)
}

.armyInBattleFormation {
    id 0 : integer # 玩家id
    legionList 1 : *legionInBattleFormation(fpos) # 军团信息
}

.campInBattleFormation {
    type 0 : integer # 阵营类型
    armyList 1 : *armyInBattleFormation # 军队信息
}

.battleFormation {
    campsList 1 : *campInBattleFormation(type) # 阵营信息
}

.skillSoldierNum {
    skillId 1 : integer # 技能id
    soldierNum 2 : integer # 士兵数量
}

.legionStatisticInBattleReport {
    damage 0 : integer # 伤害
    heal 1 : integer # 治疗
    reduceSoldierNum 2 : integer # 损失士兵数量
    beatSoldierNum 3 : integer # 击败敌方兵量
    sInjuredSoldierNum 4 : integer # 重伤士兵数量
    lInjuredSoldierNum 5 : integer # 轻伤士兵数量
    aliveSoldierNum 6 : integer # 存活士兵数量
    deadSoldierNum 7 : integer # 死亡士兵数量
    commonAttackBeatSoldierNum 8: integer # 普攻击杀士兵数量
    skillBeatSoldierNum 9: *skillSoldierNum # 技能击杀士兵数量 技能id -> 击杀士兵数量
    skillHealSoldierNum 10: *skillSoldierNum # 技能治疗士兵数量 技能id -> 治疗士兵数量
}

.legionHeroSkillConfigInBattleReport {
    ID 0 : integer # id
    Level 1 : integer # 等级
}

.legionHeroAIConfigInBattleReport {
    HighPrioritySkillID 0 : integer # 高优先级技能id
}

.legionHeroConfigInBattleReport {
    Id 0 : integer
    Type 1 : integer
    Level 2 : integer
    Skill 3 : *legionHeroSkillConfigInBattleReport # 技能
    AI 4 : legionHeroAIConfigInBattleReport # AI
    Attack 5 : string
    Defence 6 : string
    EnergyRecoverSpeed 7 : string
    MaxLeadSoldierNum 8 : integer
}

.legionSoldierConfigInBattleReport {
    Id 0 : integer
    Type 1 : integer
    Level 2 : integer
    AttackRange 3 : string
    MoveSpeed 4 : string
    Attack 5 : string
    Hp 6 : string
    AttackSpeed 7 : string
}

.legionAttrInBattleReport {
    SoldierAttackAddition 0 : double
    SoldierHpAddition 1 : double
    LegionCommonAttackAddition 2 : double
    LegionCommonAttackDeduction 3 : double
}

.legionConfigInBattleReport {
    BtreeName 0 : string # 行为树名
    Hero 1 : legionHeroConfigInBattleReport # 英雄配置
    Soldier 2 : legionSoldierConfigInBattleReport # 士兵配置
    SoldierNum 3 : integer # 士兵数量
    AliveSoldierNum 4 : integer # 战斗开始时存活士兵数量
    LeftSoldierNum 5 : integer # 战斗结束时存活士兵数量
    Attr 6 : legionAttrInBattleReport # 科技带入的军团属性
}

.legionInBattleReport {
    fpos 0 : integer # 阵位
    statistic 1 : legionStatisticInBattleReport # 统计数据
    config 2 : legionConfigInBattleReport # 配置
    inputList 3 : *inputInBattle(tick) # 输入
}

.armyInBattleReport {
    id 0 : integer # 玩家id
    legionList 1 : *legionInBattleReport(fpos) # 军团信息
    losePower 2 : integer  #玩家/npc损失战力
    power 3 : integer 
}

.campInBattleReport {
    type 0 : integer # 阵营
    armyList 1 : *armyInBattleReport(id) # 军队信息
    idx 2 : integer  # 预设索引(结算用)
    qid 3 : string   # 队列id(结算用)
}

.battleRound {
    winCamp 0 : integer # 胜利阵营
    campList 1 : *campInBattleReport(type) # 阵营信息
    battleID 2: integer # 防守方的battleId
}

.battleReport {
    version 0: integer # 版本
    type 1 : integer # 战斗类型，枚举EBattleTypeName
    seeds 2 : *integer # 随机种子
    winCamp 3 : integer # 胜利阵营
    rounds 4 : *battleRound # 战斗回合
    id 5 : integer # 唯一id
}

.battleReportOne {
    version 0: integer # 版本
    type 1 : integer # 战斗类型，枚举EBattleTypeName
    seeds 2 : *integer # 随机种子
    round 3 : battleRound # 战斗回合
    id 4 : integer # 唯一id
    uInfo1 5 : battleReportUsrBrief # 攻击方玩家信息
    uInfo2 6 : battleReportUsrBrief # 防守方玩家信息
}

.warlineup {#出征军团阵容
    idx 0 :  integer        #出征预设索引
    legionList 1 : *legionInBattleFormation(fpos) # 军团信息
    garrisonidx 2: integer  # 1驻防编队索引
}

.npclineup {#npc军团阵容
    battleId 0 :  integer        #出征预设索引
    army 1 : *legionInBattleFormation(fpos) # 军团信息
}

.arenalineup {#出征军团阵容
    idx 0 :  integer                              # 军团信息坑位
    legionList 1 : *legionInBattleFormation(fpos) # 军团信息
    power 2 : integer                             # 阵容战力
}

.battleReportUsrBrief {#简要战报信息内的玩家简要信息
	playerid 0 : integer 	    #玩家ID
	name 1 : string 		#玩家名字
	head 2 : integer 		#玩家头像
	border 3 : integer 		#玩家头像框
	guildid 4 : integer 		#玩家头像框
	guildshort 5 : string 	    #玩家联盟简称
	guildname 6 : string 	    #玩家联盟名称
	x 7 : integer 	#玩家坐标x
	y 8 : integer  #玩家坐标y
	battleID 9: integer # battles表id
	rankUp 10 : integer  #竞技场排名变化
	rank 11 : integer  #竞技场原排名
}

.battleReportUsrBriefSub {#为.battleReportUsrBrief的子集
    playerid 0 : integer 	    #玩家ID
	name 1 : string 		#玩家名字
	guildshort 2 : string 	    #玩家联盟简称
	x 3 : integer 	#玩家坐标x
	y 4 : integer  #玩家坐标y
	battleID 5: integer # battles表id
}

.battleReportBrief {#[竞技场]简要战报信息
    type 0 : integer # 战场类型
    pos 1 : mappos # 战场坐标
    winCamp 2 : integer # 胜利阵营
    rounds 3 : *battleRound # 战斗回合
    id 4 : integer # 唯一id
    usrInfo1 5 : *battleReportUsrBrief(playerid) # 攻击方玩家信息
    usrInfo2 6 : *battleReportUsrBrief(playerid) # 防守方玩家信息
    lineup1 7 : *arenalineup(idx) # 竞技场阵容
    lineup2 8 : *arenalineup(idx) # 竞技场阵容
    time 9 : integer # 时间
    isView 10 : boolean # 是否已查看
    rankUp 11 : integer  #竞技场排名变化
}

.battleReportMailBriefRound {
    winCamp 0 : integer # 胜利阵营
    atkUid 1 : integer # 攻击方玩家ID
    atkBattleId 2 : integer # 攻击方battleID
    defUid 3 : integer # 防守方玩家ID
    defBattleId 4 : integer # 防守方battleID
}

.battleReportMailBrief {#战报邮件简要信息
    type 0 : integer # 战场类型
    pos 1 : mappos # 战场坐标
    pos2 2 : mappos # 攻方坐标
    camp 3 : integer # 阵营
    winCamp 4 : integer # 胜利阵营
    rounds 5 : *battleReportMailBriefRound # 战斗回合
    usrInfo1 6 : *battleReportUsrBriefSub(playerid) # 攻击方玩家信息
    usrInfo2 7 : *battleReportUsrBriefSub(playerid) # 防守方玩家信息
    heros 8 : *integer # 进攻方显示英雄
}

.tokendata {#代币数据
    Food  0 : integer           #汽油
    Water  1 : integer          #水
    Coin 2 : integer            #电池
    Banggong  3 : integer       #帮贡
    Pbcoin  4 : integer         #弹球币
    SysFood 5 : integer         #
    SysWater 6 : integer        #
    SysCoin 7 : integer         #
}

.thingdata {#物品基础结构
    cfgid 0 : integer       #物品配置id
    amount 1 : integer      #叠加数量
    overdue 2 : integer     #过期时间
}

.rewardlib {#奖励库
    thing 0 : *thingdata            #物品数据
    token 1 : tokendata             #代币数据
    exp 2 : integer                 #君主经验
    hero 3 : *integer               #英雄id列表
    frame 6 : integer               #头像框
}

.package {
	type 0 : integer
	session 1 : integer
}
.serverinfo {#服务器信息
    id 0 : integer              #服务器id
    name 1 : string             #服务器名字
}

.citytech {#城建科技信息
    id 0 : integer          #科技id
    level 1 : integer       #科技等级
}

.collectioninfo {
    id 0 : integer
    x 1 : integer           #x坐标
    y 2 : integer           #y坐标
    collmark 3 : integer    #收藏标注: 见定义 mapcommon.collection_mark
    name 4 : string         #收藏命名
    uid 5 : integer         #玩家ID
    more 6:  string         #更多信息json
    time 7 : integer        #添加/更新时间
}

.statistics {#统计信息
    type 0 : integer            #类型
    value 1 : integer           #数值
}

]]

return types