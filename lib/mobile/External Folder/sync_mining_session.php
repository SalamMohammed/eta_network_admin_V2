<?php
require_once 'db.php';
header('Content-Type: application/json');

$data = json_decode(file_get_contents("php://input"), true);
$uid = $data['uid'] ?? '';
$coinOwnerId = $data['coinOwnerId'] ?? '';

if (empty($uid) || empty($coinOwnerId)) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing required fields']);
    exit;
}

try {
    $pdo->beginTransaction();

    // Select for update to lock the row
    $stmt = $pdo->prepare("SELECT * FROM mining_records WHERE uid = ? AND coinOwnerId = ? FOR UPDATE");
    $stmt->execute([$uid, $coinOwnerId]);
    $record = $stmt->fetch();

    if (!$record) {
        $pdo->rollBack();
        echo json_encode(['success' => true, 'message' => 'No record found']);
        exit;
    }

    $hourlyRate = (float)$record['hourlyRate'];
    $lastSyncedAt = $record['lastSyncedAt']; // String datetime
    $lastMiningEnd = $record['lastMiningEnd']; // String datetime
    $totalPoints = (float)$record['totalPoints'];

    if (empty($lastSyncedAt) || empty($lastMiningEnd)) {
         $pdo->rollBack();
         echo json_encode(['success' => true, 'message' => 'Missing timestamps']);
         exit;
    }

    $now = new DateTime();
    $s = new DateTime($lastSyncedAt);
    $e = new DateTime($lastMiningEnd);
    
    // logic: until = now.isBefore(e) ? now : e;
    $until = ($now < $e) ? $now : $e;
    
    // elapsed seconds
    $elapsed = $until->getTimestamp() - $s->getTimestamp();
    
    if ($elapsed > 0) {
        $inc = ($elapsed / 3600.0) * $hourlyRate;
        if ($inc > 0) {
            $totalPoints += $inc;
            $newSyncedAt = $until->format('Y-m-d H:i:s');
            
            $updateSql = "UPDATE mining_records SET totalPoints = ?, lastSyncedAt = ?, updatedAt = NOW() WHERE uid = ? AND coinOwnerId = ?";
            $updateStmt = $pdo->prepare($updateSql);
            $updateStmt->execute([$totalPoints, $newSyncedAt, $uid, $coinOwnerId]);
            
            $pdo->commit();
            echo json_encode([
                'success' => true,
                'synced_points' => $inc,
                'total_points' => $totalPoints,
                'elapsed_seconds' => $elapsed
            ]);
            exit;
        }
    }

    $pdo->commit();
    echo json_encode(['success' => true, 'message' => 'No increment needed']);

} catch (PDOException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>