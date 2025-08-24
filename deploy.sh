#!/bin/bash

# DigitalOcean Deployment Script for LeetCode Spaced
# This script automates the deployment process to a DigitalOcean droplet

set -e

# Configuration
DROPLET_IP=${1:-"your-droplet-ip"}
SSH_USER=${2:-"root"}
APP_DIR="/var/www/leetcode_spaced"
REPO_URL="https://github.com/yourusername/leetcode_spaced.git"

echo "🚀 Starting deployment to DigitalOcean Droplet..."

# Function to run commands on the droplet
remote_exec() {
    ssh -o StrictHostKeyChecking=no $SSH_USER@$DROPLET_IP "$1"
}

# Step 1: Initial server setup (run once)
if [ "$3" == "--init" ]; then
    echo "📦 Running initial server setup..."
    
    remote_exec "apt-get update && apt-get upgrade -y"
    remote_exec "apt-get install -y docker.io docker-compose git nginx certbot python3-certbot-nginx"
    remote_exec "systemctl start docker && systemctl enable docker"
    remote_exec "mkdir -p $APP_DIR"
    
    # Add swap if needed (for small droplets)
    remote_exec "fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile"
    remote_exec "echo '/swapfile none swap sw 0 0' >> /etc/fstab"
    
    echo "✅ Initial setup complete!"
fi

# Step 2: Deploy application
echo "📂 Deploying application..."

# Copy files to droplet
echo "📤 Copying files to droplet..."
scp -r \
    Dockerfile \
    docker-entrypoint.sh \
    docker-compose.prod.yml \
    nginx.conf \
    .env \
    $SSH_USER@$DROPLET_IP:$APP_DIR/

# Copy source code (excluding unnecessary files)
rsync -avz --exclude-from='.gitignore' \
    --exclude='.git' \
    --exclude='_build' \
    --exclude='deps' \
    --exclude='node_modules' \
    --exclude='.elixir_ls' \
    ./ $SSH_USER@$DROPLET_IP:$APP_DIR/

# Step 3: Build and run on droplet
echo "🔨 Building Docker image..."
remote_exec "cd $APP_DIR && docker build -t leetcode_spaced:latest ."

# Step 4: Run database migrations
echo "🗄️ Running database setup and migrations..."
remote_exec "cd $APP_DIR && docker-compose -f docker-compose.prod.yml up -d postgres"
remote_exec "sleep 10" # Wait for postgres to be ready

# Step 5: Start the application
echo "🎯 Starting application..."
remote_exec "cd $APP_DIR && docker-compose -f docker-compose.prod.yml up -d"

# Step 6: Setup SSL (optional)
if [ "$3" == "--ssl" ]; then
    echo "🔒 Setting up SSL certificate..."
    DOMAIN=$4
    if [ -z "$DOMAIN" ]; then
        echo "❌ Error: Domain name required for SSL setup"
        echo "Usage: ./deploy.sh <droplet-ip> <user> --ssl <domain>"
        exit 1
    fi
    
    remote_exec "certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN"
    echo "✅ SSL certificate installed!"
fi

# Step 7: Health check
echo "🏥 Performing health check..."
sleep 5
curl -f http://$DROPLET_IP:4000 > /dev/null 2>&1 && echo "✅ Application is running!" || echo "❌ Application health check failed"

echo "🎉 Deployment complete!"
echo "📍 Your app is available at: http://$DROPLET_IP:4000"
echo ""
echo "Useful commands:"
echo "  SSH to droplet: ssh $SSH_USER@$DROPLET_IP"
echo "  View logs: ssh $SSH_USER@$DROPLET_IP 'cd $APP_DIR && docker-compose -f docker-compose.prod.yml logs -f'"
echo "  Restart app: ssh $SSH_USER@$DROPLET_IP 'cd $APP_DIR && docker-compose -f docker-compose.prod.yml restart'"