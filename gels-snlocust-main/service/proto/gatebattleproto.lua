local gatebattleproto = {}

gatebattleproto.type = [[

]]

gatebattleproto.c2s = gatebattleproto.type .. [[
#战斗服网关 2201-2300

#请求登录战斗服
reqBattleLogin 2201 {
     request {
		uid 0 : integer             #玩家ID
		serverid 1 : integer        #服务器ID
		version 2 : integer         #登录连接版本号
	}
	response {
		code 0 : integer            #错误码
		subid 1 : integer           #连接ID
	}
}

#请求战斗服心跳
reqBattleHeartbeat 2202 {
    request {
	}
}

#加入一场战斗
reqJoinBattle 2203 {
     request {
		uid 0 : integer             #错误码
		battleId 1 : integer        #战场ID
	}
	response {
		code 0 : integer            #错误码
	}
}
]]

gatebattleproto.s2c = gatebattleproto.type .. [[
#战斗服网关 2201-2300

]]

return gatebattleproto