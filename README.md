# EKSDeployment

## Design Decisions
* I decided to use a local terraform backend to avoid manual creation of an S3 bucket, or extra steps during the deployment. In a production environment, you will want to set up an s3 bucket manually prior to the deployment for use as a remote state.
* I created multiple NAT Gateways, one for each subnet, which I would recommend in a production deployment. This is advantageous in the event an AZ goes down.
* For the IAM users, passwords for them must be manually created on the console if you want to login with them and test.

## Setup Notes
* Ensure Terraform is installed and on your path. I'm using version 0.12.26 for this deployment.
* You will also need AWS CLI; this is just to run `aws configure` to set up account details. This isn't strictly required but it makes life easier.

## Creation Instructions
* Create an admin account in AWS IAM console. For the purpose of this deployment, give the user the AdminstratorAccess policy.
  * In a production deployment, you would only give the account permissions required to deploy the infrastructure.
  * It isn't possible to run Terraform without an Access Key Id or Secret Access Key, so this manual step is required.
* Run `aws configure` and enter account details.
* Navigate to `EKSDeployment/Terraform` and run `terraform init`.
* Run `terraform plan -out=tfplan`.
* If everything looks good, run `terraform apply tfplan`
