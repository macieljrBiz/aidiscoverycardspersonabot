# Local Development Setup Script for Persona Bot (PowerShell)
# This script helps set up local development permissions for Azure OpenAI

Write-Host "[ROBOT] Persona Bot - Local Development Setup" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Check if Azure CLI is installed
try {
    az --version | Out-Null
} catch {
    Write-Host "[X] Azure CLI is not installed. Please install it first:" -ForegroundColor Red
    Write-Host "   https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
    exit 1
}

# Check if user is logged in
try {
    az account show | Out-Null
} catch {
    Write-Host "[AUTH] Please login to Azure first:" -ForegroundColor Yellow
    az login
}

# Get current subscription
$subscriptionId = az account show --query id -o tsv
$subscriptionName = az account show --query name -o tsv
Write-Host "[INFO] Current subscription: $subscriptionName ($subscriptionId)" -ForegroundColor Cyan

# Prompt for resource details
Write-Host ""
Write-Host "Please provide the following information:" -ForegroundColor Yellow
$userEmail = Read-Host "[EMAIL] Your Azure user email"
$resourceGroup = Read-Host "[RG] Resource group name"
$openAiResourceName = Read-Host "[AI] Azure OpenAI resource name"

Write-Host ""
Write-Host "[CHECK] Validating inputs..." -ForegroundColor Yellow

# Get user object ID
try {
    $userObjectId = az ad user show --id $userEmail --query id -o tsv
    if (-not $userObjectId) { throw }
} catch {
    Write-Host "[X] Error: Could not find user with email $userEmail" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Found user: $userEmail (ID: $userObjectId)" -ForegroundColor Green

# Check if resource group exists
try {
    az group show --name $resourceGroup | Out-Null
} catch {
    Write-Host "[X] Error: Resource group '$resourceGroup' does not exist" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Found resource group: $resourceGroup" -ForegroundColor Green

# Check if OpenAI resource exists
try {
    az cognitiveservices account show --name $openAiResourceName --resource-group $resourceGroup | Out-Null
} catch {
    Write-Host "[X] Error: Azure OpenAI resource '$openAiResourceName' does not exist in resource group '$resourceGroup'" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Found Azure OpenAI resource: $openAiResourceName" -ForegroundColor Green

# Create role assignment
Write-Host ""
Write-Host "[KEY] Assigning 'Cognitive Services OpenAI User' role..." -ForegroundColor Yellow

$resourceScope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.CognitiveServices/accounts/$openAiResourceName"

# Check if role assignment already exists
$existingAssignment = az role assignment list --assignee $userObjectId --scope $resourceScope --role "Cognitive Services OpenAI User" --query "[0].id" -o tsv

if ($existingAssignment) {
    Write-Host "[INFO] Role assignment already exists for $userEmail" -ForegroundColor Cyan
} else {
    try {
        az role assignment create --assignee $userObjectId --role "Cognitive Services OpenAI User" --scope $resourceScope | Out-Null
        Write-Host "[OK] Successfully assigned 'Cognitive Services OpenAI User' role to $userEmail" -ForegroundColor Green
        
        # Also assign at the resource group level as a fallback (sometimes needed for certain operations)
        $rgScope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup"
        try {
            az role assignment create --assignee $userObjectId --role "Cognitive Services OpenAI User" --scope $rgScope | Out-Null
            Write-Host "[OK] Also assigned role at resource group level" -ForegroundColor Green
        } catch {
            Write-Host "[INFO] Resource group level assignment may already exist" -ForegroundColor Cyan
        }
        
        Write-Host ""
        Write-Host "[WAIT] Waiting for role assignment to propagate (30 seconds)..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
        
    } catch {
        Write-Host "[ERROR] Failed to assign role. Error details:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""
        Write-Host "[MANUAL] Please manually assign the role using Azure Portal:" -ForegroundColor Yellow
        Write-Host "1. Go to Azure Portal > $openAiResourceName > Access control (IAM)" -ForegroundColor White
        Write-Host "2. Click 'Add role assignment'" -ForegroundColor White
        Write-Host "3. Select 'Cognitive Services OpenAI User' role" -ForegroundColor White
        Write-Host "4. Assign to: $userEmail" -ForegroundColor White
        exit 1
    }
}

# Get OpenAI endpoint
$openAiEndpoint = az cognitiveservices account show --name $openAiResourceName --resource-group $resourceGroup --query properties.endpoint -o tsv

# Get available deployments
Write-Host ""
Write-Host "[DEPLOY] Checking available deployments..." -ForegroundColor Yellow

try {
    $deployments = az cognitiveservices account deployment list --name $openAiResourceName --resource-group $resourceGroup --query "[].name" -o tsv
    if (-not $deployments) { throw "No deployments found" }
    
    # Handle both single and multiple deployments properly
    $deploymentArray = @($deployments.Trim() -split "`r?`n" | Where-Object { $_.Trim() -ne "" })
    
    if ($deploymentArray.Count -eq 1) {
        $selectedDeployment = $deploymentArray[0].Trim()
        Write-Host "[OK] Found deployment: $selectedDeployment" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Multiple deployments found:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $deploymentArray.Count; $i++) {
            Write-Host "   $($i + 1). $($deploymentArray[$i].Trim())" -ForegroundColor White
        }
        do {
            $choice = Read-Host "[SELECT] Choose deployment (1-$($deploymentArray.Count))"
            $choiceNum = [int]$choice - 1
        } while ($choiceNum -lt 0 -or $choiceNum -ge $deploymentArray.Count)
        
        $selectedDeployment = $deploymentArray[$choiceNum].Trim()
        Write-Host "[OK] Selected deployment: $selectedDeployment" -ForegroundColor Green
    }
} catch {
    Write-Host "[ERROR] Could not retrieve deployments. Using default 'gpt-4o-mini'" -ForegroundColor Red
    $selectedDeployment = "gpt-4o-mini"
}

Write-Host ""
Write-Host "[FILE] Creating .env file..." -ForegroundColor Yellow

# Create .env file
$envContent = @"
# Azure OpenAI Configuration (Managed Identity)
# Generated by setup script on $(Get-Date)

AZURE_OPENAI_ENDPOINT=$openAiEndpoint
AZURE_OPENAI_API_VERSION=2024-08-01-preview
AZURE_OPENAI_DEPLOYMENT_NAME=$selectedDeployment
"@

$webappDir = Join-Path (Split-Path $PSScriptRoot) "webapp"
$envFilePath = Join-Path $webappDir ".env"

# Ensure webapp directory exists
if (-not (Test-Path $webappDir)) {
    Write-Host "[ERROR] webapp directory not found at: $webappDir" -ForegroundColor Red
    exit 1
}

$envContent | Out-File -FilePath $envFilePath -Encoding UTF8

Write-Host "[OK] Created .env file at webapp/.env" -ForegroundColor Green

# Clear Azure CLI token cache to ensure fresh tokens with new permissions
Write-Host ""
Write-Host "[CACHE] Clearing Azure CLI token cache to refresh permissions..." -ForegroundColor Yellow
try {
    az account clear
    az login | Out-Null
    Write-Host "[OK] Successfully refreshed Azure CLI authentication" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] Could not refresh Azure CLI cache automatically" -ForegroundColor Yellow
    Write-Host "[MANUAL] Please run 'az logout' and then 'az login' to refresh your tokens" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[SUCCESS] Setup complete! You can now run the application locally:" -ForegroundColor Green
Write-Host ""
Write-Host "   cd webapp" -ForegroundColor Cyan
Write-Host "   pip install -r requirements.txt" -ForegroundColor Cyan
Write-Host "   streamlit run app.py" -ForegroundColor Cyan
Write-Host ""
Write-Host "[TROUBLESHOOTING] If you still get permission errors:" -ForegroundColor Yellow
Write-Host "1. Wait 5-10 minutes for Azure role assignments to propagate" -ForegroundColor White
Write-Host "2. Run: az logout && az login" -ForegroundColor White
Write-Host "3. Verify your role assignment in Azure Portal:" -ForegroundColor White
Write-Host "   Portal > $openAiResourceName > Access control (IAM) > Role assignments" -ForegroundColor White
Write-Host "4. Look for '$userEmail' with 'Cognitive Services OpenAI User' role" -ForegroundColor White
Write-Host ""
Write-Host "[DOCS] For more information, see the README.md file" -ForegroundColor Yellow