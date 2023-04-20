##########################################################################################
# Platform auto detect
##########################################################################################
SUPPORTED_PLATFORMS := linux darwin
PLATFORMNAME        ?= $(shell echo $(shell uname) | tr "[:upper:]" "[:lower:]")
$(if $(findstring $(PLATFORMNAME),$(SUPPORTED_PLATFORMS)),,$(error "Unsupported os, must be one of '$(SUPPORTED_PLATFORMS)'"))

##########################################################################################
# Compile commands
##########################################################################################
.PHONY: all darwin macosx clean help

all: $(PLATFORMNAME)

linux:
	@echo "========== make skynet start =========="
	cd ./skynet;make clean;make linux
	@echo "========== make skynet end =========="

	@echo "\n\n========== make lua-json start =========="
	cd ./game/lib/lua-json;make linux
	@echo "========== make lua-json end =========="

	@echo "\n\n========== make lua-encrypt start =========="
	cd ./game/lib/lua-encrypt;make linux
	@echo "========== make lua-encrypt end =========="

	@echo "\n\n========== make lua-crc32 start =========="
	cd ./game/lib/lua-crc32;make linux
	@echo "========== make lua-crc32 end =========="

	@echo "\n\n========== make lua-lfs start =========="
	cd ./game/lib/lua-lfs;make linux
	@echo "========== make lua-lfs end =========="

	@echo "\n\n========== make lua-curl start =========="
	cd ./game/lib/lua-curl;make linux
	@echo "========== make lua-curl end =========="

	@echo "\n\n========== make lua-zset start =========="
	cd ./game/lib/lua-zset;make linux
	@echo "========== make lua-zset end =========="

	@echo "\n\n========== make lua-extra start =========="
	cd ./game/lib/lua-extra;make linux
	@echo "========== make lua-extra end =========="

	@echo "\n\n========== make lua-hmac_sha256 start =========="
	cd ./game/lib/lua-hmac_sha256;make linux
	@echo "========== make lua-hmac_sha256 end =========="

macosx: darwin

darwin:
	@echo "========== make skynet start =========="
	cd ./skynet;make macosx
	@echo "========== make skynet end =========="

	@echo "\n\n========== make lua-json start =========="
	cd ./game/lib/lua-json;make macosx
	@echo "========== make lua-json end =========="

	@echo "\n\n========== make lua-encrypt start =========="
	cd ./game/lib/lua-encrypt;make macosx
	@echo "========== make lua-encrypt end =========="

	@echo "\n\n========== make lua-crc32 start =========="
	cd ./game/lib/lua-crc32;make macosx
	@echo "========== make lua-crc32 end =========="

	@echo "\n\n========== make lua-lfs start =========="
	cd ./game/lib/lua-lfs;make macosx
	@echo "========== make lua-lfs end =========="

	@echo "\n\n========== make lua-curl start =========="
	cd ./game/lib/lua-curl;make macosx
	@echo "========== make lua-curl end =========="

	@echo "\n\n========== make lua-zset start =========="
	cd ./game/lib/lua-zset;make macosx
	@echo "========== make lua-zset end =========="

	@echo "\n\n========== make lua-extra start =========="
	cd ./game/lib/lua-extra;make linux
	@echo "========== make lua-extra end =========="

	@echo "\n\n========== make lua-hmac_sha256 start =========="
	cd ./game/lib/lua-hmac_sha256;make macosx
	@echo "========== make lua-hmac_sha256 end =========="
	
clean:
	@echo "========== clean skynet start =========="
	cd ./skynet;make cleanall
	@echo "========== clean skynet end =========="

	@echo "\n\n========== clean lua-json start =========="
	cd ./game/lib/lua-json;make clean
	@echo "========== clean lua-json end =========="

	@echo "\n\n========== clean lua-encrypt start =========="
	cd ./game/lib/lua-encrypt;make clean
	@echo "========== clean lua-encrypt end =========="

	@echo "\n\n========== clean lua-crc32 start =========="
	cd ./game/lib/lua-crc32;make clean
	@echo "========== clean lua-crc32 end =========="

	@echo "\n\n========== clean lua-lfs start =========="
	cd ./game/lib/lua-lfs;make clean
	@echo "========== clean lua-lfs end =========="

	@echo "\n\n========== clean lua-curl start =========="
	cd ./game/lib/lua-curl;make clean
	@echo "========== clean lua-curl end =========="

	@echo "\n\n========== clean lua-zset start =========="
	cd ./game/lib/lua-zset;make clean
	@echo "========== clean lua-zset end =========="

	@echo "\n\n========== clean lua-extra start =========="
	cd ./game/lib/lua-extra;make clean
	@echo "========== clean lua-extra end =========="

	@echo "\n\n========== clean lua-hmac_sha256 start =========="
	cd ./game/lib/lua-hmac_sha256;make clean
	@echo "========== clean lua-hmac_sha256 end =========="

help:
	@echo "  * linux"
	@echo "  * macosx"
	@echo "  * clean"
