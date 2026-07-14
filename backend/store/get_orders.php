<?php
include_once '../config.php';

$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$role = isset($_GET['role']) ? $_GET['role'] : 'buyer'; // 'buyer' or 'seller'

if($user_id > 0) {
    if ($role == 'seller') {
        $query = "SELECT o.*, p.name as product_name, p.image as product_image, u.name as buyer_name
                  FROM orders o
                  JOIN products p ON o.product_id = p.id
                  JOIN users u ON o.buyer_id = u.id
                  WHERE o.seller_id = :uid
                  ORDER BY o.created_at DESC";
    } else {
        $query = "SELECT o.*, p.name as product_name, p.image as product_image, u.name as seller_name
                  FROM orders o
                  JOIN products p ON o.product_id = p.id
                  JOIN users u ON o.seller_id = u.id
                  WHERE o.buyer_id = :uid
                  ORDER BY o.created_at DESC";
    }

    $stmt = $conn->prepare($query);
    $stmt->bindParam(':uid', $user_id);
    $stmt->execute();
    $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);
    sendResponse(true, "Orders fetched.", $orders);
} else {
    sendResponse(false, "Invalid data.");
}
?>
