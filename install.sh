#!/bin/bash
########################
# Author: Rocklin K S
# Date: 13/08/2024
# This script makes my config to autinstall
# Version: v3
############################

set -exo  pipefail
mkdir -p "$HOME/.config"
cp -rf config/networkmanager-dmenu config/openbox config/xfce4 "$HOME/.config/"

copy_normal_polybar() {
    cp -rf config/polybar "$HOME/.config/"
    echo "Normal Polybar configuration copied to ~/.config"
}

copy_transparent_polybar() {
    mv -f config/polybar-transparent "$HOME/.config/polybar"
    echo "Transparent Polybar configuration copied to ~/.config/polybar"
}

echo "Select Polybar version:"
echo "1. Normal"
echo "2. Transparent"
read -p "Enter your choice (1 or 2): " choice

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
    sed -i "s/sys_network_interface = wlan0/sys_network_interface = $WIFI/" "$SYSTEM_CONFIG"
    
elif [ -n "$ETHERNET" ]; then
    echo "Using Ethernet interface: $ETHERNET"
    sed -i "s/sys_network_interface = wlan0/sys_network_interface = $ETHERNET/" "$SYSTEM_CONFIG"
    sed -i "s/network/ethernet/g" "$POLYBAR_CONFIG"

else
    echo "No active network interfaces found."
fi

TARGET_DIR="$HOME/.config/gtk-3.0"
SETTINGS_FILE="settings.ini" 

if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
    echo "Created directory: $TARGET_DIR"
fi

if [ -f "$SETTINGS_FILE" ]; then
    mv "$SETTINGS_FILE" "$TARGET_DIR/"
    echo "Moved settings.ini to $TARGET_DIR"
else
    echo "settings.ini not found at $SETTINGS_FILE"
fi

mkdir -p $HOME/.icons
mkdir -p $HOME/.icons/default
mv icons/default/index.theme $HOME/.config/default/

mv zsh/bashrc $HOME/.bashrc
mv zsh/zshrc $HOME/.zshrc
sudo -v

###### Check if yay is installed ###############
if ! command -v yay &> /dev/null; then
    sudo pacman -S yay --noconfirm
fi

if ! grep -q "chaotic-aur" /etc/pacman.conf; then
   sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
   sudo pacman-key --lsign-key 3056513887B78AEB
   sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm
   sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
fi

PACMAN="/etc/pacman.conf"
CHAOTIC="[chaotic-aur]"
INCLUDE_LINE="Include = /etc/pacman.d/chaotic-mirrorlist"

if ! grep -q "$CHAOTIC" "$PACMAN"; then
    echo -e "\n$CHAOTIC\n$INCLUDE_LINE" | sudo tee -a "$PACMAN" > /dev/null
else
    sudo echo "$CHAOTIC already exists in $PACMAN."
fi

sudo pacman -Syu --noconfirm
packages=(
    zramswap preload python-dbus xarchiver xed thunar thunar-volman thunar-archive-plugin
    udiskie udisks2 tumbler gvfs xfce4-panel polkit-gnome xfdesktop blueman python-dbus
    firefox wine winetricks wine-mono wine-gecko seahorse xfce4-settings xfce4-power-manager
    xfce4-docklike-plugin obs-studio virtualbox-guest-utils unzip bc openbox obconf playerctl
    xcompmgr parcellite gst-plugins-bad ttf-wps-fonts localsend numlockx rofi polybar
    lxappearance gst-plugins-base tlp tlp-rdw tlpui visual-studio-code-bin zsh
    zsh-syntax-highlighting zsh-autosuggestions gst-plugins-ugly qbittorrent git wget curl
    zsh-history-substring-search zsh-completions gst-plugins-good wps-office virtualbox
    xfce4-screenshooter
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

stacer=http://archlinuxgr.tiven.org/archlinux/x86_64/stacer-1.1.0-1-x86_64.pkg.tar.zst
wget $stacer
sudo pacman -U stacer-1.1.0-1-x86_64.pkg.tar.zst --noconfirm
sudo rm -rf stacer-1.1.0-1-x86_64.pkg.tar.zst

xdm=https://github.com/subhra74/xdm/releases/download/8.0.29/xdman_gtk-8.0.29-1-x86_64.pkg.tar.zst
wget $xdm
sudo pacman -U xdman_gtk-8.0.29-1-x86_64.pkg.tar.zst --noconfirm
sudo rm -rf xdman_gtk-8.0.29-1-x86_64.pkg.tar.zst
###### Themes ####
sudo mkdir -p themes/theme
sudo tar -xvzf themes/CachyOS.tar.gz -C themes/theme
sudo cp -rf themes/theme/* /usr/share/themes/
sudo rm -rf themes/theme

sudo unzip themes/Tokyonight-Dark-B-MB.zip -d themes/Tokyonight
sudo cp -rf themes/Tokyonight/* /usr/share/themes/
sudo rm -rf themes/Tokyonight

### Icons
kora="/usr/share/icons/kora"
if [ ! -d "$kora" ]; then
    sudo mkdir -p icons/kora
    sudo tar -xf icons/kora-1-6-6.tar.xz -C icons/kora
    sudo mv icons/kora/* /usr/share/icons/ 
    sudo rm icons/kora -rf
else
    echo "Directory $kora already exists."
fi

TARGET_DIR="/usr/share/icons/Qogir"

if [ ! -d "$TARGET_DIR" ]; then
    sudo mkdir -p icons/qogir
    sudo tar -xf icons/01-Qogir.tar.xz -C icons/qogir
    sudo mv icons/qogir/* /usr/share/icons/
    sudo rm -rf icons/qogir
else
    echo "Directory $TARGET_DIR already exists."
fi

oxygen="/usr/share/icons/Oxygen"

if [ ! -d "$oxygen" ]; then
    sudo mkdir -p icons/Oxygen
    sudo tar -xvzf icons/oxygen.tar.gz -C icons/Oxygen
    sudo mv icons/Oxygen /usr/share/icons/
else
    echo "Directory $oxygen already exists."
fi

## Pwfeedback
pwfeedback="/etc/sudoers.d/pwfeedback"

if [ -f "$pwfeedback" ]; then
    echo "File $pwfeedback already exists. Exiting."
    exit 1
fi

echo "Defaults pwfeedback" | sudo tee "$pwfeedback" > /dev/null
sudo chmod 440 "$pwfeedback"
echo "Password feedback enabled successfully."

##### Change shell
current_shell=$(echo $SHELL)
desired_shell="/bin/bash"

if [ "$current_shell" != "$desired_shell" ]; then
    chsh -s /bin/bash
    echo "Shell changed successfully."
else
    echo "Your current shell is already set to Bash."
fi

echo "All operations completed successfully."
