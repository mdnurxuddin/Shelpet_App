<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->product_id)) {
    $query = "DELETE FROM products WHERE id = :id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':id', $data->product_id);

    if($stmt->execute()) {
        sendResponse(true, "Product deleted successfully.");
    } else {
        sendResponse(false, "Failed to delete product.");
    }
} else {
    sendResponse(false, "Missing parameters.");
}
?>
