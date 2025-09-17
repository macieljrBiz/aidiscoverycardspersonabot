#!/bin/bash
# Post-deployment script to manually configure GitHub deployment
# Use this if the ARM template's automatic GitHub deployment fails

echo "🔧 Manual GitHub Deployment Setup"
echo "================================="

# Check if Azure CLI is available
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if user is logged in
if ! az account show &> /dev/null; then
    echo "🔐 Please login to Azure first:"
    az login
fi

# Prompt for required information
echo ""
read -p "📝 Enter your Web App name: " WEB_APP_NAME
read -p "🏢 Enter your Resource Group name: " RESOURCE_GROUP
read -p "📦 Enter repository URL [https://github.com/macieljrBiz/aidiscoverycardspersonabot]: " REPO_URL
read -p "🌿 Enter branch name [main]: " BRANCH

# Set defaults if empty
REPO_URL=${REPO_URL:-"https://github.com/macieljrBiz/aidiscoverycardspersonabot"}
BRANCH=${BRANCH:-"main"}

echo ""
echo "🚀 Configuring GitHub deployment..."
echo "   Web App: $WEB_APP_NAME"
echo "   Resource Group: $RESOURCE_GROUP" 
echo "   Repository: $REPO_URL"
echo "   Branch: $BRANCH"

# Configure source control
if az webapp deployment source config \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --repo-url "$REPO_URL" \
    --branch "$BRANCH" \
    --manual-integration; then
    
    echo ""
    echo "✅ GitHub deployment configured successfully!"
    echo "🕐 Initial deployment will take 5-10 minutes."
    echo "📊 Monitor deployment status in Azure Portal > App Service > Deployment Center"
    echo ""
    
    # Get the web app URL
    WEB_APP_URL=$(az webapp show --name "$WEB_APP_NAME" --resource-group "$RESOURCE_GROUP" --query defaultHostName -o tsv 2>/dev/null)
    if [ ! -z "$WEB_APP_URL" ]; then
        echo "🌐 Your app will be available at: https://$WEB_APP_URL"
    fi
    
else
    echo ""
    echo "❌ Failed to configure GitHub deployment."
    echo "💡 Alternative: Use Azure Portal > App Service > Deployment Center"
    echo "   - Select 'GitHub' as source"
    echo "   - Repository: $REPO_URL"
    echo "   - Branch: $BRANCH"
    echo "   - Build provider: App Service build service"
fi

echo ""
echo "📚 For more information, see: https://docs.microsoft.com/en-us/azure/app-service/deploy-continuous-deployment"