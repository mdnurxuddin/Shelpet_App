<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->user_id) && isset($data->avatar)) {
    $query = "UPDATE users SET avatar = :avatar WHERE id = :user_id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':avatar', $data->avatar);
    $stmt->bindParam(':user_id', $data->user_id);

    if($stmt->execute()) {
        sendResponse(true, "Avatar updated successfully.");
    } else {
        sendResponse(false, "Failed to update avatar.");
    }
} else {
    sendResponse(false, "Incomplete data.");
}
?>
