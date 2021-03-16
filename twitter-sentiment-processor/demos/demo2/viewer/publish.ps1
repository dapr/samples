# Be sure and log into your docker hub account
[CmdletBinding()]
param (
   [Parameter(
      Position = 0,
      HelpMessage = "The name of the docker up user to push images to."
   )]
   [string]
   $dockerHubUser = 'darquewarrior',

   [Parameter(
      Position = 1,
      HelpMessage = "The version of the dapr runtime version to use as image tag."
   )]
   [string]
   $daprVersion = "1.0.0"
)

docker build --build-arg APP_VERSION=$daprVersion -t $dockerHubUser/viewer:$daprVersion .

docker push $dockerHubUser/viewer:$daprVersion
