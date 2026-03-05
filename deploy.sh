#!/bin/bash
# ───────────────────────────────────────────────────
# FORBASI Kalbar Auto-Deploy Script
# Called by webhook.js when GitHub push event is received
#
# Usage: bash deploy.sh [backend|frontend]
# ───────────────────────────────────────────────────

set -e

TARGET="${1:-backend}"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="/var/www/kalbar/deploy.log"

# Log to both console and file
exec > >(tee -a "$LOG_FILE") 2>&1

echo ""
echo "═══════════════════════════════════════════"
echo "  Deploy: $TARGET"
echo "  Time:   $TIMESTAMP"
echo "═══════════════════════════════════════════"

# ── Paths ──────────────────────────────────────────
BACKEND_DIR="/var/www/kalbar/backend"
FRONTEND_DIR="/var/www/kalbar/frontend"

deploy_backend() {
    echo "→ Deploying backend..."

    echo "  [1/4] git pull..."
    cd "$BACKEND_DIR"
    git checkout -- .
    git clean -fd
    git pull origin master

    echo "  [2/4] npm install..."
    npm install --production

    echo "  [3/4] prisma migrate & generate..."
    npx prisma migrate deploy || true
    npx prisma generate

    echo "  [4/4] pm2 restart..."
    pm2 restart kalbar-backend --update-env || pm2 start src/server.js --name kalbar-backend

    echo "✅ Backend deployed!"
}

deploy_frontend() {
    echo "→ Deploying frontend..."

    echo "  [1/4] git pull..."
    cd "$FRONTEND_DIR"
    git checkout -- .
    git clean -fd
    git pull origin master

    echo "  [2/4] npm install..."
    npm install

    echo "  [3/4] npm run build..."
    npm run build

    echo "  [4/4] verify version..."
    cat dist/version.json

    echo ""
    echo "✅ Frontend deployed!"
}

# ── Run ────────────────────────────────────────────

case "$TARGET" in
    backend)
        deploy_backend
        ;;
    frontend)
        deploy_frontend
        ;;
    *)
        echo "❌ Unknown target: $TARGET"
        echo "Usage: bash deploy.sh [backend|frontend]"
        exit 1
        ;;
esac

echo ""
echo "Deploy finished at $(date '+%Y-%m-%d %H:%M:%S')"
