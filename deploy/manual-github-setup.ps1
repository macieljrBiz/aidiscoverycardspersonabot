# Post-deployment script to manually configure GitHub deployment (PowerShell)
# Use this if the ARM template's automatic GitHub deployment fails

Write-Host "[TOOL] Manual GitHub Deployment Setup" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Check if Azure CLI is available
try {
    az --version | Out-Null
} catch {
    Write-Host "[X] Azure CLI is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Check if user is logged in
try {
    az account show | Out-Null
} catch {
    Write-Host "[AUTH] Please login to Azure first:" -ForegroundColor Yellow
    az login
}

# Prompt for required information
Write-Host ""
$webAppName = Read-Host "[NAME] Enter your Web App name"
$resourceGroup = Read-Host "[RG] Enter your Resource Group name" 
$repoUrl = Read-Host "[REPO] Enter repository URL [https://github.com/macieljrBiz/aidiscoverycardspersonabot]"
$branch = Read-Host "[BRANCH] Enter branch name [main]"

# Set defaults if empty
if ([string]::IsNullOrWhiteSpace($repoUrl)) { $repoUrl = "https://github.com/macieljrBiz/aidiscoverycardspersonabot" }
if ([string]::IsNullOrWhiteSpace($branch)) { $branch = "main" }

Write-Host ""
Write-Host "[CONFIG] Configuring GitHub deployment..." -ForegroundColor Yellow
Write-Host "   Web App: $webAppName" -ForegroundColor Cyan
Write-Host "   Resource Group: $resourceGroup" -ForegroundColor Cyan
Write-Host "   Repository: $repoUrl" -ForegroundColor Cyan
Write-Host "   Branch: $branch" -ForegroundColor Cyan

# Configure source control
try {
    az webapp deployment source config --name $webAppName --resource-group $resourceGroup --repo-url $repoUrl --branch $branch --manual-integration | Out-Null
    
    Write-Host ""
    Write-Host "[SUCCESS] GitHub deployment configured successfully!" -ForegroundColor Green
    Write-Host "[TIME] Initial deployment will take 5-10 minutes." -ForegroundColor Yellow
    Write-Host "[MONITOR] Monitor deployment status in Azure Portal > App Service > Deployment Center" -ForegroundColor Yellow
    Write-Host ""
    
    # Get the web app URL
    try {
        $webAppUrl = az webapp show --name $webAppName --resource-group $resourceGroup --query defaultHostName -o tsv
        if ($webAppUrl) {
            Write-Host "[URL] Your app will be available at: https://$webAppUrl" -ForegroundColor Green
        }
    } catch {
        Write-Host "[INFO] Could not retrieve app URL automatically" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host ""
    Write-Host "[ERROR] Failed to configure GitHub deployment." -ForegroundColor Red
    Write-Host "[ALTERNATIVE] Use Azure Portal > App Service > Deployment Center" -ForegroundColor Yellow
    Write-Host "   - Select 'GitHub' as source" -ForegroundColor White
    Write-Host "   - Repository: $repoUrl" -ForegroundColor White
    Write-Host "   - Branch: $branch" -ForegroundColor White
    Write-Host "   - Build provider: App Service build service" -ForegroundColor White
}

Write-Host ""
Write-Host "[DOCS] For more information, see: https://docs.microsoft.com/en-us/azure/app-service/deploy-continuous-deployment" -ForegroundColor Cyan