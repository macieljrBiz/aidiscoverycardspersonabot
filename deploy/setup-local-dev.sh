#!/bin/bash

# Local Development Setup Script for Persona Bot
# This script helps set up local development permissions for Azure OpenAI

set -e

echo "🤖 Persona Bot - Local Development Setup"
echo "========================================"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first:"
    echo "   https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if user is logged in
if ! az account show &> /dev/null; then
    echo "🔐 Please login to Azure first:"
    az login
fi

# Get current subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
echo "📋 Current subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

# Prompt for resource details
echo ""
echo "Please provide the following information:"
read -p "📧 Your Azure user email: " USER_EMAIL
read -p "🏢 Resource group name: " RESOURCE_GROUP
read -p "🧠 Azure OpenAI resource name: " OPENAI_RESOURCE_NAME

echo ""
echo "🔍 Validating inputs..."

# Get user object ID
USER_OBJECT_ID=$(az ad user show --id "$USER_EMAIL" --query id -o tsv 2>/dev/null) || {
    echo "❌ Error: Could not find user with email $USER_EMAIL"
    exit 1
}

echo "✅ Found user: $USER_EMAIL (ID: $USER_OBJECT_ID)"

# Check if resource group exists
if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    echo "❌ Error: Resource group '$RESOURCE_GROUP' does not exist"
    exit 1
fi

echo "✅ Found resource group: $RESOURCE_GROUP"

# Check if OpenAI resource exists
if ! az cognitiveservices account show --name "$OPENAI_RESOURCE_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    echo "❌ Error: Azure OpenAI resource '$OPENAI_RESOURCE_NAME' does not exist in resource group '$RESOURCE_GROUP'"
    exit 1
fi

echo "✅ Found Azure OpenAI resource: $OPENAI_RESOURCE_NAME"

# Create role assignment
echo ""
echo "🔑 Assigning 'Cognitive Services OpenAI User' role..."

RESOURCE_SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.CognitiveServices/accounts/$OPENAI_RESOURCE_NAME"

# Check if role assignment already exists
EXISTING_ASSIGNMENT=$(az role assignment list --assignee "$USER_OBJECT_ID" --scope "$RESOURCE_SCOPE" --role "Cognitive Services OpenAI User" --query "[0].id" -o tsv 2>/dev/null)

if [ ! -z "$EXISTING_ASSIGNMENT" ]; then
    echo "ℹ️  Role assignment already exists for $USER_EMAIL"
else
    if az role assignment create \
        --assignee "$USER_OBJECT_ID" \
        --role "Cognitive Services OpenAI User" \
        --scope "$RESOURCE_SCOPE" &> /dev/null; then
        echo "✅ Successfully assigned 'Cognitive Services OpenAI User' role to $USER_EMAIL"
        
        # Also assign at the resource group level as a fallback (sometimes needed for certain operations)
        RG_SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
        if az role assignment create \
            --assignee "$USER_OBJECT_ID" \
            --role "Cognitive Services OpenAI User" \
            --scope "$RG_SCOPE" &> /dev/null; then
            echo "✅ Also assigned role at resource group level"
        else
            echo "ℹ️  Resource group level assignment may already exist"
        fi
        
        echo ""
        echo "⏳ Waiting for role assignment to propagate (30 seconds)..."
        sleep 30
        
    else
        echo "❌ Failed to assign role. Please manually assign the role using Azure Portal:"
        echo "1. Go to Azure Portal > $OPENAI_RESOURCE_NAME > Access control (IAM)"
        echo "2. Click 'Add role assignment'"
        echo "3. Select 'Cognitive Services OpenAI User' role"
        echo "4. Assign to: $USER_EMAIL"
        exit 1
    fi
fi

# Get OpenAI endpoint
OPENAI_ENDPOINT=$(az cognitiveservices account show \
    --name "$OPENAI_RESOURCE_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query properties.endpoint -o tsv)

# Get available deployments
echo ""
echo "🚀 Checking available deployments..."

DEPLOYMENTS=$(az cognitiveservices account deployment list \
    --name "$OPENAI_RESOURCE_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "[].name" -o tsv 2>/dev/null) || {
    echo "⚠️  Could not retrieve deployments. Using default 'gpt-4o-mini'"
    SELECTED_DEPLOYMENT="gpt-4o-mini"
}

if [ ! -z "$DEPLOYMENTS" ]; then
    # Convert to array
    IFS=$'\n' read -d '' -r -a DEPLOYMENT_ARRAY <<< "$DEPLOYMENTS" || true
    
    if [ ${#DEPLOYMENT_ARRAY[@]} -eq 1 ]; then
        SELECTED_DEPLOYMENT="${DEPLOYMENT_ARRAY[0]}"
        echo "✅ Found deployment: $SELECTED_DEPLOYMENT"
    else
        echo "ℹ️  Multiple deployments found:"
        for i in "${!DEPLOYMENT_ARRAY[@]}"; do
            echo "   $((i + 1)). ${DEPLOYMENT_ARRAY[$i]}"
        done
        
        while true; do
            read -p "🎯 Choose deployment (1-${#DEPLOYMENT_ARRAY[@]}): " CHOICE
            if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le ${#DEPLOYMENT_ARRAY[@]} ]; then
                SELECTED_DEPLOYMENT="${DEPLOYMENT_ARRAY[$((CHOICE - 1))]}"
                echo "✅ Selected deployment: $SELECTED_DEPLOYMENT"
                break
            else
                echo "❌ Invalid choice. Please enter a number between 1 and ${#DEPLOYMENT_ARRAY[@]}"
            fi
        done
    fi
fi

echo ""
echo "📝 Creating .env file..."

# Create .env file
cat > ../webapp/.env << EOF
# Azure OpenAI Configuration (Managed Identity)
# Generated by setup script on $(date)

AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT
AZURE_OPENAI_API_VERSION=2024-08-01-preview
AZURE_OPENAI_DEPLOYMENT_NAME=$SELECTED_DEPLOYMENT
EOF

echo "✅ Created .env file at webapp/.env"

# Clear Azure CLI token cache to ensure fresh tokens with new permissions
echo ""
echo "🔄 Clearing Azure CLI token cache to refresh permissions..."
if az account clear && az login &> /dev/null; then
    echo "✅ Successfully refreshed Azure CLI authentication"
else
    echo "⚠️  Could not refresh Azure CLI cache automatically"
    echo "📋 Please run 'az logout' and then 'az login' to refresh your tokens"
fi

echo ""
echo "🎉 Setup complete! You can now run the application locally:"
echo ""
echo "   cd webapp"
echo "   pip install -r requirements.txt"
echo "   streamlit run app.py"
echo ""
echo "🔧 TROUBLESHOOTING: If you still get permission errors:"
echo "1. Wait 5-10 minutes for Azure role assignments to propagate"
echo "2. Run: az logout && az login"
echo "3. Verify your role assignment in Azure Portal:"
echo "   Portal > $OPENAI_RESOURCE_NAME > Access control (IAM) > Role assignments"
echo "4. Look for '$USER_EMAIL' with 'Cognitive Services OpenAI User' role"
echo ""
echo "📚 For more information, see the README.md file"