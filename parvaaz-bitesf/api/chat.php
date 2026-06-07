<?php
/**
 * پروکسی API چت — برای هاست اشتراکی NetAfraz / irwebspace (PHP)
 */
header('Content-Type: application/json; charset=utf-8');

$allowed = [
    'https://presf.ir',
    'https://www.presf.ir',
    'http://localhost:3000',
    'http://127.0.0.1:3000',
];

$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if (in_array($origin, $allowed, true)) {
    header('Access-Control-Allow-Origin: ' . $origin);
}
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

$secretsFile = __DIR__ . '/secrets.php';
if (!is_file($secretsFile)) {
    http_response_code(500);
    echo json_encode(['error' => 'API key not configured on server']);
    exit;
}

$secrets = require $secretsFile;
$apiKey = $secrets['anthropic_api_key'] ?? '';

if ($apiKey === '' || $apiKey === 'YOUR_API_KEY_HERE') {
    http_response_code(500);
    echo json_encode(['error' => 'API key not configured on server']);
    exit;
}

$body = file_get_contents('php://input');
if ($body === false || $body === '') {
    http_response_code(400);
    echo json_encode(['error' => 'Empty request body']);
    exit;
}

if (!function_exists('curl_init')) {
    http_response_code(500);
    echo json_encode(['error' => 'PHP cURL extension required']);
    exit;
}

$ch = curl_init('https://api.anthropic.com/v1/messages');
curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => $body,
    CURLOPT_HTTPHEADER => [
        'Content-Type: application/json',
        'x-api-key: ' . $apiKey,
        'anthropic-version: 2023-06-01',
    ],
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 120,
    CURLOPT_SSL_VERIFYPEER => true,
]);

$response = curl_exec($ch);
$httpCode = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
curl_close($ch);

if ($response === false) {
    http_response_code(502);
    echo json_encode(['error' => 'Upstream failed: ' . $curlError]);
    exit;
}

http_response_code($httpCode > 0 ? $httpCode : 502);
echo $response;
