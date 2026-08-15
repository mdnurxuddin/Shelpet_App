<?php
include_once '../config.php';

// Inputs
$data = json_decode(file_get_contents("php://input"));

if(!empty($data->name) && !empty($data->email) && !empty($data->password) && !empty($data->phone) && !empty($data->user_category)) {

    $email = trim($data->email);
    $phone = trim($data->phone);
    $password = $data->password;

    // Strong Password Validation
    // At least 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special character
    $uppercase = preg_match('@[A-Z]@', $password);
    $lowercase = preg_match('@[a-z]@', $password);
    $number    = preg_match('@[0-9]@', $password);
    $specialChars = preg_match('@[^\w]@', $password);

    if(!$uppercase || !$lowercase || !$number || !$specialChars || strlen($password) < 8) {
        sendResponse(false, "Password must be at least 8 characters long and contain uppercase, lowercase, number, and special character.");
    }

    // Email duplication check
    $check = $conn->prepare("SELECT id, is_email_verified FROM users WHERE email = :email");
    $check->bindParam(':email', $email);
    $check->execute();

    if($check->rowCount() > 0) {
        $existing = $check->fetch(PDO::FETCH_ASSOC);
        if ($existing['is_email_verified'] == 1) {
            sendResponse(false, "This email ($email) is already registered and verified. Please login.");
        } else {
            // Delete old unverified account to allow re-registration
            $del = $conn->prepare("DELETE FROM users WHERE id = :id");
            $del->bindParam(':id', $existing['id']);
            $del->execute();
        }
    }

    // Generate 6-Digit OTP
    $otp = sprintf("%06d", mt_rand(100000, 999999));
    $otp_expires_at = date('Y-m-d H:i:s', strtotime('+10 minutes'));

    // Insert new user directly as verified email (NID verification handles identity)
    $query = "INSERT INTO users (name, email, password, phone, is_email_verified, nid_number, user_category, verification_status, rating, address)
              VALUES (:name, :email, :password, :phone, 1, :nid, :category, 'pending', 0.0, :address)";
    $stmt = $conn->prepare($query);

    $password_hash = password_hash($password, PASSWORD_BCRYPT);
    $nid = !empty($data->nid) ? $data->nid : null;
    $address = !empty($data->address) ? $data->address : null;

    $stmt->bindParam(':name', $data->name);
    $stmt->bindParam(':email', $email);
    $stmt->bindParam(':password', $password_hash);
    $stmt->bindParam(':phone', $phone);
    $stmt->bindParam(':nid', $nid);
    $stmt->bindParam(':category', $data->user_category);
    $stmt->bindParam(':address', $address);

    if($stmt->execute()) {
        $user_id = (int)$conn->lastInsertId();

        sendResponse(true, "Registration successful! You can now log in.", [
            "require_otp" => false,
            "id" => $user_id,
            "name" => $data->name,
            "email" => $email,
            "phone" => $phone,
            "user_category" => $data->user_category,
            "verification_status" => "pending",
            "is_email_verified" => 1
        ]);
    } else {
        sendResponse(false, "System error during registration.");
    }
} else {
    sendResponse(false, "All required fields (Name, Email, Password, Phone, Category) must be provided.");
}
?>
