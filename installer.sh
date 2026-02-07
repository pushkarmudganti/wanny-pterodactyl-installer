#!/bin/bash

# Clear screen
clear

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
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

# Function to fix nginx and ptero worker
fix_nginx_ptero() {
    echo -e "${YELLOW}Fixing Nginx and Ptero Worker services...${NC}"
    
    # Fix Nginx configuration
    if systemctl is-active --quiet nginx; then
        echo -e "${GREEN}✓ Nginx is already running${NC}"
    else
        echo -e "${YELLOW}Starting Nginx...${NC}"
        systemctl start nginx
        systemctl enable nginx
        sleep 5
        
        if systemctl is-active --quiet nginx; then
            echo -e "${GREEN}✓ Nginx started successfully${NC}"
        else
            echo -e "${RED}⚠ Nginx failed to start. Checking configuration...${NC}"
            nginx -t
            echo -e "${YELLOW}Fixing Nginx configuration...${NC}"
            
            # Check and fix common Nginx issues
            if [ -f /etc/nginx/sites-available/pterodactyl.conf ]; then
                # Ensure proper permissions
                chown -R www-data:www-data /var/www/pterodactyl
                chmod -R 755 /var/www/pterodactyl
                
                # Restart Nginx
                systemctl restart nginx
                systemctl enable nginx
                
                if systemctl is-active --quiet nginx; then
                    echo -e "${GREEN}✓ Nginx fixed and started${NC}"
                else
                    echo -e "${RED}❌ Nginx still not working. Check logs: journalctl -u nginx${NC}"
                fi
            fi
        fi
    fi
    
    # Fix Ptero Queue Worker
    if systemctl is-active --quiet pteroq; then
        echo -e "${GREEN}✓ Ptero Queue Worker is already running${NC}"
    else
        echo -e "${YELLOW}Starting Ptero Queue Worker...${NC}"
        
        # Create pteroq systemd service if it doesn't exist
        if [ ! -f /etc/systemd/system/pteroq.service ]; then
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
        fi
        
        # Set proper permissions
        chown -R www-data:www-data /var/www/pterodactyl/storage
        chown -R www-data:www-data /var/www/pterodactyl/bootstrap/cache
        
        # Start pteroq
        systemctl start pteroq
        systemctl enable pteroq
        sleep 5
        
        if systemctl is-active --quiet pteroq; then
            echo -e "${GREEN}✓ Ptero Queue Worker started successfully${NC}"
        else
            echo -e "${RED}⚠ Ptero Queue Worker failed to start${NC}"
            echo -e "${YELLOW}Checking PHP requirements...${NC}"
            
            # Check PHP and install missing extensions
            apt-get install -y php-common php-cli php-fpm php-mysql php-mbstring php-xml php-curl php-zip php-gd php-bcmath
            
            # Restart services
            systemctl restart php8.1-fpm || systemctl restart php8.0-fpm || systemctl restart php7.4-fpm
            systemctl restart pteroq
            
            if systemctl is-active --quiet pteroq; then
                echo -e "${GREEN}✓ Ptero Queue Worker fixed and started${NC}"
            else
                echo -e "${RED}❌ Ptero Queue Worker still not working. Check logs: journalctl -u pteroq${NC}"
            fi
        fi
    fi
    
    # Check and fix PHP-FPM
    if systemctl is-active --quiet php8.1-fpm || systemctl is-active --quiet php8.0-fpm || systemctl is-active --quiet php7.4-fpm; then
        echo -e "${GREEN}✓ PHP-FPM is running${NC}"
    else
        echo -e "${YELLOW}Starting PHP-FPM...${NC}"
        systemctl restart php8.1-fpm || systemctl restart php8.0-fpm || systemctl restart php7.4-fpm
        sleep 5
    fi
    
    # Check Redis (required for queue)
    if systemctl is-active --quiet redis-server; then
        echo -e "${GREEN}✓ Redis is running${NC}"
    else
        echo -e "${YELLOW}Starting Redis...${NC}"
        apt-get install -y redis-server
        systemctl start redis-server
        systemctl enable redis-server
        sleep 5
    fi
    
    echo ""
}

# Function to install Panel automatically with special handling for telemetry and certificate
install_panel_auto() {
    echo -e "${YELLOW}Starting Automatic Pterodactyl Panel Installation...${NC}"
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
    
    # Check and install required packages
    echo -e "${YELLOW}Installing required packages...${NC}"
    apt-get update
    apt-get install -y expect curl git mariadb-server nginx certbot python3-certbot-nginx php-fpm php-common php-cli php-gd php-mysql php-mbstring php-bcmath php-xml php-fpm php-curl php-zip
    
    # Check if expect is installed
    if ! command -v expect &> /dev/null; then
        echo -e "${YELLOW}Installing expect package...${NC}"
        apt-get install expect -y
    fi
    
    echo -e "${YELLOW}Starting installation...${NC}"
    
    # Create expect script for automatic installation with special handling
    cat > /tmp/install_panel.exp << 'EOF'
#!/usr/bin/expect -f
set timeout -1

spawn bash <(curl -s https://pterodactyl-installer.se)
sleep 5

# Wait for initial prompt
expect "*Input 0-6:*"
send "0\r"
sleep 5

# Wait for database name prompt and press enter for default
expect "*Database name (panel):*"
send "\r"
sleep 5

# Wait for database username prompt and press enter for default
expect "*Database username (pterodactyl):*"
send "\r"
sleep 5

# Wait for password prompt and press enter for random password
expect "*Password (press enter to use randomly generated password):*"
send "\r"
sleep 5

# Wait for timezone prompt and press enter for default
expect "*Select timezone*"
send "\r"
sleep 5

# Wait for Let's Encrypt email prompt
expect "*Provide the email address that will be used to configure Let's Encrypt and Pterodactyl:*"
send "admin@gmail.com\r"
sleep 5

# Wait for admin email prompt
expect "*Email address for the initial admin account:*"
send "admin@gmail.com\r"
sleep 5

# Wait for username prompt
expect "*Username for the initial admin account:*"
send "admin\r"
sleep 5

# Wait for first name prompt
expect "*First name for the initial admin account:*"
send "admin\r"
sleep 5

# Wait for last name prompt
expect "*Last name for the initial admin account:*"
send "user\r"
sleep 5

# Wait for password prompt
expect "*Password for the initial admin account:*"
send "admin123\r"
sleep 5

# Wait for FQDN prompt
expect "*Set the FQDN of this panel:*"
send "bad-cat-91.telebit.io\r"
sleep 5

# Wait for UFW prompt
expect "*Do you want to automatically configure UFW (firewall)? (y/N):*"
send "n\r"
sleep 5

# Wait for Let's Encrypt prompt
expect "*Do you want to automatically configure HTTPS using Let's Encrypt? (y/N):*"
send "y\r"
sleep 5

# Wait for Let's Encrypt agreement prompt
expect "*I agree that this HTTPS request is performed (y/N):*"
send "y\r"
sleep 5

# Wait for Cloudflare warning prompt
expect "*Proceed anyways (your install will be broken if you do not know what you are doing)? (y/N):*"
send "y\r"
sleep 5

# Wait for configuration confirmation
expect "*Initial configuration completed. Continue with installation? (y/N):*"
send "y\r"
sleep 5

# Wait for telemetry prompt and automatically answer Y after 3 minutes
expect "*Enable sending anonymous telemetry data? (yes/no) [yes]:*"
sleep 180  # Wait 3 minutes (180 seconds)
send "y\r"
sleep 5

# Wait for Let's Encrypt Terms of Service
expect "*Do you agree?*"
sleep 180  # Wait 3 minutes for certificate process
send "y\r"
sleep 5

# After certificate acceptance, send Ctrl+C to return to menu
expect "*WARNING: The process of obtaining a Let's Encrypt certificate failed!*" {
    send "\003"
    exp_continue
}
expect "*Still assume SSL? (y/N):*" {
    send "\003"
    exp_continue
}
expect eof
EOF
    
    chmod +x /tmp/install_panel.exp
    echo -e "${YELLOW}Starting automatic installation...${NC}"
    echo -e "${BLUE}Telemetry will be auto-accepted after 3 minutes...${NC}"
    echo -e "${BLUE}Certificate will be auto-accepted after 3 minutes...${NC}"
    echo -e "${BLUE}After installation, press Ctrl+C to return to menu${NC}"
    
    expect /tmp/install_panel.exp
    rm -f /tmp/install_panel.exp
    
    # Fix nginx and ptero worker
    fix_nginx_ptero
    
    # Show login details after installation
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
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  Important: Save these credentials!${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Final service status check
    echo -e "${YELLOW}Final Service Status:${NC}"
    echo -e "Nginx: $(systemctl is-active nginx)"
    echo -e "PHP-FPM: $(systemctl is-active php8.1-fpm || systemctl is-active php8.0-fpm || systemctl is-active php7.4-fpm || echo 'Not found')"
    echo -e "Ptero Queue: $(systemctl is-active pteroq)"
    echo -e "Redis: $(systemctl is-active redis-server)"
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
sleep 5

# Wait for initial prompt
expect "*Input 0-6:*"
send "1\r"
sleep 5

# Wait for UFW prompt - answer n
expect "*Do you want to automatically configure UFW (firewall)? (y/N):*"
send "n\r"
sleep 5

# Wait for database user prompt - answer n
expect "*Do you want to automatically configure a user for database hosts? (y/N):*"
send "n\r"
sleep 5

# Wait for Let's Encrypt prompt - answer n
expect "*Do you want to automatically configure HTTPS using Let's Encrypt? (y/N):*"
send "n\r"
sleep 5

# Wait for installation confirmation - answer y
expect "*Proceed with installation? (y/N):*"
send "y\r"
sleep 5

expect eof
EOF
    
    chmod +x /tmp/install_wings.exp
    echo -e "${YELLOW}Starting Wings installation (n n n y)...${NC}"
    expect /tmp/install_wings.exp
    rm -f /tmp/install_wings.exp
    
    echo -e "${GREEN}✓ Wings base installation completed!${NC}"
    
    # Automatically run SSL certificate setup
    echo -e "${YELLOW}Setting up SSL certificates automatically...${NC}"
    mkdir -p /etc/certs && cd /etc/certs && openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/C=NA/ST=NA/L=NA/O=NA/CN=Generic SSL Certificate" -keyout privkey.pem -out fullchain.pem && cd && clear
    
    echo -e "${GREEN}✓ SSL certificates created at /etc/certs/${NC}"
    
    # Display certificate details
    echo -e "${YELLOW}Certificate Details:${NC}"
    echo -e "${BLUE}Location:${NC} /etc/certs/"
    echo -e "${BLUE}Private Key:${NC} privkey.pem"
    echo -e "${BLUE}Certificate:${NC} fullchain.pem"
    echo ""
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}                 📋 WINGS INSTALLATION COMPLETE 📋${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}✅ Wings successfully installed!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps to configure Wings:${NC}"
    echo ""
    echo -e "${BLUE}1. Edit config file:${NC}"
    echo -e "   nano /etc/pterodactyl/config.yml"
    echo ""
    echo -e "${BLUE}2. Update SSL certificate paths to:${NC}"
    echo -e "   cert: /etc/certs/fullchain.pem"
    echo -e "   key: /etc/certs/privkey.pem"
    echo ""
    echo -e "${BLUE}3. Start Wings:${NC}"
    echo -e "   Test mode: ${GREEN}wings --debug${NC}"
    echo -e "   As service: ${GREEN}systemctl start wings${NC}"
    echo -e "   Enable on boot: ${GREEN}systemctl enable wings${NC}"
    echo ""
    echo -e "${BLUE}4. Check status:${NC}"
    echo -e "   systemctl status wings"
    echo ""
    
    echo -e "${GREEN}Press Enter to return to main menu...${NC}"
    read -p ""
}

# Function to install Cloudflared
install_cloudflared() {
    echo -e "${YELLOW}Installing Cloudflared...${NC}"
    sleep 5
    
    # Add cloudflare gpg key
    sudo mkdir -p --mode=0755 /usr/share/keyrings
    curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
    
    # Add repo to apt
    echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list
    
    # Install cloudflared
    sudo apt-get update && sudo apt-get install cloudflared -y
    
    echo -e "${GREEN}✓ Cloudflared installed successfully${NC}"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}                 📋 CLOUDFLARE SETUP 📋${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}1. Go to:${NC} https://one.dash.cloudflare.com/"
    echo -e "${BLUE}2. Network → Tunnel → Create Tunnel${NC}"
    echo -e "${BLUE}3. Name:${NC} PTERODACTYL"
    echo -e "${BLUE}4. Add application routes:${NC}"
    echo -e "   - Panel: panel.yourdomain.com → localhost:80"
    echo -e "   - Node: node.yourdomain.com → localhost:8443"
    echo -e "${BLUE}5. Use token from Cloudflare dashboard${NC}"
    echo ""
    
    echo -e "${GREEN}Press Enter to return to main menu...${NC}"
    read -p ""
}

# Function to show system information
show_system_info() {
    echo -e "${YELLOW}System Information:${NC}"
    echo -e "${BLUE}OS:${NC} $(lsb_release -d | cut -f2)"
    echo -e "${BLUE}Kernel:${NC} $(uname -r)"
    echo -e "${BLUE}Uptime:${NC} $(uptime -p | sed 's/up //')"
    echo -e "${BLUE}RAM:${NC} $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo -e "${BLUE}Disk:${NC} $(df -h / | awk 'NR==2 {print $4 " free / " $2 " total"}')"
    echo -e "${BLUE}IP:${NC} $(curl -s ifconfig.me)"
    echo ""
    
    echo -e "${GREEN}Press Enter to return to main menu...${NC}"
    read -p ""
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
    echo -e "${RED}  1) Install Pterodactyl Panel (Automatic)${NC}"
    echo -e "${RED}  2) Install Wings (Automatic with SSL)${NC}"
    echo -e "${RED}  3) Complete Setup (Panel + Wings)${NC}"
    echo -e "${RED}  4) Install Cloudflared${NC}"
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
            install_panel_auto
            ;;
        2)
            check_requirements
            install_wings_auto
            ;;
        3)
            echo -e "\n${YELLOW}Starting Complete Pterodactyl Setup...${NC}"
            check_requirements
            install_panel_auto
            echo -e "${YELLOW}Panel installed. Now installing Wings...${NC}"
            install_wings_auto
            echo -e "${GREEN}✓ Complete Pterodactyl setup finished!${NC}"
            ;;
        4)
            install_cloudflared
            ;;
        5)
            show_system_info
            ;;
        0)
            echo -e "\n${RED}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid option!${NC}"
            ;;
    esac
doneBLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Function to check system requirements
check_requirements() {
    echo -e "${YELLOW}Checking system requirements...${NC}"
    
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

# Function to install Panel automatically
install_panel_auto() {
    echo -e "${YELLOW}Starting Automatic Pterodactyl Panel Installation...${NC}"
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
    
    # Check if expect is installed
    if ! command -v expect &> /dev/null; then
        echo -e "${YELLOW}Installing expect package...${NC}"
        apt-get update && apt-get install expect -y
    fi
    
    # Create expect script for automatic installation
    cat > /tmp/install_panel.exp << EOF
#!/usr/bin/expect -f
set timeout -1

spawn bash <(curl -s https://pterodactyl-installer.se)

# Wait for initial prompt
expect "*Input 0-6:*"
send "0\r"

# Wait for database name prompt and press enter for default
expect "*Database name (panel):*"
send "\r"

# Wait for database username prompt and press enter for default
expect "*Database username (pterodactyl):*"
send "\r"

# Wait for password prompt and press enter for random password
expect "*Password (press enter to use randomly generated password):*"
send "\r"

# Wait for timezone prompt and press enter for default
expect "*Select timezone*"
send "\r"

# Wait for Let's Encrypt email prompt
expect "*Provide the email address that will be used to configure Let's Encrypt and Pterodactyl:*"
send "$EMAIL\r"

# Wait for admin email prompt
expect "*Email address for the initial admin account:*"
send "$EMAIL\r"

# Wait for username prompt
expect "*Username for the initial admin account:*"
send "$USERNAME\r"

# Wait for first name prompt
expect "*First name for the initial admin account:*"
send "$FIRST_NAME\r"

# Wait for last name prompt
expect "*Last name for the initial admin account:*"
send "$LAST_NAME\r"

# Wait for password prompt
expect "*Password for the initial admin account:*"
send "$PASSWORD\r"

# Wait for FQDN prompt
expect "*Set the FQDN of this panel:*"
send "$FQDN\r"

# Wait for UFW prompt
expect "*Do you want to automatically configure UFW (firewall)? (y/N):*"
send "n\r"

# Wait for Let's Encrypt prompt
expect "*Do you want to automatically configure HTTPS using Let's Encrypt? (y/N):*"
send "y\r"

# Wait for Let's Encrypt agreement prompt
expect "*I agree that this HTTPS request is performed (y/N):*"
send "y\r"

# Wait for Cloudflare warning prompt
expect "*Proceed anyways (your install will be broken if you do not know what you are doing)? (y/N):*"
send "y\r"

# Wait for configuration confirmation
expect "*Initial configuration completed. Continue with installation? (y/N):*"
send "y\r"

# Wait for telemetry prompt
expect "*Enable sending anonymous telemetry data? (yes/no) [yes]:*"
send "\r"

# Wait for Let's Encrypt Terms of Service
expect "*Do you agree?*"
send "y\r"

expect eof
EOF
    
    chmod +x /tmp/install_panel.exp
    echo -e "${YELLOW}Starting automatic installation...${NC}"
    expect /tmp/install_panel.exp
    rm -f /tmp/install_panel.exp
    
    # Show login details after installation
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
    echo -e "${BLUE}🌐 Panel URL:${NC} ${WHITE}https://$FQDN${NC}"
    echo ""
    echo -e "${BLUE}📧 Email:${NC} ${WHITE}$EMAIL${NC}"
    echo -e "${BLUE}👤 Username:${NC} ${WHITE}$USERNAME${NC}"
    echo -e "${BLUE}🔑 Password:${NC} ${WHITE}$PASSWORD${NC}"
    echo -e "${BLUE}👤 Full Name:${NC} ${WHITE}$FIRST_NAME $LAST_NAME${NC}"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  Important: Save these credentials!${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Check panel services
    echo -e "${YELLOW}Checking panel services...${NC}"
    if systemctl is-active --quiet nginx; then
        echo -e "${GREEN}✓ Nginx is running${NC}"
    else
        echo -e "${RED}⚠ Nginx is not running${NC}"
    fi
    
    if systemctl is-active --quiet pteroq; then
        echo -e "${GREEN}✓ Ptero Queue Worker is running${NC}"
    else
        echo -e "${RED}⚠ Ptero Queue Worker is not running${NC}"
    fi
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
    
    # Create expect script for automatic installation with n n n y
    cat > /tmp/install_wings.exp << EOF
#!/usr/bin/expect -f
set timeout -1

spawn bash <(curl -s https://pterodactyl-installer.se)

# Wait for initial prompt
expect "*Input 0-6:*"
send "1\r"

# Wait for UFW prompt - answer n
expect "*Do you want to automatically configure UFW (firewall)? (y/N):*"
send "n\r"

# Wait for database user prompt - answer n
expect "*Do you want to automatically configure a user for database hosts? (y/N):*"
send "n\r"

# Wait for Let's Encrypt prompt - answer n
expect "*Do you want to automatically configure HTTPS using Let's Encrypt? (y/N):*"
send "n\r"

# Wait for installation confirmation - answer y
expect "*Proceed with installation? (y/N):*"
send "y\r"

expect eof
EOF
    
    chmod +x /tmp/install_wings.exp
    echo -e "${YELLOW}Starting Wings installation (n n n y)...${NC}"
    expect /tmp/install_wings.exp
    rm -f /tmp/install_wings.exp
    
    echo -e "${GREEN}✓ Wings base installation completed!${NC}"
    
    # Automatically run SSL certificate setup
    echo -e "${YELLOW}Setting up SSL certificates automatically...${NC}"
    mkdir -p /etc/certs && cd /etc/certs && openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/C=NA/ST=NA/L=NA/O=NA/CN=Generic SSL Certificate" -keyout privkey.pem -out fullchain.pem && cd && clear
    
    echo -e "${GREEN}✓ SSL certificates created at /etc/certs/${NC}"
    
    # Display certificate details
    echo -e "${YELLOW}Certificate Details:${NC}"
    echo -e "${BLUE}Location:${NC} /etc/certs/"
    echo -e "${BLUE}Private Key:${NC} privkey.pem"
    echo -e "${BLUE}Certificate:${NC} fullchain.pem"
    echo ""
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}                 📋 WINGS INSTALLATION COMPLETE 📋${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}✅ Wings successfully installed!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps to configure Wings:${NC}"
    echo ""
    echo -e "${BLUE}1. Edit config file:${NC}"
    echo -e "   nano /etc/pterodactyl/config.yml"
    echo ""
    echo -e "${BLUE}2. Update SSL certificate paths to:${NC}"
    echo -e "   cert: /etc/certs/fullchain.pem"
    echo -e "   key: /etc/certs/privkey.pem"
    echo ""
    echo -e "${BLUE}3. Start Wings:${NC}"
    echo -e "   Test mode: ${GREEN}wings --debug${NC}"
    echo -e "   As service: ${GREEN}systemctl start wings${NC}"
    echo -e "   Enable on boot: ${GREEN}systemctl enable wings${NC}"
    echo ""
    echo -e "${BLUE}4. Check status:${NC}"
    echo -e "   systemctl status wings"
    echo ""
}

# Function to install Cloudflared
install_cloudflared() {
    echo -e "${YELLOW}Installing Cloudflared...${NC}"
    
    # Add cloudflare gpg key
    sudo mkdir -p --mode=0755 /usr/share/keyrings
    curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
    
    # Add repo to apt
    echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list
    
    # Install cloudflared
    sudo apt-get update && sudo apt-get install cloudflared -y
    
    echo -e "${GREEN}✓ Cloudflared installed successfully${NC}"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}                 📋 CLOUDFLARE SETUP 📋${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}1. Go to:${NC} https://one.dash.cloudflare.com/"
    echo -e "${BLUE}2. Network → Tunnel → Create Tunnel${NC}"
    echo -e "${BLUE}3. Name:${NC} PTERODACTYL"
    echo -e "${BLUE}4. Add application routes:${NC}"
    echo -e "   - Panel: panel.yourdomain.com → localhost:80"
    echo -e "   - Node: node.yourdomain.com → localhost:8443"
    echo -e "${BLUE}5. Use token from Cloudflare dashboard${NC}"
    echo ""
}

# Function to show system information
show_system_info() {
    echo -e "${YELLOW}System Information:${NC}"
    echo -e "${BLUE}OS:${NC} $(lsb_release -d | cut -f2)"
    echo -e "${BLUE}Kernel:${NC} $(uname -r)"
    echo -e "${BLUE}Uptime:${NC} $(uptime -p | sed 's/up //')"
    echo -e "${BLUE}RAM:${NC} $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo -e "${BLUE}Disk:${NC} $(df -h / | awk 'NR==2 {print $4 " free / " $2 " total"}')"
    echo -e "${BLUE}IP:${NC} $(curl -s ifconfig.me)"
    echo ""
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
    echo -e "${RED}  1) Install Pterodactyl Panel (Automatic)${NC}"
    echo -e "${RED}  2) Install Wings (Automatic with SSL)${NC}"
    echo -e "${RED}  3) Complete Setup (Panel + Wings)${NC}"
    echo -e "${RED}  4) Install Cloudflared${NC}"
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
            install_panel_auto
            ;;
        2)
            check_requirements
            install_wings_auto
            ;;
        3)
            echo -e "\n${YELLOW}Starting Complete Pterodactyl Setup...${NC}"
            check_requirements
            install_panel_auto
            echo -e "${YELLOW}Panel installed. Now installing Wings...${NC}"
            install_wings_auto
            echo -e "${GREEN}✓ Complete Pterodactyl setup finished!${NC}"
            ;;
        4)
            install_cloudflared
            ;;
        5)
            show_system_info
            ;;
        0)
            echo -e "\n${RED}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid option!${NC}"
            ;;
    esac
    
    echo -e "\n${YELLOW}Press Enter to continue...${NC}"
    read -p ""
done
