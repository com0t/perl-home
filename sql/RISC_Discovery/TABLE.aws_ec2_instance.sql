-- MySQL dump 10.13  Distrib 5.6.39, for FreeBSD11.1 (amd64)
--
-- Host: db.internal.grond.us    Database: RISC_Discovery
-- ------------------------------------------------------
-- Server version	5.6.36

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `aws_ec2_instance`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `aws_ec2_instance` (
  `collection_id` bigint(20) DEFAULT NULL,
  `instance_id` varchar(255) DEFAULT NULL,
  `instance_name` varchar(255) DEFAULT NULL,
  `instance_state_name` varchar(255) DEFAULT NULL,
  `instance_state_code` int(11) DEFAULT NULL,
  `instance_status` varchar(255) DEFAULT NULL,
  `instance_system_status` varchar(255) DEFAULT NULL,
  `instance_image_id` varchar(255) DEFAULT NULL,
  `instance_public_ip` varchar(255) DEFAULT NULL,
  `instance_public_dns_name` varchar(255) DEFAULT NULL,
  `instance_private_ip` varchar(255) DEFAULT NULL,
  `instance_private_dns_name` varchar(255) DEFAULT NULL,
  `instance_private_key_name` varchar(255) DEFAULT NULL,
  `instance_hypervisor` varchar(255) DEFAULT NULL,
  `instance_virtualization_type` varchar(255) DEFAULT NULL,
  `instance_ena_support` int(11) DEFAULT NULL,
  `instance_availability_zone` varchar(255) DEFAULT NULL,
  `instance_cpu_architecture` varchar(255) DEFAULT NULL,
  `instance_monitoring_state` varchar(255) DEFAULT NULL,
  `instance_launch_time` int(11) DEFAULT NULL,
  `instance_ebs_optimized` int(11) DEFAULT NULL,
  `instance_type` varchar(255) DEFAULT NULL,
  `instance_source_dest_check_state` int(11) DEFAULT NULL,
  `instance_kernel_id` varchar(255) DEFAULT NULL,
  `instance_iam_profile_id` varchar(255) DEFAULT NULL,
  `instance_iam_profile_arn` varchar(255) DEFAULT NULL,
  UNIQUE KEY `instance_id` (`instance_id`),
  KEY `devid` (`collection_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-06-07 18:11:21
