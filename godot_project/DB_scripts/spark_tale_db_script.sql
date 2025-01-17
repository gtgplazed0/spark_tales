CREATE DATABASE spark_tales_db;
USE spark_tales_db;
CREATE TABLE users (
	user_id INT AUTO_INCREMENT PRIMARY KEY, 
    username VARCHAR(255) NOT NULL UNIQUE, 
    salt CHAR(64) NOT NULL,
    hashed_password CHAR(64) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
CREATE TABLE stories (
	story_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(100) NOT NULL UNIQUE,
    user_id INT NOT NULL,
    UNIQUE(user_id, story_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE
);
CREATE TABLE pages(
	page_id INT AUTO_INCREMENT PRIMARY KEY, 
    story_id INT NOT NULL, 
    page_number INT NOT NULL, 
    UNIQUE (story_id, page_number),
    FOREIGN KEY (story_id) REFERENCES stories(story_id)
		ON DELETE CASCADE
        ON UPDATE CASCADE
);
CREATE TABLE page_content(
	content_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    page_id INT NOT NULL, 
    text_content TEXT,
    image_url TEXT,
    UNIQUE (user_id, page_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (page_id) REFERENCES pages(page_id)
		ON DELETE CASCADE
        ON UPDATE CASCADE
);
SELECT * FROM stories;
ALTER TABLE pages AUTO_INCREMENT = 0;
ALTER TABLE stories AUTO_INCREMENT = 0;
ALTER TABLE page_content AUTO_INCREMENT = 0;

