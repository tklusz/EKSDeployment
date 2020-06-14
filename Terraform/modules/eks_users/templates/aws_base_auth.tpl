apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${worker_role_arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
  mapUsers: |
    - userarn: ${admin_user_arn}
      username: ${admin_username}
      groups:
        - system:masters
    - userarn: ${user_1_arn}
      username: ${user_1_name}
      groups:
        - namespace-1-role
    - userarn: ${user_2_arn}
      username: ${user_2_name}
      groups:
        - namespace-2-role
