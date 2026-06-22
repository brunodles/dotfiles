#!/usr/bin/env bash

# install
sudo apt install -y ufw

# setup UFW
sudo ufw allow OpenSSH
sudo ufw allow 80
sudo ufw allow 443

# enable UFW
sudo ufw enable
sudo ufw status
