<?php
include_once '../config.php';

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->email)) {
    $email = trim($data->email);

    $query = "SELECT id, name, is_email_verified FROM users WHERE email = :email";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':email', $email);
    $stmt->execute();

    if($stmt->rowCount() > 0) {
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user['is_email_verified'] == 1) {
            sendResponse(false, "This email is already verified. Please login.");
        }

        // Generate new OTP
        $otp = sprintf("%06d", mt_rand(100000, 999999));
        $otp_expires_at = date('Y-m-d H:i:s', strtotime('+10 minutes'));

        $update = $conn->prepare("UPDATE users SET otp_code = :otp, otp_expires_at = :otp_expires WHERE id = :id");
        $update->bindParam(':otp', $otp);
        $update->bindParam(':otp_expires', $otp_expires_at);
        $update->bindParam(':id', $user['id']);

        if($update->execute()) {
            // Send Email OTP
            $subject = "ShelPet New Verification Code: $otp";
            $headers = "MIME-Version: 1.0" . "\r\n";
            $headers .= "Content-type:text/html;charset=UTF-8" . "\r\n";
            $headers .= "From: ShelPet Verification <noreply@shelpet.com>" . "\r\n";

            $body = "
            <div style='font-family: Arial, sans-serif; padding: 20px; color: #333;'>
                <h2 style='color: #4F46E5;'>ShelPet Verification Code 🐾</h2>
                <p>You requested a new verification code. Please use the following 6-digit code:</p>
                <div style='background: #F3F4F6; padding: 15px; border-radius: 10px; font-size: 28px; font-weight: bold; letter-spacing: 5px; text-align: center; color: #4F46E5; margin: 20px 0;'>
                    $otp
                </div>
                <p>This code is valid for <strong>10 minutes</strong>.</p>
            </div>
            ";

            @mail($email, $subject, $body, $headers);

            sendResponse(true, "A new verification code has been sent to $email.");
        } else {
            sendResponse(false, "Failed to update verification code.");
        }
    } else {
        sendResponse(false, "User account not found.");
    }
} else {
    sendResponse(false, "Email address is required.");
}
?>
