-- ============================================================
-- DATABASE: tailorix (schema only, no data)
-- TailorIX - Laravel Backend
-- ============================================================

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
-- 15. TABEL: migrations
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
('2019_12_14_000001_create_personal_access_tokens_table', 1);

SET FOREIGN_KEY_CHECKS = 1;
