param location string
param tags object
param adminSourceIp string

resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: 'vnet-dify'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.10.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: 'nsg-dify'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowSSH'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowWeb'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRanges: [ '0-65535' ]
          destinationPortRanges: [ '80', '443' ]
          sourceAddressPrefix: adminSourceIp
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

output subnetId string = vnet.properties.subnets[0].id
output nsgId string = nsg.id
