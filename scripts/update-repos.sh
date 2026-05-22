#!/usr/bin/env bash
set -euo pipefail

update_repo() {
  local dir="$1"

  if [[ -d "$dir/.git" ]]; then
    echo "Updating $dir..."
    git -C "$dir" pull --ff-only
  elif [[ -d "$dir" ]]; then
    echo "Skipping $dir: directory exists but is not a git repository."
  else
    echo "Skipping $dir: directory does not exist."
  fi
}

update_repo "music-catalog-core"
update_repo "soundloom-core"
