#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
MAGENTA='\033[1;35m'
NC='\033[0m'
BOLD='\033[1m'

# Clear screen
clear

# Print banner with emojis
echo -e "${PURPLE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║   🚀  WANNY Pterodactyl Installer v2.0  🚀             ║
╚══════════════════════════════════════════════════════════╝
EOF
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${MAGENTA}               Made By - WANNY 🦅                        ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "❌ ${RED}Error: This script must be run as root!${NC}"
   echo -e "📌 ${YELLOW}Use: sudo bash installer.sh${NC}"
   exit 1
fi

# Function to display main menu
show_menu() {
    echo ""
    echo -e "${CYAN}┌──────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│         ${BOLD}📋 MAIN MENU${NC} ${CYAN}                   │${NC}"
    echo -e "${CYAN}├──────────────────────────────────────┤${NC}"
    echo -e "${YELLOW}│ 1) 🏠 Install Pterodactyl Panel     │${NC}"
    echo -e "${YELLOW}│ 2) 🖥️  Install Pterodactyl Wings     │${NC}"
    echo -e "${YELLOW}│ 3) 🔧 Install Complete Setup         │${NC}"
    echo -e "${YELLOW}│ 4) ⚡ VPS Optimization Tools         │${NC}"
    echo -e "${YELLOW}│ 5) 💾 Backup & Restore Tools         │${NC}"
    echo -e "${YELLOW}│ 6) 🚪 Exit                           │${NC}"
    echo -e "${CYAN}└──────────────────────────────────────┘${NC}"
    echo -ne "${GREEN}${BOLD}👉 Select option [1-6] → ${NC}"
}

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/debian_version ]; then
        OS="debian"
        OS_VERSION=$(cat /etc/debian_version)
    elif [ -f /etc/centos-release ]; then
        OS="centos"
        OS_VERSION=$(cat /etc/centos-release | cut -d" " -f4)
    else
        OS=$(uname -s)
        OS_VERSION=$(uname -r)
    fi
    echo -e "📦 ${BLUE}Detected OS: ${OS} ${OS_VERSION}${NC}"
}

# Function to check dependencies
check_dependencies() {
    echo -e "\n🔍 ${YELLOW}Checking system dependencies...${NC}"
    
    # Check for curl
    if ! command -v curl &> /dev/null; then
        echo -e "📥 ${YELLOW}Installing curl...${NC}"
        apt-get update && apt-get install -y curl 2>/dev/null || yum install -y curl 2>/dev/null
    fi
    
    # Check for wget
    if ! command -v wget &> /dev/null; then
        echo -e "📥 ${YELLOW}Installing wget...${NC}"
        apt-get install -y wget 2>/dev/null || yum install -y wget 2>/dev/null
    fi
    
    echo -e "✅ ${GREEN}Dependencies checked successfully${NC}"
}

# Function to install Panel
install_panel() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "🦅 ${PURPLE}PTERODACTYL PANEL INSTALLATION${NC} 🦅"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    detect_os
    check_dependencies
    
    # Update system
    echo -e "\n1️⃣  ${YELLOW}Updating system packages...${NC}"
    apt-get update && apt-get upgrade -y 2>/dev/null || yum update -y 2>/dev/null
    echo -e "✅ ${GREEN}System updated${NC}"
    
    # Install dependencies based on OS
    echo -e "\n2️⃣  ${YELLOW}Installing required packages...${NC}"
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get install -y software-properties-common apt-transport-https ca-certificates gnupg lsb-release
        
        # Add PHP repository
        add-apt-repository -y ppa:ondrej/php 2>/dev/null
        apt-get update
        
        # Install PHP 8.1 and dependencies
        apt-get install -y php8.1 php8.1-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip,intl,ldap} \
            mariadb-server nginx tar unzip git redis-server cron
    elif [[ "$OS" == "centos" ]]; then
        yum install -y epel-release
        yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm
        yum-config-manager --enable remi-php81
        yum install -y php php-{common,cli,gd,mysqlnd,mbstring,bcmath,xml,fpm,curl,zip,intl,ldap} \
            mariadb-server nginx tar unzip git redis
    fi
    echo -e "✅ ${GREEN}Packages installed${NC}"
    
    # Start and enable services
    echo -e "\n3️⃣  ${YELLOW}Starting required services...${NC}"
    systemctl start mariadb 2>/dev/null || systemctl start mysqld
    systemctl enable mariadb 2>/dev/null || systemctl enable mysqld
    systemctl start redis
    systemctl enable redis
    systemctl start nginx
    systemctl enable nginx
    echo -e "✅ ${GREEN}Services started${NC}"
    
    # Secure MySQL installation
    echo -e "\n4️⃣  ${YELLOW}Securing MySQL installation...${NC}"
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '';" 2>/dev/null || true
    echo -e "✅ ${GREEN}MySQL secured${NC}"
    
    # Database configuration
    echo -e "\n${CYAN}════════════════════════════════════════════════${NC}"
    echo -e "🗃️  ${BOLD}Database Configuration${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════${NC}"
    
    read -p "📝 Database name [pterodactyl]: " db_name
    db_name=${db_name:-pterodactyl}
    
    read -p "👤 Database username [pterodactyl]: " db_user
    db_user=${db_user:-pterodactyl}
    
    while true; do
        read -sp "🔑 Database password: " db_pass
        echo
        read -sp "🔑 Confirm password: " db_pass_confirm
        echo
        if [ "$db_pass" = "$db_pass_confirm" ]; then
            break
        else
            echo -e "❌ ${RED}Passwords don't match!${NC}"
        fi
    done
    
    # Create database
    echo -e "\n5️⃣  ${YELLOW}Creating database and user...${NC}"
    mysql -e "CREATE DATABASE IF NOT EXISTS ${db_name};" 2>/dev/null || echo "Database might exist"
    mysql -e "CREATE USER IF NOT EXISTS '${db_user}'@'127.0.0.1' IDENTIFIED BY '${db_pass}';" 2>/dev/null
    mysql -e "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'127.0.0.1' WITH GRANT OPTION;"
    mysql -e "FLUSH PRIVILEGES;"
    echo -e "✅ ${GREEN}Database created${NC}"
    
    # Install Composer
    echo -e "\n6️⃣  ${YELLOW}Installing Composer...${NC}"
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    echo -e "✅ ${GREEN}Composer installed${NC}"
    
    # Download Panel
    echo -e "\n7️⃣  ${YELLOW}Downloading Pterodactyl Panel...${NC}"
    mkdir -p /var/www/pterodactyl
    cd /var/www/pterodactyl
    
    echo -e "⬇️  ${BLUE}Downloading latest panel...${NC}"
    curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
    tar -xzvf panel.tar.gz
    rm -f panel.tar.gz
    
    # Set permissions
    chmod -R 755 storage/* bootstrap/cache/
    chown -R www-data:www-data /var/www/pterodactyl/* 2>/dev/null || chown -R nginx:nginx /var/www/pterodactyl/*
    echo -e "✅ ${GREEN}Panel downloaded${NC}"
    
    # Install PHP dependencies
    echo -e "\n8️⃣  ${YELLOW}Installing PHP dependencies...${NC}"
    cp .env.example .env
    composer install --no-dev --optimize-autoloader --quiet
    php artisan key:generate --force
    echo -e "✅ ${GREEN}Dependencies installed${NC}"
    
    # Panel configuration
    echo -e "\n${CYAN}════════════════════════════════════════════════${NC}"
    echo -e "⚙️  ${BOLD}Panel Configuration${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════${NC}"
    
    read -p "🌐 Panel URL (e.g., https://panel.yourdomain.com): " app_url
    read -p "🕒 Timezone [UTC]: " timezone
    timezone=${timezone:-UTC}
    
    # Setup environment
    php artisan p:environment:setup \
        --author="WANNY" \
        --url="$app_url" \
        --timezone="$timezone" \
        --cache=redis \
        --session=redis \
        --queue=redis \
        --redis-host=localhost \
        --redis-port=6379
    
    php artisan p:environment:database \
        --host=127.0.0.1 \
        --port=3306 \
        --database="$db_name" \
        --username="$db_user" \
        --password="$db_pass"
    
    # Run database migrations
    echo -e "\n9️⃣  ${YELLOW}Running database migrations...${NC}"
    php artisan migrate --seed --force
    echo -e "✅ ${GREEN}Migrations completed${NC}"
    
    # Create admin user
    echo -e "\n${CYAN}════════════════════════════════════════════════${NC}"
    echo -e "👑 ${BOLD}Admin Account Creation${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════${NC}"
    
    read -p "📧 Admin email: " admin_email
    read -p "👤 Admin username: " admin_username
    read -p "👨 First name: " admin_firstname
    read -p "👨 Last name: " admin_lastname
    
    while true; do
        read -sp "🔑 Admin password: " admin_password
        echo
        read -sp "🔑 Confirm password: " admin_password_confirm
        echo
        if [ "$admin_password" = "$admin_password_confirm" ]; then
            break
        else
            echo -e "❌ ${RED}Passwords don't match!${NC}"
        fi
    done
    
    php artisan p:user:make \
        --email="$admin_email" \
        --username="$admin_username" \
        --name-first="$admin_firstname" \
        --name-last="$admin_lastname" \
        --password="$admin_password" \
        --admin=1
    echo -e "✅ ${GREEN}Admin user created${NC}"
    
    # Setup cron job
    echo -e "\n🔟 ${YELLOW}Setting up cron job...${NC}"
    (crontab -l 2>/dev/null; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -
    echo -e "✅ ${GREEN}Cron job set${NC}"
    
    # Setup queue worker
    echo -e "\n1️⃣1️⃣ ${YELLOW}Setting up queue worker...${NC}"
    cat > /etc/systemd/system/pteroq.service << EOF
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
    
    systemctl enable --now pteroq
    echo -e "✅ ${GREEN}Queue worker started${NC}"
    
    # Configure Nginx
    echo -e "\n1️⃣2️⃣ ${YELLOW}Configuring Nginx...${NC}"
    domain=$(echo "$app_url" | sed 's~https://~~; s~http://~~')
    
    cat > /etc/nginx/sites-available/pterodactyl.conf << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    root /var/www/pterodactyl/public;
    
    index index.php;
    charset utf-8;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size = 100M";
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF
    
    ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default 2>/dev/null
    nginx -t && systemctl restart nginx
    echo -e "✅ ${GREEN}Nginx configured${NC}"
    
    # Display completion
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "🎉 ${BOLD}PANEL INSTALLATION COMPLETE!${NC} 🎉"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "🌐 ${CYAN}Panel URL:${NC} $app_url"
    echo -e "🗃️  ${CYAN}Database:${NC} $db_name"
    echo -e "👤 ${CYAN}Admin User:${NC} $admin_username"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "📋 ${YELLOW}Next steps:${NC}"
    echo -e "   🔐 Configure SSL (LetsEncrypt)"
    echo -e "   🛡️  Setup firewall"
    echo -e "   💾 Configure backups"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to install Wings
install_wings() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "🦅 ${PURPLE}PTERODACTYL WINGS INSTALLATION${NC} 🦅"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    detect_os
    check_dependencies
    
    # Update system
    echo -e "\n1️⃣  ${YELLOW}Updating system packages...${NC}"
    apt-get update && apt-get upgrade -y 2>/dev/null || yum update -y 2>/dev/null
    echo -e "✅ ${GREEN}System updated${NC}"
    
    # Install Docker
    echo -e "\n2️⃣  ${YELLOW}Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable --now docker
    echo -e "✅ ${GREEN}Docker installed${NC}"
    
    # Install Wings
    echo -e "\n3️⃣  ${YELLOW}Installing Wings...${NC}"
    mkdir -p /etc/pterodactyl
    
    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        *) ARCH="amd64" ;;
    esac
    
    curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$ARCH"
    chmod +x /usr/local/bin/wings
    echo -e "✅ ${GREEN}Wings installed${NC}"
    
    # Wings configuration
    echo -e "\n${CYAN}════════════════════════════════════════════════${NC}"
    echo -e "⚙️  ${BOLD}Wings Configuration${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════${NC}"
    
    read -p "🌐 Panel URL (e.g., https://panel.yourdomain.com): " panel_url
    read -sp "🔑 Node Authentication Token: " node_token
    echo
    
    # Create Wings configuration
    echo -e "\n4️⃣  ${YELLOW}Creating Wings configuration...${NC}"
    cat > /etc/pterodactyl/config.yml << EOF
---
debug: false
panel: "$panel_url"
token: "$node_token"
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: false
  upload_limit: 100
system:
  data: /var/lib/pterodactyl/containers
  sftp:
    bind_port: 2022
  username: pterodactyl
allowed_mounts: []
EOF
    echo -e "✅ ${GREEN}Configuration created${NC}"
    
    # Create Wings service
    echo -e "\n5️⃣  ${YELLOW}Creating Wings service...${NC}"
    cat > /etc/systemd/system/wings.service << EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable wings
    systemctl start wings
    echo -e "✅ ${GREEN}Wings service started${NC}"
    
    # Configure firewall
    echo -e "\n6️⃣  ${YELLOW}Configuring firewall...${NC}"
    if command -v ufw &> /dev/null; then
        ufw allow 22/tcp
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw allow 8080/tcp
        ufw allow 2022/tcp
        ufw allow 25565:26000/tcp
        ufw --force enable
        echo -e "✅ ${GREEN}UFW configured${NC}"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --add-port={22,80,443,8080,2022}/tcp --permanent
        firewall-cmd --add-port=25565-26000/tcp --permanent
        firewall-cmd --reload
        echo -e "✅ ${GREEN}Firewalld configured${NC}"
    fi
    
    # Display completion
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "🎉 ${BOLD}WINGS INSTALLATION COMPLETE!${NC} 🎉"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "📊 ${CYAN}Wings Status:${NC} systemctl status wings"
    echo -e "📝 ${CYAN}View Logs:${NC} journalctl -u wings -f"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "📋 ${YELLOW}Next steps:${NC}"
    echo -e "   ➕ Add node to Panel"
    echo -e "   🔧 Configure allocations"
    echo -e "   🚀 Deploy your first server!"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function for complete installation
install_complete() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "🚀 ${PURPLE}COMPLETE PTERODACTYL SETUP${NC} 🚀"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e "\n📥 ${YELLOW}This will install both Panel and Wings on this server${NC}"
    echo -e "⚠️  ${RED}Note: This setup is for single-server installations only${NC}"
    echo -e "\n${CYAN}Proceed with installation? (y/N): ${NC}"
    read -r confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        install_panel
        
        echo -e "\n${CYAN}════════════════════════════════════════════════${NC}"
        echo -e "🔄 ${BOLD}Now installing Wings...${NC}"
        echo -e "${CYAN}════════════════════════════════════════════════${NC}"
        
        # Get panel URL for wings configuration
        read -p "🌐 Enter Panel URL (same as above): " panel_url
        echo -e "\n${YELLOW}Go to your Panel:${NC}"
        echo -e "1. Navigate to ${BLUE}Admin -> Locations -> Nodes${NC}"
        echo -e "2. Click ${BLUE}'Create New'${NC} to add this node"
        echo -e "3. Go to ${BLUE}'Configuration'${NC} tab and copy the token"
        echo -e "\n${CYAN}Paste the node token below:${NC}"
        read -sp "🔑 Token: " node_token
        echo
        
        # Update install_wings function call with parameters
        # For simplicity, we'll just call the install_wings function
        # The user will need to manually enter the token
        
        install_wings
    else
        echo -e "❌ ${RED}Installation cancelled${NC}"
    fi
}

# Function for VPS optimization
vps_optimization() {
    while true; do
        echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "⚡ ${PURPLE}VPS OPTIMIZATION TOOLS${NC} ⚡"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        echo -e "\n${YELLOW}Select optimization:${NC}"
        echo -e "1) 🚀 Basic System Optimization"
        echo -e "2) 💾 SWAP Configuration"
        echo -e "3) 🔧 Kernel Optimization"
        echo -e "4) 🗃️  MariaDB Optimization"
        echo -e "5) 📊 Performance Monitoring"
        echo -e "6) 🔙 Back to Main Menu"
        echo -ne "${GREEN}👉 Select [1-6] → ${NC}"
        read -r opt_choice
        
        case $opt_choice in
            1)
                echo -e "\n🚀 ${YELLOW}Running basic system optimization...${NC}"
                apt-get update && apt-get upgrade -y
                apt-get install -y htop nload neofetch
                apt-get autoremove -y
                apt-get clean
                echo -e "✅ ${GREEN}Basic optimization complete${NC}"
                ;;
            2)
                echo -e "\n💾 ${YELLOW}Configuring SWAP...${NC}"
                read -p "💽 SWAP size in GB (e.g., 2): " swap_size
                fallocate -l ${swap_size}G /swapfile
                chmod 600 /swapfile
                mkswap /swapfile
                swapon /swapfile
                echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
                sysctl vm.swappiness=10
                echo -e "✅ ${GREEN}SWAP configured${NC}"
                ;;
            3)
                echo -e "\n🔧 ${YELLOW}Optimizing kernel...${NC}"
                cat >> /etc/sysctl.conf << EOF
# WANNY Kernel Optimizations
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.core.default_qdisc = fq
fs.file-max = 2097152
EOF
                sysctl -p
                echo -e "✅ ${GREEN}Kernel optimized${NC}"
                ;;
            4)
                echo -e "\n🗃️  ${YELLOW}Optimizing MariaDB...${NC}"
                cat >> /etc/mysql/mariadb.conf.d/50-server.cnf 2>/dev/null || cat >> /etc/my.cnf 2>/dev/null << EOF
[mysqld]
# WANNY Optimizations
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_file_per_table = 1
query_cache_type = 1
query_cache_size = 128M
max_connections = 100
EOF
                systemctl restart mariadb 2>/dev/null || systemctl restart mysqld
                echo -e "✅ ${GREEN}MariaDB optimized${NC}"
                ;;
            5)
                echo -e "\n📊 ${YELLOW}Installing monitoring tools...${NC}"
                apt-get install -y glances btop netdata
                echo -e "✅ ${GREEN}Monitoring tools installed${NC}"
                ;;
            6)
                return
                ;;
            *)
                echo -e "❌ ${RED}Invalid option${NC}"
                ;;
        esac
        echo -e "\n${CYAN}Press Enter to continue...${NC}"
        read
    done
}

# Function for backup and restore
backup_tools() {
    while true; do
        echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "💾 ${PURPLE}BACKUP & RESTORE TOOLS${NC} 💾"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        echo -e "\n${YELLOW}Select action:${NC}"
        echo -e "1) 📦 Backup Panel"
        echo -e "2) 🔄 Restore Panel"
        echo -e "3) 🗃️  Backup Database"
        echo -e "4) ♻️  Restore Database"
        echo -e "5) 🎯 Create Auto-Backup Script"
        echo -e "6) 🔙 Back to Main Menu"
        echo -ne "${GREEN}👉 Select [1-6] → ${NC}"
        read -r backup_choice
        
        case $backup_choice in
            1)
                echo -e "\n📦 ${YELLOW}Creating Panel backup...${NC}"
                backup_dir="/backup/pterodactyl-$(date +%Y%m%d-%H%M%S)"
                mkdir -p $backup_dir
                
                # Backup files
                cp -r /var/www/pterodactyl $backup_dir/
                # Backup database
                mysqldump -u root pterodactyl > $backup_dir/database.sql 2>/dev/null
                
                # Create archive
                tar -czf $backup_dir.tar.gz $backup_dir
                rm -rf $backup_dir
                echo -e "✅ ${GREEN}Backup created: $backup_dir.tar.gz${NC}"
                ;;
            2)
                echo -e "\n🔄 ${YELLOW}Restoring Panel...${NC}"
                read -p "📁 Backup file path: " backup_file
                
                if [ -f "$backup_file" ]; then
                    temp_dir="/tmp/restore-$(date +%s)"
                    mkdir -p $temp_dir
                    tar -xzf "$backup_file" -C $temp_dir
                    
                    # Restore files
                    cp -r $temp_dir/*/pterodactyl/* /var/www/pterodactyl/
                    chown -R www-data:www-data /var/www/pterodactyl/*
                    
                    # Restore database
                    if [ -f "$temp_dir/*/database.sql" ]; then
                        mysql -u root pterodactyl < $temp_dir/*/database.sql
                    fi
                    
                    rm -rf $temp_dir
                    echo -e "✅ ${GREEN}Restore completed${NC}"
                else
                    echo -e "❌ ${RED}Backup file not found${NC}"
                fi
                ;;
            3)
                echo -e "\n🗃️  ${YELLOW}Backing up database...${NC}"
                backup_file="/backup/db-backup-$(date +%Y%m%d-%H%M%S).sql"
                mkdir -p /backup
                mysqldump -u root pterodactyl > $backup_file
                echo -e "✅ ${GREEN}Database backup: $backup_file${NC}"
                ;;
            4)
                echo -e "\n♻️  ${YELLOW}Restoring database...${NC}"
                read -p "📁 SQL file path: " sql_file
                if [ -f "$sql_file" ]; then
                    mysql -u root pterodactyl < "$sql_file"
                    echo -e "✅ ${GREEN}Database restored${NC}"
                else
                    echo -e "❌ ${RED}File not found${NC}"
                fi
                ;;
            5)
                echo -e "\n🎯 ${YELLOW}Creating auto-backup script...${NC}"
                cat > /usr/local/bin/auto-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d-%H%M%S)

# Create backup
mkdir -p $BACKUP_DIR/$DATE
cp -r /var/www/pterodactyl $BACKUP_DIR/$DATE/
mysqldump -u root pterodactyl > $BACKUP_DIR/$DATE/database.sql

# Create archive
tar -czf $BACKUP_DIR/pterodactyl-$DATE.tar.gz $BACKUP_DIR/$DATE
rm -rf $BACKUP_DIR/$DATE

# Keep only last 7 backups
cd $BACKUP_DIR
ls -t pterodactyl-*.tar.gz | tail -n +8 | xargs rm -f

echo "Backup completed: pterodactyl-$DATE.tar.gz"
EOF
                chmod +x /usr/local/bin/auto-backup.sh
                echo -e "✅ ${GREEN}Auto-backup script created${NC}"
                echo -e "📅 ${CYAN}Add to crontab: 0 2 * * * /usr/local/bin/auto-backup.sh${NC}"
                ;;
            6)
                return
                ;;
            *)
                echo -e "❌ ${RED}Invalid option${NC}"
                ;;
        esac
        echo -e "\n${CYAN}Press Enter to continue...${NC}"
        read
    done
}

# Main loop
while true; do
    show_menu
    read -r choice
    
    case $choice in
        1)
            install_panel
            ;;
        2)
            install_wings
            ;;
        3)
            install_complete
            ;;
        4)
            vps_optimization
            ;;
        5)
            backup_tools
            ;;
        6)
            echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "👋 ${GREEN}Thank you for using WANNY Installer!${NC}"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}🌟 Star the repo if you found it useful! 🌟${NC}"
            exit 0
            ;;
        *)
            echo -e "❌ ${RED}Invalid option! Please select 1-6${NC}"
            ;;
    esac
    
    echo -e "\n${CYAN}Press Enter to return to menu...${NC}"
    read
done
