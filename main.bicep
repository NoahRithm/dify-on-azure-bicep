targetScope = 'subscription'

param location string = 'japaneast'
param environmentName string = 'prod'
param resourceGroupName string = 'rg-dify-${environmentName}'
@description('管理端末のグローバルIPv4アドレス')
param adminSourceIp string
@secure()
@description('SSH 公開鍵')
param adminPublicKey string
param adminUsername string = 'azureuser'
param vmSize string = 'Standard_B2ms'

var tags = {
  environment: environmentName
  project: 'dify'
}

// ── リソースグループ ｓ
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// ── ネットワーク ────────────────────────────
module network 'modules/network.bicep' = {
  name: 'network'
  scope: rg
  params: {
    location: location
    tags: tags
    adminSourceIp: adminSourceIp
  }
}

// ── VM ──────────────────────────────────────
module vm 'modules/vm.bicep' = {
  name: 'vm'
  scope: rg
  params: {
    location: location
    tags: tags
    adminPublicKey: adminPublicKey
    subnetId: network.outputs.subnetId
    nsgId: network.outputs.nsgId
    adminUsername  : adminUsername
    vmSize         : vmSize
  }
}

// ── Outputs ────────────────────────────────
output resourceGroupName string = rg.name
output publicIp         string = vm.outputs.publicIp
output sshCommand string = format(
  'ssh {0}@{1}',
  adminUsername,
  vm.outputs.publicIp
)
