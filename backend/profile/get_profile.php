<?php
include_once '../config.php';

$user_id = isset($_GET['user_id']) ? $_GET['user_id'] : null;

if($user_id) {
    $query = "SELECT id, name, email, avatar, user_category, verification_status, rating, role, address FROM users WHERE id = :id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':id', $user_id);
    $stmt->execute();

    if($stmt->rowCount() > 0) {
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        sendResponse(true, "Profile fetched.", $user);
    } else {
        sendResponse(false, "User not found.");
    }
} else {
    sendResponse(false, "User ID missing.");
}
?>
