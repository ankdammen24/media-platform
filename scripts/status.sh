#!/usr/bin/env bash
set -euo pipefail

docker compose ps

echo
echo "API health (http://127.0.0.1:3000/health):"
if ! curl -fsS http://127.0.0.1:3000/health; then
  echo "API health check failed"
fi

echo
echo "Frontend health (http://127.0.0.1:8080):"
if ! curl -fsS http://127.0.0.1:8080; then
  echo "Frontend health check failed"
fi
