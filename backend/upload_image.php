<?php
include_once 'config.php';

// Ensure uploads folder exists
$target_dir = "uploads/";
if (!file_exists($target_dir)) {
    mkdir($target_dir, 0777, true);
}

// Basic error logging
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, "Invalid request method.");
}

if(isset($_FILES["image"])) {
    $file_extension = pathinfo($_FILES["image"]["name"], PATHINFO_EXTENSION);
    $file_name = time() . '_' . uniqid() . '.' . $file_extension;
    $target_file = $target_dir . $file_name;

    if (move_uploaded_file($_FILES["image"]["tmp_name"], $target_file)) {
        // Use your PC IP here
        $my_ip = "192.168.0.141";
        $actual_link = "http://" . $my_ip . "/shelpet_api/" . $target_file;
        sendResponse(true, "Upload successful", $actual_link);
    } else {
        $error = error_get_last();
        sendResponse(false, "Upload failed: " . $error['message']);
    }
} else {
    sendResponse(false, "No image found in request field 'image'. Available fields: " . json_encode($_FILES));
}
?>
