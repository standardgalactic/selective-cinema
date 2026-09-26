#!/usr/bin/env bash
set -euo pipefail

REPO="standardgalactic/selective-cinema"
DIR="${1:-$HOME/new-repos/selective-cinema}"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

command -v git >/dev/null 2>&1 || die "git not found"
command -v gh  >/dev/null 2>&1 || die "GitHub CLI (gh) not found"

[[ -d "$DIR/.git" ]] || die "not a Git repository: $DIR"

cd "$DIR"

echo "Repository:"
echo "  $DIR"
echo

# Make sure GitHub CLI is authenticated.
gh auth status

# Use main consistently.
git branch -M main

# Stage the intended repository contents.
git add .

echo
echo "Staged snapshot:"
git status --short
echo
git diff --cached --stat

# Commit only if there is something staged.
if ! git diff --cached --quiet; then
    git commit -m "Initial Selective Cinema manuscript"
else
    echo "No uncommitted changes; using existing commit."
fi

# A repository needs at least one commit before publishing.
git rev-parse --verify HEAD >/dev/null 2>&1 ||
    die "repository has no commit"

# Refuse to overwrite an existing origin.
if git remote get-url origin >/dev/null 2>&1; then
    echo
    echo "Existing origin:"
    git remote get-url origin
    die "origin already exists; inspect it before publishing"
fi

# Refuse to create over an existing GitHub repository.
if gh repo view "$REPO" >/dev/null 2>&1; then
    die "GitHub repository already exists: $REPO"
fi

echo
echo "Creating public GitHub repository:"
echo "  $REPO"

gh repo create "$REPO" \
    --public \
    --source=. \
    --remote=origin

echo
echo "Remote:"
git remote -v

echo
echo "Pushing main..."
git push -u origin main

echo
echo "============================================================"
echo "Published successfully"
echo "============================================================"
echo
gh repo view "$REPO"
echo
git status
