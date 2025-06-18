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

# --- STEP 3: Resize PNGs if output doesn't exist OR source was changed ---

for image in "$imagesDir"/*.png; do
    rel_path="${image#./}"
    filename=$(basename "$image")
    outputPath="$outputDir/$filename"

    if [[ ! -f "$outputPath" ]] || echo "$changed_files" | grep -q "^$rel_path$"; then
        dimensions=$(identify -format "%w %h" "$image")
        width=$(echo "$dimensions" | cut -d' ' -f1)
        height=$(echo "$dimensions" | cut -d' ' -f2)

        if [ "$width" -lt "$height" ]; then
            resizeArg="40x"
        else
            resizeArg="x40"
        fi

        magick mogrify "$image" -resize "$resizeArg" -quality "$quality" "$outputPath"
        echo "Resized $filename"
        changes_made=true
    fi
done

# --- STEP 4: Copy SVGs if output doesn't exist OR source was changed ---

for svg in "$svgsDir"/*.svg; do
    rel_path="${svg#./}"
    filename=$(basename "$svg")
    outputPath="$outputDir/$filename"

    if [[ ! -f "$outputPath" ]] || echo "$changed_files" | grep -q "^$rel_path$"; then
        cp "$svg" "$outputPath"
        echo "Copied $filename"
        changes_made=true
    fi
done

# --- STEP 5: Commit and push if changes made ---

git add ./icons

if git diff --cached --quiet; then
    echo "No changes in ./icons to commit."
else
    echo "Changes detected in ./icons — committing..."
    git config --global user.name 'github-actions[bot]'
    git config --global user.email 'github-actions[bot]@users.noreply.github.com'
    git commit -m 'Update icons'
    git push
fi

echo "Icon processing completed!"
