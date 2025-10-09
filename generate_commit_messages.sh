#!/bin/bash
set -e

# Script to generate a mapping of commit hashes to commit messages from the rl-tools submodule

OUTPUT_FILE="commit_messages.json"

echo "Generating commit message mapping from rl-tools submodule..."

# Check if rl-tools directory exists
if [ ! -d "rl-tools" ]; then
    echo "Error: rl-tools directory not found"
    exit 1
fi

# Use Python to properly escape JSON
python3 << 'PYTHON_SCRIPT' > "${OUTPUT_FILE}"
import subprocess
import json
import sys

try:
    # Get all commits from the rl-tools submodule
    result = subprocess.run(
        ['git', '-C', 'rl-tools', 'log', '--all', '--abbrev=7', '--pretty=format:%h%x00%s'],
        capture_output=True,
        text=True,
        check=True
    )
    
    # Parse the output
    commits = {}
    for line in result.stdout.strip().split('\n'):
        if not line:
            continue
        parts = line.split('\x00', 1)
        if len(parts) == 2:
            hash_val, message = parts
            commits[hash_val] = message
    
    # Output as properly formatted JSON
    print(json.dumps(commits, indent=2, ensure_ascii=False))
    
except subprocess.CalledProcessError as e:
    print(f"Error running git command: {e}", file=sys.stderr)
    print("{}", file=sys.stdout)  # Output empty JSON on error
    sys.exit(1)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    print("{}", file=sys.stdout)  # Output empty JSON on error
    sys.exit(1)
PYTHON_SCRIPT

# Count number of commits
COMMIT_COUNT=$(grep -c '":' "${OUTPUT_FILE}" || echo "0")

echo "Generated ${OUTPUT_FILE} with ${COMMIT_COUNT} commits"
echo "File size: $(du -h ${OUTPUT_FILE} | cut -f1)"

