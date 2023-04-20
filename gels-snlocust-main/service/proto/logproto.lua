local logproto = {}

logproto.type = [[
#玩家操作日志
.logopt {
    manipulate_type 0 : integer  #类型 1点击 2拖拽
    tap_pos_y 1 : integer  #点击x
    tap_pos_x 2 : integer  #点击y
    drag_distance 3 : integer  #拖拽距离
    Num 4 : integer  #次数
    button 5 : string  #控件
    scene 6 : integer  #场景id
    scene_id 7 : integer  #战斗、弹球场景id
    object_id 8 : integer  #活物id
}
]]

logproto.c2s = logproto.type .. [[
#数据日志 1281~ 1300

#请求上报中台数据日志
reqwritelog4zt 1281 {
	request {
        event_tag 0 : string #日志tag, 见gLogEventTagZt定义
        data 1 : string      #日志内容json
	}
}


#请求上报玩家操作日志
reqwritelogopt 1282 {
	request {
	    logs 0 : *logopt #日志
	}
}

]]

logproto.s2c = logproto.type .. [[
#数据日志 1281~ 1300

]]

return logproto