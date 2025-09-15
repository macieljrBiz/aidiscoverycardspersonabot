# Deploy to Azure Button Setup

This guide explains how to set up and use the "Deploy to Azure" button for one-click deployment.

## Quick Setup

1. **Fork/Clone the Repository** to your GitHub account
2. **Update the Deploy Button URL** in README.md files:
   - Replace `[YOUR_USERNAME]` with your GitHub username
   - Replace `[YOUR_REPO]` with your repository name
3. **Click the Deploy Button** to start deployment

## Button URL Format

The Deploy to Azure button uses this URL format:

```
https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F[USERNAME]%2F[REPO]%2Fmain%2Fdeploy%2Fazuredeploy.json
```

## What Gets Deployed

When you click the "Deploy to Azure" button, Azure will:

1. **Load the ARM Template** from your repository
2. **Open Azure Portal** with a custom deployment form
3. **Create Resources**:
   - Resource Group (if new)
   - Azure OpenAI account with GPT-4o-mini deployment
   - App Service Plan (Linux, Python 3.11)
   - Web App with System Assigned Managed Identity
   - RBAC role assignment for secure access

## Deployment Parameters

The deployment form will prompt for:

- **Environment Name**: dev, test, prod, etc.
- **Location**: Azure region (defaults to East US 2)
- **App Service SKU**: B1, B2, S1, etc. (defaults to B1)
- **OpenAI Model**: GPT model name (defaults to gpt-4o-mini)

## Post-Deployment Steps

After the infrastructure is deployed:

1. **Deploy Application Code**:
   ```bash
   # Create application package
   zip -r persona-bot.zip bots templates webapp
   
   # Deploy to the created web app
   az webapp deployment source config-zip \
     --resource-group [YOUR_RESOURCE_GROUP] \
     --name [YOUR_WEB_APP_NAME] \
     --src persona-bot.zip
   ```

2. **Verify Deployment**:
   - Navigate to the web app URL from the deployment outputs
   - Test the persona selection and chat functionality

## Customization

To customize the deployment:

1. **Modify Parameters**: Edit `azuredeploy.parameters.json`
2. **Update Template**: Modify `azuredeploy.json` for additional resources
3. **Add Personas**: Include additional persona YAML files in the `bots/` directory

## Troubleshooting

### Common Issues:

1. **Template Not Found**: Ensure the repository is public and files are in the correct location
2. **Deployment Fails**: Check Azure subscription limits and region availability
3. **App Not Loading**: Verify application code is deployed after infrastructure

### Debug Steps:

1. **Check Deployment Logs** in Azure Portal under Resource Group > Deployments
2. **Verify App Service Logs** in the App Service resource
3. **Test Managed Identity** permissions on the OpenAI resource

## Security Notes

- **No API Keys**: The deployment uses Managed Identity for secure authentication
- **RBAC Permissions**: Least privilege access is automatically configured
- **HTTPS Only**: All traffic is encrypted by default
- **Network Security**: Consider VNet integration for additional security

## GitHub Actions Integration

For automated deployments on code changes, see the GitHub Actions workflow example in the main README.md.