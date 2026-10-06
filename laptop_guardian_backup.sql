-- MariaDB dump 10.19  Distrib 10.4.32-MariaDB, for Win64 (AMD64)
--
-- Host: 127.0.0.1    Database: laptop_guardian
-- ------------------------------------------------------
-- Server version	10.4.32-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `activity_logs`
--

DROP TABLE IF EXISTS `activity_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `activity_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `device_id` varchar(32) NOT NULL,
  `event_type` varchar(50) NOT NULL,
  `event_details` text DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `location_label` varchar(200) DEFAULT NULL,
  `laptop_time` datetime DEFAULT NULL,
  `laptop_timezone` varchar(100) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_activity_device` (`device_id`),
  KEY `idx_activity_created` (`created_at`),
  KEY `idx_activity_type` (`event_type`),
  CONSTRAINT `fk_activity_device` FOREIGN KEY (`device_id`) REFERENCES `devices` (`device_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=50 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `activity_logs`
--

LOCK TABLES `activity_logs` WRITE;
/*!40000 ALTER TABLE `activity_logs` DISABLE KEYS */;
INSERT INTO `activity_logs` VALUES (1,'LG-8EC25AEC','STARTUP','Device paired/started. User: BABISH, OS: Windows 11 Home Single Language',NULL,NULL,NULL,NULL,NULL,'2026-09-09 17:10:14'),(2,'LG-8EC25AEC','LOCK_REQUESTED','Remote lock requested by owner (User ID: 1). Command ID: 1',NULL,NULL,NULL,NULL,NULL,'2026-09-09 17:10:15'),(3,'LG-8EC25AEC','LOCK','Windows Workstation locked successfully via remote command.',NULL,NULL,NULL,NULL,NULL,'2026-09-09 17:10:16'),(4,'LG-8EC25AEC','UNLOCK','Laptop Unlocked by Windows user: BABISH',NULL,NULL,NULL,NULL,NULL,'2026-09-09 17:10:16'),(5,'LG-8EC25AEC','SLEEP','Laptop entered sleep mode',NULL,NULL,NULL,NULL,NULL,'2026-09-09 17:10:16'),(6,'LG-8EC25AEC','WAKE','Laptop woke up from sleep',NULL,NULL,NULL,NULL,NULL,'2026-09-09 17:10:16'),(7,'LG-8EC25AEC','UNEXPECTED_OFFLINE','Test unexpected offline',NULL,NULL,NULL,NULL,NULL,'2026-09-09 17:10:16'),(8,'LG-38557424','STARTUP','Device paired/started. User: BABISH, OS: Windows 11 Home Single Language',NULL,NULL,NULL,NULL,NULL,'2026-09-10 19:34:11'),(9,'LG-38557424','UNEXPECTED_OFFLINE','Unexpected offline event detected. No heartbeat for >30s.',NULL,NULL,NULL,NULL,NULL,'2026-09-10 19:34:47'),(10,'laptop_5f93285a4da0','STARTUP','Device paired/started. User: , OS: ',NULL,NULL,NULL,NULL,NULL,'2026-09-10 21:06:44'),(11,'laptop_d13f71757cfe','STARTUP','Device paired/started. User: , OS: ',NULL,NULL,NULL,NULL,NULL,'2026-09-10 21:09:53'),(12,'laptop_a2cf2863e80d','STARTUP','Device paired/started. User: , OS: ',NULL,NULL,NULL,NULL,NULL,'2026-09-10 21:10:36'),(13,'laptop_a2cf2863e80d','LOCK','Remote lock executed.',NULL,NULL,NULL,NULL,NULL,'2026-09-10 21:10:36'),(14,'laptop_fd84ab835a8b','STARTUP','Device paired/started. User: , OS: ',NULL,NULL,NULL,NULL,NULL,'2026-09-10 21:11:00'),(15,'laptop_fd84ab835a8b','LOCK','Remote lock executed.',NULL,NULL,NULL,NULL,NULL,'2026-09-10 21:11:00'),(16,'laptop_5f93285a4da0','UNEXPECTED_OFFLINE','Unexpected offline event detected. No heartbeat for >60s.',NULL,NULL,NULL,NULL,NULL,'2026-09-10 21:22:53'),(17,'laptop_d13f71757cfe','UNEXPECTED_OFFLINE','Unexpected offline event detected. No heartbeat for >60s.',NULL,NULL,NULL,NULL,NULL,'2026-09-10 21:22:53'),(18,'laptop_a2cf2863e80d','UNEXPECTED_OFFLINE','Unexpected offline event detected. No heartbeat for >60s.',NULL,NULL,NULL,NULL,NULL,'2026-09-10 21:22:53'),(19,'laptop_fd84ab835a8b','UNEXPECTED_OFFLINE','Unexpected offline event detected. No heartbeat for >60s.',NULL,NULL,NULL,NULL,NULL,'2026-09-10 21:22:53'),(20,'LG-B889ED4B','STARTUP','Device paired/started. User: BABISH, OS: Windows 11',NULL,NULL,NULL,NULL,NULL,'2026-09-10 22:21:55'),(21,'LG-B889ED4B','UNEXPECTED_OFFLINE','Unexpected offline event detected. No heartbeat for >60s.',NULL,NULL,NULL,NULL,NULL,'2026-09-10 22:22:56'),(22,'LG-B889ED4B','STARTUP','Device paired/started. User: BABISH, OS: Windows 11',NULL,NULL,NULL,NULL,NULL,'2026-09-10 22:27:05'),(23,'LG-B889ED4B','STARTUP','Agent started. Device: LG-B889ED4B',13.0895000,80.2739000,'Chennai, Tamil Nadu, India (Approximate)','2026-09-10 22:27:27','Asia/Calcutta','2026-09-10 22:27:27'),(24,'LG-B889ED4B','SHUTDOWN','Agent clean shutdown.',13.0895000,80.2739000,'Chennai, Tamil Nadu, India (Approximate)','2026-09-10 22:27:27','Asia/Calcutta','2026-09-10 22:27:27'),(25,'LG-B889ED4B','STARTUP','Agent started. Device: LG-B889ED4B',13.0895000,80.2739000,'Chennai, Tamil Nadu, India (Approximate)','2026-09-10 22:34:29','Asia/Calcutta','2026-09-10 22:34:29'),(26,'LG-B889ED4B','SHUTDOWN','Agent clean shutdown.',13.0895000,80.2739000,'Chennai, Tamil Nadu, India (Approximate)','2026-09-10 22:34:29','Asia/Calcutta','2026-09-10 22:34:29'),(27,'LG-B889ED4B','STARTUP','Agent started. Device: LG-B889ED4B',13.0895000,80.2739000,'Chennai, Tamil Nadu, India (Approximate)','2026-09-10 22:35:12','Asia/Calcutta','2026-09-10 22:35:12'),(28,'LG-B889ED4B','SHUTDOWN','Agent clean shutdown.',13.0895000,80.2739000,'Chennai, Tamil Nadu, India (Approximate)','2026-09-10 22:35:12','Asia/Calcutta','2026-09-10 22:35:12'),(29,'LG-B889ED4B','STARTUP','Agent started. Device: LG-B889ED4B',13.0895000,80.2739000,'Chennai, Tamil Nadu, India (Approximate)','2026-09-10 22:35:48','Asia/Calcutta','2026-09-10 22:35:48'),(30,'LG-B889ED4B','STARTUP','Agent started. Device: LG-B889ED4B',13.0895000,80.2739000,'Chennai, Tamil Nadu, India (Approximate)','2026-09-10 22:36:41','Asia/Calcutta','2026-09-10 22:36:41'),(31,'LG-B889ED4B','UNEXPECTED_OFFLINE','Unexpected offline event detected. No heartbeat for >60s.',NULL,NULL,NULL,NULL,NULL,'2026-09-11 20:17:49'),(32,'laptop_77ac0b0e3cb5','STARTUP','Device paired/started. User: , OS: ',NULL,NULL,NULL,NULL,NULL,'2026-09-11 20:35:49'),(33,'laptop_77ac0b0e3cb5','LOCK','Remote lock executed.',NULL,NULL,NULL,NULL,NULL,'2026-09-11 20:35:49'),(34,'laptop_77ac0b0e3cb5','UNEXPECTED_OFFLINE','Unexpected offline event detected. No heartbeat for >60s.',NULL,NULL,NULL,NULL,NULL,'2026-09-11 20:36:52'),(35,'LG-B889ED4B','STARTUP','Agent started. Device: LG-B889ED4B',13.0895000,80.2739000,'Chennai, Tamil Nadu, India (Approximate)','2026-09-11 20:54:41','Asia/Calcutta','2026-09-11 20:54:41'),(36,'LG-B889ED4B','LOCK','Remote lock executed.',13.0895000,80.2739000,'Chennai, Tamil Nadu, India (Approximate)','2026-09-11 20:57:01','Asia/Calcutta','2026-09-11 20:57:01'),(37,'LG-B889ED4B','LOCK','Remote lock executed.',NULL,NULL,NULL,NULL,NULL,'2026-09-11 20:57:01'),(38,'LG-B889ED4B','SHUTDOWN','Remote shutdown initiated.',13.0895000,80.2739000,'Chennai, Tamil Nadu, India (Approximate)','2026-09-11 20:57:21','Asia/Calcutta','2026-09-11 20:57:21'),(39,'LG-B889ED4B','SHUTDOWN','Remote shutdown executed.',NULL,NULL,NULL,NULL,NULL,'2026-09-11 20:57:21'),(40,'laptop_8b094211eaaf','STARTUP','Device paired/started. User: , OS: ',NULL,NULL,NULL,NULL,NULL,'2026-09-11 21:25:58'),(41,'laptop_8b094211eaaf','LOCK','Remote lock executed.',NULL,NULL,NULL,NULL,NULL,'2026-09-11 21:25:58'),(42,'laptop_8b094211eaaf','UNEXPECTED_OFFLINE','Unexpected offline event detected. No heartbeat for >60s.',NULL,NULL,NULL,NULL,NULL,'2026-09-11 21:32:13'),(43,'LG-B889ED4B','STARTUP','Agent started. Device: LG-B889ED4B',10.8949920,76.9951690,'Hindusthan School Of Architecture, Coimbatore, Tamil Nadu, India (Exact - GPS/Wi-Fi)','2026-09-11 21:33:11','Asia/Calcutta','2026-09-11 21:33:12'),(44,'LG-B889ED4B','SHUTDOWN','Remote shutdown initiated.',10.8949920,76.9951690,'Hindusthan School Of Architecture, Coimbatore, Tamil Nadu, India (Exact - GPS/Wi-Fi)','2026-09-11 21:37:13','Asia/Calcutta','2026-09-11 21:37:13'),(45,'LG-B889ED4B','SHUTDOWN','Remote shutdown executed.',NULL,NULL,NULL,NULL,NULL,'2026-09-11 21:37:13'),(46,'laptop_b6949cfc0eaf','STARTUP','Device paired/started. User: , OS: ',NULL,NULL,NULL,NULL,NULL,'2026-09-11 22:06:56'),(47,'laptop_b6949cfc0eaf','LOCK','Remote lock executed.',NULL,NULL,NULL,NULL,NULL,'2026-09-11 22:06:56'),(48,'laptop_b6949cfc0eaf','UNEXPECTED_OFFLINE','Unexpected offline event detected. No heartbeat for >60s.',NULL,NULL,NULL,NULL,NULL,'2026-09-19 18:30:05'),(49,'LG-B889ED4B','UNEXPECTED_OFFLINE','Unexpected offline event detected. No heartbeat for >60s.',NULL,NULL,NULL,NULL,NULL,'2026-09-19 19:01:04');
/*!40000 ALTER TABLE `activity_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `commands`
--

DROP TABLE IF EXISTS `commands`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `commands` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `device_id` varchar(32) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `command` varchar(32) NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'PENDING',
  `created_at` datetime DEFAULT current_timestamp(),
  `executed_at` datetime DEFAULT NULL,
  `result` text DEFAULT NULL,
  `expires_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_commands_device_status` (`device_id`,`status`),
  CONSTRAINT `fk_commands_device` FOREIGN KEY (`device_id`) REFERENCES `devices` (`device_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `commands`
--

LOCK TABLES `commands` WRITE;
/*!40000 ALTER TABLE `commands` DISABLE KEYS */;
INSERT INTO `commands` VALUES (1,'LG-8EC25AEC',NULL,'LOCK','EXECUTED','2026-09-09 17:10:15','2026-09-09 17:10:16',NULL,NULL),(2,'laptop_d13f71757cfe',9,'LOCK','RECEIVED','2026-09-10 21:09:53',NULL,NULL,'2026-09-10 15:44:53'),(3,'laptop_a2cf2863e80d',11,'LOCK','EXECUTED','2026-09-10 21:10:36','2026-09-10 15:40:36','Workstation locked successfully.','2026-09-10 15:45:36'),(4,'laptop_fd84ab835a8b',13,'LOCK','EXECUTED','2026-09-10 21:11:00','2026-09-10 15:41:00','Workstation locked successfully.','2026-09-10 15:46:00'),(5,'laptop_77ac0b0e3cb5',16,'LOCK','EXECUTED','2026-09-11 20:35:49','2026-09-11 15:05:49','Workstation locked successfully.','2026-09-11 15:10:49'),(6,'LG-B889ED4B',15,'LOCK','EXECUTED','2026-09-11 20:56:56','2026-09-11 15:27:01','Windows session locked.','2026-09-11 15:31:56'),(7,'LG-B889ED4B',15,'SHUTDOWN','EXECUTED','2026-09-11 20:57:03','2026-09-11 15:27:21','Shutdown command issued.','2026-09-11 15:32:03'),(8,'laptop_8b094211eaaf',18,'LOCK','EXECUTED','2026-09-11 21:25:58','2026-09-11 15:55:58','Workstation locked successfully.','2026-09-11 16:00:58'),(9,'LG-B889ED4B',15,'SHUTDOWN','EXECUTED','2026-09-11 21:36:55','2026-09-11 16:07:13','Shutdown command issued.','2026-09-11 16:11:55'),(10,'laptop_b6949cfc0eaf',20,'LOCK','EXECUTED','2026-09-11 22:06:56','2026-09-11 16:36:56','Workstation locked successfully.','2026-09-11 16:41:56');
/*!40000 ALTER TABLE `commands` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `devices`
--

DROP TABLE IF EXISTS `devices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `devices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `device_id` varchar(32) NOT NULL,
  `device_token_hash` varchar(255) DEFAULT NULL,
  `device_name` varchar(150) NOT NULL DEFAULT 'Laptop',
  `os` varchar(150) DEFAULT NULL,
  `cpu` varchar(150) DEFAULT NULL,
  `ram` varchar(50) DEFAULT NULL,
  `storage` varchar(50) DEFAULT NULL,
  `gpu` varchar(255) DEFAULT NULL,
  `manufacturer` varchar(150) DEFAULT NULL,
  `model` varchar(150) DEFAULT NULL,
  `username` varchar(100) DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `timezone` varchar(100) DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'OFFLINE',
  `battery` int(11) DEFAULT NULL,
  `charging` tinyint(1) DEFAULT 0,
  `last_seen` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `device_id` (`device_id`),
  KEY `idx_device_user` (`user_id`),
  KEY `idx_device_id` (`device_id`),
  KEY `idx_device_status` (`status`),
  KEY `idx_device_last_seen` (`last_seen`),
  CONSTRAINT `fk_devices_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `devices`
--

LOCK TABLES `devices` WRITE;
/*!40000 ALTER TABLE `devices` DISABLE KEYS */;
INSERT INTO `devices` VALUES (1,1,'LG-8EC25AEC','027d40ef84489fa4d357703a3f171e026d7e1413e0191ae314136baa99bb37ca','Acer ALG Test Rig','Windows 11 Home Single Language','Intel(R) Core(TM) 5 210H','16 GB','477 GB','Intel Graphics | NVIDIA RTX 3050',NULL,NULL,'BABISH',NULL,NULL,'OFFLINE',75,1,'2026-09-09 17:09:16','2026-09-09 17:10:14','2026-09-09 17:10:16'),(2,2,'LG-38557424','4b1b6b3201c15371057805bfd927a26924bc95d3b4910805e272b33a29a8522f','Acer ALG AL15G-53','Windows 11 Home Single Language','Intel(R) Core(TM) 5 210H','16 GB','475 GB','Intel(R) Graphics | NVIDIA GeForce RTX 3050 6GB Laptop GPU',NULL,NULL,'BABISH',NULL,NULL,'OFFLINE',NULL,0,'2026-09-10 19:34:11','2026-09-10 19:34:11','2026-09-10 19:34:47'),(3,7,'laptop_5f93285a4da0','86d1c34a4c863168a0bbf02163728c544be6ee2c8f9dc175e2ffae3cc8300afc','Antigravity Test Laptop','','','','','','Dell','XPS 15','',NULL,NULL,'OFFLINE',NULL,0,'2026-09-10 15:52:53','2026-09-10 21:06:44','2026-09-10 21:22:53'),(4,9,'laptop_d13f71757cfe','fee63105b954036a7f762dad42fbaafb3a461a25b592c2c4d53c4f6a83600000','Antigravity Test Laptop','','','','','','Dell','XPS 15','','192.168.1.50','UTC','OFFLINE',87,0,'2026-09-10 15:52:53','2026-09-10 21:09:53','2026-09-10 21:22:53'),(5,11,'laptop_a2cf2863e80d','2f0f7123e07f63792ab9b840637f0fde90cc0c39e94e5343dcb91d091c86d03a','Antigravity Test Laptop','','','','','','Dell','XPS 15','','192.168.1.50','UTC','OFFLINE',87,0,'2026-09-10 15:52:53','2026-09-10 21:10:36','2026-09-10 21:22:53'),(6,13,'laptop_fd84ab835a8b','ffeba71ba766cb4c0a406cbc43728c1158d20db26edcfccb4573e2846f03ea1b','Antigravity Test Laptop','','','','','','Dell','XPS 15','','192.168.1.50','UTC','OFFLINE',87,0,'2026-09-10 15:52:53','2026-09-10 21:11:00','2026-09-10 21:22:53'),(7,15,'LG-B889ED4B','466c6beb5b6e5e4f4abf5249fdf90650d7d6d7ce520658a283ee675c72ec45a8','DESKTOP-T6TEM4H','Windows 11','','','','','','','BABISH','172.29.27.74','Asia/Calcutta','OFFLINE',46,0,'2026-09-19 13:31:04','2026-09-10 22:21:55','2026-09-19 19:01:04'),(8,16,'laptop_77ac0b0e3cb5','f243d983deedffda2f4af12e5f3c99823f05429b173038ebe16f56f186475ba0','Antigravity Test Laptop','','','','','','Dell','XPS 15','','192.168.1.50','UTC','OFFLINE',87,0,'2026-09-11 15:06:52','2026-09-11 20:35:49','2026-09-11 20:36:52'),(9,18,'laptop_8b094211eaaf','5216cae712a107d26e00cbe4c3205694ac0621ab7ad903b52b5a8d1eb882082a','Antigravity Test Laptop','','','','','','Dell','XPS 15','','192.168.1.50','UTC','OFFLINE',87,0,'2026-09-11 16:02:13','2026-09-11 21:25:58','2026-09-11 21:32:13'),(10,20,'laptop_b6949cfc0eaf','e366675bfeb67830a9b87217e8a1e32873323833b5a828840882bb2f61f35595','Antigravity Test Laptop','','','','','','Dell','XPS 15','','192.168.1.50','UTC','OFFLINE',87,0,'2026-09-19 13:00:05','2026-09-11 22:06:56','2026-09-19 18:30:05');
/*!40000 ALTER TABLE `devices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `heartbeats`
--

DROP TABLE IF EXISTS `heartbeats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `heartbeats` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `device_id` varchar(32) NOT NULL,
  `battery` int(3) DEFAULT NULL,
  `charging` tinyint(1) NOT NULL DEFAULT 0,
  `ip_address` varchar(45) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_device_id` (`device_id`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=93 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `heartbeats`
--

LOCK TABLES `heartbeats` WRITE;
/*!40000 ALTER TABLE `heartbeats` DISABLE KEYS */;
INSERT INTO `heartbeats` VALUES (1,'laptop_d13f71757cfe',89,1,'192.168.1.50','2026-09-10 21:09:53'),(2,'laptop_d13f71757cfe',87,0,NULL,'2026-09-10 21:09:54'),(3,'laptop_a2cf2863e80d',89,1,'192.168.1.50','2026-09-10 21:10:36'),(4,'laptop_a2cf2863e80d',87,0,NULL,'2026-09-10 21:10:36'),(5,'laptop_fd84ab835a8b',88,1,'192.168.1.50','2026-09-10 21:11:00'),(6,'laptop_fd84ab835a8b',87,0,NULL,'2026-09-10 21:11:00'),(7,'LG-B889ED4B',31,0,'10.89.154.74','2026-09-10 22:35:48'),(8,'LG-B889ED4B',31,0,'10.89.154.74','2026-09-10 22:36:08'),(9,'LG-B889ED4B',31,0,'10.89.154.74','2026-09-10 22:36:28'),(10,'LG-B889ED4B',31,0,'10.89.154.74','2026-09-10 22:36:41'),(11,'LG-B889ED4B',31,0,'10.89.154.74','2026-09-10 22:36:48'),(12,'LG-B889ED4B',31,0,'10.89.154.74','2026-09-10 22:37:02'),(13,'LG-B889ED4B',30,0,'10.89.154.74','2026-09-10 22:37:08'),(14,'LG-B889ED4B',30,0,'10.89.154.74','2026-09-10 22:37:22'),(15,'LG-B889ED4B',30,0,'10.89.154.74','2026-09-10 22:37:28'),(16,'LG-B889ED4B',30,0,'10.89.154.74','2026-09-10 22:37:42'),(17,'LG-B889ED4B',30,0,'10.89.154.74','2026-09-10 22:37:48'),(18,'LG-B889ED4B',30,0,'10.89.154.74','2026-09-10 22:38:02'),(19,'LG-B889ED4B',30,0,'10.89.154.74','2026-09-10 22:38:08'),(20,'LG-B889ED4B',30,0,'10.89.154.74','2026-09-10 22:38:22'),(21,'LG-B889ED4B',30,0,'10.89.154.74','2026-09-10 22:38:28'),(22,'LG-B889ED4B',30,0,'10.89.154.74','2026-09-10 22:38:42'),(23,'LG-B889ED4B',30,0,'10.89.154.74','2026-09-10 22:38:48'),(24,'LG-B889ED4B',30,0,'10.89.154.74','2026-09-10 22:39:02'),(25,'LG-B889ED4B',30,0,'10.89.154.74','2026-09-10 22:39:08'),(26,'LG-B889ED4B',30,0,'10.89.154.74','2026-09-10 22:39:28'),(27,'LG-B889ED4B',29,0,'10.89.154.74','2026-09-10 22:39:49'),(28,'laptop_77ac0b0e3cb5',88,1,'192.168.1.50','2026-09-11 20:35:49'),(29,'laptop_77ac0b0e3cb5',87,0,NULL,'2026-09-11 20:35:49'),(30,'LG-B889ED4B',75,0,'10.89.154.74','2026-09-11 20:53:58'),(31,'LG-B889ED4B',74,0,'10.89.154.74','2026-09-11 20:54:41'),(32,'LG-B889ED4B',74,0,'10.89.154.74','2026-09-11 20:55:01'),(33,'LG-B889ED4B',74,0,'10.89.154.74','2026-09-11 20:55:21'),(34,'LG-B889ED4B',74,0,'10.89.154.74','2026-09-11 20:55:41'),(35,'LG-B889ED4B',74,0,'10.89.154.74','2026-09-11 20:56:01'),(36,'LG-B889ED4B',74,0,'10.89.154.74','2026-09-11 20:56:21'),(37,'LG-B889ED4B',73,0,'10.89.154.74','2026-09-11 20:56:41'),(38,'LG-B889ED4B',73,0,'10.89.154.74','2026-09-11 20:57:01'),(39,'LG-B889ED4B',73,0,'10.89.154.74','2026-09-11 20:57:21'),(40,'laptop_8b094211eaaf',88,1,'192.168.1.50','2026-09-11 21:25:58'),(41,'laptop_8b094211eaaf',87,0,NULL,'2026-09-11 21:25:58'),(42,'LG-B889ED4B',52,0,'10.89.154.74','2026-09-11 21:33:12'),(43,'LG-B889ED4B',52,0,'10.89.154.74','2026-09-11 21:33:32'),(44,'LG-B889ED4B',51,0,'10.89.154.74','2026-09-11 21:33:52'),(45,'LG-B889ED4B',51,0,'10.89.154.74','2026-09-11 21:34:12'),(46,'LG-B889ED4B',51,0,'10.89.154.74','2026-09-11 21:34:32'),(47,'LG-B889ED4B',51,0,'10.89.154.74','2026-09-11 21:34:52'),(48,'LG-B889ED4B',50,0,'10.89.154.74','2026-09-11 21:35:12'),(49,'LG-B889ED4B',50,0,'10.89.154.74','2026-09-11 21:35:32'),(50,'LG-B889ED4B',50,0,'10.89.154.74','2026-09-11 21:35:52'),(51,'LG-B889ED4B',50,0,'10.89.154.74','2026-09-11 21:36:12'),(52,'LG-B889ED4B',50,0,'10.89.154.74','2026-09-11 21:36:32'),(53,'LG-B889ED4B',50,0,'10.89.154.74','2026-09-11 21:36:53'),(54,'LG-B889ED4B',50,0,'10.89.154.74','2026-09-11 21:37:13'),(55,'laptop_b6949cfc0eaf',88,1,'192.168.1.50','2026-09-11 22:06:56'),(56,'laptop_b6949cfc0eaf',87,0,NULL,'2026-09-11 22:06:56'),(57,'LG-B889ED4B',53,0,'10.89.154.74','2026-09-19 18:30:24'),(58,'LG-B889ED4B',53,0,'10.89.154.74','2026-09-19 18:30:44'),(59,'LG-B889ED4B',53,0,'10.89.154.74','2026-09-19 18:31:04'),(60,'LG-B889ED4B',53,0,'10.89.154.74','2026-09-19 18:31:24'),(61,'LG-B889ED4B',53,0,'10.89.154.74','2026-09-19 18:31:44'),(62,'LG-B889ED4B',52,0,'10.89.154.74','2026-09-19 18:32:04'),(63,'LG-B889ED4B',52,0,'10.89.154.74','2026-09-19 18:32:24'),(64,'LG-B889ED4B',52,0,'10.89.154.74','2026-09-19 18:32:44'),(65,'LG-B889ED4B',52,0,'10.89.154.74','2026-09-19 18:33:04'),(66,'LG-B889ED4B',51,0,'10.89.154.74','2026-09-19 18:34:07'),(67,'LG-B889ED4B',51,0,'10.89.154.74','2026-09-19 18:34:27'),(68,'LG-B889ED4B',51,0,'10.89.154.74','2026-09-19 18:34:47'),(69,'LG-B889ED4B',51,0,'10.89.154.74','2026-09-19 18:35:07'),(70,'LG-B889ED4B',51,0,'10.89.154.74','2026-09-19 18:35:27'),(71,'LG-B889ED4B',51,0,'10.89.154.74','2026-09-19 18:35:47'),(72,'LG-B889ED4B',50,0,'10.89.154.74','2026-09-19 18:36:08'),(73,'LG-B889ED4B',50,0,'10.89.154.74','2026-09-19 18:36:28'),(74,'LG-B889ED4B',50,0,'10.89.154.74','2026-09-19 18:36:48'),(75,'LG-B889ED4B',50,0,'10.89.154.74','2026-09-19 18:37:08'),(76,'LG-B889ED4B',50,0,'10.89.154.74','2026-09-19 18:37:28'),(77,'LG-B889ED4B',50,0,'10.89.154.74','2026-09-19 18:37:48'),(78,'LG-B889ED4B',49,0,'172.29.27.74','2026-09-19 18:38:09'),(79,'LG-B889ED4B',49,0,'172.29.27.74','2026-09-19 18:38:58'),(80,'LG-B889ED4B',49,0,'172.29.27.74','2026-09-19 18:39:18'),(81,'LG-B889ED4B',49,0,'172.29.27.74','2026-09-19 18:39:38'),(82,'LG-B889ED4B',49,0,'172.29.27.74','2026-09-19 18:39:59'),(83,'LG-B889ED4B',48,0,'172.29.27.74','2026-09-19 18:40:19'),(84,'LG-B889ED4B',48,0,'172.29.27.74','2026-09-19 18:40:39'),(85,'LG-B889ED4B',48,0,'172.29.27.74','2026-09-19 18:40:59'),(86,'LG-B889ED4B',48,0,'172.29.27.74','2026-09-19 18:41:19'),(87,'LG-B889ED4B',47,0,'172.29.27.74','2026-09-19 18:41:39'),(88,'LG-B889ED4B',47,0,'172.29.27.74','2026-09-19 18:41:59'),(89,'LG-B889ED4B',47,0,'172.29.27.74','2026-09-19 18:42:19'),(90,'LG-B889ED4B',47,0,'172.29.27.74','2026-09-19 18:42:39'),(91,'LG-B889ED4B',47,0,'172.29.27.74','2026-09-19 18:42:59'),(92,'LG-B889ED4B',46,0,'172.29.27.74','2026-09-19 18:43:19');
/*!40000 ALTER TABLE `heartbeats` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `locations`
--

DROP TABLE IF EXISTS `locations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `locations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `device_id` varchar(32) NOT NULL,
  `latitude` decimal(10,7) NOT NULL,
  `longitude` decimal(10,7) NOT NULL,
  `accuracy` float DEFAULT NULL,
  `source` enum('GPS','WIFI','IP','UNKNOWN') NOT NULL DEFAULT 'UNKNOWN',
  `city` varchar(150) DEFAULT NULL,
  `state` varchar(150) DEFAULT NULL,
  `country` varchar(100) DEFAULT NULL,
  `is_approximate` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_device_id` (`device_id`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `locations`
--

LOCK TABLES `locations` WRITE;
/*!40000 ALTER TABLE `locations` DISABLE KEYS */;
INSERT INTO `locations` VALUES (1,'laptop_d13f71757cfe',37.7749000,-122.4194000,5,'UNKNOWN','San Francisco','California','United States',1,'2026-09-10 21:09:53'),(2,'laptop_a2cf2863e80d',37.7749000,-122.4194000,5,'UNKNOWN','San Francisco','California','United States',1,'2026-09-10 21:10:36'),(3,'laptop_fd84ab835a8b',37.7749000,-122.4194000,5,'UNKNOWN','San Francisco','California','United States',1,'2026-09-10 21:11:00'),(4,'LG-B889ED4B',13.0895000,80.2739000,NULL,'IP','Chennai','Tamil Nadu','India',1,'2026-09-10 22:27:27'),(5,'LG-B889ED4B',13.0895000,80.2739000,NULL,'IP','Chennai','Tamil Nadu','India',1,'2026-09-10 22:34:29'),(6,'LG-B889ED4B',13.0895000,80.2739000,NULL,'IP','Chennai','Tamil Nadu','India',1,'2026-09-10 22:35:12'),(7,'LG-B889ED4B',13.0895000,80.2739000,NULL,'IP','Chennai','Tamil Nadu','India',1,'2026-09-10 22:35:47'),(8,'LG-B889ED4B',13.0895000,80.2739000,NULL,'IP','Chennai','Tamil Nadu','India',1,'2026-09-10 22:36:41'),(9,'laptop_77ac0b0e3cb5',37.7749000,-122.4194000,5,'UNKNOWN','San Francisco','California','United States',1,'2026-09-11 20:35:49'),(10,'LG-B889ED4B',13.0895000,80.2739000,NULL,'IP','Chennai','Tamil Nadu','India',1,'2026-09-11 20:54:41'),(11,'LG-B889ED4B',12.8418000,80.2188000,50000,'GPS','Navalur, Chengalpattu','Tamil Nadu','India',0,'2026-09-11 21:19:37'),(12,'LG-B889ED4B',10.8949920,76.9951690,212,'GPS','Hindusthan School Of Architecture, Coimbatore','Tamil Nadu','India',0,'2026-09-11 21:25:35'),(13,'laptop_8b094211eaaf',37.7749000,-122.4194000,5,'UNKNOWN','San Francisco','California','United States',1,'2026-09-11 21:25:58'),(14,'LG-B889ED4B',10.8949920,76.9951690,212,'GPS','Hindusthan School Of Architecture, Coimbatore','Tamil Nadu','India',0,'2026-09-11 21:33:11'),(15,'laptop_b6949cfc0eaf',37.7749000,-122.4194000,5,'UNKNOWN','San Francisco','California','United States',1,'2026-09-11 22:06:56'),(16,'LG-B889ED4B',11.4873000,79.3011000,50000,'GPS',NULL,NULL,NULL,0,'2026-09-19 18:33:47'),(17,'LG-B889ED4B',13.0719000,80.2579000,200000,'GPS','Zone 5 Royapuram, Chennai','Tamil Nadu','India',0,'2026-09-19 18:38:38');
/*!40000 ALTER TABLE `locations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notification_tokens`
--

DROP TABLE IF EXISTS `notification_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notification_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `token` varchar(255) NOT NULL,
  `platform` varchar(20) NOT NULL DEFAULT 'android',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_token` (`token`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notification_tokens`
--

LOCK TABLES `notification_tokens` WRITE;
/*!40000 ALTER TABLE `notification_tokens` DISABLE KEYS */;
/*!40000 ALTER TABLE `notification_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `device_id` varchar(32) NOT NULL,
  `title` varchar(150) NOT NULL,
  `message` text NOT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_notif_user_read` (`user_id`,`is_read`),
  KEY `idx_notif_device` (`device_id`),
  CONSTRAINT `fk_notif_device` FOREIGN KEY (`device_id`) REFERENCES `devices` (`device_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_notif_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
INSERT INTO `notifications` VALUES (1,1,'LG-8EC25AEC','🟢 Laptop Started','Device LG-8EC25AEC (Acer ALG Test Rig) was successfully registered and connected.',0,'2026-09-09 17:10:14'),(2,1,'LG-8EC25AEC','🔐 Laptop Locked','Laptop LG-8EC25AEC was successfully locked via remote command.',1,'2026-09-09 17:10:16'),(3,1,'LG-8EC25AEC','🚨 Laptop Unlocked','Laptop Unlocked by Windows user: BABISH',0,'2026-09-09 17:10:16'),(4,1,'LG-8EC25AEC','😴 Laptop Sleep','Laptop entered sleep mode',0,'2026-09-09 17:10:16'),(5,1,'LG-8EC25AEC','🟢 Laptop Wake','Laptop woke up from sleep',0,'2026-09-09 17:10:16'),(6,2,'LG-38557424','🟢 Laptop Started','Device LG-38557424 (Acer ALG AL15G-53) was successfully registered and connected.',0,'2026-09-10 19:34:11'),(7,2,'LG-38557424','⚠️ Unexpected Offline','Unexpected offline event detected on laptop LG-38557424.',0,'2026-09-10 19:34:47'),(8,7,'laptop_5f93285a4da0','🟢 Laptop Started','Antigravity Test Laptop came online.',1,'2026-09-10 21:06:44'),(9,9,'laptop_d13f71757cfe','🟢 Laptop Started','Antigravity Test Laptop came online.',1,'2026-09-10 21:09:53'),(10,11,'laptop_a2cf2863e80d','🟢 Laptop Started','Antigravity Test Laptop came online.',1,'2026-09-10 21:10:36'),(11,11,'laptop_a2cf2863e80d','🔒 Laptop Lock','Remote lock was executed successfully.',1,'2026-09-10 21:10:36'),(12,13,'laptop_fd84ab835a8b','🟢 Laptop Started','Antigravity Test Laptop came online.',1,'2026-09-10 21:11:00'),(13,13,'laptop_fd84ab835a8b','🔒 Laptop Lock','Remote lock was executed successfully.',1,'2026-09-10 21:11:00'),(14,7,'laptop_5f93285a4da0','⚠️ Unexpected Offline','Antigravity Test Laptop lost connection unexpectedly. Last seen: 10 Sep 2026 03:36:44 PM',0,'2026-09-10 21:22:53'),(15,9,'laptop_d13f71757cfe','⚠️ Unexpected Offline','Antigravity Test Laptop lost connection unexpectedly. Last seen: 10 Sep 2026 03:39:54 PM',0,'2026-09-10 21:22:53'),(16,11,'laptop_a2cf2863e80d','⚠️ Unexpected Offline','Antigravity Test Laptop lost connection unexpectedly. Last seen: 10 Sep 2026 03:40:36 PM',0,'2026-09-10 21:22:53'),(17,13,'laptop_fd84ab835a8b','⚠️ Unexpected Offline','Antigravity Test Laptop lost connection unexpectedly. Last seen: 10 Sep 2026 03:41:00 PM',0,'2026-09-10 21:22:53'),(18,15,'LG-B889ED4B','🟢 Laptop Started','DESKTOP-T6TEM4H came online.',0,'2026-09-10 22:21:55'),(19,15,'LG-B889ED4B','⚠️ Unexpected Offline','DESKTOP-T6TEM4H lost connection unexpectedly. Last seen: 10 Sep 2026 04:51:55 PM',0,'2026-09-10 22:22:56'),(20,15,'LG-B889ED4B','🟢 Laptop Started','DESKTOP-T6TEM4H came online.',0,'2026-09-10 22:27:05'),(21,15,'LG-B889ED4B','🟢 Laptop Online','DESKTOP-T6TEM4H came online.',0,'2026-09-10 22:27:27'),(22,15,'LG-B889ED4B','🔴 Laptop Shutdown','DESKTOP-T6TEM4H was shut down.',0,'2026-09-10 22:27:27'),(23,15,'LG-B889ED4B','🟢 Laptop Online','DESKTOP-T6TEM4H came online.',0,'2026-09-10 22:34:29'),(24,15,'LG-B889ED4B','🔴 Laptop Shutdown','DESKTOP-T6TEM4H was shut down.',0,'2026-09-10 22:34:29'),(25,15,'LG-B889ED4B','🟢 Laptop Online','DESKTOP-T6TEM4H came online.',0,'2026-09-10 22:35:12'),(26,15,'LG-B889ED4B','🔴 Laptop Shutdown','DESKTOP-T6TEM4H was shut down.',0,'2026-09-10 22:35:12'),(27,15,'LG-B889ED4B','🟢 Laptop Online','DESKTOP-T6TEM4H came online.',0,'2026-09-10 22:35:48'),(28,15,'LG-B889ED4B','🟢 Laptop Online','DESKTOP-T6TEM4H came online.',0,'2026-09-10 22:36:41'),(29,15,'LG-B889ED4B','⚠️ Unexpected Offline','DESKTOP-T6TEM4H lost connection unexpectedly. Last seen: 10 Sep 2026 05:09:49 PM',0,'2026-09-11 20:17:49'),(30,16,'laptop_77ac0b0e3cb5','🟢 Laptop Started','Antigravity Test Laptop came online.',1,'2026-09-11 20:35:49'),(31,16,'laptop_77ac0b0e3cb5','🔒 Laptop Lock','Remote lock was executed successfully.',1,'2026-09-11 20:35:49'),(32,16,'laptop_77ac0b0e3cb5','⚠️ Unexpected Offline','Antigravity Test Laptop lost connection unexpectedly. Last seen: 11 Sep 2026 03:05:49 PM',0,'2026-09-11 20:36:52'),(33,15,'LG-B889ED4B','🟢 Laptop Online','DESKTOP-T6TEM4H came online.',0,'2026-09-11 20:54:41'),(34,15,'LG-B889ED4B','🔒 Laptop Locked','DESKTOP-T6TEM4H was locked.',0,'2026-09-11 20:57:01'),(35,15,'LG-B889ED4B','🔒 Laptop Lock','Remote lock was executed successfully.',0,'2026-09-11 20:57:01'),(36,15,'LG-B889ED4B','🔴 Laptop Shutdown','DESKTOP-T6TEM4H was shut down.',0,'2026-09-11 20:57:21'),(37,15,'LG-B889ED4B','🔴 Laptop Shutdown','Remote shutdown was executed successfully.',0,'2026-09-11 20:57:21'),(38,18,'laptop_8b094211eaaf','🟢 Laptop Started','Antigravity Test Laptop came online.',1,'2026-09-11 21:25:58'),(39,18,'laptop_8b094211eaaf','🔒 Laptop Lock','Remote lock was executed successfully.',1,'2026-09-11 21:25:58'),(40,18,'laptop_8b094211eaaf','⚠️ Unexpected Offline','Antigravity Test Laptop lost connection unexpectedly. Last seen: 11 Sep 2026 03:55:58 PM',0,'2026-09-11 21:32:13'),(41,15,'LG-B889ED4B','🟢 Laptop Online','DESKTOP-T6TEM4H came online.',0,'2026-09-11 21:33:12'),(42,15,'LG-B889ED4B','🔴 Laptop Shutdown','DESKTOP-T6TEM4H was shut down.',0,'2026-09-11 21:37:13'),(43,15,'LG-B889ED4B','🔴 Laptop Shutdown','Remote shutdown was executed successfully.',0,'2026-09-11 21:37:13'),(44,20,'laptop_b6949cfc0eaf','🟢 Laptop Started','Antigravity Test Laptop came online.',1,'2026-09-11 22:06:56'),(45,20,'laptop_b6949cfc0eaf','🔒 Laptop Lock','Remote lock was executed successfully.',1,'2026-09-11 22:06:56'),(46,20,'laptop_b6949cfc0eaf','⚠️ Unexpected Offline','Antigravity Test Laptop lost connection unexpectedly. Last seen: 11 Sep 2026 04:36:56 PM',0,'2026-09-19 18:30:05'),(47,15,'LG-B889ED4B','⚠️ Unexpected Offline','DESKTOP-T6TEM4H lost connection unexpectedly. Last seen: 19 Sep 2026 01:13:19 PM',0,'2026-09-19 19:01:04');
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pairing_codes`
--

DROP TABLE IF EXISTS `pairing_codes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pairing_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `code` varchar(20) NOT NULL,
  `used` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp(),
  `expires_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_code` (`code`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pairing_codes`
--

LOCK TABLES `pairing_codes` WRITE;
/*!40000 ALTER TABLE `pairing_codes` DISABLE KEYS */;
INSERT INTO `pairing_codes` VALUES (1,5,'LG-ONE8R2DC',0,'2026-09-10 21:04:22','2026-09-10 15:49:22'),(2,7,'522321',1,'2026-09-10 21:06:44','2026-09-10 15:51:44'),(3,9,'287885',1,'2026-09-10 21:09:53','2026-09-10 15:54:53'),(4,11,'408769',1,'2026-09-10 21:10:36','2026-09-10 15:55:36'),(5,13,'413297',1,'2026-09-10 21:11:00','2026-09-10 15:56:00'),(6,15,'453669',1,'2026-09-10 22:21:27','2026-09-10 17:06:27'),(7,15,'693700',1,'2026-09-10 22:26:00','2026-09-10 17:11:00'),(8,15,'421240',1,'2026-09-10 22:26:44','2026-09-10 17:11:44'),(9,16,'193930',1,'2026-09-11 20:35:49','2026-09-11 15:20:49'),(10,18,'454433',1,'2026-09-11 21:25:58','2026-09-11 16:10:58'),(11,20,'917498',1,'2026-09-11 22:06:56','2026-09-11 16:51:56');
/*!40000 ALTER TABLE `pairing_codes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sessions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `session_token_hash` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `expires_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `session_token_hash` (`session_token_hash`),
  KEY `idx_sessions_token` (`session_token_hash`),
  KEY `idx_sessions_user` (`user_id`),
  KEY `idx_sessions_expires` (`expires_at`),
  CONSTRAINT `fk_sessions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sessions`
--

LOCK TABLES `sessions` WRITE;
/*!40000 ALTER TABLE `sessions` DISABLE KEYS */;
INSERT INTO `sessions` VALUES (2,1,'c58be3aa4d94431e46e40fbe051559feab4e7806571675175624935b5246eb46','2026-09-09 17:10:15','2026-09-16 17:10:15'),(3,1,'9f059b2c4cf0401e3361d4f736742b1b4f2a422802b660db496be89b6baa23d0','2026-09-09 17:10:15','2026-09-16 17:10:15'),(4,1,'2cc775e4946a92400233322e491d754b9ea5c11b92e55e869ee6aa9b28d64a27','2026-09-09 17:10:17','2026-09-16 17:10:17'),(6,2,'98dc3c4db1e623ff63d499e260dc9986732f78a498d639e2d0cbd57c7b46279d','2026-09-09 17:14:51','2026-09-16 17:14:51'),(7,2,'df0695ac7f8fa461d2ba59ec2701ee93365fca52064e286c560bfae03db1f5c8','2026-09-09 17:45:05','2026-09-16 17:45:05'),(8,2,'4beeb500f21c8dff74e2a2a98f1ff870ade7b66f4e33f0e0f9e8476309a17bb9','2026-09-09 18:08:02','2026-09-16 18:08:02'),(9,2,'4ceb4f99e42eaa67b1ea1608e1c2b69b23fe9dfcdcbdfc10868edcd8bcaa0bab','2026-09-10 19:17:06','2026-09-17 19:17:06'),(10,2,'1d5adfae90dd9d439b22cc1550150dc58d61a8d652c2b310e1881c5710e81db8','2026-09-10 20:10:57','2026-09-17 20:10:57'),(11,3,'344a1b61b9140f06fb22474a1fcbd8bb480991b80fcec0b8a9132a85e0449014','2026-09-10 20:54:53','2026-10-10 15:24:53'),(12,3,'bdaa76aba6f7cbace948fbdbb5af9d3583d0d6b41767f67d99dc9e97b68d4d32','2026-09-10 20:54:54','2026-10-10 15:24:54'),(13,4,'36ae230dce015a41b0a51310dd51135b704b447b711b44a523c94c287d2bc4c4','2026-09-10 20:54:54','2026-10-10 15:24:54'),(14,5,'5be5973e9c602a97384fc7364dbbe10077b66ee2c8888f47d4ccc502c33f18e5','2026-09-10 21:04:21','2026-10-10 15:34:21'),(15,5,'30d507a14469eae38ec7942f628fb7fbd17ef227600d9aa9fbc0e82bc84cca46','2026-09-10 21:04:22','2026-10-10 15:34:22'),(16,6,'a9704c77bf2f2549eb6bc48e94734178d299f8f86e6394c70e0ebed0936ec5dc','2026-09-10 21:04:23','2026-10-10 15:34:23'),(17,7,'f9852305fb2c02fe5b3182d1138248eba38bd8b4a6111b697d5a5b199fec2068','2026-09-10 21:06:43','2026-10-10 15:36:43'),(18,7,'7c41fdd41fdd8da04ca4c735fd652e4fe0a3768bbd3a2921068821a8ccfe0eba','2026-09-10 21:06:44','2026-10-10 15:36:44'),(19,8,'c50538666af09037777242199d028f7a5b3688a4ef7be74fea6b469528a308c0','2026-09-10 21:06:46','2026-10-10 15:36:46'),(20,9,'57392f3b2eb1a99eacd7a82b7579332e7f0fe6c3315f3119c0797b93c9670e7b','2026-09-10 21:09:52','2026-10-10 15:39:52'),(21,9,'9efdde341a54fad28f0415afa4662d64aea246cf110c8d4d91b258f416cd1071','2026-09-10 21:09:53','2026-10-10 15:39:53'),(22,10,'15c8ea39382fa597b17002cf153ebbf775306ec281d392594bbd32ce81ab723b','2026-09-10 21:09:54','2026-10-10 15:39:54'),(23,11,'0dd71febbda1da06ceaddd6dc566a9782ff3c905abc64d06590b3520db21bc88','2026-09-10 21:10:35','2026-10-10 15:40:35'),(24,11,'9932346218d26b2b6554b006430acfdfa68071399a5ae25fe81e33f6236a8f11','2026-09-10 21:10:36','2026-10-10 15:40:36'),(25,12,'b57371416f25dd2199c479cce69fa4dc23634753b18527459c23453ec2a65ab7','2026-09-10 21:10:37','2026-10-10 15:40:37'),(26,13,'a3aaccc0b4aee9993341dfaca3619ed5684dd5f1126b51e48be4a9ec23f0ff9e','2026-09-10 21:10:59','2026-10-10 15:40:59'),(27,13,'c015bc4efff088b06a4745080f446701823c2ff21cb4be9fa4e3ef3c6d700f2e','2026-09-10 21:11:00','2026-10-10 15:41:00'),(28,14,'b58d54f7d4db0f7e3a74f05ab7fa828cd040eaf489f9095f380d4a69ba5d4fbf','2026-09-10 21:11:01','2026-10-10 15:41:01'),(30,15,'d0d239d46edd9185b0ef2bc7cbc6ed073d3dfcd5091a638cfc8f3368d4ab5653','2026-09-10 21:57:24','2026-10-10 16:27:24'),(32,15,'1f4de0d8d3b1396c4e4eae6eadcbc99b24bcc810a895a682e63803f6203cda57','2026-09-10 21:58:41','2026-10-10 16:28:41'),(33,15,'79c0f59fd6563ebd3a95617b8ed2968ccf11d1705770a7fa47be1309d56a1ff5','2026-09-10 22:13:52','2026-10-10 16:43:52'),(34,15,'776e712b741aa4506b879d17c2327ba27ea1a5332a30cc64fa20454d69a8a9d2','2026-09-11 20:18:46','2026-10-11 14:48:46'),(35,15,'acb6d0864322759ada812aa01ece6da444642a6e86bafb8166bd23e806933ec5','2026-09-11 20:18:52','2026-10-11 14:48:52'),(36,15,'6073ed8ccc84ab30c87d30d6b8c6f2baedc4359458a49a9e7df3de7df8f3aa2e','2026-09-11 20:33:56','2026-10-11 15:03:56'),(37,16,'f5367741554a1a8428bab1661de398021b3e83a933ffa7f138fea27691ac6d75','2026-09-11 20:35:49','2026-10-11 15:05:49'),(38,16,'8ff3d2e4a8b532da413a3386ffff426f0cb4ab53214e362138d84e5e0d65a48d','2026-09-11 20:35:49','2026-10-11 15:05:49'),(39,17,'ca82074aff3c6df1845c0adcd0bde838525b396af99ca5858524c3a1d5d8cb73','2026-09-11 20:35:50','2026-10-11 15:05:50'),(40,15,'e9ae41c1eeb6b2e0c5eb5354e6e2fc79d5c930d138b0f30ac2c4583b2dc577d5','2026-09-11 20:35:55','2026-10-11 15:05:55'),(41,15,'9daf16112f94c0df65d76a0155ae53005f52461f1d4e8b8b05a400bea2be6c1c','2026-09-11 20:40:04','2026-10-11 15:10:04'),(42,15,'ead2c941f3472959655e3e6f04f348f628b308c38be16b2a0b62e303176d989c','2026-09-11 20:49:53','2026-10-11 15:19:53'),(43,15,'930c6c3a8ce18404be8cecf885202953f48ea794c4a6805cee93fc0f6819be5d','2026-09-11 20:55:02','2026-10-11 15:25:02'),(44,18,'2c21813b27dd7eaefb4c7f2942c08350b8d1fa48fae061d0dbf16a243890c63e','2026-09-11 21:25:58','2026-10-11 15:55:58'),(45,18,'b2707a2809a061978c494f1894611419ad5eec58d3f6a35d4caf756724a2481e','2026-09-11 21:25:58','2026-10-11 15:55:58'),(46,19,'3634202cc499a003d122643f4e5d0c95c749cb0906aeeaa7de3bb55346816c4e','2026-09-11 21:25:59','2026-10-11 15:55:59'),(47,20,'4d2a29013dd120f4304d08c21d566c0ab54c748b85ed6ca1f67c2f137f3150c0','2026-09-11 22:06:56','2026-10-11 16:36:56'),(48,20,'b9b5c15c5116ad4ed8237ddc60f4483aacdbf76a3db3663c529f100db90eb4b8','2026-09-11 22:06:56','2026-10-11 16:36:56'),(49,21,'495a5fea3833ffc0579b9dc564bdc067f75e35508eb99d61b7037c77769d591a','2026-09-11 22:06:57','2026-10-11 16:36:57');
/*!40000 ALTER TABLE `sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `email` varchar(191) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  KEY `idx_user_email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'Alex Guardian','test_owner_1788954007@example.com','pbkdf2:sha256:1000000$rQgNFSapGTzgiljc$1b656afea403ed7bf083bc875fc67147b43be43ef91b4fdf7b88ffe7395e1a30','2026-09-09 17:10:08'),(2,'Babish','babishbabish1012@gmail.com','pbkdf2:sha256:1000000$YSseewYi6uWMgmGu$0935c3263664dd1cca07b03b4e030362de057eb827610ffcc60c1ca6b1f164b1','2026-09-09 17:13:44'),(3,'Test User','test_user_abf4529a@example.com','$2b$12$qGrhFE6ywki0vU304ZBdWOgpk1oc3tutAt3UydYnxINYIYFsyYGiq','2026-09-10 20:54:53'),(4,'Attacker','attacker_5c83f7eb@example.com','$2b$12$esxfmLDabMQj3u.l.qQndO4lvsZDOUyFQcs0l1X.jcOLWY8GMZ5L.','2026-09-10 20:54:54'),(5,'Test User','test_user_a5df531f@example.com','$2b$12$Zmh7XDGYfs0EqZu3v/YlqOH6PZPmzaAvIGU99VBtOvKB5C.P2p.c2','2026-09-10 21:04:21'),(6,'Attacker','attacker_ea23b419@example.com','$2b$12$0OMZ81RSnR1vYGtq2sa6DO9RmaN8l4Pq2JpK6mi5e/o7/zPM5zq2m','2026-09-10 21:04:23'),(7,'Test User','test_user_a60b4ef5@example.com','$2b$12$M3VVN9LNAkdeqU37lpEHiOyBq5Dj0T8g9C5ZLksRRJMkfhkReCstO','2026-09-10 21:06:43'),(8,'Attacker','attacker_febf58c1@example.com','$2b$12$o7Cvm0EHMnZ4cf9iZ6qP0eZ07tuIx9iVeb41ltAVO5oRqreOMNUtG','2026-09-10 21:06:46'),(9,'Test User','test_user_99220481@example.com','$2b$12$m9Fvz64lRxxIWNI8nqIzzeq2F/6aCAAx4NZkJ9ThqHtXA7oqQSVcW','2026-09-10 21:09:52'),(10,'Attacker','attacker_430bde2f@example.com','$2b$12$6cPrr16sB05pMH2XJYKki.IjYhnRYwsjYjsolK1a9PEF9.bznSW7G','2026-09-10 21:09:54'),(11,'Test User','test_user_ca373afb@example.com','$2b$12$rEc1aLMrH2ES2tEbUfQL.O3FMHobDncm77nhFrE8NuOU451T4zHQ6','2026-09-10 21:10:35'),(12,'Attacker','attacker_ce6287a7@example.com','$2b$12$vlvGp6MpfS9EyaifubBJBOsLku8gn7LO6tJFkn1wL431a/np2Y8Uq','2026-09-10 21:10:37'),(13,'Test User','test_user_b54a45ae@example.com','$2b$12$fpKLleSP2JRW0BCilqsvleCMqIxhkrJ2J1aWBnm2mumKkkUjz0SIO','2026-09-10 21:10:59'),(14,'Attacker','attacker_d393bb9a@example.com','$2b$12$kp5j8JCye2nDSnqDwAPe8.EB28WWd0Le5THxHzOpE4jqjMZf7V65S','2026-09-10 21:11:01'),(15,'Babish','babishpk10@gmail.com','$2b$12$fYGH7/Stio4BY755wgVTVuJJB5m65T/41BMYsxGOyhngtHBnT7bBi','2026-09-10 21:56:17'),(16,'Test User','test_user_d8946d80@example.com','$2b$12$rxPUjBok5z8gXUl76B6aresSm/5vkz2si3qTfmOf7uGX9sAdTTqKm','2026-09-11 20:35:49'),(17,'Attacker','attacker_a8556985@example.com','$2b$12$kk1huocZ8cqMN4vqZgJQ2uBXjG31KF5cKvRg3bDccya0B1zX9oYUq','2026-09-11 20:35:50'),(18,'Test User','test_user_d564379f@example.com','$2b$12$3lazDakayaWi.HrZAEQ26OEsLROmcWVnIgW6EV6pLCnBXzMoE5pNK','2026-09-11 21:25:58'),(19,'Attacker','attacker_6d14bbf9@example.com','$2b$12$f4soX2/MVEXnNBWpVUGMdONkQ9yMzkhbk0GfWVXpMsdS6ZlZ7zLwy','2026-09-11 21:25:58'),(20,'Test User','test_user_affdb6cc@example.com','$2b$12$uO3kE0QnBIv7.bODOPkX4.G4CcVTqpvLtiU9gxNqQbzAE.wCCYj9i','2026-09-11 22:06:56'),(21,'Attacker','attacker_e515947d@example.com','$2b$12$QsE00zmyiBykWMpSTNaHMeH4HOaVgspKWeai2kFAiHRdKo2HSFtxq','2026-09-11 22:06:57');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'laptop_guardian'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-19 19:02:49
