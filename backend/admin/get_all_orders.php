<?php
include_once '../config.php';

$query = "SELECT o.*, p.name as product_name, u.name as buyer_name, s.name as seller_name
          FROM orders o
          JOIN products p ON o.product_id = p.id
          JOIN users u ON o.buyer_id = u.id
          JOIN users s ON o.seller_id = s.id
          ORDER BY o.created_at DESC";

$stmt = $conn->prepare($query);
$stmt->execute();
$orders = $stmt->fetchAll(PDO::FETCH_ASSOC);

sendResponse(true, "Orders fetched.", $orders);
?>
