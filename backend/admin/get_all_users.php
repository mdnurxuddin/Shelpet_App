<?php
include_once '../config.php';

try {
    $query = "SELECT id, name, email, user_category, verification_status, role FROM users ORDER BY id DESC";
    $stmt = $conn->prepare($query);
    $stmt->execute();
    
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    sendResponse(true, "All users fetched.", $users);
} catch (Exception $e) {
    sendResponse(false, "Error: " . $e->getMessage());
}
?>
