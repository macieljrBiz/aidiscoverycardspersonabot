# AI Discovery Cards - Persona Bot

A web-based chat application that simulates customer personas for AI Discovery Cards sessions. This tool helps session participants interact with consistent, in-character AI personas representing fictional customers, enabling more realistic and engaging discovery sessions.

## 🚀 Quick Deploy to Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FmacieljrBiz%2Faidiscoverycardspersonabot%2Fmain%2Fdeploy%2Fazuredeploy.json)

Click the "Deploy to Azure" button for a **complete one-click deployment** that automatically:
- ✅ **Creates all Azure infrastructure** (App Service, Azure OpenAI, monitoring, etc.)
- ✅ **Deploys application code** from GitHub automatically
- ✅ **Configures secure authentication** using Managed Identity (no API keys!)
- ✅ **Sets up proper permissions** for seamless operation
- ✅ **Detects deployment names** dynamically from your Azure OpenAI resource

**Total deployment time: ~5-10 minutes** including both infrastructure and application code.

## Features

- 🤖 **AI-Powered Personas** - Interact with realistic customer personas powered by Azure OpenAI
- 💬 **Interactive Chat Interface** - Clean, intuitive Streamlit-based chat UI
- 📁 **Configurable Personas** - Easy-to-edit YAML configuration files
- ☁️ **One-Click Azure Deployment** - Complete ARM template for Azure deployment
- 🔐 **Secure Authentication** - Uses Azure Managed Identity (no API keys to manage)
- 🔧 **Extensible Architecture** - Modular design for adding new personas and featuresry Cards - Persona Bot

A web-based chat application that simulates customer personas for AI Discovery Cards sessions. This tool helps session participants interact with consistent, in-character AI personas representing fictional customers, enabling more realistic and engaging discovery sessions.

## Features

- 🤖 **AI-Powered Personas** - Interact with realistic customer personas powered by Azure OpenAI
- 💬 **Interactive Chat Interface** - Clean, intuitive Streamlit-based chat UI
- 📁 **Configurable Personas** - Easy-to-edit YAML configuration files
- ☁️ **One-Click Azure Deployment** - Complete Bicep template for Azure deployment
- � **Secure Authentication** - Uses Azure Managed Identity (no API keys to manage)
- �🔧 **Extensible Architecture** - Modular design for adding new personas and features

## Quick Start

### Local Development

#### Quick Setup (Recommended)

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd aidiscoverycardspersonabot
   ```

2. **Run the automated setup script**
   ```bash
   # Windows PowerShell
   cd deploy
   .\setup-local-dev.ps1
   
   # macOS/Linux
   cd deploy
   chmod +x setup-local-dev.sh
   ./setup-local-dev.sh
   ```

3. **Install dependencies and run**
   ```bash
   cd webapp
   pip install -r requirements.txt
   streamlit run app.py
   ```

#### Manual Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd aidiscoverycardspersonabot
   ```

2. **Install dependencies**
   ```bash
   cd webapp
   pip install -r requirements.txt
   ```

3. **Set up Azure authentication**
   ```bash
   # Login to Azure
   az login
   
   # Set your subscription
   az account set --subscription "your-subscription-id"
   ```

4. **Grant your user access to Azure OpenAI**
   ```bash
   # Replace with your actual values
   USER_EMAIL="your-email@domain.com"
   OPENAI_RESOURCE_NAME="your-openai-resource-name"
   RESOURCE_GROUP="your-resource-group"
   
   # Get your user object ID and assign role
   USER_OBJECT_ID=$(az ad user show --id $USER_EMAIL --query id -o tsv)
   az role assignment create \
     --assignee $USER_OBJECT_ID \
     --role "Cognitive Services OpenAI User" \
     --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.CognitiveServices/accounts/$OPENAI_RESOURCE_NAME"
   ```

5. **Set up environment variables**
   ```bash
   # Create a .env file in the webapp directory
   AZURE_OPENAI_ENDPOINT=https://your-openai-resource.openai.azure.com/
   AZURE_OPENAI_API_VERSION=2024-08-01-preview
   AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4o-mini
   ```

6. **Run the application**
   ```bash
   streamlit run app.py
   ```

7. **Open your browser** to `http://localhost:8501`

### Azure Deployment

For one-click deployment to Azure, see the [deployment guide](deploy/README.md).

## Project Structure

```
persona-bot-mvp/
├── bots/                    # Persona configuration files
│   └── maria-silva.yaml    # Sample marketing persona
├── templates/               # Prompt templates
│   └── prompt-template.txt  # Base prompt with placeholders
├── webapp/                  # Web application
│   ├── app.py              # Streamlit main application
│   ├── persona_bot.py      # Core persona bot logic
│   └── requirements.txt    # Python dependencies
├── deploy/                  # Azure deployment
│   ├── azuredeploy.json    # ARM infrastructure template
│   ├── azuredeploy.parameters.json # Deployment parameters
│   ├── metadata.json       # Template metadata
│   ├── DEPLOY_TO_AZURE.md  # Deploy button guide
│   ├── post-build.sh       # Deployment script
│   ├── setup-local-dev.ps1 # Local dev setup (Windows)
│   ├── setup-local-dev.sh  # Local dev setup (Unix/macOS)
│   └── README.md           # Deployment instructions
└── README.md               # This file
```

## How It Works

1. **Persona Configuration** - Customer personas are defined in YAML files with fields like name, role, industry, pain points, goals, and sample dialogue.

2. **Prompt Generation** - The system loads persona configs and injects them into a prompt template to create character-consistent system prompts.

3. **AI Chat** - Azure OpenAI (GPT-4o-mini) generates responses that stay in character based on the persona's context and constraints.

4. **Web Interface** - Streamlit provides an intuitive chat interface where users can select personas and engage in conversations.

## Sample Persona

Here's an example persona configuration (`maria-silva.yaml`):

```yaml
name: Maria Silva
role: Head of Marketing
industry: Retail
pain_points:
  - Difficulty personalizing campaigns at scale
  - Low customer engagement in digital channels
  - Fragmented customer data across platforms
goals:
  - Improve customer segmentation
  - Increase ROI on marketing campaigns
  - Launch AI-powered product recommendations
tech_maturity: Medium
tone: Curious and business-focused
sample_dialogue: |
  Q: What's your biggest challenge right now?
  A: We're struggling to unify customer data across our CRM and e-commerce platforms...
```

## Creating New Personas

1. **Create a new YAML file** in the `bots/` directory
2. **Define the persona attributes** following the schema above
3. **Test the persona** by selecting it in the web interface
4. **Refine the character** based on conversation quality

### Persona Schema

| Field | Description | Example |
|-------|-------------|---------|
| `name` | Full name of the persona | "Maria Silva" |
| `role` | Job title/position | "Head of Marketing" |
| `industry` | Industry sector | "Retail" |
| `pain_points` | List of challenges | ["Data fragmentation", "Low engagement"] |
| `goals` | List of objectives | ["Improve ROI", "Better segmentation"] |
| `tech_maturity` | Technology adoption level | "Medium" |
| `tone` | Communication style | "Curious and business-focused" |
| `sample_dialogue` | Example Q&A pairs | Realistic conversation examples |

## Architecture

### Components

- **PersonaLoader** - Loads and parses YAML persona configurations
- **PromptBuilder** - Injects persona data into prompt templates
- **AzureOpenAIClient** - Handles Azure OpenAI API communication
- **PersonaBot** - Orchestrates the entire persona chat experience
- **Streamlit App** - Provides the web interface

### Data Flow

1. User selects a persona → PersonaLoader loads YAML config
2. PromptBuilder creates system prompt → AzureOpenAIClient generates introduction
3. User asks question → System maintains conversation history
4. AI responds in character → Response displayed in chat interface

## Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `AZURE_OPENAI_ENDPOINT` | Azure OpenAI service endpoint | None | Yes |
| `AZURE_OPENAI_API_VERSION` | API version | `2024-08-01-preview` | No |
| `AZURE_OPENAI_DEPLOYMENT_NAME` | Model deployment name | `gpt-4o-mini` | No |

**Authentication:** Uses Azure Managed Identity - no API keys required for either local development or production.

### Azure OpenAI Setup

**Both Local Development and Production use Managed Identity:**

1. **Create Azure OpenAI Resource:**
   - Create an Azure OpenAI resource in the Azure Portal
   - Deploy the GPT-4o-mini model

2. **For Local Development:**
   - Run `az login` to authenticate with your Azure account
   - Assign yourself the "Cognitive Services OpenAI User" role on the OpenAI resource
   - See the [deployment guide](deploy/README.md) for detailed local setup instructions

3. **For Production:**
   - Use the "Deploy to Azure" button above for one-click deployment
   - Or deploy manually using the provided ARM template
   - The web app's managed identity is automatically granted access

## Use Cases

- **AI Discovery Sessions** - Realistic customer interviews
- **Product Research** - Understanding user pain points
- **Sales Training** - Practice customer conversations
- **Design Workshops** - User persona development
- **Market Research** - Industry-specific insights

## Troubleshooting

### Common Issues

- **Import errors** - Run `pip install -r requirements.txt`
- **No personas found** - Ensure YAML files are in the `bots/` directory
- **Authentication errors** - For local development:
  - Ensure you're logged in: `az login`
  - Verify you have "Cognitive Services OpenAI User" role on the OpenAI resource
  - Check your Azure subscription is set correctly
- **Chat not working** - Verify your OpenAI deployment name matches the environment variable

### Logs

Check the Streamlit console output for detailed error messages and debugging information.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add new personas or improve existing functionality
4. Test your changes locally
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions or issues:
- Check the [deployment guide](deploy/README.md)
- Review troubleshooting section above
- Open an issue on GitHub