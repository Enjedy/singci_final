SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS incidents;
DROP TABLE IF EXISTS statuts;
DROP TABLE IF EXISTS problemes;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS type_lieu;
DROP TABLE IF EXISTS fokontany;
DROP TABLE IF EXISTS quartiers;
DROP TABLE IF EXISTS arrondissements;

SET FOREIGN_KEY_CHECKS = 1;

-- TYPE LIEU
CREATE TABLE type_lieu (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(255) NOT NULL
);
INSERT INTO type_lieu (id, nom) VALUES
(1, 'Lieu public'),
(2, 'Bâtiment');

-- CATEGORIES
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    type_lieu_id INT,
    FOREIGN KEY (type_lieu_id) REFERENCES type_lieu(id)
);
INSERT INTO categories (id, nom, type_lieu_id) VALUES
(1, 'Route', 1),
(2, 'Éclairage', 1),
(3, 'Déchet', 1),
(4, 'Sécurité', 1);

-- PROBLEMES
CREATE TABLE problemes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    categorie_id INT,
    FOREIGN KEY (categorie_id) REFERENCES categories(id)
);
INSERT INTO problemes (id, nom, categorie_id) VALUES
(1, 'Route endommagée', 1),
(2, 'Route inondée', 1),
(3, 'Arbre dangereux', 1),
(4, 'Lampadaire éteint', 2),
(5, 'Dépôt sauvage', 3);

-- LOCALISATION
CREATE TABLE arrondissements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(255) NOT NULL
);
INSERT INTO arrondissements (id, nom) VALUES
(1, '1er arrondissement');

CREATE TABLE quartiers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    arrondissement_id INT,
    FOREIGN KEY (arrondissement_id) REFERENCES arrondissements(id)
);
INSERT INTO quartiers (id, nom, arrondissement_id) VALUES
(1, 'Analakely', 1);

CREATE TABLE fokontany (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    quartier_id INT,
    FOREIGN KEY (quartier_id) REFERENCES quartiers(id)
);
INSERT INTO fokontany (id, nom, quartier_id) VALUES
(1, 'Tsaralalana', 1);

-- STATUT
CREATE TABLE statuts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(255) NOT NULL
);
INSERT INTO statuts (id, nom) VALUES
(1, 'En attente'),
(2, 'En cours'),
(3, 'Résolu');


-- INCIDENTS / SIGNALEMENTS
CREATE TABLE incidents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NULL,
    description TEXT,
    probleme_id INT,
    fokontany_id INT,
    statut_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    latitude DOUBLE NULL,
    longitude DOUBLE NULL,
    FOREIGN KEY (probleme_id) REFERENCES problemes(id),
    FOREIGN KEY (fokontany_id) REFERENCES fokontany(id),
    FOREIGN KEY (statut_id) REFERENCES statuts(id)
);

-- Insert sample data to populate the dashboard stats
INSERT INTO incidents (title, description, probleme_id, fokontany_id, statut_id, created_at, latitude, longitude)
VALUES 
('Nid de poule géant', 'Un trou au milieu de la rue.', 1, 1, 1, DATE_SUB(NOW(), INTERVAL 1 DAY), -18.906, 47.525),
('Lampadaire cassé', 'Aucune lumière la nuit.', 4, 1, 2, DATE_SUB(NOW(), INTERVAL 3 DAY), -18.905, 47.526),
('Ordures non ramassées', 'Les poubelles débordent.', 5, 1, 3, DATE_SUB(NOW(), INTERVAL 2 DAY), -18.907, 47.524),
('Grosse branche sur route', 'Danger lors de vents forts.', 3, 1, 1, DATE_SUB(NOW(), INTERVAL 5 DAY), -18.908, 47.525),
('Route inondée', 'Impossible de passer.', 2, 1, 2, NOW(), -18.910, 47.530);
