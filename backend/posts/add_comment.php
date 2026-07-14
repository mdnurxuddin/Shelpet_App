<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->post_id) && !empty($data->user_id) && !empty($data->content)) {
    $post_id = (int)$data->post_id;
    $user_id = (int)$data->user_id;
    $content = trim($data->content);
    $parent_id = isset($data->parent_id) ? (int)$data->parent_id : null;

    $query = "INSERT INTO comments (post_id, user_id, content, parent_id) VALUES (:post_id, :user_id, :content, :parent_id)";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':post_id', $post_id);
    $stmt->bindParam(':user_id', $user_id);
    $stmt->bindParam(':content', $content);
    $stmt->bindParam(':parent_id', $parent_id);

    if($stmt->execute()) {
        // --- Create Notification for Post Owner ---
        // Get post owner ID
        $postOwnerQuery = "SELECT user_id, content FROM posts WHERE id = :pid";
        $poStmt = $conn->prepare($postOwnerQuery);
        $poStmt->bindParam(':pid', $post_id);
        $poStmt->execute();
        $postData = $poStmt->fetch(PDO::FETCH_ASSOC);
        $target_user_id = (int)$postData['user_id'];

        // Get commenter name
        $nameQuery = "SELECT name FROM users WHERE id = :uid";
        $nStmt = $conn->prepare($nameQuery);
        $nStmt->bindParam(':uid', $user_id);
        $nStmt->execute();
        $commenter_name = $nStmt->fetchColumn() ?: "Someone";

        if ($target_user_id != $user_id) {
            $msg = "$commenter_name commented on your post: " . (strlen($content) > 30 ? substr($content, 0, 30) . "..." : $content);
            $notif_query = "INSERT INTO notifications (user_id, actor_id, post_id, type, message)
                            VALUES (:target_uid, :actor_id, :pid, 'comment', :msg)";
            $notif_stmt = $conn->prepare($notif_query);
            $notif_stmt->execute([
                ':target_uid' => $target_user_id,
                ':actor_id' => $user_id,
                ':pid' => $post_id,
                ':msg' => $msg
            ]);
        }
        // --- End Notification ---

        sendResponse(true, "Comment added successfully.");
    } else {
        sendResponse(false, "Failed to add comment.");
    }
} else {
    sendResponse(false, "Incomplete parameters.");
}
?>
