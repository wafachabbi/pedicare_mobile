<?php
require_once '../config.php';

$db = getDB();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $stmt = $db->prepare('SELECT id, name, email FROM users WHERE role = ? ORDER BY name ASC');
    $stmt->execute(['pediatre']);
    json_response(['pediatres' => $stmt->fetchAll()]);
}

json_response(['error' => 'Méthode non supportée.'], 405);
