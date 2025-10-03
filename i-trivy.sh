# Update package index
sudo apt-get update

# Install curl if missing
sudo apt-get install -y curl gnupg

# Add Aqua Security's GPG key
curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg

# Add Trivy APT repository
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb stable main" | sudo tee /etc/apt/sources.list.d/trivy.list

# Update and install
sudo apt-get update
sudo apt-get install trivy -y
