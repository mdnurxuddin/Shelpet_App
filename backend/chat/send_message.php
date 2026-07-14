<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->sender_id) && !empty($data->receiver_id) && !empty($data->message)) {
    $query = "INSERT INTO messages (sender_id, receiver_id, message) VALUES (:sender_id, :receiver_id, :message)";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':sender_id', $data->sender_id);
    $stmt->bindParam(':receiver_id', $data->receiver_id);
    $stmt->bindParam(':message', $data->message);

    if($stmt->execute()) {
        // Create a notification for the receiver
        $sender_query = "SELECT name FROM users WHERE id = :id";
        $sender_stmt = $conn->prepare($sender_query);
        $sender_stmt->bindParam(':id', $data->sender_id);
        $sender_stmt->execute();
        $sender_name = $sender_stmt->fetchColumn() ?: "Someone";

        $notif_msg = "New message from $sender_name: " . (strlen($data->message) > 30 ? substr($data->message, 0, 30) . "..." : $data->message);

        $notif_query = "INSERT INTO notifications (user_id, actor_id, type, message)
                        VALUES (:uid, :actor_id, 'message', :msg)";
        $notif_stmt = $conn->prepare($notif_query);
        $notif_stmt->bindParam(':uid', $data->receiver_id);
        $notif_stmt->bindParam(':actor_id', $data->sender_id);
        $notif_stmt->bindParam(':msg', $notif_msg);
        $notif_stmt->execute();

        sendResponse(true, "Message sent.");
    } else {
        sendResponse(false, "Failed to send message.");
    }
} else {
    sendResponse(false, "Incomplete data.");
}
?>
