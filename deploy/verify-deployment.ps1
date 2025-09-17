#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Verify Azure App Service deployment and GitHub integration status
.DESCRIPTION
    This script checks the status of your Azure App Service deployment and GitHub integration
.PARAMETER ResourceGroupName
    The name of the Azure resource group
.PARAMETER WebAppName
    The name of the Azure Web App
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$WebAppName
)

Write-Host "🔍 Verifying deployment status for Web App: $WebAppName" -ForegroundColor Cyan
Write-Host "📍 Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host ""

# Check if Web App exists and is running
Write-Host "1️⃣ Checking Web App status..." -ForegroundColor Yellow
try {
    $webapp = az webapp show --name $WebAppName --resource-group $ResourceGroupName --query "{name:name,state:state,defaultHostName:defaultHostName}" -o json | ConvertFrom-Json
    
    if ($webapp) {
        Write-Host "   ✅ Web App exists: $($webapp.name)" -ForegroundColor Green
        Write-Host "   ✅ State: $($webapp.state)" -ForegroundColor Green
        Write-Host "   ✅ URL: https://$($webapp.defaultHostName)" -ForegroundColor Green
    }
} catch {
    Write-Host "   ❌ Failed to get Web App info: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check source control configuration
Write-Host ""
Write-Host "2️⃣ Checking source control configuration..." -ForegroundColor Yellow
try {
    $sourceControl = az webapp deployment source show --name $WebAppName --resource-group $ResourceGroupName -o json | ConvertFrom-Json
    
    if ($sourceControl -and $sourceControl.repoUrl) {
        Write-Host "   ✅ Source control configured" -ForegroundColor Green
        Write-Host "   ✅ Repository: $($sourceControl.repoUrl)" -ForegroundColor Green
        Write-Host "   ✅ Branch: $($sourceControl.branch)" -ForegroundColor Green
        Write-Host "   ✅ Is Manual Integration: $($sourceControl.isManualIntegration)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  No source control configured" -ForegroundColor Yellow
        Write-Host "   💡 You can configure it manually in the Azure Portal" -ForegroundColor Cyan
    }
} catch {
    Write-Host "   ⚠️  Could not retrieve source control info: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Check recent deployments
Write-Host ""
Write-Host "3️⃣ Checking deployment history..." -ForegroundColor Yellow
try {
    $deployments = az webapp deployment list --name $WebAppName --resource-group $ResourceGroupName --query "[0:3].{id:id,status:status,author:author,start_time:start_time,end_time:end_time}" -o json | ConvertFrom-Json
    
    if ($deployments -and $deployments.Count -gt 0) {
        Write-Host "   ✅ Recent deployments found:" -ForegroundColor Green
        foreach ($deployment in $deployments) {
            $status = if ($deployment.status -eq 4) { "✅ Success" } elseif ($deployment.status -eq 3) { "❌ Failed" } else { "⏳ In Progress" }
            Write-Host "   $status - $($deployment.author) at $($deployment.start_time)" -ForegroundColor White
        }
    } else {
        Write-Host "   ⚠️  No deployments found yet" -ForegroundColor Yellow
        Write-Host "   💡 If you just set up the app, wait 5-10 minutes for the first deployment" -ForegroundColor Cyan
    }
} catch {
    Write-Host "   ⚠️  Could not retrieve deployment history: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test the web app URL
Write-Host ""
Write-Host "4️⃣ Testing web app accessibility..." -ForegroundColor Yellow
try {
    $url = "https://$($webapp.defaultHostName)"
    $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 30
    Write-Host "   ✅ Web app is accessible (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Web app might not be ready yet: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "   💡 If this is a new deployment, wait a few more minutes" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "🎯 Summary:" -ForegroundColor Cyan
Write-Host "   • Web App URL: https://$($webapp.defaultHostName)" -ForegroundColor White
Write-Host "   • Deployment Center: https://portal.azure.com/#@/resource/subscriptions/{subscription-id}/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$WebAppName/vstscd" -ForegroundColor White
Write-Host "   • If you need to manually configure GitHub deployment:" -ForegroundColor White
Write-Host "     az webapp deployment source config --name $WebAppName --resource-group $ResourceGroupName --repo-url https://github.com/macieljrBiz/aidiscoverycardspersonabot --branch main --manual-integration" -ForegroundColor Gray

Write-Host ""
Write-Host "✨ Verification complete!" -ForegroundColor Green