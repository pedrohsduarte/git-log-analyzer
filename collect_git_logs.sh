#!/bin/bash

# Parse command line arguments
LAST_COMMIT=""
REPO_PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --last-commit-id)
            LAST_COMMIT="$2"
            shift 2
            ;;
        *)
            REPO_PATH="$1"
            shift
            ;;
    esac
done

# Validate required arguments
if [ -z "$REPO_PATH" ]; then
    echo "Error: Repository path is required"
    echo "Usage: $0 [--last-commit-id <hash>] <repository-path>"
    exit 1
fi

# Set up directories
LOG_DIR="Commit Logs"
DATE=$(date +%Y%m%d)
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

mkdir -p "$LOG_DIR"
cd "$REPO_PATH" || exit

# Check if it is a git repository
if [ ! -d ".git" ]; then
    echo "Error: Not a git repository"
    exit 1
fi

# Validate commit hash if provided
if [ -n "$LAST_COMMIT" ]; then
    if ! git rev-parse --verify "$LAST_COMMIT" >/dev/null 2>&1; then
        echo "Error: Invalid commit hash"
        exit 1
    fi
fi

# Create revision range based on last commit
REV_RANGE=""
if [ -n "$LAST_COMMIT" ]; then
    REV_RANGE="$LAST_COMMIT"
else
    REV_RANGE="HEAD"
fi

# Create dated directory for this export
EXPORT_DIR="$SCRIPT_DIR/$LOG_DIR/$DATE/Logs"
mkdir -p "$EXPORT_DIR"

echo "Collecting git logs for repository at $REPO_PATH..."
if [ -n "$LAST_COMMIT" ]; then
    echo "Using commits up to: $LAST_COMMIT"
fi

# 1. Commit History
echo "Extracting commit history..."
git log --full-history "$REV_RANGE" --pretty=format:"%h,%an,%ae,%ad,%s" > "$EXPORT_DIR/commit_history.csv"
git log --full-history "$REV_RANGE" --patch > "$EXPORT_DIR/commit_history_full.txt"
git log --stat "$REV_RANGE" --pretty=format:"%h,%an,%ae,%ad,%s" > "$EXPORT_DIR/commit_history_stats.csv"

# 2. Branch Information
echo "Extracting branch information..."
git branch -av > "$EXPORT_DIR/branch_list.txt"
git show-branch --all > "$EXPORT_DIR/branch_relationships.txt"
git reflog --date=local "$REV_RANGE" > "$EXPORT_DIR/branch_history_complete.txt"

# 3. Merge Information
echo "Extracting merge history..."
git log --merges "$REV_RANGE" --pretty=format:"%h,%an,%ae,%ad,%s" > "$EXPORT_DIR/merge_history.csv"
git log --merges "$REV_RANGE" --patch > "$EXPORT_DIR/merge_details.txt"

# 4. Developer Contributions
echo "Extracting developer contributions..."
git shortlog -sn "$REV_RANGE" > "$EXPORT_DIR/author_commit_counts.txt"
git log "$REV_RANGE" --pretty=format:"%an,%ae" | sort | uniq -c > "$EXPORT_DIR/author_details.csv"

# Get contributions for each author
mkdir -p "$EXPORT_DIR/author_details"
git log "$REV_RANGE" --pretty=format:"%an" | sort -u | while read -r author; do
    clean_name=$(echo "$author" | tr ' ' '_')
    git log "$REV_RANGE" --author="$author" --pretty=tformat: --numstat > "$EXPORT_DIR/author_details/${clean_name}_changes.txt"
done

# 5. Project Timeline
echo "Creating project timeline..."
git log "$REV_RANGE" --pretty=format:"%h,%an,%ad,%s" --date=short --reverse > "$EXPORT_DIR/project_timeline.csv"

# 6. File History
echo "Collecting file history..."
mkdir -p "$EXPORT_DIR/file_history"
git ls-files | while read -r file; do
    clean_name=$(echo "$file" | tr '/' '_')
    git log "$REV_RANGE" --follow --patch -- "$file" > "$EXPORT_DIR/file_history/${clean_name}_history.txt"
done

# Create metadata file
echo "Creating metadata..."
{
    echo "Repository: $REPO_PATH"
    echo "Export Date: $DATE"
    if [ -n "$LAST_COMMIT" ]; then
        echo "Last Commit ID: $LAST_COMMIT"
    fi
    echo "First Commit: $(git log "$REV_RANGE" --reverse --pretty=format:"%ad" | head -1)"
    echo "Last Commit: $(git log "$REV_RANGE" --pretty=format:"%ad" | head -1)"
    echo "Total Commits: $(git rev-list "$REV_RANGE" --count)"
    echo "Total Authors: $(git log "$REV_RANGE" --pretty=format:"%an" | sort -u | wc -l)"
    echo "Total Branches: $(git branch -a | wc -l)"
} > "$EXPORT_DIR/metadata.txt"

echo "Log collection complete. Files saved in $EXPORT_DIR"