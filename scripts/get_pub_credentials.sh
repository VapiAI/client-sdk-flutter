#!/bin/bash

# Define credential locations
MACOS_CREDS="$HOME/Library/Application Support/dart/pub-credentials.json"
LINUX_CREDS="$HOME/.pub-cache/credentials.json"

# Function to display credentials
display_credentials() {
    local creds_file=$1
    local location_name=$2
    
    echo "Found credentials at $location_name location"
    echo "Your pub.dev credentials:"
    echo "========================="
    cat "$creds_file"
    echo ""
    echo "========================="
    echo ""
    echo "Copy the ENTIRE content above (including the curly braces)"
    echo "and add it as a GitHub secret named 'PUB_CREDENTIALS'"
}

# Function to find and display credentials
find_credentials() {
    if [ -f "$MACOS_CREDS" ]; then
        display_credentials "$MACOS_CREDS" "macOS"
        return 0
    elif [ -f "$LINUX_CREDS" ]; then
        display_credentials "$LINUX_CREDS" "Linux/default"
        return 0
    else
        return 1
    fi
}

# Main script
echo "This script helps you obtain your pub.dev credentials for GitHub Actions"
echo "========================================================================="
echo ""

# Try to find existing credentials
if find_credentials; then
    exit 0
fi

# No credentials found, run login
echo "Credentials not found. Running 'flutter pub login' now..."
echo ""
flutter pub login

# Check again after login
echo ""
echo "Checking for credentials after login..."
echo ""

if find_credentials; then
    exit 0
else
    echo "ERROR: Could not find credentials after login. Something went wrong."
    echo "Please try running 'flutter pub login' manually."
    exit 1
fi
