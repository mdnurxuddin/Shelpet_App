<?php
include_once '../config.php';

$user_id = isset($_GET['user_id']) ? $_GET['user_id'] : null;
$other_id = isset($_GET['other_id']) ? $_GET['other_id'] : null;

if($user_id && $other_id) {
    // Mark messages from other_id to user_id as read
    $updateQuery = "UPDATE messages SET is_read = TRUE WHERE sender_id = :other_id AND receiver_id = :user_id";
    $updateStmt = $conn->prepare($updateQuery);
    $updateStmt->bindParam(':other_id', $other_id);
    $updateStmt->bindParam(':user_id', $user_id);
    $updateStmt->execute();

    $query = "SELECT * FROM messages 
              WHERE (sender_id = :user_id AND receiver_id = :other_id) 
                 OR (sender_id = :other_id AND receiver_id = :user_id)
              ORDER BY created_at ASC";
              
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':user_id', $user_id);
    $stmt->bindParam(':other_id', $other_id);
    $stmt->execute();
    
    $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);
    sendResponse(true, "Messages retrieved.", $messages);
} else {
    sendResponse(false, "Incomplete parameters.");
}
?>
