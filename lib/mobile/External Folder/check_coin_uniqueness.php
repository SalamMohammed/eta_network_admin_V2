<?php
require_once 'db.php';
header('Content-Type: application/json');

$data = json_decode(file_get_contents("php://input"), true);
$name = $data['name'] ?? '';
$symbol = $data['symbol'] ?? '';
$excludeUid = $data['excludeUid'] ?? '';

$response = ['available' => true];

if (!empty($name)) {
    $stmt = $pdo->prepare("SELECT ownerId FROM user_coins WHERE name = ? AND ownerId != ? LIMIT 1");
    $stmt->execute([$name, $excludeUid]);
    if ($stmt->fetch()) {
        $response = ['available' => false, 'message' => "Coin name \"$name\" is already taken."];
    }
}

if ($response['available'] && !empty($symbol)) {
    $stmt = $pdo->prepare("SELECT ownerId FROM user_coins WHERE symbol = ? AND ownerId != ? LIMIT 1");
    $stmt->execute([$symbol, $excludeUid]);
    if ($stmt->fetch()) {
        $response = ['available' => false, 'message' => "Coin symbol \"$symbol\" is already taken."];
    }
}

echo json_encode($response);
?>