!/bin/bash

GO_VERSION=go1.12.5
COSMOS_VERSION=v0.35.0

echo "update"
sudo apt-get update
sudo apt-get upgrade -y
echo "Checking required packages are installed"
sudo apt-get install -y wget git make gcc curl

echo "Installing go"
wget https://dl.google.com/go/$GO_VERSION.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf $GO_VERSION.linux-amd64.tar.gz
rm $GO_VERSION.linux-amd64.tar.gz

echo "Setting up environment variables for GO"

mkdir -p $HOME/go/bin
echo "export GOPATH=$HOME/go" >> ~/.bashrc
echo "export GOBIN=\$GOPATH/bin" >> ~/.bashrc
echo "export PATH=\$PATH:\$GOBIN:/usr/local/go/bin" >> ~/.bashrc
source ~/.bashrc
export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN:/usr/local/go/bin

echo "Installing cosmos-sdk"

mkdir -p $GOPATH/cosmos
cd $GOPATH/cosmos
git clone https://github.com/cosmos/cosmos-sdk
cd cosmos-sdk && git checkout $COSMOS_VERSION
make tools install

#check the version 
gaiad version --long
gaiacli version --long

#init a node
echo "Setting up gaia service"
gaiad init ivy

# connect a testnet
### copy the Genesis File
echo "Need genesis.json to connect to testnet"
rm $HOME/.gaiad/config/genesis.json
curl https://raw.githubusercontent.com/cosmos/launch/master/genesis.json > $HOME/.gaiad/config/genesis.json

### modify persistent_peer
echo "Need to add persistent_peer in $HOME/.gaiad/config/config.toml before start"



