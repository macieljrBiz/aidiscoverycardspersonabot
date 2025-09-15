#!/bin/bash

# Post-build script for Azure App Service deployment
# This script runs after the Python dependencies are installed

echo "Starting post-build setup..."

# Create necessary directories if they don't exist
mkdir -p /home/site/wwwroot/bots
mkdir -p /home/site/wwwroot/templates

# Copy persona configurations if they exist
if [ -d "/home/site/repository/bots" ]; then
    echo "Copying persona configurations..."
    cp -r /home/site/repository/bots/* /home/site/wwwroot/bots/
fi

# Copy templates if they exist
if [ -d "/home/site/repository/templates" ]; then
    echo "Copying prompt templates..."
    cp -r /home/site/repository/templates/* /home/site/wwwroot/templates/
fi

# Set working directory
cd /home/site/wwwroot

echo "Post-build setup completed!"