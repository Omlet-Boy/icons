#!/bin/bash

# Define input and output directories
imagesDir="./original-images"
svgsDir="./svgs"
outputDir="./icons"
size="40"
quality="90"

# Create output directory if it doesn't exist
mkdir -p "$outputDir"

# Loop through each .png file in the input directory
for image in "$imagesDir"/*.png; do
    # Get the filename from the image path
    filename=$(basename "$image")
    outputPath="$outputDir/$filename"
    
    # Use magick command to resize the image to 32px width and maintain aspect ratio
    convert "$image" -resize "${size}x" -quality "$quality" "$outputPath"
    
    echo "Resized $filename"
done

# Copy svgs to icons folder
cp -r "$svgsDir"/* "$outputDir"/
echo "Copied SVGs to icons folder"

echo "Image resizing completed!"
