local systemproto = {}

systemproto.c2s = [[
# 登录 1 ~ 50
login 2 {
	request {  
		token 0 : string		# encryped token
        did 1 : string          #设备id
        channel_id 2 : string   #渠道id
        datetime 3 : integer    #时间
        sign 4 : string         #验证码
        model 5 : string        #机型
        memory 6 : string       #内存容量
        country 7 : string      #国家
        distinctId 8 : string   #访客ID
        version 9 : string      #版本号
	}
    response {
        code 0 : integer        #返回码 5还未创建角色
        hasCity 1 : boolean     #是否有城堡
	}
}

back 3 {
	request {  
		token 0 : string		# encryped token
        did 1 : string          #设备id
        channel_id 2 : string   #渠道id
        model 3 : string        #机型
        memory 4 : string       #内存容量
        country 5 : string      #国家
	}
    response {
        code 0 : integer        #返回码
	}
}

createrole 5 {#创建角色
    request {
        roleid 0 : integer      #默认角色id
        name 1 : string         #名字
    }
    response {
        code 0 : integer        #返回码
        roleid 1 : integer      #默认角色id
        name 2 : string         #名字
        hasCity 3 : boolean     #是否有城堡
    }
}

reqsysteminit 6 {#请求系统初始数据
    response {
        current 0 : integer     #当前系统时间
        gmt 1 : integer         #时区
        opensertime 2 : integer #开服时间
        server 3 : serverinfo   #服务器信息
        music 4 : boolean       #音乐
        sound 5 : boolean       #音效
        closepush 6 : *integer  #关闭的推送类型 0代表总类型
        createtime 7 : integer  #创角时间
    }
}

keepalive 7 {#心跳包
    response {
        current 0 : integer     #当前系统时间
    }
}

entergameok 8 {#客户端登录游戏完成
    response {
        code 0 : integer        #返回码
        time 1 : integer        #当前时间
    }
}

logout 9 {#登出
    response {
        code 0 : integer        #返回码
    }
}

pushsetting 12 {#推送设置
    request {
        closetype 0 : *integer   #关闭的推送类型 0代表总类型
    }
    response {
        code 0 : integer
        closetype 1 : *integer   #关闭的推送类型 0代表总类型
    }
}

reqserverdebug 14 {#请求服务器debug状态
    
}

gmcommand 15 { #GM命令
    request {
        content 0 : string      #内容
    }
    response {
        code    0 : integer        #返回码
        content 1 : string      #内容
    }
}

bindaccount 24 {#绑定账号
    request {
        platform 0 : string         #平台
        signture 1 : string         #密匙
        email 2 : string            #邮箱
    }
    response {
        code 0 : integer        #返回码
    }
}

]]

systemproto.s2c = [[

dayrefresh 16 {#每日刷新时间通知
    request {
        time 0 : integer    #linux时间戳
    }
}

reconnectkickout 17 {#重连被t
    request {
         
    }
}

syncserverdebug 18 {#同步服务器DEBUG状态
    request {
        debug 0 : boolean   #
    }
}
]]

return systemproto