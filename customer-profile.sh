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


sudo cat > /usr/lib/systemd/system/customer-profile.service << 'EOF'

root@ip-10-0-12-130:/usr/lib/systemd/system# cat customer-profile.service 
[Unit]
Description=Customer Profile Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple

Environment="LISTEN_ADDR=0.0.0.0:9091"
Environment="UPSTREAM_URIS=http://192.168.2.106:9092"
Environment="NAME=customer-profile-svc"
Environment="MESSAGE=HelloCloudBank | Retail Banking | customer-profile-svc"

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
sudo systemctl enable customer-profile.service
sudo systemctl start customer-profile.service
sleep 1
sudo systemctl status customer-profile.service
sudo lsof -i -P | grep customer-profile
