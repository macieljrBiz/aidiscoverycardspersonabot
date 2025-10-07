"""
Create deployment ZIP package for Azure App Service
This script creates a ZIP file with Linux-compatible path separators
"""
import zipfile
import os
from pathlib import Path

def create_deployment_zip(output_filename='persona-bot.zip'):
    """Create a ZIP file for Azure deployment with proper path separators"""
    
    # Files and directories to include
    items_to_include = [
        'bots',
        'templates',
        'webapp',
        'requirements.txt',
        'startup.sh'
    ]
    
    # Files to exclude
    exclude_patterns = [
        '__pycache__',
        '.pyc',
        '.env',
        '.venv',
        'venv',
        '.git',
        '.vscode',
        '.idea'
    ]
    
    print(f"Creating deployment package: {output_filename}")
    print("-" * 50)
    
    with zipfile.ZipFile(output_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for item in items_to_include:
            if not os.path.exists(item):
                print(f"⚠️  Warning: {item} not found, skipping...")
                continue
            
            if os.path.isfile(item):
                # Add single file
                arcname = item.replace('\\', '/')  # Ensure forward slashes
                zipf.write(item, arcname)
                print(f"✓ Added file: {arcname}")
            
            elif os.path.isdir(item):
                # Add directory recursively
                for root, dirs, files in os.walk(item):
                    # Remove excluded directories
                    dirs[:] = [d for d in dirs if not any(pattern in d for pattern in exclude_patterns)]
                    
                    for file in files:
                        # Skip excluded files
                        if any(pattern in file for pattern in exclude_patterns):
                            continue
                        
                        file_path = os.path.join(root, file)
                        arcname = file_path.replace('\\', '/')  # Ensure forward slashes
                        zipf.write(file_path, arcname)
                        print(f"✓ Added: {arcname}")
    
    # Get ZIP file size
    zip_size = os.path.getsize(output_filename)
    zip_size_mb = zip_size / (1024 * 1024)
    
    print("-" * 50)
    print(f"✅ Package created successfully: {output_filename}")
    print(f"📦 Size: {zip_size_mb:.2f} MB")
    print(f"\nNext step: Deploy using Azure CLI")
    print(f"az webapp deployment source config-zip --name <APP_NAME> --resource-group <RG_NAME> --src {output_filename}")

if __name__ == '__main__':
    # Check if we're in the right directory
    if not os.path.exists('webapp') or not os.path.exists('bots'):
        print("❌ Error: Please run this script from the repository root directory")
        print("   (where 'webapp' and 'bots' folders are located)")
        exit(1)
    
    create_deployment_zip()
