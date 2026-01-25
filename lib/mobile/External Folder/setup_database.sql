-- 1. Create user_coins table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS user_coins (
    ownerId VARCHAR(191) NOT NULL,
    name VARCHAR(191) NOT NULL,
    symbol VARCHAR(50) NOT NULL,
    imageUrl TEXT,
    description TEXT,
    baseRatePerHour DOUBLE DEFAULT 0.0,
    isActive TINYINT(1) DEFAULT 1,
    socialLinks TEXT,
    minersCount INT DEFAULT 0,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (ownerId),
    UNIQUE KEY unique_name (name),
    UNIQUE KEY unique_symbol (symbol)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Create mining_records table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS mining_records (
    uid VARCHAR(191) NOT NULL,
    coinOwnerId VARCHAR(191) NOT NULL,
    totalPoints DOUBLE DEFAULT 0.0,
    hourlyRate DOUBLE DEFAULT 0.0,
    lastMiningStart DATETIME NULL,
    lastMiningEnd DATETIME NULL,
    lastSyncedAt DATETIME NULL,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (uid, coinOwnerId),
    CONSTRAINT fk_coin_owner
        FOREIGN KEY (coinOwnerId) 
        REFERENCES user_coins(ownerId) 
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
