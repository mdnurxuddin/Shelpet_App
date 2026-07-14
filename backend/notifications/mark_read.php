<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->id)) {
    $query = "UPDATE notifications SET is_read = 1 WHERE id = :id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':id', $data->id);

    if($stmt->execute()) {
        sendResponse(true, "Marked as read.");
    } else {
        sendResponse(false, "Failed to mark read.");
    }
} else {
    sendResponse(false, "ID missing.");
}
?>
