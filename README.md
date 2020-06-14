# EKSDeployment

## Setup Notes
* Ensure Terraform is installed and on your path. I'm using version 0.12.26 for this deployment.
* You will also need AWS CLI. I'm using version 2.0.20.

## Creation Instructions
* Create an admin account in AWS IAM console if you don't already have one. For the purpose of this deployment, give the user the AdminstratorAccess policy.
  * It isn't possible to run Terraform without an Access Key Id or Secret Access Key, so this manual step is required.
* Run `aws configure` and enter account details. If using a region other than us-west-2, change the region in `terraform.tfvars`.
* Update your local IP address in `Terraform/terraform.tfvars` if you would like access to the cluster.
* Navigate to `Terraform/` and run `terraform init`.
* Run `terraform plan -out=tfplan` in the same directory.
* If everything looks good, run `terraform apply tfplan`

## Post-Creation
* Run `aws eks --region us-west-2 update-kubeconfig --name primary`. Replace the region and cluster name if you used different ones.
* Run `kubectl apply -f aws-auth.yaml` while in the `Terraform/` directory.
* To enable cluster autoscaling, run `kubectl apply -f cluster_autoscaler.yaml` while in the `Terraform/` directory.
  * Both of these files are generated as a part of the `terraform apply`.

### Testing with Multiple Users
* For the IAM users `eks_admin`, `user-1` and `user-2`; the credentials must be manually created on the console.
* To set up the users, navigate to the `Kubernetes` directory. Run `kubectl create -f namespaces.json`.
* Next, run `kubectl create -f roles.yaml` in the same directory.
  * `user-1` will have access to the `user-1` namespace, `user-2` to the `user-2` namespace.
* Run `aws_configure` and enter the credentials of another user you wish to test with (you can also create a profile for easier switching).
* Run `aws eks --region us-west-2 update-kubeconfig --name primary`.

## Extra Features
* Internal and external load-balancing definitions in Kubernetes charts create load balancers correctly. Note that any load balancers created via Kubernetes won't automatically delete with a `terraform destroy`.
* Cluster autoscaling is enabled (ASGs will resize automatically when required).
* ASGs are set up in a blue-green deployment configuration, which makes upgrading easier.
* One NAT gateway for each public subnet, which I would recommend in a production deployment. This is advantageous in the event an AZ goes down.

## Design Decisions
* I decided to use a local terraform backend to avoid manual creation of an S3 bucket, or extra steps during the deployment. In a deployment with multiple contributors, you will want to set up an s3 bucket manually for use as a remote state.
  * Not using an S3 backend allows the entire infrastructure to be deleted with a `terraform destroy` which is beneficial for testing purposes.
* I've added the user's IP address as a `terraform.tfvars` input. This just makes deployment for testing easier.
* Using MFA is recommended in a production environment, using MFA will change the setup instructions here. I would recommend a 3rd party tool such as [awsume](https://awsu.me) to make the process easier.
* I'm not using the Kubernetes module for resource creation as there is a bug where the Kubernetes API calls will time-out waiting for cluster creation. The issue is described [here](https://github.com/hashicorp/terraform-provider-kubernetes/issues/144) and [here.](https://github.com/hashicorp/terraform/issues/2430)
