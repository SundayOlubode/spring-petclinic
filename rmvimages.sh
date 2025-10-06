#!/bin/bash
# A script to remove multiple Docker images at once using their IMAGE IDs

IMAGE_IDS=$(docker images -q)

if [ -z "$IMAGE_IDS" ]; then
  echo "No images found to remove."
  exit 0
fi

echo "The following image IDs will be removed:"
echo "$IMAGE_IDS"
echo

read -p "Are you sure you want to remove these images? (y/n): " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
  docker rmi -f $IMAGE_IDS
  echo "All listed images have been removed."
else
  echo "Operation cancelled."
fi
