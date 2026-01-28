<?php
require_once 'db.php';
header('Content-Type: application/json');

$data = json_decode(file_get_contents("php://input"), true);
$uid = $data['uid'] ?? '';

if (empty($uid)) {
    http_response_code(400);
    echo json_encode(['error' => 'uid is required']);
    exit;
}

try {
    // Start transaction
    $pdo->beginTransaction();

    // 1. Delete mining sessions where this user is the MINER
    $stmtMiner = $pdo->prepare("DELETE FROM mining_records WHERE uid = ?");
    $stmtMiner->execute([$uid]);

    // 2. Delete mining sessions where this user is the COIN OWNER (users mining this user's coin)
    $stmtOwner = $pdo->prepare("DELETE FROM mining_records WHERE coinOwnerId = ?");
    $stmtOwner->execute([$uid]);

    // 3. Delete the coin itself (if any)
    $stmtCoin = $pdo->prepare("DELETE FROM user_coins WHERE ownerId = ?");
    $stmtCoin->execute([$uid]);

    $pdo->commit();
    echo json_encode(['success' => true]);
} catch (PDOException $e) {
    $pdo->rollBack();
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>