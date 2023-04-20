local taskproto = {}

taskproto.type = [[
.taskobj {
    type 0 : integer    #任务类型
    taskid 1 : integer  #任务id
    process 2 : integer #任务进度
    state 3 : integer   #任务状态
}

.taskkey {
    type 0 : integer    #任务类型
    taskid 1 : integer  #任务id
}
]]

taskproto.c2s = taskproto.type .. [[
#任务 501 ～ 600
reqtask 501 {#请求角色任务信息
    request {
        
    }
    response {
        tasks 0 : *taskobj          #任务列表
        chapter 1 : integer         #已完成章节 （+1为当前章节   如果配置找不到则完成所有章节）
        notice 2 : boolean          #通知进入新章节 
        develop 3 : *integer        #已完成的发展任务
        cachecastle 4 : integer     #缓存主堡等级，每日0点刷新
    }
}

receivetaskreward 502 {#领取任务奖励
    request {
        key 0 : taskkey     #
    }
    response {
        code 0 : integer    #
        key 1 : taskkey     #
        reward 2 : rewardlib    #奖励数据
    }
}

receivechapterreward 503 {#领取章节奖励
    request {

    }
    response {
        code 0 : integer    #返回码
        chapter 1 : integer #已完成章节
        reward 2 : rewardlib    #奖励数据
    }
}

overchaptershow 504 {#通知章节过场表现结束
    response {
        code 0 : integer
    }
}
]]


taskproto.s2c = taskproto.type .. [[
#任务 501 ～ 600
updatetask 551 {#同步任务数据变化
    request {
        tasks 0 : *taskobj       #
    }
}

receivedtask 552 {#领取到新任务
    request {
        tasks 0 : *taskobj       #
    }
}

deletetask 553 {#删除任务
    request {
        keys 0 : *taskkey       #任务key
    }
}

noticechapter 554 {#通知章节改变
    request {
        chapter 1 : integer #新章节 （+1为当前章节   如果配置找不到则完成所有章节）
    }
}

noticenewdevelop 555 {#通知新的已完成任务
    request {
        taskid 0 : integer
    }
}
]]

return taskproto