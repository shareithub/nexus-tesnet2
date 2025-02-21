#!/bin/bash 
# Periksa apakah skrip dijalankan sebagai pengguna root 
if [ "$(id -u)" != "0" ]; then
    echo "Skrip ini harus dijalankan dengan izin pengguna root."
    echo "Silakan coba gunakan perintah 'sudo -i' untuk beralih ke pengguna root, lalu jalankan skrip ini lagi."
    exit 1
fi

echo "=======================Titan Node=======================" 

echo "███████╗██╗  ██╗ █████╗ ██████╗ ███████╗    ██╗████████╗    ██╗  ██╗██╗   ██╗██████╗ "
echo "██╔════╝██║  ██║██╔══██╗██╔══██╗██╔════╝    ██║╚══██╔══╝    ██║  ██║██║   ██║██╔══██╗"
echo "███████╗███████║███████║██████╔╝█████╗      ██║   ██║       ███████║██║   ██║██████╔╝"
echo "╚════██║██╔══██║██╔══██║██╔══██╗██╔══╝      ██║   ██║       ██╔══██║██║   ██║██╔══██╗"
echo "███████║██║  ██║██║  ██║██║  ██║███████╗    ██║   ██║       ██║  ██║╚██████╔╝██████╔╝"
echo "╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝    ╚═╝   ╚═╝       ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ "
echo ""
echo "𝘋𝘰𝘯'𝘵 𝘧𝘰𝘳𝘨𝘦𝘵 𝘵𝘰 𝘫𝘰𝘪𝘯 𝘰𝘶𝘳 𝘰𝘧𝘧𝘪𝘤𝘪𝘢𝘭 𝘤𝘩𝘢𝘯𝘯𝘦𝘭:"
echo "Telegram: https://t.me/SHAREITHUB_COM"
echo "Youtube: https://www.youtube.com/@SHAREITHUB_COM"
echo "Repo Github: https://github.com/shareithub/"

sleep 5

# 1. Install Build Essential
echo "Installing Build Essential..."
sudo apt install build-essential pkg-config libssl-dev git-all -y

# 2. Install Protobuf Compiler
echo "Installing Protobuf Compiler..."
sudo apt install -y protobuf-compiler

# 3. Install Unzip
echo "Installing Unzip..."
sudo apt install -y unzip

# 4. Install Protoc v21.3
echo "Downloading and installing Protoc v21.3..."
wget https://github.com/protocolbuffers/protobuf/releases/download/v21.3/protoc-21.3-linux-x86_64.zip
unzip protoc-21.3-linux-x86_64.zip -d /usr/local

# 5. Add Overswap 16GB
echo "Configuring 16GB Swap..."
sudo swapoff -a  
sudo fallocate -l 16G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 6. Add Overcommit Memory
echo "Setting Overcommit Memory..."
sudo sysctl -w vm.overcommit_memory=1
echo 'vm.overcommit_memory=1' | sudo tee -a /etc/sysctl.conf

# 7. Install Rust
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

# 8. Add the riscv32i target
echo "Adding riscv32i target for Rust..."
rustup target add riscv32i-unknown-none-elf

# 9. Install Nexus CLI
echo "Installing Nexus CLI..."
curl -s https://cli.nexus.xyz/ | sh

# 10. Set path Nexus menggunakan direktori home pengguna
NEXUS_PATH="$HOME/.nexus/network-api/clients/cli"

if [ -d "$NEXUS_PATH" ]; then
  cd "$NEXUS_PATH" || exit
else
  echo "Path $NEXUS_PATH does not exist. Exiting..."
  exit 1
fi

# 11. Run cargo build
echo "Building with Cargo..."
if ! command -v cargo &> /dev/null; then
  echo "Cargo not found! Installing Rust again to get Cargo..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
fi
cargo build --release

# 12. Fix "optional" error in orchestrator.proto
PROTO_FILE="$NEXUS_PATH/proto/orchestrator.proto"
if grep -q "optional" "$PROTO_FILE"; then
  echo "Fixing 'optional' error..."
  sed -i '/optional/d' "$PROTO_FILE"
fi

# 13. Fix "Some" error in orchestrator_client.rs
CLIENT_FILE="$NEXUS_PATH/src/orchestrator_client.rs"
if grep -q "Some" "$CLIENT_FILE"; then
  echo "Fixing 'Some' error..."
  sed -i '/node_telemetry:/,/}/c\
    node_telemetry: Some(crate::nexus_orchestrator::NodeTelemetry {\n\
        flops_per_sec: 1,\n\
        memory_used: 1,\n\
        memory_capacity: 1,\n\
        location: "US".to_string(),\n\
    }),' "$CLIENT_FILE"
fi

# 14. Run nodes
echo "Starting node..."
cargo run -r -- --start --beta

echo "Setup complete!"
