-------fixtest.lua
-------
local skynet = require ("skynet")
local cluster = require ("cluster")

xpcall(function()
	Log.i("=====fixtest begin")
	print("=====fixtest begin")


	Log.i("=====fixtest end")
	print("=====fixtest end")
end,svrFunc.exception)