#!/bin/bash
# Скрипт деплоя Midnight Collective на GitHub

REPO_URL="https://github.com/egorasus/midnight-collective.git"
LOCAL_DIR="$HOME/midnight-collective"

echo "🌙 Midnight Collective — деплой"
echo ""

# Если папка уже есть — просто пушим
if [ -d "$LOCAL_DIR/.git" ]; then
  cd "$LOCAL_DIR"
  git add .
  git commit -m "Update $(date '+%Y-%m-%d %H:%M')"
  git push origin main
  echo ""
  echo "✅ Запушено! Amvera задеплоит сайт через ~1 минуту."
  exit 0
fi

# Первый запуск — создаём репо
echo "Первый запуск — инициализируем репо..."
mkdir -p "$LOCAL_DIR"

# Копируем файлы из Downloads (где лежат скачанные файлы)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cp -r "$SCRIPT_DIR"/* "$LOCAL_DIR/" 2>/dev/null || true

cd "$LOCAL_DIR"
git init
git branch -M main
git remote add origin "$REPO_URL"
git add .
git commit -m "Initial commit — Midnight Collective"
git push -u origin main

echo ""
echo "✅ Первый деплой завершён!"
echo "Теперь настрой Amvera, чтобы она смотрела на этот репо."
