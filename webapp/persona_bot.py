"""
Persona Bot Backend Logic
Handles loading persona configurations and interacting with Azure OpenAI
"""
import yaml
import os
from typing import Dict, Any, List
from openai import AzureOpenAI
from azure.identity import DefaultAzureCredential
import logging
from dotenv import load_dotenv
from pathlib import Path

# Load environment variables from .env file
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Get the root directory of the project (parent of webapp/)
# This works both locally and in Azure
BASE_DIR = Path(__file__).resolve().parent.parent

class PersonaLoader:
    """Handles loading and parsing persona configuration files"""
    
    def __init__(self, bots_directory: str = None):
        if bots_directory is None:
            # Use absolute path based on project root
            self.bots_directory = str(BASE_DIR / "bots")
        else:
            self.bots_directory = bots_directory
    
    def load_persona(self, persona_file: str) -> Dict[str, Any]:
        """
        Load a persona configuration from a YAML file
        
        Args:
            persona_file: Name of the persona file (e.g., 'maria-silva.yaml')
            
        Returns:
            Dictionary containing persona configuration
        """
        try:
            file_path = os.path.join(self.bots_directory, persona_file)
            with open(file_path, 'r', encoding='utf-8') as f:
                persona_config = yaml.safe_load(f)
            
            logger.info(f"Successfully loaded persona: {persona_config.get('name', 'Unknown')}")
            return persona_config
        except FileNotFoundError:
            logger.error(f"Persona file not found: {file_path}")
            raise
        except yaml.YAMLError as e:
            logger.error(f"Error parsing YAML file: {e}")
            raise
    
    def list_available_personas(self) -> List[str]:
        """
        List all available persona files in the bots directory
        
        Returns:
            List of persona file names
        """
        try:
            if not os.path.exists(self.bots_directory):
                return []
            
            files = [f for f in os.listdir(self.bots_directory) if f.endswith('.yaml') or f.endswith('.yml')]
            return files
        except Exception as e:
            logger.error(f"Error listing persona files: {e}")
            return []

class PromptBuilder:
    """Handles building prompts from templates and persona data"""
    
    def __init__(self, template_path: str = None):
        if template_path is None:
            # Use absolute path based on project root
            self.template_path = str(BASE_DIR / "templates" / "prompt-template.txt")
        else:
            self.template_path = template_path
        self.template_content = self._load_template()
    
    def _load_template(self) -> str:
        """Load the prompt template from file"""
        try:
            with open(self.template_path, 'r', encoding='utf-8') as f:
                template = f.read()
            logger.info("Successfully loaded prompt template")
            return template
        except FileNotFoundError:
            logger.error(f"Template file not found: {self.template_path}")
            raise
    
    def build_system_prompt(self, persona_config: Dict[str, Any]) -> str:
        """
        Build a system prompt by injecting persona data into the template
        
        Args:
            persona_config: Persona configuration dictionary
            
        Returns:
            Formatted system prompt string
        """
        try:
            # Format list items for pain points and goals
            pain_points = self._format_list(persona_config.get('pain_points', []))
            goals = self._format_list(persona_config.get('goals', []))
            
            # Replace placeholders in template
            prompt = self.template_content.replace('{{name}}', persona_config.get('name', 'Unknown'))
            prompt = prompt.replace('{{role}}', persona_config.get('role', 'Unknown Role'))
            prompt = prompt.replace('{{industry}}', persona_config.get('industry', 'Unknown Industry'))
            prompt = prompt.replace('{{pain_points}}', pain_points)
            prompt = prompt.replace('{{goals}}', goals)
            prompt = prompt.replace('{{tech_maturity}}', persona_config.get('tech_maturity', 'Unknown'))
            prompt = prompt.replace('{{tone}}', persona_config.get('tone', 'Professional'))
            prompt = prompt.replace('{{sample_dialogue}}', persona_config.get('sample_dialogue', ''))
            
            return prompt
        except Exception as e:
            logger.error(f"Error building system prompt: {e}")
            raise
    
    def _format_list(self, items: List[str]) -> str:
        """Format a list of items as a readable string"""
        if not items:
            return "None specified"
        return ", ".join(items)

class AzureOpenAIClient:
    """Handles communication with Azure OpenAI service using Managed Identity"""
    
    def __init__(self):
        # Use Azure DefaultAzureCredential for both local development (az login) and production (managed identity)
        logger.info("Initializing Azure OpenAI client with Managed Identity")
        try:
            credential = DefaultAzureCredential()
            self.client = AzureOpenAI(
                azure_ad_token_provider=lambda: credential.get_token("https://cognitiveservices.azure.com/.default").token,
                api_version=os.getenv("AZURE_OPENAI_API_VERSION", "2024-08-01-preview"),
                azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT")
            )
            logger.info("Successfully initialized Azure OpenAI client with Managed Identity")
        except Exception as e:
            logger.error(f"Failed to initialize Azure OpenAI client: {e}")
            logger.error("Ensure you are logged in with 'az login' for local development")
            logger.error("or that Managed Identity is properly configured for production")
            raise ValueError("Unable to authenticate with Azure OpenAI. Please check your authentication setup.")
        
        self.deployment_name = os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME", "gpt-4o-mini")
        
        # Validate configuration
        if not os.getenv("AZURE_OPENAI_ENDPOINT"):
            raise ValueError("AZURE_OPENAI_ENDPOINT environment variable must be set")
    
    def generate_response(self, system_prompt: str, user_message: str, conversation_history: List[Dict[str, str]] = None) -> str:
        """
        Generate a response using Azure OpenAI with Managed Identity authentication and content filtering
        
        Args:
            system_prompt: The system prompt with persona context
            user_message: The user's message
            conversation_history: Optional list of previous messages
            
        Returns:
            Generated response string
        """
        try:
            # Security limits
            max_tokens = min(int(os.getenv("AZURE_OPENAI_MAX_TOKENS", "500")), 1000)
            temperature = max(0.0, min(1.0, float(os.getenv("AZURE_OPENAI_TEMPERATURE", "0.7"))))
            top_p = max(0.0, min(1.0, float(os.getenv("AZURE_OPENAI_TOP_P", "0.9"))))
            
            # Build message list
            messages = [{"role": "system", "content": system_prompt}]
            
            # Add conversation history if provided (limit to last 10 messages for context window management)
            if conversation_history:
                # Limit conversation history to prevent token overflow
                recent_history = conversation_history[-10:] if len(conversation_history) > 10 else conversation_history
                messages.extend(recent_history)
            
            # Add current user message
            messages.append({"role": "user", "content": user_message})
            
            # Generate response with content filtering
            response = self.client.chat.completions.create(
                model=self.deployment_name,
                messages=messages,
                max_tokens=max_tokens,
                temperature=temperature,
                top_p=top_p,
                frequency_penalty=0.0,
                presence_penalty=0.0,
                stop=None  # Let Azure OpenAI handle natural stopping
            )
            
            # Log content filtering results if available
            if hasattr(response, 'prompt_filter_results') and response.prompt_filter_results:
                logger.info(f"Prompt filter results: {response.prompt_filter_results}")
            
            if (hasattr(response, 'choices') and response.choices and 
                hasattr(response.choices[0], 'content_filter_results') and 
                response.choices[0].content_filter_results):
                logger.info(f"Content filter results: {response.choices[0].content_filter_results}")
            
            # Return the response or a safe fallback
            if response.choices and response.choices[0].message.content:
                return response.choices[0].message.content
            else:
                logger.warning("No content returned from Azure OpenAI, possibly filtered")
                return "I apologize, but I cannot provide a response to that request. Please try rephrasing your question."
            
        except Exception as e:
            logger.error(f"Error generating response: {e}")
            if "authentication" in str(e).lower() or "unauthorized" in str(e).lower():
                return "Authentication error: Please ensure you have proper permissions to access Azure OpenAI. Check the documentation for setup instructions."
            elif "content_filter" in str(e).lower():
                return "I apologize, but I cannot provide a response to that request due to content policy restrictions. Please try rephrasing your question."
            else:
                return "I apologize, but I'm experiencing technical difficulties. Please try again later."
            return "I apologize, but I'm having trouble responding right now. Please try again in a moment."

class PersonaBot:
    """Main class that orchestrates the persona bot functionality"""
    
    def __init__(self, bots_directory: str = None, template_path: str = None):
        self.persona_loader = PersonaLoader(bots_directory)
        self.prompt_builder = PromptBuilder(template_path)
        self.openai_client = AzureOpenAIClient()
        self.current_persona = None
        self.system_prompt = None
        self.conversation_history = []
    
    def load_persona(self, persona_file: str) -> Dict[str, Any]:
        """Load a persona and prepare the system prompt"""
        self.current_persona = self.persona_loader.load_persona(persona_file)
        self.system_prompt = self.prompt_builder.build_system_prompt(self.current_persona)
        self.conversation_history = []  # Reset conversation history
        return self.current_persona
    
    def get_introduction_message(self) -> str:
        """Get an introduction message from the persona"""
        if not self.current_persona:
            return "Hello! I'm a customer persona. Please load a persona configuration first."
        
        name = self.current_persona.get('name', 'Unknown')
        role = self.current_persona.get('role', 'Unknown Role')
        industry = self.current_persona.get('industry', 'Unknown Industry')
        
        intro_prompt = f"Introduce yourself briefly as {name}, mention your role as {role} in {industry}, and invite participants to ask you questions about your work and challenges."
        
        response = self.openai_client.generate_response(
            system_prompt=self.system_prompt,
            user_message=intro_prompt,
            conversation_history=[]
        )
        
        return response
    
    def chat(self, user_message: str) -> str:
        """
        Process a user message and return a persona response
        
        Args:
            user_message: The user's input message
            
        Returns:
            Persona's response
        """
        if not self.current_persona or not self.system_prompt:
            return "Please load a persona configuration first."
        
        # Generate response
        response = self.openai_client.generate_response(
            system_prompt=self.system_prompt,
            user_message=user_message,
            conversation_history=self.conversation_history
        )
        
        # Update conversation history
        self.conversation_history.append({"role": "user", "content": user_message})
        self.conversation_history.append({"role": "assistant", "content": response})
        
        # Keep only last 10 exchanges to manage token usage
        if len(self.conversation_history) > 20:
            self.conversation_history = self.conversation_history[-20:]
        
        return response
    
    def list_available_personas(self) -> List[str]:
        """List all available persona files"""
        return self.persona_loader.list_available_personas()
    
    def reset_conversation(self):
        """Reset the conversation history"""
        self.conversation_history = []
        logger.info("Conversation history reset")