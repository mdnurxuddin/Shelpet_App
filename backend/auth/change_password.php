<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->user_id) && !empty($data->current_password) && !empty($data->new_password)) {
    // 1. Verify current password
    $query = "SELECT password FROM users WHERE id = :id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':id', $data->user_id);
    $stmt->execute();

    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if($user && password_verify($data->current_password, $user['password'])) {
        // 2. Update to new password
        $new_hash = password_hash($data->new_password, PASSWORD_BCRYPT);
        $update = "UPDATE users SET password = :pass WHERE id = :id";
        $up_stmt = $conn->prepare($update);
        $up_stmt->bindParam(':pass', $new_hash);
        $up_stmt->bindParam(':id', $data->user_id);

        if($up_stmt->execute()) {
            sendResponse(true, "Password changed successfully.");
        } else {
            sendResponse(false, "Failed to update password.");
        }
    } else {
        sendResponse(false, "Current password is incorrect.");
    }
} else {
    sendResponse(false, "Incomplete data.");
}
?>
