<?php
require_once 'db.php';
header('Content-Type: application/json');

$uid = $_GET['uid'] ?? '';

if (empty($uid)) {
    echo json_encode(null);
    exit;
}

try {
    $stmt = $pdo->prepare("SELECT * FROM user_coins WHERE ownerId = ? LIMIT 1");
    $stmt->execute([$uid]);
    $coin = $stmt->fetch();
    
    if ($coin) {
            // Ensure types match Firestore (boolean for isActive, numeric for others)
            $coin['isActive'] = (bool)$coin['isActive'];
            $coin['baseRatePerHour'] = (float)$coin['baseRatePerHour'];
            $coin['minersCount'] = (int)$coin['minersCount'];
            
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