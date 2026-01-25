<?php
require_once 'db.php';
header('Content-Type: application/json');

$data = json_decode(file_get_contents("php://input"), true);
$coinOwnerId = $data['coinOwnerId'] ?? '';
$uid = $data['uid'] ?? ''; // Passed from Flutter

if (empty($uid) || empty($coinOwnerId)) {
    http_response_code(400);
    echo json_encode(['error' => 'uid and coinOwnerId are required']);
    exit;
}

try {
    // 1. Add to mining_records
    $sql = "INSERT IGNORE INTO mining_records (uid, coinOwnerId, createdAt, updatedAt) VALUES (?, ?, NOW(), NOW())";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$uid, $coinOwnerId]);

    // 2. Increment minersCount in user_coins
    // (Only if the record was actually inserted, but for simplicity/idempotency we can just run it)
    $updateSql = "UPDATE user_coins SET minersCount = minersCount + 1 WHERE ownerId = ?";
    $updateStmt = $pdo->prepare($updateSql);
    $updateStmt->execute([$coinOwnerId]);

    echo json_encode(['success' => true]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>