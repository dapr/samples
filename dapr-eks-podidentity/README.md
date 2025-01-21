# Setting Up Dapr with AWS EKS Pod Identity and Secrets Manager

This guide walks through setting up Dapr with AWS EKS Pod Identity for accessing AWS Secrets Manager.

## Prerequisites

- [AWS CLI configured with appropriate permissions](https://docs.dapr.io/developing-applications/integrations/aws/authenticating-aws/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [eksctl](https://eksctl.io/installation/)
- [Docker](https://docs.docker.com/engine/install/)
- A Docker Hub account or another container registry

## Clone repository

```bash
git clone https://github.com/dapr/samples.git
cd samples/dapr-eks-podidentity
```

## Create EKS Cluster and install Dapr

Follow the official Dapr documentation for setting up an EKS cluster and installing Dapr:
[Set up an Elastic Kubernetes Service (EKS) cluster](https://docs.dapr.io/operations/hosting/kubernetes/cluster/setup-eks/)

## Create IAM Role and Enable Pod Identity

1. Create IAM policy for Secrets Manager access:

```bash
aws iam create-policy \
    --policy-name dapr-secrets-policy \
    --policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "secretsmanager:GetSecretValue",
                    "secretsmanager:DescribeSecret"
                ],
                "Resource": "arn:aws:secretsmanager:YOUR_AWS_REGION:YOUR_ACCOUNT_ID:secret:*"
            }
        ]
    }'
```

2. Create IAM role with Pod Identity trust relationship:

```bash
aws iam create-role \
    --role-name dapr-pod-identity-role \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "pods.eks.amazonaws.com"
                },
                "Action": [
                    "sts:AssumeRole",
                    "sts:TagSession"
                ]
            }
        ]
    }'
```

3. Attach the policy to the role:

```bash
aws iam attach-role-policy \
    --role-name dapr-pod-identity-role \
    --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/dapr-secrets-policy
```

## Create Test Resources

1. Create namespace:

```bash
kubectl create namespace dapr-podidentity
```

2. Create service account (`service-account.yaml`):

```bash
kubectl apply -f k8s-config/service-account.yaml
```

3. Create Pod Identity association:

```bash
eksctl create podidentityassociation \
    --cluster [your-cluster-name] \
    --namespace dapr-podidentity \
    --region [your-aws-region] \
    --service-account-name dapr-test-sa \
    --role-arn arn:aws:iam::YOUR_ACCOUNT_ID:role/dapr-pod-identity-role
```

4. Create a test secret in AWS Secrets Manager:

```bash
aws secretsmanager create-secret \
    --name test-secret \
    --secret-string '{"key":"value"}' \
    --region [your-aws-region]
```

5. Create Dapr component for AWS Secrets Manager (`aws-secretstore.yaml`):

```bash
kubectl apply -f components/aws-secretstore.yaml
```

## Deploy Test Application

1. Build and push the Docker image:

```bash
cd app
docker build -t your-repository/dapr-secrets-test:latest .
docker push your-repository/dapr-secrets-test:latest
```

2. Apply the deployment:

```bash
kubectl apply -f deploy/app.yaml
```

> Modify `your-repository` with your container registry repository name on the commands above and inside `/deploy/app.yaml`.

## Testing

1. Check if the pod is running:

```bash
kubectl get pods -n dapr-podidentity
```

2. Port forward to access the application:

```bash
kubectl port-forward -n dapr-podidentity deploy/test-app 8080:8080
```

3. Test secret access:

```bash
curl http://localhost:8080/test-secret
```

## Troubleshooting

### Authentication Issues

If you see "You must be logged in to the server (Unauthorized)", update your kubeconfig:

```bash
aws eks update-kubeconfig --region [your-aws-region] --name [your-cluster-name]
```

### Pod Identity Issues

Verify Pod Identity association:

```bash
eksctl get podidentityassociation --cluster [your-cluster-name] --region [your-aws-region]]
```

### Dapr Component Issues

Check Dapr sidecar logs:

```bash
kubectl logs -n dapr-podidentity -l app=test-app -c daprd
```

## References

- [EKS Pod Identity Documentation](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)
- [Set up an Elastic Kubernetes Service (EKS) cluster](https://docs.dapr.io/operations/hosting/kubernetes/cluster/setup-eks/)
