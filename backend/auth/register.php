<?php
include_once '../config.php';

// Inputs
$data = json_decode(file_get_contents("php://input"));

if(!empty($data->name) && !empty($data->email) && !empty($data->password) && !empty($data->user_category)) {

    $email = trim($data->email); // ফালতু স্পেস রিমুভ করবে

    // ইমেইল চেক
    $check = $conn->prepare("SELECT id FROM users WHERE email = :email");
    $check->bindParam(':email', $email);
    $check->execute();

    if($check->rowCount() > 0) {
        sendResponse(false, "This email ($email) is already in our system. Please use another.");
    }

    // নতুন ইউজার ইনসার্ট
    $query = "INSERT INTO users (name, email, password, nid_number, user_category, verification_status, rating, address)
              VALUES (:name, :email, :password, :nid, :category, 'pending', 0.0, :address)";
    $stmt = $conn->prepare($query);

    $password_hash = password_hash($data->password, PASSWORD_BCRYPT);
    $nid = !empty($data->nid) ? $data->nid : null;
    $address = !empty($data->address) ? $data->address : null;

    $stmt->bindParam(':name', $data->name);
    $stmt->bindParam(':email', $email);
    $stmt->bindParam(':password', $password_hash);
    $stmt->bindParam(':nid', $nid);
    $stmt->bindParam(':category', $data->user_category);
    $stmt->bindParam(':address', $address);

    if($stmt->execute()) {
        $user_id = (int)$conn->lastInsertId();
        
        $user = [
            "id" => $user_id,
            "name" => $data->name,
            "email" => $email,
            "avatar" => null,
            "user_category" => $data->user_category,
            "verification_status" => "pending",
            "rating" => 0.0,
            "role" => "user",
            "address" => $address
        ];

        sendResponse(true, "Registration successful.", $user);
    } else {
        sendResponse(false, "System error during registration.");
    }
} else {
    sendResponse(false, "Please fill all required fields.");
}
?>
