local mapproto = {}

mapproto.type = [[
.mapcitydata {#玩家城堡
	uid 0 : integer 	    #玩家ID
	aid 1 : integer 	    #玩家联盟ID
	name 2 : string 		#玩家名字
	level 3 : integer       #玩家等级
	castlelv 4 : integer 	#城堡等级
	head 5 : integer 		#玩家头像
	border 6 : integer 		#玩家头像框
	skin 7 : integer 		#玩家皮肤
	abbr 8 : string 	    #玩家联盟简称
	aname 9 : string 	    #玩家联盟简称
	language 10 : integer 	#玩家语种/国旗
	shieldover 11 : integer #保护罩截止时间
	durability 12 : integer #城墙当前耐久
	wallst 13 : integer     #城墙是否恢复开始时间
	wallet 14 : integer     #城墙是否恢复截止时间
}

.mapmonsterdata {#怪物数据
	level 0 : integer		#野怪等级
	ownUid 1 : integer		#野怪归属
}

.mapbossdata {#boss数据
	level 0 : integer		#boss等级
}

.mapminedata {#资源数据
	level 0 : integer		#资源等级
	remain_num 1 : integer 	#资源剩余量
	uid 2 : integer 	    #玩家ID
	aid 3 : integer 	    #玩家联盟ID
}

.mapchestdata {#宝箱数据
	level 0 : integer		#宝箱等级
	ownUid 1 : integer		#宝箱归属
}

.mapbuildminedata {#建筑矿数据
	level 0 : integer		#建筑矿等级
	status 1 : integer		#建筑矿状态
	statusStartTime 2 : integer		#建筑矿状态开始时间
	statusEndTime 3 : integer		#建筑矿状态结束时间
	ownUid 4 : integer		#建筑矿归属UID
	ownAid 5 : integer		#建筑矿归属AID
	defenderCdTime 6 : integer #守军恢复截止时间
	cumuValue 7 : integer   #累积值(占领累积时间秒)
	groupId 8 : integer     #建筑矿分组ID
}

.mapfortressdata {#碉堡数据
	level 0 : integer		#碉堡等级
	status 1 : integer		#碉堡状态
	statusStartTime 2 : integer		#碉堡状态开始时间
	statusEndTime 3 : integer		#碉堡状态结束时间
	ownUid 4 : integer		#碉堡归属UID
	ownAid 5 : integer		#碉堡归属AID
	defenderCdTime 6 : integer #守军恢复截止时间
	cumuValue 7 : integer   #累积值(占领累积时间秒)
	groupId 8 : integer     #碉堡分组ID
	ownTime 9 : integer     #碉堡归属截止时间, 0表示永久拥有
}

.mapcheckpointdata {#关卡数据
	level 0 : integer		#等级
	status 1 : integer		#状态
	statusStartTime 2 : integer		#状态开始时间
	statusEndTime 3 : integer		#状态结束时间
	ownAid 5 : integer		#归属AID
}

.mapwharfdata {#码头数据
	level 0 : integer		#等级
	status 1 : integer		#状态
	statusStartTime 2 : integer		#状态开始时间
	statusEndTime 3 : integer		#状态结束时间
	ownAid 5 : integer		#归属AID
}

.mapmcitydata {#城市数据
	level 0 : integer		#等级
	status 1 : integer		#状态
	statusStartTime 2 : integer		#状态开始时间
	statusEndTime 3 : integer		#状态结束时间
	ownAid 5 : integer		#归属AID
}

.mapcommandpostdata {#帮派指挥所数据
	level 0 : integer		#等级
	status 1 : integer		#状态
	statusStartTime 2 : integer		#状态开始时间
	statusEndTime 3 : integer		#状态结束时间
	ownAid 5 : integer		#归属AID
}

.mapstationdata {#车站数据
	level 0 : integer		#等级
	status 1 : integer		#状态
	statusStartTime 2 : integer		#状态开始时间
	statusEndTime 3 : integer		#状态结束时间
	ownAid 5 : integer		#归属AID
}

.mapmilldata {#帮派磨坊
	level 0 : integer		#等级
	status 1 : integer		#状态
	statusStartTime 2 : integer		#状态开始时间
	statusEndTime 3 : integer		#状态结束时间
	ownAid 5 : integer		#归属AID
}

.mapobject {#地图对象
	objid 0 : integer 		#活物id
	type 1 : integer 		#活物类型 1玩家城堡 2野怪 4矿
	subtype 2 : integer 	#活物子类型
	x 3 : integer
	y 4 : integer

	#矿
	mine 5 : mapminedata
	#野怪
	monster 6 : mapmonsterdata
	#玩家主堡
	city 7 : mapcitydata
	#宝箱
	chest 8 : mapchestdata
	#建筑矿
	buildmine 9 : mapbuildminedata
	#碉堡
	fortress 10 : mapfortressdata
	#boss(精英怪)
	boss 11 : mapbossdata
	#关卡数据
	checkpoint 12 : mapcheckpointdata
	#码头数据
	wharf 13 : mapwharfdata
	#城市数据
	mcity 14 : mapmcitydata
	#帮派指挥所数据
	commandpost 15 : mapcommandpostdata
	#车站数据
	station 16 : mapstationdata
	#帮派磨坊
	mill 17 : mapmilldata
}

.gridmapobject {#九宫格-地图对象
	gridid 0 : integer   #九宫格ID
	objs 1 : *mapobject	 #地图对象数据
}

.mapobjectdetail {#地图对象详细信息
	score 0 : integer		#战力[玩家城堡]
	uid 1 : integer 		#占领者玩家ID[建筑矿]
	aid 2 : integer 		#占领者玩家联盟ID[建筑矿]
	name 3 : string 		#占领者玩家名字[建筑矿]
	head 4 : integer 		#占领者玩家头像[建筑矿]
	abbr 5 : string 	    #占领者玩家联盟简称[建筑矿]
	aname 6 : string 	    #占领者玩家联盟名称[建筑矿]
	ownName 7 : string 		#拥有者玩家名字[建筑矿]
	ownHead 8 : integer 	#拥有者玩家头像[建筑矿]
	ownAbbr 9 : string 	    #拥有者玩家联盟简称[建筑矿]
	ownAname 10 : string 	#拥有者玩家联盟名称[建筑矿]
	hp 11 : integer		    #剩余HP[野怪、宝箱]
	deadTime 12 : integer   #存活截止时间[野怪、建筑矿宝箱]
	build 13 : integer	    #是否有xx建筑[玩家城堡] 第1bit=是否有外交所
}

.mistqueuecell {#地图迷雾解锁时间队列单元
	chunckid 0 : integer	#块ID
	x 1 : integer		    #x
	y 2 : integer		    #y
	startTime 3 : integer	#开始时间
	endTime 4 : integer		#结束时间
}

.scoutqueuecell {#地图侦查时间队列单元
	objid 0 : integer	#块ID
	uid 1 : integer	    #玩家ID(仅侦查玩家城堡时)
	startTime 3 : integer	#开始时间
	endTime 4 : integer		#结束时间
	scoutEndTime 5 : integer #侦查权限截止时间[建筑矿]
	x 6 : integer		    #x
	y 7 : integer		    #y
}
]]

mapproto.c2s = mapproto.type .. [[
#地图 1901~ 2000

#请求地图信息
reqmapinfo 1901 {
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
		newgrids 3 : *gridmapobject	 #九宫格-地图对象
		delgrids 4 : *integer  #移除的九宫格ID
	}
}

reqmapleave 1902 {#离开地图

}

reqplayercity 1903 {#请求玩家地图信息
	response {
	    code 0 : integer
		mycity 1 : mapobject 		#玩家城池信息
		buildmines 2 : *mapobject(objid) #归属玩家的建筑矿信息
		citys 3 : *mapobject(objid) #归属玩家的城池信息
		zoneId 4 : integer          #出生区域
		zoneCdTime 5 : integer      #玩家更换出生区CD截止时间
		washout 6 : boolean         #是否废号移除
	}
}

#请求地图对象详细信息
reqmapobjectdetail 1904 {
	request {
		serverid 0 : integer  #服务器id
		objectid 1 : integer  #地图对象id
	}
	response {
		code 0 : integer
		serverid 1 : integer  #服务器id
		objectid 2 : integer  #地图对象id
		detail 3 : mapobjectdetail  #地图对象详细信息
	}
}

#请求迁城
reqmovecity 1905 {
	request {
		toserverid 0 : integer  #目标服务器ID
		movetype 1 : integer  #迁城类型, 见 mapcommon.move_type 定义
		x 2 : integer
		y 3 : integer
		auto 4 : integer  #1=coin购买道具
		zoneId 5 : integer  #新手换区随机迁城时传
	}
	response {
		code 0 : integer
		toserverid 1 : integer  #目标服务器ID
		movetype 2 : integer  #迁城类型, 见 mapcommon.move_type 定义
		x 3 : integer
		y 4 : integer
		zoneId 5 : integer  #新手换区随机迁城时传
	}
}

#请求所有收藏的坐标
reqcollection 1906 {
	request {
		colltype 0 : integer	#收藏类型: 见定义 mapcommon.collection_type
	}
	response {
		code 0 : integer
		colltype 1 : integer	#收藏类型: 见定义 mapcommon.collection_type
		collection 2 : *collectioninfo(id)
	}
}

#收藏/更新坐标
reqcoordcollection 1907 {
    request {
    	colltype 0 : integer	#收藏类型: 见定义 mapcommon.collection_type
    	x 1 : integer        	#x坐标
        y 2 : integer        	#y坐标
    	collmark 3 : integer	#收藏标注: 见定义 mapcommon.collection_mark
        name 4 : string         #收藏命名
        uid 5 : integer 		#玩家ID
       	more 6:  string			#更多信息json
    }
    response {
		code 0 : integer
		colltype 1 : integer	#收藏类型: 见定义 mapcommon.collection_type
		cell 2 : collectioninfo
	}
}

#删除收藏坐标
reqremovecollection 1909 {
	request {
		colltype 0 : integer	#收藏类型: 见定义 mapcommon.collection_type
		ids 1 : *integer 		#坐标ids
	}
	response {
		colltype 0 : integer	#收藏类型: 见定义 mapcommon.collection_type
		ids 1 : *integer 		#坐标ids
	}
}

reqsearchmap 1910 { #地图搜索
	request {
		type 0 : integer 		#活物类型 2野怪 4矿
		subtype 1 : integer
		level 2 : integer
	}
	response {
		code 0 : integer
		type 1 : integer 		#活物类型 2野怪 4矿
		subtype 2 : integer
		level 3 : integer 		#是否最后一只
		data 4 : *mappos 		#坐标数据
	}
}

reqgetmistinfo 1911 { #请求迷雾信息
	response {
		code 0 : integer
		mistInfo 1 : *integer   #迷雾信息
        mistQueue 2 : *mistqueuecell(chunckid)   #迷雾解锁队列信息
	}
}

reqopenmist 1912 { #请求开启迷雾
    request {
		x 0 : integer
		y 1 : integer
	}
	response {
		code 0 : integer
		queuecell 1 : mistqueuecell   #迷雾解锁队列信息
	}
}

#请求多个地图对象信息
reqmapobjsinfo 1913 {
	request {
		objids 1 : *integer  #中心点X
	}
	response {
		code 0 : integer
		objs 1 : *mapobject(objid)	 #地图对象数据
	}
}

#放弃已战力的地图对象
reqgiveupownedobj 1914 {
	request {
		objid 1 : integer  #对象ID
	}
	response {
		code 0 : integer
		objid 1 : integer  #对象ID
	}
}

#请求侦查队列信息
reqscoutqueue 1915 {
	response {
		code 0 : integer
        scoutQueue 2 : *scoutqueuecell(objid)
	}
}

#侦查
reqscout 1916 {
	request {
	    objid 0 : integer       #对象ID
		uid 1 : integer 		#玩家ID(仅侦查玩家城堡时)
	}
	response {
		code 0 : integer		#错误码
		queuecell 1 : scoutqueuecell   #侦查队列信息
	}
}

#取消侦查
reqcancelscout 1917 {
	request {
	    objid 0 : integer       #对象ID
	}
	response {
		code 0 : integer		#错误码
		objid 1 : integer       #对象ID
	}
}

#取消解锁迷雾
reqcancelopenmist 1918 {
	request {
	    x 0 : integer
		y 1 : integer
	}
	response {
		code 0 : integer		#错误码
		x 1 : integer
		y 2 : integer
	}
}

#清除废号移除字段
reqcleanwashout 1919 {
	response {
		code 0 : integer		#错误码
	}
}
]]


mapproto.s2c = mapproto.type .. [[
#地图 1901~ 2000

#更新地图对象数据
updatemapobject 1999 {
	request {
		gridid 0 : integer      #九宫格ID
		obj 1 : mapobject 		#活物数据
	}
}

#移除地图活物
removemapobject 1998 {
	request {
		gridid 0 : integer      #九宫格ID
		objid 1 : integer 		#活物id
		effect 2 : integer 		#特效 1城堡击飞特效
	}
}

#同步玩家地图城堡信息
syncplayercity 1997 {
	request {
		mycity 0 : mapobject    #玩家城池信息
	}
}

#同步玩家迷雾信息
syncopenmist 1996 {
    request {
        chunckpos 0 : *mappos   #块坐标信息
	}
}

#同步玩家侦查信息
syncscoutqueue 1995 {
    request {
        queuecell 0 : scoutqueuecell   #侦查队列信息
	}
}

#同步玩家获得建筑矿
syncgetbuildmines 1994 {
    request {
        cell 0 : mapobject #归属玩家的建筑矿信息
	}
}

#同步玩家失去建筑矿
synclostbuildmines 1993 {
    request {
        objid 0 : integer  #建筑矿id
	}
}

#同步玩家取消侦查
synccancelscout 1992 {
    request {
        objid 0 : integer  #侦查对象id
	}
}

#同步玩家出生区域
syncbornzoneid 1991 {
    request {
        zoneId 0 : integer          #出生区域
        zoneCdTime 1 : integer      #玩家更换出生区CD截止时间
	}
}
]]

return mapproto