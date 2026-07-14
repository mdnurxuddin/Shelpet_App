<?php
include_once 'config.php';

$email = 'admin@shelpet.com';
$password = '123456';
$password_hash = password_hash($password, PASSWORD_BCRYPT);

try {
    $stmt = $conn->prepare("SELECT id, name, email, role FROM users WHERE email = :email");
    $stmt->bindParam(':email', $email);
    $stmt->execute();
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user) {
        echo "User found: " . json_encode($user) . "\n";
        // Update password and make sure role is admin
        $update = $conn->prepare("UPDATE users SET password = :password, role = 'admin' WHERE email = :email");
        $update->bindParam(':password', $password_hash);
        $update->bindParam(':email', $email);
        $update->execute();
        echo "Password updated successfully to '123456' and role ensured to 'admin'.\n";
    } else {
        echo "User 'admin@shelpet.com' not found. Creating user...\n";
        $insert = $conn->prepare("INSERT INTO users (name, email, password, user_category, verification_status, rating, role) 
                                  VALUES ('ShelPet Admin', :email, :password, 'Rescuer', 'verified', 5.0, 'admin')");
        $insert->bindParam(':email', $email);
        $insert->bindParam(':password', $password_hash);
        $insert->execute();
        echo "Admin user created successfully with password '123456'.\n";
    }
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>
