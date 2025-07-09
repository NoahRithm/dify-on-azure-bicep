param location string
param tags object
param adminPublicKey string
param subnetId string
param nsgId string
param adminUsername string
param vmSize string

var vmName = 'vm-dify'

// ── パブリックIP ─────────────────────────────────────
resource pip 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: '${vmName}-pip'
  location: location
  tags: tags

  sku: {
    name: 'Standard'   // 'Basic' との二択
  }

  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// ── NIC ─────────────────────────────────────
resource nic 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: '${vmName}-nic'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: { id: subnetId }
          publicIPAddress: { id: pip.id }
        }
      }
    ]
    networkSecurityGroup: { id: nsgId }
  }
}

// ── 仮想マシン ─────────────────────────────────────
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/azureuser/.ssh/authorized_keys'
              keyData: adminPublicKey
            }
          ]
        }
      }
      // Cloud-init scriptをカスタムデータとして渡す
      customData: base64(loadTextContent('../scripts/cloud-init.yaml'))
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        diskSizeGB: 32
      }
    }
    networkProfile: {
      networkInterfaces: [
        { id: nic.id }
      ]
    }
  }
}

// ── VM extensions ─────────────────────────────────────
resource waitDocker 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  name: 'wait-dify-docker'
  parent: vm  
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true

    settings: {
      commandToExecute: '''
        bash -c '
        COMPOSE=/opt/dify/docker/docker-compose.yaml;
        for i in {1..20}; do
          docker compose -f $COMPOSE ps | grep -q "Up" && exit 0;
          echo "⏳ waiting for Dify … ($i/20)"; sleep 30;
        done;
        echo "Dify containers did not start in time." >&2; exit 1'
      '''
    }
  }
}

output publicIp string = pip.properties.ipAddress
