<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->user_id)) {
    // Delete user (Cascade will handle posts, comments etc if setup in DB)
    $query = "DELETE FROM users WHERE id = :id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':id', $data->user_id);

    if($stmt->execute()) {
        sendResponse(true, "Account deleted successfully.");
    } else {
        sendResponse(false, "Failed to delete account.");
    }
} else {
    sendResponse(false, "User ID missing.");
}
?>
