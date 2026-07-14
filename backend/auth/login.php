<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->email) && !empty($data->password)) {
    $query = "SELECT id, name, email, avatar, password, user_category, verification_status, rating, role, address FROM users WHERE email = :email";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':email', $data->email);
    $stmt->execute();

    if($stmt->rowCount() > 0) {
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        if($user && password_verify($data->password, $user['password'])) {
            unset($user['password']);
            sendResponse(true, "Login successful.", $user);
        } else if (!$user) {
            sendResponse(false, "Failed to retrieve user profile from database.");
        } else {
            sendResponse(false, "Invalid password.");
        }
    } else {
        sendResponse(false, "User not found.");
    }
} else {
    sendResponse(false, "Incomplete data.");
}
?>
