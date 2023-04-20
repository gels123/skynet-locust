local worldproto = {}

worldproto.type = [[
.gsdata {
	opentime 2 : integer   	#开服时间
	kinggsname 5 : string 	#国王联盟缩写
	kinggname 6 : string 	#国王联盟名字
	kingname 7 : string 	#国王名字
	kingstage 8 : integer 	#国王状态 nil 争夺中  1 npc  2玩家
	kinghead 9 : integer 	#国王头像
}
.gameserver {#
	serverid 0 : integer
	name 1 : string 		#名字
	status 3 : boolean 		#是否维护
	trailnotice 4 : string  #预告
	data 5 : gsdata 		#服务器数据
}
]]

worldproto.c2s = worldproto.type .. [[
#世界 4401 ～ 4500
reqgameserverlist 4401 {#请求服务器列表

}

migrategameserver 4402 {#迁移服务器
	request {
		serverid 0 : integer 	#服务器id
		auto 1 : boolean 		#是否自动购买
	}
}

]]


worldproto.s2c = worldproto.type .. [[
#世界 4401 ～ 4500
retgameserverlist 4451 {#返回服务器列表
	request {
		list 0 : *gameserver
	}
}

retmigrategameserver 4452 {#迁移服务器返回
	request {
		serverid 0 : integer 	#服务器id
		code 1 : integer 		#返回码
		auto 2 : boolean 		#是否自动购买
	}
}

]]

return worldproto