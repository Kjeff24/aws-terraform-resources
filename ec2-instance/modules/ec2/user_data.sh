#!/usr/bin/env bash
set -euxo pipefail

# Log output to both console and a logfile
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "[user-data] Starting bootstrap at $(date)"

# Detect package manager and install a simple web server
if command -v yum >/dev/null 2>&1; then
  # Amazon Linux / RHEL family
  yum update -y || true
  # Prefer nginx; fall back to httpd if needed
  yum install -y nginx || yum install -y httpd
  if command -v nginx >/dev/null 2>&1; then
    systemctl enable nginx
    systemctl start nginx
    echo "<h1>EC2 up via user_data (nginx)</h1>" > /usr/share/nginx/html/index.html || true
  else
    systemctl enable httpd
    systemctl start httpd
    echo "<h1>EC2 up via user_data (httpd)</h1>" > /var/www/html/index.html || true
  fi
elif command -v apt-get >/dev/null 2>&1; then
  # Ubuntu / Debian family
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y || true
  apt-get install -y nginx || true
  systemctl enable nginx || true
  systemctl start nginx || true
  echo "<h1>EC2 up via user_data (nginx)</h1>" > /var/www/html/index.nginx-debian.html || true
else
  echo "[user-data] Unknown OS; writing marker file only"
  echo "EC2 up via user_data" > /var/tmp/user-data.txt
fi

echo "[user-data] Completed bootstrap at $(date)"
