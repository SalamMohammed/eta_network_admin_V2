<?php
require_once 'db.php';
header('Content-Type: application/json');

$data = json_decode(file_get_contents("php://input"), true);
$ownerId = $data['ownerId'] ?? '';

if (empty($ownerId)) {
    http_response_code(400);
    echo json_encode(['error' => 'ownerId is required']);
    exit;
}

$name = $data['name'] ?? '';
$symbol = $data['symbol'] ?? '';
$imageUrl = $data['imageUrl'] ?? '';
$description = $data['description'] ?? '';
$baseRatePerHour = $data['baseRatePerHour'] ?? 0.0;
$isActive = isset($data['isActive']) ? ($data['isActive'] ? 1 : 0) : 1;
// Ensure socialLinks is stored as a valid JSON string
$socialLinks = isset($data['socialLinks']) ? json_encode($data['socialLinks']) : '[]';

$sql = "INSERT INTO user_coins 
        (ownerId, name, symbol, imageUrl, description, baseRatePerHour, isActive, socialLinks, createdAt, updatedAt)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
        ON DUPLICATE KEY UPDATE
        name = VALUES(name),
        symbol = VALUES(symbol),
        imageUrl = VALUES(imageUrl),
        description = VALUES(description),
        baseRatePerHour = VALUES(baseRatePerHour),
        isActive = VALUES(isActive),
        socialLinks = VALUES(socialLinks),
        updatedAt = NOW()";

try {
    $pdo->beginTransaction();

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        $ownerId, $name, $symbol, $imageUrl, $description, $baseRatePerHour, $isActive, $socialLinks
    ]);
    
    // Auto-add creator to their own coin's mining list
    // This mimics the Firestore logic where creators auto-mine their own coin
    $miningSql = "INSERT IGNORE INTO mining_records (uid, coinOwnerId, createdAt, updatedAt) VALUES (?, ?, NOW(), NOW())";
    $miningStmt = $pdo->prepare($miningSql);
    $miningStmt->execute([$ownerId, $ownerId]);
    
    // If we actually inserted into mining_records (rowCount > 0), increment minersCount
    if ($miningStmt->rowCount() > 0) {
        $updateSql = "UPDATE user_coins SET minersCount = minersCount + 1 WHERE ownerId = ?";
        $updateStmt = $pdo->prepare($updateSql);
        $updateStmt->execute([$ownerId]);
    }

    $pdo->commit();
    echo json_encode(['success' => true]);
} catch (PDOException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>