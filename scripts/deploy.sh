#!/bin/bash
set -euo pipefail

IMAGE="${1:-yourdockerhubuser/foodexpress-api:latest}"
CONTAINER="foodexpress-api"
PORT="3000"

echo "=== FoodExpress Deployment ==="
echo "Image: $IMAGE"
echo "Time:  $(date)"

# Pull the new image
docker pull "$IMAGE"

# Graceful stop of old container
if docker ps -q --filter name="$CONTAINER" | grep -q .; then
    echo "Stopping existing container..."
    docker stop "$CONTAINER" --time=30
fi
docker rm -f "$CONTAINER" 2>/dev/null || true

# Run new container
docker run -d \
    --name "$CONTAINER" \
    --restart unless-stopped \
    -p "$PORT:$PORT" \
    -e NODE_ENV=production \
    -e PORT="$PORT" \
    --memory="512m" \
    --cpus="1.0" \
    --log-driver json-file \
    --log-opt max-size="10m" \
    --log-opt max-file="3" \
    "$IMAGE"

# Wait and verify
sleep 10
if curl -sf http://localhost:"$PORT"/health > /dev/null; then
    echo " Deployment successful!"
    docker system prune -f --volumes 2>/dev/null || true
else
    echo " Health check failed! Rolling back..."
    docker stop "$CONTAINER" || true
    exit 1
fi