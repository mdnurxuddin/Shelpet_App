<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->buyer_id) && !empty($data->product_id) && !empty($data->address)) {
    // Get product details (price and seller_id)
    $prod_query = "SELECT user_id, price FROM products WHERE id = :pid";
    $p_stmt = $conn->prepare($prod_query);
    $p_stmt->bindParam(':pid', $data->product_id);
    $p_stmt->execute();
    $product = $p_stmt->fetch(PDO::FETCH_ASSOC);

    if($product) {
        $seller_id = $product['user_id'];
        $total_price = $product['price'] * ($data->quantity ?? 1);

        $query = "INSERT INTO orders (buyer_id, seller_id, product_id, quantity, total_price, shipping_address, phone_number)
                  VALUES (:bid, :sid, :pid, :qty, :total, :addr, :phone)";

        $stmt = $conn->prepare($query);
        $stmt->execute([
            ':bid' => $data->buyer_id,
            ':sid' => $seller_id,
            ':pid' => $data->product_id,
            ':qty' => $data->quantity ?? 1,
            ':total' => $total_price,
            ':addr' => $data->address,
            ':phone' => $data->phone
        ]);

        // Notify Seller
        $notif_msg = "You received a new order for your product!";
        $notif_query = "INSERT INTO notifications (user_id, actor_id, type, message)
                        VALUES (:uid, :actor_id, 'alert', :msg)";
        $notif_stmt = $conn->prepare($notif_query);
        $notif_stmt->execute([':uid' => $seller_id, ':actor_id' => $data->buyer_id, ':msg' => $notif_msg]);

        sendResponse(true, "Order placed successfully.");
    } else {
        sendResponse(false, "Product not found.");
    }
} else {
    sendResponse(false, "Required data missing.");
}
?>
