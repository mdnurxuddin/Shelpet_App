<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->user_id) && !empty($data->phone)) {
    $phone = trim($data->phone);
    $query = "UPDATE users SET phone = :phone WHERE id = :id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':phone', $phone);
    $stmt->bindParam(':id', $data->user_id);

    if($stmt->execute()) {
        $fetch = $conn->prepare("SELECT id, name, email, phone, avatar, user_category, verification_status, rating, role, address FROM users WHERE id = :id");
        $fetch->bindParam(':id', $data->user_id);
        $fetch->execute();
        $user = $fetch->fetch(PDO::FETCH_ASSOC);

        sendResponse(true, "Phone number updated successfully.", $user);
    } else {
        sendResponse(false, "Failed to update phone number.");
    }
} else {
    sendResponse(false, "Phone number cannot be empty.");
}
?>
