<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->order_id) && !empty($data->status)) {
    $query = "UPDATE orders SET status = :status WHERE id = :id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':status', $data->status);
    $stmt->bindParam(':id', $data->order_id);

    if($stmt->execute()) {
        // Notify Buyer about status update
        $order_query = "SELECT buyer_id, seller_id FROM orders WHERE id = :id";
        $o_stmt = $conn->prepare($order_query);
        $o_stmt->execute([':id' => $data->order_id]);
        $order = $o_stmt->fetch(PDO::FETCH_ASSOC);

        $msg = "Your order status has been updated to: " . strtoupper($data->status);
        $notif = "INSERT INTO notifications (user_id, actor_id, type, message) VALUES (:uid, :aid, 'alert', :msg)";
        $n_stmt = $conn->prepare($notif);
        $n_stmt->execute([':uid' => $order['buyer_id'], ':aid' => $order['seller_id'], ':msg' => $msg]);

        sendResponse(true, "Order status updated.");
    } else {
        sendResponse(false, "Failed to update status.");
    }
} else {
    sendResponse(false, "Missing parameters.");
}
?>
