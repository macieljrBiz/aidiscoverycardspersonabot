# Azure Deployment Guide

This document provides step-by-step instructions for deploying the Persona Bot to Azure.

## Quick Deploy to Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F%5BYOUR_USERNAME%5D%2F%5BYOUR_REPO%5D%2Fmain%2Fdeploy%2Fazuredeploy.json)

> **Note**: Replace `[YOUR_USERNAME]` and `[YOUR_REPO]` in the button URL above with your actual GitHub username and repository name.

Click the "Deploy to Azure" button above for a one-click deployment experience. This will:
- Create all required Azure resources (App Service, OpenAI, etc.)
- Configure Managed Identity authentication
- Deploy the application code
- Set up proper RBAC permissions

## Prerequisites

1. **Azure Subscription** - You need an active Azure subscription
2. **Azure CLI** (for manual deployment) - [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

## Local Development Setup

### Quick Setup (Recommended)

We provide automated setup scripts to configure local development:

**For Windows (PowerShell):**
```powershell
cd deploy
.\setup-local-dev.ps1
```

**For macOS/Linux (Bash):**
```bash
cd deploy
chmod +x setup-local-dev.sh
./setup-local-dev.sh
```

These scripts will:
- Verify Azure CLI installation and login status
- Prompt for your Azure OpenAI resource details
- Assign the necessary permissions to your user account
- Create a `.env` file with the correct configuration

### Manual Setup

If you prefer to set up manually, follow these steps:

### Authentication Setup for Local Development

The application uses Managed Identity for both local development and production. For local development, you'll use your Azure user account credentials via `az login`.

#### Step 1: Login to Azure
```bash
az login
```

#### Step 2: Set Your Subscription
```bash
az account set --subscription "your-subscription-id"
```

#### Step 3: Grant Your User Account Access to Azure OpenAI

You need to assign the "Cognitive Services OpenAI User" role to your user account for the Azure OpenAI resource:

```bash
# Replace with your actual values
SUBSCRIPTION_ID="your-subscription-id"
RESOURCE_GROUP="your-resource-group"
OPENAI_RESOURCE_NAME="your-openai-resource-name"
USER_EMAIL="your-email@domain.com"

# Get your user's object ID
USER_OBJECT_ID=$(az ad user show --id $USER_EMAIL --query id -o tsv)

# Assign the Cognitive Services OpenAI User role
az role assignment create \
  --assignee $USER_OBJECT_ID \
  --role "Cognitive Services OpenAI User" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.CognitiveServices/accounts/$OPENAI_RESOURCE_NAME"
```

#### Alternative: Using Azure Portal
1. Navigate to your Azure OpenAI resource in the Azure Portal
2. Go to **Access control (IAM)**
3. Click **+ Add** → **Add role assignment**
4. Select **Cognitive Services OpenAI User** role
5. Choose **User, group, or service principal**
6. Search for and select your user account
7. Click **Review + assign**

#### Step 4: Verify Access
```bash
# Test that you can access the OpenAI resource
az cognitiveservices account show \
  --name $OPENAI_RESOURCE_NAME \
  --resource-group $RESOURCE_GROUP
```

## Manual Deployment

If you prefer to deploy manually using Azure CLI:

### 1. Login to Azure

```bash
az login
```

### 2. Set Your Subscription

```bash
az account set --subscription "your-subscription-id"
```

### 3. Create Resource Group

```bash
az group create --name "rg-persona-bot-dev" --location "eastus2"
```

### 4. Deploy Infrastructure

```bash
az deployment group create \
  --resource-group "rg-persona-bot-dev" \
  --template-file "deploy/azuredeploy.json" \
  --parameters "@deploy/azuredeploy.parameters.json"
```

### 5. Deploy Application Code

```bash
# Create a zip file of your application
# PowerShell (Windows)
Compress-Archive -Path "bots", "templates", "webapp" -DestinationPath "persona-bot.zip"

# Bash (macOS/Linux)
zip -r persona-bot.zip bots templates webapp

# Deploy the zip file
az webapp deployment source config-zip \
  --resource-group "rg-persona-bot-dev" \
  --name "persona-bot-dev-[uniqueSuffix]-webapp" \
  --src "persona-bot.zip"
```

## Detailed Deployment Information

### Infrastructure Components

The ARM template deploys:

- **Azure OpenAI** - Cognitive Services account with GPT-4o-mini deployment
- **App Service Plan** - Linux-based hosting plan (Python 3.11)
- **Web App** - Streamlit application with System Assigned Managed Identity
- **RBAC Role Assignment** - Grants the web app "Cognitive Services OpenAI User" permissions
- **Configuration** - Environment variables for OpenAI integration (no API keys stored)

### Configuration Parameters

You can customize the deployment by modifying `deploy/azuredeploy.parameters.json`:

```json
{
  "environmentName": { "value": "dev" },        // Environment: dev, test, prod
  "location": { "value": "eastus2" },           // Azure region
  "appServicePlanSku": { "value": "B1" },       // App Service plan size
  "openAiModelName": { "value": "gpt-4o-mini" } // OpenAI model
}
```

### Environment Variables

The following environment variables are automatically configured:

- `AZURE_OPENAI_ENDPOINT` - OpenAI service endpoint
- `AZURE_OPENAI_API_VERSION` - OpenAI API version
- `AZURE_OPENAI_DEPLOYMENT_NAME` - Model deployment name

**Note:** No API keys are stored or managed - the application uses Managed Identity for secure authentication.

## Alternative Deployment Methods

### Using Azure Portal

1. Use the "Deploy to Azure" button above for the easiest deployment experience
2. Alternatively, upload the ARM template (`azuredeploy.json`) manually to Azure Portal
3. Fill in the required parameters
4. Deploy the infrastructure
5. Use Azure Portal to deploy the application code

### Using GitHub Actions

Create a GitHub Actions workflow for automated deployment:

```yaml
name: Deploy Persona Bot
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Deploy Infrastructure
        run: |
          az deployment group create \
            --resource-group ${{ secrets.RESOURCE_GROUP }} \
            --template-file deploy/azuredeploy.json \
            --parameters "@deploy/azuredeploy.parameters.json"
      
      - name: Deploy App
        run: |
          zip -r persona-bot.zip bots templates webapp
          az webapp deployment source config-zip \
            --resource-group ${{ secrets.RESOURCE_GROUP }} \
            --name ${{ secrets.WEB_APP_NAME }} \
            --src persona-bot.zip
```

## Troubleshooting

### Common Issues

1. **OpenAI Service Not Available**
   - Check if Azure OpenAI is available in your region
   - Verify your subscription has access to Azure OpenAI

2. **Deployment Fails**
   - Check resource naming conflicts
   - Verify subscription quotas
   - Review deployment logs in Azure Portal

3. **Application Not Starting**
   - Check App Service logs
   - Verify environment variables are set
   - Ensure all dependencies are installed

### Monitoring

Monitor your deployment using:

- **Azure Portal** - View resource health and metrics
- **App Service Logs** - Check application logs
- **Application Insights** - Monitor performance (optional)

## Cost Considerations

- **App Service Plan B1**: ~$13/month
- **Azure OpenAI**: Pay-per-token usage
- **Storage**: Minimal cost for configuration files

## Security Recommendations

1. **Managed Identity** - ✅ Already implemented for secure authentication
2. **Network Security** - Restrict access using VNet integration
3. **RBAC Permissions** - ✅ Least privilege access already configured
4. **HTTPS Only** - ✅ Enabled by default
5. **Monitoring** - Enable Application Insights for audit logging

## Scaling

- **App Service**: Scale up/out based on usage
- **OpenAI**: Automatically scales with usage
- **Load Testing**: Test with expected user load

## Support

For issues with:
- **Azure Services**: Use Azure Support
- **Application Code**: Check GitHub issues
- **ARM Templates**: Reference Azure documentation