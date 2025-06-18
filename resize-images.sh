#!/bin/bash

# Define input and output directories
imagesDir="./original-images"
svgsDir="./svgs"
outputDir="./icons"
size="40"
quality="90"

# Create output directory if it doesn't exist
mkdir -p "$outputDir"

# Get list of changed .png and .svg files
changed_files=$(git diff --name-only HEAD~1 HEAD)

# Process changed PNGs
echo "$changed_files" | grep "^original-images/.*\.png$" | while read -r image; do
    filename=$(basename "$image")
    outputPath="$outputDir/$filename"

    convert "$image" -resize "${size}x" -quality "$quality" "$outputPath"
    echo "Resized $image..."
done

# Copy changed SVGs
echo "$changed_files" | grep "^svgs/.*\.svg$" | while read -r svg; do
    filename=$(basename "$svg")
    cp "$svg" "$outputDir/$filename"
    echo "Copied SVG: $filename"
done

echo "Selective image processing completed!"
