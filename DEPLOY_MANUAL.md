# 🚀 Guia de Deploy Manual - Azure App Service

Este guia descreve **todos os passos manuais** necessários para fazer o deploy da aplicação Persona Bot no Azure App Service usando Azure CLI.

> ⏱️ **Tempo estimado:** 15-20 minutos  
> 💡 **Nível:** Intermediário  
> 🛠️ **Ferramentas necessárias:** Azure CLI, PowerShell

## 📋 Pré-requisitos

Antes de começar, certifique-se de ter:

1. ✅ **Azure CLI instalado** - [Download](https://docs.microsoft.com/cli/azure/install-azure-cli)
2. ✅ **Conta Azure** com permissões de Contributor
3. ✅ **Azure OpenAI** já criado e configurado com modelo GPT-4o-mini
4. ✅ **PowerShell** (já vem no Windows)
5. ✅ **Repositório clonado** localmente

### Informações que você precisará ter em mãos:

- 📝 Nome do **Resource Group** onde está o Azure OpenAI
- 📝 Nome da **conta do Azure OpenAI**
- 📝 Nome do **deployment** do modelo (ex: gpt4mini)

## � Índice de Passos

1. [Login no Azure](#-passo-1-login-no-azure)
2. [Criar Resource Group](#-passo-2-criar-grupo-de-recursos)
3. [Criar App Service Plan](#-passo-3-criar-app-service-plan)
4. [Criar Web App](#️-passo-4-criar-web-app)
5. [Configurar Managed Identity](#-passo-5-configurar-managed-identity-no-azure-openai)
6. [Configurar Variáveis de Ambiente](#️-passo-6-configurar-variáveis-de-ambiente)
7. [Configurar Startup Command](#-passo-7-configurar-startup-command)
8. [Deploy do Código](#-passo-8-deploy-do-código)
9. [Verificar Deploy](#-passo-9-verificar-o-deploy)

---

## �🔧 Passo 1: Login no Azure

```powershell
# Fazer login no Azure
az login

# Listar suas subscriptions
az account list --output table

# Definir a subscription que será usada (substitua pelo ID correto)
az account set --subscription "YOUR-SUBSCRIPTION-ID"
```

## 📦 Passo 2: Criar Grupo de Recursos

```powershell
# Definir variáveis (ajuste conforme necessário)
$RESOURCE_GROUP = "rg-personabot-dev"
$LOCATION = "eastus2"  # ou outra região que suporte Azure OpenAI

# Criar o resource group
az group create --name $RESOURCE_GROUP --location $LOCATION
```

## 🌐 Passo 3: Criar App Service Plan

```powershell
# Criar App Service Plan (Linux, Python 3.11)
$APP_SERVICE_PLAN = "plan-personabot-dev"

az appservice plan create `
    --name $APP_SERVICE_PLAN `
    --resource-group $RESOURCE_GROUP `
    --location $LOCATION `
    --is-linux `
    --sku B1
```

**Opções de SKU:**
- `F1` - Free (limitações significativas)
- `B1` - Basic (recomendado para desenvolvimento)
- `B2`, `B3` - Basic com mais recursos
- `S1`, `S2`, `S3` - Standard (recomendado para produção)
- `P1v2`, `P2v2`, `P3v2` - Premium

## 🖥️ Passo 4: Criar Web App

```powershell
# Criar Web App com Managed Identity
$WEB_APP_NAME = "app-personabot-dev-$(Get-Random -Maximum 9999)"

az webapp create `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --plan $APP_SERVICE_PLAN `
    --runtime "PYTHON:3.11" `
    --assign-identity [system]

# Exibir o nome do app criado (será usado depois)
Write-Host "Web App criado: $WEB_APP_NAME" -ForegroundColor Green
```

## 🔐 Passo 5: Configurar Managed Identity no Azure OpenAI

```powershell
# Obter o Principal ID da Managed Identity do Web App
$PRINCIPAL_ID = az webapp identity show `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --query principalId `
    --output tsv

Write-Host "Principal ID: $PRINCIPAL_ID" -ForegroundColor Cyan

# Definir informações do Azure OpenAI (AJUSTE COM SEUS DADOS)
$OPENAI_RESOURCE_GROUP = "SEU-RESOURCE-GROUP-OPENAI"
$OPENAI_ACCOUNT_NAME = "SEU-AZURE-OPENAI-ACCOUNT"

# Atribuir role "Cognitive Services OpenAI User" à Managed Identity
az role assignment create `
    --assignee $PRINCIPAL_ID `
    --role "Cognitive Services OpenAI User" `
    --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$OPENAI_RESOURCE_GROUP/providers/Microsoft.CognitiveServices/accounts/$OPENAI_ACCOUNT_NAME"

Write-Host "Permissões atribuídas com sucesso!" -ForegroundColor Green
```

## ⚙️ Passo 6: Configurar Variáveis de Ambiente

```powershell
# Obter o endpoint do Azure OpenAI
$OPENAI_ENDPOINT = az cognitiveservices account show `
    --name $OPENAI_ACCOUNT_NAME `
    --resource-group $OPENAI_RESOURCE_GROUP `
    --query properties.endpoint `
    --output tsv

# Nome do deployment do modelo (ajuste conforme seu deployment)
$DEPLOYMENT_NAME = "gpt4mini"  # ou o nome que você deu ao deployment

# Configurar as variáveis de ambiente no Web App
az webapp config appsettings set `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --settings `
        AZURE_OPENAI_ENDPOINT="$OPENAI_ENDPOINT" `
        AZURE_OPENAI_DEPLOYMENT_NAME="$DEPLOYMENT_NAME" `
        AZURE_OPENAI_API_VERSION="2024-08-01-preview" `
        AZURE_OPENAI_MAX_TOKENS="500" `
        AZURE_OPENAI_TEMPERATURE="0.7" `
        AZURE_OPENAI_TOP_P="0.9" `
        SCM_DO_BUILD_DURING_DEPLOYMENT="true" `
        ENABLE_ORYX_BUILD="true"

Write-Host "Variáveis de ambiente configuradas!" -ForegroundColor Green
```

## 🚀 Passo 7: Configurar Startup Command

```powershell
# Configurar o comando de startup para usar o arquivo startup.sh
az webapp config set `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --startup-file "startup.sh"

Write-Host "Startup command configurado!" -ForegroundColor Green
```

> **Nota:** O arquivo `startup.sh` já está incluído na raiz do repositório e será deployado junto com o código.

## 📤 Passo 8: Deploy do Código

### Opção A: Deploy via Git (Recomendado)

```powershell
# Habilitar deployment local git
az webapp deployment source config-local-git `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP

# Obter a URL do repositório Git
$GIT_URL = az webapp deployment source config-local-git `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --query url `
    --output tsv

Write-Host "Git URL: $GIT_URL" -ForegroundColor Cyan

# Obter credenciais de deployment
az webapp deployment list-publishing-credentials `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --query "{username:publishingUserName, password:publishingPassword}" `
    --output table

# Adicionar remote do Azure e fazer push
cd c:\Users\vicentem\repos\aidiscoverycardspersonabot
git remote add azure $GIT_URL
git push azure main

# Obs: Será solicitado usuário e senha (use as credenciais obtidas acima)
```

### Opção B: Deploy via ZIP

```powershell
# Criar pacote ZIP (da raiz do repositório)
cd c:\Users\vicentem\repos\aidiscoverycardspersonabot

# IMPORTANTE: No PowerShell, use este método para criar ZIP compatível com Linux
# Método 1: Usando Python (recomendado se tiver Python instalado)
python -c "import shutil; shutil.make_archive('persona-bot', 'zip', '.', None, ['bots', 'templates', 'webapp', 'requirements.txt', 'startup.sh', 'README.md'])"

# OU Método 2: Usando Git (se tiver Git Bash instalado)
# git archive -o persona-bot.zip HEAD bots templates webapp requirements.txt startup.sh README.md

# OU Método 3: Compress-Archive (pode ter problema com barras no Windows)
# Compress-Archive -Path bots,templates,webapp,requirements.txt,startup.sh,README.md -DestinationPath persona-bot.zip -Force

# Deploy do ZIP
az webapp deployment source config-zip `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --src persona-bot.zip

Write-Host "Deploy via ZIP concluído!" -ForegroundColor Green

# Limpar arquivo ZIP
Remove-Item persona-bot.zip
```

> **⚠️ Importante:** O `Compress-Archive` do PowerShell pode criar ZIPs com caminhos no formato Windows (`\`) que causam problemas no Linux. Prefira usar Python ou Git para criar o arquivo ZIP.

## ✅ Passo 9: Verificar o Deploy

```powershell
# Obter a URL do app
$APP_URL = az webapp show `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --query defaultHostName `
    --output tsv

Write-Host "`n✅ Deploy concluído!" -ForegroundColor Green
Write-Host "URL da aplicação: https://$APP_URL" -ForegroundColor Cyan

# Abrir no navegador
Start-Process "https://$APP_URL"

# Ver logs em tempo real (útil para debug)
az webapp log tail `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP
```

## 🔍 Troubleshooting

### Ver logs da aplicação

```powershell
# Habilitar logging
az webapp log config `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --application-logging filesystem `
    --level verbose

# Ver logs em tempo real
az webapp log tail `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP

# Download logs
az webapp log download `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --log-file logs.zip
```

### Verificar variáveis de ambiente

```powershell
az webapp config appsettings list `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --output table
```

### Reiniciar o app

```powershell
az webapp restart `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP
```

### SSH no container (para debug avançado)

```powershell
# Abrir SSH no navegador
az webapp ssh `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP
```

### Erro "Invalid argument" durante deploy ZIP (rsync error code 23)

**Sintoma nos logs:**
```
rsync: [generator] recv_generator: failed to stat "/home/site/wwwroot/webapp\app.py": Invalid argument (22)
```

**Causa:** O ZIP foi criado no Windows com separadores de caminho `\` (backslash) em vez de `/` (forward slash) que o Linux espera.

**Solução:**
```powershell
# 1. Delete o ZIP antigo se existir
Remove-Item persona-bot.zip -ErrorAction SilentlyContinue

# 2. Use Python para criar o ZIP com caminhos compatíveis com Linux
cd c:\Users\vicentem\repos\aidiscoverycardspersonabot
python create_deployment_package.py

# 3. Faça o deploy novamente
az webapp deployment source config-zip `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --src persona-bot.zip
```

**Alternativa se não tiver Python:** Use Git para fazer o deploy
```powershell
# Configure git deployment
az webapp deployment source config-local-git --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP

# Obtenha a URL do git
$GIT_URL = az webapp deployment source config-local-git --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP --query url --output tsv

# Adicione o remote e faça push
git remote add azure $GIT_URL
git push azure main
```

## 🔄 Redeploy (Atualizações Futuras)

### Quando você fizer alterações no código:

**Opção 1: Deploy via Git (se configurado)**
```powershell
# Navegue até a raiz do repositório
cd c:\Users\vicentem\repos\aidiscoverycardspersonabot

# Commit suas alterações
git add .
git commit -m "Descrição das alterações"

# Push para Azure
git push azure main
```

**Opção 2: Deploy via ZIP (mais simples)**
```powershell
# Navegue até a raiz do repositório
cd c:\Users\vicentem\repos\aidiscoverycardspersonabot

# Substitua pelos seus valores
$WEB_APP_NAME = "seu-app-name"
$RESOURCE_GROUP = "seu-resource-group"

# Criar novo pacote ZIP usando Python (recomendado para compatibilidade Linux)
python create_deployment_package.py

# Deploy
az webapp deployment source config-zip --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP --src persona-bot.zip

# Limpar
Remove-Item persona-bot.zip

Write-Host "Redeploy concluído!" -ForegroundColor Green
```

> **⚠️ Nota sobre ZIP no Windows:** O comando `Compress-Archive` do PowerShell pode criar ZIPs com barras invertidas (`\`) que causam problemas no Linux. Use o script Python `create_deployment_package.py` para garantir compatibilidade.

## 🗑️ Limpeza (Deletar Recursos)

```powershell
# Deletar apenas o Web App
az webapp delete --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP

# Deletar o grupo de recursos inteiro (cuidado!)
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

## 📚 Recursos Adicionais

- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Managed Identity Documentation](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/)
- [Azure OpenAI Documentation](https://docs.microsoft.com/azure/cognitive-services/openai/)
- [Streamlit Deployment Guide](https://docs.streamlit.io/knowledge-base/tutorials/deploy)

## 💡 Dicas

1. **Custos**: Use SKU B1 para dev/test e S1+ para produção
2. **Segurança**: Sempre use Managed Identity (nunca coloque API keys no código)
3. **Performance**: Monitore o App Service Insights para otimizações
4. **Backup**: Configure slots de deployment para zero-downtime deploys
5. **Escalabilidade**: Configure auto-scaling se esperar picos de tráfego
