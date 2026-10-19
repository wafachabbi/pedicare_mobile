<?php
require_once '../config.php';

$method      = $_SERVER['REQUEST_METHOD'];
$enfant_id   = $_GET['enfant_id']   ?? null;
$pediatre_id = $_GET['pediatre_id'] ?? null;
$db          = getDB();

// ── GET ───────────────────────────────────────────────────────────────────────
if ($method === 'GET') {

    // Liste par pédiatre (espace pédiatre)
    if ($pediatre_id) {
        $stmt = $db->prepare('
            SELECT r.*,
                   e.prenom AS enfant_prenom, e.nom AS enfant_nom,
                   u.name   AS parent_nom
            FROM rendezvous r
            LEFT JOIN enfants e ON e.id = r.enfant_id
            LEFT JOIN users   u ON u.id = e.parent_id
            WHERE r.pediatre_id = ?
            ORDER BY r.date_heure ASC
        ');
        $stmt->execute([$pediatre_id]);
        json_response(['rendezvous' => $stmt->fetchAll()]);
    }

    // Liste par enfant (espace parent)
    if ($enfant_id) {
        try {
            $stmt = $db->prepare('
                SELECT r.*
                FROM rendezvous r
                WHERE r.enfant_id = ?
                ORDER BY r.date_heure ASC
            ');
            $stmt->execute([$enfant_id]);
            json_response(['rendezvous' => $stmt->fetchAll()]);
        } catch (Exception $e) {
            json_response(['error' => $e->getMessage(), 'rendezvous' => []], 500);
        }
    }

    json_response(['error' => 'enfant_id ou pediatre_id requis.'], 400);
}

// ── POST ──────────────────────────────────────────────────────────────────────
if ($method === 'POST') {
    $b = get_body();
    $stmt = $db->prepare('
        INSERT INTO rendezvous
          (enfant_id, pediatre_id, titre, medecin, specialite, lieu, date_heure, statut, type, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ');
    $stmt->execute([
        $b['enfantId'],
        $b['pediatreId'] ?? null,
        $b['titre'],
        $b['medecin']    ?? '',
        $b['specialite'] ?? '',
        $b['lieu']       ?? '',
        $b['dateHeure'],
        $b['statut']     ?? 'enAttente',
        $b['type']       ?? 'presentiel',
        $b['notes']      ?? '',
    ]);
    json_response(['id' => $db->lastInsertId()], 201);
}

// ── PUT ───────────────────────────────────────────────────────────────────────
if ($method === 'PUT') {
    $b  = get_body();
    $id = $_GET['id'] ?? null;
    if (!$id) json_response(['error' => 'id requis.'], 400);
    $stmt = $db->prepare('
        UPDATE rendezvous
        SET pediatre_id=?, titre=?, medecin=?, specialite=?,
            lieu=?, date_heure=?, statut=?, type=?, notes=?
        WHERE id=?
    ');
    $stmt->execute([
        $b['pediatreId'] ?? null,
        $b['titre'],
        $b['medecin']    ?? '',
        $b['specialite'] ?? '',
        $b['lieu']       ?? '',
        $b['dateHeure'],
        $b['statut']     ?? 'enAttente',
        $b['type']       ?? 'presentiel',
        $b['notes']      ?? '',
        $id,
    ]);
    json_response(['message' => 'Rendez-vous mis à jour.']);
}

// ── DELETE ────────────────────────────────────────────────────────────────────
if ($method === 'DELETE') {
    $id = $_GET['id'] ?? null;
    if (!$id) json_response(['error' => 'id requis.'], 400);
    $db->prepare('DELETE FROM rendezvous WHERE id = ?')->execute([$id]);
    json_response(['message' => 'Rendez-vous supprimé.']);
}

json_response(['error' => 'Méthode non supportée.'], 405);
