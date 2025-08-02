-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Jul 27, 2025 at 05:24 AM
-- Server version: 10.11.10-MariaDB-log
-- PHP Version: 7.2.34

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `u457989556_npc`
--

-- --------------------------------------------------------

--
-- Table structure for table `admin_login`
--

CREATE TABLE `admin_login` (
  `id` int(11) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `sessionid` varchar(255) DEFAULT NULL,
  `session_expiry` datetime DEFAULT NULL,
  `fcm_token` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `admin_login`
--

INSERT INTO `admin_login` (`id`, `email`, `password`, `sessionid`, `session_expiry`, `fcm_token`) VALUES
(1, 'npc@gmail.com', '$2y$10$cDKTJB/PUCCHnHPRFWNSyuh4Fm0trcCu4t8Aq1aUvlv7GIjXHh16.', '90ac719c3df908278ebcc614e3b315c917e87453ed062a65b337edbe26fcc9b7', '2025-07-28 18:43:49', 'web_token');

-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

CREATE TABLE `bookings` (
  `booking_id` varchar(20) NOT NULL,
  `user_id` int(11) NOT NULL,
  `service_name` varchar(100) NOT NULL,
  `service_date` date NOT NULL,
  `time_slot` varchar(50) NOT NULL,
  `service_address` text NOT NULL,
  `special_notes` text DEFAULT NULL,
  `subtotal` decimal(10,2) NOT NULL,
  `discount_amount` decimal(10,2) DEFAULT 0.00,
  `coupon_code` varchar(50) DEFAULT NULL,
  `coupon_discount` decimal(10,2) DEFAULT 0.00,
  `total_amount` decimal(10,2) NOT NULL,
  `payment_method` enum('cash','razorpay') NOT NULL,
  `payment_status` enum('pending','paid','failed') DEFAULT 'pending',
  `razorpay_order_id` varchar(100) DEFAULT NULL,
  `razorpay_payment_id` varchar(100) DEFAULT NULL,
  `booking_status` enum('pending','confirmed','in_progress','completed','cancelled') DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `assigned_technician` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `bookings`
--

INSERT INTO `bookings` (`booking_id`, `user_id`, `service_name`, `service_date`, `time_slot`, `service_address`, `special_notes`, `subtotal`, `discount_amount`, `coupon_code`, `coupon_discount`, `total_amount`, `payment_method`, `payment_status`, `razorpay_order_id`, `razorpay_payment_id`, `booking_status`, `created_at`, `updated_at`, `assigned_technician`) VALUES
('BK202506016421', 1, 'Sanitization', '2025-06-04', '9:00 AM - 11:00 AM', '5/68 MMDA maduravoyal chennai, samantha colony', 'Hhh', 16000.00, 2400.00, NULL, 0.00, 13600.00, 'razorpay', 'pending', NULL, NULL, 'cancelled', '2025-06-01 16:38:00', '2025-06-02 12:46:26', NULL),
('BK202506018875', 1, 'Sanitization', '2025-06-02', '9:00 AM - 11:00 AM', '5/68 MMDA maduravoyal chennai, samantha colony', '', 2000.00, 300.00, NULL, 0.00, 1700.00, 'razorpay', 'paid', NULL, 'pay_Qc0CoUoslhCoYV', 'pending', '2025-06-01 16:45:15', '2025-06-01 16:45:15', NULL),
('BK202506023494', 1, 'Sanitization', '2025-06-03', '2:00 PM - 4:00 PM', '5/68 MMDA maduravoyal chennai, samantha colony', '', 16000.00, 2400.00, NULL, 0.00, 13600.00, 'razorpay', 'paid', NULL, 'pay_QcKRKMZVRLyx9w', 'completed', '2025-06-02 12:32:55', '2025-06-04 03:33:07', 1),
('BK202506045430', 1, 'Sanitization', '2025-06-06', '2:00 PM - 4:00 PM', '5/68 MMDA maduravoyal chennai, samantha colony', '', 21000.00, 3150.00, NULL, 0.00, 17850.00, 'razorpay', 'paid', NULL, 'pay_Qd83H7u3FscOEe', 'completed', '2025-06-04 13:04:50', '2025-07-07 17:40:08', 1),
('BK202506051025', 1, 'General Pest', '2025-06-06', '4:00 PM - 6:00 PM', '5/68 MMDA maduravoyal chennai, samantha', '', 4500.00, 675.00, NULL, 0.00, 3825.00, 'cash', 'pending', NULL, NULL, 'confirmed', '2025-06-05 06:59:52', '2025-07-07 17:29:39', 5),
('BK202506051233', 1, 'Sanitization', '2025-06-06', '9:00 AM - 11:00 AM', '5/68 MMDA maduravoyal chennai, samantha', '', 1000.00, 150.00, NULL, 0.00, 850.00, 'cash', 'pending', NULL, NULL, 'pending', '2025-06-05 06:23:06', '2025-06-05 06:23:06', NULL),
('BK202506053149', 1, 'General Pest', '2025-06-06', '9:00 AM - 11:00 AM', '5/68 MMDA maduravoyal chennai, samantha', '', 4500.00, 675.00, NULL, 0.00, 3825.00, 'cash', 'pending', NULL, NULL, 'confirmed', '2025-06-05 06:52:05', '2025-07-07 17:31:48', 8),
('BK202506058974', 1, 'Termite Control', '2025-06-06', '11:00 AM - 1:00 PM', '5/68 MMDA maduravoyal chennai, samantha', '', 2800.75, 420.11, NULL, 0.00, 2380.64, 'cash', 'pending', NULL, NULL, 'confirmed', '2025-06-05 06:56:05', '2025-07-07 17:31:31', 6),
('BK202506171294', 1, 'Sanitization', '2025-06-20', '2:00 PM - 4:00 PM', '5/68 MMDA maduravoyal chennai, samantha', '', 15000.00, 2250.00, NULL, 0.00, 12750.00, 'razorpay', 'paid', NULL, 'pay_QiFWNjiEVQSlqY', 'completed', '2025-06-17 11:38:18', '2025-06-17 11:46:11', 8),
('BK202506252006', 3, 'Bugs Control', '2025-06-26', '9:00 AM - 11:00 AM', 'dno \n43 shanthi nagar', '', 500.00, 75.00, NULL, 0.00, 425.00, 'cash', 'pending', NULL, NULL, 'confirmed', '2025-06-25 06:51:29', '2025-06-25 06:54:20', 7),
('BK202506254984', 19, 'Sanitization', '2025-06-26', '9:00 AM - 11:00 AM', 'Jawadupatty', '', 1000.00, 150.00, NULL, 0.00, 850.00, 'cash', 'pending', NULL, NULL, 'confirmed', '2025-06-25 16:22:51', '2025-07-02 04:40:17', 6),
('BK202506256190', 3, 'Termite Control', '2025-06-26', '11:00 AM - 1:00 PM', 'dno \n43 shanthi nagar', '', 1000.00, 150.00, NULL, 0.00, 850.00, 'cash', 'pending', NULL, NULL, 'confirmed', '2025-06-25 07:20:06', '2025-06-25 07:22:33', 3),
('BK202506258626', 3, 'Termite Control', '2025-06-26', '9:00 AM - 11:00 AM', 'dno \n43 shanthi nagar', '', 1000.00, 150.00, NULL, 0.00, 850.00, 'razorpay', 'paid', NULL, 'pay_QlJXHFahjLfrMd', 'cancelled', '2025-06-25 05:30:55', '2025-06-25 06:09:17', NULL),
('BK202507024565', 3, 'Termite Control', '2025-07-03', '9:00 AM - 11:00 AM', 'dno \n43 shanthi nagar', '', 2800.75, 420.11, NULL, 0.00, 2380.64, 'cash', 'pending', NULL, NULL, 'completed', '2025-07-02 04:37:30', '2025-07-07 17:40:52', 1),
('BK202507039963', 3, 'Termite Control', '2025-07-04', '9:00 AM - 11:00 AM', 'dno \n43 shanthi nagar', '', 3800.75, 570.11, NULL, 0.00, 3230.64, 'razorpay', 'paid', NULL, 'pay_QoSX1KZVcHrZlV', 'confirmed', '2025-07-03 04:16:01', '2025-07-03 04:19:15', 7),
('BK202507071356', 20, 'CrittenClean', '2025-07-08', '11:00 AM - 1:00 PM', 'shanthi nagar', '', 2000.00, 300.00, NULL, 0.00, 1700.00, 'cash', 'pending', NULL, NULL, 'confirmed', '2025-07-07 17:01:13', '2025-07-07 17:15:20', 8),
('BK202507077028', 3, 'Bugs Control', '2025-07-08', '9:00 AM - 11:00 AM', 'dno \n43 shanthi nagar', '', 500.00, 75.00, NULL, 0.00, 425.00, 'cash', 'pending', NULL, NULL, 'confirmed', '2025-07-07 17:43:47', '2025-07-22 15:40:12', 7),
('BK202507153726', 3, 'CrittenClean', '2025-07-16', '9:00 AM - 11:00 AM', 'dno \n43 shanthi nagar', '', 2000.00, 300.00, NULL, 0.00, 1700.00, 'cash', 'pending', NULL, NULL, 'confirmed', '2025-07-15 13:47:57', '2025-07-21 09:03:57', 1),
('BK202507158048', 3, 'Termite Control', '2025-07-17', '11:00 AM - 1:00 PM', 'dno \n43 shanthi nagar', '', 2800.75, 420.11, NULL, 0.00, 2380.64, 'cash', 'pending', NULL, NULL, 'confirmed', '2025-07-15 02:21:39', '2025-07-15 02:26:02', 8),
('BK202507213571', 22, 'CrittenClean', '2025-07-22', '9:00 AM - 11:00 AM', '3kd', '', 2000.00, 300.00, NULL, 0.00, 1700.00, 'cash', 'pending', NULL, NULL, 'confirmed', '2025-07-21 08:05:40', '2025-07-21 09:03:24', 1),
('BK202507216071', 22, 'Sanitization', '2025-07-22', '9:00 AM - 11:00 AM', '3kd', '', 1000.00, 150.00, NULL, 0.00, 850.00, 'cash', 'pending', NULL, NULL, 'confirmed', '2025-07-21 08:57:51', '2025-07-22 15:40:37', 5),
('BK202507222188', 22, 'Rat Control', '2025-07-23', '2:00 PM - 4:00 PM', '3kd', '', 2000.00, 300.00, NULL, 0.00, 1700.00, 'cash', 'pending', NULL, NULL, 'confirmed', '2025-07-22 16:18:23', '2025-07-24 18:04:25', 8),
('BK202507224065', 22, 'Sanitization', '2025-07-23', '9:00 AM - 11:00 AM', '3kd', '', 5000.00, 750.00, NULL, 0.00, 4250.00, 'cash', 'pending', NULL, NULL, 'confirmed', '2025-07-22 16:19:06', '2025-07-24 17:56:51', 6),
('BK202507227888', 22, 'General Pest', '2025-07-23', '6:00 PM - 8:00 PM', '3kd', '', 4500.00, 675.00, NULL, 0.00, 3825.00, 'cash', 'pending', NULL, NULL, 'pending', '2025-07-22 16:19:20', '2025-07-22 16:19:20', NULL),
('BK202507237129', 24, 'Rat Control', '2025-07-24', '6:00 PM - 8:00 PM', 'PBS castle', '', 2000.00, 300.00, NULL, 0.00, 1700.00, 'razorpay', 'paid', NULL, 'pay_QwO81OhFZtE6xK', 'pending', '2025-07-23 05:09:37', '2025-07-23 05:09:38', NULL),
('BK202507237438', 24, 'New', '2025-07-24', '11:00 AM - 1:00 PM', 'PBS castle', '', 1200.00, 180.00, NULL, 0.00, 1020.00, 'cash', 'pending', NULL, NULL, 'confirmed', '2025-07-23 05:22:54', '2025-07-23 15:34:19', 1),
('BK202507244224', 22, 'Rat Control', '2025-07-25', '6:00 PM - 8:00 PM', 'asd', 'asd', 2000.00, 300.00, NULL, 0.00, 1700.00, '', 'pending', NULL, NULL, 'confirmed', '2025-07-24 05:29:02', '2025-07-24 17:36:46', 1),
('BK202507245149', 22, 'Bugs Control', '2025-07-25', '2:00 PM - 4:00 PM', 'SDS', 'ASD', 1500.00, 225.00, NULL, 0.00, 1275.00, '', 'paid', NULL, 'pay_Qwn5uqIfseXTGf', 'confirmed', '2025-07-24 05:34:45', '2025-07-24 17:56:28', 3),
('BK202507246364', 22, 'Bugs Control', '2025-07-24', '9:00 AM - 11:00 AM', 'hgfh', ' ghcgh', 3000.00, 450.00, NULL, 0.00, 2550.00, 'cash', 'pending', NULL, NULL, 'confirmed', '2025-07-24 05:10:14', '2025-07-24 18:01:05', 7),
('BK202507248193', 22, 'Rat Control', '2025-07-24', '2:00 PM - 4:00 PM', 'asdf', 'asdf', 2000.00, 300.00, 'test1', 200.00, 1500.00, '', 'pending', NULL, NULL, 'pending', '2025-07-24 05:21:55', '2025-07-24 05:21:55', NULL),
('BK202507248876', 22, 'Rat Control', '2025-07-25', '2:00 PM - 4:00 PM', '456', '1334', 2000.00, 300.00, 'test1', 200.00, 1500.00, '', 'pending', NULL, NULL, 'confirmed', '2025-07-24 05:28:31', '2025-07-24 17:59:01', 3);

-- --------------------------------------------------------

--
-- Table structure for table `booking_items`
--

CREATE TABLE `booking_items` (
  `id` int(11) NOT NULL,
  `booking_id` varchar(20) NOT NULL,
  `service_type_name` varchar(100) NOT NULL,
  `room_size` varchar(50) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 1,
  `item_total` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `booking_items`
--

INSERT INTO `booking_items` (`id`, `booking_id`, `service_type_name`, `room_size`, `price`, `quantity`, `item_total`) VALUES
(1, 'BK202506016421', 'Hospital', 'Icu ward', 1000.00, 2, 2000.00),
(2, 'BK202506016421', 'Industrial', 'Backyard', 7000.00, 2, 14000.00),
(3, 'BK202506018875', 'Hospital', 'Icu ward', 1000.00, 2, 2000.00),
(4, 'BK202506023494', 'Hospital', 'Icu ward', 1000.00, 2, 2000.00),
(5, 'BK202506023494', 'Industrial', 'Backyard', 7000.00, 2, 14000.00),
(6, 'BK202506045430', 'Hospital', 'Icu ward', 1000.00, 2, 2000.00),
(7, 'BK202506045430', 'Industrial', 'Backyard', 7000.00, 2, 14000.00),
(8, 'BK202506045430', 'Industrial', 'Living Room', 5000.00, 1, 5000.00),
(9, 'BK202506051233', 'Hospital', 'Icu ward', 1000.00, 1, 1000.00),
(10, 'BK202506053149', 'Hospital', 'ICU Ward', 4500.00, 1, 4500.00),
(11, 'BK202506058974', 'Commercial', 'Restaurant Kitchen', 2800.75, 1, 2800.75),
(12, 'BK202506051025', 'Hospital', 'ICU Ward', 4500.00, 1, 4500.00),
(13, 'BK202506171294', 'Hospital', 'Icu ward', 1000.00, 1, 1000.00),
(14, 'BK202506171294', 'Industrial', 'Backyard', 7000.00, 2, 14000.00),
(15, 'BK202506258626', 'Residential', 'Bedroom Room', 1000.00, 1, 1000.00),
(16, 'BK202506252006', 'Residential', '1BHk', 500.00, 1, 500.00),
(17, 'BK202506256190', 'Residential', 'Bedroom Room', 1000.00, 1, 1000.00),
(18, 'BK202506254984', 'Hospital', 'Icu ward', 1000.00, 1, 1000.00),
(19, 'BK202507024565', 'Commercial', 'Restaurant Kitchen', 2800.75, 1, 2800.75),
(20, 'BK202507039963', 'Commercial', 'Restaurant Kitchen', 2800.75, 1, 2800.75),
(21, 'BK202507039963', 'Residential', 'Bedroom Room', 1000.00, 1, 1000.00),
(22, 'BK202507071356', 'bedroom', '1bhk', 2000.00, 1, 2000.00),
(23, 'BK202507077028', 'Residential', '1BHk', 500.00, 1, 500.00),
(24, 'BK202507158048', 'Commercial', 'Restaurant Kitchen', 2800.75, 1, 2800.75),
(25, 'BK202507153726', 'bedroom', '1bhk', 2000.00, 1, 2000.00),
(26, 'BK202507213571', 'bedroom', '1bhk', 2000.00, 1, 2000.00),
(27, 'BK202507216071', 'Hospital', 'Icu ward', 1000.00, 1, 1000.00),
(28, 'BK202507222188', 'Residential', '1BHK', 2000.00, 1, 2000.00),
(29, 'BK202507224065', 'hotel', 'hall', 5000.00, 1, 5000.00),
(30, 'BK202507227888', 'Hospital', 'ICU Ward', 4500.00, 1, 4500.00),
(31, 'BK202507237129', 'Residential', '1BHK', 2000.00, 1, 2000.00),
(32, 'BK202507237438', 'BHKS', '1 BHK', 1000.00, 1, 1000.00),
(33, 'BK202507237438', 'BHKS', '2 BHK', 200.00, 1, 200.00),
(34, 'BK202507246364', 'Residential', '1BHk', 500.00, 2, 1000.00),
(35, 'BK202507246364', 'Residential', '2BHK', 1000.00, 2, 2000.00),
(36, 'BK202507248193', 'Residential', '1BHK', 2000.00, 1, 2000.00),
(37, 'BK202507248876', 'Residential', '1BHK', 2000.00, 1, 2000.00),
(38, 'BK202507244224', 'Residential', '1BHK', 2000.00, 1, 2000.00),
(39, 'BK202507245149', 'Residential', '1BHk', 500.00, 1, 500.00),
(40, 'BK202507245149', 'Residential', '2BHK', 1000.00, 1, 1000.00);

-- --------------------------------------------------------

--
-- Table structure for table `contact_queries`
--

CREATE TABLE `contact_queries` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `first_name` varchar(100) NOT NULL,
  `last_name` varchar(100) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone` varchar(20) NOT NULL,
  `subject` varchar(100) NOT NULL,
  `message` text NOT NULL,
  `status` enum('pending','responded','closed') DEFAULT 'pending',
  `admin_response` text DEFAULT NULL,
  `response_date` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `contact_queries`
--

INSERT INTO `contact_queries` (`id`, `user_id`, `first_name`, `last_name`, `email`, `phone`, `subject`, `message`, `status`, `admin_response`, `response_date`, `created_at`, `updated_at`) VALUES
(1, 1, 'ggh', 'ghu', 'saiganesh78901@gmail.com', '9840523294', 'Feedback', 'Cgggg', 'responded', 'Will be fixed thank you', '2025-06-04 11:49:11', '2025-06-04 04:35:41', '2025-06-04 11:49:11'),
(6, 1, 'cvg', 'ggg', 'saiganesh78901@gmail.com', '9840523294', 'Billing Inquiry', 'Ghhh', 'pending', NULL, NULL, '2025-06-05 07:48:00', '2025-06-05 07:48:00'),
(7, 1, 'fff', 'ccc', 'saiganesh78901@gmail.com', '9840523294', 'Billing Inquiry', 'Jsjsjd', 'pending', NULL, NULL, '2025-06-05 07:51:19', '2025-06-05 07:51:19'),
(8, 1, 'fcf', 'cccc', 'saiganesh78901@gmail.com', '9840523294', 'Billing Inquiry', 'Shdhdh', 'responded', 'asdf', '2025-07-24 16:42:48', '2025-06-05 07:54:22', '2025-07-24 16:42:48'),
(9, 1, 'xdd', 'xxx', 'saiganesh78901@gmail.com', '9840523294', 'Billing Inquiry', 'Nsjsjsjss', 'responded', 'Will be solved', '2025-06-17 11:42:56', '2025-06-05 07:57:18', '2025-06-17 11:42:56');

-- --------------------------------------------------------

--
-- Table structure for table `locations`
--

CREATE TABLE `locations` (
  `id` int(11) NOT NULL,
  `location_name` varchar(100) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `locations`
--

INSERT INTO `locations` (`id`, `location_name`, `created_at`) VALUES
(1, 'Chennai', '2025-07-12 16:57:45'),
(2, 'Salem', '2025-07-12 16:57:53'),
(3, 'Coimbatore', '2025-07-12 16:57:59'),
(4, 'Erode', '2025-07-12 16:58:27');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `notification_id` int(11) NOT NULL,
  `user_type` enum('customer','technician','admin') NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `type` enum('booking_assigned','status_update','payment','general') NOT NULL,
  `related_booking_id` varchar(50) DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`notification_id`, `user_type`, `user_id`, `title`, `message`, `type`, `related_booking_id`, `is_read`, `created_at`, `updated_at`) VALUES
(1, 'technician', 1, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202506023494. Service: Sanitization. Date: 2025-06-03 at 2:00 PM - 4:00 PM.', 'booking_assigned', 'BK202506023494', 0, '2025-06-02 14:29:28', '2025-06-02 14:29:28'),
(2, 'customer', 1, 'Technician Assigned', 'Good news! Technician Rishi has been assigned to your booking #BK202506023494. They will contact you soon.', 'status_update', 'BK202506023494', 0, '2025-06-02 14:29:28', '2025-06-02 14:29:28'),
(3, 'customer', 1, 'Technician Arrived', 'Your technician Rishi has arrived at your location for booking #BK202506023494.', 'status_update', 'BK202506023494', 0, '2025-06-04 03:31:27', '2025-06-04 03:31:27'),
(4, 'customer', 1, 'Service Started', 'Your service for booking #BK202506023494 has been started by technician Rishi.', 'status_update', 'BK202506023494', 0, '2025-06-04 03:31:37', '2025-06-04 03:31:37'),
(5, 'customer', 1, 'Service Completed', 'Great news! Your service for booking #BK202506023494 has been completed successfully by Rishi.', 'status_update', 'BK202506023494', 0, '2025-06-04 03:33:07', '2025-06-04 03:33:07'),
(6, 'customer', 1, 'Password Changed', 'Your password has been successfully updated.', '', NULL, 0, '2025-06-04 03:45:54', '2025-06-04 03:45:54'),
(7, 'technician', 1, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202506045430. Service: Sanitization. Date: 2025-06-06 at 2:00 PM - 4:00 PM.', 'booking_assigned', 'BK202506045430', 0, '2025-06-04 13:07:32', '2025-06-04 13:07:32'),
(8, 'customer', 1, 'Technician Assigned', 'Good news! Technician Rishi has been assigned to your booking #BK202506045430. They will contact you soon.', 'status_update', 'BK202506045430', 0, '2025-06-04 13:07:32', '2025-06-04 13:07:32'),
(9, 'customer', 1, 'Technician Arrived', 'Your technician Rishi has arrived at your location for booking #BK202506045430.', 'status_update', 'BK202506045430', 0, '2025-06-04 13:10:42', '2025-06-04 13:10:42'),
(10, 'customer', 1, 'Service Started', 'Your service for booking #BK202506045430 has been started by technician Rishi.', 'status_update', 'BK202506045430', 0, '2025-06-04 13:11:01', '2025-06-04 13:11:01'),
(11, 'technician', 8, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202506171294. Service: Sanitization. Date: 2025-06-20 at 2:00 PM - 4:00 PM.', 'booking_assigned', 'BK202506171294', 0, '2025-06-17 11:40:26', '2025-06-17 11:40:26'),
(12, 'customer', 1, 'Technician Assigned', 'Good news! Technician Arun Kumar has been assigned to your booking #BK202506171294. They will contact you soon.', 'status_update', 'BK202506171294', 0, '2025-06-17 11:40:26', '2025-06-17 11:40:26'),
(13, 'customer', 1, 'Technician Arrived', 'Your technician Arun Kumar has arrived at your location for booking #BK202506171294.', 'status_update', 'BK202506171294', 0, '2025-06-17 11:45:45', '2025-06-17 11:45:45'),
(14, 'customer', 1, 'Service Started', 'Your service for booking #BK202506171294 has been started by technician Arun Kumar.', 'status_update', 'BK202506171294', 0, '2025-06-17 11:46:00', '2025-06-17 11:46:00'),
(15, 'customer', 1, 'Service Completed', 'Great news! Your service for booking #BK202506171294 has been completed successfully by Arun Kumar.', 'status_update', 'BK202506171294', 0, '2025-06-17 11:46:11', '2025-06-17 11:46:11'),
(16, 'technician', 7, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202506252006. Service: Bugs Control. Date: 2025-06-26 at 9:00 AM - 11:00 AM.', 'booking_assigned', 'BK202506252006', 0, '2025-06-25 06:54:20', '2025-06-25 06:54:20'),
(17, 'customer', 3, 'Technician Assigned', 'Good news! Technician Ayesha has been assigned to your booking #BK202506252006. They will contact you soon.', 'status_update', 'BK202506252006', 0, '2025-06-25 06:54:20', '2025-06-25 06:54:20'),
(18, 'technician', 3, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202506256190. Service: Termite Control. Date: 2025-06-26 at 11:00 AM - 1:00 PM.', 'booking_assigned', 'BK202506256190', 0, '2025-06-25 07:22:33', '2025-06-25 07:22:33'),
(19, 'customer', 3, 'Technician Assigned', 'Good news! Technician John Doe has been assigned to your booking #BK202506256190. They will contact you soon.', 'status_update', 'BK202506256190', 0, '2025-06-25 07:22:33', '2025-06-25 07:22:33'),
(20, 'technician', 1, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202507024565. Service: Termite Control. Date: 2025-07-03 at 9:00 AM - 11:00 AM.', 'booking_assigned', 'BK202507024565', 0, '2025-07-02 04:40:02', '2025-07-02 04:40:02'),
(21, 'customer', 3, 'Technician Assigned', 'Good news! Technician Rishi has been assigned to your booking #BK202507024565. They will contact you soon.', 'status_update', 'BK202507024565', 0, '2025-07-02 04:40:02', '2025-07-02 04:40:02'),
(22, 'technician', 6, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202506254984. Service: Sanitization. Date: 2025-06-26 at 9:00 AM - 11:00 AM.', 'booking_assigned', 'BK202506254984', 0, '2025-07-02 04:40:17', '2025-07-02 04:40:17'),
(23, 'customer', 19, 'Technician Assigned', 'Good news! Technician Anbu Kutty has been assigned to your booking #BK202506254984. They will contact you soon.', 'status_update', 'BK202506254984', 0, '2025-07-02 04:40:17', '2025-07-02 04:40:17'),
(24, 'technician', 7, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202507039963. Service: Termite Control. Date: 2025-07-04 at 9:00 AM - 11:00 AM.', 'booking_assigned', 'BK202507039963', 0, '2025-07-03 04:19:15', '2025-07-03 04:19:15'),
(25, 'customer', 3, 'Technician Assigned', 'Good news! Technician Ayesha has been assigned to your booking #BK202507039963. They will contact you soon.', 'status_update', 'BK202507039963', 0, '2025-07-03 04:19:15', '2025-07-03 04:19:15'),
(26, 'technician', 8, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202507071356. Service: CrittenClean. Date: 2025-07-08 at 11:00 AM - 1:00 PM.', 'booking_assigned', 'BK202507071356', 0, '2025-07-07 17:15:20', '2025-07-07 17:15:20'),
(27, 'customer', 20, 'Technician Assigned', 'Good news! Technician Arun Kumar has been assigned to your booking #BK202507071356. They will contact you soon.', 'status_update', 'BK202507071356', 0, '2025-07-07 17:15:20', '2025-07-07 17:15:20'),
(28, 'technician', 5, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202506051025. Service: General Pest. Date: 2025-06-06 at 4:00 PM - 6:00 PM.', 'booking_assigned', 'BK202506051025', 0, '2025-07-07 17:29:39', '2025-07-07 17:29:39'),
(29, 'customer', 1, 'Technician Assigned', 'Good news! Technician Sai Ganesh S has been assigned to your booking #BK202506051025. They will contact you soon.', 'status_update', 'BK202506051025', 0, '2025-07-07 17:29:39', '2025-07-07 17:29:39'),
(30, 'technician', 6, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202506058974. Service: Termite Control. Date: 2025-06-06 at 11:00 AM - 1:00 PM.', 'booking_assigned', 'BK202506058974', 0, '2025-07-07 17:31:31', '2025-07-07 17:31:31'),
(31, 'customer', 1, 'Technician Assigned', 'Good news! Technician Anbu Kutty has been assigned to your booking #BK202506058974. They will contact you soon.', 'status_update', 'BK202506058974', 0, '2025-07-07 17:31:31', '2025-07-07 17:31:31'),
(32, 'technician', 8, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202506053149. Service: General Pest. Date: 2025-06-06 at 9:00 AM - 11:00 AM.', 'booking_assigned', 'BK202506053149', 0, '2025-07-07 17:31:48', '2025-07-07 17:31:48'),
(33, 'customer', 1, 'Technician Assigned', 'Good news! Technician Arun Kumar has been assigned to your booking #BK202506053149. They will contact you soon.', 'status_update', 'BK202506053149', 0, '2025-07-07 17:31:48', '2025-07-07 17:31:48'),
(34, 'customer', 3, 'Technician Arrived', 'Your technician Rishi has arrived at your location for booking #BK202507024565.', 'status_update', 'BK202507024565', 0, '2025-07-07 17:40:01', '2025-07-07 17:40:01'),
(35, 'customer', 1, 'Service Completed', 'Great news! Your service for booking #BK202506045430 has been completed successfully by Rishi.', 'status_update', 'BK202506045430', 0, '2025-07-07 17:40:08', '2025-07-07 17:40:08'),
(36, 'customer', 3, 'Service Started', 'Your service for booking #BK202507024565 has been started by technician Rishi.', 'status_update', 'BK202507024565', 0, '2025-07-07 17:40:19', '2025-07-07 17:40:19'),
(37, 'customer', 3, 'Service Completed', 'Great news! Your service for booking #BK202507024565 has been completed successfully by Rishi.', 'status_update', 'BK202507024565', 0, '2025-07-07 17:40:52', '2025-07-07 17:40:52'),
(38, 'technician', 8, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202507158048. Service: Termite Control. Date: 2025-07-17 at 11:00 AM - 1:00 PM.', 'booking_assigned', 'BK202507158048', 0, '2025-07-15 02:26:02', '2025-07-15 02:26:02'),
(39, 'customer', 3, 'Technician Assigned', 'Good news! Technician Arun Kumar has been assigned to your booking #BK202507158048. They will contact you soon.', 'status_update', 'BK202507158048', 0, '2025-07-15 02:26:02', '2025-07-15 02:26:02'),
(40, 'technician', 1, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202507213571. Service: CrittenClean. Date: 2025-07-22 at 9:00 AM - 11:00 AM.', 'booking_assigned', 'BK202507213571', 0, '2025-07-21 09:03:24', '2025-07-21 09:03:24'),
(41, 'customer', 22, 'Technician Assigned', 'Good news! Technician Rishi has been assigned to your booking #BK202507213571. They will contact you soon.', 'status_update', 'BK202507213571', 0, '2025-07-21 09:03:24', '2025-07-21 09:03:24'),
(42, 'technician', 1, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202507153726. Service: CrittenClean. Date: 2025-07-16 at 9:00 AM - 11:00 AM.', 'booking_assigned', 'BK202507153726', 0, '2025-07-21 09:03:57', '2025-07-21 09:03:57'),
(43, 'customer', 3, 'Technician Assigned', 'Good news! Technician Rishi has been assigned to your booking #BK202507153726. They will contact you soon.', 'status_update', 'BK202507153726', 0, '2025-07-21 09:03:57', '2025-07-21 09:03:57'),
(44, 'technician', 7, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202507077028. Service: Bugs Control. Date: 2025-07-08 at 9:00 AM - 11:00 AM.', 'booking_assigned', 'BK202507077028', 0, '2025-07-22 15:40:12', '2025-07-22 15:40:12'),
(45, 'customer', 3, 'Technician Assigned', 'Good news! Technician Ayesha has been assigned to your booking #BK202507077028. They will contact you soon.', 'status_update', 'BK202507077028', 0, '2025-07-22 15:40:12', '2025-07-22 15:40:12'),
(46, 'technician', 5, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202507216071. Service: Sanitization. Date: 2025-07-22 at 9:00 AM - 11:00 AM.', 'booking_assigned', 'BK202507216071', 0, '2025-07-22 15:40:37', '2025-07-22 15:40:37'),
(47, 'customer', 22, 'Technician Assigned', 'Good news! Technician Sai Ganesh S has been assigned to your booking #BK202507216071. They will contact you soon.', 'status_update', 'BK202507216071', 0, '2025-07-22 15:40:37', '2025-07-22 15:40:37'),
(48, 'technician', 1, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202507237438. Service: New. Date: 2025-07-24 at 11:00 AM - 1:00 PM.', 'booking_assigned', 'BK202507237438', 0, '2025-07-23 15:34:19', '2025-07-23 15:34:19'),
(49, 'customer', 24, 'Technician Assigned', 'Good news! Technician Rishi has been assigned to your booking #BK202507237438. They will contact you soon.', 'status_update', 'BK202507237438', 0, '2025-07-23 15:34:19', '2025-07-23 15:34:19'),
(50, 'technician', 1, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202507244224. Service: Rat Control. Date: 2025-07-25 at 6:00 PM - 8:00 PM.', 'booking_assigned', 'BK202507244224', 0, '2025-07-24 17:36:46', '2025-07-24 17:36:46'),
(51, 'customer', 22, 'Technician Assigned', 'Good news! Technician Rishi has been assigned to your booking #BK202507244224. They will contact you soon.', 'status_update', 'BK202507244224', 0, '2025-07-24 17:36:46', '2025-07-24 17:36:46'),
(52, 'technician', 3, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202507245149. Service: Bugs Control. Date: 2025-07-25 at 2:00 PM - 4:00 PM.', 'booking_assigned', 'BK202507245149', 0, '2025-07-24 17:56:28', '2025-07-24 17:56:28'),
(53, 'customer', 22, 'Technician Assigned', 'Good news! Technician John Doe has been assigned to your booking #BK202507245149. They will contact you soon.', 'status_update', 'BK202507245149', 0, '2025-07-24 17:56:28', '2025-07-24 17:56:28'),
(54, 'technician', 6, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202507224065. Service: Sanitization. Date: 2025-07-23 at 9:00 AM - 11:00 AM.', 'booking_assigned', 'BK202507224065', 0, '2025-07-24 17:56:51', '2025-07-24 17:56:51'),
(55, 'customer', 22, 'Technician Assigned', 'Good news! Technician Anbu Kutty has been assigned to your booking #BK202507224065. They will contact you soon.', 'status_update', 'BK202507224065', 0, '2025-07-24 17:56:51', '2025-07-24 17:56:51'),
(56, 'technician', 3, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202507248876. Service: Rat Control. Date: 2025-07-25 at 2:00 PM - 4:00 PM.', 'booking_assigned', 'BK202507248876', 0, '2025-07-24 17:59:01', '2025-07-24 17:59:01'),
(57, 'customer', 22, 'Technician Assigned', 'Good news! Technician John Doe has been assigned to your booking #BK202507248876. They will contact you soon.', 'status_update', 'BK202507248876', 0, '2025-07-24 17:59:01', '2025-07-24 17:59:01'),
(58, 'technician', 7, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202507246364. Service: Bugs Control. Date: 2025-07-24 at 9:00 AM - 11:00 AM.', 'booking_assigned', 'BK202507246364', 0, '2025-07-24 18:01:05', '2025-07-24 18:01:05'),
(59, 'customer', 22, 'Technician Assigned', 'Good news! Technician Ayesha has been assigned to your booking #BK202507246364. They will contact you soon.', 'status_update', 'BK202507246364', 0, '2025-07-24 18:01:05', '2025-07-24 18:01:05'),
(60, 'technician', 8, 'New Job Assignment', 'You have been assigned to a new job. Booking ID: BK202507222188. Service: Rat Control. Date: 2025-07-23 at 2:00 PM - 4:00 PM.', 'booking_assigned', 'BK202507222188', 0, '2025-07-24 18:04:25', '2025-07-24 18:04:25'),
(61, 'customer', 22, 'Technician Assigned', 'Good news! Technician Arun Kumar has been assigned to your booking #BK202507222188. They will contact you soon.', 'status_update', 'BK202507222188', 0, '2025-07-24 18:04:25', '2025-07-24 18:04:25');

-- --------------------------------------------------------

--
-- Table structure for table `notification_requests`
--

CREATE TABLE `notification_requests` (
  `id` int(11) NOT NULL,
  `request_id` varchar(255) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `target_user_type` enum('user','technician','admin','all') NOT NULL,
  `priority` enum('low','normal','high','critical') DEFAULT 'normal',
  `sender_id` int(11) DEFAULT NULL,
  `sender_type` enum('user','technician','admin') DEFAULT NULL,
  `sender_info` varchar(255) DEFAULT NULL,
  `status` enum('pending','approved','rejected','sent') DEFAULT 'pending',
  `additional_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`additional_data`)),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `processed_at` timestamp NULL DEFAULT NULL,
  `processed_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `offers`
--

CREATE TABLE `offers` (
  `offer_id` int(11) NOT NULL,
  `offer_name` varchar(255) NOT NULL,
  `coupon_number` varchar(100) NOT NULL,
  `offer_starts_on` date NOT NULL,
  `expires_on` date NOT NULL,
  `offer_percentage` decimal(5,2) NOT NULL,
  `offer_banner_location` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `offers`
--

INSERT INTO `offers` (`offer_id`, `offer_name`, `coupon_number`, `offer_starts_on`, `expires_on`, `offer_percentage`, `offer_banner_location`, `created_at`) VALUES
(1, 'New Year Sale', 'NY2025', '2025-01-01', '2025-06-13', 20.00, 'offer-banner/NY2025_67877d0773f6b.jpg', '2025-01-15 09:16:55'),
(3, 'womens day special', 'WOMEN2025', '2025-03-11', '2025-03-13', 3.00, 'offer-banner/WOMEN2025_67cfd0d35be98.jpg', '2025-03-11 05:57:39'),
(4, 'Workers Day', 'WORKING2025', '2025-03-05', '2025-03-10', 3.00, 'offer-banner/WORKING2025_67cfd55a72f1d.jpg', '2025-03-11 06:16:58'),
(7, 'New Test', 'test1', '2025-07-22', '2025-07-31', 10.00, 'offer-banner/test1_68806f3257e71.jpg', '2025-07-23 05:12:18'),
(24, 'asd', 'test123', '2025-07-27', '2025-07-30', 12.00, 'offer-banner/test123_688520f7ef676.jpg', '2025-07-26 18:39:51');

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `order_id` int(11) NOT NULL,
  `customer_name` varchar(255) NOT NULL,
  `mobile_no` varchar(15) NOT NULL,
  `slot_date` date NOT NULL,
  `slot_time` time NOT NULL,
  `address` text NOT NULL,
  `payment_mode` enum('Cash','Online') NOT NULL,
  `status` enum('Pending','Accepted','Rejected','Completed') DEFAULT 'Pending',
  `assigned_technician` int(11) DEFAULT NULL,
  `session` enum('Pest Session 1','Pest Session 2') DEFAULT NULL,
  `type_of_service` varchar(255) NOT NULL,
  `space` varchar(255) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `status_updated_date` datetime DEFAULT NULL,
  `booked_date` datetime DEFAULT current_timestamp(),
  `paymentid` varchar(255) DEFAULT NULL,
  `session2_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`order_id`, `customer_name`, `mobile_no`, `slot_date`, `slot_time`, `address`, `payment_mode`, `status`, `assigned_technician`, `session`, `type_of_service`, `space`, `amount`, `status_updated_date`, `booked_date`, `paymentid`, `session2_date`) VALUES
(1, 'Hari Raja', '730589753', '2025-02-15', '10:00:00', '123 Main St, City, Country', 'Online', 'Pending', 1, 'Pest Session 2', 'General Pest', 'Living Room', 150.00, '2025-02-15 19:28:00', '2025-02-15 14:45:08', 'pay_1234567890', '2025-02-22'),
(2, 'Sai Ganesh S', '9840523294', '2025-02-15', '10:00:00', '123 Main St, City, Country', 'Online', 'Rejected', NULL, 'Pest Session 2', 'General Pest', 'Living Room', 350.00, '2025-02-15 19:37:58', '2025-02-15 15:03:29', 'pay_1234567890', '2025-02-22'),
(3, 'rishi', '73058975334', '2025-02-17', '10:00:00', '123 Main St, City, Country', 'Online', 'Accepted', NULL, 'Pest Session 1', 'Termite Pest', 'Living Room', 750.00, '2025-02-15 19:43:15', '2025-02-15 15:08:54', 'pay_1234567890', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `password_change_log`
--

CREATE TABLE `password_change_log` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `user_type` enum('customer','admin','technician') NOT NULL DEFAULT 'customer',
  `changed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `ip_address` varchar(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `password_change_log`
--

INSERT INTO `password_change_log` (`id`, `user_id`, `user_type`, `changed_at`, `ip_address`) VALUES
(1, 1, 'customer', '2025-06-04 03:45:54', '192.168.1.2');

-- --------------------------------------------------------

--
-- Table structure for table `reviews`
--

CREATE TABLE `reviews` (
  `review_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `username` varchar(255) NOT NULL,
  `ratings` float(2,1) NOT NULL,
  `review_description` text NOT NULL,
  `created_date` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `reviews`
--

INSERT INTO `reviews` (`review_id`, `user_id`, `username`, `ratings`, `review_description`, `created_date`) VALUES
(1, 1, 'Hari raja', 4.5, 'Great service! Highly recommended.', '2025-02-15 22:37:37'),
(2, 1, 'Hari raja', 2.5, 'could have been done better', '2025-02-15 22:38:05'),
(3, 1, 'Hari raja', 5.0, 'perfect work!! highly recommending', '2025-02-15 22:38:38');

-- --------------------------------------------------------

--
-- Table structure for table `services`
--

CREATE TABLE `services` (
  `service_id` int(11) NOT NULL,
  `service_name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `image_path` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `locations` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`locations`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `services`
--

INSERT INTO `services` (`service_id`, `service_name`, `description`, `image_path`, `created_at`, `locations`) VALUES
(1, 'Rat Control', 'General rat control services', 'ServiceImages/pest1.jpg', '2025-01-15 08:36:36', '[\"Chennai\",\"Coimbatore\",\"Erode\",\"Salem\"]'),
(2, 'Bugs Control', 'General Bugs control services', 'ServiceImages/pest1.jpg', '2025-01-15 08:36:49', NULL),
(3, 'General Pest', 'General Pest services', 'ServiceImages/pest1.jpg', '2025-01-15 08:37:17', NULL),
(4, 'Termite Control', 'General Termite control services', 'ServiceImages/pest1.jpg', '2025-01-31 16:16:02', NULL),
(6, 'Sanitization', 'Sanitization works', 'ServiceImages/image.png', '2025-03-11 07:02:30', NULL),
(7, 'CrittenClean', 'Humane and efficient removal of rodents insects and other pests. Clean living starts here.', 'ServiceImages/pest1.jpg', '2025-04-10 17:40:11', NULL),
(8, 'cleaning', 'clean', 'ServiceImages/service_1751909796_686c05a4715e4.jpg', '2025-07-07 17:36:36', NULL),
(9, 'New', 'Hello Everyone', 'ServiceImages/service_1752339543_687294578d3ef.jpg', '2025-07-12 16:59:03', '[\"Chennai\"]'),
(10, 'test hari', 'test 1111', 'ServiceImages/service_1753442414_6883686e37706.jpg', '2025-07-23 16:08:09', '[]'),
(11, 'test sidhu', 'asdf', 'ServiceImages/service_1753555398_688521c67e9cc.jpg', '2025-07-26 18:43:18', '[\"Chennai\",\"Coimbatore\"]');

-- --------------------------------------------------------

--
-- Table structure for table `service_details`
--

CREATE TABLE `service_details` (
  `service_type_id` int(11) NOT NULL,
  `service_type_name` varchar(255) NOT NULL,
  `service_id` int(11) NOT NULL,
  `room_size` varchar(255) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `service_details`
--

INSERT INTO `service_details` (`service_type_id`, `service_type_name`, `service_id`, `room_size`, `price`, `created_at`) VALUES
(7, 'Residential', 2, '2BHK', 1000.00, '2025-03-11 06:39:46'),
(12, 'Residential', 1, '1BHK', 2000.00, '2025-03-16 05:15:47'),
(15, 'Residential', 2, '1BHk', 500.00, '2025-03-16 06:02:38'),
(16, 'Industrial', 3, 'Warehouse', 5000.00, '2025-03-16 06:04:20'),
(17, 'Residential', 3, 'Basement', 3500.99, '2025-03-16 06:04:36'),
(18, 'Hospital', 3, 'ICU Ward', 4500.00, '2025-03-16 06:04:54'),
(19, 'Commercial', 4, 'Restaurant Kitchen', 2800.75, '2025-03-16 06:05:22'),
(20, 'Residential', 4, 'Living Room', 1200.50, '2025-03-16 06:05:39'),
(21, 'Residential', 4, 'Bedroom Room', 1000.00, '2025-03-16 06:05:55'),
(22, 'Industrial', 6, 'Warehouse', 5000.00, '2025-03-16 06:06:56'),
(23, 'Industrial', 6, 'Living Room', 5000.00, '2025-03-16 06:07:13'),
(24, 'Industrial', 6, 'Backyard', 7000.00, '2025-03-16 06:07:24'),
(25, 'Hospital', 6, 'Icu ward', 1000.00, '2025-03-16 06:07:49'),
(26, 'bedroom', 7, '1bhk', 2000.00, '2025-06-17 11:42:11'),
(27, 'hotel', 6, 'hall', 5000.00, '2025-07-07 17:36:04'),
(28, 'BHKS', 9, '1 BHK', 1000.00, '2025-07-23 04:16:02'),
(29, 'BHKS', 9, '2 BHK', 200.00, '2025-07-23 04:16:02'),
(31, '', 10, '1 bhk', 100.00, '2025-07-26 18:02:17');

-- --------------------------------------------------------

--
-- Table structure for table `technicians`
--

CREATE TABLE `technicians` (
  `technician_id` int(11) NOT NULL,
  `employee_name` varchar(255) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `service_type` varchar(255) NOT NULL,
  `address` text NOT NULL,
  `id_proof` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `sessionid` varchar(255) DEFAULT NULL,
  `session_expiry` datetime DEFAULT NULL,
  `fcm_token` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `technicians`
--

INSERT INTO `technicians` (`technician_id`, `employee_name`, `phone_number`, `service_type`, `address`, `id_proof`, `email`, `password`, `sessionid`, `session_expiry`, `fcm_token`) VALUES
(1, 'Rishi', '1234567890', 'Pest Control', '123 Main Street', 'tech_idproof/6787599fe16a7.png', 'rishi@gmail.com', '$2y$10$JCVOHVHmEHtga5Z//y4lp.x/a1DNja9vl2LVRbOFuoA6C.CpStrgK', 'ce9fba13befb61c3363d6db8538bb8c0e447cb36114fb47e6d8ad7c01cb39b29', '2025-07-25 16:17:25', 'fq7S1hHlQEaIy3sEU6SAnR:APA91bGbDHNv5ok8gy7bkbw0W-1JmBPe3se0giizzEkNdvJvLR53DY5mI4NKAmlKLljRPoeRBF2cQS_Iv0JKIzvVn203CsjYwoiUEQ2dDmWiI7mQP0OPY8o'),
(3, 'John Doe', '1234567890', 'Pest Control', '123 Main Street', 'tech_idproof/67875ce383471.png', 'hari@gmail.com', '$2y$10$g8Kcv3CeoX5eMBC1UzPPRenqaFZH3Juf1R9eS8xA3rPnH0I8IV9e.', NULL, NULL, NULL),
(5, 'Sai Ganesh S', '9840523294', 'Pest Control', '5/68 MMDA maduravoyal chennai', 'tech_idproof/67b0448bc0f2c.png', 'sai@gmail.com', '$2y$10$tbeL9yohIg2c4JlpMLoc0.de8.d4MKzaE1Y9pSg62HSgzsd5G2SY6', '5be2d052732ca77643afad14b96769b916cf8c75a752c7940200522e7b278003', '2025-06-06 05:23:07', 'your_sample_fcm_token'),
(6, 'Anbu Kutty', '9840523296', 'Terminate ', '7th street madurai ', 'tech_idproof/67cdc8a7654e3.png', 'anbukutty@gmail.com', '$2y$10$l1z9yKxAR06QRCX.WtPCsuDGPrYJlTlTzRQmlCJ61BYpZitOI44YK', NULL, NULL, NULL),
(7, 'Ayesha', '9840523200', 'Bug control', 'Theni abeth street ', 'tech_idproof/67cdd21a12e8f.png', 'ayesha@gmail.com', '$2y$10$mUfGG/VKYtWhcf5xUMFnsuykVZ2bMxaT9i1DHysZWNffTs7b5nyTK', NULL, NULL, NULL),
(8, 'Arun Kumar', '9840526294', 'Bed bugs', 'kodaikanal village park', 'tech_idproof/67cf083575fc0.png', 'arun@gmail.com', '$2y$10$TLfxLUBXRbxf44p2Vc1n6OjNBaTbK20MZ5lQTSqjZPzbXzF.dcPHm', 'c985737260518cb87ba37b98cc5bcf1cc7d8e01f4e4c328afe6d38c2acca895f', '2025-06-19 13:44:31', 'fYCIzg9vSUWisfeeDD9VS6:APA91bE1vWgcSVJNvetbozgkOlLj3Edt78xpKryY1-pw7XMgJdN9ZKDwN31E4KCLuO_L_sSMNw_apNC49EJ6qBMPasy9UIYeNCDoCBEI8u8Udu6HtVhn-6Q'),
(9, 'hhh', '6658', 'cvhh', 'cghhh', 'tech_idproof/tech_688061bab200b6.85456976.png', 'the@gmail.com', '$2y$10$LuCupFH3fNeW9yKJpLSlB.kC/3BYHZLygRB/BU05TC8pr3vW/3DlG', NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `technician_status_log`
--

CREATE TABLE `technician_status_log` (
  `log_id` int(11) NOT NULL,
  `booking_id` varchar(50) NOT NULL,
  `technician_id` int(11) NOT NULL,
  `status` enum('assigned','reached','started','completed') NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  `notes` text DEFAULT NULL,
  `location_lat` decimal(10,8) DEFAULT NULL,
  `location_lng` decimal(11,8) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `technician_status_log`
--

INSERT INTO `technician_status_log` (`log_id`, `booking_id`, `technician_id`, `status`, `timestamp`, `notes`, `location_lat`, `location_lng`) VALUES
(1, 'BK202506023494', 1, 'assigned', '2025-06-02 14:29:28', 'Technician assigned by admin', NULL, NULL),
(2, 'BK202506023494', 1, 'reached', '2025-06-04 03:31:27', 'Fcc', NULL, NULL),
(3, 'BK202506023494', 1, 'started', '2025-06-04 03:31:37', 'Yess', NULL, NULL),
(4, 'BK202506023494', 1, 'completed', '2025-06-04 03:33:07', 'Yess', NULL, NULL),
(5, 'BK202506045430', 1, 'assigned', '2025-06-04 13:07:32', 'Technician assigned by admin', NULL, NULL),
(6, 'BK202506045430', 1, 'reached', '2025-06-04 13:10:42', 'Reached by bike', NULL, NULL),
(7, 'BK202506045430', 1, 'started', '2025-06-04 13:11:01', 'Started', NULL, NULL),
(8, 'BK202506171294', 8, 'assigned', '2025-06-17 11:40:26', 'Technician assigned by admin', NULL, NULL),
(9, 'BK202506171294', 8, 'reached', '2025-06-17 11:45:45', 'Reached using bike', NULL, NULL),
(10, 'BK202506171294', 8, 'started', '2025-06-17 11:46:00', 'Starting', NULL, NULL),
(11, 'BK202506171294', 8, 'completed', '2025-06-17 11:46:11', 'Completed', NULL, NULL),
(12, 'BK202506252006', 7, 'assigned', '2025-06-25 06:54:20', 'Technician assigned by admin', NULL, NULL),
(13, 'BK202506256190', 3, 'assigned', '2025-06-25 07:22:33', 'Technician assigned by admin', NULL, NULL),
(14, 'BK202507024565', 1, 'assigned', '2025-07-02 04:40:02', 'Technician assigned by admin', NULL, NULL),
(15, 'BK202506254984', 6, 'assigned', '2025-07-02 04:40:17', 'Technician assigned by admin', NULL, NULL),
(16, 'BK202507039963', 7, 'assigned', '2025-07-03 04:19:15', 'Technician assigned by admin', NULL, NULL),
(17, 'BK202507071356', 8, 'assigned', '2025-07-07 17:15:20', 'Technician assigned by admin', NULL, NULL),
(18, 'BK202506051025', 5, 'assigned', '2025-07-07 17:29:39', 'Technician assigned by admin', NULL, NULL),
(19, 'BK202506058974', 6, 'assigned', '2025-07-07 17:31:31', 'Technician assigned by admin', NULL, NULL),
(20, 'BK202506053149', 8, 'assigned', '2025-07-07 17:31:48', 'Technician assigned by admin', NULL, NULL),
(21, 'BK202507024565', 1, 'reached', '2025-07-07 17:40:01', 'reach', NULL, NULL),
(22, 'BK202506045430', 1, 'completed', '2025-07-07 17:40:08', '', NULL, NULL),
(23, 'BK202507024565', 1, 'started', '2025-07-07 17:40:19', 'complete', NULL, NULL),
(24, 'BK202507024565', 1, 'completed', '2025-07-07 17:40:52', '', NULL, NULL),
(25, 'BK202507158048', 8, 'assigned', '2025-07-15 02:26:02', 'Technician assigned by admin', NULL, NULL),
(26, 'BK202507213571', 1, 'assigned', '2025-07-21 09:03:24', 'Technician assigned by admin', NULL, NULL),
(27, 'BK202507153726', 1, 'assigned', '2025-07-21 09:03:57', 'Technician assigned by admin', NULL, NULL),
(28, 'BK202507077028', 7, 'assigned', '2025-07-22 15:40:12', 'Technician assigned by admin', NULL, NULL),
(29, 'BK202507216071', 5, 'assigned', '2025-07-22 15:40:37', 'Technician assigned by admin', NULL, NULL),
(30, 'BK202507237438', 1, 'assigned', '2025-07-23 15:34:19', 'Technician assigned by admin', NULL, NULL),
(31, 'BK202507244224', 1, 'assigned', '2025-07-24 17:36:46', 'Technician assigned by admin', NULL, NULL),
(32, 'BK202507245149', 3, 'assigned', '2025-07-24 17:56:28', 'Technician assigned by admin', NULL, NULL),
(33, 'BK202507224065', 6, 'assigned', '2025-07-24 17:56:51', 'Technician assigned by admin', NULL, NULL),
(34, 'BK202507248876', 3, 'assigned', '2025-07-24 17:59:01', 'Technician assigned by admin', NULL, NULL),
(35, 'BK202507246364', 7, 'assigned', '2025-07-24 18:01:05', 'Technician assigned by admin', NULL, NULL),
(36, 'BK202507222188', 8, 'assigned', '2025-07-24 18:04:25', 'Technician assigned by admin', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `customer_name` varchar(255) NOT NULL,
  `mobile_number` varchar(15) NOT NULL,
  `address1` text NOT NULL,
  `address2` text DEFAULT NULL,
  `profile_pic` varchar(255) DEFAULT NULL,
  `email_id` varchar(255) NOT NULL,
  `gender` enum('Male','Female','Other') DEFAULT NULL,
  `country` varchar(100) DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `sessionid` varchar(255) DEFAULT NULL,
  `session_expiry` datetime DEFAULT NULL,
  `fcm_token` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `customer_name`, `mobile_number`, `address1`, `address2`, `profile_pic`, `email_id`, `gender`, `country`, `password`, `sessionid`, `session_expiry`, `fcm_token`) VALUES
(1, 'Hari raja', '9840523294', '5/68 MMDA maduravoyal chennai', 'samantha', 'userprofile/profile_68729c35e2e923.07158991.jpg', 'hari@gmail.co', 'Male', 'India', '$2y$10$fR/JoswSNNriyoDh5J.1U.dOn5qzUfH/2wlMON6ud0he8ytEJ8/VO', '301709e6708609e0c2d4f51ed2492df651a06931c37a07c5ad2255aef2eefe3c', '2025-07-25 04:38:08', 'fxYD1Y5NQ-mmZEbVHQCcKa:APA91bFNFerryrlniQ0hvE115tuScV_gSNnL0DoLyCX_AvGXjux-faj70-MgWWdqpNp3DQGVKkp6eSvBZui5Or2TGmZXtLlKqyLVHle8Wq_yDJUWRrnr5Gk'),
(2, 'Rishi', '9840523264', 'kurukul sandhu pillar Kovil', 'hell', 'userprofile/profile_67d68f0593b5f3.71923177.jpg', 'rishivasan@gmail.com', 'Male', 'India', '$2y$10$sihJDojCvHe2kH8co5RXv.lYwW92EJpLgUi1IV0t8eLNq.96yN8rm', '5e2657d2600e76a9f2f80cd1344785dc2292dc23654f7a88fb7a6cf3aa39ecba', '2025-03-18 09:07:07', 'your_sample_fcm_token'),
(3, 'anjana', '7904342001', 'dno \n43 shanthi nagar', '', 'userprofile/profile_685b95cd50bdb8.64733011.jpg', 'anjanaeswaran001@gmail.com', 'Female', 'India', '$2y$10$xiLCGygstpSL2sIwJ.Hb/eUYmpFInPb2woUVCgVUgOEYOPq/Yb1Py', '04dc3572504e903176787fb66c44749c7d92fddd021718864d258d86556ccdb3', '2025-07-25 05:05:09', 'eUdNJEgTTg-wLg9Hn0jSnY:APA91bEw4nsoQWJa4VAOvwLgWtXuxkAuLgApQoKBTVvWHdpVNYw-kNA5-FOsDYrOHP4isg54RS74Qh-u7xpothzZ4VSd_PmcbJ_hwmXW4uQUu_2IRX-HslE'),
(4, 'Ashik', '8637454428', '', NULL, NULL, '', NULL, NULL, '$2y$10$GFGGfhJ8is6MXj0DKJkSvOvvJtqJnogS7thc53/pGj66DaPB.h22O', '0a69e4635cf09915a4bf5ca2352804e598896ef2691faad4548ba24aa0f124f0', '2025-06-27 06:26:26', NULL),
(16, 'fgg', '9840553297', 'thrid', '', NULL, 'uri@gmail.com', 'Male', 'India', '$2y$10$jVDi/xXQ/Is.8PF54EYmQuPE/tihojMp6qfkxni7HmvKqZvj0crHO', '1b5fa0810beb102576efd2226d5cffebd0001b10a17d8550177b6995691d81b1', '2025-06-27 06:54:29', 'fYCIzg9vSUWisfeeDD9VS6:APA91bE1vWgcSVJNvetbozgkOlLj3Edt78xpKryY1-pw7XMgJdN9ZKDwN31E4KCLuO_L_sSMNw_apNC49EJ6qBMPasy9UIYeNCDoCBEI8u8Udu6HtVhn-6Q'),
(17, 'sabanaparveen', '7339424526', '', NULL, NULL, 'user_1750835321_1315@placeholder.com', NULL, NULL, '$2y$10$/FnMcZZ14veRT7m0MEh6C.0QlvNdLEDK95yuSbX.SqmuxMAO5kTkS', 'fd6fc50ab5f9efed8756fb074b39350255d41fb7de7598649601a4c901061d15', '2025-06-27 07:08:41', NULL),
(18, 'Ashik', '9092468900', 'PBS castle block 2', 'nethaji street Vanasakthi nagar ', NULL, 'ashikali613@gmail.com', 'Male', 'India', '$2y$10$ZbAFxstxRVdKXfvkfNE/xex2g9jwyyjdPf95ymwDwz2.mJ6A6OtHG', 'ec8f73c2a81e84b1e3c6b8d4c32f2c54d305d95d55303ee20c52eee0bd0fd3d9', '2025-06-27 13:15:36', 'dKxUBecsRW-kEmo-i2NUCZ:APA91bFnVnoOTXjGzUMfkRJkTxVWhMt0wLXT-yr0mNapLJsc-H3LLIcWBtP45r2uL1vLd99m9K4aI038aQnP1bMPLTFVu_fCGGs-BlYQCGeYIIVXrUjdvu0'),
(19, 'Tharik', '6383428143', 'Jawadupatty', NULL, NULL, 'user_1750868414_3202@placeholder.com', NULL, NULL, '$2y$10$vXL5wDp0MBpPO.5cyXrU9eBe58GMacthHA2lxD3p19NT5bel66HAG', '76692bed040737a04d06572ad85ea11cff2737ca5966002e0a4ab4b8767974a6', '2025-06-27 16:20:33', 'c4bvphf-SGu0-Fp_sOLlTk:APA91bFWCP4do0yLUooYGk1tXESWm4ncyq1Ps3SilkS39qWbt7dIacDTq1vAGWGNvdFvVEuFQZ7_IILWdqqVxfvK75YJl0aOKQj15MZ_3uh3ktTLa8lXB2Q'),
(20, 'aju', '7977813204', 'shanthi nagar', NULL, NULL, 'user_1751907381_7235@placeholder.com', NULL, NULL, '$2y$10$tkesFHpa0kfa6brHbRHbM.k8381DE8LR79LnlKdI4GIilTjaRrZxy', 'c0bd411b72300f5f54efb661ff2f0716362de8fa197fb1030704028cc471376e', '2025-07-09 16:56:38', 'dmm6rVIoR-eTliq0ONkBz2:APA91bEfDyxCVE8YtpVaAjJ-eqhz_y06pBDBR6ZLsupOqnyoFaRv5K0EXMe6nSaEga8J-ZOUF_uMQxHRWE-IV9YzRd1m59_ZF76uXMiaDiuiETQs-50f2Gk'),
(21, 'Mohammed Rafi', '9324867676', '', NULL, NULL, 'user_1751970217_6078@placeholder.com', NULL, NULL, '$2y$10$gM.8RQt65gSerZLDR3UaZOjgn8ocpBah/6EsCj2TYVrbUpmMPBapi', 'd4ace4a096f2b287e472dad1542c4769350a609bce3f5f960b72b9ee5b48871c', '2025-07-10 10:23:59', 'dKxUBecsRW-kEmo-i2NUCZ:APA91bFnVnoOTXjGzUMfkRJkTxVWhMt0wLXT-yr0mNapLJsc-H3LLIcWBtP45r2uL1vLd99m9K4aI038aQnP1bMPLTFVu_fCGGs-BlYQCGeYIIVXrUjdvu0'),
(22, 'hari', '8940645820', '3kd', 'test address', 'userprofile/profile_68810fc4625ec7.35811627.jpg', 'testbari@gmail.com', 'Male', 'India', '$2y$10$t6TcMjMvqNbkN4D1QFEdE.Qm4xv7QBIpXNKE36hr6zlvYmPvkhrRa', 'ca3911d4f978544cde38eb275ad3e73bf8a87fded92112cd21bd127688afd7bd', '2025-07-27 15:17:56', 'web_token'),
(23, 'hari', '8940645828', '', NULL, NULL, 'user_1753017114_4568@placeholder.com', NULL, NULL, '$2y$10$/GzBjAiLjwtV5.yQovnXqOYDrheuvR..NGIx34p6tOOkWUnBVcGvm', '8ec1a8c3153206248223331b23dca9b1c4802ad7d266f8dc28fd1a21d352a04f', '2025-07-22 13:11:54', NULL),
(24, 'Ashik', '8111043335', 'PBS castle', NULL, NULL, 'user_1753247139_5219@placeholder.com', NULL, NULL, '$2y$10$q9lzR9At/HrNzbCRjFmS/uq2sqe68FeHuPhONZhB1bSjinvG4TWMq', '92be98871a039b29a39499cd1127915fb775b9521cc925320a84b7864cfc2ee6', '2025-07-27 10:28:02', 'dKxUBecsRW-kEmo-i2NUCZ:APA91bFnVnoOTXjGzUMfkRJkTxVWhMt0wLXT-yr0mNapLJsc-H3LLIcWBtP45r2uL1vLd99m9K4aI038aQnP1bMPLTFVu_fCGGs-BlYQCGeYIIVXrUjdvu0');

-- --------------------------------------------------------

--
-- Table structure for table `user_notifications`
--

CREATE TABLE `user_notifications` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `status_log_id` int(11) NOT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `read_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_notifications`
--

INSERT INTO `user_notifications` (`id`, `user_id`, `status_log_id`, `is_read`, `read_at`, `created_at`) VALUES
(1, 1, 2, 1, '2025-06-17 11:34:36', '2025-06-04 11:33:05'),
(2, 1, 1, 1, '2025-06-17 11:34:35', '2025-06-04 11:33:06'),
(3, 1, 3, 1, '2025-06-17 11:34:37', '2025-06-04 11:33:07'),
(4, 1, 4, 1, '2025-06-05 07:23:17', '2025-06-04 11:33:07'),
(17, 1, 6, 1, '2025-06-05 07:23:18', '2025-06-04 15:06:04'),
(18, 1, 7, 1, '2025-06-05 07:23:18', '2025-06-04 15:06:05'),
(20, 1, 5, 1, '2025-06-05 07:23:17', '2025-06-05 05:24:28'),
(33, 1, 22, 1, '2025-07-12 17:32:08', '2025-07-12 17:32:08'),
(34, 1, 19, 1, '2025-07-12 17:32:08', '2025-07-12 17:32:08'),
(35, 1, 20, 1, '2025-07-12 17:32:09', '2025-07-12 17:32:09'),
(36, 3, 24, 1, '2025-07-15 02:22:07', '2025-07-15 02:22:07'),
(37, 3, 23, 1, '2025-07-15 02:22:18', '2025-07-15 02:22:18'),
(38, 22, 26, 1, '2025-07-22 16:21:45', '2025-07-22 16:21:45'),
(39, 22, 29, 1, '2025-07-22 16:21:46', '2025-07-22 16:21:46'),
(40, 24, 30, 1, '2025-07-26 06:30:16', '2025-07-26 06:30:16');

-- --------------------------------------------------------

--
-- Table structure for table `email_logs`
--

CREATE TABLE `email_logs` (
  `id` int(11) NOT NULL,
  `user_email` varchar(255) NOT NULL,
  `user_name` varchar(255) NOT NULL,
  `booking_id` varchar(20) NOT NULL,
  `service_name` varchar(100) NOT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `sent_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin_login`
--
ALTER TABLE `admin_login`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `bookings`
--
ALTER TABLE `bookings`
  ADD PRIMARY KEY (`booking_id`),
  ADD KEY `idx_bookings_user_id` (`user_id`),
  ADD KEY `idx_bookings_date` (`service_date`),
  ADD KEY `idx_bookings_status` (`booking_status`),
  ADD KEY `idx_assigned_technician` (`assigned_technician`),
  ADD KEY `idx_bookings_service_date` (`service_date`),
  ADD KEY `idx_bookings_created_at` (`created_at`);

--
-- Indexes for table `booking_items`
--
ALTER TABLE `booking_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_booking_items_booking_id` (`booking_id`);

--
-- Indexes for table `contact_queries`
--
ALTER TABLE `contact_queries`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- Indexes for table `locations`
--
ALTER TABLE `locations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `location_name` (`location_name`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`notification_id`),
  ADD KEY `idx_user_type_id` (`user_type`,`user_id`),
  ADD KEY `idx_booking_id` (`related_booking_id`),
  ADD KEY `idx_created_at` (`created_at`),
  ADD KEY `idx_notifications_unread` (`user_type`,`user_id`,`is_read`);

--
-- Indexes for table `notification_requests`
--
ALTER TABLE `notification_requests`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `request_id` (`request_id`);

--
-- Indexes for table `offers`
--
ALTER TABLE `offers`
  ADD PRIMARY KEY (`offer_id`),
  ADD UNIQUE KEY `coupon_number` (`coupon_number`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`order_id`),
  ADD KEY `assigned_technician` (`assigned_technician`);

--
-- Indexes for table `password_change_log`
--
ALTER TABLE `password_change_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_changed_at` (`changed_at`);

--
-- Indexes for table `reviews`
--
ALTER TABLE `reviews`
  ADD PRIMARY KEY (`review_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `services`
--
ALTER TABLE `services`
  ADD PRIMARY KEY (`service_id`);

--
-- Indexes for table `service_details`
--
ALTER TABLE `service_details`
  ADD PRIMARY KEY (`service_type_id`),
  ADD KEY `service_id` (`service_id`);

--
-- Indexes for table `technicians`
--
ALTER TABLE `technicians`
  ADD PRIMARY KEY (`technician_id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `technician_status_log`
--
ALTER TABLE `technician_status_log`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `idx_booking_id` (`booking_id`),
  ADD KEY `idx_technician_id` (`technician_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `email_id` (`email_id`);

--
-- Indexes for table `user_notifications`
--
ALTER TABLE `user_notifications`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_notification` (`user_id`,`status_log_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_status_log_id` (`status_log_id`);

--
-- Indexes for table `email_logs`
--
ALTER TABLE `email_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_email` (`user_email`),
  ADD KEY `idx_booking_id` (`booking_id`),
  ADD KEY `idx_sent_at` (`sent_at`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admin_login`
--
ALTER TABLE `admin_login`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `booking_items`
--
ALTER TABLE `booking_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;

--
-- AUTO_INCREMENT for table `contact_queries`
--
ALTER TABLE `contact_queries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `locations`
--
ALTER TABLE `locations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `notification_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=62;

--
-- AUTO_INCREMENT for table `notification_requests`
--
ALTER TABLE `notification_requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `offers`
--
ALTER TABLE `offers`
  MODIFY `offer_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `order_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `password_change_log`
--
ALTER TABLE `password_change_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `reviews`
--
ALTER TABLE `reviews`
  MODIFY `review_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `services`
--
ALTER TABLE `services`
  MODIFY `service_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `service_details`
--
ALTER TABLE `service_details`
  MODIFY `service_type_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT for table `technicians`
--
ALTER TABLE `technicians`
  MODIFY `technician_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `technician_status_log`
--
ALTER TABLE `technician_status_log`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=37;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT for table `user_notifications`
--
ALTER TABLE `user_notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;

--
-- AUTO_INCREMENT for table `email_logs`
--
ALTER TABLE `email_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `bookings`
--
ALTER TABLE `bookings`
  ADD CONSTRAINT `bookings_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_bookings_technician` FOREIGN KEY (`assigned_technician`) REFERENCES `technicians` (`technician_id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `booking_items`
--
ALTER TABLE `booking_items`
  ADD CONSTRAINT `booking_items_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE;

--
-- Constraints for table `contact_queries`
--
ALTER TABLE `contact_queries`
  ADD CONSTRAINT `contact_queries_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`assigned_technician`) REFERENCES `technicians` (`technician_id`);

--
-- Constraints for table `reviews`
--
ALTER TABLE `reviews`
  ADD CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `service_details`
--
ALTER TABLE `service_details`
  ADD CONSTRAINT `service_details_ibfk_1` FOREIGN KEY (`service_id`) REFERENCES `services` (`service_id`) ON DELETE CASCADE;

--
-- Constraints for table `technician_status_log`
--
ALTER TABLE `technician_status_log`
  ADD CONSTRAINT `fk_status_log_technician` FOREIGN KEY (`technician_id`) REFERENCES `technicians` (`technician_id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
