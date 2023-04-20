local armyproto = {}

armyproto.type = [[
.armydata {
    type 0 : integer    #类型
    num 1 : integer     #数量
}

.injuredata {
    type 0 : integer    #类型
    num 1 : integer     #数量
}
]]

armyproto.c2s = armyproto.type .. [[
#部队 601 ～ 700
reqmyarmy 601 {#请求我的部队信息
    response {
        free 0 : *armydata(type)  #部队数据
    }
}

reqcurearmy 602 {#请求治疗/追加治疗
request { 
    injured 0 : *injuredata(type)        #类型
}
    response {
        injuredinfo 0: *injuredata(type) #伤兵
        totalcureinfo 1: *injuredata(type)  #请求的伤兵
        nextcurtime 2 : integer           #下次治疗完成时间
        finishtime 3: integer               #下次治疗完成时间
        needtime 4 : integer               #治疗需要时间
        code 5 : integer                      #返回码
    }
}

reqontimecure 603 {#定时治疗
    response {
        nextcurtime 1 : integer           #下次治疗完成时间 0 为治疗结束
        injuredinfo 2:*injuredata(type) #剩余伤兵数据
        cureinfo 3:*injuredata(type)    #治疗完成伤兵
        code 4 : integer                        #返回码
    }
}

reqinjuredinfo 604 {#登录请求伤兵信息
    response {
        finishtime 0: integer           #治疗完成时间
        injuredinfo 1: *injuredata(type) #伤兵
        curedinfo 2: *injuredata(type)  #治疗好的伤兵
        totalcureinfo 3: *injuredata(type)  #请求的伤兵
        nextcurtime 4 : integer           #下次治疗完成时间
        needtime 5 : integer               #治疗需要时间
        code 6 : integer                        #返回码
    }
}

reqstopcure 605 {#停止治疗
    response {
        foodnum 0: integer #返回资源数
        injuredinfo 1: *injuredata(type) #剩余总伤兵
        code 2 : integer       #返回码
    }
}

reqquickcure 606 {#快速治疗
request {
    quick 1 : boolean       #是否花电池立刻完成
    injured 2 : *injuredata(type)        #伤兵数据
}
    response {
        injuredinfo 0: *injuredata(type) #剩余总伤兵
        cureinfo 1:*injuredata(type)    #治疗完成伤兵
        quick 2 : boolean
        code 3 : integer                      #返回码
    }
}

reqspeedupcure 607 {#加速治疗
    request {
    itemid 1 : integer        #道具配置id
    itemnum 2 : integer    #数量
    auto 3 : boolean        #自动用金币补足
}
    response {
        injuredinfo 0: *injuredata(type) #剩余的治疗伤兵
        cureinfo 1:*injuredata(type)    #治疗完成伤兵
        nextcurtime 2 : integer           #下次治疗完成时间
        finishtime 3: integer           #治疗完成时间
        needtime 4 : integer               #治疗需要时间
        code 5 : integer                       #返回码
    }
}

reqcureall 608 {#全部完成
    response {
        injuredinfo 0: *injuredata(type)     #治疗完成伤兵
        nextcurtime 1 : integer                 #下次治疗完成时间
        finishtime 2: integer                     #治疗完成时间
        needtime 3 : integer                    #治疗需要时间
        code 4 : integer                           #返回码
    }
}

testcurefinish 609 {
request {
    injured 0:*injuredata(type)        #类型
}
    response {
        code 0:integer
    }
}

]]

armyproto.s2c = armyproto.type .. [[
#部队 601 ～ 700
updatefreearmy 651 {#同步闲置部队
    request {
        free 0 : *armydata(type)
    }
}

notifyinjuredinfo 652 {#战斗后同步伤兵
    request {
        injuredarmy 0: *injuredata(type) 
        nextcurtime 1: integer
    }
}

]]

return armyproto