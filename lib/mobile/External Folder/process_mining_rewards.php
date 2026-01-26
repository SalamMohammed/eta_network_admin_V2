<?php
require_once 'db.php';
header('Content-Type: application/json');

// This script is intended to be run by a Cron Job (e.g., every 1 or 5 minutes).
// It finds mining sessions that have ended but haven't been fully synced/paid out yet.

try {
    // 1. Select records where:
    // - The session has ended (lastMiningEnd <= NOW())
    // - We haven't synced up to the end time yet (lastSyncedAt < lastMiningEnd)
    // - Use FOR UPDATE to lock these rows and prevent race conditions with start_mining_session.php
    
    // Note: We process in batches to avoid timeouts if there are many records
    $limit = 100; 
    
    $pdo->beginTransaction();

    $sql = "SELECT uid, coinOwnerId, hourlyRate, lastMiningStart, lastMiningEnd, lastSyncedAt, totalPoints 
            FROM mining_records 
            WHERE lastMiningEnd <= NOW() 
              AND (lastSyncedAt IS NULL OR lastSyncedAt < lastMiningEnd)
            LIMIT $limit 
            FOR UPDATE";
            
    $stmt = $pdo->query($sql);
    $records = $stmt->fetchAll();

    $count = 0;
    $updatedRecords = [];

    foreach ($records as $row) {
        $uid = $row['uid'];
        $coinOwnerId = $row['coinOwnerId'];
        $rate = (float)$row['hourlyRate'];
        $end = new DateTime($row['lastMiningEnd']);
        
        // Determine start point for this calculation chunk
        $startCalc = new DateTime($row['lastMiningStart']);
        if (!empty($row['lastSyncedAt'])) {
            $synced = new DateTime($row['lastSyncedAt']);
            if ($synced > $startCalc) {
                $startCalc = $synced;
            }
        }

        // Calculate duration to pay out
        // Since we filtered by lastMiningEnd <= NOW(), we know the session is fully done.
        // We pay from $startCalc to $end.
        
        if ($end > $startCalc) {
            $seconds = $end->getTimestamp() - $startCalc->getTimestamp();
            
            if ($seconds > 0) {
                $earned = ($seconds / 3600.0) * $rate;
                
                // Update the record
                // Set lastSyncedAt = lastMiningEnd so we don't pay this again
                // Use COALESCE for safety
                $updateSql = "UPDATE mining_records 
                              SET totalPoints = COALESCE(totalPoints, 0) + ?, 
                                  lastSyncedAt = GREATEST(COALESCE(lastSyncedAt, '1970-01-01 00:00:00'), ?), 
                                  updatedAt = NOW() 
                              WHERE uid = ? AND coinOwnerId = ?";
                              
                $updateStmt = $pdo->prepare($updateSql);
                $updateStmt->execute([
                    $earned, 
                    $end->format('Y-m-d H:i:s'), 
                    $uid, 
                    $coinOwnerId
                ]);
                
                $count++;
                $updatedRecords[] = [
                    'uid' => $uid,
                    'coin' => $coinOwnerId,
                    'earned' => $earned
                ];
            }
        } else {
            // Edge case: synced time >= end time (should be filtered out by query, but just in case)
            // We just update lastSyncedAt to match lastMiningEnd to ensure consistency if needed
            // But query says lastSyncedAt < lastMiningEnd, so this block might be unreachable.
        }
    }

    $pdo->commit();

    echo json_encode([
        'success' => true, 
        'processed_count' => $count,
        'details' => $updatedRecords
    ]);

} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>