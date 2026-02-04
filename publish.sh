#!/usr/bin/env bash
hugo -D
rsync -a --delete --exclude .git public/ ../pages/
cd ../pages
git add -A && git commit -m "publish"
git push
