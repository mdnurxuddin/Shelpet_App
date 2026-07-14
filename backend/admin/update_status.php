<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->user_id) && !empty($data->status)) {
    $query = "UPDATE users SET verification_status = :status WHERE id = :user_id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':status', $data->status);
    $stmt->bindParam(':user_id', $data->user_id);

    if($stmt->execute()) {
        sendResponse(true, "User status updated to " . $data->status);
    } else {
        sendResponse(false, "Failed to update status.");
    }
} else {
    sendResponse(false, "Incomplete data.");
}
?>
