<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->admin_id) && !empty($data->target_user_id)) {
    // Check if requester is admin
    $adminCheck = $conn->prepare("SELECT role FROM users WHERE id = :admin_id");
    $adminCheck->bindParam(':admin_id', $data->admin_id);
    $adminCheck->execute();
    $admin = $adminCheck->fetch(PDO::FETCH_ASSOC);

    if ($admin && $admin['role'] === 'admin') {
        // Prevent deleting own self
        if ($data->admin_id == $data->target_user_id) {
            sendResponse(false, "You cannot delete your own admin account.");
        }

        $query = "DELETE FROM users WHERE id = :target_user_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':target_user_id', $data->target_user_id);

        if($stmt->execute()) {
            sendResponse(true, "User account deleted successfully.");
        } else {
            sendResponse(false, "Failed to delete user account.");
        }
    } else {
        sendResponse(false, "Unauthorized request.");
    }
} else {
    sendResponse(false, "Incomplete data.");
}
?>
