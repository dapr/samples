# Install the CustomResourceDefinition resources
kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.13/deploy/manifests/00-crds.yaml

# Label the cert-manager namespace to disable resource validation
kubectl label namespace ingress-basic cert-manager.io/disable-validation=true

# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io

# Update your local Helm chart repository cache
helm repo update

# Install the cert-manager Helm chart
helm install cert-manager --namespace ingress-basic --version v0.13.0 jetstack/cert-manager

# Verify the installation - kubectl get pods --namespace ingress-basic
# You should see the cert-manager, cert-manager-cainjector, and cert-manager-webhook pod
# in a Running state. It may take a minute or so for the TLS assets required for the webhook
# to function to be provisioned. This may cause the webhook to take a while longer to start
# for the first time than other pods.
# https://cert-manager.io/docs/installation/kubernetes/

# Set your email in deploy/cluster-issuer.yaml and run:
kubectl apply -f deploy/cluster-issuer.yaml --namespace ingress-basic

# Set your FQDN in deploy/ingress.yaml and run:
kubectl apply -f deploy/ingress.yaml

# Cert-manager has likely automatically created a certificate object
# for you using ingress-shim, which is automatically deployed with
# cert-manager since v0.2.2. If not, follow this tutorial:
# https://docs.microsoft.com/en-us/azure/aks/ingress-static-ip#create-a-certificate-object)
# to create a certificate object.

# To test, run:
# kubectl describe certificate tls-secret
#
# You connection should now be secure.