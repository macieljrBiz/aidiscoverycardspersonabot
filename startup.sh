#!/bin/bash

# Azure App Service Startup Script for Streamlit
# This script starts the Streamlit application from the repository root

# Change to the application directory
cd /home/site/wwwroot

# Install dependencies if needed (Azure should do this automatically, but as fallback)
if [ ! -d ".venv" ]; then
    echo "Installing dependencies..."
    pip install -r requirements.txt
fi

# Start Streamlit
# Note: Azure App Service expects the app to listen on port 8000 by default
echo "Starting Streamlit application..."
python -m streamlit run webapp/app.py \
    --server.port=8000 \
    --server.address=0.0.0.0 \
    --server.headless=true \
    --browser.serverAddress=0.0.0.0 \
    --browser.gatherUsageStats=false \
    --server.enableCORS=false \
    --server.enableXsrfProtection=true