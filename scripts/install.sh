#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="damage-report-loop"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
MODE="user"
PROJECT_ROOT=""

usage() {
  cat <<EOF
Usage:
  ./scripts/install.sh
  ./scripts/install.sh --user
  ./scripts/install.sh --project /path/to/project

Installs ${SKILL_NAME} as a real directory so Cursor can discover SKILL.md reliably.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)
      MODE="user"
      shift
      ;;
    --project)
      MODE="project"
      PROJECT_ROOT="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "$MODE" == "project" ]]; then
  if [[ -z "$PROJECT_ROOT" ]]; then
    echo "Error: --project requires a project path." >&2
    exit 2
  fi
  TARGET_DIR="$(cd "$PROJECT_ROOT" && pwd -P)/.cursor/skills"
else
  TARGET_DIR="$HOME/.cursor/skills"
fi

TARGET="$TARGET_DIR/$SKILL_NAME"
mkdir -p "$TARGET_DIR"

if [[ -d "$TARGET" ]] && [[ "$(cd "$TARGET" && pwd -P)" == "$ROOT" ]]; then
  echo "Already installed: $TARGET"
  echo "Restart Cursor or reload the window, then invoke /$SKILL_NAME."
  exit 0
fi

rm -rf "$TARGET"
mkdir -p "$TARGET"
cp -R "$ROOT/." "$TARGET/"
rm -rf "$TARGET/.git"

if [[ ! -f "$TARGET/SKILL.md" ]]; then
  echo "Error: installation completed without $TARGET/SKILL.md" >&2
  exit 1
fi

echo "Installed $SKILL_NAME -> $TARGET"
echo "Restart Cursor or reload the window, then invoke /$SKILL_NAME."
echo "Optional hook instructions: references/HOOK_SETUP.md"
