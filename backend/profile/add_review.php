<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->reviewer_id) && !empty($data->target_id) && !empty($data->rating)) {

    // ১. রিভিউ ইনসার্ট করা
    $query = "INSERT INTO user_reviews (reviewer_id, target_id, rating, comment)
              VALUES (:reviewer_id, :target_id, :rating, :comment)";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':reviewer_id', $data->reviewer_id);
    $stmt->bindParam(':target_id', $data->target_id);
    $stmt->bindParam(':rating', $data->rating);
    $stmt->bindParam(':comment', $data->comment);

    if($stmt->execute()) {
        // ২. ইউজারের গড় রেটিং (Average Rating) আপডেট করা
        $update_query = "UPDATE users
                         SET rating = (SELECT AVG(rating) FROM user_reviews WHERE target_id = :tid)
                         WHERE id = :tid";
        $update_stmt = $conn->prepare($update_query);
        $update_stmt->bindParam(':tid', $data->target_id);
        $update_stmt->execute();

        sendResponse(true, "Review submitted successfully.");
    } else {
        sendResponse(false, "Failed to submit review.");
    }
} else {
    sendResponse(false, "Incomplete data.");
}
?>
