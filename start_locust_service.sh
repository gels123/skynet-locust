#!/usr/bin/env bash
export PATH=${PATH}:/usr/local/mysql/bin
chmod +x ./start_locust_service.sh ./stop_locust_service.sh ./skynet/skynet ./skynet/3rd/lua/lua;
if [ ! -d "./log" ]; then
  mkdir ./log;
fi
chmod 777 ./log;
ulimit -n 65535;

#删除启动成功标志文件
if [ -f "./startsuccess_locust" ]; then
  rm -f ./startsuccess_locust;
fi

if [ ! -f "./dbconflocal.lua" ]; then
  #后台启动
  if [ -f "./game/locuststartconf_daemon" ]; then
    rm -f ./game/locuststartconf_daemon;
  fi
  cp ./game/locuststartconf ./game/locuststartconf_daemon;
  sed -i 's/-- daemon/daemon/g' ./game/locuststartconf_daemon;
  `pwd`/skynet/skynet game/locuststartconf_daemon
else
  #控制台启动
  if [ -f "./game/locuststartconf_daemon" ]; then
    rm -f ./game/locuststartconf_daemon;
  fi
  `pwd`/skynet/skynet game/locuststartconf
fi

