#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "${2}${1}${NC}"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_message "This script only works on macOS" "$RED"
    exit 1
fi

# Create output directory
EXPORT_DIR="$HOME/browser_data_export"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Function to check if Homebrew is installed
check_brew() {
    if ! command -v brew &> /dev/null; then
        print_message "Installing Homebrew..." "$YELLOW"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

# Function to install required tools
install_requirements() {
    print_message "Installing required tools..." "$YELLOW"
    brew install sqlite3 jq
}

# Function to export Chrome data
export_chrome() {
    print_message "Exporting Chrome data..." "$YELLOW"
    CHROME_DIR="$HOME/Library/Application Support/Google/Chrome"
    CHROME_EXPORT_DIR="$EXPORT_DIR/chrome_export_$TIMESTAMP"
    
    if [ -d "$CHROME_DIR" ]; then
        mkdir -p "$CHROME_EXPORT_DIR"
        
        # Copy Cookies database
        if [ -f "$CHROME_DIR/Default/Cookies" ]; then
            cp "$CHROME_DIR/Default/Cookies" "$CHROME_EXPORT_DIR/cookies.db"
            print_message "Exported Chrome cookies" "$GREEN"
        fi
        
        # Copy Login Data (passwords)
        if [ -f "$CHROME_DIR/Default/Login Data" ]; then
            cp "$CHROME_DIR/Default/Login Data" "$CHROME_EXPORT_DIR/login_data.db"
            print_message "Exported Chrome passwords database" "$GREEN"
        fi
        
        # Copy History
        if [ -f "$CHROME_DIR/Default/History" ]; then
            cp "$CHROME_DIR/Default/History" "$CHROME_EXPORT_DIR/history.db"
            print_message "Exported Chrome history" "$GREEN"
        fi
        
        # Copy Bookmarks
        if [ -f "$CHROME_DIR/Default/Bookmarks" ]; then
            cp "$CHROME_DIR/Default/Bookmarks" "$CHROME_EXPORT_DIR/bookmarks.json"
            print_message "Exported Chrome bookmarks" "$GREEN"
        fi
        
        # Extract passwords from database (if possible)
        if [ -f "$CHROME_EXPORT_DIR/login_data.db" ]; then
            sqlite3 "$CHROME_EXPORT_DIR/login_data.db" \
                "SELECT origin_url, username_value, password_value FROM logins;" \
                > "$CHROME_EXPORT_DIR/passwords.txt" 2>/dev/null
            print_message "Extracted password data" "$GREEN"
        fi
    else
        print_message "Chrome data directory not found" "$RED"
    fi
}

# Function to export Safari data
export_safari() {
    print_message "Exporting Safari data..." "$YELLOW"
    SAFARI_DIR="$HOME/Library/Safari"
    SAFARI_EXPORT_DIR="$EXPORT_DIR/safari_export_$TIMESTAMP"
    
    if [ -d "$SAFARI_DIR" ]; then
        mkdir -p "$SAFARI_EXPORT_DIR"
        
        # Copy Cookies
        if [ -f "$SAFARI_DIR/Cookies.binarycookies" ]; then
            cp "$SAFARI_DIR/Cookies.binarycookies" "$SAFARI_EXPORT_DIR/"
            print_message "Exported Safari cookies" "$GREEN"
        fi
        
        # Copy History
        if [ -f "$SAFARI_DIR/History.db" ]; then
            cp "$SAFARI_DIR/History.db" "$SAFARI_EXPORT_DIR/"
            print_message "Exported Safari history" "$GREEN"
        fi
        
        # Copy Bookmarks
        if [ -f "$SAFARI_DIR/Bookmarks.plist" ]; then
            cp "$SAFARI_DIR/Bookmarks.plist" "$SAFARI_EXPORT_DIR/"
            print_message "Exported Safari bookmarks" "$GREEN"
        fi
    else
        print_message "Safari data directory not found" "$RED"
    fi
}

# Function to export Firefox data
export_firefox() {
    print_message "Exporting Firefox data..." "$YELLOW"
    FIREFOX_DIR="$HOME/Library/Application Support/Firefox/Profiles"
    FIREFOX_EXPORT_DIR="$EXPORT_DIR/firefox_export_$TIMESTAMP"
    
    if [ -d "$FIREFOX_DIR" ]; then
        mkdir -p "$FIREFOX_EXPORT_DIR"
        
        # Find the default profile
        DEFAULT_PROFILE=$(find "$FIREFOX_DIR" -name "*.default-release" -type d | head -n 1)
        
        if [ -n "$DEFAULT_PROFILE" ]; then
            # Copy cookies database
            if [ -f "$DEFAULT_PROFILE/cookies.sqlite" ]; then
                cp "$DEFAULT_PROFILE/cookies.sqlite" "$FIREFOX_EXPORT_DIR/"
                print_message "Exported Firefox cookies" "$GREEN"
            fi
            
            # Copy places database (history and bookmarks)
            if [ -f "$DEFAULT_PROFILE/places.sqlite" ]; then
                cp "$DEFAULT_PROFILE/places.sqlite" "$FIREFOX_EXPORT_DIR/"
                print_message "Exported Firefox history and bookmarks" "$GREEN"
            fi
            
            # Copy login data
            if [ -f "$DEFAULT_PROFILE/logins.json" ]; then
                cp "$DEFAULT_PROFILE/logins.json" "$FIREFOX_EXPORT_DIR/"
                print_message "Exported Firefox login data" "$GREEN"
            fi
        else
            print_message "Firefox default profile not found" "$RED"
        fi
    else
        print_message "Firefox data directory not found" "$RED"
    fi
}

# Main execution
main() {
    print_message "Starting browser data export..." "$GREEN"
    
    # Create main export directory
    mkdir -p "$EXPORT_DIR"
    
    # Install requirements
    check_brew
    install_requirements
    
    # Export data from each browser
    export_chrome
    export_safari
    export_firefox
    
    print_message "Export completed! Data saved to: $EXPORT_DIR" "$GREEN"
    print_message "Note: Some files might not be exported due to macOS security restrictions." "$YELLOW"
    print_message "To access all data, grant 'Full Disk Access' to Terminal in System Preferences > Security & Privacy > Privacy" "$YELLOW"
}

# Run the script
main 