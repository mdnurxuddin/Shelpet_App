<?php
include_once '../config.php';

header("Content-Type: application/json");

$user_id = isset($_GET['user_id']) ? $_GET['user_id'] : null;

if($user_id) {
    try {
        // 1. Total Posts by User
        $postsStmt = $conn->prepare("SELECT COUNT(*) as cnt FROM posts WHERE user_id = :user_id");
        $postsStmt->bindParam(':user_id', $user_id);
        $postsStmt->execute();
        $postsCount = $postsStmt->fetch(PDO::FETCH_ASSOC)['cnt'];

        // 2. Successful Adoptions (Adoption posts marked as 'done')
        $adoptionStmt = $conn->prepare("SELECT COUNT(*) as cnt FROM posts WHERE user_id = :user_id AND type = 'adoption' AND status = 'done'");
        $adoptionStmt->bindParam(':user_id', $user_id);
        $adoptionStmt->execute();
        $adoptionCount = $adoptionStmt->fetch(PDO::FETCH_ASSOC)['cnt'];

        // 3. Successful Rescues (Rescue posts marked as 'done')
        $rescueStmt = $conn->prepare("SELECT COUNT(*) as cnt FROM posts WHERE user_id = :user_id AND type = 'rescue' AND status = 'done'");
        $rescueStmt->bindParam(':user_id', $user_id);
        $rescueStmt->execute();
        $rescueCount = $rescueStmt->fetch(PDO::FETCH_ASSOC)['cnt'];

        // 4. Successful Fosters (Fostering posts marked as 'done')
        $fosterStmt = $conn->prepare("SELECT COUNT(*) as cnt FROM posts WHERE user_id = :user_id AND type = 'fostering' AND status = 'done'");
        $fosterStmt->bindParam(':user_id', $user_id);
        $fosterStmt->execute();
        $fosterCount = $fosterStmt->fetch(PDO::FETCH_ASSOC)['cnt'];

        // 5. Total Reviews Received
        $reviewsStmt = $conn->prepare("SELECT COUNT(*) as cnt FROM user_reviews WHERE target_id = :user_id");
        $reviewsStmt->bindParam(':user_id', $user_id);
        $reviewsStmt->execute();
        $reviewsCount = $reviewsStmt->fetch(PDO::FETCH_ASSOC)['cnt'];

        sendResponse(true, "Stats retrieved.", [
            "posts" => (int)$postsCount,
            "adoptions" => (int)$adoptionCount,
            "rescues" => (int)$rescueCount,
            "fosters" => (int)$fosterCount,
            "reviews" => (int)$reviewsCount
        ]);
    } catch (PDOException $e) {
        sendResponse(false, "Database error: " . $e->getMessage());
    } catch (Exception $e) {
        sendResponse(false, "Error: " . $e->getMessage());
    }
} else {
    sendResponse(false, "User ID missing.");
}
?>
