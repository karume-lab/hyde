#!/bin/bash
# Post-installation Configuration & Package Installation Script
# Run after: arch-chroot setup is complete, GRUB is installed, and Hyde is set up
# This script copies configuration files and installs packages from the backup

set -euo pipefail

REPO_PATH="${1:-.}"  # Use provided path or current directory
CONFIG_SOURCE="$REPO_PATH/configs"
DOTFILES_SOURCE="$REPO_PATH/dotfiles"
PACKAGES_FILE="$REPO_PATH/packages/pacman-packages.txt"
AUR_PACKAGES_FILE="$REPO_PATH/packages/aur-packages.txt"

echo "=== Post-Installation Configuration Setup ==="
echo "Using repository from: $REPO_PATH"
echo ""

# Check if Hyde needs to be run first
if ! command -v hyde-cli &> /dev/null && [ -z "${SKIP_HYDE_CHECK:-}" ]; then
  echo "⚠️  Hyde CLI not found. Please run Hyde first:"
  echo "   git clone https://github.com/hyde-project/hyde.git ~/.config/hyde"
  echo "   cd ~/.config/hyde && bash install.sh"
  echo ""
  read -p "Press Enter once Hyde is installed, or set SKIP_HYDE_CHECK=1 to continue anyway..."
fi

# Verify paths exist
if [ ! -d "$CONFIG_SOURCE" ]; then
  echo "❌ Error: Config source path not found: $CONFIG_SOURCE"
  exit 1
fi

# Function to copy config directory
copy_config() {
  local config_name=$1
  local target_path="${2:-$HOME/.config/$config_name}"
  local source_path="$CONFIG_SOURCE/$config_name"
  
  if [ -d "$source_path" ]; then
    echo "📋 Copying $config_name..."
    mkdir -p "$(dirname "$target_path")"
    cp -r "$source_path" "$target_path"
    echo "   ✓ $config_name"
  fi
}

# Function to copy dotfile
copy_dotfile() {
  local dotfile_name=$1
  local target_path="${2:-$HOME/$dotfile_name}"
  local source_path="$DOTFILES_SOURCE/$dotfile_name"
  
  if [ -f "$source_path" ]; then
    echo "📋 Copying $dotfile_name..."
    # Backup existing file if it exists
    if [ -f "$target_path" ]; then
      mv "$target_path" "$target_path.bak.$(date +%s)"
      echo "   (Backed up existing $dotfile_name)"
    fi
    cp "$source_path" "$target_path"
    echo "   ✓ $dotfile_name"
  fi
}

echo "🔄 Copying configuration files..."
echo ""

# Copy application configs
copy_config "hypr"
copy_config "waybar"
copy_config "kitty"
copy_config "zsh"
copy_config "rofi"
copy_config "dunst"
copy_config "starship"
copy_config "vim"
copy_config "swaylock"
copy_config "gtk-3.0"
copy_config "qt5ct"
copy_config "qt6ct"
copy_config "swappy"

# Copy config files
if [ -d "$CONFIG_SOURCE" ]; then
  for config_file in "$CONFIG_SOURCE"/*.list "$CONFIG_SOURCE"/*rc; do
    if [ -f "$config_file" ]; then
      basename_file=$(basename "$config_file")
      echo "📋 Copying $basename_file..."
      cp "$config_file" "$HOME/.config/$basename_file"
      echo "   ✓ $basename_file"
    fi
  done
fi

echo ""
echo "🔄 Copying dotfiles to home directory..."
echo ""

# Copy dotfiles
copy_dotfile ".zshrc"
copy_dotfile ".bashrc"
copy_dotfile ".gitconfig"

echo ""
echo "🔄 Installing packages from backup..."
echo ""

# Function to install packages
install_packages() {
  local packages_file=$1
  local package_manager=$2
  
  if [ ! -f "$packages_file" ]; then
    echo "⚠️  Package file not found: $packages_file"
    return 1
  fi
  
  # Count packages
  package_count=$(wc -l < "$packages_file")
  echo "📦 Found $package_count packages to install from $packages_file"
  
  read -p "Install packages from $packages_file? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ "$package_manager" = "pacman" ]; then
      # Install from file, skipping base-devel and meta-packages that may already be installed
      pacman -S --noconfirm $(grep -v "^$" "$packages_file" | tr '\n' ' ') || true
    elif [ "$package_manager" = "yay" ]; then
      # Use yay for AUR packages
      if command -v yay &> /dev/null; then
        yay -S --noconfirm $(grep -v "^$" "$packages_file" | tr '\n' ' ') || true
      else
        echo "⚠️  yay not found, skipping AUR packages"
      fi
    fi
  else
    echo "⏭️  Skipped package installation"
  fi
}

# Install pacman packages
install_packages "$PACKAGES_FILE" "pacman"

echo ""
echo "🔄 Installing AUR packages..."
install_packages "$AUR_PACKAGES_FILE" "yay"

echo ""
echo "✅ Post-installation setup complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Review copied configs in ~/.config/"
echo "   2. Restart your shell or run: source ~/.zshrc"
echo "   3. Customize any settings as needed"
echo ""
echo "💡 Backups of overwritten files are saved with .bak.TIMESTAMP extension"
