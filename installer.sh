#!/bin/bash

# Clear screen
clear

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Function to install Pterodactyl (Panel + Wings together)
install_pterodactyl() {
    echo -e "\n${RED}Installing Pterodactyl Panel...${NC}"
    
    # Install Panel first
    echo "0" | bash <(curl -s https://pterodactyl-installer.se) --panel
    
    echo -e "\n${RED}Panel installation completed. Now installing Wings...${NC}"
    echo ""
    echo -e "${YELLOW}After Panel installation completes, you'll need to manually install Wings.${NC}"
    echo -e "${YELLOW}Press Enter to continue to Wings installation...${NC}"
    read -p " "
    
    # Install Wings
    echo "1" | bash <(curl -s https://pterodactyl-installer.se) --wings
    
    echo -e "\n${GREEN}Pterodactyl Panel + Wings installation completed!${NC}"
}

# Main menu
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}           🚀 WANNY SCRIPT MANAGER${NC}"
echo -e "${RED}              MAKE BY WANNYDRAGON${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${RED} __  __    _    ___ _   _    __  __ _____ _   _ _   _${NC}"
echo -e "${RED}|  \/  |  / \  |_ _| \ | |  |  \/  | ____| \ | | | | |${NC}"
echo -e "${RED}| |\/| | / _ \  | ||  \| |  | |\/| |  _| |  \| | | | |${NC}"
echo -e "${RED}| |  | |/ ___ \ | || |\  |  | |  | | |___| |\  | |_| |${NC}"
echo -e "${RED}|_|  |_/_/   \_\___|_| \_|  |_|  |_|_____|_| \_|\___/${NC}"
echo ""
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}  1) Install Pterodactyl (Panel + Wings)${NC}"
echo -e "${RED}  2) Uninstall Tools${NC}"
echo -e "${RED}  3) Blueprint+Theme+Extensions${NC}"
echo -e "${RED}  4) Cloudflare Setup${NC}"
echo -e "${RED}  5) System Information${NC}"
echo -e "${RED}  6) Tailscale (install + up)${NC}"
echo -e "${RED}  7) Database Setup${NC}"
echo -e "${RED}  0) Exit${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📝 Select an option [0-7]:${NC} "

read -p " " choice

case $choice in
    1)
        install_pterodactyl
        ;;
    2)
        echo -e "\n${RED}Starting Uninstall Tools...${NC}"
        # Add uninstall tools command here
        ;;
    3)
        echo -e "\n${RED}Starting Blueprint+Theme+Extensions...${NC}"
        # Add blueprint/theme command here
        ;;
    4)
        echo -e "\n${RED}Starting Cloudflare Setup...${NC}"
        # Add Cloudflare setup command here
        ;;
    5)
        echo -e "\n${RED}Showing System Information...${NC}"
        # Add system info command here
        ;;
    6)
        echo -e "\n${RED}Starting Tailscale Installation...${NC}"
        # Add Tailscale command here
        ;;
    7)
        echo -e "\n${RED}Starting Database Setup...${NC}"
        # Add database setup command here
        ;;
    0)
        echo -e "\n${RED}Exiting...${NC}"
        exit 0
        ;;
    *)
        echo -e "\n${RED}Invalid option!${NC}"
        exit 1
        ;;
esac
