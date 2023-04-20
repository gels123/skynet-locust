local ranklistproto = {}

ranklistproto.type = [[

.playerrankobj {
    rankidx 0 : integer     #排行
    uid 1 : integer         #playerid
    score 2 : integer       #具体看什么排行榜，战力排行榜就是战力，击杀分排行就是击杀分
    border 3 : integer      #头像框
    head 4 : integer        #头像
    name 5 : string         #昵称
    guildshort 6 : string    #联盟缩写
    serverid 7: integer
    language 8 : integer     #国旗
}

.guildrankobj {
    rankidx 0 : integer     #排行
    banner 1 : integer      #旗帜
    shortname 2 : string    #简称
    name 3 : string         #名字
    uid 4 : integer         #帮派id
    score 5 : integer       #具体看什么排行榜
    serverid 7 : integer    #服务器id
    chairman 8 : string     #盟主
}

]]

ranklistproto.c2s = ranklistproto.type .. [[
#排行 1301~1400

reqPersonalRankInfo 1301 {  #请求个人排行榜信息
    request {
        type 0 : integer       #排行榜类型
    }
    response {
        code 0 : integer        #返回状态码
        type 1 : integer        #请求的排行榜
        personalRanklist 2 : *playerrankobj #返回的排行榜内容
        myRank 3 : playerrankobj #我的排名信息
    }
}

reqGuildRankInfo 1302 {    #请求联盟相关排行榜信息
    request {
        type 0 : integer        #排行榜类型
    }
    response {
        code 0 : integer        #返回状态码
        type 1 : integer        #请求的排行榜
        guildRankList 2 : *guildrankobj #返回的排行榜内容
        myRank 3 : guildrankobj #我的联盟信息
    }
}

]]


ranklistproto.s2c = ranklistproto.type .. [[


]]




return ranklistproto