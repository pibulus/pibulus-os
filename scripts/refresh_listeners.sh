#!/bin/bash
# Refresh KPAB listener snapshot from AzuraCast's MySQL via PHP inside the container.
# Output written to /tmp/kpab_recent_listeners.tsv

set -euo pipefail

output=$(docker exec -i azuracast sh <<'INNER'
cat >/tmp/kpab_listener_sample.php <<'PHP'
<?php
$dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
    '127.0.0.1', getenv('MYSQL_PORT'), getenv('MYSQL_DATABASE'));
$pdo = new PDO($dsn, getenv('MYSQL_USER'), getenv('MYSQL_PASSWORD'));
$sql = "SELECT listener_ip, listener_user_agent, timestamp_start
        FROM listener ORDER BY id DESC LIMIT 8";
foreach ($pdo->query($sql) as $row) {
    echo implode("\t", [
        $row['listener_ip'],
        preg_replace('/\s+/', ' ', (string)$row['listener_user_agent']),
        $row['timestamp_start']
    ]), PHP_EOL;
}
PHP
php /tmp/kpab_listener_sample.php
INNER
)

if [ -z "$output" ]; then
  echo "Could not fetch listener rows — is the azuracast container running?"
  exit 1
fi

printf '%s\n' "$output" > /tmp/kpab_recent_listeners.tsv
echo "Listener snapshot refreshed."
