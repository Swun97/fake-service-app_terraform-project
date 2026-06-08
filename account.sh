#!/bin/bash

sudo apt update -y
sudo apt-get install net-tools zip curl jq tree unzip wget siege apt-transport-https ca-certificates software-properties-common gnupg lsb-release -y
sudo curl -LO https://github.com/nicholasjackson/fake-service/releases/download/v0.26.2/fake_service_linux_amd64.zip
sudo unzip fake_service_linux_amd64.zip
sudo rm -rf fake_service_linux_amd64.zip
sudo mv fake_service_linux_amd64 fake_service
sudo mv fake_service /usr/bin/fake_service
sudo chmod 755 fake_service
sudo chown ubuntu:ubuntu /usr/bin/fake_service


sudo cat > /usr/lib/systemd/system/account.service << 'EOF'

root@ip-10-0-12-130:/usr/lib/systemd/system# cat account.service 
[Unit]
Description=Account Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple

Environment="LISTEN_ADDR=0.0.0.0:9091"
Environment="UPSTREAM_URIS=http://172.16.2.8:9093"
Environment="NAME=account-svc"
Environment="MESSAGE=HelloCloudBank | Retail Banking | account-svc"

ExecStart=/usr/bin/fake-service

User=ubuntu
Group=ubuntu

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target

EOF

sudo systemctl daemon-reload
sleep 1
sudo systemctl enable account.service
sudo systemctl start account.service
sleep 1
sudo systemctl status account.service
sudo lsof -i -P | grep account
