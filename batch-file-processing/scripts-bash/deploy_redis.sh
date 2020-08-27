helm repo add bitnami https://charts.bitnami.com/bitnami
helm install redis bitnami/redis

kubectl get secret --namespace default redis -o jsonpath="{.data.redis-password}" > encoded.b64

base64 --decode encoded.b64 > password.txt

# copy the password from password.txt and delete the two files: password.txt and encoded.b64