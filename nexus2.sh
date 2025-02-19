#!/bin/bash 
# Periksa apakah skrip dijalankan sebagai pengguna root 
if [ "$(id -u)" != "0" ]; then
    echo "Skrip ini harus dijalankan dengan izin pengguna root."
    echo "Silakan coba gunakan perintah 'Gunakan sudo -i' untuk beralih ke pengguna root, lalu jalankan skrip ini lagi."
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
# 1. Install Rust
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

# 2. Install Nexus CLI
echo "Installing Nexus CLI..."
curl -s https://cli.nexus.xyz/ | sh

# 3. Set path Nexus menggunakan direktori home pengguna
NEXUS_PATH="$HOME/.nexus/network-api/clients/cli"

if [ -d "$NEXUS_PATH" ]; then
  cd "$NEXUS_PATH" || exit
else
  echo "Path $NEXUS_PATH does not exist. Exiting..."
  exit 1
fi

# 4. Run cargo build
echo "Building with Cargo..."
if ! command -v cargo &> /dev/null; then
  echo "Cargo not found! Installing Rust again to get Cargo..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
fi
cargo build --release

# 5. Fix "optional" error in orchestrator.proto
PROTO_FILE="$NEXUS_PATH/proto/orchestrator.proto"
if grep -q "optional" "$PROTO_FILE"; then
  echo "Fixing 'optional' error..."
  sed -i '/optional/d' "$PROTO_FILE"
fi

# Fix "Some" error in orchestrator_client.rs
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

# 6. Run nodes
echo "Starting node..."
cargo run -r -- --start --beta

echo "Setup complete!"
