#!/bin/bash

# Define input and output directories
inputDir="./original-images"
outputDir="./svgs"
size="100"
quality="100"

# Create output directory if it doesn't exist
mkdir -p "$outputDir"

# Loop through each .png file in the input directory
for image in "$inputDir"/*.png; do
    # Get the filename from the image path
    filename=$(basename "$image")
    outputPath="$outputDir/$filename"
    
    # Use magick command to resize the image to 32px width and maintain aspect ratio
    convert "$image" -resize "${size}x" -quality "$quality" "$outputPath"
    
    echo "Resized $filename"
done

echo "Image resizing completed!"
