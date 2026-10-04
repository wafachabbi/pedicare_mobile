<?php
require_once '../config.php';

$body = get_body();
$name     = trim($body['name'] ?? '');
$email    = trim($body['email'] ?? '');
$password = $body['password'] ?? '';
$role     = $body['role'] ?? 'parent';

if (!$name || !$email || !$password) {
    json_response(['error' => 'Champs requis manquants.'], 400);
}

$db = getDB();

// Vérifier doublon email
$stmt = $db->prepare('SELECT id FROM users WHERE email = ?');
$stmt->execute([$email]);
if ($stmt->fetch()) {
    json_response(['error' => 'Un compte avec cet email existe déjà.'], 409);
}

$hash = password_hash($password, PASSWORD_BCRYPT);
$stmt = $db->prepare('INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)');
$stmt->execute([$name, $email, $hash, $role]);

json_response(['message' => 'Compte créé avec succès.', 'id' => $db->lastInsertId()], 201);
