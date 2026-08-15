<?php
include_once '../config.php';

header("Content-Type: application/json");

try {
    // Auto-create products table if missing
    try {
        $conn->exec("CREATE TABLE IF NOT EXISTS products (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT,
            name VARCHAR(255) NOT NULL,
            description TEXT,
            price DECIMAL(10, 2) NOT NULL,
            category ENUM('food', 'accessory', 'medicine') NOT NULL,
            image VARCHAR(255),
            stock INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )");
    } catch (Exception $e) {}

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
} catch (PDOException $e) {
    sendResponse(false, "Database error: " . $e->getMessage(), []);
} catch (Exception $e) {
    sendResponse(false, "Error: " . $e->getMessage(), []);
}
?>
