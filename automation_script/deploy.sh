
#!/bin/bash

# Variables
S3_BUCKET="my-nodejs-bluegreen-source"
S3_PATH="manifests"
LOCAL_PATH="/tmp/k8s-manifests"
BLUE_DEPLOYMENT="blue-deployment.yaml"
GREEN_DEPLOYMENT="green-deployment.yaml"
SERVICE="service.yaml"

# Create local directory
mkdir -p $LOCAL_PATH

# Download manifests from S3
aws s3 cp s3://$S3_BUCKET/$S3_PATH/$BLUE_DEPLOYMENT $LOCAL_PATH/
aws s3 cp s3://$S3_BUCKET/$S3_PATH/$GREEN_DEPLOYMENT $LOCAL_PATH/
aws s3 cp s3://$S3_BUCKET/$S3_PATH/$SERVICE $LOCAL_PATH/

# Apply blue deployment and service
kubectl apply -f $LOCAL_PATH/$BLUE_DEPLOYMENT
kubectl apply -f $LOCAL_PATH/$SERVICE

# Function to switch traffic to green
switch_to_green() {
    # Modify service.yaml to point to green
    sed -i 's/version: blue/version: green/' $LOCAL_PATH/$SERVICE
    kubectl apply -f $LOCAL_PATH/$SERVICE
}

# Function to switch traffic to blue
switch_to_blue() {
    # Modify service.yaml to point to blue
    sed -i 's/version: green/version: blue/' $LOCAL_PATH/$SERVICE
    kubectl apply -f $LOCAL_PATH/$SERVICE
}

# Check for argument to switch traffic
if [ "$1" == "green" ]; then
    switch_to_green
elif [ "$1" == "blue" ]; then
    switch_to_blue
else
    echo "Usage: $0 {blue|green}"
fi
