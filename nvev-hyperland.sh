#!/bin/bash

# Hyprland Installation Script
# Author: Abdullah Alomani (nvevesthetic)
# This script automates the installation of Hyprland and essential tools
# on a fresh Fedora system, ensuring a smooth setup experience.

set -e  # Stop on any error

# Check if 'yay' is available before proceeding
yay_installed() {
    if ! command -v yay &>/dev/null; then
        echo "Error: 'yay' is missing. Install it first before running this script."
        exit 1
    fi
}

yay_installed

echo "'yay' detected. Updating packages..."
yay -Suy --noconfirm

# Disable WiFi power-saving mode if the user wants to
disable_wifi_saving() {
    local config_path="/etc/NetworkManager/conf.d/wifi-powersave.conf"
    echo -e "[connection]\nwifi.powersave = 2" | sudo tee "$config_path" > /dev/null
    echo "Restarting NetworkManager to apply changes..."
    sudo systemctl restart NetworkManager
}

read -p "Disable WiFi power-saving mode? (y/n): " disable_wifi
[[ $disable_wifi =~ ^[Yy]$ ]] && disable_wifi_saving

# Install necessary packages
packages=(
    hyprland kitty waybar nitrogen swaylock-effects wofi wlogout mako thunar
    ttf-jetbrains-mono-nerd noto-fonts-emoji polkit-gnome python-requests starship
    swappy grim slurp pamixer brightnessctl gvfs bluez bluez-utils lxappearance
    xfce4-settings dracula-gtk-theme dracula-icons-git xdg-desktop-portal-hyprland
)

read -p "Proceed with package installation? (y/n): " install_packages
if [[ $install_packages =~ ^[Yy]$ ]]; then
    yay -S --noconfirm "${packages[@]}"
    echo "Enabling Bluetooth services..."
    sudo systemctl enable --now bluetooth.service

    echo "Removing unnecessary xdg portals..."
    yay -R --noconfirm xdg-desktop-portal-gnome xdg-desktop-portal-gtk
fi

# Move configuration files to the correct locations
apply_configs() {
    for config in hypr kitty mako waybar swaylock wofi; do
        cp -R "$config" ~/.config/
    done
    chmod +x ~/.config/hypr/xdg-portal-hyprland
    chmod +x ~/.config/waybar/scripts/waybar-wttr.py
}

read -p "Copy configuration files? (y/n): " copy_config_files
[[ $copy_config_files =~ ^[Yy]$ ]] && apply_configs

# Set up the Starship shell
setup_starship() {
    echo 'eval "$(starship init bash)"' >> ~/.bashrc
    cp starship.toml ~/.config/
}

read -p "Enable Starship shell customization? (y/n): " enable_starship
[[ $enable_starship =~ ^[Yy]$ ]] && setup_starship

# Install support for Asus ROG systems
install_rog_support() {
    sudo pacman-key --recv-keys 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35
    sudo pacman-key --lsign-key 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35
    echo -e "\n[g14]\nServer = https://arch.asus-linux.org" | sudo tee -a /etc/pacman.conf > /dev/null
    sudo pacman -Suy --noconfirm
    sudo pacman -S --noconfirm asusctl supergfxctl rog-control-center
    sudo systemctl enable --now power-profiles-daemon.service
    sudo systemctl enable --now supergfxd
}

read -p "Install Asus ROG support? (y/n): " install_rog
[[ $install_rog =~ ^[Yy]$ ]] && install_rog_support

echo "Installation completed! You can start Hyprland by typing 'Hyprland'."
read -p "Launch Hyprland now? (y/n): " start_hyprland
[[ $start_hyprland =~ ^[Yy]$ ]] && exec Hyprland
