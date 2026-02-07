#!/bin/bash

set -e

# exit with error status code if user is not root
if [[ $EUID -ne 0 ]]; then
  echo "* This script must be executed with root privileges (sudo)." 1>&2
  exit 1
fi

# check for curl
if ! [ -x "$(command -v curl)" ]; then
  echo "* curl is required in order for this script to work."
  echo "* install using apt (Debian and derivatives) or yum/dnf (CentOS)"
  exit 1
fi

output() {
  echo -e "\e[1;32m* ${1}\e[0m"
}

error() {
  echo ""
  echo -e "\e[1;31m* ERROR: ${1}\e[0m"
  echo ""
}

show_banner() {
  clear
  echo -e "\e[1;36m"
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║                                                          ║"
  echo "║   🐉  WANNY DRAGON PTERODACTYL INSTALLER  🐉            ║"
  echo "║                                                          ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo -e "\e[0m"
  echo -e "\e[1;33mSponsored by: Wanny Dragon Community\e[0m"
  echo -e "\e[1;33mVersion: Enhanced Edition\e[0m"
  echo
}

panel=false
wings=false
blueprint=false

show_banner

output "Pterodactyl installation script"
output
output "Copyright (C) 2018 - 2020, Vilhelm Prytz, <vilhelm@prytznet.se>, et al."
output "https://github.com/vilhelmprytz/pterodactyl-installer"
output
output "Sponsoring/Donations: https://github.com/vilhelmprytz/pterodactyl-installer?sponsor=1"
output "This script is not associated with the official Pterodactyl Project."
output

echo -e "\e[1;36m╔══════════════════════════════════════════════════════════╗"
echo -e "║                      🚀  MAIN MENU  🚀                    ║"
echo -e "╠══════════════════════════════════════════════════════════╣"
echo -e "║                                                          ║"
echo -e "║   \e[1;33m1️⃣   Install Pterodactyl Panel\e[1;36m                    ║"
echo -e "║   \e[1;33m2️⃣   Install Wings Daemon\e[1;36m                         ║"
echo -e "║   \e[1;33m3️⃣   Install Both (Panel + Wings)\e[1;36m                 ║"
echo -e "║   \e[1;33m4️⃣ 🏗️Install Blueprint\e[1;36m                         ║"
echo -e "║                                                          ║"
echo -e "║   \e[1;31m0️⃣   Exit\e[1;36m                                          ║"
echo -e "║                                                          ║"
echo -e "╚══════════════════════════════════════════════════════════╝\e[0m"
echo

while [ "$panel" == false ] && [ "$wings" == false ] && [ "$blueprint" == false ]; do
  echo -ne "\e[1;36m* Select option [0-4]: \e[0m"
  read -r action

  case $action in
      1 )
          panel=true
          echo -e "\n\e[1;32m✅ Selected: Pterodactyl Panel Installation\e[0m" ;;
      2 )
          wings=true
          echo -e "\n\e[1;32m✅ Selected: Wings Daemon Installation\e[0m" ;;
      3 )
          panel=true
          wings=true
          echo -e "\n\e[1;32m✅ Selected: Full Installation (Panel + Wings)\e[0m" ;;
      4 )
          blueprint=true
          echo -e "\n\e[1;32m✅ Selected: Blueprint Installation 🏗️\e[0m" ;;
      0 )
          echo -e "\n\e[1;33m👋 Exiting installer...\e[0m"
          exit 0 ;;
      * )
          error "Invalid option! Please enter 0-4" ;;
  esac
done

echo -e "\n\e[1;36m🚀 Starting installation process...\e[0m\n"

if [ "$panel" == true ]; then
  echo -e "\e[1;35m──────────────────────────────────────────\e[0m"
  echo -e "\e[1;35m         INSTALLING PTERODACTYL PANEL     \e[0m"
  echo -e "\e[1;35m──────────────────────────────────────────\e[0m"
bash <(curl -s "https://raw.githubusercontent.com/pushkarmudganti/wanny-pterodactyl-installer/blob/main/install-panel.sh"

if [ "$wings" == true ]; then
  echo -e "\n\e[1;35m──────────────────────────────────────────\e[0m"
  echo -e "\e[1;35m         INSTALLING WINGS DAEMON          \e[0m"
  echo -e "\e[1;35m──────────────────────────────────────────\e[0m"
  bash <(curl -s "https://raw.githubusercontent.com/pushkarmudganti/wanny-pterodactyl-installer/blob/main/install-wings.sh"
fi

if [ "$blueprint" == true ]; then
  echo -e "\n\e[1;35m──────────────────────────────────────────\e[0m"
  echo -e "\e[1;35m         INSTALLING BLUEPRINT 🏗️          \e[0m"
  echo -e "\e[1;35m──────────────────────────────────────────\e[0m"
  # Add Blueprint installation command here
  echo -e "\e[1;33m📦 Blueprint installation would be executed here\e[0m"
  # Example: bash <(curl -s https://raw.githubusercontent.com/pushkarmudganti/wanny_pterodactyl-installer/master/install-blueprint.sh)
fi

echo -e "\n\e[1;32m✨ Installation process completed! 🐉\e[0m"
echo -e "\e[1;33mThank you for using Wanny Dragon Installer!\e[0m\n"
