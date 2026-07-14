<?php
include_once '../config.php';

$query_str = isset($_GET['q']) ? $_GET['q'] : '';

if (!empty($query_str)) {
    $search_term = "%$query_str%";
    $query = "SELECT id, name, email, avatar, user_category, verification_status, rating
              FROM users
              WHERE name LIKE :search OR user_category LIKE :search
              LIMIT 20";

    $stmt = $conn->prepare($query);
    $stmt->bindParam(':search', $search_term);
    $stmt->execute();

    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    sendResponse(true, "Users found.", $users);
} else {
    sendResponse(false, "Search query is empty.");
}
?>
