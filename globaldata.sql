/*
 Navicat MySQL Data Transfer

 Source Server         : localhost_root2_1
 Source Server Type    : MySQL
 Source Host           : 192.168.0.106:3306
 Source Schema         : globaldata
 File Encoding         : 65001
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for droplimitinfo
-- ----------------------------
CREATE TABLE IF NOT EXISTS `droplimitinfo`  (
    `id` int NOT NULL,
    `data` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL,
    `createtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatetime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`) USING BTREE,
    INDEX `key_droplimitinfo_id`(`id`) USING BTREE,
    INDEX `key_droplimitinfo_updatetime`(`updatetime`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '全局掉落信息' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for tradeinfo
-- ----------------------------
CREATE TABLE IF NOT EXISTS `tradeinfo`  (
    `id` int NOT NULL,
    `data` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL,
    `createtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatetime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`) USING BTREE,
INDEX `key_tradeinfo_id`(`id`) USING BTREE,
INDEX `key_tradeinfo_updatetime`(`updatetime`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '交易行信息' ROW_FORMAT = Dynamic;
