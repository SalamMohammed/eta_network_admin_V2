<?php
require_once 'db.php';
header('Content-Type: application/json');

$uid = $_GET['uid'] ?? '';

if (empty($uid)) {
    echo json_encode([]);
    exit;
}

try {
    // Join mining_records with user_coins to get full coin details AND mining progress
    $sql = "SELECT 
                uc.*, 
                mr.totalPoints, 
                mr.hourlyRate, 
                mr.lastMiningStart, 
                mr.lastMiningEnd, 
                mr.lastSyncedAt
            FROM mining_records mr
            JOIN user_coins uc ON mr.coinOwnerId = uc.ownerId
            WHERE mr.uid = ?";
            
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$uid]);
    
    $rows = $stmt->fetchAll();

    // LAZY SYNC LOGIC:
    // Check if any session has finished but points haven't been added yet.
    // If so, calculate and update DB immediately before returning data.
    // This mimics the Firestore "sync on load" behavior without needing a Cron Job.
    
    $now = new DateTime();
    $updatesMade = false;

    foreach ($rows as &$row) {
        // Convert numeric types first
        $row['isActive'] = (bool)$row['isActive'];
        $row['totalPoints'] = (float)$row['totalPoints'];
        $row['baseRatePerHour'] = (float)$row['baseRatePerHour'];
        $row['hourlyRate'] = (float)$row['hourlyRate'];
        $row['minersCount'] = (int)$row['minersCount'];

        if (isset($row['socialLinks']) && is_string($row['socialLinks'])) {
            $row['socialLinks'] = json_decode($row['socialLinks'], true);
        }

        // Check for pending rewards
        if (!empty($row['lastMiningEnd'])) {
            $end = new DateTime($row['lastMiningEnd']);
            
            // Only process if the session has actually ended
            if ($now >= $end) {
                $startCalc = new DateTime($row['lastMiningStart']);
                if (!empty($row['lastSyncedAt'])) {
                    $synced = new DateTime($row['lastSyncedAt']);
                    if ($synced > $startCalc) {
                        $startCalc = $synced;
                    }
                }

                // If we haven't paid out up to the end time yet
                if ($end > $startCalc) {
                    $seconds = $end->getTimestamp() - $startCalc->getTimestamp();
                    if ($seconds > 0) {
                        // FIX: Use the 'hourlyRate' stored in the mining record (mr.hourlyRate)
                        // This rate was locked in when the session STARTED.
                        // We do NOT use user_coins.baseRatePerHour because the owner might have changed it mid-session.
                        $rateToUse = (float)$row['hourlyRate'];
                        
                        // Fallback: If for some reason the stored rate is 0, use the current coin base rate
                        if ($rateToUse <= 0) {
                            $rateToUse = (float)$row['baseRatePerHour'];
                        }

                        $earned = ($seconds / 3600.0) * $rateToUse;
                        
                        // Update DB
                        // Use COALESCE to handle NULL totalPoints
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
                            $row['ownerId'] // 'ownerId' comes from user_coins joined table
                        ]);

                        // Update local row data so the user sees the new balance immediately
                        $row['totalPoints'] += $earned;
                        $row['lastSyncedAt'] = $end->format('Y-m-d H:i:s');
                        $updatesMade = true;
                    }
                }
            }
        }
    }
    
    echo json_encode($rows);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>