Write-Host "sending blob created event"

curl.exe http://localhost:3500/v1.0/invoke/batch-receiver/method/blobAddedHandler -H "Content-Type: application/json" -d @testdata/orderHeaderDetails

curl.exe http://localhost:3500/v1.0/invoke/batch-receiver/method/blobAddedHandler -H "Content-Type: application/json" -d @testdata/orderLineItems

curl.exe http://localhost:3500/v1.0/invoke/batch-receiver/method/blobAddedHandler -H "Content-Type: application/json" -d @testdata/productInformation