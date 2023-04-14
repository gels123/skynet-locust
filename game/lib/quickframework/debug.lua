--[[

Copyright (c) 2011-2014 chukong-inc.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

--[[--


]]
local dbconf = require("dbconf")
function DEPRECATED(newfunction, oldname, newname)
    return function(...)
        PRINT_DEPRECATED(string.format("%s() is deprecated, please use %s()", oldname, newname))
        return newfunction(...)
    end
end

--[[--


]]
function PRINT_DEPRECATED(msg)
    if not DISABLE_DEPRECATED_WARNING then
        printf("[DEPRECATED] %s", msg)
    end
end

--[[--

打印调试信息

### 用法示例

~~~ lua

printLog("WARN", "Network connection lost at %d", os.time())

~~~

@param string tag 调试信息的 tag
@param string fmt 调试信息格式
@param [mixed ...] 更多参数

]]
function printLog(tag, fmt, ...)
    local t = {
        "[",
        string.upper(tostring(tag)),
        "] ",
        string.format(tostring(fmt), ...)
    }
    print(table.concat(t))
end

--[[--

输出 tag 为 ERR 的调试信息

@param string fmt 调试信息格式
@param [mixed ...] 更多参数

]]
function printError(fmt, ...)
    printLog("ERR", fmt, ...)
    print(debug.traceback("", 2))
end

--[[--

输出 tag 为 INFO 的调试信息

@param string fmt 调试信息格式
@param [mixed ...] 更多参数

]]
function printInfo(fmt, ...)
    printLog("INFO", fmt, ...)
end

-- 获取dump字符串
function transformTableToString(value, desciption, nesting)
    if type(nesting) ~= "number" then nesting = 9 end

    local lookupTable = {}
    local result = {}

    local function _v(v)
        if type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        return tostring(v)
    end

--    local traceback = string.split(debug.traceback("", 2), "\n")
--    print("dump from: " .. string.trim(traceback[3]))

    local function _dump(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(_v(desciption)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, _v(desciption), spc, _v(value))
        elseif lookupTable[value] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, desciption, spc)
        else
            lookupTable[value] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, desciption)
            else
                result[#result +1 ] = string.format("%s%s = {", indent, _v(desciption))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = _v(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    _dump(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    _dump(value, desciption, "- ", 1)

    -- local output = ""
    -- for i, line in ipairs(result) do
    --     output = output .. line .. "\n"
    -- end

    -- return output
    return table.concat(result, "\n")
end

--[[--

输出值的内容

### 用法示例

~~~ lua

local t = {comp = "chukong", engine = "quick"}

Log.dump(t)

~~~

@param mixed value 要输出的值

@param [string desciption] 输出内容前的文字描述

@parma [integer nesting] 输出时的嵌套层级，默认为 3

]]
function dump(value, desciption, nesting)
    if not dbconf.DEBUG then
        return
    end
    print(transformTableToString(value, desciption, nesting))
end

--[[ 
===========ZBStudio Remote Debug============
完整配置:
dbconf.remotedebug = {
    isopen = true,
    ip = "127.0.0.1",
    port = 8172,
    package_path = ";game/lib/zbstudio/lualibs/mobdebug/?.lua;game/lib/zbstudio/lualibs/?.lua",
    package_cpath = "game/lib/zbstudio/clibs53/?.dylib",
}
以上配置除了isopen之外都有默认值，所以最简单的配置就是只写个isopen=true就可以打开了，默认值如上表所示。

使用方法(Mac)：
1. 按上述配置配好dbconf.lua.
2. 打开ZBStudio, 再打开要调试的工程目录。
3. 在要调用的Lua代码的开始处调用startRemoteDebug()函数，一般是ctor()内。
4. 切到ZBStudio, 在菜单栏上点Project->Start Debug Server开启调试服务器。
5. 启动skynet程序。
6. 在ZBStudio愉，找到要调试的地方下断点(Command+F9), 然后操作游戏触发这段逻辑即可断住。
]]
if dbconf.remotedebug and dbconf.remotedebug.isopen then
    if dbconf.remotedebug.package_path and dbconf.remotedebug.package_cpath then
        package.path = package.path .. dbconf.remotedebug.package_path
        package.cpath = package.cpath .. dbconf.remotedebug.package_cpath
    else
        dbconf.remotedebug.platform = dbconf.remotedebug.platform or "macosx"
        if dbconf.remotedebug.platform == "macosx" then
            package.path = package.path .. ";game/lib/zbstudio/lualibs/mobdebug/?.lua;game/lib/zbstudio/lualibs/?.lua"
            package.cpath = package.cpath .. "game/lib/zbstudio/clibs53/?.dylib"
        elseif dbconf.remotedebug.platform == "linux" then
            package.path = package.path .. ";game/lib/zbstudio/lualibs/mobdebug/?.lua;game/lib/zbstudio/lualibs/?.lua"
            package.cpath = package.cpath .. "game/lib/zbstudio/clibs53/?.so"
        end
    end

    dbconf.remotedebug.ip = dbconf.remotedebug.ip or "127.0.0.1"
end

-- 开启远程调试
function startRemoteDebug()
    if dbconf.remotedebug and dbconf.remotedebug.isopen then
        --local sharedataLib = require "sharedataLib"
        --local ret = sharedataLib.query("remotedebug")
        
        --Log.e("startRemoteDebug===", ret)
        --if not ret then
            require("mobdebug").start(dbconf.remotedebug.ip, dbconf.remotedebug.port)
            --sharedataLib.new("remotedebug", SERVICE_NAME)

            Log.d(">>Start zbstudio's remote debug.")
        --else
            --Log.e("remote debug more than one session,last svr--->>",ret)
        --end
    end
end

-- 关闭远程调试
function stopRemoteDebug()
    if dbconf.remotedebug and dbconf.remotedebug.isopen then
        --local sharedataLib = require "sharedataLib"
        --sharedataLib.delete("remotedebug")

        require("mobdebug").done()

        Log.d("<<Stop zbstudio's remote debug.")
    end
end

-- 是否是PM环境
function isPMEnv()
    return dbconf.DEBUG and dbconf.BACK_DOOR and dbconf.ISCHEAT
end

