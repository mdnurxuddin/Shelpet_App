<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->post_id) && !empty($data->user_id)) {
    // Check user role
    $userQuery = "SELECT role FROM users WHERE id = :user_id";
    $userStmt = $conn->prepare($userQuery);
    $userStmt->bindParam(':user_id', $data->user_id);
    $userStmt->execute();
    $user = $userStmt->fetch(PDO::FETCH_ASSOC);

    if ($user && $user['role'] === 'admin') {
        // Admin can delete any post
        $query = "DELETE FROM posts WHERE id = :post_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':post_id', $data->post_id);
    } else {
        // Normal user can only delete their own post
        $query = "DELETE FROM posts WHERE id = :post_id AND user_id = :user_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':post_id', $data->post_id);
        $stmt->bindParam(':user_id', $data->user_id);
    }

    if($stmt->execute()) {
        if($stmt->rowCount() > 0) {
            sendResponse(true, "Post deleted successfully.");
        } else {
            sendResponse(false, "Post not found or you are not authorized to delete it.");
        }
    } else {
        sendResponse(false, "Failed to delete post.");
    }
} else {
    sendResponse(false, "Incomplete data.");
}
?>
