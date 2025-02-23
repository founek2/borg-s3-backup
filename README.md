# Borg S3 storage backup

This is a script to backup your folders using borg into a local borg repository which is synced into an AWS S3  bucket.

Commands:
```bash
git clone https://github.com/founek2/borg-s3-backup.git backup

# Initialize repository
borg init --encryption=repokey-blake2 repository

# run backup
./run_backup.sh

# recovery 
./run_download.sh /home/martas/backup/repository/

borg list repository::work-2023-06-04T00.31 var

# this will extract deploy folder `var` in your cwd
borg extract repository::work-2023-06-04T00.31 var

# now just copy extracted files into target location
mv var/data /var/data
mv var/deploy /var/deploy
rm -rf var
```

## Features
- support for Mac notifications via [terminal-notifier](https://github.com/julienXX/terminal-notifier)
- support for Linux notifications via notify-send

## Setup new docker node
```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Post install
sudo usermod -aG docker $USER

sudo apt install -y git borgbackup unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws*

git clone https://github.com/founek2/borg-s3-backup.git backup

cd backup
mkdir repository
cp run_download.sh.example run_download.sh
vim run_download.sh.example
```

### Add cron jobs
```cron
0 3 * * 0 /root/backup/run_backup.sh > /var/log/backup.log 2>&1
0 6 * * * /usr/bin/docker volume prune -f
```

### Setup docker tls
```bash
mkdir ca
chmod 700 ca

# Create the Certificate Authority private key and certificate 
openssl genrsa -out ca/ca-key.pem 4096
openssl req -x509 -new -nodes -key ca/ca-key.pem -days 3650 -out ca/ca.pem -subj '/CN=docker-CA'

echo "[added]

[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth" >> ca/openssl.cnf

# Create the Client TLS certificate 
openssl genrsa -out ca/client-key.pem 4096
openssl req -new -key ca/client-key.pem -out ca/client-cert.csr -subj '/CN=docker-client' -config ca/openssl.cnf
openssl x509 -req -in ca/client-cert.csr -CA ca/ca.pem -CAkey ca/ca-key.pem -CAcreateserial -out ca/client-cert.pem -days 3650 -extensions v3_req -extfile ca/openssl.cnf

# Create daemon TLS certificate
mkdir ssl
echo "[added]

[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = yourtestweb | yourprodweb
DNS.2 = yourtestrserve | yourprodrserve
IP.1 = 127.0.0.1
IP.2 = 192.168.10.X" > ssl/openssl.cnf 

openssl genrsa -out ssl/daemon-key.pem 4096
openssl req -new -key ssl/daemon-key.pem -out ssl/daemon-cert.csr -subj '/CN=docker-daemon' -config ssl/openssl.cnf
openssl x509 -req -in ssl/daemon-cert.csr -CA ca/ca.pem -CAkey ca/ca-key.pem -CAcreateserial -out ssl/daemon-cert.pem -days 3650 -extensions v3_req -extfile ssl/openssl.cnf

chmod 600 ssl/*

#Docker daemon ----------------------------------------------------------------------

echo '{   "tls": true,
    "tlsverify": true,
    "tlscacert": "/etc/docker/ca/ca.pem",
    "tlscert": "/etc/docker/ssl/daemon-cert.pem",
    "tlskey": "/etc/docker/ssl/daemon-key.pem",
    "hosts": ["unix:///var/run/docker.sock", "tcp://192.168.10.X:2376"]
}' > /etc/docker/daemon.json


sudo systemctl edit docker
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
```

## Setup borg jail
```bash
pkg install vim git bash py311-borgbackup py311-awscli
```