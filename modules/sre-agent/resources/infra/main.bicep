@description('Base name for workshop resources. Must be globally safe for Azure resource names.')
param appName string

@description('Azure region for resources.')
param location string = resourceGroup().location

@description('Container image to deploy after CI publishes one. Keep the default for planning-only validation.')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Incident mode injected into the sample app. Leave blank for healthy runtime.')
@allowed([
  ''
  'checkout_latency'
  'checkout_error'
])
param incidentMode string = ''

var normalizedName = toLower(replace(appName, '_', '-'))
var tags = {
  workload: 'frontier-agentic-devops-hackathon'
  environment: 'workshop'
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${normalizedName}-logs'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource managedEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: '${normalizedName}-env'
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: workspace.properties.customerId
        sharedKey: workspace.listKeys().primarySharedKey
      }
    }
  }
}

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: normalizedName
  location: location
  tags: tags
  properties: {
    managedEnvironmentId: managedEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 3000
        transport: 'auto'
      }
    }
    template: {
      containers: [
        {
          name: 'sample-app'
          image: containerImage
          env: [
            {
              name: 'INCIDENT_MODE'
              value: incidentMode
            }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/healthz'
                port: 3000
              }
              initialDelaySeconds: 10
              periodSeconds: 30
            }
          ]
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 2
      }
    }
  }
}

output appUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output logAnalyticsWorkspaceName string = workspace.name
