<?php

require __DIR__ . '/../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Méthode non autorisée', 405);
}

$data = body();
$pseudo = trim($data['pseudo'] ?? '');
$email = trim($data['email'] ?? '');
$password = $data['password'] ?? '';

if ($pseudo === '' || $email === '' || $password === '') {
    json_error('Pseudo, email et mot de passe sont obligatoires');
}
if (strlen($password) < 4) {
    json_error('Mot de passe trop court (minimum 4 caractères)');
}

$pdo = db();
$hash = password_hash($password, PASSWORD_DEFAULT);

try {
    $stmt = $pdo->prepare('INSERT INTO users (pseudo, email, password) VALUES (:pseudo, :email, :hash)');
    $stmt->execute([':pseudo' => $pseudo, ':email' => $email, ':hash' => $hash]);
} catch (PDOException $e) {
    json_error('Pseudo ou email déjà utilisé', 409);
}

$userId = (int)$pdo->lastInsertId();
$token = jwt_encode(['id' => $userId, 'pseudo' => $pseudo, 'email' => $email]);
json_out([
    'success' => true,
    'token' => $token,
    'user' => ['id' => $userId, 'pseudo' => $pseudo, 'email' => $email],
], 201);