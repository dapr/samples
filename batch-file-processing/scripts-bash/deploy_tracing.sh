# Add App Insights extension to Azure CLI
az extension add -n application-insights

# Create an App Insights resource
az monitor app-insights component create \
    --app <app-insight-resource-name> \
    --location <location> \
    --resource-group <resource-group-name>

# Copy the value of the instrumentationKey, we will need it later