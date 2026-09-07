#!/usr/bin/env bash
set -euo pipefail

echo "========================================="
echo "   Chimera Linux Custom Ricing Installer  "
echo "========================================="

# 1. Install all necessary system libraries & compilers via apk
echo -e "\n[1/5] Installing system dependencies via apk..."
doas apk add \
    cargo rust go make \
    python python-pip python-devel \
    gtk+3 gtk+3-devel gtk-layer-shell gobject-introspection gobject-introspection-devel \
    meson pkgconf xcur2png git

# 2. Build & Install Matugen via Cargo
echo -e "\n[2/5] Installing Matugen..."
cargo install matugen

# Ensure local cargo bin directory exists and add it to PATH dynamically for the script
mkdir -p "$HOME/.cargo/bin"
export PATH="$HOME/.cargo/bin:$PATH"

# Persist Cargo PATH if not already present
if ! grep -q '\.cargo/bin' "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.bashrc"
    echo "-> Added Cargo path to ~/.bashrc"
fi

# 3. Setup Python Venv & Install Fabric Shell
echo -e "\n[3/5] Setting up Fabric Shell in an isolated Python environment..."
FABRIC_DIR="$HOME/.config/fabric"
mkdir -p "$FABRIC_DIR"

# Create a clean virtual environment
python -m venv "$FABRIC_DIR/venv"

# Use the absolute path of the venv pip to prevent shell-activation headaches
"$FABRIC_DIR/venv/bin/pip" install --upgrade pip
"$FABRIC_DIR/venv/bin/pip" install git+https://github.com/Fabric-Development/fabric.git
"$FABRIC_DIR/venv/bin/pip" install psutil

# 4. Build and Install nwg-look from source
echo -e "\n[4/5] Compiling and installing nwg-look..."
BUILD_DIR=$(mktemp -d)
cd "$BUILD_DIR"

git clone --depth=1 https://github.com/nwg-piotr/nwg-look.git .
make build
doas make install

# Clean up temp build folder
cd "$HOME"
rm -rf "$BUILD_DIR"

# 5. Summary and Testing
echo -e "\n[5/5] Verifying installations..."
echo "-----------------------------------------"

if command -v matugen &> /dev/null; then
    echo "✓ Matugen: Installed ($(matugen --version))"
else
    echo "✗ Matugen compilation failed."
fi

if "$FABRIC_DIR/venv/bin/python" -c "import fabric" &> /dev/null; then
    echo "✓ Fabric Shell: Installed inside $FABRIC_DIR/venv"
else
    echo "✗ Fabric installation failed."
fi

if command -v nwg-look &> /dev/null; then
    echo "✓ nwg-look: Installed successfully"
else
    echo "✗ nwg-look build failed."
fi

echo "-----------------------------------------"
echo "All done! Run 'source ~/.bashrc' to sync your current terminal session."
echo "To run your Fabric shell configuration, execute it via its venv python:"
echo "   $FABRIC_DIR/venv/bin/python your_script.py"
