#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Install kubectl
echo "Installing kubectl..."
VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
curl -L -o kubectl "https://storage.googleapis.com/kubernetes-release/release/${VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

# Install eksctl
echo "Installing eksctl..."
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" -o eksctl.tar.gz
tar -xzf eksctl.tar.gz
sudo mv eksctl /usr/local/bin/
eksctl version

# Create an EKS cluster
echo "Creating EKS cluster..."
eksctl create cluster \
  --name demo-blue-green-cluster \
  --region us-east-1 \
  --nodegroup-name free-tier-nodes \
  --node-type t3.small \
  --nodes 1 \
  --nodes-min 1 \
  --nodes-max 1 \
  --managed

# Install Helm
echo "Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 -o get_helm.sh
chmod +x get_helm.sh
./get_helm.sh
helm version

# Add Jenkins Helm chart repository
echo "Adding Jenkins Helm chart repository..."
helm repo add jenkins https://charts.jenkins.io
helm repo update

# Deploy Jenkins
echo "Deploying Jenkins..."
kubectl create namespace jenkins
helm install jenkins jenkins/jenkins \
  --namespace jenkins \
  --set controller.serviceType=LoadBalancer

# Wait for Jenkins to be ready
echo "Waiting for Jenkins to be ready..."
kubectl wait --namespace jenkins \
  --for=condition=available \
  --timeout=600s \
  deployment/jenkins

# Set up ECR repository
echo "Setting up ECR repository..."
aws ecr create-repository --repository-name nodejs-bluegreen

# Create CodeBuild project
echo "Creating CodeBuild project..."
aws codebuild create-project \
  --name nodejs-bluegreen-build \
  --source type=S3,location=my-nodejs-bluegreen-source/nodejs-bluegreen.zip \
  --artifacts type=NO_ARTIFACTS \
  --environment type=LINUX_CONTAINER,computeType=BUILD_GENERAL1_SMALL,image=aws/codebuild/standard:5.0,privilegedMode=true \
  --service-role arn:aws:iam::<your_account_id>:role/codebuild-service-role

# Start CodeBuild build
echo "Starting CodeBuild build..."
aws codebuild start-build --project-name nodejs-bluegreen-build

# Download Kubernetes manifests from S3
echo "Downloading Kubernetes manifests from S3..."
aws s3 cp s3://my-nodejs-bluegreen-source/manifests/blue-deployment.yaml .
aws s3 cp s3://my-nodejs-bluegreen-source/manifests/green-deployment.yaml .
aws s3 cp s3://my-nodejs-bluegreen-source/manifests/service.yaml .

# Deploy blue version of the application
echo "Deploying blue version of the application..."
kubectl apply -f blue-deployment.yaml

# Create Kubernetes service
echo "Creating Kubernetes service..."
kubectl apply -f service.yaml

# Deploy green version of the application
echo "Deploying green version of the application..."
kubectl apply -f green-deployment.yaml

echo "Setup complete!"
