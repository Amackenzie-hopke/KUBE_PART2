
echo "initilizing github and pulling files"
rm -rf .git
git init
rm -rf DEV_OPS_KUBE
git clone https://github.com/Amackenzie-hopke/DEV_OPS_KUBE 

cd DEV_OPS_KUBE
# Script to Install Docker Engine, Minikube, kubectl, and Kompose on Ubuntu WSL2

echo "Starting Docker Engine, Minikube, kubectl, and Kompose installation on Ubuntu WSL2..."

# 1. Update and Upgrade Existing Packages
echo -e "\n--- Updating and upgrading existing packages ---"
sudo apt update && sudo apt upgrade -y || { echo "Failed to update/upgrade packages. Exiting."; exit 1; }

# --- Docker Installation ---

# 2. Install Required Dependencies for Docker (already good)
echo -e "\n--- Installing required dependencies for Docker ---"
sudo apt install -y ca-certificates curl gnupg lsb-release || { echo "Failed to install Docker dependencies. Exiting."; exit 1; }


# 3. Add Docker's Official GPG Key
# This command directly adds the GPG key to the trusted.gpg.d directory for apt.
echo -e "\n--- Adding Docker's official GPG key ---"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg || { echo "Failed to download/add Docker GPG key. Exiting."; exit 1; }
sudo chmod a+r /etc/apt/keyrings/docker.gpg # Set permissions to be readable by all

# 4. Add the Docker APT Repository
# This command adds the repository using the new 'signed-by' syntax with the direct GPG key file path.
echo -e "\n--- Adding the Docker APT repository ---"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || { echo "Failed to add Docker repository. Exiting."; exit 1; }

# 5. Update apt Package Index Again
echo -e "\n--- Updating apt package index again for Docker ---"
sudo apt update || { echo "Failed to update apt index for Docker. Exiting."; exit 1; }

# 6. Install Docker Engine, CLI, and Containerd
echo -e "\n--- Installing Docker Engine, CLI, and Containerd ---"
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || { echo "Failed to install Docker components. Exiting."; exit 1; }

# 7. Add Your User to the 'docker' Group
echo -e "\n--- Adding current user ($USER) to the 'docker' group ---"
sudo usermod -aG docker $USER || { echo "Failed to add user to docker group. Exiting."; exit 1; }
sudo chmod 777 /var/run/docker.sock

# -q is quiet : is exact match local is restricted to function and $1 sets first param
echo -e "\n---checking ports: beware ports will be unavailable: if services are up and script has been ran"
check_port() {
	local PORT=$1
	if ss  -tulpn | grep -q ":$PORT"; then
		echo "Port $PORT is unavailable"
	else
		echo "Port $PORT is available"
	fi
}



check_port 3000 || { echo "Failed. Exiting."; exit 1; }
check_port 80 || { echo "Failed. Exiting."; exit 1; }
check_port 5000 || { echo "Failed. Exiting."; exit 1; }


# 9. (Optional) Configure Docker Service to Start Automatically
echo -e "\n--- (Optional) Adding Docker service start command to ~/.bashrc ---"
if ! grep -q "sudo service docker start" ~/.bashrc; then
    echo 'sudo service docker start > /dev/null 2>&1 || true' >> ~/.bashrc
    echo "Added 'sudo service docker start' to ~/.bashrc."
else
    echo "Line already exists in ~/.bashrc. Skipping."
fi

echo -e "\n---docker version"
docker --version || { echo "Failed. Exiting."; exit 1; }

echo -e "\n---confirm docker compose existance with ls"
ls || { echo "Failed. Exiting."; exit 1; }

echo -e "\n---docker compose build"
sudo docker compose up --build -d || { echo "Failed. Exiting."; exit 1; }

echo -e "\n---docker compose ps output"
docker compose ps || { echo "Failed. Exiting."; exit 1; }

# extracting nginx container name --format allows us to extract the names column 
echo -e "\n---extract name from nginx container"
NGINX_container=$(docker ps --filter "name=nginx" --format "{{.Names}}") || { echo "Failed to extract gninx container name. Exiting."; exit 1; }

echo -e "\n--- nginx container name is ${NGINX_container}"
echo -e "\n---current directory structure"
ls

echo -e "\n---front end health check"
curl http://localhost:80 || { echo "Failed. Exiting."; exit 1; }
curl http://localhost:80/api/login || { echo "Failed. Exiting."; exit 1; }




echo -e "\n--- docker images"
docker images || { echo "Failed. Exiting."; exit 1; }

echo -e "\n--- installing jq"
sudo apt -y update || { echo "Failed. Exiting."; exit 1; }
sudo apt -y install jq || { echo "Failed. Exiting."; exit 1; }

echo -e "\n---inspecting nginx alpine with jq"
NGINX_IMAGE="nginx:alpine" || { echo "Failed. Exiting."; exit 1; }
echo -e "\n---moving nginx alpine with jq output yo a logs json file"
docker inspect "$NGINX_IMAGE" > nginx-logs.json

echo -e "\n---extracting repo tags from nginx logs"
repoTags=$(jq '.[0].RepoTags' nginx-logs.json)
echo "$repoTags"

echo -e "\n---extracting Created from nginx logs"
Created=$(jq '.[0].Created' nginx-logs.json)
echo "$Created"


echo -e "\n---extracting Os from nginx logs"
Os=$(jq '.[0].Os' nginx-logs.json)
echo "$Os"

echo -e "\n---extracting Config from nginx logs"
Config=$(jq '.[0].Config' nginx-logs.json)
echo "$Config"

echo -e "\n---extracting ExposedPorts from nginx logs"
ExposedPorts=$(jq '.[0].Config.ExposedPorts' nginx-logs.json)
echo "$ExposedPorts"
