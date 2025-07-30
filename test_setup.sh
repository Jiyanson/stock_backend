#!/bin/bash

echo "🚀 Setting up Docker containers for stock_backend..."

# Check if user has Docker permissions
if ! docker ps > /dev/null 2>&1; then
    echo "❌ Docker permission error detected!"
    echo "🔧 Fixing Docker permissions..."
    
    # Add user to docker group if not already added
    if ! groups $USER | grep -q docker; then
        echo "➕ Adding user to docker group..."
        sudo usermod -aG docker $USER
        echo "⚠️  Please log out and log back in, then run this script again."
        echo "   Or run: newgrp docker"
        exit 1
    else
        echo "👤 User is in docker group, trying with sudo..."
        USE_SUDO="sudo "
    fi
else
    USE_SUDO=""
fi

# Clean up any existing containers and volumes
echo "📁 Cleaning up existing containers..."
${USE_SUDO}docker-compose down -v --remove-orphans

# Remove all images to force rebuild
echo "🔨 Rebuilding Docker images..."
${USE_SUDO}docker-compose build --no-cache

# Start services
echo "▶️ Starting services..."
${USE_SUDO}docker-compose up -d

# Wait a moment for services to start
echo "⏳ Waiting for services to initialize..."
sleep 10

# Check service status
echo "📊 Service Status:"
${USE_SUDO}docker-compose ps

# Check logs for any immediate errors
echo "📋 Recent logs from www service:"
${USE_SUDO}docker-compose logs --tail=20 www

echo "✅ Setup complete!"
echo "🌐 FastAPI should be available at: http://localhost"
echo "🔍 To view logs: ${USE_SUDO}docker-compose logs -f"
echo "🛑 To stop: ${USE_SUDO}docker-compose down"