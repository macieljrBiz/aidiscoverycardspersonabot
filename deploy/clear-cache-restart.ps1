# Script para limpar cache e reiniciar o Azure App Service

param(
    [Parameter(Mandatory=$true)]
    [string]$WebAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup
)

Write-Host "🧹 Limpando cache e reiniciando Azure App Service..." -ForegroundColor Cyan
Write-Host ""

# 1. Parar o app
Write-Host "⏸️  Parando aplicação..." -ForegroundColor Yellow
az webapp stop --name $WebAppName --resource-group $ResourceGroup
Start-Sleep -Seconds 5

# 2. Limpar arquivos antigos via Kudu API
Write-Host "🗑️  Limpando arquivos antigos..." -ForegroundColor Yellow
try {
    # Tentar limpar __pycache__ via SSH
    az webapp ssh --name $WebAppName --resource-group $ResourceGroup --command "cd /home/site/wwwroot && find . -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null; find . -name '*.pyc' -delete 2>/dev/null; echo 'Cache limpo'"
} catch {
    Write-Host "⚠️  Não foi possível limpar via SSH, continuando..." -ForegroundColor Yellow
}

# 3. Reiniciar
Write-Host "🔄 Reiniciando aplicação..." -ForegroundColor Yellow
az webapp start --name $WebAppName --resource-group $ResourceGroup
Start-Sleep -Seconds 5

# 4. Restart completo
Write-Host "♻️  Fazendo restart completo..." -ForegroundColor Yellow
az webapp restart --name $WebAppName --resource-group $ResourceGroup

Write-Host ""
Write-Host "✅ Processo concluído!" -ForegroundColor Green
Write-Host "⏳ Aguarde 1-2 minutos para a aplicação inicializar completamente" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 Ver logs em tempo real:" -ForegroundColor Yellow
Write-Host "   az webapp log tail --name $WebAppName --resource-group $ResourceGroup" -ForegroundColor Gray
