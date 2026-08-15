<?php
include_once '../config.php';

$raw = file_get_contents("php://input");
$data = json_decode($raw, true);

$post_id = 0;
$status = '';

if (is_array($data)) {
    if (isset($data['post_id'])) $post_id = (int)$data['post_id'];
    if (isset($data['status'])) $status = trim($data['status']);
}

if ($post_id == 0 && isset($_POST['post_id'])) {
    $post_id = (int)$_POST['post_id'];
}
if (empty($status) && isset($_POST['status'])) {
    $status = trim($_POST['status']);
}

if ($post_id == 0 && isset($_GET['post_id'])) {
    $post_id = (int)$_GET['post_id'];
}
if (empty($status) && isset($_GET['status'])) {
    $status = trim($_GET['status']);
}

if ($post_id > 0 && !empty($status)) {
    $query = "UPDATE posts SET status = :status WHERE id = :id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':status', $status);
    $stmt->bindParam(':id', $post_id);

    if ($stmt->execute()) {
        sendResponse(true, "Status updated successfully.", ["post_id" => $post_id, "status" => $status]);
    } else {
        sendResponse(false, "Failed to update status.");
    }
} else {
    sendResponse(false, "Incomplete data. post_id: $post_id, status: $status");
}
?>
