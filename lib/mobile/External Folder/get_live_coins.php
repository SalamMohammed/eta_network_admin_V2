<?php
require_once 'db.php';
header('Content-Type: application/json');

// Supports sorting!
$sort = $_GET['sort'] ?? 'popular';

// Whitelist allowed sort columns to prevent SQL injection
$allowedSorts = [
    'popular' => 'minersCount DESC',
    'name_az' => 'name ASC',
    'name_za' => 'name DESC',
    'old_new' => 'createdAt ASC',
    'new_old' => 'createdAt DESC',
    'newest'  => 'createdAt DESC'
];

$orderBy = $allowedSorts[$sort] ?? 'minersCount DESC';

try {
    // Prepare statement even though we use whitelisted string, good practice
    $sql = "SELECT * FROM user_coins WHERE isActive = 1 ORDER BY $orderBy LIMIT 50";
    $stmt = $pdo->query($sql);
    
    $rows = $stmt->fetchAll();
    echo json_encode($rows);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>