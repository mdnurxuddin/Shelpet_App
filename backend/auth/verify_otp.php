<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->email) && !empty($data->otp)) {
    $email = trim($data->email);
    $otp = trim($data->otp);

    $query = "SELECT * FROM users WHERE email = :email";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':email', $email);
    $stmt->execute();

    if($stmt->rowCount() > 0) {
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user['is_email_verified'] == 1) {
            unset($user['password']);
            unset($user['otp_code']);
            unset($user['otp_expires_at']);
            sendResponse(true, "Account is already verified.", $user);
        }

        if ($user['otp_code'] === $otp) {
            $now = date('Y-m-d H:i:s');
            if ($user['otp_expires_at'] < $now) {
                sendResponse(false, "Verification code has expired. Please request a new code.");
            }

            // Verify User Account
            $update = $conn->prepare("UPDATE users SET is_email_verified = 1, otp_code = NULL, otp_expires_at = NULL WHERE id = :id");
            $update->bindParam(':id', $user['id']);

            if ($update->execute()) {
                // Fetch clean profile
                $fetch = $conn->prepare("SELECT id, name, email, phone, avatar, user_category, verification_status, rating, role, address FROM users WHERE id = :id");
                $fetch->bindParam(':id', $user['id']);
                $fetch->execute();
                $verifiedUser = $fetch->fetch(PDO::FETCH_ASSOC);

                sendResponse(true, "Email verification successful! Welcome to ShelPet.", $verifiedUser);
            } else {
                sendResponse(false, "Failed to activate account.");
            }
        } else {
            sendResponse(false, "Invalid verification code. Please check and try again.");
        }
    } else {
        sendResponse(false, "User account not found.");
    }
} else {
    sendResponse(false, "Email and OTP code are required.");
}
?>
