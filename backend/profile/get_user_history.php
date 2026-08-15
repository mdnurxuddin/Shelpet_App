<?php
include_once '../config.php';

header("Content-Type: application/json");

$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;

if ($user_id > 0) {
    try {
        $stmt = $conn->prepare("
            SELECT p.*, u.name as user_name, u.phone as user_phone, u.avatar as user_avatar 
            FROM posts p 
            JOIN users u ON p.user_id = u.id 
            WHERE p.user_id = :uid AND p.status = 'done' 
            ORDER BY p.created_at DESC
        ");
        $stmt->bindParam(':uid', $user_id);
        $stmt->execute();
        $history = $stmt->fetchAll(PDO::FETCH_ASSOC);

        sendResponse(true, "User history retrieved.", $history);
    } catch (PDOException $e) {
        sendResponse(false, "Database error: " . $e->getMessage(), []);
    } catch (Exception $e) {
        sendResponse(false, "Error: " . $e->getMessage(), []);
    }
} else {
    sendResponse(false, "User ID missing or invalid.", []);
}
?>
