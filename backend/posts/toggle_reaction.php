<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->post_id) && !empty($data->user_id)) {
    $post_id = (int)$data->post_id;
    $user_id = (int)$data->user_id;

    $checkQuery = "SELECT id FROM reactions WHERE post_id = :post_id AND user_id = :user_id";
    $checkStmt = $conn->prepare($checkQuery);
    $checkStmt->bindParam(':post_id', $post_id);
    $checkStmt->bindParam(':user_id', $user_id);
    $checkStmt->execute();

    if ($checkStmt->rowCount() > 0) {
        $deleteQuery = "DELETE FROM reactions WHERE post_id = :post_id AND user_id = :user_id";
        $deleteStmt = $conn->prepare($deleteQuery);
        $deleteStmt->bindParam(':post_id', $post_id);
        $deleteStmt->bindParam(':user_id', $user_id);
        $deleteStmt->execute();
        sendResponse(true, "Reaction removed.", ["liked" => false]);
    } else {
        $insertQuery = "INSERT INTO reactions (post_id, user_id, type) VALUES (:post_id, :user_id, 'like')";
        $insertStmt = $conn->prepare($insertQuery);
        $insertStmt->bindParam(':post_id', $post_id);
        $insertStmt->bindParam(':user_id', $user_id);

        if ($insertStmt->execute()) {
            // --- Create Notification for Post Owner ---
            $postOwnerQuery = "SELECT user_id, content FROM posts WHERE id = :pid";
            $poStmt = $conn->prepare($postOwnerQuery);
            $poStmt->bindParam(':pid', $post_id);
            $poStmt->execute();
            $postData = $poStmt->fetch(PDO::FETCH_ASSOC);
            $target_user_id = (int)$postData['user_id'];

            $nameQuery = "SELECT name FROM users WHERE id = :uid";
            $nStmt = $conn->prepare($nameQuery);
            $nStmt->bindParam(':uid', $user_id);
            $nStmt->execute();
            $actor_name = $nStmt->fetchColumn() ?: "Someone";

            if ($target_user_id != $user_id) {
                $msg = "$actor_name liked your post.";
                $notif_query = "INSERT INTO notifications (user_id, actor_id, post_id, type, message)
                                VALUES (:target_uid, :actor_id, :pid, 'reaction', :msg)";
                $notif_stmt = $conn->prepare($notif_query);
                $notif_stmt->execute([
                    ':target_uid' => $target_user_id,
                    ':actor_id' => $user_id,
                    ':pid' => $post_id,
                    ':msg' => $msg
                ]);
            }
            // --- End Notification ---
            sendResponse(true, "Reaction added.", ["liked" => true]);
        } else {
            sendResponse(false, "Failed to add reaction.");
        }
    }
} else {
    sendResponse(false, "Incomplete parameters.");
}
?>
