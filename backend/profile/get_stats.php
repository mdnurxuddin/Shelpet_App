<?php
include_once '../config.php';

$user_id = isset($_GET['user_id']) ? $_GET['user_id'] : null;

if($user_id) {
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

    // 3. Total Reviews Received
    $reviewsStmt = $conn->prepare("SELECT COUNT(*) as cnt FROM user_reviews WHERE target_id = :user_id");
    $reviewsStmt->bindParam(':user_id', $user_id);
    $reviewsStmt->execute();
    $reviewsCount = $reviewsStmt->fetch(PDO::FETCH_ASSOC)['cnt'];

    sendResponse(true, "Stats retrieved.", [
        "posts" => (int)$postsCount,
        "adoptions" => (int)$adoptionCount,
        "reviews" => (int)$reviewsCount
    ]);
} else {
    sendResponse(false, "User ID missing.");
}
?>
