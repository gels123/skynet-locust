local shopproto = {}

shopproto.type = [[

]]

shopproto.c2s = shopproto.type .. [[
#场景 1001 ～ 1100
reqplayershop 1001 {
    response {

    }
}

shopbuy 1005 {#商城购买
    request {
        id 0 : integer          #配置id
        num 1 : integer         #数量
    }
    response {
        code 2 : integer        #返回码
        id 0 : integer          #配置id
        num 1 : integer         #数量
    }
}
vipshopbuy 1006 {#vip商店购买
    request {
        id 0 : integer          #配置id
        num 1 : integer         #数量
    }
    response {
        code 2 : integer        #返回码
        id 0 : integer          #配置id
        num 1 : integer         #数量
    }
}
]]


shopproto.s2c = shopproto.type .. [[


.buytimes {#购买次数
    key 0 : integer     #商品key
    times 1 : integer   #已购买次数
}

.shopbuytimes {#商店购买次数
    info 0 : *buytimes
    type 1 : integer        #商店类型
}


updateshopbuytimes 1051 {#更新商店限购商品已购买次数
    request {
        info 0 : buytimes
        type 1 : integer        #商店类型
    }
}


syncshopbuytimes 1052 {#同步商店限购商品已购买次数
    request {
        shoptimes 0 : *shopbuytimes     #商店购买次数
    }
}
]]

return shopproto