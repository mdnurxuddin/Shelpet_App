<?php
include_once '../config.php';

$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;

if($user_id > 0) {
    $query = "SELECT r.*, u.name as reviewer_name, u.avatar as reviewer_avatar
              FROM user_reviews r
              JOIN users u ON r.reviewer_id = u.id
              WHERE r.target_id = :user_id
              ORDER BY r.created_at DESC";
              
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':user_id', $user_id);
    $stmt->execute();
    $reviews = $stmt->fetchAll(PDO::FETCH_ASSOC);

    sendResponse(true, "Reviews retrieved.", $reviews);
} else {
    sendResponse(false, "Invalid User ID.");
}
?>
