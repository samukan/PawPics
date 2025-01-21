--  Luodaan tietokanta
DROP DATABASE IF EXISTS PawPicsDB;
CREATE DATABASE PawPicsDB;
USE PawPicsDB;

-- Taulu rooleille
CREATE TABLE UserLevels (
    level_id INT AUTO_INCREMENT PRIMARY KEY,
    level_name VARCHAR(50) NOT NULL
);

-- Taulu käyttäjille
CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    user_level_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_level_id) REFERENCES UserLevels(level_id) ON DELETE CASCADE
);

-- Taulu lemmikkien perustiedoille
CREATE TABLE Pets (
    pet_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    pet_name VARCHAR(100) NOT NULL,
    pet_breed VARCHAR(100),
    pet_age INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Taulu mediaa varten (kuvat + videot).
-- Jokainen media-item viittaa yhteen lemmikkiin.
CREATE TABLE PetMedia (
    media_id INT AUTO_INCREMENT PRIMARY KEY,
    pet_id INT NOT NULL,
    filename VARCHAR(255) NOT NULL,
    filesize INT NOT NULL,
    media_type VARCHAR(50) NOT NULL, 
    title VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (pet_id) REFERENCES Pets(pet_id) ON DELETE CASCADE
);

-- Kommentit (liitetään media_id) 
CREATE TABLE Comments (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    media_id INT NOT NULL,
    user_id INT NOT NULL,
    comment_text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (media_id) REFERENCES PetMedia(media_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Tykkäykset like (liitetään media_id)
CREATE TABLE Likes (
    like_id INT AUTO_INCREMENT PRIMARY KEY,
    media_id INT NOT NULL,
    user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (media_id) REFERENCES PetMedia(media_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Tagit
CREATE TABLE Tags (
    tag_id INT AUTO_INCREMENT PRIMARY KEY,
    tag_name VARCHAR(50) NOT NULL
);

--  Media tagit 
--      PetMedia <-> Tags
CREATE TABLE MediaTags (
    media_id INT NOT NULL,
    tag_id INT NOT NULL,
    PRIMARY KEY (media_id, tag_id),
    FOREIGN KEY (media_id) REFERENCES PetMedia(media_id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES Tags(tag_id) ON DELETE CASCADE
);

-- Indeksit
CREATE INDEX idx_users_username ON Users(username);
CREATE INDEX idx_pets_userid ON Pets(user_id);
CREATE INDEX idx_petmedia_petid ON PetMedia(pet_id);
CREATE INDEX idx_comments_userid_mediaid ON Comments(user_id, media_id);

--  Esimerkkitietojen lisääminen

-- UserLevels
INSERT INTO UserLevels (level_name) VALUES ('Admin'), ('User'), ('Guest');

-- Users
INSERT INTO Users (username, password, email, user_level_id) VALUES
('JohnDoe', 'to-be-hashed-pw1', 'johndoe@example.com', 2),
('JaneSmith', 'to-be-hashed-pw2', 'janesmith@example.com', 2),
('Anon5468', 'to-be-hashed-pw3', 'anon5468@example.com', 2),
('AdminUser', 'to-be-hashed-pw4', 'adminuser@example.com', 1);

-- Pets (liitetään käyttäjiin)
INSERT INTO Pets (user_id, pet_name, pet_breed, pet_age) VALUES
(1, 'Buddy', 'Golden Retriever', 3),
(1, 'Fluffy', 'British Shorthair', 2),
(2, 'BunBun', 'Netherland Dwarf Rabbit', 1);

-- PetMedia (Kuvat ja videot)
INSERT INTO PetMedia (pet_id, filename, filesize, media_type, title, description)
VALUES
(1, 'buddy_park.jpg', 2048, 'image/jpeg', 'Buddy at the Park', 'Playing fetch on a sunny day'),
(1, 'buddy_fetch.mp4', 1048576, 'video/mp4', 'Buddy Fetch Video', 'Short clip of Buddy fetching the ball'),
(2, 'fluffy_sleep.jpg', 1024, 'image/jpeg', 'Fluffy Sleeping', 'Cutest sleeping pose ever'),
(3, 'bunbun_garden.jpg', 1500, 'image/jpeg', 'BunBun in Garden', 'Enjoying fresh veggies outside');

-- Comments
INSERT INTO Comments (media_id, user_id, comment_text) VALUES
(1, 2, 'Aww, Buddy is so cute!'),
(2, 1, 'Nice fetch video. Good dog!'),
(4, 2, 'BunBun looks so happy in the garden.');

-- Likes
INSERT INTO Likes (media_id, user_id) VALUES
(1, 2),
(1, 3),
(2, 3),
(4, 1);

-- Tags
INSERT INTO Tags (tag_name) VALUES 
('Dog'), 
('Cat'), 
('Rabbit'), 
('Outdoor'), 
('Funny'), 
('Video');

-- MediaTags - liitetään tageja eri media_id
-- (pet_id=1 => Buddy), (media_id=1 => buddy_park.jpg)
INSERT INTO MediaTags (media_id, tag_id) VALUES
(1, 1), -- Dog
(1, 4), -- Outdoor

(2, 1), -- Dog
(2, 6), -- Video

(3, 2), -- Cat

(4, 3), -- Rabbit
(4, 4); -- Outdoor

-- (VIEW)
-- Käyttäjien kontaktitiedot
CREATE OR REPLACE VIEW UserContactInfo AS
SELECT 
    user_id, 
    username, 
    email
FROM Users;

-- Yhdistetyt tiedot lemmikeistä ja omistajista
CREATE OR REPLACE VIEW PetDetails AS
SELECT 
    p.pet_id,
    p.pet_name,
    p.pet_breed,
    p.pet_age,
    u.username AS owner
FROM Pets p
JOIN Users u ON p.user_id = u.user_id;

-- Yhdistetyt tiedot mediaobjekteista ja lemmikeistä
CREATE OR REPLACE VIEW MediaDetails AS
SELECT
    m.media_id,
    m.title,
    m.description,
    m.media_type,
    pet.pet_name,
    pet.pet_breed,
    u.username AS owner
FROM PetMedia m
JOIN Pets pet ON m.pet_id = pet.pet_id
JOIN Users u ON pet.user_id = u.user_id;

-- Montako mediaa kullakin lemmikillä on
CREATE OR REPLACE VIEW PetMediaCount AS
SELECT
    pet.pet_id,
    pet.pet_name,
    COUNT(m.media_id) AS total_media
FROM Pets pet
LEFT JOIN PetMedia m ON pet.pet_id = m.pet_id
GROUP BY pet.pet_id;

-- Testikyselyt
-- SELECT * FROM UserContactInfo;
-- SELECT * FROM PetDetails;
-- SELECT * FROM MediaDetails;
-- SELECT * FROM PetMediaCount;
