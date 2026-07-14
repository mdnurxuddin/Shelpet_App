<?php
include_once '../config.php';

$type = isset($_GET['type']) ? $_GET['type'] : null;
$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;

$query = "SELECT p.*, u.name as user_name, u.avatar as user_avatar,
          (SELECT COUNT(*) FROM reactions WHERE post_id = p.id) as likes_count,
          (SELECT COUNT(*) FROM comments WHERE post_id = p.id) as comments_count,
          (SELECT COUNT(*) FROM reactions WHERE post_id = p.id AND user_id = :user_id) as has_liked
          FROM posts p JOIN users u ON p.user_id = u.id";
          
if($type) {
    $query .= " WHERE p.type = :type";
}
$query .= " ORDER BY p.created_at DESC";

$stmt = $conn->prepare($query);
$stmt->bindParam(':user_id', $user_id);
if($type) {
    $stmt->bindParam(':type', $type);
}
$stmt->execute();

$posts = $stmt->fetchAll(PDO::FETCH_ASSOC);

sendResponse(true, "Posts fetched successfully.", $posts);
?>
