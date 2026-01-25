<?php
require_once 'db.php';
header('Content-Type: application/json');

$uid = $_GET['uid'] ?? '';

if (empty($uid)) {
    echo json_encode([]);
    exit;
}

try {
    // Join mining_records with user_coins to get full coin details AND mining progress
    $sql = "SELECT 
                uc.*, 
                mr.totalPoints, 
                mr.hourlyRate, 
                mr.lastMiningStart, 
                mr.lastMiningEnd, 
                mr.lastSyncedAt
            FROM mining_records mr
            JOIN user_coins uc ON mr.coinOwnerId = uc.ownerId
            WHERE mr.uid = ?";
            
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$uid]);
    
    $rows = $stmt->fetchAll();
    
    // Convert numeric strings to proper types if needed (PDO often returns strings)
    // and decode socialLinks
    foreach ($rows as &$row) {
        $row['isActive'] = (bool)$row['isActive'];
        $row['totalPoints'] = (float)$row['totalPoints'];
        $row['baseRatePerHour'] = (float)$row['baseRatePerHour'];
        $row['hourlyRate'] = (float)$row['hourlyRate'];
        $row['minersCount'] = (int)$row['minersCount'];
        
        if (isset($row['socialLinks']) && is_string($row['socialLinks'])) {
            $row['socialLinks'] = json_decode($row['socialLinks'], true);
        }
    }
    
    echo json_encode($rows);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>