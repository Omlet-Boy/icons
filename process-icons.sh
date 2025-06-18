#!/bin/bash

set -e

# --- CONFIGURABLE VARIABLES ---
images_dir="./original-images"
svgs_dir="./original-svgs"
output_dir="./icons"
min_size="40"
quality="90"

# --- PREP ---
mkdir -p "$output_dir"

# --- STEP 1: List changed files in last commit ---
changed_files=$(git diff --name-only HEAD~1 HEAD)

# --- STEP 2: Delete stale icons (those not in source dirs) ---
valid_sources=()
while IFS= read -r f; do
    valid_sources+=("$(basename "$f")")
done < <(find "$images_dir" -type f -name '*.png')

while IFS= read -r f; do
    valid_sources+=("$(basename "$f")")
done < <(find "$svgs_dir" -type f -name '*.svg')

for icon in "$output_dir"/*; do
    icon_name=$(basename "$icon")
    if [[ ! " ${valid_sources[*]} " =~ " ${icon_name} " ]]; then
        echo "Deleting stale icon: $icon_name"
        rm -f "$icon"
    fi
done

# --- STEP 3: Resize PNGs (if new or changed) ---
for image in "$images_dir"/*.png; do
    rel_path="${image#./}"
    filename=$(basename "$image")
    output_path="$output_dir/$filename"

    if [[ ! -f "$output_path" ]] || echo "$changed_files" | grep -q "^$rel_path$"; then
        dimensions=$(magick identify -format "%w %h" "$image")
        width=$(echo "$dimensions" | cut -d' ' -f1)
        height=$(echo "$dimensions" | cut -d' ' -f2)

        if [ "$width" -lt "$height" ]; then
            resize_arg="${min_size}x"
        else
            resize_arg="x${min_size}"
        fi

        magick "$image" -resize "$resize_arg" -quality "$quality" "$output_path"
        echo "Resized $filename"
    fi
done

# --- STEP 4: Copy SVGs (if new or changed) ---
for svg in "$svgs_dir"/*.svg; do
    rel_path="${svg#./}"
    filename=$(basename "$svg")
    output_path="$output_dir/$filename"

    if [[ ! -f "$output_path" ]] || echo "$changed_files" | grep -q "^$rel_path$"; then
        cp "$svg" "$output_path"
        echo "Copied $filename"
    fi
done

# --- STEP 5: Git commit & push if changes detected ---
git add "$output_dir"

if git diff --cached --quiet; then
    echo "No changes in $output_dir to commit."
else
    echo "Changes detected in $output_dir — committing..."
    git config --global user.name 'github-actions[bot]'
    git config --global user.email 'github-actions[bot]@users.noreply.github.com'
    git commit -m 'Update icons'
    git push
fi

echo "Icon processing completed!"
