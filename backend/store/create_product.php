<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->user_id) && !empty($data->name) && !empty($data->price) && !empty($data->category)) {
    
    $category = strtolower($data->category);
    if ($category === 'accessories' || $category === 'toys' || $category === 'beds' || $category === 'accessory') {
        $db_category = 'accessory';
    } else if ($category === 'food') {
        $db_category = 'food';
    } else if ($category === 'medicine') {
        $db_category = 'medicine';
    } else {
        $db_category = 'accessory'; // default
    }

    $stock = isset($data->stock) ? (int)$data->stock : 0;

    $query = "INSERT INTO products (user_id, name, description, price, category, image, stock)
              VALUES (:user_id, :name, :description, :price, :category, :image, :stock)";
    $stmt = $conn->prepare($query);

    $stmt->bindParam(':user_id', $data->user_id);
    $stmt->bindParam(':name', $data->name);
    $stmt->bindParam(':description', $data->description);
    $stmt->bindParam(':price', $data->price);
    $stmt->bindParam(':category', $db_category);
    $stmt->bindParam(':image', $data->image);
    $stmt->bindParam(':stock', $stock);

    if($stmt->execute()) {
        sendResponse(true, "Product created successfully.");
    } else {
        sendResponse(false, "Failed to create product.");
    }
} else {
    sendResponse(false, "Incomplete data.");
}
?>
