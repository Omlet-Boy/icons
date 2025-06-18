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

    # Get image dimensions
    dimensions=$(identify -format "%w %h" "$image")
    width=$(echo "$dimensions" | cut -d' ' -f1)
    height=$(echo "$dimensions" | cut -d' ' -f2)

    # Determine which side is smaller and scale accordingly
    if [ "$width" -lt "$height" ]; then
        resizeArg="40x" # Make width 40px
    else
        resizeArg="x40" # Make height 40px
    fi

    # Resize while maintaining aspect ratio and preventing smaller side < 40px
    convert "$image" -resize "$resizeArg" -quality "$quality" "$outputPath"
    echo "Resized $image"
done

# Copy changed SVGs
echo "$changed_files" | grep "^svgs/.*\.svg$" | while read -r svg; do
    filename=$(basename "$svg")
    cp "$svg" "$outputDir/$filename"
    echo "Copied $filename"
done

echo "Icon processing completed!"
