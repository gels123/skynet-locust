local chatproto = {}


chatproto.type = [[
.chatplayer {
    playerid    0 : integer     #玩家ID
    name        1 : string      #名字
    head        2 : integer     #头像配置ID
    guildshort  3 : string      #帮派简称
    guildname   9 : string      #联盟名
    guildid     4 : integer
    border      5 : integer     #头像框
    serverid    6 : integer
    sex         7 : integer
    timenode    8 : integer     #联系人列表中的时间
}

.chatmsg {
    type        0 : integer     #聊天类型
    event       1 : integer     #事件类型
    param       2 : string      #
    content     3 : string      #聊天文本
}

.chat { #聊天数据
    ckey        0 : integer     #流水ID
    chnl        1 : integer     #频道
    player      2 : chatplayer  #玩家信息
    msg         3 : chatmsg     #
    time        4 : integer     #时间
    roomid      5 : integer     #房间ID
}

.chnlmsg { #聊天频道数据
    roomid      0 : integer     #房间ID
    roomname    1 : string      #房间名
    lastchat    2 : chat        #最新的消息
    unreadnum   3 : integer     #未读的消息数量
    istop       4 : integer     #是否置顶，1是0否
    chnl        5 : integer     #频道
    playerid    6 : integer     #私聊的玩家ID，非私聊为nil
    member      7 : *chatplayer #成员信息
}

.undisturdata { #免打扰
    chnl        0 : integer     #频道
    targetid    1 : integer     #目标ID，群聊为房间号，私聊为玩家ID
    undisturb   2 : integer     #是否免打扰，1是0否
    hide        3 : integer     #是否隐藏频道，1是0否
}
.chatcd { #聊天的CD
    roomid      0 : integer
    nexttime    1 : integer     #下次发言时间
}

.groupmsg {#好友列表中的群聊信息
    roomid      0 : integer
    member      1 : *chatplayer #成员信息
    timenode    2 : integer     #联系人列表中的时间
    roomname    3 : string      #房间名
}
]]

chatproto.c2s = chatproto.type .. [[
#聊天 1101 ～ 1200
reqchatmsg 1101 { #请求聊天消息
    request {
        roomid      0 : integer     #房间ID
        ckey        1 : integer     #nil为请求最新
    }
    response {
        code        0 : integer
        roomid      1 : integer     #房间ID
        chats       2 : *chat       #聊天数据
        ckey        3 : integer
        chnl        4 : integer
    }
}

reqchnlmsg 1102 { #请求全部频道信息
    response {
        chnlmsg 0 : *chnlmsg(roomid)         #频道信息
        chatcd 1 : *chatcd(roomid)           #各房间的聊天CD
    }
}

reqchannelchat 1103 { #频道聊天
	request {
        roomid  0 : integer         #房间ID
        msg     1 : chatmsg         #聊天信息
	}                            
    response {                   
        code    0 : integer         #返回码
        roomid  1 : integer         #房间ID
        chnl    2 : integer         #频道
        nexttime 3 : integer        #下次发言时间
    }
}

reqprivatechat 1104 { #私聊
	request {
        playerid    0 : integer     #对方玩家ID
        serverid    1 : integer     #对方服务器ID
        msg         2 : chatmsg     #聊天信息
	} 
    response {                   
        code        0 : integer     #返回码
        playerid    1 : integer     #玩家ID
        roomid      2 : integer     #房间ID
    }                           
}

openchnlroom 1105 { #打开频道房间
    request {
        roomid      0 : integer     #0表示离开房间
    }
    response {
        code        0 : integer     
        roomid      1 : integer     #0表示离开房间
    }
}

setchnlmsg 1106 { #设置频道房间信息
    request {
        roomid      0 : integer
        roomname    1 : string      #房间名
        istop       2 : integer     #是否置顶，1是0否
    }
    response {
        code        0 : integer
        roomid      1 : integer
        roomname    2 : string      #房间名
        istop       3 : integer     #是否置顶，1是0否
    }
}

setundisturb 1107 { #设置免打扰
    request {
        undisturdata 0 : undisturdata
    }
    response {
        code            0 : integer
        undisturdata    1 : undisturdata
    }
}

reqchatseting 1108 { #请求玩家的聊天设置（免打扰和隐藏）
    response {
        undisturdata 0 : *undisturdata(targetid)
    }
}

reqchatmembers 1109 { #请求群聊的所有成员
    request {
        roomid      0 : integer
    }
    response {
        code        0 : integer
        roomid      1 : integer
        chnl        2 : integer         #频道
        member      3 : *chatplayer     #成员信息
    }
}

removeprivatechnl 1110 { #移除私聊房间
    request {
        roomids      0 : *integer
    }
    response {
        code        0 : integer
        chnl        1 : integer
        roomids     2 : *integer
    }
}

reqlinklist 1111 { #请求联系人列表
    response {
        apply 0 : *chatplayer(playerid)
        friend 1 : *chatplayer(playerid)
        grouplist 2 : *groupmsg(roomid)         #群聊列表
        blacklist 3 : *chatplayer(playerid)
        applied 4 : *integer                    #已申请列表
    }
}

searchplayer 1112 { #搜索玩家
    request {
        playerid 0 : integer
    }
    response {
        code 0 : integer
        player 1 : chatplayer  #玩家信息
    }
}

friendapply 1113 { #好友申请
    request {
        playerid 0 : integer
        serverid 1 : integer
    }
    response {
        code 0 : integer
        playerid 1 : integer
    }
}

checkfriendapply 1114 { #同意/拒绝好友申请
    request {
        playerid 0 : integer
        agree 1 : integer       #1同意，0拒绝
    }
    response {
        code 0 : integer
        agree 1 : integer       #1同意，0拒绝
        playerid 2 : integer
    }
}

deletefriend 1115 {#删除好友
    request {
        playerid 0 : integer
    }
    response {
        code 0 : integer
        playerid 1 : integer
    }
}

setblacklist 1116 { #设置黑名单
    request {
        player 0 : chatplayer
        state 1 : integer       #1加入黑名单，0移出黑名单
    }
    response {
        code 0 : integer
        player 1 : chatplayer
        state 2 : integer       #1加入黑名单，0移出黑名单
    }
}

creategroup 1117 {#创建讨论组
    request {
        plyids 0 : *integer     #不包括自己
    }
    response {
        code 0 : integer
        plyids 1 : *integer
        roomid 2 : integer     #房间ID
        fail 3 : *integer      #邀请失败的玩家
        succ 4 : *integer      #邀请成功的玩家
    }
}

invitegroup 1118 {#邀请加入讨论组
    request {
        roomid          0 : integer  #讨论组id
        plyids          1 : *integer #玩家id列表
    }
    response {
        code        0 : integer  #
        roomid      1 : integer  #讨论组id
        plyids      2 : *integer #玩家id列表
        limitfail   3 : *integer #讨论组人数已满，邀请失败的玩家
    }
}

kickoutgroup 1126 {#T出讨论组
    request {
        roomid          1 : integer  #讨论组id
        plyids          2 : *integer #玩家id列表
    }
    response {
        code            0 : integer  #
        roomid          1 : integer  #讨论组id
        plyids          2 : *integer #玩家id列表
    }
}

leavegroup 1127 {#退出讨论组
    request {
        roomid          1 : integer  #讨论组id
    }
    response {
        code            0 : integer  #
        roomid          1 : integer  #讨论组id
    }
}

]]

chatproto.s2c = chatproto.type .. [[
#聊天 1151 ～ 1200
syncchannelchat 1151 { #同步聊天信息
	request {
        chats 0 : *chat
	}
}

syncprivatechat 1152 { #同步私聊信息
	request {
        tagid 0 : integer  #对象ID
        chats 1 : *chat    #私聊数据
	}                          
}

syncchnlmsg 1153 { #同步频道信息(差量)
    request {
        chnlmsg 0 : *chnlmsg(roomid)         #频道信息
    }
}

syncdeletechnl 1154 { #同步频道删除
    request {
        chnlids 0 : *integer
    }
}

syncfriendapply 1155 {#同步好友申请
    request {
        apply 0 : chatplayer        #新增申请
        delapply 1 : integer        #删除已申请
    }
}

syncfriendlist 1156 {#同步好友列表
    request {
        friend 0 : chatplayer       #新增好友
        delfriend 1 : integer    #删除好友
    }
}

]]

return chatproto