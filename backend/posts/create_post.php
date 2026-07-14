<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->user_id) && !empty($data->content) && !empty($data->type)) {
    $query = "INSERT INTO posts (user_id, content, image, type, location, price, pet_details)
              VALUES (:user_id, :content, :image, :type, :location, :price, :pet_details)";
    $stmt = $conn->prepare($query);

    $stmt->bindParam(':user_id', $data->user_id);
    $stmt->bindParam(':content', $data->content);
    $stmt->bindParam(':image', $data->image);
    $stmt->bindParam(':type', $data->type);
    $stmt->bindParam(':location', $data->location);
    $stmt->bindParam(':price', $data->price);
    $pet_details = isset($data->pet_details) ? json_encode($data->pet_details) : null;
    $stmt->bindParam(':pet_details', $pet_details);

    if($stmt->execute()) {
        $post_id = $conn->lastInsertId();
        
        if ($data->type === 'rescue') {
            $authorQuery = "SELECT name FROM users WHERE id = :user_id";
            $authorStmt = $conn->prepare($authorQuery);
            $authorStmt->bindParam(':user_id', $data->user_id);
            $authorStmt->execute();
            $authorName = $authorStmt->fetchColumn() ?: "Someone";

            $notifMsg = "$authorName posted an URGENT rescue request at " . ($data->location ?: "nearby location");

            $usersQuery = "SELECT id FROM users WHERE id != :user_id";
            $usersStmt = $conn->prepare($usersQuery);
            $usersStmt->bindParam(':user_id', $data->user_id);
            $usersStmt->execute();
            $otherUsers = $usersStmt->fetchAll(PDO::FETCH_COLUMN);

            if (!empty($otherUsers)) {
                $insertNotif = "INSERT INTO notifications (user_id, actor_id, post_id, type, message) 
                                VALUES (:target_user_id, :actor_id, :post_id, 'rescue_alert', :message)";
                $insertNotifStmt = $conn->prepare($insertNotif);
                foreach ($otherUsers as $targetUserId) {
                    $insertNotifStmt->execute([
                        ':target_user_id' => $targetUserId,
                        ':actor_id' => $data->user_id,
                        ':post_id' => $post_id,
                        ':message' => $notifMsg
                    ]);
                }
            }
        }
        
        sendResponse(true, "Post created successfully.");
    } else {
        sendResponse(false, "Failed to create post.");
    }
} else {
    sendResponse(false, "Incomplete data.");
}
?>
