local queueproto = {}

queueproto.type = [[
.queueOtherInfo {#队列其他信息
    baseSpeed 1 : integer #[建筑矿]基础采集速度
    buffSpeed 2 : integer #[建筑矿]buff加成采集速度
    hasCollNum 3 : integer #[建筑矿]已经采集的量
    buffCollNum 4 : integer #[建筑矿]buff已经采集的量
    totalCollNum 5 : integer #[建筑矿]采集的总量(负重)
    statusStartTime 6 : integer #[建筑矿]采集状态开始时间
    statusEndTime 7 : integer #[建筑矿]采集状态结束时间
}

.queuePathCell {#队列行军路线分割路径
    x 0 : integer #x
    y 1 : integer #y
    railway 2 : boolean #true=到下个点坐火车 false=到下个点步行,
    cost 3 : integer #花费的时间
    arriveTime 4 : integer #抵达时间
    startTime 5 : integer  #火车发车时间
}

.queueMoveTimeSpan {#队列行军路线分割
    path 0 : *queuePathCell #队列行军路线分割路径
}

#队列信息(简要信息, 若是他人队列, 则用此结构)
.queueInfoBrief {
	#####简要信息#####
	id 1 : string #队列ID
	uid 2 : integer #玩家ID
	aid 3 : integer #玩家联盟ID
	queueType 4 : integer #队列类型
	fromId 5 : integer #起始地地图对象ID
	fromX 6 : integer #起始地坐标X
	fromY 7 : integer #起始地坐标Y
	toId 8 : integer #目的地地图对象ID
	toX 9 : integer #目的地坐标X
	toY 10 : integer #目的地坐标Y
	toMapType 11 : integer #目的地地图对象类型
	status 12 : integer #状态
	statusStartTime 13 : integer #状态开始时间
	statusEndTime 14 : integer #状态结束时间
	statusEndTimeOri 15 : integer #状态结束时间(原始)
	moveTimeSpan 16 : queueMoveTimeSpan #行军路线分割
	lineup 17 : warlineup #出征阵容
	isReturn 18 : boolean #是否回城
	mainQid 19 : string #集结主队列ID
}

#队列信息(简要信息+详细信息, 若是自己队列, 则用此结构)
.queueInfo {
	#####简要信息#####
	id 1 : string #队列ID
	uid 2 : integer #玩家ID
	aid 3 : integer #玩家联盟ID
	queueType 4 : integer #队列类型
	fromId 5 : integer #起始地地图对象ID
	fromX 6 : integer #起始地坐标X
	fromY 7 : integer #起始地坐标Y
	toId 8 : integer #目的地地图对象ID
	toX 9 : integer #目的地坐标X
	toY 10 : integer #目的地坐标Y
	toMapType 11 : integer #目的地地图对象类型
	status 12 : integer #状态
	statusStartTime 13 : integer #状态开始时间
	statusEndTime 14 : integer #状态结束时间
	statusEndTimeOri 15 : integer #状态结束时间(原始)
	moveTimeSpan 16 : queueMoveTimeSpan #行军路线分割
	lineup 17 : warlineup #出征阵容
	isReturn 18 : boolean #是否回城
	mainQid 19 : string #集结主队列ID

	#####详细信息#####
	toSubMapType 20 : integer #目的地地图对象子类型
	toGroupId 21 : integer #目的地地图对象分组ID
	toUid 22 : integer #目的地玩家ID
	toLevel 23 : integer #目的地地图对象子类型
	createTime 24 : integer #创建时间
	otherInfo 25 : queueOtherInfo #其他信息
	code 26 : integer #错误码
	buildType 27 : integer #建造类型
	nextPlan 28 : integer #下一个车站的计划: 重新寻路=1, 召回=2
}

#队列信息(简要信息+少量详细信息+拓展信息, 若是外交所/战争大厅的队列信息, 则用此结构)
.queueInfoBriefEx {
	#####简要信息#####
	id 1 : string #队列ID
	uid 2 : integer #玩家ID
	aid 3 : integer #玩家联盟ID
	queueType 4 : integer #队列类型
	fromId 5 : integer #起始地地图对象ID
	fromX 6 : integer #起始地坐标X
	fromY 7 : integer #起始地坐标Y
	toId 8 : integer #目的地地图对象ID
	toX 9 : integer #目的地坐标X
	toY 10 : integer #目的地坐标Y
	toMapType 11 : integer #目的地地图对象类型
	status 12 : integer #状态
	statusStartTime 13 : integer #状态开始时间
	statusEndTime 14 : integer #状态结束时间
	statusEndTimeOri 15 : integer #状态结束时间(原始)
	moveTimeSpan 16 : queueMoveTimeSpan #行军路线分割
	lineup 17 : warlineup #出征阵容
	isReturn 18 : boolean #是否回城
	mainQid 19 : string #集结主队列ID

	#####详细信息#####
	toSubMapType 20 : integer #目的地地图对象子类型
	toLevel 21 : integer        #目的地地图对象子类型
	createTime 22 : integer #创建时间

	#####拓展信息#####
	head 23 : integer 		#玩家头像
	border 24 : integer 	#玩家头像框
	name 25 : string 		#玩家名字
	guildshort 26 : string 	#玩家联盟简称
	toName 27 : string 		#玩家名字
	toGuildshort 28 : string #玩家联盟简称
}

.queueInfoEx {#队列信息ex
    id 0 : string           #队列ID
	playerid 1 : integer 	#玩家ID
	name 2 : string 		#玩家名字
	head 3 : integer 		#玩家头像
	border 4 : integer 		#玩家头像
	sex 5 : integer 		#玩家头像
	guildid 6 : integer 		#玩家联盟ID
	guildshort 7 : string 	    #玩家联盟简称
	guildname 8 : string 	    #玩家联盟名称
	serverid 9 : integer 		#玩家服务器ID
	spoils 10 : rewardlib 		#战利品
}

.stayInQueueInfo {#驻扎队列信息
    id 0 : string           #队列ID
	uid 1 : integer 		#玩家ID
	name 2 : string 		#玩家名字
	head 3 : integer 		#玩家头像
	guildid 4 : integer 	#玩家联盟ID
	guildshort 5 : string 	#玩家联盟简称
	guildname 6 : string 	#玩家联盟名称
    lineup 7 : warlineup    #出征阵容
}

.bossRewardCell {#打boss已领奖次数
	subtype 0 : integer 	#boss子类型
	num 1 : integer 		#已领奖次数
}

]]

queueproto.c2s = queueproto.type .. [[
#队列 2101~ 2300

#请求设置队列阵容预设
reqUpdateLineupSet 2101 {
	request {
		lineup 0 : warlineup #出征阵容
	}
	response {
		code 0 : integer
		lineup 1 : warlineup #出征阵容
	}
}

#请求队列阵容预设信息
reqLineupSetInfo 2102 {
	request {
	}
	response {
		code 0 : integer
		lineupSet 1 : *warlineup(idx) #出征阵容
	}
}

#请求创建行军队列
reqMarch 2103 {
	request {
		queueType 0 : integer  #队列类型
		toId 1 : integer  #目标对象ID
		toX 2 : integer   #目标对象坐标X
		toY 3 : integer   #目标对象坐标Y
		toMapType 4 : integer  #目标对象类型
		lineup 5 : warlineup   #出征阵容
		massTime 6 : integer   #集结时间, 创建集结主队列时传之
		mainQid 7 : string     #集结主队列ID, 创建集结子队列时传之
		mainQueueType 8 : integer #集结主队列类型, 创建集结子队列时传之
		taskID 9 : integer     #雷达打怪任务ID
		buildType 10 : integer     #建造类型
	}
	response {
		code 0 : integer  #错误码
		queue 1 : queueInfo #队列信息
	}
}

#请求自己的行军队列信息
reqMarchInfo 2104 {
	request {
	}
	response {
		code 0 : integer  #错误码
		queues 1 : *queueInfo(id) #队列信息(详细信息)
		monsterLv 2 : integer     #击杀怪物最高等级
		bossReward 3 : *bossRewardCell(subtype)
	}
}

#请求视野内队列信息
reqViewMarch 2105 {
	request {
		serverid 0 : integer  #服务器id
		x 1 : integer  #中心点X
		y 2 : integer  #中心点Y
		radius 3 : integer  #直径
	}
	response {
		code 0 : integer
		serverid 1 : integer  #服务器id
		lv 2 : integer  #地图缩放等级
		addQueues 3 : *queueInfoBrief(id)	 #九宫格-队列信息(简要信息)
		delQueues 4 : *string  #移除的队列ID
	}
}

#请求离开队列视野
reqLeaveViewMarch 2106 {
	
}

#请求加速队列
reqSpeedQueue 2107 {
	request {
		qid 0 : string  #队列ID
		itemID 1 : integer  #道具ID
		auto 2 : integer  #1=coin购买道具
	}
	response {
		code 0 : integer
	}
}

#请求行军召回
reqRecallQueue 2108 {
	request {
		qid 0 : string  #队列ID
		skipMove 1 : boolean  #是否秒回
		auto 2 : integer      #是否自动购买道具
	}
	response {
		code 0 : integer
	}
}

#获取队列信息
reqQueueInfoEx 2110 {
	request {
		qids 0 : *string          #队列ID
	}
	response {
		code 0 : integer		#错误码
		data 1 : *queueInfoEx(id)    #队列信息ex
	}
}

#雷达请求获得一个地图空闲点
reqSpaceRadar 2111 {
	request {
		taskID 0 : integer #雷达打怪任务ID
	}
	response {
		code 0 : integer
		x 1 : integer 		#空闲点x坐标
		y 2 : integer 		#空闲点y坐标
		objid 3 : integer 	#地图对象ID
	}
}

#获取目标是玩家的队列
reqToPlayerQueue 2112 {
	response {
		code 0 : integer		#错误码
		helpCityQueue 1 : *queueInfoBriefEx(id)     #[外交所]帮助我的城堡的队列信息
		helpOtherQueue 2 : *queueInfoBriefEx(id)    #[外交所]帮助我的非城堡的队列信息
		enemyQueue 3 : *queueInfoBriefEx(id)        #[战争大厅]攻击我的联盟成员的队列信息
		attakQueue 4 : *queueInfoBriefEx(id)        #[战争大厅]我的联盟成员的攻击队列信息
	}
}

#查看自己/已侦查的地图对象的驻扎队列信息
reqStayInQueue 2113 {
    request {
		objid 0 : integer   #地图对象ID
	    idx1 1 : integer    #开始索引
	    idx2 2 : integer    #结束索引
	}
	response {
		code 0 : integer     #错误码
		objid 1 : integer   #地图对象ID
		idx1 2 : integer     #开始索引
	    idx2 3 : integer     #结束索引
	    idxMax 4 : integer   #最大索引
	    totalNum 5 : integer #士兵总数
		queues 6 : *stayInQueueInfo
		wqueues 7 : *stayInQueueInfo #城墙守军(侦查玩家城堡)
		npcArmy 8 : *npclineup #npc守军(侦查资源田、碉堡)
	}
}
]]

queueproto.s2c = queueproto.type .. [[
#队列 2101~ 2300

#更新视野内队列
updateViewQueue 2300 {
	request {
		queue 0 : queueInfoBrief		#队列信息(全量简要信息)
	}
}

#删除视野内队列
removeViewQueue 2299 {
	request {
		id 0 : string			#队列ID
	}
}

#更新视野内队列
updateViewQueueLittle 2298 {
	request {
		queue 0 : queueInfoBrief		#队列信息(增量简要信息)
	}
}


#更新自己队列
updateQueue 2297 {
	request {
		queue 0 : queueInfo		#队列信息(全量详细信息)
	}
}

#删除自己队列
removeQueue 2296 {
	request {
		id 0 : string			#队列ID
	}
}

#更新自己队列
updateQueueLittle 2295 {
	request {
		queue 0 : queueInfo		#队列信息(增量详细信息)
	}
}

#更新杀怪最高等级
updateMonsterLv 2294 {
	request {
		monsterLv 0 : integer    #击杀怪物最高等级
	}
}

#更新出征阵容信息
notifyLineup 2293 {
	request {
		lineup 0 : warlineup     #出征阵容
	}
}

#更新出征阵容信息
notifyToPlayerQueue 2292 {
	request {
	    helpCityQueue 0 : *queueInfoBriefEx(id)     #[外交所]帮助我的城堡的队列信息, 推{id=id}表示删除
		helpOtherQueue 1 : *queueInfoBriefEx(id)    #[外交所]帮助我的非城堡的队列信息, 推{id=id}表示删除
		enemyQueue 2 : *queueInfoBriefEx(id)        #[战争大厅]攻击我的联盟成员的队列信息, 推{id=id}表示删除
		attakQueue 3 : *queueInfoBriefEx(id)        #[战争大厅]我的联盟成员的攻击队列信息, 推{id=id}表示删除
	}
}

#更新打boss奖励限制
notifyBossRewardCell 2291 {
    request {
		cell 0 : bossRewardCell
	}
}
]]

return queueproto