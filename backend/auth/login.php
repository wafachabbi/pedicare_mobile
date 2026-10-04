<?php
require_once '../config.php';

$body     = get_body();
$email    = trim($body['email'] ?? '');
$password = $body['password'] ?? '';

if (!$email || !$password) {
    json_response(['error' => 'Email et mot de passe requis.'], 400);
}

$db   = getDB();
$stmt = $db->prepare('SELECT * FROM users WHERE email = ?');
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user || !password_verify($password, $user['password'])) {
    json_response(['error' => 'Email ou mot de passe incorrect.'], 401);
}

unset($user['password']); // ne jamais retourner le hash
json_response(['user' => $user]);
