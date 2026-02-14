#!/bin/bash

set -e

GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m"

print() {
  echo -e "${GREEN}$1${NC}"
}

print_error() {
  echo -e "${RED}$1${NC}"
}

read -p "Enter your node MONIKER: " MONIKER
read -p "Enter your custom port prefix (e.g. 16): " CUSTOM_PORT

print "Installing Nibiru Node with moniker: $MONIKER"
print "Using custom port prefix: $CUSTOM_PORT"

print "Updating system and installing dependencies..."
sudo apt update
sudo apt install -y curl git build-essential lz4 wget

sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.24.6.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)
echo "export PATH=$PATH:/usr/local/go/bin:/usr/local/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile

cd $HOME && mkdir -p go/bin/
git clone https://github.com/NibiruChain/nibiru/
cd $HOME/nibiru/
git fetch --all
git checkout v2.11.0
make install

nibid config chain-id cataclysm-1
nibid config keyring-backend file
nibid config node tcp://localhost:${CUSTOM_PORT}657
nibid init $MONIKER --chain-id cataclysm-1 --home $HOME/.nibid

curl -Ls https://ss.nibiru.nodestake.org/genesis.json > $HOME/.nibid/config/genesis.json 
curl -Ls https://ss.nibiru.nodestake.org/addrbook.json > $HOME/.nibid/config/addrbook.json

seed="9a9e6eab3a83b670f7f20c3f56cd0e5f7f81f46c@rpc.nibiru.nodestake.org:666"
sed -i.bak -e "s/^seed *=.*/seed = \"$seed\"/" $HOME/.nibid/config/config.toml
peers=$(curl -s https://ss.nibiru.nodestake.org/peers.txt)
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.nibid/config/config.toml

sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.025unibi\"/;" $HOME/.nibid/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.nibid/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.nibid/config/config.toml

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
  $HOME/.nibid/config/app.toml
  
sed -i.bak -e "s%:26658%:${CUSTOM_PORT}658%g;
s%:26657%:${CUSTOM_PORT}657%g;
s%:26656%:${CUSTOM_PORT}656%g;
s%:6060%:${CUSTOM_PORT}060%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${CUSTOM_PORT}56\"%;
s%:26660%:${CUSTOM_PORT}660%g" $HOME/.nibid/config/config.toml

sed -i.bak -e "s%:1317%:${CUSTOM_PORT}317%g;
s%:8080%:${CUSTOM_PORT}080%g;
s%:9090%:${CUSTOM_PORT}090%g;
s%:9091%:${CUSTOM_PORT}091%g;
s%:8545%:${CUSTOM_PORT}545%g;
s%:8546%:${CUSTOM_PORT}546%g" $HOME/.nibid/config/app.toml

sudo tee /etc/systemd/system/nibid.service > /dev/null <<EOF
[Unit]
Description=nibid Daemon
After=network-online.target
​
[Service]
User=$USER
ExecStart=$(which nibid) start
Restart=always
RestartSec=3
LimitNOFILE=65535
​
[Install]
WantedBy=multi-user.target
EOF

print "Downloading snapshot..."
curl -L https://snapshots3.stakevillage.net/cataclysm-1/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.nibid/data

sudo systemctl daemon-reload
sudo systemctl enable nibid
sudo systemctl restart nibid

print "✅ Setup complete. Use 'journalctl -u nibid -f -o cat' to view logs"
