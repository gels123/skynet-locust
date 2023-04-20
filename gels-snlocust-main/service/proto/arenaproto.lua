local arenaproto = {}

arenaproto.type = [[

#竞技场时间队列单元
.arenaChallengeCell {
    idx 0 : integer 		    #坑位
    rank 1 : integer 		    #排名
    uid 2 : integer 		    #玩家ID
    name 3 : string 		    #玩家名称
    head 4 : integer 		    #玩家头像
    level 5 : integer 		    #玩家等级
    border 6 : integer          #边框
    castlelv 7 : integer 		#玩家城堡等级
    guildid 8 : integer 		#玩家联盟ID
    guildshort 9 : string 		#玩家联盟简称
    guildname 10 : string 		#玩家联盟名称
    lineup 11 : *arenalineup(idx) #阵容
    totalPower 12 : integer      #阵容总战力
    mainHeroId 13 : integer      #最高战力英雄ID
    goupId 14 : integer         #robot配置ID
}

#竞技场排名信息单元
.arenaRankCell {
    rank 1 : integer 		    #排名
    uid 2 : integer 		    #玩家ID
    name 3 : string 		    #玩家名称
    head 4 : integer 		    #玩家头像
    lv 5 : integer 		        #玩家等级
    border 6 : integer          #边框
    guildid 7 : integer 		#玩家联盟ID
    guildshort 8 : string 		#玩家联盟简称
    guildname 9 : string 		#玩家联盟名称
    goupId 10 : integer          #robot配置ID
}

#竞技场每日排名信息
.arenaMultiRank {
    day 0 : integer 		    #日期
    round 1 : integer 		    #轮次
    ranks 2 : *arenaRankCell(rank) #每日排名信息
    iRank 3 : integer 		    #我的排名
}
]]

arenaproto.c2s = arenaproto.type .. [[
#竞技场 1801~ 1850

#竞技场请求玩家信息
reqArenaUserInfo 1801 {
	response {
		code 0 : integer            #错误码
		challengeTime 1 : integer   #挑战刷新时间
		challenge 2 : integer       #挑战次数
		maxRank 3 : integer         #最高排名
		curRank 4 : integer         #当前排名
		lineupDef 5 : *arenalineup(idx) #防守阵容
		lineupAtk 6 : *arenalineup(idx) #进攻阵容
        totalPower 7 : integer      #阵容总战力
        mainHeroId 8 : integer      #最高战力英雄ID
        taskInfo 9 : *integer       #已领取的任务
	}
}

#竞技场请求刷新挑战列表
reqArenaRefresh 1802 {
	request {
	}
	response {
		code 0 : integer
        challenges 1 : *arenaChallengeCell(idx) #5名挑战对手
	}
}

#竞技场更新防守阵容
reqArenaUpdateLineupDef 1803 {
	request {
	    lineup 0 : *arenalineup(idx)      #阵容
	}
	response {
		code 0 : integer                  #错误码
		lineup 1 : *arenalineup(idx)      #阵容
		totalPower 2 : integer      #阵容总战力
        mainHeroId 3 : integer      #最高战力英雄ID
	}
}

#竞技场挑战
reqArenaChallenge 1804 {
	request {
	    idx 0 : integer 		          #挑战的坑位
	    rank 1 : integer                  #挑战的排名
	    uid 2 : integer                   #挑战的玩家ID 0=机器人 >0=玩家ID
	    lineupVs 3 : *arenalineup(idx)    #挑战的玩家阵容(挑战机器人、强制挑时可不传)
	    force 4 : boolean                 #是否强制挑战
	    lineup 5 : *arenalineup(idx)      #进攻阵容
	    isView 6 : boolean                #是否观看
	}
	response {
		code 0 : integer
		lineup 1 : *arenalineup(idx)      #进攻阵容
		rank 2 : integer                  #挑战的排名
        reward 3 : rewardlib              #挑战奖励
        challengeInfo 4 : arenaChallengeCell  #挑战对手信息
        lineupDef 5 : *arenalineup(idx)   #自己的防守阵容 如果next(lineupDef)则替换防守阵容
        isWin 6 : boolean                 #是否胜利
        report 7 : battleReportBrief      #战报
        challengeTime 8 : integer         #挑战刷新时间
		challenge 9 : integer             #挑战次数
		maxRank 10 : integer              #最高排名
		curRank 11 : integer              #当前排名
		totalPower 12 : integer           #阵容总战力
		mainHeroId 13 : integer           #最高战力英雄ID
	}
}

#领取任务奖励
reqArenaTaskReward 1806 {
    request {
	    taskId 0 : integer                #任务ID
	}
	response {
		code 0 : integer
		taskId 1 : integer                #任务ID
		reward 2 : rewardlib              #奖励
	}
}

#获取当前排名信息
reqArenaCurRankInfo 1808 {
	response {
		code 0 : integer
		curRanks 1 : *arenaChallengeCell(rank)
		iRank 2 : integer
	}
}

#获取每日排名信息
reqarenaDayRankInfo 1809 {
	response {
		code 0 : integer
		dayRanks 1 : *arenaMultiRank
	}
}

#获取历史排名信息
reqArenaHisRankInfo 1810 {
	response {
		code 0 : integer
		hisRanks 1 : *arenaMultiRank
	}
}

#获取全部简要战报信息
reqArenaBriefReports 1811 {
	response {
		code 0 : integer
		reports 1 : *battleReportBrief
	}
}

#获取战报回放详细信息
reqArenaDetailReport 1812 {
    request {
	    id 0 : integer                #战报ID
	}
	response {
		code 0 : integer
		id 1 : integer                #战报ID
		report 2 : battleReport       #战报详情
	}
}

#查看战报
reqArenaViewReport 1813 {
    request {
	    ids 0 : *integer                #战报IDs
	}
	response {
		code 0 : integer
		ids 1 : *integer                #战报IDs
	}
}

#查看挑战对手信息
reqArenaRankInfo 1814 {
	request {
	    rank 0 : integer                  #挑战的排名
	}
	response {
		code 0 : integer
        challengeInfo 1 : arenaChallengeCell  #挑战对手信息
	}
}

#一键已读战报
reqArenaViewReportOneKey 1815 {
	response {
		code 0 : integer
	}
}
]]

arenaproto.s2c = arenaproto.type .. [[
#竞技场 1801~ 1850

#被打败更新排名
notifyDefeatRank 1850 {
	request {
	    curRank 1 : integer
	    report 2 : battleReportBrief      #战报
	}
}

#同步战力
notifytotalPower 1851 {
	request {
	    totalPower 1 : integer
	    mainHeroIdMax 2 : integer
	    lineupDef 3 : *arenalineup(idx) #防守阵容
	}
}
]]

return arenaproto