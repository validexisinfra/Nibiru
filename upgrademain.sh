#!/bin/bash
cd $HOME
rm -rf nibiru
git clone https://github.com/NibiruChain/nibiru.git
cd nibiru
git checkout v2.5.0
make install

sudo systemctl restart nibid && sudo journalctl -fu nibid -o cat
