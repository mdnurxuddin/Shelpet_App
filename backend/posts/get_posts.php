<?php
include_once '../config.php';

$type = isset($_GET['type']) ? $_GET['type'] : null;
$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 50;

$where = [];
if($type) {
    $where[] = "p.type = :type";
}

$query = "SELECT p.*, u.name as user_name, u.avatar as user_avatar, u.phone as user_phone,
          (SELECT COUNT(*) FROM reactions WHERE post_id = p.id) as likes_count,
          (SELECT COUNT(*) FROM comments WHERE post_id = p.id) as comments_count,
          (SELECT COUNT(*) FROM reactions WHERE post_id = p.id AND user_id = :user_id) as has_liked
          FROM posts p JOIN users u ON p.user_id = u.id";

if (count($where) > 0) {
    $query .= " WHERE " . implode(" AND ", $where);
}

$query .= " ORDER BY p.created_at DESC LIMIT :limit";

$stmt = $conn->prepare($query);
$stmt->bindValue(':user_id', $user_id, PDO::PARAM_INT);
if($type) {
    $stmt->bindValue(':type', $type, PDO::PARAM_STR);
}
$stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
$stmt->execute();

$posts = $stmt->fetchAll(PDO::FETCH_ASSOC);

sendResponse(true, "Posts fetched successfully.", $posts);
?>
