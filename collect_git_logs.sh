#!/bin/bash

# Set up directories
REPO_PATH=$1
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

# Create dated directory for this export
EXPORT_DIR="$SCRIPT_DIR/$LOG_DIR/$DATE/Logs"
mkdir -p "$EXPORT_DIR"

echo "Collecting git logs for repository at $REPO_PATH..."

# 1. Commit History
echo "Extracting commit history..."
git log --full-history --all --pretty=format:"%h,%an,%ae,%ad,%s" > "$EXPORT_DIR/commit_history.csv"
git log --full-history --all --patch > "$EXPORT_DIR/commit_history_full.txt"
git log --stat --pretty=format:"%h,%an,%ae,%ad,%s" > "$EXPORT_DIR/commit_history_stats.csv"

# 2. Branch Information
echo "Extracting branch information..."
git branch -av > "$EXPORT_DIR/branch_list.txt"
git show-branch --all > "$EXPORT_DIR/branch_relationships.txt"
git reflog --all > "$EXPORT_DIR/branch_history_complete.txt"

# 3. Merge Information
echo "Extracting merge history..."
git log --merges --pretty=format:"%h,%an,%ae,%ad,%s" > "$EXPORT_DIR/merge_history.csv"
git log --merges --patch > "$EXPORT_DIR/merge_details.txt"

# 4. Developer Contributions
echo "Extracting developer contributions..."
git shortlog -sn --all > "$EXPORT_DIR/author_commit_counts.txt"
git log --pretty=format:"%an,%ae" | sort | uniq -c > "$EXPORT_DIR/author_details.csv"

# Get contributions for each author
mkdir -p "$EXPORT_DIR/author_details"
git log --pretty=format:"%an" | sort -u | while read -r author; do
    clean_name=$(echo "$author" | tr ' ' '_')
        git log --author="$author" --pretty=tformat: --numstat > "$EXPORT_DIR/author_details/${clean_name}_changes.txt"
done

# 5. Project Timeline
echo "Creating project timeline..."
git log --pretty=format:"%h,%an,%ad,%s" --date=short --reverse > "$EXPORT_DIR/project_timeline.csv"

# 6. File History
echo "Collecting file history..."
mkdir -p "$EXPORT_DIR/file_history"
git ls-files | while read -r file; do
    clean_name=$(echo "$file" | tr '/' '_')
        git log --follow --patch -- "$file" > "$EXPORT_DIR/file_history/${clean_name}_history.txt"
done

# Create metadata file
echo "Creating metadata..."
{
	    echo "Repository: $REPO_PATH"
	        echo "Export Date: $DATE"
		    echo "First Commit: $(git log --reverse --pretty=format:"%ad" | head -1)"
		        echo "Last Commit: $(git log --pretty=format:"%ad" | head -1)"
			    echo "Total Commits: $(git rev-list --all --count)"
			        echo "Total Authors: $(git log --pretty=format:"%an" | sort -u | wc -l)"
				    echo "Total Branches: $(git branch -a | wc -l)"
			    } > "$EXPORT_DIR/metadata.txt"

			    echo "Log collection complete. Files saved in $EXPORT_DIR"
