CREATE DATABASE IF NOT EXISTS shelpet;
USE shelpet;

-- Drop tables in order
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS shares;
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS reactions;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS vets;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    avatar VARCHAR(255),
    user_category ENUM('Adoptor', 'Adoption Giver', 'Rescuer', 'Vet Doctor') NOT NULL,
    nid_number VARCHAR(20),
    nid_front_image VARCHAR(255),
    nid_back_image VARCHAR(255),
    verification_status ENUM('none', 'pending', 'verified', 'rejected') DEFAULT 'pending',
    rating DECIMAL(2, 1) DEFAULT 5.0,
    role ENUM('user', 'admin') DEFAULT 'user',
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    content TEXT,
    image VARCHAR(255),
    type ENUM('feed', 'adoption', 'fostering', 'rescue') DEFAULT 'feed',
    location VARCHAR(255),
    status ENUM('active', 'done', 'urgent') DEFAULT 'active',
    price DECIMAL(10, 2),
    pet_details JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    category ENUM('food', 'accessory', 'medicine') NOT NULL,
    image VARCHAR(255),
    stock INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT, receiver_id INT,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(id),
    FOREIGN KEY (receiver_id) REFERENCES users(id)
);

CREATE TABLE reactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT, post_id INT,
    type ENUM('like', 'love', 'care', 'sad') DEFAULT 'like',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    UNIQUE KEY (user_id, post_id)
);

CREATE TABLE comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT, post_id INT,
    parent_id INT DEFAULT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES comments(id) ON DELETE CASCADE
);

CREATE TABLE notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT, actor_id INT, post_id INT,
    type ENUM('reaction', 'comment', 'rescue_alert', 'message') NOT NULL,
    message TEXT, is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (actor_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE vets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    clinic VARCHAR(255),
    specialization VARCHAR(100),
    rating DECIMAL(2, 1) DEFAULT 0.0,
    reviews_count INT DEFAULT 0,
    image VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- --- INSERTING DUMMY DATA FOR TESTING ---

-- 1. Admin User (Password: 123456)
INSERT INTO users (name, email, password, user_category, verification_status, rating, role)
VALUES ('ShelPet Admin', 'admin@shelpet.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Rescuer', 'verified', 5.0, 'admin');

-- 2. Some Posts
INSERT INTO posts (user_id, content, image, type, location)
VALUES (1, 'Hello ShelPet! Meet my new kitten Luna. She is very playful!', 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800', 'feed', 'Dhaka');

INSERT INTO posts (user_id, content, image, type, location)
VALUES (1, 'URGENT: Found an injured dog near Central Park. Needs immediate medical help!', 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=800', 'rescue', 'Sector 4, Dhanmondi');

INSERT INTO posts (user_id, content, image, type, location, price)
VALUES (1, 'Beautiful Persian Cat for adoption. 2 years old, very friendly.', 'https://images.unsplash.com/photo-1513245543132-31f507417b26?w=800', 'adoption', 'Uttara', 0);

-- 3. Some Vets
INSERT INTO vets (name, clinic, specialization, rating, reviews_count)
VALUES ('Dr. Sarah Kabir', 'PetCare Clinic', 'Small Animals', 4.8, 120),
       ('Dr. Rahman', 'DVM Hospital', 'Surgery Specialist', 4.9, 85);

-- 4. Some Products
INSERT INTO products (user_id, name, description, price, category, image)
VALUES (1, 'Premium Dog Food', 'Nutritious kibble for adult dogs of all breeds.', 1250.00, 'food', 'https://images.unsplash.com/photo-1589722258380-6817d710d00d?w=800'),
       (1, 'Cat Scratching Post', 'Durable scratching tree with plush toy.', 2500.00, 'accessory', 'https://images.unsplash.com/photo-1545249390-6bdfa286032f?w=800'),
       (1, 'Cozy Pet Bed', 'Soft and comfortable cushion bed for cats and dogs.', 1800.00, 'accessory', 'https://images.unsplash.com/photo-1591584530036-0222388f41e1?w=800'),
       (1, 'Rubber Chew Toy', 'Non-toxic dental chew toy for aggressive chewing dogs.', 450.00, 'accessory', 'https://images.unsplash.com/photo-1576201836106-db1758fd1c97?w=800');

-- 5. Chat Messages Table
CREATE TABLE IF NOT EXISTS messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 6. User Reviews Table
CREATE TABLE IF NOT EXISTS user_reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    reviewer_id INT NOT NULL,
    target_id INT NOT NULL,
    rating DECIMAL(2,1) NOT NULL,
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (reviewer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (target_id) REFERENCES users(id) ON DELETE CASCADE
);
