#!/usr/bin/env bash
set -euo pipefail

gh workflow run pages.yml --repo alexasa79/alchemy-lang --ref main
