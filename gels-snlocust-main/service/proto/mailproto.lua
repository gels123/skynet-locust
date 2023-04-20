local mailproto = {}

mailproto.type = [[
.mailCover {
    setType 0 : integer     #集合类型
    totalNum 1 : integer    #集合邮件总数
    notViewNum 2 : integer  #集合未读邮件总数
    hasExtraNum 3 : integer #集合有未领取附件邮件总数
}

.mailparam {
    language 0 : string     #语言
    content 1 : *string     #参数
}

.mailCell {
    mid 0 : integer           #邮件id
    cfgid 1 : integer         #邮件配置id
    hasExtra 2 : boolean      #是否有奖励
    createTime 3 : integer    #邮件创建时间
    isGetExtra 4 : boolean    #是否已领奖
    isView 5 : boolean        #是否已查看
    brief 6 : string          #简要数据(json数组如‘brief = {["1"] = 111,["2"] = 1,["extra"] = extra,}’)
    brief2 7 : battleReportMailBrief #战报邮件独有的简要数据
    setTypeOri 8 : integer    #原集合类型
}

.mailDetail {
    text 0 : string          #文本
    extra 1 : rewardlib      #附件奖励
    data 2 : string          #其他信息(json)
    report 3 : battleReportOne #单场战报详情(少量数据)
}
]]

mailproto.c2s = mailproto.type .. [[
#邮件 1601 ～ 1700

#请求邮件封面数据
reqCovers 1601 {
    request {
    }
    response {
        code 0 : integer        #错误码
        covers 1 : *mailCover   #邮件封面数据
    }
}

#请求邮件简要信息
reqMailBrief 1602 {
    request {
        setType 0 : integer     #集合类型
        begin 1 : integer       #起始位置
        over 2 : integer        #结束位置
    }
    response {
        code 0 : integer        #错误码
        setType 1 : integer     #集合类型
        begin 2 : integer       #起始位置
        over 3 : integer        #结束位置
        mails 4 : *mailCell     #邮件简要信息
        cover 5 : mailCover     #邮件封面信息
        autoViewMids 6 : *integer #本次请求自动已读的邮件ID, 客户端显示小红点用, 目前只采集邮件有
    }
}

#请求邮件详细信息/查看邮件
reqMailDetail 1603 {
    request {
        setType 0 : integer     #集合类型
        mid 1 : integer         #邮件id
        idx 2 : integer         #战报索引
    }
    response {
        code 0 : integer         #错误码
        setType 1 : integer      #集合类型
        mid 2 : integer          #邮件id
        detail 3 : mailDetail    #邮件详细信息
        cover 4 : mailCover      #邮件封面信息
        idx 5 : integer          #战报索引
    }
}

#删除邮件
reqDelMail 1604 {
    request {
        setType 0 : integer     #集合类型
        mids 1 : *integer      #邮件ids
    }
    response {
        code 0 : integer       #错误码
        setType 1 : integer    #集合类型
        mids 2 : *integer      #成功删除的邮件ids
    }
}

#领取邮件附件
reqGetMailExtra 1605 {
    request {
        mid 0 : integer      #邮件id
        setType 1 : integer  #集合类型
    }
    response {
        code 0 : integer     #返回码
        setType 1 : integer  #集合类型
        mid 2 : integer      #邮件id
    }
}

#一键领取邮件附件
reqGetMailExtraOneKey 1606 {
    request {
        setTypes 0 : *integer     #集合类型
    }
    response {
        code 0 : integer        #错误码
        mids 1 : *integer        #成功的邮件ids
        covers 2 : *mailCover   #邮件封面数据
        extra 3 : rewardlib      #附件奖励
    }
}

#请求收藏邮件
reCollectMail 1607 {
    request {
        mid 0 : integer         #邮件id
        setType 1 : integer     #集合类型
    }
    response {
        code 0 : integer        #错误码
        mid 1 : integer         #邮件id
        setType 2 : integer     #集合类型
        covers 3 : *mailCover   #邮件封面数据
    }
}

#一键删除邮件
reqDelMailOneKey 1608 {
    request {
        setType 0 : integer     #集合类型
    }
    response {
        code 0 : integer        #错误码
        setType 1 : integer     #集合类型
        mids 2 : *integer       #成功的邮件ids
        cover 3 : mailCover     #邮件封面信息
    }
}

#请求邮件战报单场回放数据
reqReport 1609 {
    request {
        setType 0 : integer     #集合类型
        mid 1 : integer         #邮件id
        idx 2 : integer         #战报索引
    }
    response {
        code 0 : integer        #错误码
        setType 1 : integer     #集合类型
        mid 2 : integer         #邮件id
        idx 3 : integer         #战报索引
        report 4 : battleReportOne #单场战报详情(大量数据)
    }
}
]]


mailproto.s2c = mailproto.type .. [[
#邮件 1601 ～ 1700

#新邮件
newMail 1655 {#
    request {
        mail 0 : mailCell     #邮件简要信息
        cover 1 : mailCover   #邮件封面信息
        setType 2 : integer   #集合类型
    }
}

#删除邮件
removeMail 1656 {
    request {
        setType 0 : integer     #集合类型
        mids 1 : integer        #邮件ids
        cover 2 : mailCover     #邮件封面信息
    }
}

]]

return mailproto