<?php
include_once '../config.php';

$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$unread_only = isset($_GET['unread_only']) ? $_GET['unread_only'] === 'true' : false;

if($user_id > 0) {
    $query = "SELECT n.*, u.name as actor_name, u.avatar as actor_avatar
              FROM notifications n
              JOIN users u ON n.actor_id = u.id
              WHERE n.user_id = :user_id";

    if($unread_only) {
        $query .= " AND n.is_read = 0";
    }

    $query .= " ORDER BY n.created_at DESC LIMIT 50";

    $stmt = $conn->prepare($query);
    $stmt->bindParam(':user_id', $user_id);
    $stmt->execute();

    $notifs = $stmt->fetchAll(PDO::FETCH_ASSOC);
    sendResponse(true, "Notifications fetched.", $notifs);
} else {
    sendResponse(false, "Invalid User ID.");
}
?>
