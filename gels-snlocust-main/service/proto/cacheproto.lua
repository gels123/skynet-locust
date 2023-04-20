local cacheproto = {}

cacheproto.type = [[
]]

cacheproto.c2s = cacheproto.type .. [[
#缓存信息 1201 ～ 1300
reqplayerstatistics 1201 {#请求统计信息
    response {
        info 0 : *statistics
        closeconfirm 1 : string #关闭的二次弹窗json
    }
}

saveguideinfo 1202 {#记录已完成新手引导步骤
    request {        
        info    0 : string  #步骤信息 - 客户端负责内容
        type  1 : string #新手引导线类型
        id  2 : integer #新手引导步骤
    }
    response {
        code    0 : integer #返回码
    }
}

requestguideinfo 1203 {#申请新手引导信息    
    response {  
        info    1 : string  #记录的改模块引导信息
        closeconfirm 2 : string #关闭的二次弹窗json
    }
}

reqclientstatistics 1206 {
    response {
        type 0 : *integer           #
    }
}

openclientstatistics 1207 {
    request {
        type 0 : *integer           #
    }
    response {
        type 0 : *integer           #
    }
}

resetcloseconfirm 1208 {#设置关闭的二次确认弹窗
    request {
        closeconfirm 0 : string   #关闭的二次弹窗json
    }
    response {
        code 0 : integer            #返回码
        closeconfirm 1 : string   #关闭的二次弹窗json
    }
}

resetclosetip 1209 {#设置关闭的提示
    request {
        closetip 0 : *integer       #关闭的提示
    }
    response {
        code 0 : integer            #返回码
        closetip 1 : *integer       #关闭的提示
    }
}

getWeather 1210 {#获取天气
    response {
        weather 1 : integer     #天气: 1晴天 2雨天
    }
}
]]


cacheproto.s2c = cacheproto.type .. [[
#缓存信息 1201 ～ 1300
syncdaytime 1251 {#同步当前时间ID
    request {
        daytimeid 0 : integer       #天气ID
    }
}

syncclientstatistics 1253 {
    request {
        type 0 : integer           #
    }
}

syncWeather 1254 {#推送天气
    request {
        weather 1 : integer     #天气: 1晴天 2雨天
    }
}
]]

return cacheproto