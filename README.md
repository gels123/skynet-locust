# sn-locust
## Description
A high performence load test tool, implement with [skynet](https://github.com/cloudwu/skynet) and [locust](https://github.com/locustio/locust).

## Install
pull submodule
```
git submodule update --init
```
build linux
```
make linux
```
or macosx
```
make macosx
```

## run
```
1. execute locust.sql first
2. check dbconf.lua is all right
3. start in shell => ./start.sh
```
open the browser with default url http://127.0.0.1:7001 