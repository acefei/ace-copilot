#!/bin/bash
# Install a skill with appropriate scope (local vs global)
#
# Usage: install-skill.sh <owner/repo@skill>

set -e

if [[ -z "$1" ]]; then
    echo "Usage: $0 <owner/repo@skill>" >&2
    exit 1
fi

SKILL_PACKAGE="$1"

# Check if inside a git repository
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Not inside a git repository. Installing globally..."
    npx skills add "$SKILL_PACKAGE" -g -y
    exit 0
fi

# Find skills directory and extract parent name
GIT_ROOT=$(git rev-parse --show-toplevel)
SKILLS_DIR=$(find "$GIT_ROOT" -maxdepth 3 -type d -name "skills" 2>/dev/null | head -1)
PARENT_NAME=$(echo "$SKILLS_DIR" | grep -oE '\.(github|claude)' | head -1)

# Install based on parent directory
case "$PARENT_NAME" in
    .github)
        echo "Installing for GitHub Copilot..."
        npx skills add "$SKILL_PACKAGE" --agent github-copilot -y
        ;;
    .claude)
        echo "Installing for Claude Code..."
        npx skills add "$SKILL_PACKAGE" --agent claude-code -y
        ;;
    *)
        if [[ -n "$SKILLS_DIR" ]]; then
            echo "Installing locally..."
            npx skills add "$SKILL_PACKAGE" -y
        else
            echo "No skills directory found. Installing globally..."
            npx skills add "$SKILL_PACKAGE" -g -y
        fi
        ;;
esac
