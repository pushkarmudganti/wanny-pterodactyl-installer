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

# Function to check system requirements
check_requirements() {
    echo -e "${YELLOW}Checking system requirements...${NC}"
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}❌ Please run as root/sudo user!${NC}"
        exit 1
    fi
    
    # Check RAM
    RAM=$(free -g | awk '/^Mem:/ {print $2}')
    if [ $RAM -lt 2 ]; then
        echo -e "${RED}❌ Insufficient RAM! Minimum 2GB required, found ${RAM}GB${NC}"
        echo -e "${YELLOW}Continue anyway? (y/n):${NC}"
        read -p " " continue_anyway
        if [[ $continue_anyway != "y" && $continue_anyway != "Y" ]]; then
            exit 1
        fi
    else
        echo -e "${GREEN}✓ RAM: ${RAM}GB (Minimum 2GB)${NC}"
    fi
    
    # Check Disk
    DISK=$(df -h / | awk 'NR==2 {print $2}' | sed 's/G//')
    if [ $DISK -lt 20 ]; then
        echo -e "${RED}❌ Insufficient Disk Space! Minimum 20GB required, found ${DISK}GB${NC}"
        echo -e "${YELLOW}Continue anyway? (y/n):${NC}"
        read -p " " continue_anyway
        if [[ $continue_anyway != "y" && $continue_anyway != "Y" ]]; then
            exit 1
        fi
    else
        echo -e "${GREEN}✓ Disk: ${DISK}GB (Minimum 20GB)${NC}"
    fi
    
    # Check systemd
    if ! command -v systemctl &> /dev/null; then
        echo -e "${RED}❌ Systemd not found!${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Systemd is available${NC}"
    
    echo ""
}

# Function to manually install Panel with visible certificate process
install_panel_manual() {
    echo -e "${YELLOW}Starting Manual Pterodactyl Panel Installation...${NC}"
    echo -e "${YELLOW}INSTALLATION OF PTERODACTYL PANEL EASILY - MADE BY WANNYDRAGON${NC}"
    echo ""
    
    # Fixed settings as requested
    FQDN="bad-cat-91.telebit.io"
    EMAIL="admin@gmail.com"
    USERNAME="admin"
    PASSWORD="admin123"
    FIRST_NAME="admin"
    LAST_NAME="user"
    
    echo -e "${GREEN}Using fixed settings:${NC}"
    echo -e "${BLUE}FQDN:${NC} $FQDN"
    echo -e "${BLUE}Email:${NC} $EMAIL"
    echo -e "${BLUE}Username:${NC} $USERNAME"
    echo -e "${BLUE}Password:${NC} $PASSWORD"
    echo ""
    
    echo -e "${YELLOW}Step 1: Installing required packages...${NC}"
    apt-get update
    apt-get install -y curl git mariadb-server nginx certbot python3-certbot-nginx php-fpm php-common php-cli php-gd php-mysql php-mbstring php-bcmath php-xml php-curl php-zip
    
    echo -e "${YELLOW}Step 2: Starting MariaDB and Nginx...${NC}"
    systemctl start mariadb
    systemctl enable mariadb
    systemctl start nginx
    systemctl enable nginx
    
    echo -e "${YELLOW}Step 3: Running Pterodactyl installer...${NC}"
    echo -e "${GREEN}Follow these steps manually:${NC}"
    echo ""
    echo -e "${BLUE}1. Run installer:${NC} bash <(curl -s https://pterodactyl-installer.se)"
    echo -e "${BLUE}2. Select option:${NC} 0 (Install Panel)"
    echo -e "${BLUE}3. Database name:${NC} Press Enter (default: panel)"
    echo -e "${BLUE}4. Database user:${NC} Press Enter (default: pterodactyl)"
    echo -e "${BLUE}5. Database password:${NC} Press Enter (random)"
    echo -e "${BLUE}6. Timezone:${NC} Press Enter (default)"
    echo -e "${BLUE}7. Let's Encrypt email:${NC} admin@gmail.com"
    echo -e "${BLUE}8. Admin email:${NC} admin@gmail.com"
    echo -e "${BLUE}9. Username:${NC} admin"
    echo -e "${BLUE}10. First name:${NC} admin"
    echo -e "${BLUE}11. Last name:${NC} user"
    echo -e "${BLUE}12. Password:${NC} admin123"
    echo -e "${BLUE}13. FQDN:${NC} bad-cat-91.telebit.io"
    echo -e "${BLUE}14. UFW firewall:${NC} n"
    echo -e "${BLUE}15. Let's Encrypt:${NC} y"
    echo -e "${BLUE}16. HTTPS request:${NC} y"
    echo -e "${BLUE}17. Cloudflare warning:${NC} y"
    echo -e "${BLUE}18. Continue installation:${NC} y"
    echo ""
    echo -e "${RED}IMPORTANT: When you see certificate generation, WATCH THE PROCESS!${NC}"
    echo -e "${RED}You will see Let's Encrypt attempting to get SSL certificate.${NC}"
    echo ""
    
    echo -e "${YELLOW}Press Enter to start installer (you will see certificate process)...${NC}"
    read -p ""
    
    # Run installer manually so user can see certificate process
    bash <(curl -s https://pterodactyl-installer.se)
    
    # After installer finishes or user exits
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}                 INSTALLATION STATUS               ${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Check if installation completed
    if [ -d "/var/www/pterodactyl" ]; then
        echo -e "${GREEN}✓ Panel files installed at /var/www/pterodactyl${NC}"
        
        # Fix nginx and ptero worker
        fix_nginx_ptero
        
        # Show login details
        echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}              📋 INSTALLATION COMPLETED 📋${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${GREEN}✅ Panel successfully installed!${NC}"
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}                 🔐 LOGIN DETAILS 🔐${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${BLUE}🌐 Panel URL:${NC} ${WHITE}https://bad-cat-91.telebit.io${NC}"
        echo ""
        echo -e "${BLUE}📧 Email:${NC} ${WHITE}admin@gmail.com${NC}"
        echo -e "${BLUE}👤 Username:${NC} ${WHITE}admin${NC}"
        echo -e "${BLUE}🔑 Password:${NC} ${WHITE}admin123${NC}"
        echo -e "${BLUE}👤 Full Name:${NC} ${WHITE}admin user${NC}"
        echo ""
        
        # Check SSL certificate
        echo -e "${YELLOW}Checking SSL certificate...${NC}"
        if [ -f "/etc/letsencrypt/live/bad-cat-91.telebit.io/fullchain.pem" ]; then
            echo -e "${GREEN}✓ SSL certificate found!${NC}"
            echo -e "${BLUE}Certificate path:${NC} /etc/letsencrypt/live/bad-cat-91.telebit.io/"
        else
            echo -e "${RED}⚠ SSL certificate not found!${NC}"
            echo -e "${YELLOW}To manually create SSL certificate:${NC}"
            echo -e "certbot --nginx -d bad-cat-91.telebit.io --email admin@gmail.com --agree-tos --no-eff-email"
        fi
    else
        echo -e "${RED}⚠ Panel installation may not have completed${NC}"
        echo -e "${YELLOW}Check if you need to run the installer again${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}Press Enter to return to main menu...${NC}"
    read -p ""
}

# Function to install Panel automatically (alternative)
install_panel_auto() {
    echo -e "${YELLOW}Starting Automatic Pterodactyl Panel Installation...${NC}"
    echo -e "${YELLOW}INSTALLATION OF PTERODACTYL PANEL EASILY - MADE BY WANNYDRAGON${NC}"
    echo ""
    
    echo -e "${RED}This will use automated script. For visible certificate process, use Option 3${NC}"
    echo -e "${YELLOW}Continue with automatic install? (y/n):${NC}"
    read -p " " auto_choice
    
    if [[ $auto_choice != "y" && $auto_choice != "Y" ]]; then
        echo -e "${YELLOW}Returning to menu...${NC}"
        return
    fi
    
    # Fixed settings as requested
    FQDN="bad-cat-91.telebit.io"
    EMAIL="admin@gmail.com"
    USERNAME="admin"
    PASSWORD="admin123"
    FIRST_NAME="admin"
    LAST_NAME="user"
    
    echo -e "${GREEN}Using fixed settings:${NC}"
    echo -e "${BLUE}FQDN:${NC} $FQDN"
    echo -e "${BLUE}Email:${NC} $EMAIL"
    echo -e "${BLUE}Username:${NC} $USERNAME"
    echo -e "${BLUE}Password:${NC} $PASSWORD"
    echo ""
    
    # Check if expect is installed
    if ! command -v expect &> /dev/null; then
        echo -e "${YELLOW}Installing expect package...${NC}"
        apt-get update && apt-get install expect -y
    fi
    
    # Create simplified expect script
    cat > /tmp/install_panel.exp << 'EOF'
#!/usr/bin/expect -f
set timeout -1

spawn bash <(curl -s https://pterodactyl-installer.se)

# Step-by-step with visible output
expect "*Input 0-6:*"
send "0\r"

expect "*Database name (panel):*"
send "\r"

expect "*Database username (pterodactyl):*"
send "\r"

expect "*Password (press enter to use randomly generated password):*"
send "\r"

expect "*Select timezone*"
send "\r"

expect "*Provide the email address that will be used to configure Let's Encrypt and Pterodactyl:*"
send "admin@gmail.com\r"

expect "*Email address for the initial admin account:*"
send "admin@gmail.com\r"

expect "*Username for the initial admin account:*"
send "admin\r"

expect "*First name for the initial admin account:*"
send "admin\r"

expect "*Last name for the initial admin account:*"
send "user\r"

expect "*Password for the initial admin account:*"
send "admin123\r"

expect "*Set the FQDN of this panel:*"
send "bad-cat-91.telebit.io\r"

expect "*Do you want to automatically configure UFW (firewall)? (y/N):*"
send "n\r"

expect "*Do you want to automatically configure HTTPS using Let's Encrypt? (y/N):*"
send "y\r"

expect "*I agree that this HTTPS request is performed (y/N):*"
send "y\r"

expect "*Proceed anyways (your install will be broken if you do not know what you are doing)? (y/N):*"
send "y\r"

expect "*Initial configuration completed. Continue with installation? (y/N):*"
send "y\r"

# Let user see telemetry prompt
expect "*Enable sending anonymous telemetry data? (yes/no) [yes]:*"
send "\r"

# Certificate process will be visible here
expect "*Do you agree?*"
send "y\r"

# Wait for certificate process to complete
expect eof
EOF
    
    chmod +x /tmp/install_panel.exp
    echo -e "${YELLOW}Starting installation with visible output...${NC}"
    echo -e "${GREEN}You will see certificate generation process now!${NC}"
    echo ""
    
    # Run expect with visible output
    expect -f /tmp/install_panel.exp
    rm -f /tmp/install_panel.exp
    
    # Post-installation
    fix_nginx_ptero
    
    # Show results
    show_installation_results
}

# Function to show installation results
show_installation_results() {
    echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}              📋 INSTALLATION RESULTS 📋${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Check SSL certificate
    echo -e "${YELLOW}SSL Certificate Status:${NC}"
    if [ -f "/etc/letsencrypt/live/bad-cat-91.telebit.io/fullchain.pem" ]; then
        echo -e "${GREEN}✓ SSL certificate successfully obtained!${NC}"
        echo -e "${BLUE}Certificate valid until:${NC}"
        openssl x509 -in /etc/letsencrypt/live/bad-cat-91.telebit.io/fullchain.pem -noout -enddate 2>/dev/null || echo "Could not read certificate"
    elif [ -f "/etc/letsencrypt/live/$(hostname)/fullchain.pem" ]; then
        echo -e "${GREEN}✓ SSL certificate found for $(hostname)${NC}"
    else
        echo -e "${RED}⚠ SSL certificate not found${NC}"
        echo -e "${YELLOW}You may need to manually run:${NC}"
        echo -e "certbot --nginx -d bad-cat-91.telebit.io --email admin@gmail.com --agree-tos --no-eff-email"
    fi
    
    echo ""
    echo -e "${YELLOW}Service Status:${NC}"
    echo -e "Nginx: $(systemctl is-active nginx 2>/dev/null || echo 'Not installed')"
    echo -e "MariaDB: $(systemctl is-active mariadb 2>/dev/null || echo 'Not installed')"
    echo -e "PHP-FPM: $(systemctl is-active php*-fpm 2>/dev/null | head -1 || echo 'Not installed')"
    echo -e "Ptero Queue: $(systemctl is-active pteroq 2>/dev/null || echo 'Not installed')"
    
    echo ""
    echo -e "${YELLOW}Panel Files:${NC}"
    if [ -d "/var/www/pterodactyl" ]; then
        echo -e "${GREEN}✓ Panel installed at /var/www/pterodactyl${NC}"
        echo -e "${BLUE}Disk usage:${NC} $(du -sh /var/www/pterodactyl 2>/dev/null | cut -f1)"
    else
        echo -e "${RED}⚠ Panel files not found${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}Press Enter to return to main menu...${NC}"
    read -p ""
}

# Function to install Wings automatically with n n n y and SSL setup
install_wings_auto() {
    echo -e "${YELLOW}Starting Automatic Wings Installation...${NC}"
    echo ""
    
    # Check if expect is installed
    if ! command -v expect &> /dev/null; then
        echo -e "${YELLOW}Installing expect package...${NC}"
        apt-get update && apt-get install expect -y
    fi
    
    echo -e "${YELLOW}Starting installation...${NC}"
    
    # Create expect script for automatic installation with n n n y
    cat > /tmp/install_wings.exp << 'EOF'
#!/usr/bin/expect -f
set timeout -1

spawn bash <(curl -s https://pterodactyl-installer.se)
sleep 2

# Wait for initial prompt
expect "*Input 0-6:*"
send "1\r"
sleep 2

# Wait for UFW prompt - answer n
expect "*Do you want to automatically configure UFW (firewall)? (y/N):*"
send "n\r"
sleep 2

# Wait for database user prompt - answer n
expect "*Do you want to automatically configure a user for database hosts? (y/N):*"
send "n\r"
sleep 2

# Wait for Let's Encrypt prompt - answer n
expect "*Do you want to automatically configure HTTPS using Let's Encrypt? (y/N):*"
send "n\r"
sleep 2

# Wait for installation confirmation - answer y
expect "*Proceed with installation? (y/N):*"
send "y\r"
sleep 2

expect eof
EOF
    
    chmod +x /tmp/install_wings.exp
    echo -e "${YELLOW}Starting Wings installation (n n n y)...${NC}"
    expect /tmp/install_wings.exp
    rm -f /tmp/install_wings.exp
    
    echo -e "${GREEN}✓ Wings base installation completed!${NC}"
    
    # Automatically run SSL certificate setup
    echo -e "${YELLOW}Setting up SSL certificates...${NC}"
    mkdir -p /etc/certs && cd /etc/certs && openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/C=NA/ST=NA/L=NA/O=NA/CN=Generic SSL Certificate" -keyout privkey.pem -out fullchain.pem && cd && clear
    
    echo -e "${GREEN}✓ SSL certificates created at /etc/certs/${NC}"
    
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}                 📋 WINGS INSTALLATION COMPLETE 📋${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}✅ Wings successfully installed!${NC}"
    echo ""
    echo -e "${BLUE}Certificate location:${NC} /etc/certs/"
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. nano /etc/pterodactyl/config.yml"
    echo "2. Update: cert: /etc/certs/fullchain.pem"
    echo "3. Update: key: /etc/certs/privkey.pem"
    echo "4. systemctl start wings"
    echo ""
    
    echo -e "${GREEN}Press Enter to return to main menu...${NC}"
    read -p ""
}

# Function to fix nginx and ptero worker
fix_nginx_ptero() {
    echo -e "${YELLOW}Setting up services...${NC}"
    
    # Start and enable services
    systemctl start nginx 2>/dev/null && systemctl enable nginx 2>/dev/null
    systemctl start mariadb 2>/dev/null && systemctl enable mariadb 2>/dev/null
    
    # Setup pteroq if needed
    if [ ! -f /etc/systemd/system/pteroq.service ] && [ -d /var/www/pterodactyl ]; then
        echo -e "${YELLOW}Creating pteroq service...${NC}"
        cat > /etc/systemd/system/pteroq.service << 'EOF'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl start pteroq
        systemctl enable pteroq
    fi
    
    # Fix permissions
    if [ -d "/var/www/pterodactyl" ]; then
        chown -R www-data:www-data /var/www/pterodactyl/storage
        chown -R www-data:www-data /var/www/pterodactyl/bootstrap/cache
    fi
    
    echo -e "${GREEN}✓ Services configured${NC}"
}

# Main menu
show_menu() {
    clear
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
    echo -e "${RED}  1) Install Panel (Manual - See Certificate Process)${NC}"
    echo -e "${RED}  2) Install Panel (Automatic)${NC}"
    echo -e "${RED}  3) Install Wings (Automatic with SSL)${NC}"
    echo -e "${RED}  4) Complete Setup (Panel + Wings)${NC}"
    echo -e "${RED}  5) System Information${NC}"
    echo -e "${RED}  0) Exit${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📝 Select an option [0-5]:${NC} "
}

# Main execution
while true; do
    show_menu
    read -p " " choice
    
    case $choice in
        1)
            check_requirements
            install_panel_manual
            ;;
        2)
            check_requirements
            install_panel_auto
            ;;
        3)
            check_requirements
            install_wings_auto
            ;;
        4)
            echo -e "\n${YELLOW}Starting Complete Setup...${NC}"
            check_requirements
            install_panel_manual
            echo -e "${YELLOW}Now installing Wings...${NC}"
            install_wings_auto
            ;;
        5)
            echo -e "${YELLOW}System Information:${NC}"
            echo -e "${BLUE}OS:${NC} $(lsb_release -d | cut -f2 2>/dev/null || echo 'Unknown')"
            echo -e "${BLUE}Kernel:${NC} $(uname -r)"
            echo -e "${BLUE}RAM:${NC} $(free -h | awk '/^Mem:/ {print $2}')"
            echo -e "${BLUE}Disk:${NC} $(df -h / | awk 'NR==2 {print $4 " free"}')"
            echo -e "${BLUE}IP:${NC} $(curl -s ifconfig.me 2>/dev/null || echo 'Unknown')"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        0)
            echo -e "\n${RED}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid option!${NC}"
            sleep 2
            ;;
    esac
done
