<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->product_id) && isset($data->stock)) {
    $query = "UPDATE products SET stock = :stock WHERE id = :id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':stock', $data->stock);
    $stmt->bindParam(':id', $data->product_id);

    if($stmt->execute()) {
        sendResponse(true, "Product stock updated successfully.");
    } else {
        sendResponse(false, "Failed to update stock.");
    }
} else {
    sendResponse(false, "Missing parameters.");
}
?>
