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

    // Delete from mining_records first (foreign key constraint usually, or just cleanup)
    $stmt1 = $pdo->prepare("DELETE FROM mining_records WHERE coinOwnerId = ?");
    $stmt1->execute([$uid]);

    // Delete from user_coins
    $stmt2 = $pdo->prepare("DELETE FROM user_coins WHERE ownerId = ?");
    $stmt2->execute([$uid]);

    $pdo->commit();
    echo json_encode(['success' => true]);
} catch (PDOException $e) {
    $pdo->rollBack();
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>