-- Schema MySQL pour SignCi
-- Exécuter ce script une seule fois sur votre serveur (phpMyAdmin ou CLI).

CREATE DATABASE IF NOT EXISTS signci CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE signci;

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  pseudo VARCHAR(100) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS signalement (
  id INT AUTO_INCREMENT PRIMARY KEY,
  firestore_id VARCHAR(255) NULL,
  type VARCHAR(100) NULL,
  categorie VARCHAR(100) NULL,
  probleme VARCHAR(255) NULL,
  description TEXT NULL,
  adresse TEXT NULL,
  image TEXT NULL,
  status VARCHAR(50) DEFAULT 'En attente',
  latitude DOUBLE NULL,
  longitude DOUBLE NULL,
  priorite VARCHAR(50) DEFAULT 'Moyenne',
  confidence_score DOUBLE DEFAULT 0.80,
  keywords TEXT NULL,
  upvotes_count INT DEFAULT 1,
  is_duplicate TINYINT(1) DEFAULT 0,
  duplicate_of_id VARCHAR(255) NULL,
  is_critical_zone TINYINT(1) DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  user_id VARCHAR(255) NULL,
  user_pseudo VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Annonces publiées par l'administration (visibles par les citoyens)
CREATE TABLE IF NOT EXISTS annonces (
  id INT AUTO_INCREMENT PRIMARY KEY,
  titre VARCHAR(255) NOT NULL,
  description TEXT NULL,
  image TEXT NULL,
  auteur VARCHAR(100) DEFAULT 'Administration SignCi',
  date_publication DATETIME DEFAULT CURRENT_TIMESTAMP,
  likes INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Commentaires citoyens sur les annonces
CREATE TABLE IF NOT EXISTS annonce_comments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  annonce_id INT NOT NULL,
  pseudo VARCHAR(100) DEFAULT 'Citoyen SignCi',
  contenu TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_annonce_comments FOREIGN KEY (annonce_id) REFERENCES annonces(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;