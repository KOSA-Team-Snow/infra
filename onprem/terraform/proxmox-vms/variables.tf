variable "proxmox_endpoint" {
  description = "Proxmox API endpoint."
  type        = string
  default     = "https://172.16.30.11:8006/"
}

variable "proxmox_api_token" {
  description = "Proxmox API token in the form user@realm!tokenid=secret."
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Allow self-signed Proxmox TLS certificate."
  type        = bool
  default     = true
}

variable "template_vm_id" {
  description = "Ubuntu cloud-init template VMID."
  type        = number
  default     = 9000
}

variable "template_node_name" {
  description = "Proxmox node where the source template currently lives."
  type        = string
  default     = "kosa-team3-01"
}

variable "datastore_id" {
  description = "Shared Ceph datastore for VM disks."
  type        = string
  default     = "TEAM3"
}

variable "cloud_init_datastore_id" {
  description = "Datastore for cloud-init disks."
  type        = string
  default     = "TEAM3"
}

variable "service_bridge" {
  description = "VLAN-aware Proxmox bridge used by VM service NICs."
  type        = string
  default     = "vmbr0"
}

variable "cloud_init_user" {
  description = "Default cloud-init user."
  type        = string
  default     = "kosa"
}

variable "ssh_public_key_path" {
  description = "SSH public key injected into VM cloud-init user."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "dns_servers" {
  description = "DNS servers passed through cloud-init."
  type        = list(string)
  default     = ["8.8.8.8", "1.1.1.1"]
}

variable "cpu_type" {
  description = "CPU type used for cloned VMs."
  type        = string
  default     = "x86-64-v2-AES"
}

variable "start_vms" {
  description = "Start VMs after creation."
  type        = bool
  default     = true
}

variable "ansible_inventory_path" {
  description = "Relative path from this Terraform module to the generated Ansible inventory."
  type        = string
  default     = "../../ansible/inventories/onprem/hosts.yml"
}

variable "vms" {
  description = "On-prem VM plan. pfSense is intentionally excluded and managed manually."
  type = map(object({
    vm_id          = number
    node_name      = string
    ip             = string
    cidr           = number
    gateway        = string
    vlan_id        = number
    cores          = number
    memory_mb      = number
    disk_gb        = number
    ansible_groups = list(string)
  }))

  default = {
    k8s-cp-1 = {
      vm_id          = 201
      node_name      = "kosa-team3-01"
      ip             = "172.16.43.100"
      cidr           = 24
      gateway        = "172.16.43.1"
      vlan_id        = 30
      cores          = 2
      memory_mb      = 4096
      disk_gb        = 40
      ansible_groups = ["k8s", "control_plane"]
    }
    k8s-cp-2 = {
      vm_id          = 202
      node_name      = "kosa-team3-02"
      ip             = "172.16.43.101"
      cidr           = 24
      gateway        = "172.16.43.1"
      vlan_id        = 30
      cores          = 2
      memory_mb      = 4096
      disk_gb        = 40
      ansible_groups = ["k8s", "control_plane"]
    }
    k8s-cp-3 = {
      vm_id          = 203
      node_name      = "kosa-team3-03"
      ip             = "172.16.43.102"
      cidr           = 24
      gateway        = "172.16.43.1"
      vlan_id        = 30
      cores          = 2
      memory_mb      = 4096
      disk_gb        = 40
      ansible_groups = ["k8s", "control_plane"]
    }
    k8s-worker-1 = {
      vm_id          = 211
      node_name      = "kosa-team3-01"
      ip             = "172.16.43.110"
      cidr           = 24
      gateway        = "172.16.43.1"
      vlan_id        = 30
      cores          = 4
      memory_mb      = 4096
      disk_gb        = 40
      ansible_groups = ["k8s", "worker", "app_worker"]
    }
    k8s-worker-2 = {
      vm_id          = 212
      node_name      = "kosa-team3-02"
      ip             = "172.16.43.111"
      cidr           = 24
      gateway        = "172.16.43.1"
      vlan_id        = 30
      cores          = 4
      memory_mb      = 4096
      disk_gb        = 40
      ansible_groups = ["k8s", "worker", "app_worker"]
    }
    k8s-worker-3 = {
      vm_id          = 213
      node_name      = "kosa-team3-03"
      ip             = "172.16.43.112"
      cidr           = 24
      gateway        = "172.16.43.1"
      vlan_id        = 30
      cores          = 4
      memory_mb      = 4096
      disk_gb        = 40
      ansible_groups = ["k8s", "worker", "infra_worker"]
    }
    lb-1 = {
      vm_id          = 221
      node_name      = "kosa-team3-04"
      ip             = "172.16.42.100"
      cidr           = 24
      gateway        = "172.16.42.1"
      vlan_id        = 20
      cores          = 2
      memory_mb      = 2048
      disk_gb        = 32
      ansible_groups = ["load_balancer"]
    }
    lb-2 = {
      vm_id          = 222
      node_name      = "kosa-team3-05"
      ip             = "172.16.42.101"
      cidr           = 24
      gateway        = "172.16.42.1"
      vlan_id        = 20
      cores          = 2
      memory_mb      = 2048
      disk_gb        = 32
      ansible_groups = ["load_balancer"]
    }
    bastion = {
      vm_id          = 231
      node_name      = "kosa-team3-01"
      ip             = "172.16.44.100"
      cidr           = 24
      gateway        = "172.16.44.1"
      vlan_id        = 40
      cores          = 2
      memory_mb      = 4096
      disk_gb        = 30
      ansible_groups = ["bastion_nodes"]
    }
    monitoring = {
      vm_id          = 232
      node_name      = "kosa-team3-04"
      ip             = "172.16.44.101"
      cidr           = 24
      gateway        = "172.16.44.1"
      vlan_id        = 40
      cores          = 2
      memory_mb      = 4096
      disk_gb        = 40
      ansible_groups = ["monitoring_nodes"]
    }
    argocd = {
      vm_id          = 233
      node_name      = "kosa-team3-03"
      ip             = "172.16.44.102"
      cidr           = 24
      gateway        = "172.16.44.1"
      vlan_id        = 40
      cores          = 2
      memory_mb      = 4096
      disk_gb        = 40
      ansible_groups = ["argocd_nodes"]
    }
    mariadb-1 = {
      vm_id          = 241
      node_name      = "kosa-team3-05"
      ip             = "172.16.43.160"
      cidr           = 24
      gateway        = "172.16.43.1"
      vlan_id        = 30
      cores          = 2
      memory_mb      = 4096
      disk_gb        = 100
      ansible_groups = ["database"]
    }
  }
}

