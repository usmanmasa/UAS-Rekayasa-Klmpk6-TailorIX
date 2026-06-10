-- ============================================================
-- DATABASE: db_tailorix
-- TailorIX - Laravel Backend
-- Generated dari semua migration + seeder
-- Cara pakai: Import file ini lewat phpMyAdmin atau MySQL CLI
-- ============================================================

CREATE DATABASE IF NOT EXISTS `db_tailorix`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `db_tailorix`;

SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- 1. TABEL: users
-- ============================================================
CREATE TABLE IF NOT EXISTS `users` (
  `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `role`                      VARCHAR(255)    NOT NULL DEFAULT 'customer',
  `name`                      VARCHAR(255)    NOT NULL,
  `email`                     VARCHAR(255)    NOT NULL UNIQUE,
  `email_verified_at`         TIMESTAMP       NULL DEFAULT NULL,
  `password`                  VARCHAR(255)    NOT NULL,
  `phone`                     VARCHAR(255)    NULL DEFAULT NULL,
  `address`                   VARCHAR(255)    NULL DEFAULT NULL,
  `profile_photo_url`         VARCHAR(255)    NULL DEFAULT NULL,
  `is_verified`               TINYINT(1)      NOT NULL DEFAULT 0,
  `terms_accepted`            TINYINT(1)      NOT NULL DEFAULT 0,
  `terms_accepted_at`         TIMESTAMP       NULL DEFAULT NULL,
  `shop_name`                 VARCHAR(255)    NULL DEFAULT NULL,
  `location_lat`              DECIMAL(10,7)   NULL DEFAULT NULL,
  `location_lng`              DECIMAL(10,7)   NULL DEFAULT NULL,
  `specializations`           JSON            NULL DEFAULT NULL,
  `portfolio`                 JSON            NULL DEFAULT NULL,
  `is_available`              TINYINT(1)      NOT NULL DEFAULT 1,
  `rating`                    DECIMAL(3,2)    NOT NULL DEFAULT 0.00,
  `rating_count`              INT UNSIGNED    NOT NULL DEFAULT 0,
  `verification_document_url` VARCHAR(255)    NULL DEFAULT NULL,
  `remember_token`            VARCHAR(100)    NULL DEFAULT NULL,
  `device_token`              VARCHAR(255)    NULL DEFAULT NULL,
  `created_at`                TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`                TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 2. TABEL: password_reset_tokens
-- ============================================================
CREATE TABLE IF NOT EXISTS `password_reset_tokens` (
  `email`      VARCHAR(255) NOT NULL,
  `token`      VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP    NULL DEFAULT NULL,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 3. TABEL: failed_jobs
-- ============================================================
CREATE TABLE IF NOT EXISTS `failed_jobs` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid`       VARCHAR(255)    NOT NULL UNIQUE,
  `connection` TEXT            NOT NULL,
  `queue`      TEXT            NOT NULL,
  `payload`    LONGTEXT        NOT NULL,
  `exception`  LONGTEXT        NOT NULL,
  `failed_at`  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 4. TABEL: personal_access_tokens
-- ============================================================
CREATE TABLE IF NOT EXISTS `personal_access_tokens` (
  `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tokenable_type` VARCHAR(255)    NOT NULL,
  `tokenable_id`   BIGINT UNSIGNED NOT NULL,
  `name`           VARCHAR(255)    NOT NULL,
  `token`          VARCHAR(64)     NOT NULL UNIQUE,
  `abilities`      TEXT            NULL DEFAULT NULL,
  `last_used_at`   TIMESTAMP       NULL DEFAULT NULL,
  `expires_at`     TIMESTAMP       NULL DEFAULT NULL,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`, `tokenable_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 5. TABEL: penjahits
-- ============================================================
CREATE TABLE IF NOT EXISTS `penjahits` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nama`       VARCHAR(255)    NOT NULL,
  `alamat`     VARCHAR(255)    NOT NULL,
  `latitude`   DECIMAL(10,7)   NOT NULL,
  `longitude`  DECIMAL(10,7)   NOT NULL,
  `kategori`   VARCHAR(255)    NOT NULL,
  `rating`     DECIMAL(3,2)    NOT NULL DEFAULT 0.00,
  `harga`      INT             NOT NULL DEFAULT 0,
  `status`     ENUM('buka','tutup') NOT NULL DEFAULT 'buka',
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 6. TABEL: favorite_tailors
-- ============================================================
CREATE TABLE IF NOT EXISTS `favorite_tailors` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `customer_id` BIGINT UNSIGNED NOT NULL,
  `tailor_id`   BIGINT UNSIGNED NOT NULL,
  `created_at`  TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`  TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `favorite_tailors_customer_id_tailor_id_unique` (`customer_id`, `tailor_id`),
  CONSTRAINT `fk_favorites_customer` FOREIGN KEY (`customer_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_favorites_tailor`   FOREIGN KEY (`tailor_id`)   REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 7. TABEL: orders
-- ============================================================
CREATE TABLE IF NOT EXISTS `orders` (
  `id`                   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `customer_id`          BIGINT UNSIGNED NOT NULL,
  `tailor_id`            BIGINT UNSIGNED NOT NULL,
  `category`             VARCHAR(255)    NOT NULL,
  `description`          TEXT            NULL DEFAULT NULL,
  `deadline`             DATE            NULL DEFAULT NULL,
  `delivery_mode`        VARCHAR(255)    NOT NULL DEFAULT 'dropoff',
  `status`               VARCHAR(255)    NOT NULL DEFAULT 'waiting_confirmation',
  `estimated_price_min`  DECIMAL(12,2)   NULL DEFAULT NULL,
  `estimated_price_max`  DECIMAL(12,2)   NULL DEFAULT NULL,
  `agreed_price`         DECIMAL(12,2)   NULL DEFAULT NULL,
  `final_price`          DECIMAL(12,2)   NULL DEFAULT NULL,
  `confidence`           DECIMAL(5,2)    NULL DEFAULT NULL,
  `tailor_notes`         TEXT            NULL DEFAULT NULL,
  `created_at`           TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`           TIMESTAMP       NULL DEFAULT NULL,
  `accepted_at`          TIMESTAMP       NULL DEFAULT NULL,
  `cancelled_at`         TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_orders_customer` FOREIGN KEY (`customer_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_orders_tailor`   FOREIGN KEY (`tailor_id`)   REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 8. TABEL: order_photos
-- ============================================================
CREATE TABLE IF NOT EXISTS `order_photos` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id`   BIGINT UNSIGNED NOT NULL,
  `path`       VARCHAR(255)    NOT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_order_photos_order` FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 9. TABEL: ml_estimations
-- ============================================================
CREATE TABLE IF NOT EXISTS `ml_estimations` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id`    BIGINT UNSIGNED NULL DEFAULT NULL,
  `category`    VARCHAR(255)    NOT NULL,
  `description` TEXT            NULL DEFAULT NULL,
  `photos`      JSON            NULL DEFAULT NULL,
  `min_price`   DECIMAL(12,2)   NOT NULL,
  `max_price`   DECIMAL(12,2)   NOT NULL,
  `confidence`  DECIMAL(5,2)    NOT NULL,
  `analysis`    JSON            NULL DEFAULT NULL,
  `created_at`  TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`  TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ml_estimations_order` FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 10. TABEL: payments
-- ============================================================
CREATE TABLE IF NOT EXISTS `payments` (
  `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id`       BIGINT UNSIGNED NOT NULL,
  `amount`         DECIMAL(12,2)   NOT NULL,
  `payment_method` VARCHAR(255)    NOT NULL,
  `payment_type`   VARCHAR(255)    NOT NULL DEFAULT 'down_payment',
  `status`         VARCHAR(255)    NOT NULL DEFAULT 'pending',
  `transaction_id` VARCHAR(255)    NULL DEFAULT NULL,
  `snap_token`     VARCHAR(255)    NULL DEFAULT NULL,
  `redirect_url`   VARCHAR(255)    NULL DEFAULT NULL,
  `metadata`       JSON            NULL DEFAULT NULL,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_payments_order` FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 11. TABEL: reviews
-- ============================================================
CREATE TABLE IF NOT EXISTS `reviews` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id`    BIGINT UNSIGNED NOT NULL,
  `customer_id` BIGINT UNSIGNED NOT NULL,
  `tailor_id`   BIGINT UNSIGNED NOT NULL,
  `rating`      TINYINT         NOT NULL,
  `comment`     TEXT            NULL DEFAULT NULL,
  `photos`      JSON            NULL DEFAULT NULL,
  `reply_text`  VARCHAR(255)    NULL DEFAULT NULL,
  `reported`    TINYINT(1)      NOT NULL DEFAULT 0,
  `status`      VARCHAR(255)    NOT NULL DEFAULT 'visible',
  `created_at`  TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`  TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_reviews_order`    FOREIGN KEY (`order_id`)    REFERENCES `orders`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_reviews_customer` FOREIGN KEY (`customer_id`) REFERENCES `users`(`id`)  ON DELETE CASCADE,
  CONSTRAINT `fk_reviews_tailor`   FOREIGN KEY (`tailor_id`)   REFERENCES `users`(`id`)  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 12. TABEL: order_timelines
-- ============================================================
CREATE TABLE IF NOT EXISTS `order_timelines` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id`   BIGINT UNSIGNED NOT NULL,
  `status`     VARCHAR(255)    NOT NULL,
  `notes`      TEXT            NULL DEFAULT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_order_timelines_order` FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 13. TABEL: chat_messages
-- ============================================================
CREATE TABLE IF NOT EXISTS `chat_messages` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id`    BIGINT UNSIGNED NOT NULL,
  `sender_id`   BIGINT UNSIGNED NOT NULL,
  `message`     TEXT            NULL DEFAULT NULL,
  `attachments` JSON            NULL DEFAULT NULL,
  `created_at`  TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`  TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_chat_messages_order`  FOREIGN KEY (`order_id`)  REFERENCES `orders`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_chat_messages_sender` FOREIGN KEY (`sender_id`) REFERENCES `users`(`id`)  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 14. TABEL: refund_requests
-- ============================================================
CREATE TABLE IF NOT EXISTS `refund_requests` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `payment_id` BIGINT UNSIGNED NOT NULL,
  `order_id`   BIGINT UNSIGNED NOT NULL,
  `reason`     TEXT            NOT NULL,
  `status`     VARCHAR(255)    NOT NULL DEFAULT 'pending',
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_refunds_payment` FOREIGN KEY (`payment_id`) REFERENCES `payments`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_refunds_order`   FOREIGN KEY (`order_id`)   REFERENCES `orders`(`id`)   ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 15. TABEL: migrations (wajib ada agar Laravel tidak error)
-- ============================================================
CREATE TABLE IF NOT EXISTS `migrations` (
  `id`        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `migration` VARCHAR(255) NOT NULL,
  `batch`     INT          NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `migrations` (`migration`, `batch`) VALUES
  ('2014_10_12_000000_create_users_table', 1),
  ('2014_10_12_100000_create_password_reset_tokens_table', 1),
  ('2019_08_19_000000_create_failed_jobs_table', 1),
  ('2019_12_14_000001_create_personal_access_tokens_table', 1),
  ('2025_04_01_000001_update_users_table_add_profile_fields', 1),
  ('2025_04_01_000002_create_tailor_favorites_table', 1),
  ('2025_04_01_000003_create_orders_table', 1),
  ('2025_04_01_000004_create_order_photos_table', 1),
  ('2025_04_01_000005_create_ml_estimations_table', 1),
  ('2025_04_01_000006_create_payments_table', 1),
  ('2025_04_01_000007_create_reviews_table', 1),
  ('2025_04_01_000008_create_order_timelines_table', 1),
  ('2025_04_01_000009_create_chat_messages_table', 1),
  ('2025_04_01_000010_create_refund_requests_table', 1),
  ('2026_06_08_000000_add_terms_acceptance_to_users_table', 1),
  ('2026_06_08_000000_create_penjahits_table', 1),
  ('2026_06_08_000001_add_device_token_to_users_table', 1);

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- DATA AWAL (SEEDER)
-- Password semua akun tailor/admin = sudah di-hash bcrypt
-- Admin    → admin@tailorix.com     / admin123
-- Tailor   → *.tailor@example.com   / password
-- ============================================================

INSERT INTO `users`
  (`role`,`name`,`email`,`password`,`phone`,`address`,`profile_photo_url`,`is_verified`,`terms_accepted`,`shop_name`,`location_lat`,`location_lng`,`specializations`,`portfolio`,`is_available`,`rating`,`rating_count`,`verification_document_url`,`created_at`,`updated_at`)
VALUES
(
  'admin','Admin TailoriX','admin@tailorix.com',
  '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
  '081122334455','Jakarta',NULL,1,1,NULL,NULL,NULL,NULL,NULL,1,0.00,0,NULL,NOW(),NOW()
),
(
  'tailor','Melvy Sari','melvy.tailor@example.com',
  '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
  '081234567890','Jl. Sudirman No. 45, Jakarta',
  'https://ui-avatars.com/api/?name=Melvy+Sari',
  1,1,'Melvy Sewing Studio',-6.2000000,106.8166660,
  '["jahitan wanita","jahitan pria","batik","kebaya"]',
  '["Pembuatan dress custom","Jasa jahit jas pria","Konveksi kebaya modern"]',
  1,4.80,132,'https://example.com/documents/melvy-id.jpg',NOW(),NOW()
),
(
  'tailor','Dewi Permata','dewi.tailor@example.com',
  '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
  '082345678901','Jl. Braga No. 12, Bandung',
  'https://ui-avatars.com/api/?name=Dewi+Permata',
  1,1,'Dewi''s Fashion House',-6.9147440,107.6098100,
  '["gaun pesta","kebaya","jahit bordir"]',
  '["Gaun pesta custom","Kebaya wisuda","Jahit bordir detail"]',
  1,4.70,95,'https://example.com/documents/dewi-id.jpg',NOW(),NOW()
),
(
  'tailor','Raka Putra','raka.tailor@example.com',
  '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
  '083456789012','Jl. Pemuda No. 77, Surabaya',
  'https://ui-avatars.com/api/?name=Raka+Putra',
  1,1,'Raka Tailor & Repair',-7.2574720,112.7520880,
  '["jas pria","seragam kantor","perbaikan pakaian"]',
  '["Jas custom premium","Seragam kantor rapi","Layanan perbaikan pakaian"]',
  1,4.60,88,'https://example.com/documents/raka-id.jpg',NOW(),NOW()
),
(
  'tailor','Intan Lestari','intan.tailor@example.com',
  '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
  '085678901234','Jl. Malioboro No. 14, Yogyakarta',
  'https://ui-avatars.com/api/?name=Intan+Lestari',
  1,1,'Intan Bridal Tailor',-7.7970680,110.3705290,
  '["bridal","kebaya","gaun malam"]',
  '["Kebaya pengantin","Gaun malam elegan","Bridal makeup garment"]',
  1,4.90,158,'https://example.com/documents/intan-id.jpg',NOW(),NOW()
),
(
  'tailor','Arif Santoso','arif.tailor@example.com',
  '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
  '081987654321','Jl. Pemuda No. 5, Semarang',
  'https://ui-avatars.com/api/?name=Arif+Santoso',
  1,1,'Arif Konveksi',-6.9666670,110.4166640,
  '["seragam","jahit kantor","kemeja"]',
  '["Seragam kantor tahan lama","Kemeja formal","Konveksi pesanan besar"]',
  1,4.50,74,'https://example.com/documents/arif-id.jpg',NOW(),NOW()
);

INSERT INTO `penjahits` (`nama`,`alamat`,`latitude`,`longitude`,`kategori`,`rating`,`harga`,`status`,`created_at`,`updated_at`) VALUES
  ('Bu Sari Taylor',        'Jl. Sudirman No.12, Bandung',   -6.9175, 107.6191, 'Alterasi',    4.9,  80000, 'buka',  NOW(), NOW()),
  ('Pak Andi Tailor',       'Jl. Dago No.45, Bandung',       -6.8951, 107.6099, 'Jahit Custom',4.7, 150000, 'tutup', NOW(), NOW()),
  ('Jahit Cepat Mba Rina',  'Jl. Cihampelas No.78, Bandung', -6.8983, 107.6066, 'Permak',      4.8, 100000, 'buka',  NOW(), NOW()),
  ('Tailor Mang Ujang',     'Jl. Braga No.22, Bandung',      -6.9214, 107.6079, 'Jas Formal',  4.6,  90000, 'buka',  NOW(), NOW()),
  ('Bu Dewi Fashion',       'Jl. Buah Batu No.33, Bandung',  -6.9401, 107.6318, 'Kebaya',      4.5, 120000, 'tutup', NOW(), NOW()),
  ('Tailor Pak Hendra',     'Jl. Setiabudhi No.101, Bandung',-6.8711, 107.5997, 'Seragam',     4.8, 110000, 'buka',  NOW(), NOW());

-- ============================================================
-- SELESAI — Semua tabel dan data awal sudah siap
-- Import lewat phpMyAdmin: Database > Import > pilih file ini
-- Import lewat CLI: mysql -u root -p < db_tailorix.sql
-- ============================================================
