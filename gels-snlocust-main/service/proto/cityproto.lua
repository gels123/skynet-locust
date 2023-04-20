local cityproto = {}

cityproto.type = [[
.origin {#原点
    x 0 : integer           #x坐标
    y 1 : integer           #y坐标
}
.landobj {#地块上的活物
    objid 0 : integer       #活物ID
    pos 1 : origin          #坐标
    type 2 : integer        #活物类型
}
.unlockland {#解锁地块信息
    landid 0 : integer   #配置id
    state 1 : integer    #状态 0未解锁，1可解锁，2已解锁
}
.mistlist {#迷雾表
    mistid 0 : integer
    state 1 : integer    #状态 1非安全地块,2安全地块
}
.citywall {#边界墙表
    wallid 0 : integer
    state 1 : integer    #状态 1解锁
}
.wallinfo {#
    st 1:integer 
    et 2:integer
    dud 3:integer 
    fix 4:integer  
    fixst 5:integer  
    knocked 6:integer
}
.resource {#资源
    collecttime 0 : integer     #采集建筑 上一次采集时间点
}
.soldierinfo {#资源
    currenSoldierNum 0 : integer     #医院存储士兵信息
}
.material {#材料
    id 0 : integer              #生产的材料ID
    begintime 2 : integer       #开始生产时间，非生产中为nil
    overtime 3 : integer        #结束时间点
    totaltime 4  : integer      #生产总时间
    num 5 : integer             #生产的个数
}
.queue {
    queueid 0 : integer
    material 1 : *material
    totaltime 2  : integer      #总结束时间戳
    sumtime 3  : integer        #生产队列总时间
}
.make {#生产
    queue 1 : *queue(queueid)
    showid 2 : integer              #展示的材料ID
}
.train {
    traintype 0 : integer       #兵种类型
    trainnum 1 : integer        #数量
    trainovertime 2 : integer   #结束时间点
    trainbegintime 3 : integer  #开始时间点
    totaltime 4  : integer      #训练总时间
}
.radartask {
    taskid 0 : integer
    quality 1 : integer
    open 2 : boolean
    pos 3 : origin          #坐标
    index 4 : integer       #坐标对应的配置索引
}
.radar {
    tasklist 0 : *radartask         #刷出的任务列表
    exp 1 : integer                 #当前经验值
    breachlv 2 : integer            #当前的突破等级
}
.fence {
    num 1 : integer             #已有总数量
    curnum 2 : integer          #当前已抓捕数量
    catchnum 3 : integer        #总共抓捕数量
    sptime 4  : integer         #已加速的总时间
    catchbegin 5 : integer      #开始时间点
    totaltime 6  : integer      #抓捕总时间
}

.workdata {#非生产中为空表{}
    begintime 0 : integer       #开始生产时间
    overtime 1 : integer        #结束时间点
    totaltime 2  : integer      #生产总时间
    itemid 3 : integer          #工作台道具ID
    num 4 : integer             #生产的个数
}
.worker {
    workerid 0 : integer            #工人流水ID，建筑流水ID*1000 + 工人序号
    state 1 : integer               #0闲置，1工作中，2工作完成
    curid 2 : integer               #当前所在的建筑流水ID
    deskid 3 : integer              #素材建筑的工作台ID，工人不在素材厂时默认0
    workdata 4 : *workdata          #工作台工作数据，未生产为空表{}
    item 5 : *thingdata(cfgid)      #已完成可收取的道具  
    totaltime 6 : integer           #总结束时间戳
    sumtime 7 : integer             #生产队列总时间    
}
.workbench {
    index 0 : integer               #索引
    workid 1 : integer              #0当前没有工人，其他则表示工人ID
    isnew 2 : boolean               #是否新解锁
}

.brigadecell { #工程队工人信息单元
    level 0 : integer               #等级
    num 1 : integer                 #数量
    qids 2 : *string                #队列ids
}

.cityfacility {#设施信息
    id 0 : integer          #流水id
    type 1 : integer        #建筑类型
    level 2 : integer       #等级
    pos 3 : origin          #原点坐标
    isrepair 8 : boolean    #是否是通过修复建造的建筑
    extra 10 : integer       #装饰物id
    #资源
    resource 4 : resource   #资源
    #生产
    make 5 : make           #生产
    #兵营
    train 6 : train         #兵营
    #雷达
    radar 7 : radar         #雷达
    #医院
    soldierinfo 9 : soldierinfo #医院
    #预备役围栏
    fence 11 : fence        #预备役围栏
    #素材厂工作台数据
    workbench 12 : *workbench(index)
    isriot 13 : boolean     #是否暴动
    #工程队工人信息
    brigadeinfo 14 : *brigadecell(level)
}
.decor {
    type 0 : integer        #装饰物类型
    num 1 : integer         #总数量
    buildnum 2 : integer    #已建造的数量
}
.decordata {#装饰物信息
    id 0 : integer          #装饰物流水id
    type 1 : integer        #装饰物类型
    level 2 : integer       #等级
    protect 3:integer      #保护属性
    facilityid 4:integer    #建筑id
}
.techdata {#科技信息
    type 0:integer
    level 1:integer
    finishtime 2:integer
}
.decorbook {#装饰物图鉴
    type 0 : integer        #装饰物类型
}

.killobj {
    objid 0 : integer
}

.gatherthings {
    id 0 : integer          #建筑id
    thing 1 : *thingdata    #获得的道具
}


.ordertype {
    itemid 0 : integer     #订单索引
    num 1 :integer 
}
.orderitem{
    index 0:integer 
    order 1:*ordertype(itemid)
    refreshtime 2: integer #刷新时间
    rewardtype 3:integer
    rewardnum 4:integer
}
.handover{
    count 0:integer 
    handtime 1:integer 
    redeem 2:integer #兑奖次数
    redeemtime 3:integer #上次兑奖时间
    castlelevel 4:integer #当日主堡等级
}

]]

cityproto.c2s = cityproto.type .. [[
#城建 301 ～ 400
reqmycity 301 {#请求城建信息
    response {
        facility 0 : *cityfacility(id)  #设施信息
        land 1 : *unlockland(landid)    #地块信息
        cachecastle 2 : integer
        mistlist 3 : *mistlist(mistid)  #迷雾列表
        landobj 4 : *landobj(objid) 
        citywall 5 : *citywall(wallid)  #边界列表
        decorlist 6 : *decor(type)      #可建造的装饰物列表
        killobjids 7 : *killobj(objid)  #已击杀的活物
        worker 8 : *worker(workerid)    #丧尸工人
    }
}

unlockland 302 {#解锁地块
    request {
        landid 0 : integer              #要解锁的地块ID
    }
    response {
        code 0 : integer
        land 1 : unlockland             #解锁的地块信息
        citywall 2 : *citywall          #边界列表
        delobj 3 : integer             #删除的活物
        addobj 4 : landobj
    }
}

landclear 303 {#地块清理
    request {
        objid 0 : integer              #活物ID
    }
}

createfacility 304 {#创建新的设施
    request {
        type 0 : integer        #建筑类型
        pos 1 : origin          #原点坐标
        decorid 2:integer      #装饰物id
    }
    response {
        code 0 : integer            #
        facility 1 : cityfacility   #新的设施信息
        exp 2: integer   #经验值
    }
}

editfacility 305 {#编辑设施
    request {
        id 0 : integer          #流水id
        pos 1 : origin          #原点坐标
    }
    response {
        code 0 : integer        #返回码
        id 1 : integer          #流水id
        pos 2 : origin          #原点坐标
    }
}

upgradefacility 306 {#升级建筑
    request {
        id 0 : integer      #流水id
        auto 2 : boolean    #自动用金币补足
    }
    response {
        code 0 : integer                #返回码
        id 1 : integer      #流水id
        auto 2 : boolean    #自动用金币补足
        level 3 : integer   #当前等级
    }
}

deletefacility 307 {#删除建筑
    request {
        id 0 : integer          #建筑流水id
    }
    response {
        code 0 : integer        #返回码
        id 1 : integer          #建筑流水id
    }
}

collectresource 308 {#采集资源
    request { 
        type 1 : integer         #建筑类型
    }
    response {
        code 0 : integer        #返回码
        type 1 : integer        #建筑类型
        token 2 : *integer      #获得的资源
        updatetime 3 : integer  #更新时间
        ids 4 : *integer        #流水ID
    }
}

makematerial 309 {#生产材料
    request {
        queueid 0 : integer     #队列ID
        id 1 : integer          #生产的材料ID
        cfgid 2 : integer       #建筑ID
        num 3 : integer         #个数
    }
    response {
        code 0 : integer    
        material 1 : material   #材料（差量）
        cfgid 2 : integer       #建筑流水ID
        totaltime 3 : integer
        sumtime 4 : integer
    }
}

cancelmake 310 {#取消生产材料
    request {
        queueid 0 : integer
        id 1 : integer              #生产流水
        isclear 2 : boolean         #是否为清空队列
        cfgid 3 : integer           #建筑ID
    }
    response {
        code 0 : integer    
        material 1 : *material   #材料列表
        cfgid 2 : integer       #建筑流水ID
        totaltime 3 : integer
        sumtime 4 : integer
    }
}

rewmaterial 311 {#收取已生产完的材料
    request {
        cfgid 0 : integer           #建筑ID
    }
    response {
        code 0 : integer
        thing 1 : *thingdata(cfgid)
        make 2 : make          #生产
    }
}

speedupmaterial 312 {#生产材料加速
    request {
        queueid 0 : integer
        quick 1 : boolean       #是否花电池立刻完成
        item 2 : integer        #道具配置id
        num 3 : integer         #数量
        auto 4 : boolean        #自动用金币补足
        cfgid 5 : integer       #建筑ID
    }
    response {
        code 0 : integer            #返回码
        cfgid 1 : integer           #建筑流水ID
        quick 2 : boolean           #是否花元宝立刻完成
        item 3 : integer            #道具配置id
        num 4 : integer             #数量
        material 5 : *material      #材料列表
        totaltime 6 : integer
        auto 7 : boolean            #自动用金币补足
        thing 8 : *thingdata(cfgid) #物品
        showid 9 : integer          
    }
}

trainsoldier 313 {#训练士兵
    request {
        id 0 : integer          #建筑流水id
        num 1 : integer         #数量
    }
    response {
        code 2 : integer        #返回码
        id 0 : integer          #建筑流水id
        num 1 : integer         #数量
        traintype 6 : integer   #兵种类型
    }
}

#弃用
canceltrainsoldier 314 {#取消训练士兵
    request {
        id 0 : integer          #建筑流水id
    }
    response {
        code 0 : integer        #返回码
        id 1 : integer          #建筑流水id
        traintype 2 : integer   #兵种类型
        num 3 : integer         #兵种数量
    }
}

#弃用
traincomplete 315 {#训练士兵完成
    request {
        id 0 : integer          #建筑流水id
    }
    response {
        code 0 : integer        #返回码
        id 1 : integer          #建筑流水id
        traintype 2 : integer   #兵种类型
        num 3 : integer         #兵种数量
    }
}

#弃用
speedupsoldier 316 {#训练加速
    request {
        id 0 : integer          #流水id
        quick 1 : boolean       #是否花元宝立刻完成
        item 2 : integer        #道具配置id
        num 3 : integer         #数量
        auto 4 : boolean        #数量不够自动消耗元宝
    }
    response {
        code 0 : integer        #返回码
        id 1 : integer          #流水id
        quick 2 : boolean       #是否花元宝立刻完成
        item 3 : integer        #道具配置id
        num 4 : integer         #数量
        auto 5 : boolean        #数量不够自动消耗元宝
        traintype 6 : integer   #兵种id
        trainnum 7 : integer    #兵种数量
    }
}

landbattle 317 {#地块战斗成功
    request {
        objid 0 : integer
    }
}

mistclear 318 {#清理迷雾
    request {
        mistid 0 : integer
    }
    response {
        code 0 : integer
        mistlist 1 : *mistlist  #迷雾
        landobj 2 : *landobj(objid)
        canunlockland 3 : integer      #可解锁的地块ID
        thing 4 : *thingdata(cfgid)     #物品数据
    }
}

openradar 319 {#打开雷达
    response {
        code 0 : integer
        radar 1 : radar
    }
}

openradartask 323 {#开启雷达任务
    request {
        taskid 0 : integer          #任务ID
    }
    response {
        code 0 : integer
        tasklist 1 : *radartask         #任务列表
    }
}


quickmaterial 324 {#快速生产材料
    request {
        id 0 : integer                 #生产的材料ID
        num 1 : integer                #需要生产的数量
        thing 2 : *thingdata(cfgid)    #加速道具数据
    }
    response {
        code 0 : integer
        id 1 : integer                  #生产的材料ID
        num 2 : integer                 #生产的数量
        retthing 3 : *thingdata(cfgid)  #返还的加速道具数据，可能为空表{}
    }
}

radarbreach 325 {#雷达实力突破
    response {
        code 0 : integer
        curbreachlv 1 : integer         #当前的新突破等级
        thing 2 : *thingdata(cfgid)     #奖励的物品数据
    }
}

upgradedecor 326 {#装饰物升星
    request {
        decorid 0 : integer  #装饰物id
        same 1:*integer      #同类型消耗装饰物列表
        any 2:*integer         #不同类型消耗装饰物列表
    }
    response {
        code 0 : integer            #返回码
        level 1 : integer           #星级
    }
}

freelotterydecor 327 {#装饰物抽奖
    request {
       type 0 : integer          #type:1=抽一次 type = 10 = 抽十次
       isfree 1:boolean         #是否免费
    }
    response {
        code 0 : integer                        #返回码
        nextfreetime 1 : integer            #下次免费时间
        rewards 2: *integer                #中奖道具id
        freecount 3:integer #免费剩余次数
        }
    }

reqdecorinfo 328 {#请求装饰物信息
    response {
        decorlist 0 : *decordata(id)  #设施信息
        code 1 : integer            #返回码
    }
}

reqdeldecor 329 {#删除/摧毁装饰物
    request {
        ids 0 : *integer  #id
        type 1 :integer  #装饰物类型 
    }
    response {  
        code 0 : integer #返回码
        decorlist 1:*decordata(id) #删除装饰物列表
    }
}

reqretrievedecor 330 {#回收全部装饰物
request {
    type 0 :integer  #装饰物类型 为空回收全部
}
response {  
    code 0 : integer #返回码
    decorlist 1:*decordata(id) #回收装饰物列表
    }
}

reqreplacedecor 331 {#替换装饰物
    request {
        id 0 : integer          #旧建筑流水id
        pos 1 : origin          #原点坐标
        decorid 2:integer      #替换装饰物id
    }
    response {
        code 0 : integer              #返回码
        decor 1 :*decordata(id)       #新的装饰物信息
        olddecor 2 :*decordata(id)   #旧的装饰物信息
        exp 3: integer   #经验值
    }
}

reqprotectdecpr 332 {#锁定/解锁装饰物
    request {
        decorid 0:integer      #装饰物id
    }
    response {
        code 0 : integer              #返回码
        isprotect 1:integer         #是否锁定
    }
}

reqfreshfreelottery 333 {#免费抽奖装饰物信息
response {
        code 0 : integer              #返回码
        nextfreetime 1 : integer            #下次免费时间
        freecount 2:integer #免费剩余次数
    }
}

reqdecorbook 334 {#装饰物图鉴信息
    response {
        code 0 : integer              #返回码
        decorbook 1:*integer   #装饰物图鉴
    }
}

reqaddtech 336 {#解锁科技
    request {
        techtype 0:integer      #科技类型
    }
    response {
        code 0 : integer              #返回码
        finishtime 1:integer        #研究完成时间
    }
}

requpgradetech 337 {#升级科技
    request {
        techtype 0:integer      #科技类型
    }
    response {
        code 0 : integer              #返回码
        finishtime 1:integer        #研究完成时间
    }
}

reqtechinfo 338 {#登录请求科技信息
    response {
        techlist 0 : *techdata(type)  #科技信息
        code 1 : integer            #返回码
    }
}

reqtechontime 339 {#定时请求科技
request {
    techtype 0:integer      #科技类型
}
    response {
        tech 0 : techdata  #科技信息
        code 1 : integer            #返回码
    }
}

reqspeeduptech 340 {#加速科技研究
    request {
        itemid 1 : integer        #道具配置id
        itemnum 2 : integer    #数量
        auto 3 : boolean        #自动用金币补足
        techtype 4:integer      #科技类型
    }
    response {
        tech 0 : techdata  #科技信息
        code 1 : integer            #返回码
    }
}

reqquicktech 341 {#立即研究
    request {
        techtype 0:integer      #科技类型
    }
    response {
        tech 0 : techdata  #科技信息
        code 1 : integer            #返回码
    }
}

reqtechpower 342 {#科技战力
    response {
        code 1 : integer            #返回码
        power 2: integer
    }
}

reqwallinfo 343 {#获取城墙数据
    response {
        code 1 : integer            #返回码
        wallinfo 2:wallinfo
    }
}

reqwallontime 344 {#定时请求回复耐久度
    response {
        code 1 : integer            #返回码
        wallinfo 2:wallinfo
    }
}

reqattackwall 345 {#攻击城墙测试用
    request {
        dud 0:integer      #耐久度
    }
    response {
        code 1 : integer            #返回码
        wallinfo 2:wallinfo
    }
}

reqfixwall 346 {#修复城墙
    response {
        code 1 : integer            #返回码
        wallinfo 2:wallinfo
    }
}

reqknocked 347 {#
    request {
        isknocked 0:integer
    }
    response {
        code 1 : integer            #返回码        
    }
}

reqfencecatch 348 {#请求围栏抓捕
    request {
        id 0 : integer          #建筑流水id
        num 1 : integer         #数量
        quick 2 : boolean       #立即完成
    }
    response {
        code 2 : integer        #返回码
        id 0 : integer          #建筑流水id
        num 1 : integer         #数量
        quick 4 : boolean       #立即完成
    }
}

speedupfencecatch 349 {#围栏抓捕加速
    request {
        id 0 : integer          #流水id
        quick 1 : boolean       #是否花元宝立刻完成
        item 2 : integer        #道具配置id
        num 3 : integer         #数量
        auto 4 : boolean        #数量不够自动消耗元宝
    }
    response {
        code 0 : integer        #返回码
        id 1 : integer          #流水id
        quick 2 : boolean       #是否花元宝立刻完成
        item 3 : integer        #道具配置id
        num 4 : integer         #数量
        auto 5 : boolean        #数量不够自动消耗元宝
    }
}

makecageworker 350 {#生产牢笼工人
    request {
        id 0 : integer          #流水id
    }
    response {
        code 0 : integer
        worker 1 : worker
        num 2 : integer         #丧尸预备役总数量
    }
}

makeworkbench 351 {#工人工作台生产道具
    request {
        id 0 : integer      #建筑流水ID
        deskid 1 : integer  #工作台ID
        workerid 2 :integer #工人ID
        thing 3 : *thingdata #制造队列
    }
    response {
        code 0 : integer    
        id 1 : integer      #建筑流水id
        worker 2 : worker
        workbench 3 : workbench 
    }
}

cancelworkbench 352 {#取消素材厂工作台生产
    request {
        id 0 : integer              #建筑流水ID
        deskid 1 : integer          #工作台ID
        isclear 2 : boolean         #是否为清空队列
        makeid 3 : integer          #生产队列ID
    }
    response {
        code 0 : integer    
        id 1 : integer      #建筑流水id
        worker 2 : worker
        workbench 3 : workbench
    }
}

unlockworkbench 353 {#解锁工作台
    request {
        id 0 : integer              #建筑流水ID
    }
    response {
        code 0 : integer
        id 1 : integer              #建筑流水ID
        workbench 2 : workbench
    }
}

rewworkbench 354 {#收取工作台已生产完的材料
    request {
        id 0 : integer           #建筑流水ID
        deskid 1 : integer       #工作台ID
        all 2 : boolean          #是否全部收取
    }
    response {
        code 0 : integer
        id 1 : integer           #建筑流水ID
        thing 2 : *thingdata(cfgid)
        worker 3 : *worker(workerid)
        workbench 4 : *workbench(index)
    }
}

speedupworkbench 355 {#工作台生产素材加速
    request {
        id 0 : integer          #建筑流水ID
        deskid 1 : integer      #工作台ID
        quick 2 : boolean       #是否花电池立刻完成
        item 3 : integer        #道具配置id
        num 4 : integer         #数量
        auto 5 : boolean        #自动用金币补足
    }
    response {
        code 0 : integer            #返回码
        id 1 : integer              #建筑流水ID
        quick 2 : boolean           #是否花元宝立刻完成
        item 3 : integer            #道具配置id
        num 4 : integer             #数量
        auto 5 : boolean            #自动用金币补足
        thing 6 : *thingdata(cfgid) #物品
        worker 7 : worker
        workbench 8 : workbench
    }
}

collectItem 356 {#采集道具
    request {
        type 1 : integer         #建筑类型
    }
    response {
        code 0 : integer        #返回码
        type 1 : integer        #建筑类型
        updatetime 3 : integer  #更新时间
        things 4 : *gatherthings(id)    #获得的道具
    }
}
#刷新生成订单
reqgentaskorder 357 {
    request {
        orderindex 1 : integer         #订单索引
    }
    response {
        code 0 : integer        #返回码
        order 1 :orderitem
    }
}

#登录请求订单
reqgetorder 358 {
    response {
        code 0 : integer        #返回码
        order 1 :*orderitem(index)
        handover 2: handover
    }
}

#订单刷新加速
reqspeedorder 359 {
    request {
        orderindex 1 : integer         #订单索引
    }
    response {
        code 0 : integer        #返回码
        order 1 :orderitem
    }
}

#订单交付
reqhandover 360 {
    request {
        orderindex 1 : integer         #订单索引
    }
    response {
        code 0 : integer        #返回码
        handover 1: handover
        order 2 :orderitem
    }
}
#兑换宝箱
reqorderreward 361 {
    response {
        code 0 : integer        #返回码
        handover 1: handover
    }
}

#转化工程队工人
reqmakebrigade 362 {
    request {
        id 0 : integer          #建筑id
        level 1 : integer       #工程队工人等级
        num 2 : integer         #工程队工人数量
    }
    response {
        code 0 : integer
        id 1 : integer          #建筑id
        level 2 : integer       #工程队工人等级
        num 3 : integer         #工程队工人数量
        fencenum 4 : integer    #剩余丧尸数量
    }
}

#查看工作台
seeworkbench 363 {
    request {
        id 0 : integer          #建筑流水ID
        deskid 1 : *integer      #工作台ID
    }
    response {
        code 0 : integer
        id 1 : integer          #建筑流水ID
        deskid 2 : *integer      #工作台ID
    }
}
]]

cityproto.s2c = cityproto.type .. [[
#城建 301 ～ 400
updatefacility 351 {#同步建筑
    request {
        facility 0 : cityfacility  #设施信息
    }
}

updateland 352 {#同步地块
    request {
        lands 0 : *unlockland(landid)    #地块信息
    }
}

retlandclear 353 {#地块清理返回
    request {
        code 0 : integer
        canunlockland 1 : integer      #可解锁的地块ID
        delobj 2 : integer             #删除的活物
        addobj 3 : landobj
        islimitarmy 4 : boolean        #获得的士兵是否超过上限  
        decortype 5 : integer          #获得的装饰物类型
        thing 6 : *thingdata(cfgid)    #获得的物品数据
    }
}

syncradar 354 {#同步雷达信息
    request {
        radar 0 : radar
    }
}

syncdecor 355 {#同步装饰物列表信息
    request {
        decorlist 0 : *decor(type) 
    }
}

notifyadddecor 356 {#通知增加装饰物
    request {
        decorlist 0 : *decordata(id)  #设施信息
    }
}

notifyfreshfreelottery 357 {#通知免费抽奖装饰物信息
    request {
        nextfreetime 0 : integer            #下次免费时间
        freecount 1:integer #免费剩余次数
    }
}

notifywallinfo 358 {#同步城墙信息
    request {
        wallinfo 0 : wallinfo
    }
}

syncworker 359 {#同步工人
    request {
        worker 0 : worker
    }
}

syncbrigade 360 {#同步工程队工人
    request {
        cell 0 : brigadecell
    }
}


]]

return cityproto