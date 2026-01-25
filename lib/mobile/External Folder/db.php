<?php
$host = 'localhost';
$db   = 'jawayizc_eta_coins';
// IMPORTANT: cPanel database users usually have the format 'cpaneluser_dbuser'
// Example: 'jawayizc_salamya27' instead of just 'salamya27'
$user = 'jawayizc_salamya27'; 
$pass = '22fN&SG@w7wvqUMFt!8f'; 
$charset = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (\PDOException $e) {
    // Return JSON error so the app can handle it gracefully
    http_response_code(500);
    header('Content-Type: application/json');
    echo json_encode(['error' => 'Database connection failed: ' . $e->getMessage()]);
    exit;
}
?>