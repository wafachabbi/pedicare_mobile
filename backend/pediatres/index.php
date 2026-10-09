<?php
require_once '../config.php';

$method = $_SERVER['REQUEST_METHOD'];
$db     = getDB();

// GET /pediatres — liste tous les pédiatres
if ($method === 'GET') {
    $stmt = $db->prepare(
        'SELECT id, name, email, specialite, telephone, adresse
         FROM users WHERE role = ? ORDER BY name ASC'
    );
    $stmt->execute(['pediatre']);
    json_response(['pediatres' => $stmt->fetchAll()]);
}

json_response(['error' => 'Méthode non supportée.'], 405);
