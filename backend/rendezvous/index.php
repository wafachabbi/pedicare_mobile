<?php
require_once '../config.php';

$method    = $_SERVER['REQUEST_METHOD'];
$enfant_id = $_GET['enfant_id'] ?? null;
$db        = getDB();

if ($method === 'GET') {
    if (!$enfant_id) json_response(['error' => 'enfant_id requis.'], 400);
    $stmt = $db->prepare('SELECT * FROM rendezvous WHERE enfant_id = ? ORDER BY date_heure ASC');
    $stmt->execute([$enfant_id]);
    json_response(['rendezvous' => $stmt->fetchAll()]);
}

if ($method === 'POST') {
    $b = get_body();
    $stmt = $db->prepare('
        INSERT INTO rendezvous (enfant_id, titre, medecin, specialite, lieu, date_heure, statut, type, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ');
    $stmt->execute([
        $b['enfantId'], $b['titre'], $b['medecin'] ?? '',
        $b['specialite'] ?? '', $b['lieu'] ?? '',
        $b['dateHeure'], $b['statut'] ?? 'enAttente',
        $b['type'] ?? 'presentiel', $b['notes'] ?? ''
    ]);
    json_response(['id' => $db->lastInsertId()], 201);
}

if ($method === 'PUT') {
    $b  = get_body();
    $id = $_GET['id'] ?? null;
    if (!$id) json_response(['error' => 'id requis.'], 400);
    $stmt = $db->prepare('
        UPDATE rendezvous SET titre=?, medecin=?, specialite=?, lieu=?, date_heure=?, statut=?, type=?, notes=?
        WHERE id=?
    ');
    $stmt->execute([
        $b['titre'], $b['medecin'] ?? '', $b['specialite'] ?? '',
        $b['lieu'] ?? '', $b['dateHeure'], $b['statut'] ?? 'enAttente',
        $b['type'] ?? 'presentiel', $b['notes'] ?? '', $id
    ]);
    json_response(['message' => 'Rendez-vous mis à jour.']);
}

if ($method === 'DELETE') {
    $id = $_GET['id'] ?? null;
    if (!$id) json_response(['error' => 'id requis.'], 400);
    $db->prepare('DELETE FROM rendezvous WHERE id = ?')->execute([$id]);
    json_response(['message' => 'Rendez-vous supprimé.']);
}

json_response(['error' => 'Méthode non supportée.'], 405);
