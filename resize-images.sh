#!/bin/bash

set -e

imagesDir="./original-images"
svgsDir="./svgs"
outputDir="./icons"
size="40"
quality="90"

mkdir -p "$outputDir"

# Gather all valid source image base filenames
all_sources=()
while IFS= read -r f; do
    all_sources+=("$(basename "$f")")
done < <(find "$imagesDir" -type f -name '*.png')
while IFS= read -r f; do
    all_sources+=("$(basename "$f")")
done < <(find "$svgsDir" -type f -name '*.svg')

# Delete icons that are no longer present in original-images or svgs
for icon in "$outputDir"/*; do
    icon_name=$(basename "$icon")
    if [[ ! " ${all_sources[*]} " =~ " ${icon_name} " ]]; then
        echo "Deleting stale icon: $icon_name"
        rm -f "$icon"
    fi
done

# Get list of changed files
changed_files=$(git diff --name-only HEAD~1 HEAD)

# Track if anything changed
changes_made=false

# Process new or changed PNGs
echo "$changed_files" | grep "^original-images/.*\.png$" | while read -r image; do
    filename=$(basename "$image")
    outputPath="$outputDir/$filename"

    if [[ -f "$outputPath" ]]; then
        echo "Skipping existing resized image: $filename"
        continue
    fi

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

# Copy changed SVGs
echo "$changed_files" | grep "^svgs/.*\.svg$" | while read -r svg; do
    filename=$(basename "$svg")
    dest="$outputDir/$filename"

    if [[ -f "$dest" ]]; then
        echo "Skipping existing SVG: $filename"
        continue
    fi

    cp "$svg" "$dest"
    echo "Copied SVG: $filename"
    changes_made=true
done

echo "Icon processing completed!"

# Check for actual changes in icons and commit if any
if [[ $(git status --porcelain ./icons) ]]; then
    echo "Changes detected in ./icons — committing..."
    git config --global user.name 'github-actions[bot]'
    git config --global user.email 'github-actions[bot]@users.noreply.github.com'
    git add ./icons
    git commit -m 'Update icons'
    git push
else
    echo "No changes to commit."
fi
