#!/usr/bin/env bash

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <source_directory> [output_file]"
    exit 1
fi

SOURCE_DIR="$1"
OUTPUT_FILE="${2:-merged_output.txt}"

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: '$SOURCE_DIR' is not a directory."
    exit 1
fi

: > "$OUTPUT_FILE"

find "$SOURCE_DIR" -maxdepth 1 -type f -print0 | sort -z | while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    echo "--- $filename ---" >> "$OUTPUT_FILE"
    cat "$file" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
done

echo "Merged files into '$OUTPUT_FILE'."
