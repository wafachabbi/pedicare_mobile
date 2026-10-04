<?php
require_once '../config.php';

$method    = $_SERVER['REQUEST_METHOD'];
$enfant_id = $_GET['enfant_id'] ?? null;
$db        = getDB();

if ($method === 'GET') {
    if (!$enfant_id) json_response(['error' => 'enfant_id requis.'], 400);
    $stmt = $db->prepare('SELECT * FROM croissance WHERE enfant_id = ? ORDER BY date_mesure DESC');
    $stmt->execute([$enfant_id]);
    json_response(['mesures' => $stmt->fetchAll()]);
}

if ($method === 'POST') {
    $b = get_body();
    $stmt = $db->prepare('
        INSERT INTO croissance (enfant_id, date_mesure, poids, taille, perimetre_cranien, notes)
        VALUES (?, ?, ?, ?, ?, ?)
    ');
    $stmt->execute([
        $b['enfantId'], $b['date'], $b['poids'], $b['taille'],
        $b['perimeterCranien'] ?? null, $b['notes'] ?? ''
    ]);
    json_response(['id' => $db->lastInsertId()], 201);
}

if ($method === 'PUT') {
    $b  = get_body();
    $id = $_GET['id'] ?? null;
    if (!$id) json_response(['error' => 'id requis.'], 400);
    $stmt = $db->prepare('
        UPDATE croissance SET date_mesure=?, poids=?, taille=?, perimetre_cranien=?, notes=? WHERE id=?
    ');
    $stmt->execute([
        $b['date'], $b['poids'], $b['taille'],
        $b['perimeterCranien'] ?? null, $b['notes'] ?? '', $id
    ]);
    json_response(['message' => 'Mesure mise à jour.']);
}

if ($method === 'DELETE') {
    $id = $_GET['id'] ?? null;
    if (!$id) json_response(['error' => 'id requis.'], 400);
    $db->prepare('DELETE FROM croissance WHERE id = ?')->execute([$id]);
    json_response(['message' => 'Mesure supprimée.']);
}

json_response(['error' => 'Méthode non supportée.'], 405);
