<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: text/html; charset=UTF-8");

echo "<h1>ShelPet Upload Diagnostics</h1>";

// 1. Check php.ini settings
echo "<h2>1. PHP Settings</h2>";
echo "upload_max_filesize: " . ini_get('upload_max_filesize') . "<br>";
echo "post_max_size: " . ini_get('post_max_size') . "<br>";
echo "memory_limit: " . ini_get('memory_limit') . "<br>";
echo "max_execution_time: " . ini_get('max_execution_time') . "<br>";

// 2. Check Directory Permissions
echo "<h2>2. Directory Permissions</h2>";
$target_dir = "uploads/";
echo "Target directory path: " . realpath($target_dir) . "<br>";

if (file_exists($target_dir)) {
    echo "Directory exists: YES<br>";
    echo "Is writable: " . (is_writable($target_dir) ? "YES" : "NO") . "<br>";
    echo "Permissions: " . substr(sprintf('%o', fileperms($target_dir)), -4) . "<br>";
} else {
    echo "Directory exists: NO<br>";
    echo "Attempting to create directory...<br>";
    if (mkdir($target_dir, 0777, true)) {
        echo "Directory created successfully: YES<br>";
        echo "Is writable: " . (is_writable($target_dir) ? "YES" : "NO") . "<br>";
    } else {
        echo "Directory created successfully: NO<br>";
    }
}

// 3. Test write capability
if (is_writable($target_dir)) {
    $test_file = $target_dir . "test_write.txt";
    if (file_put_contents($test_file, "test") !== false) {
        echo "Test write successful: YES<br>";
        unlink($test_file);
    } else {
        echo "Test write successful: NO (Failed to write file)<br>";
    }
}

// 4. Test upload form
echo "<h2>3. Test Upload Form</h2>";
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    echo "<h3>Post Request Received</h3>";
    echo "Files: <pre>" . print_r($_FILES, true) . "</pre>";
    
    if (isset($_FILES['image'])) {
        $error_code = $_FILES['image']['error'];
        echo "Upload error code: $error_code<br>";
        
        switch ($error_code) {
            case UPLOAD_ERR_OK:
                echo "No errors.<br>";
                $file_extension = pathinfo($_FILES["image"]["name"], PATHINFO_EXTENSION);
                $file_name = time() . '_' . uniqid() . '.' . $file_extension;
                $target_file = $target_dir . $file_name;
                if (move_uploaded_file($_FILES["image"]["tmp_name"], $target_file)) {
                    echo "File successfully uploaded!<br>";
                    $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? "https://" : "http://";
                    $host = $_SERVER['HTTP_HOST'];
                    $actual_link = $protocol . $host . "/" . $target_file;
                    echo "Link: <a href='$actual_link' target='_blank'>$actual_link</a><br>";
                } else {
                    echo "Failed to move uploaded file.<br>";
                }
                break;
            case UPLOAD_ERR_INI_SIZE:
                echo "The uploaded file exceeds the upload_max_filesize directive in php.ini.<br>";
                break;
            case UPLOAD_ERR_FORM_SIZE:
                echo "The uploaded file exceeds the MAX_FILE_SIZE directive that was specified in the HTML form.<br>";
                break;
            case UPLOAD_ERR_PARTIAL:
                echo "The uploaded file was only partially uploaded.<br>";
                break;
            case UPLOAD_ERR_NO_FILE:
                echo "No file was uploaded.<br>";
                break;
            case UPLOAD_ERR_NO_TMP_DIR:
                echo "Missing a temporary folder.<br>";
                break;
            case UPLOAD_ERR_CANT_WRITE:
                echo "Failed to write file to disk.<br>";
                break;
            case UPLOAD_ERR_EXTENSION:
                echo "A PHP extension stopped the file upload.<br>";
                break;
        }
    } else {
        echo "No 'image' field found in FILES.<br>";
    }
}
?>
<form action="" method="post" enctype="multipart/form-data">
    Select image to upload:
    <input type="file" name="image" id="image">
    <input type="submit" value="Upload Image" name="submit">
</form>
