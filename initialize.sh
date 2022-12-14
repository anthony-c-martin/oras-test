#!/bin/bash

subId=<<FILL IN>>
tenantId=<<FILL IN>>
registryName=antregistry2
rgName=ant-test
repoName=oras-test
repoSubject=repo:anthony-c-martin/$repoName:ref:refs/heads/main

az deployment group create --resource-group $rgName --template-file ./bicep/acr.bicep --parameters registryName=$registryName

appCreate=$(az ad app create --display-name $registryName)
appId=$(echo $appCreate | jq -r '.appId')
appOid=$(echo $appCreate | jq -r '.id')

spCreate=$(az ad sp create --id $appId)
spId=$(echo $spCreate | jq -r '.id')
az role assignment create --role contributor --subscription $subId --assignee-object-id $spId --assignee-principal-type ServicePrincipal --scope /subscriptions/$subId/resourceGroups/ant-test

az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$appOid/federatedIdentityCredentials" --body '{"name":"'$repoName'","issuer":"https://token.actions.githubusercontent.com","subject":"'$repoSubject'","description":"GitHub OIDC Connection","audiences":["api://AzureADTokenExchange"]}'

echo "Now configure the following GitHub Actions secrets:"
echo "  ACR_CLIENT_ID: $appId"
echo "  ACR_SUBSCRIPTION_ID: $subId"
echo "  ACR_TENANT_ID: $tenantId"
