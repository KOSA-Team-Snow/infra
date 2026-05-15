locals {
  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
}

resource "proxmox_virtual_environment_vm" "onprem" {
  for_each = var.vms

  name        = each.key
  description = "Managed by Terraform. Source template ${var.template_vm_id}."
  tags        = concat(["terraform", "onprem"], each.value.ansible_groups)

  node_name       = each.value.node_name
  vm_id           = each.value.vm_id
  started         = var.start_vms
  on_boot         = false
  stop_on_destroy = true

  clone {
    vm_id        = var.template_vm_id
    node_name    = var.template_node_name
    datastore_id = var.datastore_id
    full         = true
    retries      = 3
  }

  agent {
    enabled = true
    timeout = "10m"
  }

  cpu {
    cores = each.value.cores
    type  = var.cpu_type
  }

  memory {
    dedicated = each.value.memory_mb
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = each.value.disk_gb
  }

  initialization {
    datastore_id = var.cloud_init_datastore_id

    dns {
      servers = var.dns_servers
    }

    ip_config {
      ipv4 {
        address = "${each.value.ip}/${each.value.cidr}"
        gateway = each.value.gateway
      }
    }

    user_account {
      username = var.cloud_init_user
      keys     = [local.ssh_public_key]
    }
  }

  network_device {
    bridge  = var.service_bridge
    model   = "virtio"
    vlan_id = each.value.vlan_id
  }

  operating_system {
    type = "l26"
  }

  serial_device {}
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/${var.ansible_inventory_path}"
  content = templatefile("${path.module}/templates/ansible-inventory.yml.tftpl", {
    vms                = var.vms
    cloud_init_user    = var.cloud_init_user
    ssh_private_key    = replace(var.ssh_public_key_path, ".pub", "")
    kubernetes_api_vip = "172.16.43.99"
  })
}

