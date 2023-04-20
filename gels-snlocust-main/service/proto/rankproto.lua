local rankproto = {}

rankproto.type = [[
.playerrankobj {
    rank 0 : integer     #排行
    head 1 : integer     #头像
    name 2 : string      #名字
    score 3 : integer    #战斗力
    castlelv 4 : integer #主堡等级
    killnum 5 : integer     #杀敌数
    level 6 : integer    #君主等级
    guildshort 7 : string #帮派简称
    objid 8 : integer    #角色id
    border 9 : integer   #头像边框
    officerid 11 : integer #官职ID
    shape 12 : integer   #形象
    serverid 14 : integer #服务器id
}

.guildrankobj {
    rank 0 : integer    #排行
    banner 1 : integer  #旗帜
    shortname 2 : string #简称
    name 3 : string     #名字
    objid 4 : integer   #帮派id
    score 5 : integer   #战斗力
    killnum 6 : integer    #杀敌数
    serverid 7 : integer #服务器id
    language 8 : integer #语言 有可能为nil
}
]]

rankproto.c2s = rankproto.type .. [[
#排行 1301~1400
reqrankinfo 1301 {#请求排行榜信息
    request {
        type 0 : integer        #排行榜类型
        begin 1 : integer       #起始位置
        over 2 : integer        #结束位置
    }
}

]]


rankproto.s2c = rankproto.type .. [[
#排行 1301~1400
retrankinfo 1351 {#
    request {
        type 0 : integer        #排行榜类型
        begin 1 : integer       #起始位置
        over 2 : integer        #结束位置
        plyobjs 3 : *playerrankobj  #玩家排行信息
        guildobjs 4 : *guildrankobj #帮派排行信息
        myrank 5 : integer      #当前排名 nil未进榜
        ranknum 6 : integer     #最大排名数
        guildscore 7 : integer  #帮派战斗力
        guildkill 8 : integer   #帮派杀敌数
        mykill 9 : integer      #我的杀敌数
    }
}


]]

return rankproto