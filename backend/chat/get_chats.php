<?php
include_once '../config.php';

$user_id = isset($_GET['user_id']) ? $_GET['user_id'] : null;

if($user_id) {
    $query = "SELECT 
                u.id, 
                u.name, 
                u.avatar,
                m.message as last_message,
                m.created_at as last_message_time,
                (SELECT COUNT(*) FROM messages WHERE sender_id = u.id AND receiver_id = :user_id AND is_read = 0) as unread_count
              FROM users u
              JOIN (
                  SELECT 
                      CASE 
                          WHEN sender_id = :user_id THEN receiver_id 
                          ELSE sender_id 
                      END as other_id,
                      MAX(id) as max_msg_id
                  FROM messages
                  WHERE sender_id = :user_id OR receiver_id = :user_id
                  GROUP BY other_id
              ) last_msg ON u.id = last_msg.other_id
              JOIN messages m ON last_msg.max_msg_id = m.id
              ORDER BY last_message_time DESC";
              
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':user_id', $user_id);
    $stmt->execute();
    
    $chats = $stmt->fetchAll(PDO::FETCH_ASSOC);
    sendResponse(true, "Chats retrieved.", $chats);
} else {
    sendResponse(false, "User ID missing.");
}
?>
