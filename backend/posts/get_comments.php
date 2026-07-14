<?php
include_once '../config.php';

$post_id = isset($_GET['post_id']) ? (int)$_GET['post_id'] : 0;

if($post_id) {
    $query = "SELECT c.*, u.name as user_name, u.avatar as user_avatar 
              FROM comments c 
              JOIN users u ON c.user_id = u.id 
              WHERE c.post_id = :post_id 
              ORDER BY c.created_at ASC";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':post_id', $post_id);
    $stmt->execute();
    $comments = $stmt->fetchAll(PDO::FETCH_ASSOC);
    sendResponse(true, "Comments fetched successfully.", $comments);
} else {
    sendResponse(false, "Post ID missing.");
}
?>
