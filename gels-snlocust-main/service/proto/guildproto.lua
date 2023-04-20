local guildproto = {}

guildproto.type = [[
.playertreasure {#帮派宝藏
    id 0 : integer      #流水id
    expire 1 : integer  #过期时间 如果有人帮助为nil
    helpid 2 : integer  #帮助者id nil则没有人帮助
    helpname 3 : string #帮助者名字
    opentime 4 : integer #宝箱开启时间戳
    boxid 5 : integer    #宝藏id
    askhelp 6 : boolean     #是否已请求帮助
}
.helptreasure {#帮助的宝藏
    id 0 : integer          #流水id
    targetid 1 : integer    #角色id
    name 2 : string         #名字
    expire 3 : integer      #过期时间 如果有人帮助为nil
    opentime 4 : integer    #宝箱开启时间戳结算
    boxid 5 : integer       #宝藏id
    head 6 : integer        #头像
    border 7 : integer      #头像框
}
.guildtreasurebase {#帮派宝藏基础信息
    ids 0 : *integer            #宝藏列表
    autorefresh 1 : integer     #自动刷新时间戳
    grubtimes 2 : integer       #已挖掘次数
    freegruptime 3 : integer    #免费挖掘时间戳
    freerefresh 6 : integer     #免费刷新次数
    buyrefresh 7 : integer      #已购买的刷新次数
    helptimes 8 : integer       #已帮助次数
}
.guildshoplog {#联盟商店记录
    name 0 : string         #玩家名字
    playerid 1 : integer    #
    itemid 3 : integer      #物品id
    num 4 : integer         #数量
    time 5 : integer        #时间
}
.guildskill {
    skillid 0 : integer
    cdtime  1 : integer
}

.guildbuildskill {
    skilltype 0 : integer
    cdtime 1 : integer
    expire 2 : integer
}

.guildbattlerecordcell {
    queueType 0 : integer   #队列类型
    winCamp 1 : integer     #胜利阵营

    atkUid 2 : integer      #攻方玩家ID
    atkAid 3 : integer      #攻方玩家联盟ID
    atkName 4 : string 		#攻方玩家名字
	atkHead 5 : integer 	#攻方玩家头像
	atkBorder 6 : integer 	#攻方玩家头像
	atkAbbr 7 : string 	    #攻方玩家联盟简称

    defUid 8 : integer      #守方玩家ID
    defAid 9 : integer      #守方玩家联盟ID
    defName 10 : string 		#守方玩家名字
	defHead 11 : integer 	#守方玩家头像
	defBorder 12 : integer 	#守方玩家头像
	defAbbr 13 : string 	    #守方玩家联盟简称

    defSubType 14 : integer  #npc子类型
    defLevel 15 : integer    #npc等级

    time 16 : integer    #时间
}
]]

guildproto.c2s = guildproto.type .. [[
#帮派 801 ～ 1000
createguild 801 {#创建帮派
    request {
        name 0 : string         #名字
        shortname 1 : string    #简称
        language 2 : integer    #语言
        banner 3 : integer      #旗帜
    }
}

reqguildlist 802 {#请求帮派列表
    request {
        
    }
}

reqguildmember 803 {#请求帮派成员
    request {
        guildid 0 : integer     #帮派id
    }
}

applyguild 804 {#申请加入帮派
    request {
        guildid 0 : integer     #帮派id
    }
}

searchguild 805 {#查找帮派
    request {
        name 0 : string           #名字
    }
}

resetguildstage 806 {#修改帮派阶级
    request { 
        targetid 0 : integer        #成员playerid
        newstage 1 : integer        #新阶级
    }
}

changejoinsetting 807 {#修改入团设置
    request {
        auto 0 : boolean            #自动加入
        castlelv 1 : integer        #要求主堡等级
        #score 2 : integer           #要求战力
    }
}

kickoutmember 808 {#剔除帮派成员
    request {
        targetid 0 : integer
    }
}

invitejoinguild 809 {#邀请加入帮派
    request {
        targetid 0 : integer
    }
}

acceptguildinvite 810 {#接受帮派邀请
    request {
        mailid 0 : integer      #邮件id
    }
}

reqguildapplyer 811 {#请求帮派申请者
    
}

checkguildapplyer 812 {#审核帮派申请者
    request {
        targetid 0 : integer    #目标id   nil表示所有人
        agree 1 : boolean       #是否同意
    }
}

leaveguild 813 {#离开帮派
}

reqplayerguild 814 {#请求角色帮派信息信息
    
}

editguildplacard 815 {#修改公告
    request {
        str 0 : string          #新的公告
    }
}

editguilddeclare 816 {#修改宣言
    request {
        str 0 : string          #新的宣言
    }
}

resetguildbase 817 {#修改帮派基础信息
   request {
        name 0 : string         #名字
        shortname 1 : string    #简称
        banner 2 : integer      #旗帜配置id
        language 3 : integer    
    } 
}

transferchairman 819 {#转让会长
    request {
        targetid 0 : integer    #目标id
    }
}

applychairman 820 {#申请成为会长

}

sendguildmsg 821 {#发送全体消息
    request {
        content 0 : string      #
    }
}

openmessageboard 822 {#打开帮派留言板
    request {
        guildid 0 : integer     #帮派id
    }
}

closemessageboard 823 {#关闭帮派留言板
    response {
        code 0 : integer        #返回码
    }
}

guildboardmsg 824 {#发送帮派留言板消息
    request {
        content 0 : string     #消息
    }
}

reqotherguild 825 {#请求其他帮派信息
    request {
        guildid 0 : integer     #帮派id
        serverid 1 : integer    #服务器id
    }
}

openmyguild 826 {#打开自己帮派面板
    
}

reqguildhelp 827 {#请求帮派帮助
    request {
        type 0 : integer        #0建造 1科研 2医疗
        facilityid 1 : integer  #当类型为建造时 建筑id
    }
}

reqguildhelplist 828 {#请求帮助列表

}

dealguildhelp 829 {#处理帮派帮助
    request {
        onekey 0 : boolean      #是否处理所有
        id 1 : integer          #流水id
    }
}

delmapobject 830 { #移除地图活物
    request {
        objectid 0 : integer
    }
}

createguildbuild 831 { #创建公会建筑
    request {
        buildid 0 : integer
        x 1 : integer
        y 2 : integer
    }
}

deleteguildbuild 832 { #工会建筑移除
    request {
        buildid 0 : integer
    }
}

reqguildtech 833 {#请求帮派科技详细信息
    
}

resetrecommendtech 834 {#设置推荐科技
    request {
        techid 0 : integer      #科技id
        #cancel 1 : boolean      #是否为取消设置的标记
    }
}

upgradeguildtech 835 {#升级帮派科技
    request {
        techid 0 : integer      #科技id
    }
}

guildtechdonate 836 {#帮派科技捐献
    request {
        techid 0 : integer      #科技id
        quick 1 : boolean       #消耗金币捐献
        auto 2 : boolean        #自动消耗
        num 3 : integer         #捐献次数
    }
}

buytechdonate 837 {#购买科技捐献次数
    response {
        code 0 : integer        #返回码
    }
}

reqdonaterankreward 838 {#结算上周捐献排名奖励
    
}

reqguildshop 839 {#请求帮派商店数据
    
}

guildshopbuy 840 {#帮派商店购买
    request {
        id 0 : integer          #配置id
        num 1 : integer         #数量
    }
}

addguildshopgoods 841 {#帮派商店补货
    request {
        id 0 : integer          #配置id
        num 1 : integer         #数量
    }
}

reqguildhistory 842 {#请求帮派动态信息

}

invitemovecastle 843 {#邀请迁城
    request {
        targetid 0 : integer    #成员id
        posx 1 : integer        #坐标x
        posy 2 : integer        #坐标y
    }
}

reqguildtreasure 844 {#请求帮派宝藏
    response {
        base 0 : guildtreasurebase      #
        mytreasure 1 : *playertreasure  #我的宝藏
        myhelptreasure 2 : *helptreasure #我正在帮助的宝藏
    }
}

reqhelptreasurelist 845 {#请求宝藏帮助列表
    
}

refreshguildtreasure 846 {#刷新帮派宝藏
    response {
        code 0 : integer        #返回码
    }    
}

openguildtreasure 847 {#开启帮派宝藏
    request {
        index 0 : integer               #位置
    }
    response {
        code 0 : integer                #返回码
        newtreasure 1 : playertreasure   #新增加的我的宝藏
        index 2 : integer               #位置
    }
}

reqguildtreasurehelp 848 {#请求宝藏帮助
    request {
        id 0 : integer      #流水id
    }
}

helpguildtreasure 849 {#宝藏帮助
    request {
        targetid 0 : integer            #角色id
        id 1 : integer                  #流水id
    }
}

speedupguildtreasure 850 {#加速宝藏
    request {
        targetid 0 : integer            #角色id
        id 1 : integer                  #流水id
    }
}

receiveguildtreasure 851 {#领取帮派宝藏
    request {
        targetid 0 : integer            #角色id
        id 1 : integer                  #流水id
    }
    response {
        targetid 0 : integer            #角色id
        id 1 : integer                  #流水id
        code 2 : integer                #返回码
        reward 3 : rewardlib            #奖励库数据
    }
}

reqguildresourcehelp 852 {#请求资源援助
    request {
        token 0 : string                #资源类型
        num 1 : integer                 #请求数量
    }
}

cancelguildresourcehelp 853 {#取消资源援助请求
}

reqguildresourcehelplist 854 {#请求资源援助列表
}

guildrecruit 855 {#帮派招募
    
}

reqguildwarboardred 856 { #请求工会战争面板红点
    response {
        guildwarred 0 : boolean #历史军情红点
    }
}

reqguildcollection 857 {#请求帮派坐标收藏
    request {
        servertype 0 : integer  #1->本服，2->跨服势力战
    }
}

editguildcollection 858 {#编辑帮派坐标收藏
    request {
        name 0 : string         #坐标名字
        posx 1 : integer        #横坐标
        posy 2 : integer        #纵坐标
        ctype 3 : integer       #收藏类型
        lotid 4 : integer       #地表类型id
        objectid 5 : integer    #活物id
        servertype 6 : integer  #1->本服，2->跨服势力战
    }
}

removeguildcollection 859 {#删除收藏坐标
    request {
        id 0 : integer  #坐标id
        servertype 1 : integer  #1->本服，2->跨服势力战
    }
}

deleteguildboardmsg 860 {#删除帮派留言板消息
    request {
        ids 0 : *integer  #id列表
    }
}

applyguildoffice 862 {#申请帮派官员
    request {
        officeid 0 : integer    #官员id
    }
}

resetguildoffice 863 {#设置帮派官员
    request {
        targetid 0 : integer    #
        officeid 1 : integer 
    }
}

cancelguildoffice 864 {#取消帮派官员
    request {
        targetid 0 : integer
    }
}

reqguildgiftlist 865 {#请求帮派礼包
    request {
        tab 0 : integer 
        begin 1 : integer
        over 2 : integer
    }
}

receiveguildgift 866 {#领取帮派礼包
    request {
        id 0 : integer  #礼包id
    }
}

receiveguildgiftonekey 867 {#一键领取帮派礼包
    request {
    }
}

deleteguildgift 868 {#删除帮派礼包
    request {
    
    }
}

reqguildranklist 869 {#请求帮派排行榜信息
    request {
        ranktype 0 : integer    #排行榜类型
    }
}

openguildcollection 870 {#查看帮派坐标
    request {
    }
}

upgradeguildbuild 871 {#升级帮派建筑
    request {
        buildid 0 : integer
    }
}

reqguildshoplog 872 {#联盟商店记录
    request {
        type 0 : integer    #0购买  1补货
    }
}
reqguildskilldonate 873 {#帮派技能捐献
    request {
        itemid 0 : integer
        amount 1 : integer      #数量
        auto   2 : boolean      #自动消耗
    }
    response {
        code 0 : integer
        token 1 : integer
        addbanggong 2 : integer
    }
}

reqguildskillboard 874 {#请求帮派技能面板
    response {
        code    0 : integer
        skills  1 : *guildskill
        token   2 : integer
    }
}

useguildskill 875 { #使用帮派技能
    request {
        skillid 0 : integer
        tagid   1 : integer
    }
    response {
        skillid 0 : integer
        cdtime  1 : integer
        code    2 : integer
        token   3 : integer
    }
}

createchristmastree 876 {
    request {
        x 0 : integer
        y 1 : integer
    }
    response {
        code    0 : integer
    }
}

removechristmastree 877 {
    response {
        code    0 : integer
    }
}

reqsidewarguildlist 878 {#请求势力战帮派列表
    request {
        
    }
}

shieldkingbattleinvite 879 {#屏蔽帮派战邀请提示
    request {
        shield 0 : boolean      #是否提示
    }
    response {
        code 0 : integer
        shield 1 : boolean      #是否提示
    }
}

reqguildbuildskill 880 {
    
}

#请求联盟战争记录
reqguildbattlerecord 881 {
    response {
        code 0 : integer
        records 1 : *guildbattlerecordcell
    }
}
]]


guildproto.s2c = guildproto.type .. [[
#帮派 801 ～ 1000
.guildgiftnum {
    tab 0 : integer
    num 1 : integer
}
.ownerguild
{
    guildid 0 : integer         #帮派id
    score 2 : integer           #战力
    banner 3 : integer          #旗帜
    membernum 6 : integer       #当前成员人数
    maxnum 7 : integer          #总人数
    chairmanname 9 : string     #会长名字
    name 10 : string            #名字
    shortname 11 : string       #简称
    declare 12 : string         #宣言
    placard 13 : string         #公告
    stage 14 : integer          #阶级
    applynum 15 : integer       #申请者人数
    joincastlelv 16 : integer   #申请要求主堡等级
    joinauto 18 : boolean       #申请设置为自动加入
    chairmanid 19 : integer     #会长id
    guildmoney 20 : integer     #帮派资金
    #boardred 21 : boolean       #留言板小红点
    language 22 : integer       #语种id
    giftnum 23 : *guildgiftnum  #可领取礼包数量
    chairmanoffline 24 : integer    #会长离线时间
    jointime 25 : integer       #加入时间
    #weekreward 26 : boolean     #是否有周奖励
    level 27 : integer          #等级
    zoneids 28 : *integer       #势力范围ID
    wheat 29 : integer          #小麦
    exp 30 : integer            #经验
}

retcreateguild 901 {#创建帮派返回
    request {
        code 0 : integer        #返回码
        name 1 : string         #名字
        shortname 2 : string    #简称
        language 3 : integer    #语言
        banner 4 : integer      #旗帜
        info 5 : ownerguild     #自己的帮派信息

    }
}

.guild {#帮派数据
    guildid 0 : integer         #帮派id
    name 1 : string             #名字
    score 2 : integer           #战力
    banner 3 : integer          #旗帜
    membernum 6 : integer       #当前成员人数
    maxnum 7 : integer          #总人数
    chairmanname 9 : string     #会长名字
    activity 10 : integer       #活跃度
    shortname 11 : string       #简称
    apply 12 : boolean          #是否已申请
    chairmanid 13 : integer     #会长id
    language 14 : integer       #语种id
    active 17 : integer         #活跃人数
    level 18 : integer          #等级
    joincastlelv 19 : integer   #申请要求主堡等级
    joinauto 20 : boolean       #申请设置为自动加入
    citynum 21 : integer        #城池数量
}
retguildlist 902 {#帮派列表返回
    request {
        info 2 : *guild         #帮派数据
    }
}

.guildmember {#帮派成员数据
    playerid 0 : integer        #角色id
    shape 1 : integer           #形象
    nickname 2 : string         #昵称
    score 3 : integer           #战斗力
    stage 4 : integer           #职位
    offlinetime 5 : integer     #离线时间 nil 则在线
    name 6 : string             #名字
    head 7 : integer            #头像
    viplevel 8 : integer        #vip等级
    border 11 : integer         #头像框
    sex 12 : integer            #性别
    level 13 : integer          #玩家等级
}
retguildmember 903 {#帮派成员列表
    request {
        guildid 0 : integer     #帮派id
        member 1 : *guildmember #成员信息
    }
}

retapplyguild 904 {#返回申请加入帮派
    request {
        code 0 : integer
        guildid 1 : integer
        joincastlelv 2 : integer        #申请要求主堡等级
        joinscore 3 : integer           #申请要求战力
        joinauto 4 : boolean            #申请设置为自动加入
        info 5 : ownerguild              #加入的公会信息
    }
}

retsearchguild 905 {#查找帮派返回
    request {
        name 0 : string           #名字
        info 2 : *guild         #帮派数据
    }
}

retresetguildstage 906 {#修改帮派阶级返回
    request {
        code 0 : integer            #返回码
        targetid 1 : integer        #成员playerid
        newstage 2 : integer        #新的阶级
    }
}

retchangejoinsetting 907 {#修改入团设置
    request {
        auto 0 : boolean            #自动加入
        castlelv 1 : integer        #要求主堡等级
        score 2 : integer           #要求战力
        code 3 : integer            #返回码
    }
}

retkickoutmember 908 {#剔除帮派成员返回
    request {
        code 0 : integer            #返回码
        targetid 1 : integer        #
        mystage 2 : integer         #自己的阶级
        tarstage 3 : integer        #对方的阶级
        membernum 4 : integer
    }
}

retinvitejoinguild 909 {#邀请加入帮派返回
    request {
        code 0 : integer            #返回码
        targetid 1 : integer        
    }
}

retacceptguildinvite 910 {#接受帮派邀请返回
    request {
        code 0 : integer        #返回码
        mailid 1 : integer      #邮件id
    }
}

.guildapplyer {
    playerid 0 : integer
    head 1 : integer
    name 2 : string
    castlelv 3 : integer
    score 4 : integer
}
retguildapplyer 911 {#返回帮派申请者
    request {
        code 0 : integer        #返回码
        info 1 : *guildapplyer  #申请者信息
    }
}

retcheckguildapplyer 912 {#返回审核帮派申请者
    request {
        targetid 0 : integer    #目标id
        agree 1 : boolean       #是否同意
        code 2 : integer        #返回码
        membernum 3 : integer
    }
}

retleaveguild 913 {#离开帮派返回
    request {
        code 0 : integer
    }
}

.playerguild {#玩家帮派信息
    guildid 0 : integer     #帮派id nil则没有帮派
    name 1 : string         #帮派名字
    shortname 2 : string    #帮派简称
    stage 3 : integer       #阶级
    level 4 : integer       #帮派等级
}
.guildhelpcache {#帮助缓存信息
    type 0 : integer        
    id 1 : integer          
}
syncplayerguild 914 {#同步角色帮派信息信息
    request {
        info 0 : playerguild     #
        type 1 : integer         #1自己退出  2被踢出
        techdonate 2 : integer   #科技捐献次数
        donatetime 3 : integer   #捐献回复开始时间 次数满为0
        quickdonate 4 : integer  #用金币捐献的次数
        helpcache 5 : *guildhelpcache 
        jointime 6 : integer     #加入时间
    }
}

reteditguildplacard 915 {#修改公告返回
    request {
        str 0 : string          #新的公告
        code 1 : integer        #返回码
    }
}

reteditguilddeclare 916 {#修改宣言返回
    request {
        str 0 : string          #新的宣言
        code 1 : integer        #返回码
    }
}

retresetguildbase 917 {#修改帮派基础信息返回
    request {
        code 0 : integer        #返回码
        name 1 : string         #名字
        shortname 2 : string    #简称
        banner 3 : integer      #旗帜配置id
        language 4 : integer    
    }
}

rettransferchairman 919 {#转让会长返回
    request {
        targetid 0 : integer    #目标id
        code 1 : integer        #返回码
    }
}

retapplychairman 920 {#申请成为会长返回
    request {
        code 0 : integer        #返回码
    }
}

retsendguildmsg 921 {#发送全体消息
    request {
        content 0 : string      #
        code 1 : integer        #返回码
        cd 2 : integer          #cd时间戳
    }
}

.boardmsg {
    playerid 0 : integer        #成员id
    head 1 : integer            #头像
    shortname 2 : string        #帮派简称
    name 3 : string             #玩家名字
    time 4 : integer            #发送时间
    content 5 : string          #内容
    viplevel 6 : integer        #vip等级
    viptime 7 : integer         #vip时间
    id 8 : integer              #流水id
    border 11 : integer         #头像框
}
retopenmessageboard 922 {#返回帮派留言板消息
    request {
        guildid 0 : integer     #帮派id
        msg 1 : *boardmsg       #留言信息
    }
}

newboardmessage 923 {#新增留言板消息
    request {
        guildid 0 : integer     #帮派id
        msg 1 : boardmsg       #留言信息
    }    
}

retguildboardmsg 924 {#发送帮派留言板消息
    request {
        content 0 : string      #消息
        code 1 : integer        #返回码
    }
}

retotherguild 925 {#返回其他帮派信息
    request {
        code 1 : integer            #返回码
        guildid 0 : integer         #帮派id
        score 2 : integer           #战力
        banner 3 : integer          #旗帜
        membernum 6 : integer       #当前成员人数
        maxnum 7 : integer          #总人数
        chairmanname 9 : string     #会长名字
        name 10 : string            #名字
        shortname 11 : string       #简称
        declare 12 : string         #宣言
        joincastlelv 13 : integer   #申请要求主堡等级
        joinauto 15 : boolean       #申请设置为自动加入
        chairmanid 16 : integer     #会长id
        language 17 : integer       #语种id
        serverid 20 : integer       #服务器id
        level 21 : integer          #等级
        zoneids 22 : *integer       #势力范围ID
    }
}

retmyguild 926 {#返回自己帮派详细信息
    request {
        code 1 : integer        #返回码
        info 2 : ownerguild     #自己的帮派信息
    }
}

retguildhelp 927 {#请求帮派帮助
    request {
        type 0 : integer        #0建造 1科研 2医疗
        facilityid 1 : integer  #当类型为建造时 建筑id
        code 2 : integer        #返回码
    }
}

.guildhelp {#帮助数据
    id 0 : integer          #流水id
    playerid 1 : integer    #发起者角色id
    name 2 : string         #名字
    head 3 : integer        #头像
    type 4 : integer        #帮助类型 0建造 1科研 2医疗
    buildtype 5 : integer   #建筑type 
    buildlevel 6 : integer  #建筑等级
    techid 7 : integer      #科技id
    techlv 8 : integer      #科技等级
    healnum 9 : integer     #治疗数量
    helptimes 10 : integer  #已帮助次数
    maxtimes 11 : integer   #总帮助次数
    facilityid 12 : integer #建筑id
    viplevel 13 : integer        #vip等级
    viptime 14 : integer         #vip时间
    border 15 : integer          #头像框
}
syncguildhelplist 928 {#同步帮派帮助列表
    request {
        info 1 : *guildhelp     #帮助数据
    }
}

.helptimes {
    id 0 : integer              #流水id
    helptimes 1 : integer       #已帮助次数
    helper 2 : string           #帮助者名字
}
updateguildhelp 929 {#更新帮助次数
    request {
        info 0 : *helptimes     #帮助次数数据
    }
}

newguildhelp 930 {#新的帮助数据
    request {
        info 1 : guildhelp     #帮助数据
    }
}

deleteguildhelp 931 {#删除帮助数据
    request {
        id 0 : *integer         #流水id
    }
}

retdealguildhelp 932 {#处理帮派帮助返回
    request {
        onekey 0 : boolean      #是否处理所有
        id 1 : integer          #流水id
        code 2 : integer        #返回码
    }
}


retdelmapobject 933 { #移除地图活物返回
    request {
        objectid 0 : integer
        code 1 : integer
        cleancnt 2 : integer
    }
}

retcreateguildbuild 934 { #创建公会建筑返回
    request {
        buildid 0 : integer
        code 1 : integer
        level 2 : integer
    }
}

retdeleteguildbuild 935 { #移除工会建筑返回
    request {
        buildid 0 : integer
        code 1 : integer
        level 2 : integer
    }
}

syncmyguild 936 {#同步自己帮派详细信息
    request {
        applynum 1 : integer        #申请者人数
        chairmanoffline 2 : integer #会长离线时间
        stone  3 : integer          #铀矿数量
        stoneatk 4 : integer        #铀矿进攻次数
        invitenum 5 : integer       #国王战邀请数量
    }
}

.guildtechdesc {
    techid 0 : integer      #科技id
    level 1 : integer       #等级
    exp 2 : integer         #经验
    upgradetime 3 : integer #升级时间 有值的话表示正在升级
}
retguildtech 937 {#返回帮派科技信息
    request {
        code 0 : integer            #返回码
        tech 1 : *guildtechdesc(techid) #科技信息，以guild_tech表TechGroup字段做键值
        recommend 2 : *integer      #推荐的科技id
        weekreward 3 : boolean      #是否有周奖励
    }
}

retresetrecommendtech 938 {#设置推荐科技
    request {
        techid 0 : integer      #科技id
        #cancel 1 : boolean      #标记
        code 2 : integer        #返回码
    }
}

retupgradeguildtech 939 {#升级帮派科技返回
    request {
        techid 0 : integer      #科技id
        code 1 : integer        #返回码
        time 2 : integer        #升级的时间
    }
}

retguildtechdonate 940 {#帮派科技捐献返回
    request {
        techid 0 : integer      #科技id
        quick 1 : boolean       #消耗金币捐献
        code 2 : integer        #返回码
        addexp 3 : integer      #增加科技经验
        guildmoney 4 : integer  #获得帮派资金
        banggong 5 : integer    #获得帮贡
        tech 6 : guildtechdesc     #科技信息
        multiple 7 : integer    #暴击倍数
        auto 8 : boolean        #自动购买资源
        num 9 : integer         #捐献次数
    }
}

.guildtech {#帮派科技
    techid 0 : integer      #科技id
    level 1 : integer       #等级
    exp 2 : integer         #经验
    upgradetime 3 : integer #升级时间
}
syncguildtech 941 {#同步帮派科技
    request {
        tech 1 : *guildtech     #帮派科技信息
    }
}

retdonaterankreward 942 {#结算上周捐献排名奖励
    request {
        code 0 : integer        #返回码
    }
}

.guildshopgoods {
    id 0 : integer          #物品id
    num 1 : integer         #数量
}
retguildshop 943 {#回帮派商店数据
    request {
        goods 0 : *guildshopgoods   #商品列表
        code 1 : integer            #返回码
        guildmoney 2 : integer      #帮派资金
    }
}

retguildshopbuy 944 {#回帮派商店购买
    request {
        id 0 : integer          #道具id
        num 1 : integer         #数量
        code 2 : integer        #返回码
    }
}

retguildshopgoods 945 {#回帮派商店补货
    request {
        id 0 : integer          #道具id
        num 1 : integer         #数量
        code 2 : integer        #返回码
    }
}

.guildhistory {
    id 0 : integer      #事件id
    params 1 : *string  #参数
    time 2 : integer    #时间戳
}
retguildhistory 946 {#返回帮派动态信息
    request {
        code 0 : integer                #返回码
        history 1 : *guildhistory       #列表信息
    }
}

retinvitemovecastle 947 {#邀请迁城返回
    request {
        targetid 0 : integer    #成员id
        posx 1 : integer        #坐标x
        posy 2 : integer        #坐标y
        code 3 : integer        #返回码
    }
}

syncguildtreasure 948 {#同步宝藏表数据
    request {
        base 0 : guildtreasurebase      #
    }
}

rethelptreasurelist 949 {#返回宝藏帮助列表
    request {
        info 0 : *helptreasure 
        code 1 : integer        #返回码
    }
}

retguildtreasurehelp 950 {#请求宝藏帮助返回
    request {
        code 0 : integer        #返回码
        id 1 : integer          #流水id
    }
}

retspeedupguildtreasure 951 {#加速宝藏
    request {
        targetid 0 : integer            #角色id
        id 1 : integer                  #流水id
        code 2 : integer                #返回码
    }
}

updateguildtreasure 953 {#更新帮派宝藏
    request {
        mytreasure 0 : playertreasure   #我的宝藏
        helptip 1 : boolean             #帮助提示
    }
}

deleteguildtreasure 954 {#删除帮派宝藏
    request {
        ids 0 : *integer  #流水id
    }
}

syncguildhelptreasure 955 {#同步正在帮助的宝藏
    request {
        helptreasure 3 : *helptreasure   #我正在帮助的宝藏
    }
}

rethelpguildtreasure 956 {#宝藏帮助返回
    request {
        targetid 0 : integer            #角色id
        id 1 : integer                  #流水id
        code 2 : integer                #返回码
    }
}

.resourcehelp {
    playerid 0 : integer    #
    name 1 : string
    head 2 : integer
    expire 3 : integer              #过期时间
    token 4 : string                #资源类型
    maxnum 5 : integer              #请求数量
    num 6 : integer                 #已收到数量
    score 7 : integer               #战力
}
retguildresourcehelp 957 {#请求资源援助
    request {
        code 1 : integer                #返回码
        newhelp 2 : resourcehelp        #新增援助请求
        token 4 : string                #资源类型
        num 5 : integer                 #请求数量
    }
}

retcancelguildresourcehelp 958 {#取消资源援助返回
    request {
        code 0 : integer
    }
}

retguildresourcehelplist 959 {#请求资源援助列表返回
    request {
        code 0 : integer                #返回码
        info 1 : *resourcehelp          #
    }
}

updateguildtech 960 {#同步帮派科技(有就更新没有就添加)
    request {
        tech 1 : guildtech     #帮派科技信息
    }
}

retguildrecruit 961 {#帮派招募返回
    request {
        code 0 : integer
        cdtime 1 : integer     #cd到的时间戳
    }
}

noticeboardred 962 {#通知帮派留言板小红点
    request {
        boardred 0 : boolean 
    }
}

syncguildcollection 963 {#同步帮派坐标收藏（全量）
    request {
        collection 0 : *collectioninfo(id)
        redflag 1 : boolean   #红点标记
    }
}

reteditguildcollection 964 {#编辑帮派坐标收藏返回
    request {
        code 0 : integer        #返回码
        posx 1 : integer        #横坐标
        posy 2 : integer        #纵坐标
    }
}

retremoveguildcollection 965 {#删除收藏坐标返回
    request {
        id 0 : integer          #坐标id
        code 1 : integer        #返回码
    }
}

updateguildcollection 966 {#同步帮派收藏坐标 (有就更新 没有就添加)
    request {
        param 0 : collectioninfo
        redflag 1 : boolean   #红点标记
    }
}

deleteguildcollection 967 {#删除帮派收藏坐标
    request {
        id 0 : integer          #坐标id
    }
}

retdeleteguildboardmsg 968 {#删除留言板消息返回
    request {
        code 0 : integer        #返回码
        ids 1 : *integer        #
    }
}

deleteboardmsg 969 {#通知删除帮派留言板消息
    request {
        ids 1 : *integer        #
    }
}

.guildgift {
    id 0 : integer          #礼包id
    cfgid 1 : integer       #配置id
    params 2 : *string      #参数 有可能为nil
    state 3 : integer       #状态
    expire 4 : integer      #过期时间
    item 5 : thingdata      #奖励的道具 有可能为nil
    receive 6 : integer     #领取时间
}
retguildgiftlist 974 {#请求帮派礼包
    request {
        tab 0 : integer 
        begin 1 : integer
        over 2 : integer
        gift 3 : *guildgift
        giftlv 4 : integer      #礼包等级
        giftexp 5 : integer     #礼包经验
        boxid 6 : integer       #白金礼包id
        boxexp 7 : integer      #白金礼包经验
        code 8 : integer        #返回码
    }
}

retreceiveguildgift 975 {#领取帮派礼包
    request {
        code 0 : integer        #返回码
        id 1 : integer          #礼包id
        item 2 : thingdata      #奖励的道具
        giftlv 4 : integer      #礼包等级
        giftexp 5 : integer     #礼包经验
        boxid 6 : integer       #白金礼包id
        boxexp 7 : integer      #白金礼包经验
        addgiftexp 8 : integer  #奖励的礼包经验
        addboxexp 9 : integer   #奖励的白金礼包经验
        giftnum 11 : *guildgiftnum    #可领取礼包数量
        receive 12 : integer     #领取时间
    }
}

.receivegift {
    id 0 : integer
    item 1 : thingdata          #奖励的道具
    receive 2 : integer     #领取时间
}
retreceiveguildgiftonekey 976 {#一键领取帮派礼包
    request {
        code 0 : integer        #返回码
        reward 1 : *receivegift        #领取的礼包数据
        giftlv 4 : integer      #礼包等级
        giftexp 5 : integer     #礼包经验
        boxid 6 : integer       #白金礼包id
        boxexp 7 : integer      #白金礼包经验
        addgiftexp 8 : integer  #奖励的礼包经验
        addboxexp 9 : integer   #奖励的白金礼包经验
        giftnum 10 : *guildgiftnum         #可领取礼包数量
    }
}

retdeleteguildgift 977 {#删除帮派礼包
    request {
        code 0 : integer        #返回码
        ids 1 : *integer        #删除的礼包id
        giftlv 4 : integer      #礼包等级
        giftexp 5 : integer     #礼包经验
        boxid 6 : integer       #白金礼包id
        boxexp 7 : integer      #白金礼包经验
    }
}

noticeguildgiftexpire 978 {#通知帮派礼包过期
    request {
        ids 1 : *integer        #过期的礼包id
        giftnum 2 : *guildgiftnum         #可领取礼包数量
    }
}

noticenewguildgift 979 {#通知新的帮派礼包
    request {
        gift 1 : guildgift
        giftnum 2 : *guildgiftnum         #可领取礼包数量
    }
}

.guildrankmember {#帮派排行榜成员
    playerid 0 : integer 
    name 1 : string
    stage 3 : integer
    score 5 : integer   #分值
    head 6 : integer    #头像
}
retguildranklist 980 {#返回帮派排行榜信息
    request {
        code 2 : integer        #返回码
        ranktype 0 : integer    #排行榜类型
        objs 1 : *guildrankmember  #排行榜数据
    }
}

retupgradeguildbuild 981 {  #升级帮派建筑返回
    request {
        code 0 : integer
        buildid 1 : integer
    }
}

retguildshoplog 982 {#联盟商店记录返回
    request {
        code 0 : integer        #返回码
        log 1 : *guildshoplog   #日志
        type 2 : integer        #0购买 1补货
    }
}

broadcastuseguildskill 983 { #工会使用技能广播
    request {
        skillid 0 : integer
        name 1 : string #使用者名
        tagname 2 : string #目标名
    }
}

retsidewarguildlist 984 {#帮派列表返回
    request {
        info 2 : *guild         #帮派数据
    }
}

syncguildbuildskill 985 {
    request {
        buildskill 0 : *guildbuildskill(skilltype)
    }
}

.armorybuildmsg { #兵工厂领取详情
    type 0 : integer #士兵类型
    brecv 1 : boolean #是否领取过
}
syncarmoryrecv 986 {
    request {
        armory 0 : armorybuildmsg
    }
}
syncarmoryrecvresult 987 {
    request {
        cfgid 0 : integer
        num 1 : integer
    }
}

syncguildmember 988 {#同步帮派成员信息
    request {
        members 1 : *guildmember #成员信息
    }
}

syncguildwheat 989 {#同步联盟小麦
    request {
        wheat 0 : integer # 新小麦数量
    }
}

]]

return guildproto