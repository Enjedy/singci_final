<?php

require __DIR__ . '/config.php';

require_auth();

$method = $_SERVER['REQUEST_METHOD'];
$pdo = db();

if ($method === 'GET') {
    $rows = $pdo->query('SELECT a.*, (SELECT COUNT(*) FROM annonce_comments c WHERE c.annonce_id = a.id) AS comment_count FROM annonces a ORDER BY a.date_publication DESC')->fetchAll();
    $items = array_map(static function ($r) {
        return [
            'id' => (int)$r['id'],
            'titre' => $r['titre'],
            'description' => $r['description'],
            'image' => $r['image'],
            'auteur' => $r['auteur'],
            'datePublication' => $r['date_publication'],
            'likes' => (int)$r['likes'],
            'commentCount' => (int)$r['comment_count'],
        ];
    }, $rows);
    json_out(['success' => true, 'annonces' => $items]);
}

if ($method === 'POST') {
    $data = body();
    $action = $data['action'] ?? 'create';

    switch ($action) {
        case 'like':
            $id = (int)($data['id'] ?? 0);
            if ($id <= 0) {
                json_error('id invalide');
            }
            $delta = (int)($data['delta'] ?? 1);
            $stmt = $pdo->prepare(
                'UPDATE annonces SET likes = GREATEST(likes + :delta, 0) WHERE id = :id'
            );
            $stmt->execute([':delta' => $delta, ':id' => $id]);
            json_out(['success' => true]);

        case 'comment':
            $id = (int)($data['id'] ?? 0);
            $contenu = trim($data['contenu'] ?? '');
            if ($id <= 0 || $contenu === '') {
                json_error('id ou contenu invalide');
            }
            $stmt = $pdo->prepare(
                'INSERT INTO annonce_comments (annonce_id, pseudo, contenu) VALUES (:id, :pseudo, :contenu)'
            );
            $stmt->execute([
                ':id' => $id,
                ':pseudo' => trim($data['pseudo'] ?? 'Citoyen SignCi'),
                ':contenu' => $contenu,
            ]);
            json_out(['success' => true, 'id' => (int)$pdo->lastInsertId()], 201);

        case 'delete':
            $id = (int)($data['id'] ?? 0);
            if ($id <= 0) {
                json_error('id invalide');
            }
            $stmt = $pdo->prepare('DELETE FROM annonces WHERE id = :id');
            $stmt->execute([':id' => $id]);
            json_out(['success' => true]);

        case 'create':
        default:
            $titre = trim($data['titre'] ?? '');
            $description = trim($data['description'] ?? '');
            if ($titre === '') {
                json_error('Champ obligatoire manquant: titre');
            }
            $stmt = $pdo->prepare(
                'INSERT INTO annonces (titre, description, image, auteur, date_publication, likes)
                 VALUES (:titre, :description, :image, :auteur, NOW(), 0)'
            );
            $stmt->execute([
                ':titre' => $titre,
                ':description' => $description,
                ':image' => $data['image'] ?? '',
                ':auteur' => $data['auteur'] ?? 'Administration SignCi',
            ]);
            json_out(['success' => true, 'id' => (int)$pdo->lastInsertId()], 201);
    }
}

json_error('Méthode non autorisée', 405);