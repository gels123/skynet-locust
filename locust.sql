/*
 Navicat MySQL Data Transfer
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for conf_cluster
-- ----------------------------
CREATE TABLE IF NOT EXISTS `conf_cluster`  (
  `nodeid` int(11) NOT NULL AUTO_INCREMENT COMMENT '节点ID',
  `nodename` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT '节点名',
  `ip` varchar(64) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT '专网IP(尽量填固定专网IP, 优先级高于web域名)',
  `web` varchar(64) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT '域名',
  `listen` varchar(64) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT '监听(填0.0.0.0)',
  `listennodename` varchar(64) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT '监听节点名',
  `port` int(11) NOT NULL COMMENT '端口',
  `portdebug` int(11) NOT NULL COMMENT '调试控制台端口号',
  `porthttp` int(11) NOT NULL COMMENT 'http端口号',
  `portwebsock` int(11) NOT NULL COMMENT 'websockect端口号',
  PRIMARY KEY (`nodeid`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 10003 CHARACTER SET = latin1 COLLATE = latin1_swedish_ci COMMENT = 'cluster集群配置' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records for conf_cluster
-- ----------------------------
INSERT INTO `conf_cluster` (`nodeid`, `nodename`, `ip`, `web`, `listen`, `listennodename`, `port`, `portdebug`, `porthttp`, `portwebsock`) VALUES (1, 'node_locust', '127.0.0.1', '127.0.0.1', '0.0.0.0', 'listen_node_locust', 7000, 7002, 7001, 7003) ON DUPLICATE KEY UPDATE nodeid = 1;
