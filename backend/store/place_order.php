<?php
include_once '../config.php';

header("Content-Type: application/json");

// Allow reading from raw JSON body or $_POST / $_REQUEST
$raw_input = file_get_contents("php://input");
$data = json_decode($raw_input, true);

if (!$data || !is_array($data)) {
    $data = $_POST;
}

$buyer_id = isset($data['buyer_id']) ? (int)$data['buyer_id'] : (isset($_REQUEST['buyer_id']) ? (int)$_REQUEST['buyer_id'] : 0);
$product_id = isset($data['product_id']) ? (int)$data['product_id'] : (isset($_REQUEST['product_id']) ? (int)$_REQUEST['product_id'] : 0);
$address = isset($data['address']) ? trim($data['address']) : (isset($_REQUEST['address']) ? trim($_REQUEST['address']) : '');
$phone = isset($data['phone']) ? trim($data['phone']) : (isset($_REQUEST['phone']) ? trim($_REQUEST['phone']) : '');
$quantity = isset($data['quantity']) ? (int)$data['quantity'] : (isset($_REQUEST['quantity']) ? (int)$_REQUEST['quantity'] : 1);

if ($buyer_id > 0 && $product_id > 0 && !empty($address)) {
    try {
        // Auto-create orders table if missing
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

        // Ensure quantity column exists in orders table
        try {
            $conn->query("SELECT quantity FROM orders LIMIT 1");
        } catch (Exception $e) {
            $conn->exec("ALTER TABLE orders ADD COLUMN quantity INT DEFAULT 1");
        }

        // Get product details (price and seller_id)
        $prod_query = "SELECT user_id, price, stock FROM products WHERE id = :pid";
        $p_stmt = $conn->prepare($prod_query);
        $p_stmt->bindParam(':pid', $product_id);
        $p_stmt->execute();
        $product = $p_stmt->fetch(PDO::FETCH_ASSOC);

        if($product) {
            $seller_id = $product['user_id'];
            if ($quantity <= 0) $quantity = 1;
            $total_price = $product['price'] * $quantity;

            $query = "INSERT INTO orders (buyer_id, seller_id, product_id, quantity, total_price, shipping_address, phone_number)
                      VALUES (:bid, :sid, :pid, :qty, :total, :addr, :phone)";

            $stmt = $conn->prepare($query);
            $stmt->execute([
                ':bid' => $buyer_id,
                ':sid' => $seller_id,
                ':pid' => $product_id,
                ':qty' => $quantity,
                ':total' => $total_price,
                ':addr' => $address,
                ':phone' => $phone
            ]);

            // Deduct product stock
            if (isset($product['stock']) && $product['stock'] > 0) {
                $new_stock = max(0, (int)$product['stock'] - $quantity);
                $stock_query = "UPDATE products SET stock = :stock WHERE id = :pid";
                $s_stmt = $conn->prepare($stock_query);
                $s_stmt->execute([':stock' => $new_stock, ':pid' => $product_id]);
            }

            // Notify Seller
            try {
                $notif_msg = "You received a new order for your product!";
                $notif_query = "INSERT INTO notifications (user_id, actor_id, type, message)
                                VALUES (:uid, :actor_id, 'rescue_alert', :msg)";
                $notif_stmt = $conn->prepare($notif_query);
                $notif_stmt->execute([':uid' => $seller_id, ':actor_id' => $buyer_id, ':msg' => $notif_msg]);
            } catch (Exception $ne) {
                // Ignore notification error
            }

            sendResponse(true, "Order placed successfully.");
        } else {
            sendResponse(false, "Product not found.");
        }
    } catch (PDOException $e) {
        sendResponse(false, "Database error: " . $e->getMessage());
    } catch (Exception $e) {
        sendResponse(false, "Error: " . $e->getMessage());
    }
} else {
    sendResponse(false, "Required data missing (buyer, product, or address).");
}
?>
