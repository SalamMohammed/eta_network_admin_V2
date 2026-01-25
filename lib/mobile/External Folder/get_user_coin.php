<?php
require_once 'db.php';
header('Content-Type: application/json');

$uid = $_GET['uid'] ?? '';

if (empty($uid)) {
    echo json_encode(null);
    exit;
}

try {
    // Join mining_records to get mining status for the owner
    $sql = "SELECT 
                uc.*,
                mr.totalPoints, 
                mr.hourlyRate, 
                mr.lastMiningStart, 
                mr.lastMiningEnd, 
                mr.lastSyncedAt
            FROM user_coins uc
            LEFT JOIN mining_records mr ON uc.ownerId = mr.coinOwnerId AND mr.uid = uc.ownerId
            WHERE uc.ownerId = ? 
            LIMIT 1";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$uid]);
    $coin = $stmt->fetch();
    
    if ($coin) {
            // Ensure types match Firestore (boolean for isActive, numeric for others)
            $coin['isActive'] = (bool)$coin['isActive'];
            $coin['baseRatePerHour'] = (float)$coin['baseRatePerHour'];
            $coin['minersCount'] = (int)$coin['minersCount'];
            
            // Mining fields (might be null if LEFT JOIN fails, but shouldn't for creator)
            if (isset($coin['totalPoints'])) $coin['totalPoints'] = (float)$coin['totalPoints'];
            if (isset($coin['hourlyRate'])) $coin['hourlyRate'] = (float)$coin['hourlyRate'];
            
            // Decode socialLinks if it's a JSON string
            if (isset($coin['socialLinks']) && is_string($coin['socialLinks'])) {
                $coin['socialLinks'] = json_decode($coin['socialLinks'], true);
            }
            echo json_encode($coin);
        } else {
        echo json_encode(null);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>