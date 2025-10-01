param clusterName string = 'devsecops-aks'
param dnsPrefix string = 'devsecopsdns'
param akvName string = 'akv-${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location
param agentCount int = 3
param agentVMSize string = 'Standard_DS2_v2'

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: 'acr${uniqueString(resourceGroup().id)}'
  location: location
  sku: { name: 'Standard' }
  identity: { type: 'SystemAssigned' }
  properties: { adminUserEnabled: true }
}

resource aks 'Microsoft.ContainerService/managedClusters@2024-09-01' = {
  name: clusterName
  location: location
  identity: { type: 'SystemAssigned' }
  properties: {
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: agentCount
        vmSize: agentVMSize
        osType: 'Linux'
        mode: 'System'
      }
    ]
    aadProfile: {
      managed: true
      enableAzureRBAC: true
    }
  }
}

resource akv 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: akvName
  location: location
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: aks.identity.principalId
        permissions: {
          keys: [ 'get' ]
          secrets: [ 'get' ]
        }
      }
    ]
  }
}

output controlPlaneFQDN string = aks.properties.fqdn
