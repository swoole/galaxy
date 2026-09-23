<?php

declare(strict_types=1);

$host = getenv('DB_HOST') ?: 'mysql';
$port = (int) (getenv('DB_PORT') ?: 3306);
$database = getenv('DB_DATABASE') ?: 'code_galaxy';
$username = getenv('DB_USERNAME') ?: 'galaxy';
$password = getenv('DB_PASSWORD') ?: '';
$prefix = getenv('DB_PREFIX') ?: 'galaxy_';
$deadline = time() + 120;
$pdo = null;

do {
    try {
        $pdo = new PDO(
            sprintf('mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4', $host, $port, $database),
            $username,
            $password,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::MYSQL_ATTR_MULTI_STATEMENTS => true,
            ],
        );
        break;
    } catch (Throwable $exception) {
        if (time() >= $deadline) {
            fwrite(STDERR, "MySQL 在 120 秒内未就绪：{$exception->getMessage()}\n");
            exit(1);
        }
        sleep(2);
    }
} while (true);

if (! in_array(strtolower((string) getenv('GALAXY_AUTO_INIT')), ['', '1', 'true', 'yes'], true)) {
    exit(0);
}

$statement = $pdo->prepare('SHOW TABLES LIKE ?');
$statement->execute([$prefix . 'user']);
if ($statement->fetchColumn() !== false) {
    exit(0);
}

fwrite(STDOUT, "首次运行：正在初始化 CodeGalaxy 数据库\n");
$schema = file_get_contents('/opt/www/database/init.sql');
if ($schema === false || trim($schema) === '') {
    fwrite(STDERR, "数据库初始化文件不存在或为空\n");
    exit(1);
}
$pdo->exec($schema);
fwrite(STDOUT, "数据库初始化完成\n");
