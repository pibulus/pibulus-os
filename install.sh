#!/bin/bash
# 🦾 PIBULUS OS - BOOTSTRAP INSTALLER
# Run this on a fresh Pi to join the mainframe.

echo "🚀 Starting Cyberdeck Bootstrap..."

# 1. Install the "Toys"
sudo apt-get update
sudo apt-get install -y gum lolcat figlet git curl

# 2. Install the "Engine" (Docker)
if ! command -v docker &> /dev/null; then
    echo "🐳 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
else
    echo "✅ Docker already present."
fi

# 3. Setup the Alias
BASHRC="$HOME/.bashrc"
if ! grep -q "alias deck=" "$BASHRC"; then
    echo "🔗 Setting up 'deck' alias..."
    echo "alias deck='~/pibulus-os/launcher.sh'" >> "$BASHRC"
fi

# 4. Create initial .env if missing
if [ ! -f "~/pibulus-os/.env" ]; then
    echo "📝 Creating default .env..."
    cp ~/pibulus-os/pibulus.env ~/pibulus-os/.env
fi

echo "✨ Bootstrap complete. Restart your terminal and type 'deck' to fly." | lolcat
