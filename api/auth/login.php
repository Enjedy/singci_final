<?php

require __DIR__ . '/../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Méthode non autorisée', 405);
}

$data = body();
$login = trim($data['login'] ?? '');
$password = $data['password'] ?? '';

if ($login === '' || $password === '') {
    json_error('Login et mot de passe sont obligatoires');
}

$pdo = db();
$stmt = $pdo->prepare('SELECT id, pseudo, email, password FROM users WHERE pseudo = :login OR email = :login LIMIT 1');
$stmt->execute([':login' => $login]);
$user = $stmt->fetch();

if (!$user || !password_verify($password, $user['password'])) {
    json_error('Identifiants incorrects', 401);
}

$token = jwt_encode(['id' => (int)$user['id'], 'pseudo' => $user['pseudo'], 'email' => $user['email']]);
json_out([
    'success' => true,
    'token' => $token,
    'user' => ['id' => (int)$user['id'], 'pseudo' => $user['pseudo'], 'email' => $user['email']],
]);