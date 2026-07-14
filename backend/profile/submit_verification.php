<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->user_id) && !empty($data->nid_number) && !empty($data->nid_image)) {

    $query = "UPDATE users SET
              nid_number = :nid,
              nid_front_image = :img,
              verification_status = 'pending'
              WHERE id = :uid";

    $stmt = $conn->prepare($query);
    $stmt->bindParam(':nid', $data->nid_number);
    $stmt->bindParam(':img', $data->nid_image);
    $stmt->bindParam(':uid', $data->user_id);

    if($stmt->execute()) {
        sendResponse(true, "Verification request submitted.");
    } else {
        sendResponse(false, "Failed to update database.");
    }
} else {
    sendResponse(false, "Required data missing (User ID, NID, or Image).");
}
?>
