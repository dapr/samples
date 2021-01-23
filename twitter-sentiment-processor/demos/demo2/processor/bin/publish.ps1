# Be sure and log into your docker hub account

$RELEASE_VERSION='v0.3.3'
$DOCKER_HUB_USER='darquewarrior'

docker build -t $DOCKER_HUB_USER/processor:$RELEASE_VERSION .

docker push $DOCKER_HUB_USER/processor:$RELEASE_VERSION

# docker run -it -p 3002:3002 -d $DOCKER_HUB_USER/processor:$RELEASE_VERSION
