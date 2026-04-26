#!/bin/bash
cd ~/midnight-collective

echo "📥 Скачиваем актуальные данные с GitHub..."
curl -s "https://raw.githubusercontent.com/egorasus/midnight-collective/main/data/projects.json?t=$(date +%s)" > data/projects.json.tmp
curl -s "https://raw.githubusercontent.com/egorasus/midnight-collective/main/data/settings.json?t=$(date +%s)" > data/settings.json.tmp

# Проверяем что скачалось нормально (не 404)
if grep -q "Not Found" data/projects.json.tmp; then
  echo "⚠️  projects.json на GitHub нет, используем локальный"
else
  mv data/projects.json.tmp data/projects.json
fi

if grep -q "Not Found" data/settings.json.tmp; then
  echo "⚠️  settings.json на GitHub нет, используем локальный"
else
  mv data/settings.json.tmp data/settings.json
fi

rm -f data/*.tmp

git add .
git commit -m "${1:-update}" 2>/dev/null || echo "Нечего коммитить"
git push origin main --force
git push amvera main:master --force
echo "✅ Задеплоено"
