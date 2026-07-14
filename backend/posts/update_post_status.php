<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->post_id) && !empty($data->status)) {

    $proof_image = isset($data->proof_image) ? $data->proof_image : null;

    $query = "UPDATE posts SET status = :status, rescue_proof_image = :proof WHERE id = :id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':status', $data->status);
    $stmt->bindParam(':proof', $proof_image);
    $stmt->bindParam(':id', $data->post_id);

    if($stmt->execute()) {
        sendResponse(true, "Status updated successfully with proof.");
    } else {
        sendResponse(false, "Failed to update status.");
    }
} else {
    sendResponse(false, "Incomplete data.");
}
?>
