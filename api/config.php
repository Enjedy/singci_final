<?php

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

const DB_HOST = 'localhost';
const DB_NAME = 'signci';
const DB_USER = 'root';
const DB_PASS = '';
const JWT_SECRET = 'CHANGEZ_CE_SECRET_PAR_UNE_LONGUE_CHAINE_ALEATOIRE';

function db(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        try {
            $pdo = new PDO(
                'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
                DB_USER,
                DB_PASS,
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                ]
            );
        } catch (PDOException $e) {
            json_error('Connexion base de données échouée', 500);
        }
    }
    return $pdo;
}

function json_out($data, int $code = 200): void {
    http_response_code($code);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}

function json_error(string $message, int $code = 400): void {
    json_out(['success' => false, 'error' => $message], $code);
}

function body(): array {
    $raw = file_get_contents('php://input');
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

function b64u_encode(string $data): string {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function b64u_decode(string $data): string {
    $remainder = strlen($data) % 4;
    if ($remainder) {
        $data .= str_repeat('=', 4 - $remainder);
    }
    return base64_decode(strtr($data, '-_', '+/'));
}

function jwt_encode(array $payload, int $ttl = 86400): string {
    $now = time();
    $header = ['typ' => 'JWT', 'alg' => 'HS256'];
    $payload['iat'] = $now;
    $payload['exp'] = $now + $ttl;
    $segments = [
        b64u_encode(json_encode($header)),
        b64u_encode(json_encode($payload)),
    ];
    $signature = hash_hmac('sha256', implode('.', $segments), JWT_SECRET, true);
    $segments[] = b64u_encode($signature);
    return implode('.', $segments);
}

function jwt_decode(string $token): ?array {
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
        return null;
    }
    [$h, $p, $s] = $parts;
    $expected = b64u_encode(hash_hmac('sha256', "$h.$p", JWT_SECRET, true));
    if (!hash_equals($expected, $s)) {
        return null;
    }
    $payload = json_decode(b64u_decode($p), true);
    if (!is_array($payload)) {
        return null;
    }
    if (isset($payload['exp']) && time() >= $payload['exp']) {
        return null;
    }
    return $payload;
}

function bearer_token(): ?string {
    $auth = '';
    if (!empty($_SERVER['HTTP_AUTHORIZATION'])) {
        $auth = $_SERVER['HTTP_AUTHORIZATION'];
    } elseif (function_exists('getallheaders')) {
        foreach (getallheaders() as $key => $value) {
            if (strtolower($key) === 'authorization') {
                $auth = $value;
            }
        }
    }
    if (preg_match('/Bearer\s+(.+)/i', $auth, $m)) {
        return trim($m[1]);
    }
    return null;
}

function require_auth(): array {
    $token = bearer_token();
    if (!$token) {
        json_error('Token manquant', 401);
    }
    $payload = jwt_decode($token);
    if (!$payload) {
        json_error('Token invalide ou expiré', 401);
    }
    return $payload;
}

function mysql_datetime(?string $iso): ?string {
    if (!$iso) {
        return null;
    }
    try {
        return (new DateTime($iso))->format('Y-m-d H:i:s');
    } catch (Exception $e) {
        return null;
    }
}