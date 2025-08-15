#!/bin/bash
#
# Author: Rocklin K S
# Date: 13/08/2024
# Version: v4-refined
# Purpose: Automated config installation for Arch Linux
#

set -euo pipefail

# ---- Helper Functions ----
log() { echo -e "\e[92m[+] $1\e[0m"; }
warn() { echo -e "\e[93m[!] $1\e[0m"; }
error() { echo -e "\e[91m[-] $1\e[0m" >&2; }

# ---- 1. Copy Base Configurations ----
log "Copying base configuration files..."
mkdir -p "$HOME/.config"
cp -rf config/{networkmanager-dmenu,openbox,xfce4} "$HOME/.config/"

copy_normal_polybar() {
    cp -rf config/polybar "$HOME/.config/"
    log "Normal Polybar configuration installed."
}

copy_transparent_polybar() {
    rm -rf "$HOME/.config/polybar"
    cp -rf config/polybar-transparent "$HOME/.config/polybar"
    log "Transparent Polybar configuration installed."
}

echo "Select Polybar version:"
echo "1. Normal"
echo "2. Transparent"
read -rp "Enter choice (1/2): " choice
case "$choice" in
    1) copy_normal_polybar ;;
    2) copy_transparent_polybar ;;
    *) warn "Invalid choice — defaulting to normal."; copy_normal_polybar ;;
esac

chmod +x "$HOME/.config/polybar/scripts/"* || warn "No polybar scripts found to chmod."

SYSTEM_CONFIG="$HOME/.config/polybar/system.ini"
POLYBAR_CONFIG="$HOME/.config/polybar/config.ini"

# ---- 2. Network Interface Detection ----
log "Detecting active network interface..."
ETHERNET=$(ip -o link | awk -F': ' '!/wl/ && /state UP/ {print $2; exit}')
WIFI=$(ip -o link | awk -F': ' '/wl/ && /state UP/ {print $2; exit}')

if [ -n "$WIFI" ]; then
    log "Wi-Fi interface found: $WIFI"
    sed -i "s|sys_network_interface = .*|sys_network_interface = $WIFI|" "$SYSTEM_CONFIG"
elif [ -n "$ETHERNET" ]; then
    log "Ethernet interface found: $ETHERNET"
    sed -i "s|sys_network_interface = .*|sys_network_interface = $ETHERNET|" "$SYSTEM_CONFIG"
    sed -i 's/network/ethernet/g' "$POLYBAR_CONFIG"
else
    warn "No active network interfaces found — Polybar network module may not work."
fi

# ---- 3. Shell Configs ----
[ -f zsh/bashrc ] && mv zsh/bashrc "$HOME/.bashrc"
[ -f zsh/zshrc ] && mv zsh/zshrc "$HOME/.zshrc"

# ---- 4. Install Yay ----
log "Checking for yay..."
if ! command -v yay &>/dev/null; then
    log "Installing yay from AUR..."
    sudo pacman -Sy --needed git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm
    cd - >/dev/null
else
    log "yay is already installed."
fi

# ---- 5. Add Chaotic AUR ----
if ! grep -q "chaotic-aur" /etc/pacman.conf; then
    log "Adding Chaotic AUR..."
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm
    sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
    echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf >/dev/null
else
    log "Chaotic AUR already set up."
fi

# ---- 6. Package Installation ----
log "Installing packages..."
packages=(
    zramswap preload python-dbus xarchiver xed thunar thunar-volman thunar-archive-plugin
    udiskie udisks2 tumbler gvfs xfce4-panel polkit-gnome xfdesktop blueman
    firefox wine winetricks wine-mono wine-gecko seahorse xfce4-settings xfce4-power-manager
    obs-studio virtualbox-guest-utils unzip bc openbox obconf playerctl
    xcompmgr parcellite gst-plugins-bad ttf-wps-fonts localsend numlockx rofi polybar
    lxappearance gst-plugins-base tlp tlp-rdw tlpui visual-studio-code-bin zsh
    zsh-syntax-highlighting zsh-autosuggestions gst-plugins-ugly qbittorrent git wget curl
    zsh-history-substring-search zsh-completions gst-plugins-good wps-office virtualbox
    xfce4-screenshooter xdg-desktop-portal-gtk
)
for pkg in "${packages[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        sudo pacman -S "$pkg" --noconfirm
    else
        echo "✔ $pkg already installed."
    fi
done

# ---- 7. Enable Services ----
log "Enabling services..."
for svc in bluetooth tlp preload zramswap; do
    sudo systemctl enable "$svc"
done

# ---- 8. Fonts ----
log "Installing custom fonts..."
sudo mkdir -p Fonts
sudo tar -xzf Fonts.tar.gz -C Fonts
sudo cp -rf Fonts/* /usr/share/fonts/
sudo fc-cache -fv
rm -rf Fonts

# ---- 9. Themes ----
log "Installing themes..."
sudo tar -xvzf themes/CachyOS.tar.gz -C /usr/share/themes/
sudo unzip -q themes/Tokyonight-Dark-B-MB.zip -d /usr/share/themes/Tokyonight

# ---- 10. Icons ----
log "Installing icons..."
install_icon_set() {
    local dir=$1
    local archive=$2
    if [ ! -d "/usr/share/icons/$dir" ]; then
        tar_opts="-xf"
        [[ $archive == *.tar.gz ]] && tar_opts="-xvzf"
        [[ $archive == *.tar.xz ]] && tar_opts="-xf"
        [[ $archive == *.zip ]] && { unzip -q "icons/$archive" -d "icons/$dir" && sudo mv icons/$dir/* /usr/share/icons/ && rm -rf icons/$dir; return; }
        sudo mkdir -p icons/$dir
        sudo tar $tar_opts "icons/$archive" -C icons/$dir
        sudo mv icons/$dir/* /usr/share/icons/
        sudo rm -rf icons/$dir
    else
        log "Icon set $dir already exists."
    fi
}
install_icon_set kora kora-1-6-6.tar.xz
install_icon_set Qogir 01-Qogir.tar.xz
install_icon_set Oxygen oxygen.tar.gz

# ---- 11. pwfeedback ----
pwfile="/etc/sudoers.d/pwfeedback"
if [ ! -f "$pwfile" ]; then
    echo "Defaults pwfeedback" | sudo tee "$pwfile" >/dev/null
    sudo chmod 440 "$pwfile"
    log "Password feedback enabled."
else
    log "pwfeedback already enabled."
fi

# ---- 12. Change Shell to Bash ----
if [ "$SHELL" != "/bin/bash" ]; then
    chsh -s /bin/bash
    log "Shell changed to Bash."
else
    log "Already using Bash shell."
fi

log "✅ All operations completed successfully!"
