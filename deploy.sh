#!/bin/bash

# Step 1: Authenticate to Azure
echo "Logging into Azure..."
az login

# Step 2: Load config or ask for required parameters
CONFIG_FILE="deploy-config.json"

if [ -f "$CONFIG_FILE" ]; then
    echo "Loading configuration from $CONFIG_FILE..."
    RESOURCE_GROUP=$(jq -r '.resource_group // empty' "$CONFIG_FILE")
    ACR_NAME=$(jq -r '.acr_name // empty' "$CONFIG_FILE")
    WEB_APP_NAME=$(jq -r '.web_app_name // empty' "$CONFIG_FILE")
    IMAGE_TAG=$(jq -r '.image_tag // empty' "$CONFIG_FILE")
    IMAGE_NAME=$(jq -r '.image_name // empty' "$CONFIG_FILE")
else
    echo "No config file found. You can create '$CONFIG_FILE' to avoid entering these values each time."
fi

# Ask for missing parameters
if [ -z "$RESOURCE_GROUP" ]; then
    echo "Enter the name of the Azure Resource Group:"
    read RESOURCE_GROUP
fi

if [ -z "$ACR_NAME" ]; then
    echo "Enter the name of the Azure Container Registry (ACR):"
    read ACR_NAME
fi

if [ -z "$WEB_APP_NAME" ]; then
    echo "Enter the name of the Web App in Azure:"
    read WEB_APP_NAME
fi

if [ -z "$IMAGE_TAG" ]; then
    echo "Enter the tag for the Docker image (e.g., latest):"
    read IMAGE_TAG
fi

if [ -z "$IMAGE_NAME" ]; then
    echo "Enter the name of the Docker image (e.g., holaspirit-mcp):"
    read IMAGE_NAME
fi

echo "Using configuration:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  ACR Name: $ACR_NAME"
echo "  Web App Name: $WEB_APP_NAME"
echo "  Image Tag: $IMAGE_TAG"
echo "  Image Name: $IMAGE_NAME"

# Step 3: Get ACR login server URL
ACR_SERVER=$(az acr show --name $ACR_NAME --query "loginServer" --output tsv)

# Step 4: Log into Azure Container Registry
echo "Logging into Azure Container Registry..."
az acr login --name $ACR_NAME

# Step 5: Build Docker image locally
echo "Building the Docker image..."
docker buildx build --platform linux/amd64 -t $ACR_SERVER/$IMAGE_NAME:$IMAGE_TAG .

# Step 6: Push the image to ACR
echo "Pushing the image to Azure Container Registry..."
docker push $ACR_SERVER/$IMAGE_NAME:$IMAGE_TAG

# Step 7: Deploy the Docker image to Azure Web App
echo "Deploying Docker container to Azure Web App..."
az webapp config container set --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP \
  --container-image-name $ACR_SERVER/$IMAGE_NAME:$IMAGE_TAG --container-registry-url https://$ACR_SERVER

echo "Deployment Complete!"
