<?php

require __DIR__ . '/config.php';

require_auth();

$method = $_SERVER['REQUEST_METHOD'];
$pdo = db();

if ($method === 'GET') {
    $rows = $pdo->query('SELECT * FROM signalement ORDER BY id DESC')->fetchAll();
    $items = array_map(static function ($r) {
        return [
            'id' => (int)$r['id'],
            'firestoreId' => $r['firestore_id'],
            'type' => $r['type'],
            'categorie' => $r['categorie'],
            'probleme' => $r['probleme'],
            'description' => $r['description'],
            'adresse' => $r['adresse'],
            'image' => $r['image'],
            'status' => $r['status'],
            'latitude' => $r['latitude'] !== null ? (float)$r['latitude'] : null,
            'longitude' => $r['longitude'] !== null ? (float)$r['longitude'] : null,
            'priorite' => $r['priorite'],
            'confidenceScore' => (float)$r['confidence_score'],
            'keywords' => $r['keywords'],
            'upvotesCount' => (int)$r['upvotes_count'],
            'isDuplicate' => (int)$r['is_duplicate'],
            'duplicateOfId' => $r['duplicate_of_id'],
            'isCriticalZone' => (int)$r['is_critical_zone'],
            'createdAt' => $r['created_at'],
            'userId' => $r['user_id'],
            'userPseudo' => $r['user_pseudo'],
        ];
    }, $rows);
    json_out(['success' => true, 'signalements' => $items]);
}

if ($method === 'POST') {
    $data = body();
    $action = $data['action'] ?? 'create';

    switch ($action) {
        case 'upvote':
            $id = (int)($data['id'] ?? 0);
            if ($id <= 0) {
                json_error('id invalide');
            }
            $stmt = $pdo->prepare("UPDATE signalement SET upvotes_count = upvotes_count + 1, priorite = IF(upvotes_count + 1 >= 5, 'Haute', priorite) WHERE id = :id");
            $stmt->execute([':id' => $id]);
            json_out(['success' => true]);

        case 'critical':
            $ids = $data['ids'] ?? [];
            $isCritical = empty($data['isCriticalZone']) ? 0 : 1;
            $stmt = $pdo->prepare('UPDATE signalement SET is_critical_zone = :critical WHERE id = :id');
            foreach ($ids as $cid) {
                $stmt->execute([':critical' => $isCritical, ':id' => (int)$cid]);
            }
            json_out(['success' => true]);

        case 'status':
            $id = (int)($data['id'] ?? 0);
            $status = trim($data['status'] ?? '');
            if ($id <= 0 || $status === '') {
                json_error('id ou status invalide');
            }
            $stmt = $pdo->prepare('UPDATE signalement SET status = :status WHERE id = :id');
            $stmt->execute([':status' => $status, ':id' => $id]);
            json_out(['success' => true]);

        case 'delete':
            $pdo->exec('DELETE FROM signalement');
            json_out(['success' => true]);

        case 'create':
        default:
            foreach (['categorie', 'probleme', 'description'] as $k) {
                if (trim($data[$k] ?? '') === '') {
                    json_error("Champ obligatoire manquant: $k");
                }
            }

            $stmt = $pdo->prepare(
                'INSERT INTO signalement
                (firestore_id, type, categorie, probleme, description, adresse, image, status,
                 latitude, longitude, priorite, confidence_score, keywords, upvotes_count,
                 is_duplicate, duplicate_of_id, is_critical_zone, created_at, user_id, user_pseudo)
                VALUES
                (:firestore_id, :type, :categorie, :probleme, :description, :adresse, :image, :status,
                 :latitude, :longitude, :priorite, :confidence_score, :keywords, :upvotes_count,
                 :is_duplicate, :duplicate_of_id, :is_critical_zone, :created_at, :user_id, :user_pseudo)'
            );

            $stmt->execute([
                ':firestore_id' => $data['firestoreId'] ?? null,
                ':type' => $data['type'] ?? 'Lieu public',
                ':categorie' => $data['categorie'],
                ':probleme' => $data['probleme'],
                ':description' => $data['description'],
                ':adresse' => $data['adresse'] ?? '',
                ':image' => $data['image'] ?? '',
                ':status' => $data['status'] ?? 'En attente',
                ':latitude' => isset($data['latitude']) && $data['latitude'] !== null ? (float)$data['latitude'] : null,
                ':longitude' => isset($data['longitude']) && $data['longitude'] !== null ? (float)$data['longitude'] : null,
                ':priorite' => $data['priorite'] ?? 'Moyenne',
                ':confidence_score' => (float)($data['confidenceScore'] ?? 0.80),
                ':keywords' => $data['keywords'] ?? '[]',
                ':upvotes_count' => (int)($data['upvotesCount'] ?? 1),
                ':is_duplicate' => empty($data['isDuplicate']) ? 0 : 1,
                ':duplicate_of_id' => $data['duplicateOfId'] ?? null,
                ':is_critical_zone' => empty($data['isCriticalZone']) ? 0 : 1,
                ':created_at' => mysql_datetime($data['createdAt'] ?? null) ?? date('Y-m-d H:i:s'),
                ':user_id' => $data['userId'] ?? null,
                ':user_pseudo' => $data['userPseudo'] ?? null,
            ]);

            json_out(['success' => true, 'id' => (int)$pdo->lastInsertId()], 201);
    }
}

json_error('Méthode non autorisée', 405);