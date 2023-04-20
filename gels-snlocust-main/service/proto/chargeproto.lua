local chargeproto = {}

chargeproto.type = [[
.chargegoods {
	type 0 : integer 		#类型对应type_nocountry字段
	begintime 1 : integer 	#开发起始时间 nil表示全天开启
	overtime 2 : integer 	#结束时间
}
.limitgift {#限时礼包
	type 0 : integer   		#类型对应type_nocountry字段
	expiretime 1 : integer 	#失效时间
}
.giftgroup {#礼包组合数据
	cfg 0 : string 			#配置表
	id 1 : string 			#充值id
	index 2 : integer 		#组合位置
}
]]

chargeproto.c2s = chargeproto.type .. [[
#充值4001～4100
reqplayercharge 4001 {#请求充值数据
	request {
		
	}
	response {
		freetype 0 : *integer 		#已领取的免费等级礼包 类型对应type_nocountry字段
		lgift 1 : *limitgift 		#限时礼包
		group 3 : *giftgroup 		#充值组合数据
		historyreward 5 : *integer 	#已领取的累积充值奖励
		lvjijin 6 : *integer 		#已领取的等级基金
	}
}

receivedailyfree 4002 {#领取每日免费特惠礼包
	response {
		code 0 : integer	 #返回码
		reward 1 : rewardlib #奖励数据
	}
}

receivemonthcard 4003 {#领取月卡奖励
	response {
		code 0 : integer	 #返回码
		reward 1 : rewardlib #奖励数据
	}
}

receivelevelfree 4004 {#领取免费等级礼包
	request {
		type 0 : integer 		#类型对应type_nocountry字段
	}
	response {
		code 0 : integer 		#返回码
		type 1 : integer 		#类型对应type_nocountry字段
		reward 2 : rewardlib 	#奖励
		freetype 3 : *integer
	}
}

receiveprivilegecard 4005 {#领取月卡奖励
	response {
		code 0 : integer	 #返回码
		reward 1 : rewardlib #奖励数据
	}
}

useprivilegeskill 4006 {#使用特权技能
	request {
		skillid 0 : integer 
	}
	response {
		code 0 : integer        #返回码
        reward 1 : rewardlib    #扫荡技能奖励
        skillid 2 : integer 
	}
}

closevipchargered 4007 {#关闭vip充值红点
	response {
		vipchargered 2 : boolean 	#vip充值红点
	}
}

resetgroupgift 4008 {#设置礼包组合
	request {
		cfg 0 : string 			#配置表
		id 1 : string 			#充值id
		index 2 : integer 		#组合位置
	}
	response {
		code 0 : integer
		newgroup 1 : giftgroup 	#新的礼包组合数据
	}
}

resethidepay 4009 {#设置隐藏
	request {
		hide 0 : boolean
	}
	response {
		code 0 : integer
		hide 1 : boolean
	}
}

historychargereward 4010 {#领取累积充值奖励
	request {
		id 0 : integer
	}
	response {
		code 0 : integer
		id 1 : integer
		reward 2 : rewardlib
		historyreward 5 : *integer 	#已领取的累积充值奖励
	}
}

receivejijinreward 4011 {#领取等级基金
	request {
		id 0 : integer
	}
	response {
		code 0 : integer
		id 1 : integer
		reward 2 : rewardlib
		lvjijin 3 : *integer 		#已领取的等级基金
	}
}

]]


chargeproto.s2c = chargeproto.type .. [[
#充值4001～4100
.monthcard {
	expire 0 : integer				#过期时间 nil代表没有激活
	reward 1 : boolean				#今日奖励是否已领取
}
.privilegecard {
	expire 0 : integer				#过期时间 nil代表没有激活
	reward 1 : boolean				#今日奖励是否已领取
	skill 2 : *integer 				#今日已使用的技能
}

.chargegoodsbuy {#商品购买数据
	type 0 : integer 		#类型对应type_nocountry字段
	buy 3 : integer 		#已经购买次数
}
syncplayercharge 4051 {#同步充值数据
	request {
		priority 0 : *integer		#已首充的档
		firstcharge 1 : integer		#type_nocountry字段
		dailyfree 3 : boolean		#是否有每日免费礼包可领取
		month 4 : monthcard			#月卡数据
		dailybuy 8 : *chargegoodsbuy #每日特惠充值购买数据
		discountbuy 9 : *chargegoodsbuy #超值礼包购买数据
		commend 10 : *chargegoodsbuy 	#推荐礼包购买次数
		privilege 11 : privilegecard 	#特权卡数据
		vipcharge 12 : *integer 	#已购买的vip礼包
		hero 13 : *chargegoodsbuy 	#英雄礼包购买次数
		history 14 : integer 		#累积充值
		jijin 15 : boolean 			#是否已购买基金数据
	}
}

syncchargereward 4052 {#同步充值奖励
	request {
		type 0 : integer
		reward 1 : rewardlib
		id 2 : string 		#充值id
	}
}

synclimitgift 4053 {#同步限时礼包
	request {
		gift 0 : *limitgift
	}
}

.dynamicicon {#动态图标
	type 0 : integer 				#
	subtype 1 : integer 			#对应type_nocountry字段
	endtime 2 : integer 			#结束时间
	lasttime 3 : integer 			#图标持续时间
}
syncchargeicon 4055 {#同步充值图标
	request {
		icon 6 : dynamicicon  		#动态图标
	}
}

syncchargeactivity 4056 {#同步充值活动数据
	request {
		daily 0 : *chargegoods		#每日特惠充值
		discount 1 : *chargegoods	#超值礼包数据
		dailybuy 2 : *chargegoodsbuy #每日特惠充值购买数据
		discountbuy 3 : *chargegoodsbuy #超值礼包购买数据
	}
}

.levelcharge {#可购买
	type 0 : integer 				#主类型
	overtime 1 : integer 			#结束时间
}
synclevelchargetime 4057 {#同步等级礼包时间
	request {
		level 0 : *levelcharge 		#可购买的等级礼包数据
	}
}
]]

return chargeproto