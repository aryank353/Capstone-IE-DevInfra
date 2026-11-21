sudo groupadd devops
sudo useradd -m -G devops devuser
sudo useradd -m opsuser

sudo mkdir -p /opt/secure-app
echo "CONFIDENTIAL_DB_PASSWORD=Capstone2026" | sudo tee /opt/secure-app/secret.txt

sudo chown -R root:devops /opt/secure-app
sudo chmod 750 /opt/secure-app
sudo chmod 640 /opt/secure-app/secret.txt

id devuser && id opsuser
sudo ls -ld /opt/secure-app && sudo ls -l /opt/secure-app/secret.txt

sudo -u devuser cat /opt/secure-app/secret.txt
sudo -u opsuser cat /opt/secure-app/secret.txt
