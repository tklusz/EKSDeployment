# EKSDeployment

## Setup Notes
Ensure Terraform is installed and on your path. Anything later than 12 should be fine.

You will also need AWS CLI. I'm using version 2.

## Creation Instructions
First, we're creating the infrastructure using Terraform plus one manual step.

Create an admin account in the AWS IAM console if you don't already have one. For the purpose of this deployment, give the user the AdminstratorAccess policy.
* It isn't possible to run Terraform without an Access Key Id or Secret Access Key, so this manual step is required.

Run `aws configure` and enter the account details. If using a region other than us-west-2, change the region in `Terraform/terraform.tfvars`.

Navigate to `Terraform/`
* Update the `hosted_zone_name` in `terraform.tfvars` if desired.
* Run `terraform init`.
* Run `terraform plan -out=tfplan`.
* If everything looks good, run `terraform apply tfplan`.

## Post-Creation
Next, we're going to configure the cluster.

Run `aws eks --region us-west-2 update-kubeconfig --name primary`. Replace the region and cluster name if you used different ones.

Navigate to `Terraform/` if not already there.
* Note that the following files are generated as a part of the `terraform apply`.
* Run `kubectl apply -f aws-auth.yaml`. This provides permissions to the worker nodes and IAM users we've previously created.
* To enable cluster autoscaling, run `kubectl apply -f cluster_autoscaler.yaml`.
* To enable `external-dns` and `alb-ingress-controller` (allows for automatic Route 53 private-zone updating), run `kubectl apply -f external_dns.yaml`.


### Testing with Multiple Users
This section describes how to configure RBAC for the multiple users we've created.

First, the credentials for the IAM users `eks_admin`, `user-1` and `user-2`, must be manually created on the console if you intend to test with them.

To set up the users, navigate to the `Kubernetes/` directory.
* Run `kubectl create -f namespaces.json`. This creates the namespaces for the users.
* Next, run `kubectl create -f roles.yaml`. This applies RBAC roles and role-bindings to the users.
  * `user-1` will have access to the `user-1` namespace, `user-2` to the `user-2` namespace, and the `eks_admin` to all namespaces.

Run `aws configure` and enter the credentials of a user you want to test with (you can also create a profile for easier switching).

Run `aws eks --region us-west-2 update-kubeconfig --name primary`. Replace the region and cluster name if you used different ones.

You will now have the ability to create deployments in the namespaces the user has permissions for.

## Automatic Private Hosted Zone Updating
This is done using `external-dns` along with an `aws-alb-ingress-controller`.
For more information see [external-dns](https://github.com/kubernetes-sigs/external-dns) and [aws-alb-ingress-controller](https://aws.amazon.com/blogs/opensource/kubernetes-ingress-aws-alb-ingress-controller/).

In order for the `external-dns` deployment to update Route 53 with your services and ingresses automatically, note this formatting -
```
apiVersion: v1
kind: Service
metadata:
  name: nginx
  annotations:
    external-dns.alpha.kubernetes.io/hostname: test.tylerdevops.com
spec:
  type: LoadBalancer
  ports:
  - port: 80
    name: http
    targetPort: 80
  selector:
    app: nginx
```
The annotation `external-dns.alpha.kubernetes.io/hostname: <hostname>` should match the desired hostname.

After applying, wait 1-2 minutes, then do an `nslookup` of the hostname on one of your pods to test that the record is resolving correctly.
* Note that outside of the VPC these names won't be reachable, you'll have to use the ALB/ELB endpoint directly.

This same annotation is used for ingresses -
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: "2048-ingress"
  namespace: "2048-game"
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    external-dns.alpha.kubernetes.io/hostname: 2048.tylerdevops.com
  labels:
    app: 2048-ingress
spec:
  rules:
    - http:
        paths:
          - path: /*
            backend:
              serviceName: "service-2048"
              servicePort: 80
```

## Extra Features
* Internal and external load-balancing definitions in Kubernetes charts create load balancers correctly. Note that any load balancers created via Kubernetes won't automatically delete with a `terraform destroy`. Please use kubectl to delete all services/ingresses prior to running a `terraform destroy`.
* Cluster autoscaling is enabled (The number of instances will be scaled to the `max_size`/`min_size`, when required).
* ASGs are set up in a blue-green deployment configuration, which makes upgrading easier.
* One NAT gateway is created for each public subnet, which I would recommend in a production deployment. This is advantageous in the event an AZ goes down.


## Design Decisions
* I decided to use a local Terraform backend to avoid manual creation of an S3 bucket, or extra steps during the deployment. In a deployment with multiple contributors, you will want to set up an S3 bucket manually for use as a remote state.
  * Not using an S3 backend allows the entire infrastructure to be deleted with a `terraform destroy` which is beneficial for testing purposes.
* Using MFA is recommended in a production environment, using MFA will change the setup instructions here. I would recommend a 3rd party tool such as [awsume](https://awsu.me) to make the process easier.
* I'm not using the Kubernetes module for resource creation as there is a bug where the Kubernetes API calls will time-out waiting for cluster creation. The issue is described [here](https://github.com/hashicorp/terraform-provider-kubernetes/issues/144) and [here](https://github.com/hashicorp/terraform/issues/2430).
* Resource restrictions in the policies could be improved for added security. For a PoC, this is fine, but in a production cluster you would want to tune those values.
