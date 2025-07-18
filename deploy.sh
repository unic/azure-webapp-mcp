#!/bin/bash

# Step 1: Authenticate to Azure
echo "Logging into Azure..."
az login

# Step 2: Ask for required parameters
echo "Enter the name of the Azure Resource Group:"
read RESOURCE_GROUP
echo "Enter the name of the Azure Container Registry (ACR):"
read ACR_NAME
echo "Enter the name of the Web App in Azure:"
read WEB_APP_NAME
echo "Enter the tag for the Docker image (e.g., latest):"
read IMAGE_TAG
echo "Enter the name of the Docker image (e.g., rosen-mcp):"
read IMAGE_NAME

# Step 3: Log into Azure Container Registry
echo "Logging into Azure Container Registry..."
az acr login --name $ACR_NAME

# Step 4: Build Docker image locally
echo "Building the Docker image..."
docker buildx build --platform linux/amd64 -t $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG .

# Step 5: Tag the image
echo "Tagging the Docker image..."
docker tag $IMAGE_NAME:$IMAGE_TAG $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG

# Step 6: Push the image to ACR
echo "Pushing the image to Azure Container Registry..."
docker push $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG

# Step 7: Deploy the Docker image to Azure Web App
echo "Deploying Docker container to Azure Web App..."
az webapp config container set --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP \
  --docker-custom-image-name $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG --docker-registry-server-url https://$ACR_NAME.azurecr.io

# Step 8: Assign AcrPull role to the Managed Identity (if necessary)
echo "Assigning AcrPull role to the Managed Identity..."
az role assignment create --assignee <managed-identity-client-id> --role AcrPull --scope $(az acr show --name $ACR_NAME --query id --output tsv)

echo "Deployment Complete!"
