#!/bin/bash
########################
# Author: Rocklin K S
# Date: 13/08/2024
#
# This script outputs the helath
#
# Version: v1
############################


set -exo  pipefail
#Check if yay is installed
if ! command -v yay &> /dev/null; then
    sudo pacman -S yay
fi

# Function to check and add chaotic-aur repo
if ! grep -q "chaotic-aur" /etc/pacman.conf; then
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm
    sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
fi
PACMAN_CONF="/etc/pacman.conf"
CHAOTIC_AUR_SECTION="[chaotic-aur]"
INCLUDE_LINE="Include = /etc/pacman.d/chaotic-mirrorlist"

# Check if the section already exists in the file
if ! grep -q "$CHAOTIC_AUR_SECTION" "$PACMAN_CONF"; then
     Add the section to the end of the file
    echo -e "\n$CHAOTIC_AUR_SECTION\n$INCLUDE_LINE" >> "$PACMAN_CONF"
    echo "Added $CHAOTIC_AUR_SECTION and $INCLUDE_LINE to $PACMAN_CONF."
else
    echo "$CHAOTIC_AUR_SECTION already exists in $PACMAN_CONF."
fi

sudo pacman -Syu --noconfirm
# Define the list of packages to install
packages=(
    zramswap preload python-dbus auto-cpufreq
    xfce4-panel polkit-gnome xfdesktop blueman
    xfce4-settings xfce4-power-manager xfce4-docklike-plugin
    bc openbox obconf playerctl picom parcellite
    numlockx rofi polybar lxappearance betterlockscreen
    zsh zsh-syntax-highlighting zsh-autosuggestions
    zsh-history-substring-search zsh-completions
)

# Install the packages if they are not already installed
for package in "${packages[@]}"; do
    if ! pacman -Q "$package" &> /dev/null; then
        sudo pacman -S "$package" --noconfirm
    else
        echo "$package is already installed. Skipping."
    fi
done

# Check if Bluetooth service is available and enable it if not already enabled
if systemctl list-unit-files --type=service | grep -q "bluetooth.service"; then
    if [ "$(systemctl is-enabled bluetooth)" != "enabled" ]; then
        echo "Enabling Bluetooth service."
        sudo systemctl enable --now bluetooth
    else
        echo "Bluetooth service is already enabled. Skipping."
    fi
else
    echo "Bluetooth service is not available. Skipping enablement."
fi

# Check if Preload service is available and enable it if not already enabled
if systemctl list-unit-files --type=service | grep -q "preload.service"; then
    if [ "$(systemctl is-enabled preload)" != "enabled" ]; then
        echo "Enabling Preload service."
        sudo systemctl enable --now preload
    else
        echo "Preload service is already enabled. Skipping."
    fi
else
    echo "Preload service is not available. Skipping enablement."
fi


# Check if zram-generator is configured
if [ ! -f /etc/systemd/zram-generator.conf ] && [ ! -d /etc/systemd/zram-generator.conf.d ]; then
    echo "zram-generator is not configured. Enabling zramswap service."
    sudo systemctl enable --now zramswap
else
    echo "zram-generator is already configured. Skipping zramswap service enablement."
fi

sudo chown -R root:$(id -gn) "$HOME/.config"
chmod -R 770 "$HOME/.config"
# WIFI 
CONFIG="$HOME/.config/polybar/system.ini"

if [ ! -f "$CONFIG" ]; then
    echo "Creating configuration file at $CONFIG"
    mkdir -p "$HOME/.config/polybar"
    echo "[settings]" > "$CONFIG"
    echo "sys_network_interface = wlan0" >> "$CONFIG"
fi

WIFI=$(ip link | awk '/state UP/ {print $2}' | tr -d :)
sed -i "s/sys_network_interface = wlan0/sys_network_interface = $WIFI/" "$CONFIG"
brightness=$(ls -1 /sys/class/backlight/)
sed -i "s/sys_graphics_card = intel_backlight/sys_graphics_card = $brightness/" "$CONFIG"

# Copy cache files to the user's .cache directory, forcing the overwrite
sudo cp -Rf cache/* "$HOME/.cache/"

# Copy the backlight rules file, forcing the overwrite
sudo cp -f udev/rules.d/90-backlight.rules /etc/udev/rules.d/

# Copy the networkmanager_dmenu file, forcing the overwrite
sudo cp -f usr/bin/networkmanager_dmenu /usr/bin/
sudo chmod +x /usr/bin/networkmanager_dmenu

if [ -d "$HOME/.config" ]; then
    sudo cp -R config/* $HOME/.config/ -rf
else
    echo "Creating .config directory at $HOME/.config"
    mkdir -p "$HOME/.config"
    sudo cp -R config/* $HOME/.config/ -rf
fi

sudo chmod +x $HOME/.config/polybar/scripts/*

if [ -d "Fonts" ]; then
    sudo cp -R Fonts/ /usr/share/fonts/
else
    mkdir -p Fonts
    tar -xzvf Fonts.tar.gz -C Fonts
    sudo cp -R Fonts/ /usr/share/fonts/
fi
sudo fc-cache -fv

# Create the zsh directory and extract the contents of zsh.tar.gz
mkdir -p zsh
tar -xzvf zsh.tar.gz -C zsh

# Copy .bashrc and .zshrc to the HOME directory, replacing if they already exist
sudo cp -f zsh/.bashrc $HOME/.bashrc
sudo cp -f zsh/.zshrc $HOME/.zshrc

# Check if the betterlockscreen cache directory exists and has the correct permissions
if [ -d "$HOME/.cache/betterlockscreen" ]; then
    if [ "$(stat -c '%U:%G' "$HOME/.cache/betterlockscreen")" != "root:$(id -gn)" ] || [ "$(stat -c '%a' "$HOME/.cache/betterlockscreen")" != "750" ]; then
        sudo chown root:$(id -gn) "$HOME/.cache/betterlockscreen"
        sudo chmod 750 "$HOME/.cache/betterlockscreen"
        echo "Updated permissions for $HOME/.cache/betterlockscreen"
    else
        echo "Permissions for $HOME/.cache/betterlockscreen are already correct. Skipping."
    fi
else
    echo "$HOME/.cache/betterlockscreen directory does not exist. Skipping permission update."
fi


# Find interface for the wifi or ethernet
CONFIG="$HOME/.config/polybar/config.ini"

ETHERNET=$(ip link | awk '/state UP/ {print $2}' | tr -d :)
WIFI=$(ip link | awk '/state UP/ {print $2}' | tr -d : | grep -i '^wl')

if [ -n "$WIFI" ]; then
    sed -i "s/sys_network_interface = wlan0/sys_network_interface = $WIFI/" "$CONFIG"
elif [ -n "$ETHERNET" ]; then
    sed -i "s/sys_network_interface = wlan0/sys_network_interface = $ETHERNET/" "$CONFIG"
fi



