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

    // Insert new user
    $query = "INSERT INTO users (name, email, password, phone, is_email_verified, otp_code, otp_expires_at, nid_number, user_category, verification_status, rating, address)
              VALUES (:name, :email, :password, :phone, 0, :otp, :otp_expires, :nid, :category, 'pending', 0.0, :address)";
    $stmt = $conn->prepare($query);

    $password_hash = password_hash($password, PASSWORD_BCRYPT);
    $nid = !empty($data->nid) ? $data->nid : null;
    $address = !empty($data->address) ? $data->address : null;

    $stmt->bindParam(':name', $data->name);
    $stmt->bindParam(':email', $email);
    $stmt->bindParam(':password', $password_hash);
    $stmt->bindParam(':phone', $phone);
    $stmt->bindParam(':otp', $otp);
    $stmt->bindParam(':otp_expires', $otp_expires_at);
    $stmt->bindParam(':nid', $nid);
    $stmt->bindParam(':category', $data->user_category);
    $stmt->bindParam(':address', $address);

    if($stmt->execute()) {
        $user_id = (int)$conn->lastInsertId();

        // Send Email OTP
        $subject = "ShelPet Email Verification Code: $otp";
        $headers = "MIME-Version: 1.0" . "\r\n";
        $headers .= "Content-type:text/html;charset=UTF-8" . "\r\n";
        $headers .= "From: ShelPet Verification <noreply@shelpet.com>" . "\r\n";

        $body = "
        <div style='font-family: Arial, sans-serif; padding: 20px; color: #333;'>
            <h2 style='color: #4F46E5;'>Welcome to ShelPet! 🐾</h2>
            <p>Thank you for registering. Please use the following 6-digit verification code to complete your registration:</p>
            <div style='background: #F3F4F6; padding: 15px; border-radius: 10px; font-size: 28px; font-weight: bold; letter-spacing: 5px; text-align: center; color: #4F46E5; margin: 20px 0;'>
                $otp
            </div>
            <p>This code is valid for <strong>10 minutes</strong>.</p>
            <hr style='border: none; border-top: 1px solid #EEE; margin: 20px 0;'>
            <p style='font-size: 12px; color: #777;'>If you did not register for a ShelPet account, please ignore this email.</p>
        </div>
        ";

        @mail($email, $subject, $body, $headers);

        sendResponse(true, "Registration successful. Please enter the verification code sent to $email.", [
            "require_otp" => true,
            "email" => $email,
            "user_id" => $user_id
        ]);
    } else {
        sendResponse(false, "System error during registration.");
    }
} else {
    sendResponse(false, "All required fields (Name, Email, Password, Phone, Category) must be provided.");
}
?>
