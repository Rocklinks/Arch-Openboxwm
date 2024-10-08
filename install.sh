#!/bin/bash
########################
# Author: Rocklin K S
# Date: 13/08/2024
# This script makes my config to autinstall
# Version: v2
############################


set -exo  pipefail

mkdir -p "$HOME/.config"

cp -Rf config/networkmanager-dmenu config/openbox config/xfce4 "$HOME/.config"

copy_normal_polybar() {
    cp -rf config/polybar $HOME/.config/
    echo "Normal Polybar configuration copied to ~/.config"
}

copy_transparent_polybar() {
    cp -rf config/polybar-transparent $HOME/.config/polybar
    echo "Transparent Polybar configuration copied to ~/.config/polybar"
}

# Prompt user for choice
echo "Select Polybar version:"
echo "1. Normal"
echo "2. Transparent"
read -p "Enter your choice (1 or 2): " choice

# Handle user choice
case $choice in
    1)
        copy_normal_polybar
        ;;
    2)
        copy_transparent_polybar
        ;;
    *)
        echo "Invalid choice. Please select 1 or 2."
        ;;
esac

# Change permissions for polybar scripts
chmod +x "$HOME/.config/polybar/scripts/"*
SYSTEM_CONFIG="$HOME/.config/polybar/system.ini"
POLYBAR_CONFIG="$HOME/.config/polybar/config.ini"

# Get the active Ethernet and Wi-Fi interfaces
ETHERNET=$(ip link | awk '/state UP/ && !/wl/ {print $2}' | tr -d :)
WIFI=$(ip link | awk '/state UP/ && /wl/ {print $2}' | tr -d :)

# Check if Wi-Fi is active
if [ -n "$WIFI" ]; then
    echo "Using Wi-Fi interface: $WIFI"
    # Replace wlan0 with the actual Wi-Fi interface name in system.ini
    sed -i "s/sys_network_interface = wlan0/sys_network_interface = $WIFI/" "$SYSTEM_CONFIG"
    
# Check if Ethernet is active
elif [ -n "$ETHERNET" ]; then
    echo "Using Ethernet interface: $ETHERNET"
    # Replace wlan0 with the Ethernet interface name in system.ini
    sed -i "s/sys_network_interface = wlan0/sys_network_interface = $ETHERNET/" "$SYSTEM_CONFIG"
    
    # Replace 'network' with 'ethernet' in config.ini
    sed -i "s/network/ethernet/g" "$POLYBAR_CONFIG"

else
    echo "No active network interfaces found."
fi


sudo -v

###### Check if yay is installed ###############
if ! command -v yay &> /dev/null; then
    sudo pacman -S yay --noconfirm
fi

if ! grep -q "chaotic-aur" /etc/pacman.conf; then
   sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
   sudo pacman-key --lsign-key 3056513887B78AEB
   sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
   sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
fi

PACMAN="/etc/pacman.conf"
CHAOTIC="[chaotic-aur]"
INCLUDE_LINE="Include = /etc/pacman.d/chaotic-mirrorlist"

if ! grep -q "$CHAOTIC" "$PACMAN"; then
    echo -e "\n$CHAOTIC\n$INCLUDE_LINE" >> "$PACMAN"
    echo "Added $CHAOTIC and $INCLUDE_LINE to $PACMAN."
else
    echo "$CHAOTIC already exists in $PACMAN."
fi

sudo pacman -Syu --noconfirm
packages=(
    zramswap preload python-dbus xarchiver xed thunar thunar-volman thunar-archive-plugin udiskie udisks2 tumbler gvfs
    xfce4-panel polkit-gnome xfdesktop blueman python-dbus firefox
    xfce4-settings xfce4-power-manager xfce4-docklike-plugin 
    bc openbox obconf playerctl xcompmgr parcellite gst-plugins-bad
    numlockx rofi polybar lxappearance gst-plugins-base
    zsh zsh-syntax-highlighting zsh-autosuggestions gst-plugins-ugly
   zsh-history-substring-search zsh-completions gst-plugins-good
)

# Install the packages if they are not already installed
for package in "${packages[@]}"; do
    if ! pacman -Q "$package" &> /dev/null; then
        sudo pacman -S "$package" --noconfirm
    else
        echo "$package is already installed. Skipping."
    fi
done

##Services to Enbale
enable_service() {
    local service_name=$1
    sudo systemctl enable "$service_name"
}

enable_service bluetooth
enable_service tlp
enable_service preload
enable_service zramswap

sudo cp -rf udev/rules.d/90-backlight.rules /etc/udev/rules.d/
# Rules for the brightness
USERNAME=$(whoami)
sudo sed -i "s/\$USER/$USERNAME/g" /etc/udev/rules.d/90-backlight.rules

sudo mkdir -p Fonts
sudo tar -xzvf Fonts.tar.gz -C Fonts
sudo cp -rf Fonts/ /usr/share/fonts/
sudo fc-cache -fv

stacer = http://archlinuxgr.tiven.org/archlinux/x86_64/stacer-1.1.0-1-x86_64.pkg.tar.zst
wget $stacer
sudo pacman -U stacer-1.1.0-1-x86_64.pkg.tar.zst --noconfirm
sudo rm -rf stacer-1.1.0-1-x86_64.pkg.tar.zst

xdm = https://github.com/subhra74/xdm/releases/download/8.0.29/xdman_gtk-8.0.29-1-x86_64.pkg.tar.zst
wget $xdm
sudo pacman -U xdman_gtk-8.0.29-1-x86_64.pkg.tar.zst --noconfirm
sudo rm -rf xdman_gtk-8.0.29-1-x86_64.pkg.tar.zst
# optional
home = $HOME
sudo mkdir -p zsh
sudo tar -xzvf zsh.tar.gz -C zsh
sudo cp -Rf zsh/.bashrc "$home/.bashrc"
sudo cp -Rf zsh/.zshrc "$home/.zshrc"
#############################################
THEMES_DIR="themes"
if [ ! -d "$THEMES_DIR" ]; then
    echo "Themes directory does not exist."
    exit 1
fi

for file in "$THEMES_DIR"/*.{xz,gz,zip}; do
    # Check if the file exists (to avoid errors if no files match)
    if [ -e "$file" ]; then
        echo "Extracting $file..."

        # Determine the file type and extract accordingly
        case "$file" in
            *.xz)
                # Extract .xz files
                sudo tar -xf "$file" -C "$THEMES_DIR"
                ;;
            *.gz)
                # Extract .gz files
                sudo tar -xzf "$file" -C "$THEMES_DIR"
                ;;
            *.zip)
                # Extract .gz files
                sudo unzip "$file" -C "$THEMES_DIR"
                ;;
        esac

        # Move the extracted folder to /usr/share/themes/
        extracted_folder="${file%.*}"  # Remove the file extension
        extracted_folder="${extracted_folder%.*}"  # Remove the second extension if any
        if [ -d "$extracted_folder" ]; then
            echo "Moving $extracted_folder to /usr/share/themes/"
            sudo mv "$extracted_folder" /usr/share/themes/
        else
            echo "No extracted folder found for $file."
        fi
    else
        echo "No .xz or .gz files found in $THEMES_DIR."
    fi
done

########################################################

## Icons
SOURCE_DIR="icons"

TARGET_DIR="/usr/share/icons"
for file in "$SOURCE_DIR"/*.tar.gz "$SOURCE_DIR"/*.tar.xz; do
    if [[ -e "$file" ]]; then
        if [[ "$file" == *.tar.gz ]]; then
            sudo tar -xzf "$file" -C /tmp/
        elif [[ "$file" == *.tar.xz ]]; then
            sudo tar -xf "$file" -C /tmp/
        fi
        sudo mv /tmp/* "$TARGET_DIR"/
        
        rm "$file"
    fi
done
echo "All operations completed successfully."

























