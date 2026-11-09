<?php
require_once '../config.php';

$method    = $_SERVER['REQUEST_METHOD'];
$enfant_id = $_GET['enfant_id'] ?? null;
$db        = getDB();

// GET — liste des vaccins d'un enfant
if ($method === 'GET') {
    if (!$enfant_id) json_response(['error' => 'enfant_id requis.'], 400);
    $stmt = $db->prepare('SELECT * FROM vaccins WHERE enfant_id = ? ORDER BY date_administre DESC');
    $stmt->execute([$enfant_id]);
    json_response(['vaccins' => $stmt->fetchAll()]);
}

// POST — ajouter un vaccin
if ($method === 'POST') {
    $b = get_body();
    $stmt = $db->prepare('
        INSERT INTO vaccins (enfant_id, nom, maladie, date_administre, medecin, lieu, lot_numero, prochaine_date, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ');
    $stmt->execute([
        $b['enfantId'], $b['nom'], $b['maladie'], $b['dateAdministre'],
        $b['medecin'] ?? '', $b['lieu'] ?? '', $b['lotNumero'] ?? '',
        $b['prochaineDate'] ?? null, $b['notes'] ?? ''
    ]);
    json_response(['id' => $db->lastInsertId()], 201);
}

// PUT — modifier un vaccin
if ($method === 'PUT') {
    $b  = get_body();
    $id = $_GET['id'] ?? null;
    if (!$id) json_response(['error' => 'id requis.'], 400);
    $stmt = $db->prepare('
        UPDATE vaccins SET nom=?, maladie=?, date_administre=?, medecin=?, lieu=?, lot_numero=?, prochaine_date=?, notes=?
        WHERE id=?
    ');
    $stmt->execute([
        $b['nom'], $b['maladie'], $b['dateAdministre'],
        $b['medecin'] ?? '', $b['lieu'] ?? '', $b['lotNumero'] ?? '',
        $b['prochaineDate'] ?? null, $b['notes'] ?? '', $id
    ]);
    json_response(['message' => 'Vaccin mis à jour.']);
}

// DELETE — supprimer un vaccin
if ($method === 'DELETE') {
    $id = $_GET['id'] ?? null;
    if (!$id) json_response(['error' => 'id requis.'], 400);
    $db->prepare('DELETE FROM vaccins WHERE id = ?')->execute([$id]);
    json_response(['message' => 'Vaccin supprimé.']);
}

json_response(['error' => 'Méthode non supportée.'], 405);
