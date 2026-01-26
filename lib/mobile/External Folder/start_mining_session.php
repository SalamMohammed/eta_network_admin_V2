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
        // Ensure we are working with the server's timezone for storage
        $dt->setTimezone(new DateTimeZone(date_default_timezone_get()));
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
        $lastSynced = $existing['lastSyncedAt'];
        // Use the stored hourlyRate for the session being closed to ensure accuracy.
        // Fallback to passed hourlyRate if stored is invalid.
        $oldRate = ((float)$existing['hourlyRate'] > 0) ? (float)$existing['hourlyRate'] : (float)$hourlyRate;
        $currentTotal = (float)$existing['totalPoints'];

        if ($oldStart && $oldEnd) {
            $now = new DateTime(); // Current server time
            $s = new DateTime($oldStart);
            $e = new DateTime($oldEnd);

            // If we have a sync record, use that as the starting point 
            // to avoid double-counting points that were already synced.
            if ($lastSynced) {
                $ls = new DateTime($lastSynced);
                if ($ls > $s) {
                    $s = $ls;
                }
            }

            // STRICT COMPLETION CHECK:
            // User request: "I want the mined points to be added... not with the mined start but when mining ends."
            // Points are awarded only if the session has completed (now >= end).
            // ADDED TOLERANCE: Allow 60 seconds of clock skew/latency.
            // If the user restarts 1 second "early" according to server time, we still count it.
            $tolerance = new DateInterval('PT60S');
            $e_with_tolerance = clone $e;
            $e_with_tolerance->sub($tolerance);

            if ($now >= $e_with_tolerance) {
                 // Calculate full duration from start (or last sync) to scheduled end
                 $seconds = $e->getTimestamp() - $s->getTimestamp();
                 if ($seconds > 0) {
                     $earned = ($seconds / 3600.0) * $oldRate;
                     $addedPoints = $earned;
                 }
            } else {
                // Session restarted early. 
                // No points awarded for incomplete session.
                $addedPoints = 0;
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
            totalPoints = COALESCE(totalPoints, 0) + VALUES(totalPoints), -- Add the calculated earnings
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