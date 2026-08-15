<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->user_id) && !empty($data->content) && !empty($data->type)) {
    $contact_number = isset($data->contact_number) ? trim($data->contact_number) : null;

    $query = "INSERT INTO posts (user_id, content, image, type, location, price, pet_details, contact_number)
              VALUES (:user_id, :content, :image, :type, :location, :price, :pet_details, :contact_number)";
    $stmt = $conn->prepare($query);

    $stmt->bindParam(':user_id', $data->user_id);
    $stmt->bindParam(':content', $data->content);
    $stmt->bindParam(':image', $data->image);
    $stmt->bindParam(':type', $data->type);
    $stmt->bindParam(':location', $data->location);
    $stmt->bindParam(':price', $data->price);
    $pet_details = isset($data->pet_details) ? json_encode($data->pet_details) : null;
    $stmt->bindParam(':pet_details', $pet_details);
    $stmt->bindParam(':contact_number', $contact_number);

    if($stmt->execute()) {
        $post_id = $conn->lastInsertId();
        
        $authorQuery = "SELECT name, phone FROM users WHERE id = :user_id";
        $authorStmt = $conn->prepare($authorQuery);
        $authorStmt->bindParam(':user_id', $data->user_id);
        $authorStmt->execute();
        $authorRow = $authorStmt->fetch(PDO::FETCH_ASSOC);
        $authorName = $authorRow['name'] ?? "Someone";

        $notifMsg = null;
        $notifType = 'alert';

        if ($data->type === 'rescue') {
            $finalContact = !empty($contact_number) ? $contact_number : ($authorRow['phone'] ?? '');
            $contactInfo = !empty($finalContact) ? " (Call: $finalContact)" : "";
            $notifMsg = "$authorName posted an URGENT rescue request at " . ($data->location ?: "nearby location") . $contactInfo;
            $notifType = 'rescue_alert';
        } else if ($data->type === 'adoption' || $data->type === 'foster') {
            $notifMsg = "$authorName posted a new pet " . strtoupper($data->type) . " listing!";
            $notifType = 'post';
        }

        if (!empty($notifMsg)) {
            $usersQuery = "SELECT id FROM users WHERE id != :user_id";
            $usersStmt = $conn->prepare($usersQuery);
            $usersStmt->bindParam(':user_id', $data->user_id);
            $usersStmt->execute();
            $otherUsers = $usersStmt->fetchAll(PDO::FETCH_COLUMN);

            if (!empty($otherUsers)) {
                $insertNotif = "INSERT INTO notifications (user_id, actor_id, post_id, type, message) 
                                VALUES (:target_user_id, :actor_id, :post_id, :type, :message)";
                $insertNotifStmt = $conn->prepare($insertNotif);
                foreach ($otherUsers as $targetUserId) {
                    $insertNotifStmt->execute([
                        ':target_user_id' => $targetUserId,
                        ':actor_id' => $data->user_id,
                        ':post_id' => $post_id,
                        ':type' => $notifType,
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
