# demo-blue-green-cluster
Sample repository to create EKS cluster, Deploy jenkins on it and demonstrate a blue green deployment of an application (nodejs)

# Pre-requisite steps:
1. Create s3 bucket with name 'my-nodejs-bluegreen-source'.
2. Download repo at local and update all occurances of <your_account_id> with actual account_id.
3. push all folders to s3 bucket.


# Use:
1. Upload automation shell scripts to CloudShell:
   	aws s3 cp s3://my-nodejs-bluegreen-source/automation_script/setup_eks_jenkins_codebuild.sh .
	aws s3 cp s3://my-nodejs-bluegreen-source/automation_script/deploy.sh .
2. Make executable:
   	chmod +x setup_eks_jenkins_codebuild.sh 
	chmod +x deploy.sh
3. Run setup_eks_jenkins_codebuild.sh for complete setup with EKS cluster.
    	./setup_eks_jenkins_codebuild.sh
4. Run deploy to switch traffic between blue and green:
   ./deploy.sh blue or ./deploy.sh green
