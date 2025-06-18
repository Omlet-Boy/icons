#!/bin/bash

set -e

imagesDir="./original-images"
svgsDir="./svgs"
outputDir="./icons"
size="40"
quality="90"

mkdir -p "$outputDir"

# Track changes
changes_made=false

# --- STEP 1: Get list of changed files ---
changed_files=$(git diff --name-only HEAD~1 HEAD)

# --- STEP 2: Delete icons not found in original-images/ or svgs/ ---

valid_sources=()
while IFS= read -r f; do
    valid_sources+=("$(basename "$f")")
done < <(find "$imagesDir" -type f -name '*.png')

while IFS= read -r f; do
    valid_sources+=("$(basename "$f")")
done < <(find "$svgsDir" -type f -name '*.svg')

for icon in "$outputDir"/*; do
    icon_name=$(basename "$icon")
    if [[ ! " ${valid_sources[*]} " =~ " ${icon_name} " ]]; then
        echo "Deleting stale icon: $icon_name"
        rm -f "$icon"
        changes_made=true
    fi
done

# --- STEP 3: Resize changed PNGs only ---

for image in "$imagesDir"/*.png; do
    rel_path="${image#./}"  # strip leading ./ if present
    if ! echo "$changed_files" | grep -q "^$rel_path$"; then
        continue  # skip if not in git diff
    fi

    filename=$(basename "$image")
    outputPath="$outputDir/$filename"

    dimensions=$(identify -format "%w %h" "$image")
    width=$(echo "$dimensions" | cut -d' ' -f1)
    height=$(echo "$dimensions" | cut -d' ' -f2)

    if [ "$width" -lt "$height" ]; then
        resizeArg="40x"
    else
        resizeArg="x40"
    fi

    convert "$image" -resize "$resizeArg" -quality "$quality" "$outputPath"
    echo "Resized $filename"
    changes_made=true
done

# --- STEP 4: Copy changed SVGs only ---

for svg in "$svgsDir"/*.svg; do
    rel_path="${svg#./}"
    if ! echo "$changed_files" | grep -q "^$rel_path$"; then
        continue  # skip if not in git diff
    fi

    filename=$(basename "$svg")
    outputPath="$outputDir/$filename"

    cp "$svg" "$outputPath"
    echo "Copied SVG: $filename"
    changes_made=true
done

# --- STEP 5: Commit and push if changes made ---

if [[ "$changes_made" = true ]] || [[ $(git status --porcelain ./icons) ]]; then
    echo "Changes detected in ./icons — committing..."
    git config --global user.name 'github-actions[bot]'
    git config --global user.email 'github-actions[bot]@users.noreply.github.com'
    git add ./icons
    git commit -m 'Update icons'
    git push
else
    echo "No changes to commit."
fi

echo "Icon processing completed!"
