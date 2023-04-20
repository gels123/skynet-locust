local activityproto = {}

activityproto.type = [[
#活动时间队列单元
.activityTimeCell {
    status 0 : integer 		    #活动状态
    startTime 1 : integer 		#活动开始时间
    endTime 2 : integer 		#活动开始时间
}

#活动信息单元
.activityInfoCell {
    activityId 0 : integer      #活动ID
    skinId 1 : integer 		    #换皮ID
    round 2 : integer 		    #轮次ID/签到次数
    status 3 : integer 		    #活动状态
    queue 4 : *activityTimeCell(status) #活动时间队列
    more 5 : string 			#更多信息
    redDot 6 : integer 		    #红点
}

.ex_sevendays {
    exlimit 0: integer
    id 1 :integer
}
]]

activityproto.c2s = activityproto.type .. [[
#活动activity 1701-1800

#请求获取活动信息
reqGetActivityInfo 1701 {
	response {
		code 0 : integer
		infos 1 : *activityInfoCell(activityId) #活动信息
	}
}

#请求签到
reqSignin 1702 {
	response {
		code 0 : integer
        signinid 1:integer #signid配置id
		signtime 2 :integer 
	}
}
#登录请求签到消息
reqSigninInfo 1703 {
	response {
		code 0 : integer
        signinid 1:integer #signid配置id
        signtime 2 :integer 
	}
}

#请求七日兑换消息
reqSevendayInfo 1704 {
	response {
		code 0 : integer
        exlist 1:*integer
        exendtime 2:integer
	}
}
#七日获得兑换
reqSevendayexItem 1705 {
request {
	id 0 : integer #兑换id
	}
	response {
		code 0 : integer
        exlist 1:ex_sevendays 
	}
}

#活动页签红点
reqactRedPoint 1706 {
request {
	id 0 : integer #活动id
	}
	response {
		code 0 : integer
	}
}

]]

activityproto.s2c = activityproto.type .. [[
#活动activity 1701-1800

#更新活动信息
updateActivityInfo 1751 {
	request {
	    info 0 : activityInfoCell #活动信息
	}
}
]]

return activityproto