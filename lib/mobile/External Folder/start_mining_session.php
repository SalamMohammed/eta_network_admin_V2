<?php
require_once 'db.php';
header('Content-Type: application/json');

$data = json_decode(file_get_contents("php://input"), true);
$uid = $data['uid'] ?? '';
$coinOwnerId = $data['coinOwnerId'] ?? '';
$hourlyRate = $data['hourlyRate'] ?? 0.0;
// Expecting ISO 8601 strings or similar from Dart
$lastMiningStart = $data['lastMiningStart'] ?? ''; 
$lastMiningEnd = $data['lastMiningEnd'] ?? '';
$lastSyncedAt = $data['lastSyncedAt'] ?? '';

// Helper to convert ISO 8601 to MySQL DATETIME
function toMysqlDate($isoDate) {
    if (empty($isoDate)) return null;
    try {
        $dt = new DateTime($isoDate);
        return $dt->format('Y-m-d H:i:s');
    } catch (Exception $e) {
        return null;
    }
}

$mysqlStart = toMysqlDate($lastMiningStart);
$mysqlEnd = toMysqlDate($lastMiningEnd);
$mysqlSynced = toMysqlDate($lastSyncedAt);

if (empty($uid) || empty($coinOwnerId) || empty($mysqlStart) || empty($mysqlEnd)) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing required fields or invalid date format']);
    exit;
}

try {
    // 1. Fetch current record to calculate pending earnings from previous session
    $fetchSql = "SELECT * FROM mining_records WHERE uid = ? AND coinOwnerId = ?";
    $fetchStmt = $pdo->prepare($fetchSql);
    $fetchStmt->execute([$uid, $coinOwnerId]);
    $existing = $fetchStmt->fetch();

    $addedPoints = 0.0;
    
    if ($existing) {
        $oldStart = $existing['lastMiningStart'];
        $oldEnd = $existing['lastMiningEnd'];
        $oldRate = (float)$existing['hourlyRate'];
        $currentTotal = (float)$existing['totalPoints'];

        if ($oldStart && $oldEnd) {
            $now = new DateTime(); // Current server time
            $s = new DateTime($oldStart);
            $e = new DateTime($oldEnd);

            // Calculate overlap of [s, e] with [s, now]
            // effectively: min(now, e) - s
            $cutoff = ($now < $e) ? $now : $e;
            
            // If the session started in the past
            if ($cutoff > $s) {
                $seconds = $cutoff->getTimestamp() - $s->getTimestamp();
                if ($seconds > 0) {
                    $earned = ($seconds / 3600.0) * $oldRate;
                    $addedPoints = $earned;
                }
            }
        }
    }

    // 2. Insert or Update with NEW session data + ACCUMULATED points
    // If it's a new record, addedPoints is 0.
    // If existing, we add addedPoints to the existing totalPoints column
    
    $sql = "INSERT INTO mining_records 
            (uid, coinOwnerId, hourlyRate, lastMiningStart, lastMiningEnd, lastSyncedAt, updatedAt, totalPoints)
            VALUES (?, ?, ?, ?, ?, ?, NOW(), ?)
            ON DUPLICATE KEY UPDATE
            totalPoints = totalPoints + VALUES(totalPoints), -- Add the calculated earnings
            hourlyRate = VALUES(hourlyRate),
            lastMiningStart = VALUES(lastMiningStart),
            lastMiningEnd = VALUES(lastMiningEnd),
            lastSyncedAt = VALUES(lastSyncedAt),
            updatedAt = NOW()";

    // Pass addedPoints as the value for totalPoints in the INSERT/UPDATE
    // Note: On INSERT (first time), addedPoints is 0, so totalPoints starts at 0.
    // On UPDATE, we use `totalPoints = totalPoints + VALUES(totalPoints)` so we add the new chunk.
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        $uid, 
        $coinOwnerId, 
        $hourlyRate, 
        $mysqlStart, 
        $mysqlEnd, 
        $mysqlSynced,
        $addedPoints // This goes into the VALUES list for 'totalPoints'
    ]);
    
    // 3. Fetch the updated record to return to the app
    $fetchStmt->execute([$uid, $coinOwnerId]);
    $record = $fetchStmt->fetch();

    if ($record) {
         // Cast numeric types
         $record['totalPoints'] = (float)$record['totalPoints'];
         $record['hourlyRate'] = (float)$record['hourlyRate'];
         $record['added_chunk'] = $addedPoints; // Debug info
         echo json_encode($record);
    } else {
        echo json_encode(['success' => true]);
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>