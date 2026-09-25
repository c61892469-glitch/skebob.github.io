<?php
header('Content-Type: application/json');

$uploadDir = __DIR__ . '/uploads/';
$dataFile = __DIR__ . '/configs.json';

// Создаем папку uploads, если её нет
if (!file_exists($uploadDir)) {
    mkdir($uploadDir, 0777, true);
}

// Создаем файл с базой данных, если его нет
if (!file_exists($dataFile)) {
    file_put_contents($dataFile, json_encode([]));
}

$action = $_GET['action'] ?? '';

// Получение списка всех загруженных конфигов
if ($action === 'list') {
    echo file_get_contents($dataFile);
    exit;
}

// Загрузка нового конфига на сервер
if ($action === 'upload' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $title = trim($_POST['title'] ?? '');
    $desc = trim($_POST['desc'] ?? '');

    if (empty($title) || empty($desc) || !isset($_FILES['cfgFile'])) {
        echo json_encode(['success' => false, 'message' => 'Please fill all fields.']);
        exit;
    }

    $file = $_FILES['cfgFile'];
    $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    $allowedExts = ['cfg', 'lua', 'txt'];

    if (!in_array($ext, $allowedExts)) {
        echo json_encode(['success' => false, 'message' => 'Invalid file extension. Only .cfg, .lua, .txt allowed.']);
        exit;
    }

    // Сохраняем файл под уникальным именем, чтобы файлы разных юзеров не перезаписывали друг друга
    $uniqueName = uniqid('cfg_', true) . '.' . $ext;
    $targetPath = $uploadDir . $uniqueName;

    if (move_uploaded_file($file['tmp_name'], $targetPath)) {
        $configs = json_decode(file_get_contents($dataFile), true) ?: [];

        $newEntry = [
            'id' => uniqid(),
            'title' => htmlspecialchars($title),
            'desc' => htmlspecialchars($desc),
            'fileName' => htmlspecialchars($file['name']),
            'fileUrl' => 'uploads/' . $uniqueName,
            'date' => date('Y-m-d H:i')
        ];

        array_unshift($configs, $newEntry);
        file_put_contents($dataFile, json_encode($configs, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

        echo json_encode(['success' => true]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to upload file to server.']);
    }
    exit;
}
