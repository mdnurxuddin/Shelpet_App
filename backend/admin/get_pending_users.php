<?php
include_once '../config.php';

$query = "SELECT id, name, email, avatar, nid_number, nid_front_image, verification_status FROM users WHERE verification_status = 'pending'";
$stmt = $conn->prepare($query);
$stmt->execute();

$users = $stmt->fetchAll(PDO::FETCH_ASSOC);
sendResponse(true, "Pending users fetched.", $users);
?>
