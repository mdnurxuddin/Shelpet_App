<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->post_id) && !empty($data->status)) {

    $query = "UPDATE posts SET status = :status WHERE id = :id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':status', $data->status);
    $stmt->bindParam(':id', $data->post_id);

    if($stmt->execute()) {
        sendResponse(true, "Status updated successfully.");
    } else {
        sendResponse(false, "Failed to update status.");
    }
} else {
    sendResponse(false, "Incomplete data.");
}
?>
