"""
AI Discovery Cards Persona Bot - Streamlit Web App
A simple chat interface for interacting with customer personas
"""
import streamlit as st
import os
import sys
from typing import List, Dict

# Add the current directory to Python path for imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from persona_bot import PersonaBot

# Page configuration
st.set_page_config(
    page_title="AI Discovery Cards - Persona Bot",
    page_icon="🤖",
    layout="wide",
    initial_sidebar_state="expanded"
)

def initialize_session_state():
    """Initialize Streamlit session state variables"""
    if "persona_bot" not in st.session_state:
        st.session_state.persona_bot = PersonaBot()
    
    if "messages" not in st.session_state:
        st.session_state.messages = []
    
    if "current_persona" not in st.session_state:
        st.session_state.current_persona = None
    
    if "persona_introduced" not in st.session_state:
        st.session_state.persona_introduced = False

def load_persona(persona_file: str):
    """Load a new persona and reset the conversation"""
    try:
        # Load the persona
        persona_config = st.session_state.persona_bot.load_persona(persona_file)
        st.session_state.current_persona = persona_config
        
        # Reset conversation
        st.session_state.messages = []
        st.session_state.persona_introduced = False
        
        # Get introduction message
        intro_message = st.session_state.persona_bot.get_introduction_message()
        st.session_state.messages.append({
            "role": "assistant", 
            "content": intro_message
        })
        st.session_state.persona_introduced = True
        
        st.success(f"Loaded persona: {persona_config['name']}")
        
    except Exception as e:
        st.error(f"Error loading persona: {str(e)}")

def display_persona_info():
    """Display current persona information in the sidebar"""
    if st.session_state.current_persona:
        st.sidebar.subheader("Current Persona")
        persona = st.session_state.current_persona
        
        st.sidebar.write(f"**Name:** {persona.get('name', 'Unknown')}")
        st.sidebar.write(f"**Role:** {persona.get('role', 'Unknown')}")
        st.sidebar.write(f"**Industry:** {persona.get('industry', 'Unknown')}")
        st.sidebar.write(f"**Tech Maturity:** {persona.get('tech_maturity', 'Unknown')}")
        
        # Show pain points
        pain_points = persona.get('pain_points', [])
        if pain_points:
            st.sidebar.write("**Pain Points:**")
            for point in pain_points:
                st.sidebar.write(f"• {point}")
        
        # Show goals
        goals = persona.get('goals', [])
        if goals:
            st.sidebar.write("**Goals:**")
            for goal in goals:
                st.sidebar.write(f"• {goal}")

def main():
    """Main Streamlit application"""
    initialize_session_state()
    
    # Header
    st.title("🤖 AI Discovery Cards - Persona Bot")
    st.markdown("---")
    
    # Sidebar for persona selection
    st.sidebar.header("Persona Selection")
    
    # Get available personas
    available_personas = st.session_state.persona_bot.list_available_personas()
    
    if not available_personas:
        st.sidebar.error("No persona files found in the 'bots' directory!")
        st.error("Please ensure you have persona configuration files (*.yaml) in the 'bots' directory.")
        return
    
    # Persona selection dropdown
    selected_persona = st.sidebar.selectbox(
        "Choose a persona:",
        options=available_personas,
        index=0 if available_personas else None,
        help="Select a customer persona to interact with"
    )
    
    # Load persona button
    if st.sidebar.button("Load Persona", type="primary"):
        if selected_persona:
            load_persona(selected_persona)
            st.rerun()
    
    # Display current persona info
    display_persona_info()
    
    # Reset conversation button
    if st.sidebar.button("Reset Conversation"):
        if st.session_state.current_persona:
            st.session_state.messages = []
            st.session_state.persona_bot.reset_conversation()
            # Re-introduce the persona
            intro_message = st.session_state.persona_bot.get_introduction_message()
            st.session_state.messages.append({
                "role": "assistant", 
                "content": intro_message
            })
            st.rerun()
    
    # Main chat interface
    if not st.session_state.current_persona:
        st.info("👈 Please select and load a persona from the sidebar to start chatting!")
        return
    
    # Chat container
    chat_container = st.container()
    
    with chat_container:
        # Display chat messages
        for message in st.session_state.messages:
            with st.chat_message(message["role"]):
                st.markdown(message["content"])
    
    # Chat input
    if prompt := st.chat_input("Ask the persona a question..."):
        # Add user message to chat history
        st.session_state.messages.append({"role": "user", "content": prompt})
        
        # Display user message
        with st.chat_message("user"):
            st.markdown(prompt)
        
        # Generate and display assistant response
        with st.chat_message("assistant"):
            with st.spinner("Thinking..."):
                try:
                    response = st.session_state.persona_bot.chat(prompt)
                    st.markdown(response)
                    
                    # Add assistant response to chat history
                    st.session_state.messages.append({"role": "assistant", "content": response})
                    
                except Exception as e:
                    error_message = f"Sorry, I encountered an error: {str(e)}"
                    st.error(error_message)
                    st.session_state.messages.append({"role": "assistant", "content": error_message})
    
    # Configuration help
    with st.sidebar:
        st.markdown("---")
        st.subheader("Configuration")
        
        # Check Azure OpenAI configuration
        config_status = check_azure_config()
        if config_status["configured"]:
            st.success("✅ Azure OpenAI configured (Managed Identity)")
        else:
            st.warning("⚠️ Azure OpenAI not configured")
            st.write("Missing environment variables:")
            for var in config_status["missing"]:
                st.write(f"• {var}")
            st.info("💡 This app uses Managed Identity for authentication")
        
        # Help section
        st.markdown("---")
        st.subheader("How to Use")
        st.write("""
        1. Select a persona from the dropdown
        2. Click 'Load Persona' to start
        3. Chat with the persona by typing questions
        4. Use 'Reset Conversation' to start over
        """)

def check_azure_config() -> Dict[str, any]:
    """Check if Azure OpenAI is properly configured for Managed Identity"""
    required_vars = [
        "AZURE_OPENAI_ENDPOINT"
    ]
    
    missing = []
    for var in required_vars:
        if not os.getenv(var):
            missing.append(var)
    
    return {
        "configured": len(missing) == 0,
        "missing": missing
    }

if __name__ == "__main__":
    main()