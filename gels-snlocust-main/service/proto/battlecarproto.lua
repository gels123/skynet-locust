local battlecarproto = {}

battlecarproto.type = [[

.carpartinfo {
    id 0 : integer  #car_accessories id
    cfgid 1:integer  #配置id
    level 2: integer  #level
    planid 3: *integer  #组别号
	islocked 4:integer	#锁定
	attrlist 5 :*integer #额外属性
	isnew 6 :integer #is new

}

.carparttype {
    cfgid 0:integer  #配置id
}

]]


battlecarproto.c2s = battlecarproto.type .. [[
#战车battlecar 2600-2700

#增加战车零件
reqaddcarpart 2601 {
    request {
	    cfgid 0:integer #car_accessories id
        level 1:integer #car_accessories lv
	}
	response {
		code 0 : integer
        id 1: integer
	}
}

#请求战车数据
reqbattleinfo 2602 {
	response {
		code 0 : integer #1 成功
        battlecarinfo 1 : *carpartinfo(id) #战车信息
		teamnum 2 : integer #编组数
		cfglist 3 : *carparttype(cfgid) #获得过的配件id
		bagsize 4 : integer #配件背包容量
		repairs 7: *integer #已经激活的 发道具id
	    repairunlock 8: boolean #是否已经解锁
	}
}

#编组
reqteameditor 2603 {
    request {
	    addid 0:integer #装备的零件id
        subid 1:integer #卸下的零件id
        planid 2:integer #编组号
	}
	response {
		code 0 : integer #1 成功
	}
}

#新增战车编组
requnlockteam 2605 {
	response {
		code 0 : integer #1 成功
		teamnum 1:integer #返回编组数
	}
}

#配件升级
reqpartuplv 2606 {
	request {
	    id 0:integer #装备的零件id
	}
	response {
		code 0 : integer #1 成功
		battlecarinfo 1 : carpartinfo(id) #战车信息
	}
}

#配件分解
reqpartbreakup 2607 {
	request {
	    partlist 0:*integer #装备的零件id
	}
	response {
		code 0 : integer #1 成功
		num 1:integer 	# 分解材料数
	}
}

#配件锁定
reqpartlock 2608{
	request {
	    ids 0:*integer #零件id
	}
	response {
		code 0 : integer #1 成功
	}
}

reqpowerinfo 2609{
	request {
	    planid 0:integer #分组数
	}
	response {
		code 0 : integer #1 成功
	}
}

#背包扩容
reqaddbagsize 2610{
	request {
	    coinnum 0:integer #电池数
	}
	response {
		code 0 : integer #1 成功
		bagsize 1 : integer #背包容量
	}
}

#处理红点
reqreddot 2611{
	request {
	    partlist 0:*integer #装备的零件id
	}
	response {
		code 0 : integer #1 成功
	}
}

#编组改名
reqteamname 2612{
	request {	
	    planid  0:integer
		planname 1:string
	}
	response {
		code 0 : integer #1 成功
	}
}

reqplaninfo 2613{
	response {
		code 0 : integer #1 成功
		planinfo 1:*string
	}
}
#激活
reqrepair 2614{
    request {
	    cfgid  0:integer #道具id
		idx 1:integer  #激活下标 1-5
	}
	response {
		code 0 : integer #1 成功
		repairinfo 1:*string
	}
}
#解锁
reqrepairunlock 2615{
	response {
		code 0 : integer #1 成功
	}
}

]]

battlecarproto.s2c = battlecarproto.type .. [[
#战车battlecar 2650-2700

#更新战车信息
notifyaddpart 2651 {
	request {
	    partlist 0 : *carpartinfo(id) #战车信息
	}
}
]]

return battlecarproto