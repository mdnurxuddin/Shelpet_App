<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->user_id) && !empty($data->other_id)) {
    $query = "UPDATE messages SET is_read = 1
              WHERE receiver_id = :user_id AND sender_id = :other_id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':user_id', $data->user_id);
    $stmt->bindParam(':other_id', $data->other_id);

    if($stmt->execute()) {
        sendResponse(true, "Messages marked as read.");
    } else {
        sendResponse(false, "Failed to mark read.");
    }
} else {
    sendResponse(false, "Missing data.");
}
?>
