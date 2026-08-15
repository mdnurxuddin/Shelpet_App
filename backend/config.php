<?php
$host = "localhost";
$db_name = "stratixb_shelpet";
$username = "stratixb_user";
$password = "UC6xpI%ZSQ.N8^JL";

try {
    $conn = new PDO("mysql:host=$host;dbname=$db_name;charset=utf8mb4", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $conn->exec("SET NAMES utf8mb4");
} catch (PDOException $exception) {
    header("Content-Type: application/json");
    echo json_encode(["status" => false, "message" => "Database connection error: " . $exception->getMessage()]);
    exit();
}

if (isset($conn) && $conn) {
    try {
        $conn->query("SELECT address FROM users LIMIT 1");
    } catch (Exception $e) {
        try { $conn->exec("ALTER TABLE users ADD COLUMN address VARCHAR(255) DEFAULT NULL"); } catch (Exception $ex) {}
    }

    try {
        $conn->query("SELECT contact_number FROM posts LIMIT 1");
    } catch (Exception $e) {
        try { $conn->exec("ALTER TABLE posts ADD COLUMN contact_number VARCHAR(20) DEFAULT NULL"); } catch (Exception $ex) {}
    }

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

    try {
        $conn->exec("CREATE TABLE IF NOT EXISTS orders (
            id INT AUTO_INCREMENT PRIMARY KEY,
            buyer_id INT NOT NULL,
            seller_id INT NOT NULL,
            product_id INT NOT NULL,
            quantity INT DEFAULT 1,
            shipping_address TEXT NOT NULL,
            phone_number VARCHAR(20) NOT NULL,
            total_price DECIMAL(10,2) NOT NULL,
            status ENUM('pending', 'accepted', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )");
    } catch (Exception $e) {}

    try {
        $conn->query("SELECT quantity FROM orders LIMIT 1");
    } catch (Exception $e) {
        try { $conn->exec("ALTER TABLE orders ADD COLUMN quantity INT DEFAULT 1"); } catch (Exception $ex) {}
    }
}


try {
    $conn->exec("CREATE TABLE IF NOT EXISTS messages (
        id INT AUTO_INCREMENT PRIMARY KEY,
        sender_id INT NOT NULL,
        receiver_id INT NOT NULL,
        message TEXT NOT NULL,
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
    )");
} catch (Exception $e) {
}

function sendResponse($status, $message, $data = null)
{
    header("Content-Type: application/json");
    echo json_encode([
        "status" => $status,
        "message" => $message,
        "data" => $data
    ]);
    exit();
}
?>