<?php
include_once '../config.php';

$category = isset($_GET['category']) ? strtolower($_GET['category']) : null;

$query = "SELECT p.*, u.name as user_name FROM products p JOIN users u ON p.user_id = u.id";
$has_filter = false;

if($category && $category !== 'all') {
    if ($category === 'accessories' || $category === 'toys' || $category === 'beds' || $category === 'accessory') {
        $db_category = 'accessory';
        $has_filter = true;
    } else if ($category === 'food') {
        $db_category = 'food';
        $has_filter = true;
    } else if ($category === 'medicine') {
        $db_category = 'medicine';
        $has_filter = true;
    }
}

if ($has_filter) {
    $query .= " WHERE p.category = :category";
}
$query .= " ORDER BY p.created_at DESC";

$stmt = $conn->prepare($query);
if ($has_filter) {
    $stmt->bindParam(':category', $db_category);
}
$stmt->execute();

$products = $stmt->fetchAll(PDO::FETCH_ASSOC);

sendResponse(true, "Products fetched successfully.", $products);
?>
