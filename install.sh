#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="solana-incident-skill"
TARGET_DIR="${HOME}/.claude/skills/${SKILL_NAME}"

echo "Installing ${SKILL_NAME}..."

mkdir -p "${HOME}/.claude/skills"
rm -rf "${TARGET_DIR}"
mkdir -p "${TARGET_DIR}"

cp -R skill "${TARGET_DIR}/"
cp -R commands "${TARGET_DIR}/"
cp -R agents "${TARGET_DIR}/"
cp README.md "${TARGET_DIR}/"
cp install.sh "${TARGET_DIR}/"

if [ ! -f "${TARGET_DIR}/skill/SKILL.md" ]; then
  echo "Installation failed: skill/SKILL.md not found"
  exit 1
fi

echo "Installed to ${TARGET_DIR}"
echo "Restart Claude Code and start a new session to load the skill."