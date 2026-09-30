<?php
require_once '../config.php';

$method    = $_SERVER['REQUEST_METHOD'];
$parent_id = $_GET['parent_id'] ?? null;
$db        = getDB();

// GET — liste des enfants d'un parent
if ($method === 'GET') {
    if (!$parent_id) json_response(['error' => 'parent_id requis.'], 400);
    $stmt = $db->prepare('SELECT * FROM enfants WHERE parent_id = ? ORDER BY prenom ASC');
    $stmt->execute([$parent_id]);
    json_response(['enfants' => $stmt->fetchAll()]);
}

// POST — ajouter un enfant
if ($method === 'POST') {
    $b = get_body();
    $stmt = $db->prepare('
        INSERT INTO enfants (parent_id, nom, prenom, date_naissance, sexe, groupe_sanguin, allergies)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ');
    $stmt->execute([
        $b['parentId'], $b['nom'], $b['prenom'], $b['dateNaissance'],
        $b['sexe'], $b['groupeSanguin'] ?? null, $b['allergies'] ?? null
    ]);
    json_response(['id' => $db->lastInsertId()], 201);
}

// PUT — modifier un enfant
if ($method === 'PUT') {
    $b  = get_body();
    $id = $_GET['id'] ?? null;
    if (!$id) json_response(['error' => 'id requis.'], 400);
    $stmt = $db->prepare('
        UPDATE enfants SET nom=?, prenom=?, date_naissance=?, sexe=?, groupe_sanguin=?, allergies=? WHERE id=?
    ');
    $stmt->execute([
        $b['nom'], $b['prenom'], $b['dateNaissance'],
        $b['sexe'], $b['groupeSanguin'] ?? null, $b['allergies'] ?? null, $id
    ]);
    json_response(['message' => 'Enfant mis à jour.']);
}

// DELETE
if ($method === 'DELETE') {
    $id = $_GET['id'] ?? null;
    if (!$id) json_response(['error' => 'id requis.'], 400);
    $db->prepare('DELETE FROM enfants WHERE id = ?')->execute([$id]);
    json_response(['message' => 'Enfant supprimé.']);
}

json_response(['error' => 'Méthode non supportée.'], 405);
