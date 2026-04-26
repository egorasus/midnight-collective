#!/bin/bash
cd ~/midnight-collective
git add .
git commit -m "${1:-update}"
git push origin main --force
git push amvera main:master --force
echo "✅ Задеплоено"
