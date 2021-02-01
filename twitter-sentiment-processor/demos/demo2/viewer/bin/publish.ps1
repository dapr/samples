# Be sure and log into your docker hub account

$RELEASE_VERSION='v0.3.4'
$DOCKER_HUB_USER='darquewarrior'

docker build `
  --build-arg APP_VERSION=$RELEASE_VERSION `
  -t $DOCKER_HUB_USER/viewer:$RELEASE_VERSION `
  .

docker push $DOCKER_HUB_USER/viewer:$RELEASE_VERSION
