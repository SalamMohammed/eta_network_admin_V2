<?php
require_once 'db.php';
header('Content-Type: application/json');

// Get JSON input
$data = json_decode(file_get_contents("php://input"), true);

// Extract fields
$uid = $data['uid'] ?? '';
$coinOwnerId = $data['coinOwnerId'] ?? '';
// The amount calculated by the App (Client-side)
$amount = isset($data['amount']) ? (float)$data['amount'] : 0.0;
// The timestamp up to which the app calculated points
$syncedAt = $data['lastSyncedAt'] ?? ''; 

if (empty($uid) || empty($coinOwnerId)) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing uid or coinOwnerId']);
    exit;
}

// Convert ISO date to MySQL format
$mysqlSyncedAt = date('Y-m-d H:i:s'); // Default to NOW if not provided
if (!empty($syncedAt)) {
    try {
        $dt = new DateTime($syncedAt);
        $dt->setTimezone(new DateTimeZone(date_default_timezone_get()));
        $mysqlSyncedAt = $dt->format('Y-m-d H:i:s');
    } catch (Exception $e) {
        // Keep default NOW if parsing fails
    }
}

try {
    // Update mining_records
    // We increment totalPoints by the amount sent by the app
    // We update lastSyncedAt ONLY if the new date is newer than what's in DB to prevent regression
    $sql = "UPDATE mining_records 
            SET totalPoints = COALESCE(totalPoints, 0) + ?,
                lastSyncedAt = GREATEST(COALESCE(lastSyncedAt, '1970-01-01 00:00:00'), ?),
                updatedAt = NOW()
            WHERE uid = ? AND coinOwnerId = ?";
            
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$amount, $mysqlSyncedAt, $uid, $coinOwnerId]);

    if ($stmt->rowCount() > 0) {
        echo json_encode([
            'success' => true, 
            'message' => 'Points synced successfully',
            'added' => $amount,
            'newSyncedAt' => $mysqlSyncedAt
        ]);
    } else {
        // If no rows updated, maybe the record doesn't exist?
        $checkSql = "SELECT 1 FROM mining_records WHERE uid = ? AND coinOwnerId = ?";
        $checkStmt = $pdo->prepare($checkSql);
        $checkStmt->execute([$uid, $coinOwnerId]);
        
        if ($checkStmt->fetch()) {
             // Record exists but maybe values didn't change (e.g. amount=0 and syncedAt same)
             echo json_encode(['success' => true, 'message' => 'No changes made']);
        } else {
             http_response_code(404);
             echo json_encode(['error' => 'Mining record not found']);
        }
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
}
?>